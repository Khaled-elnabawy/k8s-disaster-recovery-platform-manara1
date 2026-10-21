import app as app_module


def test_home_reports_service_status():
    response = app_module.app.test_client().get("/")
    assert response.status_code == 200
    assert response.get_json() == {"status": "running", "service": "demo-app"}


def test_health_endpoint_does_not_require_database():
    response = app_module.app.test_client().get("/healthz")
    assert response.status_code == 200
    assert response.get_json() == {"status": "ok"}


def test_post_user_requires_a_non_empty_name():
    response = app_module.app.test_client().post("/users", json={})
    assert response.status_code == 400
    assert response.get_json()["error"] == "A non-empty name is required"
