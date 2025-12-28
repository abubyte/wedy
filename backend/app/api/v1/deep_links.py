"""
Deep Links API endpoints for Universal Links and App Links support.
"""
from fastapi import APIRouter
from fastapi.responses import JSONResponse, PlainTextResponse
from app.core.config import settings
import json

router = APIRouter()


@router.get("/.well-known/assetlinks.json", include_in_schema=False)
async def get_android_asset_links():
    """
    Android App Links verification file.
    
    This file must be accessible at: https://wedy.uz/.well-known/assetlinks.json
    Replace the package name and SHA256 fingerprint with your actual values.
    """
    sha256_fingerprint = settings.ANDROID_SHA256_FINGERPRINT
    
    sha256_fingerprint = sha256_fingerprint.replace(":", "").lower()
    
    assetlinks = [
        {
            "relation": ["delegate_permission/common.handle_all_urls"],
            "target": {
                "namespace": "android_app",
                "package_name": settings.ANDROID_PACKAGE_NAME,
                "sha256_cert_fingerprints": [
                    sha256_fingerprint
                ]
            }
        }
    ]
    
    return JSONResponse(content=assetlinks)


@router.get("/.well-known/apple-app-site-association", include_in_schema=False)
async def get_apple_app_site_association():
    """
    iOS Universal Links verification file.
    
    This file must be accessible at: https://wedy.uz/.well-known/apple-app-site-association
    Must be served with Content-Type: application/json (not text/plain)
    Replace the app ID with your actual Team ID and Bundle ID.
    """
    # Get Team ID from settings (environment variable)
    # If not set, skip iOS Universal Links (will return empty details)
    team_id = settings.IOS_TEAM_ID
    bundle_id = settings.IOS_BUNDLE_ID
    
    aasa = {
        "applinks": {
            "apps": [],
            "details": []
        }
    }
    
    # Only add iOS details if Team ID is configured
    if team_id:
        aasa["applinks"]["details"].append({
            "appID": f"{team_id}.{bundle_id}",
            "paths": [
                "/service*"  # Only /service paths should open in app
            ]
        })
    
    return JSONResponse(
        content=aasa,
        headers={
            "Content-Type": "application/json"
        }
    )


@router.get("/service", include_in_schema=False)
async def service_redirect():
    """
    Redirect service web URLs to app or show fallback page.
    This endpoint handles web URLs when app is not installed.
    """
    # This could redirect to a web page or show app download links
    return PlainTextResponse(
        content="Please open this link in the Wedy app. If you don't have the app, please download it from the app store.",
        status_code=200
    )

