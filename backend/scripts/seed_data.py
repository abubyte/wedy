import asyncio
import sys
from pathlib import Path

# Add the app directory to the Python path
sys.path.append(str(Path(__file__).parent.parent))

from sqlalchemy.ext.asyncio import AsyncSession
from app.core.database import engine, AsyncSessionLocal
from app.models import (
    User, UserType, ServiceCategory, TariffPlan
)


async def seed_sample_data():
    """Seed the database with sample data for development."""
    print("Seeding sample data...")
    
    async with AsyncSessionLocal() as db:
        try:
            # Create service categories
            categories = [
                ServiceCategory(
                    name="Photography",
                    description="Wedding photography services",
                    display_order=1
                ),
                ServiceCategory(
                    name="Videography", 
                    description="Wedding video recording services",
                    display_order=2
                ),
                ServiceCategory(
                    name="Restaurants",
                    description="Wedding venue and catering",
                    display_order=3
                ),
                ServiceCategory(
                    name="Music & Entertainment",
                    description="Wedding music and entertainment",
                    display_order=4
                ),
                ServiceCategory(
                    name="Decorations",
                    description="Wedding decorations and flowers",
                    display_order=5
                ),
                ServiceCategory(
                    name="Transportation",
                    description="Wedding transportation services",
                    display_order=6
                ),
                ServiceCategory(
                    name="Styling",
                    description="Wedding styling and makeup",
                    display_order=7
                ),
                ServiceCategory(
                    name="Clothes",
                    description="Wedding dresses and suits",
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


if __name__ == "__main__":
    asyncio.run(seed_sample_data())