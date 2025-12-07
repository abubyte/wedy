import asyncio
import sys
from pathlib import Path
from datetime import date, timedelta

# Add the app directory to the Python path
sys.path.append(str(Path(__file__).parent.parent))

from sqlalchemy import select
from app.core.database import AsyncSessionLocal
from app.models import (
    User, UserType, ServiceCategory, TariffPlan, Merchant, Service,
    MerchantSubscription, SubscriptionStatus, Image, ImageType
)


async def seed_sample_data():
    """Seed the database with sample data for development."""
    print("Seeding sample data...")
    
    async with AsyncSessionLocal() as db:
        try:
            # Check if data already exists
            existing_categories = await db.execute(select(ServiceCategory))
            existing_tariffs = await db.execute(select(TariffPlan))
            existing_users = await db.execute(select(User))
            
            if (
                existing_categories.scalars().first()
                or existing_tariffs.scalars().first()
                or existing_users.scalars().first()
            ):
                print("✅ Sample data already exists, skipping seeding...")
                return
            
            # Create service categories with real icon URLs
            categories = [
                ServiceCategory(
                    name="Photography",
                    description="Wedding photography services",
                    icon_url="https://images.unsplash.com/photo-1511285560929-80b456fea0bc?w=200&h=200&fit=crop",
                    display_order=1
                ),
                ServiceCategory(
                    name="Videography", 
                    description="Wedding video recording services",
                    icon_url="https://images.unsplash.com/photo-1492684223066-81342ee5ff30?w=200&h=200&fit=crop",
                    display_order=2
                ),
                ServiceCategory(
                    name="Restaurants",
                    description="Wedding venue and catering",
                    icon_url="https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=200&h=200&fit=crop",
                    display_order=3
                ),
                ServiceCategory(
                    name="Music & Entertainment",
                    description="Wedding music and entertainment",
                    icon_url="https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=200&h=200&fit=crop",
                    display_order=4
                ),
                ServiceCategory(
                    name="Decorations",
                    description="Wedding decorations and flowers",
                    icon_url="https://images.unsplash.com/photo-1465495976277-4387d4b0b4c6?w=200&h=200&fit=crop",
                    display_order=5
                ),
                ServiceCategory(
                    name="Transportation",
                    description="Wedding transportation services",
                    icon_url="https://images.unsplash.com/photo-1502877338535-766e1452684a?w=200&h=200&fit=crop",
                    display_order=6
                ),
                ServiceCategory(
                    name="Styling",
                    description="Wedding styling and makeup",
                    icon_url="https://images.unsplash.com/photo-1522337360788-8b13dee7a37e?w=200&h=200&fit=crop",
                    display_order=7
                ),
                ServiceCategory(
                    name="Clothes",
                    description="Wedding dresses and suits",
                    icon_url="https://images.unsplash.com/photo-1515372039744-b8f02a3ae446?w=200&h=200&fit=crop",
                    display_order=8
                ),
            ]
            
            for category in categories:
                db.add(category)
            
            # Create tariff plans
            tariff_plans = [
                TariffPlan(
                    name="Basic",
                    price_per_month=50000,  # 50,000 UZS
                    max_services=3,
                    max_images_per_service=5,
                    max_phone_numbers=1,
                    max_gallery_images=5,
                    max_social_accounts=2,
                    allow_website=False,
                    allow_cover_image=False,
                    monthly_featured_cards=0
                ),
                TariffPlan(
                    name="Standard",
                    price_per_month=100000,  # 100,000 UZS
                    max_services=10,
                    max_images_per_service=10,
                    max_phone_numbers=2,
                    max_gallery_images=15,
                    max_social_accounts=5,
                    allow_website=True,
                    allow_cover_image=True,
                    monthly_featured_cards=2
                ),
                TariffPlan(
                    name="Premium",
                    price_per_month=200000,  # 200,000 UZS
                    max_services=25,
                    max_images_per_service=15,
                    max_phone_numbers=3,
                    max_gallery_images=30,
                    max_social_accounts=10,
                    allow_website=True,
                    allow_cover_image=True,
                    monthly_featured_cards=5
                ),
                TariffPlan(
                    name="Enterprise",
                    price_per_month=500000,  # 500,000 UZS
                    max_services=100,
                    max_images_per_service=25,
                    max_phone_numbers=5,
                    max_gallery_images=100,
                    max_social_accounts=20,
                    allow_website=True,
                    allow_cover_image=True,
                    monthly_featured_cards=15
                ),
            ]
            
            for tariff in tariff_plans:
                db.add(tariff)
            
            # Create admin user
            admin_user = User(
                phone_number="901234567",
                name="System Admin",
                user_type=UserType.ADMIN
            )
            db.add(admin_user)
            
            # Commit all changes
            await db.commit()
            
            print("✅ Sample data seeded successfully!")
            print("Created:")
            print(f"  - {len(categories)} service categories")
            print(f"  - {len(tariff_plans)} tariff plans")
            print("  - 1 admin user (phone: 901234567)")
            
        except Exception as e:
            print(f"❌ Error seeding sample data: {e}")
            await db.rollback()
            raise


