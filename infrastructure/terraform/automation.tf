resource "aws_cloudwatch_metric_alarm" "primary_unhealthy_targets" {
  alarm_name          = "${var.project_name}-primary-unhealthy-targets"
  alarm_description   = "Primary ALB target group has unhealthy targets; notify the secondary-region recovery workflow."
  namespace           = "AWS/ApplicationELB"
  metric_name         = "UnHealthyHostCount"
  statistic           = "Maximum"
  period              = 60
  evaluation_periods  = 2
  threshold           = 0
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = var.primary_alb_arn_suffix
    TargetGroup  = var.primary_target_group_arn_suffix
  }

  tags = {
    Project = var.project_name
  }
}

resource "aws_cloudwatch_event_bus" "secondary_failover" {
  provider = aws.secondary
  name     = "${var.project_name}-failover-events"

  tags = {
    Project = var.project_name
  }
}

resource "aws_cloudwatch_event_bus_policy" "secondary_failover" {
  provider       = aws.secondary
  event_bus_name = aws_cloudwatch_event_bus.secondary_failover.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "AllowSameAccountPutEvents"
      Effect    = "Allow"
      Principal = { AWS = "arn:aws:iam::${data.aws_caller_identity.primary.account_id}:root" }
      Action    = "events:PutEvents"
      Resource  = aws_cloudwatch_event_bus.secondary_failover.arn
    }]
  })
}

resource "aws_iam_role" "eventbridge_forwarder" {
  name = "${var.project_name}-eventbridge-forwarder"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "events.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "eventbridge_forwarder" {
  name = "${var.project_name}-eventbridge-put-events"
  role = aws_iam_role.eventbridge_forwarder.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["events:PutEvents"]
      Resource = aws_cloudwatch_event_bus.secondary_failover.arn
    }]
  })
}

resource "aws_cloudwatch_event_rule" "primary_alarm" {
  name        = "${var.project_name}-forward-primary-alarm"
  description = "Forward primary target-health alarm transitions to the secondary region."

  event_pattern = jsonencode({
    source        = ["aws.cloudwatch"]
    "detail-type" = ["CloudWatch Alarm State Change"]
    detail = {
      alarmName = [aws_cloudwatch_metric_alarm.primary_unhealthy_targets.alarm_name]
      state     = { value = ["ALARM"] }
    }
  })

  tags = {
    Project = var.project_name
  }
}

resource "aws_cloudwatch_event_target" "primary_to_secondary" {
  rule      = aws_cloudwatch_event_rule.primary_alarm.name
  target_id = "secondary-region-event-bus"
  arn       = aws_cloudwatch_event_bus.secondary_failover.arn
  role_arn  = aws_iam_role.eventbridge_forwarder.arn

  retry_policy {
    maximum_event_age_in_seconds = 3600
    maximum_retry_attempts       = 12
  }

  depends_on = [aws_iam_role_policy.eventbridge_forwarder]
}

data "archive_file" "standby_scale_lambda" {
  type        = "zip"
  source_file = "${path.module}/../lambda/failover.py"
  output_path = "${path.module}/failover.zip"
}

resource "aws_iam_role" "standby_scale_lambda" {
  provider = aws.secondary
  name     = "${var.project_name}-standby-scale-lambda"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "standby_lambda_logs" {
  provider   = aws.secondary
  role       = aws_iam_role.standby_scale_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "standby_scale_lambda" {
  provider = aws.secondary
  name     = "${var.project_name}-standby-scale-asg"
  role     = aws_iam_role.standby_scale_lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["autoscaling:DescribeAutoScalingGroups"]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = ["autoscaling:UpdateAutoScalingGroup"]
        Resource = "arn:aws:autoscaling:${var.secondary_region}:${data.aws_caller_identity.secondary.account_id}:autoScalingGroup:*:autoScalingGroupName/${var.secondary_asg_name}"
      }
    ]
  })
}

resource "aws_lambda_function" "standby_scale" {
  provider         = aws.secondary
  function_name    = "${var.project_name}-scale-standby"
  description      = "Raises the secondary application Auto Scaling group after a forwarded primary health alarm."
  role             = aws_iam_role.standby_scale_lambda.arn
  handler          = "failover.handler"
  runtime          = "python3.12"
  timeout          = 30
  filename         = data.archive_file.standby_scale_lambda.output_path
  source_code_hash = data.archive_file.standby_scale_lambda.output_base64sha256

  environment {
    variables = {
      STANDBY_ASG_NAME     = var.secondary_asg_name
      STANDBY_DESIRED_SIZE = tostring(var.secondary_recovery_capacity)
    }
  }

  tags = {
    Project = var.project_name
  }

  depends_on = [
    aws_iam_role_policy_attachment.standby_lambda_logs,
    aws_iam_role_policy.standby_scale_lambda
  ]
}

resource "aws_cloudwatch_event_rule" "secondary_scale_standby" {
  provider       = aws.secondary
  name           = "${var.project_name}-scale-standby-on-primary-alarm"
  event_bus_name = aws_cloudwatch_event_bus.secondary_failover.name
  description    = "Consume forwarded primary ALB alarms and scale the standby application tier."

  event_pattern = jsonencode({
    source        = ["aws.cloudwatch"]
    "detail-type" = ["CloudWatch Alarm State Change"]
    detail = {
      alarmName = [aws_cloudwatch_metric_alarm.primary_unhealthy_targets.alarm_name]
      state     = { value = ["ALARM"] }
    }
  })

  tags = {
    Project = var.project_name
  }
}

resource "aws_cloudwatch_event_target" "secondary_scale_lambda" {
  provider       = aws.secondary
  event_bus_name = aws_cloudwatch_event_bus.secondary_failover.name
  rule           = aws_cloudwatch_event_rule.secondary_scale_standby.name
  target_id      = "scale-secondary-asg"
  arn            = aws_lambda_function.standby_scale.arn
}

resource "aws_lambda_permission" "allow_secondary_eventbridge" {
  provider      = aws.secondary
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.standby_scale.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.secondary_scale_standby.arn
}
