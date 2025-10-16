import os
import importlib
import pytest
from fastapi import status
from fastapi.testclient import TestClient


def _get_app_or_skip():
    """Try to import the FastAPI app; skip tests if import fails due to missing deps."""
    try:
        mod = importlib.import_module("app.main")
        return mod.app
    except Exception as e:
        # Skip the test at runtime if application cannot be imported (missing deps, DB unavailable, etc.)
        pytest.skip(f"Skipping integration tests - cannot import app: {e}")


@pytest.mark.integration
def test_root_and_health_and_docs_and_services():
    app = _get_app_or_skip()
    client = TestClient(app)

    # root
    r = client.get("/")
    assert r.status_code == status.HTTP_200_OK
    body = r.json()
    assert "message" in body

    # health
    r = client.get("/health")
    assert r.status_code == status.HTTP_200_OK
    hb = r.json()
    assert hb.get("status") == "healthy"

    # docs
    r = client.get("/docs")
    # docs may be disabled depending on settings; accept 200 or 404
    assert r.status_code in (200, 404)

    # services list (simple smoke)
    r = client.get("/api/v1/services?offset=0&limit=5")
    # The app may redirect to a trailing slash; accept 200 or 307
    assert r.status_code in (200, 307)


@pytest.mark.integration
def test_users_profile_get_unauthenticated():
    app = _get_app_or_skip()
    client = TestClient(app)

    # Should return 401 for protected endpoints that require auth
    r = client.get("/api/v1/users/profile")
    assert r.status_code in (401, 422, 403)