async def seed_merchants_and_services():
    """Seed the database with dummy merchants and services."""
    print("\nSeeding merchants and services...")
    
    async with AsyncSessionLocal() as db:
        try:
            # Get existing categories and tariff plans
            categories_result = await db.execute(select(ServiceCategory).where(ServiceCategory.is_active == True))
            categories = list(categories_result.scalars().all())
            
            if not categories:
                print("❌ No active categories found. Please run seed_sample_data() first.")
                return
            
            tariff_result = await db.execute(select(TariffPlan).where(TariffPlan.is_active == True).limit(1))
            tariff = tariff_result.scalar_one_or_none()
            
            if not tariff:
                print("❌ No active tariff plan found. Please run seed_sample_data() first.")
                return
            
            # Check if services already exist (allow creating services for existing merchants)
            existing_services = await db.execute(select(Service))
            if existing_services.scalars().first():
                print("⚠️  Services already exist. Skipping service seeding...")
                print("   If you want to add more services, delete existing services first.")
                return
            
            # Get existing merchants or create new ones
            existing_merchants_result = await db.execute(select(Merchant))
            existing_merchants_list = list(existing_merchants_result.scalars().all())
            existing_merchants_dict = {m.business_name: m for m in existing_merchants_list}
            
            # Merchant data to create or use
            merchants_data = [
                {
                    "phone": "901111111",
                    "name": "Aziz Karimov",
                    "business_name": "Wedding Photo Studio",
                    "description": "Professional wedding photography services with 10+ years of experience",
                    "region": "Tashkent",
                    "lat": 41.3111,
                    "lon": 69.2797,
                    "cover_image_url": "https://images.unsplash.com/photo-1511285560929-80b456fea0bc?w=1200&h=600&fit=crop",
                    "avatar_url": "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200&h=200&fit=crop",
                },
                {
                    "phone": "902222222",
                    "name": "Nodira Alimova",
                    "business_name": "Elegant Decorations",
                    "description": "Beautiful wedding decorations and flower arrangements",
                    "region": "Samarkand",
                    "lat": 39.6542,
                    "lon": 66.9597,
                    "cover_image_url": "https://images.unsplash.com/photo-1465495976277-4387d4b0b4c6?w=1200&h=600&fit=crop",
                    "avatar_url": "https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=200&h=200&fit=crop",
                },
                {
                    "phone": "903333333",
                    "name": "Bobur Toshmatov",
                    "business_name": "Royal Wedding Venue",
                    "description": "Luxury wedding venue and catering services",
                    "region": "Tashkent",
                    "lat": 41.3111,
                    "lon": 69.2797,
                    "cover_image_url": "https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=1200&h=600&fit=crop",
                    "avatar_url": "https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=200&h=200&fit=crop",
                },
                {
                    "phone": "904444444",
                    "name": "Dilbar Kadirova",
                    "business_name": "Bridal Beauty Salon",
                    "description": "Professional wedding makeup and hairstyling",
                    "region": "Bukhara",
                    "lat": 39.7756,
                    "lon": 64.4286,
                    "cover_image_url": "https://images.unsplash.com/photo-1522337360788-8b13dee7a37e?w=1200&h=600&fit=crop",
                    "avatar_url": "https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=200&h=200&fit=crop",
                },
                {
                    "phone": "905555555",
                    "name": "Jasur Murodov",
                    "business_name": "Music Entertainment Group",
                    "description": "Live music and DJ services for weddings",
                    "region": "Tashkent",
                    "lat": 41.3111,
                    "lon": 69.2797,
                    "cover_image_url": "https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=1200&h=600&fit=crop",
                    "avatar_url": "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=200&h=200&fit=crop",
                },
                {
                    "phone": "906666666",
                    "name": "Madina Yusupova",
                    "business_name": "Dream Wedding Dresses",
                    "description": "Elegant wedding dresses and groom suits",
                    "region": "Tashkent",
                    "lat": 41.3111,
                    "lon": 69.2797,
                    "cover_image_url": "https://images.unsplash.com/photo-1515372039744-b8f02a3ae446?w=1200&h=600&fit=crop",
                    "avatar_url": "https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=200&h=200&fit=crop",
                },
            ]
            
            created_merchants = []
            services_data = []
            
            # Map categories by name for easy lookup
            category_map = {cat.name: cat for cat in categories}
            
            for idx, merchant_info in enumerate(merchants_data):
                business_name = merchant_info["business_name"]
                
                # Check if merchant already exists
                merchant = existing_merchants_dict.get(business_name)
                
                if merchant:
                    print(f"   Using existing merchant: {business_name}")
                    # Update merchant with image URLs if missing
                    if not merchant.cover_image_url and merchant_info.get("cover_image_url"):
                        merchant.cover_image_url = merchant_info["cover_image_url"]
                    # Update user avatar if missing
                    user = await db.get(User, merchant.user_id)
                    if user and not user.avatar_url and merchant_info.get("avatar_url"):
                        user.avatar_url = merchant_info["avatar_url"]
                    # Ensure merchant has an active subscription
                    subscription_check = await db.execute(
                        select(MerchantSubscription).where(
                            MerchantSubscription.merchant_id == merchant.id,
                            MerchantSubscription.status == SubscriptionStatus.ACTIVE
                        )
                    )
                    if not subscription_check.scalar_one_or_none():
                        # Create active subscription for existing merchant
                        start_date = date.today()
                        end_date = start_date + timedelta(days=30)
                        subscription = MerchantSubscription(
                            merchant_id=merchant.id,
                            tariff_plan_id=tariff.id,
                            start_date=start_date,
                            end_date=end_date,
                            status=SubscriptionStatus.ACTIVE
                        )
                        db.add(subscription)
                else:
                    # Create new user
                    user = User(
                        phone_number=merchant_info["phone"],
                        name=merchant_info["name"],
                        user_type=UserType.MERCHANT,
                        avatar_url=merchant_info.get("avatar_url")
                    )
                    db.add(user)
                    await db.flush()  # Get user.id
                    
                    # Create new merchant
                    merchant = Merchant(
                        user_id=user.id,
                        business_name=business_name,
                        description=merchant_info["description"],
                        location_region=merchant_info["region"],
                        latitude=merchant_info["lat"],
                        longitude=merchant_info["lon"],
                        cover_image_url=merchant_info.get("cover_image_url")
                    )
                    db.add(merchant)
                    await db.flush()  # Get merchant.id
                    
                    print(f"   Created new merchant: {business_name}")
                    
                    # Create active subscription for new merchant
                    start_date = date.today()
                    end_date = start_date + timedelta(days=30)  # 30 days subscription
                    
                    subscription = MerchantSubscription(
                        merchant_id=merchant.id,
                        tariff_plan_id=tariff.id,
                        start_date=start_date,
                        end_date=end_date,
                        status=SubscriptionStatus.ACTIVE
                    )
                    db.add(subscription)
                
                created_merchants.append(merchant)
                
                # Prepare services for this merchant based on business type
                if "Photo" in merchant_info["business_name"]:
                    category = category_map.get("Photography", categories[0])
                    services_data.append({
                        "merchant_id": merchant.id,
                        "category_id": category.id,
                        "name": "Wedding Photography Package",
                        "description": "Full day wedding photography with 500+ edited photos and photo album",
                        "price": 5000000.0,
                        "region": merchant_info["region"],
                        "lat": merchant_info["lat"],
                        "lon": merchant_info["lon"],
                        "images": [
                            "https://images.unsplash.com/photo-1511285560929-80b456fea0bc?w=800&h=600&fit=crop",
                            "https://images.unsplash.com/photo-1465495976277-4387d4b0b4c6?w=800&h=600&fit=crop",
                            "https://images.unsplash.com/photo-1519741497674-611481863552?w=800&h=600&fit=crop",
                        ]
                    })
                    services_data.append({
                        "merchant_id": merchant.id,
                        "category_id": category.id,
                        "name": "Pre-wedding Photography",
                        "description": "Romantic pre-wedding photoshoot at beautiful locations",
                        "price": 2000000.0,
                        "region": merchant_info["region"],
                        "lat": merchant_info["lat"],
                        "lon": merchant_info["lon"],
                        "images": [
                            "https://images.unsplash.com/photo-1519741497674-611481863552?w=800&h=600&fit=crop",
                            "https://images.unsplash.com/photo-1469371670807-013ccf25f16a?w=800&h=600&fit=crop",
                        ]
                    })
                    
                elif "Decor" in merchant_info["business_name"]:
                    category = category_map.get("Decorations", categories[0])
                    services_data.append({
                        "merchant_id": merchant.id,
                        "category_id": category.id,
                        "name": "Full Wedding Decoration",
                        "description": "Complete wedding hall decoration with flowers, lights, and props",
                        "price": 8000000.0,
                        "region": merchant_info["region"],
                        "lat": merchant_info["lat"],
                        "lon": merchant_info["lon"],
                        "images": [
                            "https://images.unsplash.com/photo-1465495976277-4387d4b0b4c6?w=800&h=600&fit=crop",
                            "https://images.unsplash.com/photo-1519167758481-83f550bb49b3?w=800&h=600&fit=crop",
                            "https://images.unsplash.com/photo-1519167758481-83f550bb49b3?w=800&h=600&fit=crop",
                        ]
                    })
                    services_data.append({
                        "merchant_id": merchant.id,
                        "category_id": category.id,
                        "name": "Flower Arrangements",
                        "description": "Beautiful bridal bouquet and centerpieces",
                        "price": 1500000.0,
                        "region": merchant_info["region"],
                        "lat": merchant_info["lat"],
                        "lon": merchant_info["lon"],
                        "images": [
                            "https://images.unsplash.com/photo-1465495976277-4387d4b0b4c6?w=800&h=600&fit=crop",
                            "https://images.unsplash.com/photo-1518621012428-6d5d0c8b0c8c?w=800&h=600&fit=crop",
                        ]
                    })
                    
                elif "Venue" in merchant_info["business_name"]:
                    category = category_map.get("Restaurants", categories[0])
                    services_data.append({
                        "merchant_id": merchant.id,
                        "category_id": category.id,
                        "name": "Wedding Venue Rental",
                        "description": "Elegant wedding hall for 200+ guests with catering",
                        "price": 15000000.0,
                        "region": merchant_info["region"],
                        "lat": merchant_info["lat"],
                        "lon": merchant_info["lon"],
                        "images": [
                            "https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=800&h=600&fit=crop",
                            "https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=800&h=600&fit=crop",
                            "https://images.unsplash.com/photo-1559339352-11d035aa65de?w=800&h=600&fit=crop",
                        ]
                    })
                    services_data.append({
                        "merchant_id": merchant.id,
                        "category_id": category.id,
                        "name": "Wedding Catering",
                        "description": "Delicious traditional and European cuisine for wedding",
                        "price": 5000000.0,
                        "region": merchant_info["region"],
                        "lat": merchant_info["lat"],
                        "lon": merchant_info["lon"],
                        "images": [
                            "https://images.unsplash.com/photo-1559339352-11d035aa65de?w=800&h=600&fit=crop",
                            "https://images.unsplash.com/photo-1504674900247-0877df9c8360?w=800&h=600&fit=crop",
                        ]
                    })
                    
                elif "Beauty" in merchant_info["business_name"]:
                    category = category_map.get("Styling", categories[0])
                    services_data.append({
                        "merchant_id": merchant.id,
                        "category_id": category.id,
                        "name": "Bridal Makeup & Hair",
                        "description": "Professional wedding day makeup and hairstyling",
                        "price": 2000000.0,
                        "region": merchant_info["region"],
                        "lat": merchant_info["lat"],
                        "lon": merchant_info["lon"],
                        "images": [
                            "https://images.unsplash.com/photo-1522337360788-8b13dee7a37e?w=800&h=600&fit=crop",
                            "https://images.unsplash.com/photo-1512496015851-a90fb38a796b?w=800&h=600&fit=crop",
                        ]
                    })
                    services_data.append({
                        "merchant_id": merchant.id,
                        "category_id": category.id,
                        "name": "Groom Grooming",
                        "description": "Professional grooming and styling for groom",
                        "price": 800000.0,
                        "region": merchant_info["region"],
                        "lat": merchant_info["lat"],
                        "lon": merchant_info["lon"],
                        "images": [
                            "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=800&h=600&fit=crop",
                            "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=800&h=600&fit=crop",
                        ]
                    })
                    
                elif "Music" in merchant_info["business_name"]:
                    category = category_map.get("Music & Entertainment", categories[0])
                    services_data.append({
                        "merchant_id": merchant.id,
                        "category_id": category.id,
                        "name": "Wedding DJ Services",
                        "description": "Professional DJ with sound system for wedding celebration",
                        "price": 3000000.0,
                        "region": merchant_info["region"],
                        "lat": merchant_info["lat"],
                        "lon": merchant_info["lon"],
                        "images": [
                            "https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=800&h=600&fit=crop",
                            "https://images.unsplash.com/photo-1470229722913-7c0e2dbbafd3?w=800&h=600&fit=crop",
                        ]
                    })
                    services_data.append({
                        "merchant_id": merchant.id,
                        "category_id": category.id,
                        "name": "Live Music Band",
                        "description": "Traditional and modern live music performance",
                        "price": 5000000.0,
                        "region": merchant_info["region"],
                        "lat": merchant_info["lat"],
                        "lon": merchant_info["lon"],
                        "images": [
                            "https://images.unsplash.com/photo-1470229722913-7c0e2dbbafd3?w=800&h=600&fit=crop",
                            "https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=800&h=600&fit=crop",
                        ]
                    })
                    
                elif "Dress" in merchant_info["business_name"]:
                    category = category_map.get("Clothes", categories[0])
                    services_data.append({
                        "merchant_id": merchant.id,
                        "category_id": category.id,
                        "name": "Bridal Wedding Dress",
                        "description": "Elegant wedding dress rental or purchase",
                        "price": 10000000.0,
                        "region": merchant_info["region"],
                        "lat": merchant_info["lat"],
                        "lon": merchant_info["lon"],
                        "images": [
                            "https://images.unsplash.com/photo-1515372039744-b8f02a3ae446?w=800&h=600&fit=crop",
                            "https://images.unsplash.com/photo-1519167758481-83f550bb49b3?w=800&h=600&fit=crop",
                            "https://images.unsplash.com/photo-1469371670807-013ccf25f16a?w=800&h=600&fit=crop",
                        ]
                    })
                    services_data.append({
                        "merchant_id": merchant.id,
                        "category_id": category.id,
                        "name": "Groom Suit",
                        "description": "Classic wedding suit rental",
                        "price": 3000000.0,
                        "region": merchant_info["region"],
                        "lat": merchant_info["lat"],
                        "lon": merchant_info["lon"],
                        "images": [
                            "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=800&h=600&fit=crop",
                            "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=800&h=600&fit=crop",
                        ]
                    })
            
            # Create services
            for service_info in services_data:
                service = Service(
                    merchant_id=service_info["merchant_id"],
                    category_id=service_info["category_id"],
                    name=service_info["name"],
                    description=service_info["description"],
                    price=service_info["price"],
                    location_region=service_info["region"],
                    latitude=service_info["lat"],
                    longitude=service_info["lon"],
                )
                db.add(service)
                await db.flush()  # Get service.id
                
                # Create service images if provided
                service_images = service_info.get("images", [])
                for idx, image_url in enumerate(service_images):
                    image = Image(
                        s3_url=image_url,
                        file_name=f"{service_info['name'].lower().replace(' ', '_')}_{idx + 1}.jpg",
                        image_type=ImageType.SERVICE_IMAGE,
                        related_id=str(service.id),  # Convert service.id (string) to string for Image.related_id
                        display_order=idx,
                        is_active=True
                    )
                    db.add(image)
            
            # Commit all changes
            await db.commit()
            
            print("✅ Merchants and services seeded successfully!")
            print(f"Created:")
            print(f"  - {len(created_merchants)} merchants")
            print(f"  - {len(services_data)} services")
            print(f"  - {len(created_merchants)} active subscriptions")
            
        except Exception as e:
            print(f"❌ Error seeding merchants and services: {e}")
            import traceback
            traceback.print_exc()
            await db.rollback()
            raise


async def seed_all():
    """Seed all data: categories, tariffs, merchants, and services."""
    await seed_sample_data()
    await seed_merchants_and_services()


if __name__ == "__main__":
    import argparse
    
    parser = argparse.ArgumentParser(description="Seed database with sample data")
    parser.add_argument(
        "--merchants-only",
        action="store_true",
        help="Only seed merchants and services (skip categories and tariffs)"
    )
    parser.add_argument(
        "--all",
        action="store_true",
        help="Seed everything: categories, tariffs, merchants, and services"
    )
    parser.add_argument(
        "--force",
        action="store_true",
        help="Force re-seeding even if data exists (clears existing data first)"
    )
    
    args = parser.parse_args()
    
    if args.merchants_only:
        asyncio.run(seed_merchants_and_services())
    elif args.all:
        asyncio.run(seed_all())
    else:
        asyncio.run(seed_sample_data())