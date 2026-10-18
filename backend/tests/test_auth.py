import uuid
import pytest
from fastapi.testclient import TestClient
from backend.app.main import app

client = TestClient(app)

def test_health_check():
    response = client.get("/")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "healthy"

def test_register_and_login():
    email = f"user_{uuid.uuid4().hex[:8]}@obsidianslate.dev"
    password = "secure_password_123"

    # Register
    reg_res = client.post(
        "/api/auth/register",
        json={"email": email, "password": password},
    )
    assert reg_res.status_code == 201
    assert reg_res.json()["email"] == email

    # Duplicate register should fail
    dup_res = client.post(
        "/api/auth/register",
        json={"email": email, "password": password},
    )
    assert dup_res.status_code == 400

    # Login
    login_res = client.post(
        "/api/auth/login",
        json={"email": email, "password": password},
    )
    assert login_res.status_code == 200
    assert "access_token" in login_res.json()
