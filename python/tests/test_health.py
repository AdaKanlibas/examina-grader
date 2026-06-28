"""Smoke tests for the Python service."""

import pytest
from httpx import AsyncClient, ASGITransport
from app.main import app


@pytest.mark.asyncio
async def test_health():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.get("/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "ok"
    assert data["service"] == "examina-python"


@pytest.mark.asyncio
async def test_verify_stub():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.post("/verify", json={
            "submission_id": "test-123",
            "mark_id": "A1",
            "student_answer": "3*x**2 + 4*x - 5",
            "expected_answer": "3*x**2 + 4*x - 5",
            "variables": ["x"],
        })
    assert response.status_code == 200
    data = response.json()
    assert data["result"] == "not_applicable"  # Phase 2 stub
    assert data["submission_id"] == "test-123"


@pytest.mark.asyncio
async def test_ocr_stub():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.post("/ocr", json={
            "image_base64": "aGVsbG8=",  # "hello" in base64
            "mime_type": "image/jpeg",
        })
    assert response.status_code == 200
    data = response.json()
    assert "latex" in data
    assert "confidence" in data
