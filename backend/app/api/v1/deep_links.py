"""
Deep Links API endpoints for Universal Links and App Links support.
"""
from fastapi import APIRouter, Query, HTTPException, status, Depends
from fastapi.responses import JSONResponse, HTMLResponse
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.config import settings
from app.core.database import get_db_session
from app.services.service_manager import ServiceManager
from app.core.exceptions import NotFoundError
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
async def service_redirect(
    id: str = Query(..., description="Service ID"),
    db: AsyncSession = Depends(get_db_session)
):
    """
    Service web page that redirects to app or shows service preview.
    This endpoint handles web URLs when app is not installed.
    Universal Links / App Links will automatically open the app if installed.
    """
    try:
        service_manager = ServiceManager(db)
        service = await service_manager.get_service_details(service_id=id, user_id=None)
        
        # Get main image URL
        main_image_url = ""
        if service.images and len(service.images) > 0:
            main_image_url = service.images[0].s3_url
        
        # Generate app deep link
        app_deep_link = f"wedy://service?id={id}"
        web_url = f"https://wedy.uz/service?id={id}"
        
        # Format price
        price_formatted = f"{int(service.price):,}".replace(",", " ")
        
        # Create HTML page with meta tags and auto-redirect
        html_content = f"""<!DOCTYPE html>
<html lang="uz">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{service.name} - Wedy</title>
    
    <!-- Open Graph / Facebook -->
    <meta property="og:type" content="website">
    <meta property="og:url" content="{web_url}">
    <meta property="og:title" content="{service.name}">
    <meta property="og:description" content="{service.description[:200]}">
    {f'<meta property="og:image" content="{main_image_url}">' if main_image_url else ''}
    
    <!-- Twitter -->
    <meta name="twitter:card" content="summary_large_image">
    <meta name="twitter:url" content="{web_url}">
    <meta name="twitter:title" content="{service.name}">
    <meta name="twitter:description" content="{service.description[:200]}">
    {f'<meta name="twitter:image" content="{main_image_url}">' if main_image_url else ''}
    
    <!-- App Deep Link -->
    <meta name="apple-itunes-app" content="app-id=YOUR_APP_STORE_ID">
    <link rel="alternate" href="android-app://{settings.ANDROID_PACKAGE_NAME}/wedy/service?id={id}">
    
    <style>
        * {{
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }}
        body {{
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 20px;
        }}
        .container {{
            background: white;
            border-radius: 20px;
            max-width: 500px;
            width: 100%;
            box-shadow: 0 20px 60px rgba(0,0,0,0.3);
            overflow: hidden;
        }}
        .image {{
            width: 100%;
            height: 300px;
            background: #f0f0f0;
            display: flex;
            align-items: center;
            justify-content: center;
            color: #999;
        }}
        .image img {{
            width: 100%;
            height: 100%;
            object-fit: cover;
        }}
        .content {{
            padding: 30px;
        }}
        h1 {{
            font-size: 24px;
            margin-bottom: 10px;
            color: #333;
        }}
        .price {{
            font-size: 28px;
            font-weight: bold;
            color: #667eea;
            margin-bottom: 15px;
        }}
        .description {{
            color: #666;
            line-height: 1.6;
            margin-bottom: 20px;
        }}
        .meta {{
            display: flex;
            gap: 15px;
            margin-bottom: 20px;
            flex-wrap: wrap;
        }}
        .meta-item {{
            display: flex;
            align-items: center;
            gap: 5px;
            color: #666;
            font-size: 14px;
        }}
        .button {{
            background: #667eea;
            color: white;
            border: none;
            padding: 15px 30px;
            border-radius: 10px;
            font-size: 16px;
            font-weight: 600;
            cursor: pointer;
            width: 100%;
            transition: background 0.3s;
        }}
        .button:hover {{
            background: #5568d3;
        }}
        .loading {{
            text-align: center;
            color: #999;
            margin-top: 20px;
            font-size: 14px;
        }}
    </style>
    
    <script>
        // Try to open app immediately
        function openApp() {{
            // Try Android intent
            window.location.href = "intent://service?id={id}#Intent;scheme=wedy;package={settings.ANDROID_PACKAGE_NAME};end";
            
            // Fallback to app scheme
            setTimeout(function() {{
                window.location.href = "{app_deep_link}";
            }}, 500);
            
            // If app doesn't open, show download buttons after 2 seconds
            setTimeout(function() {{
                document.getElementById('loading').style.display = 'none';
                document.getElementById('download-buttons').style.display = 'block';
            }}, 2000);
        }}
        
        // Auto-try to open app on page load
        window.onload = function() {{
            openApp();
        }};
    </script>
</head>
<body>
    <div class="container">
        {f'<div class="image"><img src="{main_image_url}" alt="{service.name}"></div>' if main_image_url else '<div class="image">Rasm yo\'q</div>'}
        <div class="content">
            <h1>{service.name}</h1>
            <div class="price">{price_formatted} so'm</div>
            <div class="meta">
                <div class="meta-item">📍 {service.location_region}</div>
                <div class="meta-item">📁 {service.category_name}</div>
                {f'<div class="meta-item">⭐ {service.overall_rating:.1f}</div>' if service.overall_rating > 0 else ''}
            </div>
            <div class="description">{service.description}</div>
            <button class="button" onclick="openApp()">Ilovada ochish</button>
            <div id="loading" class="loading">Ilova ochilmoqda...</div>
            <div id="download-buttons" style="display: none; margin-top: 20px;">
                <p style="text-align: center; color: #666; margin-bottom: 15px;">Ilova o'rnatilmagan</p>
                <a href="https://play.google.com/store/apps/details?id={settings.ANDROID_PACKAGE_NAME}" 
                   style="display: block; background: #000; color: white; text-align: center; padding: 12px; border-radius: 8px; text-decoration: none; margin-bottom: 10px;">
                    Google Play'dan yuklab olish
                </a>
                <a href="https://apps.apple.com/app/id=YOUR_APP_STORE_ID" 
                   style="display: block; background: #000; color: white; text-align: center; padding: 12px; border-radius: 8px; text-decoration: none;">
                    App Store'dan yuklab olish
                </a>
            </div>
        </div>
    </div>
</body>
</html>"""
        
        return HTMLResponse(content=html_content)
        
    except NotFoundError:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Service not found"
        )
    except Exception as e:
        # Return a simple error page
        html_content = f"""<!DOCTYPE html>
<html lang="uz">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Xatolik - Wedy</title>
    <style>
        body {{
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 20px;
        }}
        .container {{
            background: white;
            border-radius: 20px;
            padding: 40px;
            max-width: 400px;
            text-align: center;
        }}
        h1 {{
            color: #333;
            margin-bottom: 20px;
        }}
        p {{
            color: #666;
        }}
    </style>
</head>
<body>
    <div class="container">
        <h1>Xatolik</h1>
        <p>Xizmat topilmadi yoki mavjud emas.</p>
    </div>
</body>
</html>"""
        return HTMLResponse(content=html_content, status_code=status.HTTP_404_NOT_FOUND)

