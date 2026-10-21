resource "aws_route53_health_check" "primary_alb" {
  fqdn              = var.primary_alb_dns_name
  port              = 80
  type              = "HTTP"
  resource_path     = "/health"
  failure_threshold = 3
  request_interval  = 30
  measure_latency   = true

  tags = {
    Name    = "${var.project_name}-primary-health-check"
    Project = var.project_name
  }
}

resource "aws_route53_health_check" "secondary_alb" {
  fqdn              = var.secondary_alb_dns_name
  port              = 80
  type              = "HTTP"
  resource_path     = "/health"
  failure_threshold = 3
  request_interval  = 30
  measure_latency   = true

  tags = {
    Name    = "${var.project_name}-secondary-health-check"
    Project = var.project_name
  }
}

resource "aws_route53_record" "primary" {
  zone_id         = var.route53_hosted_zone_id
  name            = var.application_fqdn
  type            = "A"
  set_identifier  = "primary-us-east-1"
  health_check_id = aws_route53_health_check.primary_alb.id

  failover_routing_policy {
    type = "PRIMARY"
  }

  alias {
    name                   = var.primary_alb_dns_name
    zone_id                = var.primary_alb_zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "secondary" {
  zone_id         = var.route53_hosted_zone_id
  name            = var.application_fqdn
  type            = "A"
  set_identifier  = "secondary-eu-west-1"
  health_check_id = aws_route53_health_check.secondary_alb.id

  failover_routing_policy {
    type = "SECONDARY"
  }

  alias {
    name                   = var.secondary_alb_dns_name
    zone_id                = var.secondary_alb_zone_id
    evaluate_target_health = true
  }
}
