import asyncio
import sys
from pathlib import Path
from datetime import datetime, date, timedelta
from random import choice, randint

# Add the app directory to the Python path
sys.path.append(str(Path(__file__).parent.parent))

from sqlalchemy import select
from app.core.database import AsyncSessionLocal
from app.models import (
    Service, Merchant, FeaturedService, FeatureType
)


async def seed_featured_services():
    """Seed the database with dummy featured services."""
    print("Seeding featured services...")
    
    async with AsyncSessionLocal() as db:
        try:
            # Get all active services
            services_result = await db.execute(
                select(Service).where(Service.is_active == True)
            )
            services = list(services_result.scalars().all())
            
            if not services:
                print("❌ No active services found. Please seed services first using:")
                print("   poetry run python scripts/seed_data.py --all")
                return
            
            # Check if featured services already exist
            existing_featured = await db.execute(select(FeaturedService))
            if existing_featured.scalars().first():
                print("⚠️  Featured services already exist.")
                response = input("   Do you want to add more? (y/n): ")
                if response.lower() != 'y':
                    print("   Skipping featured services seeding...")
                    return
            
            print(f"   Found {len(services)} active services")
            
            # Select random services to feature (at least 5, up to 10)
            num_to_feature = min(max(5, len(services) // 2), 10)
            services_to_feature = services[:num_to_feature] if len(services) <= num_to_feature else [
                choice(services) for _ in range(num_to_feature)
            ]
            
            # Remove duplicates
            services_to_feature = list(dict.fromkeys(services_to_feature))
            
            print(f"   Creating featured services for {len(services_to_feature)} services...")
            
            created_count = 0
            now = datetime.now()
            
            for idx, service in enumerate(services_to_feature):
                # Get merchant for this service
                merchant_result = await db.execute(
                    select(Merchant).where(Merchant.id == service.merchant_id)
                )
                merchant = merchant_result.scalar_one_or_none()
                
                if not merchant:
                    print(f"   ⚠️  Skipping service {service.id} - merchant not found")
                    continue
                
                # Determine feature type and dates
                # Mix of active, future, and recently expired features
                feature_scenario = idx % 4
                
                if feature_scenario == 0:
                    # Active feature (started 5 days ago, ends in 25 days)
                    start_date = now - timedelta(days=5)
                    end_date = now + timedelta(days=25)
                    days_duration = 30
                    feature_type = FeatureType.MONTHLY_ALLOCATION
                    amount_paid = None
                    is_active = True
                    
                elif feature_scenario == 1:
                    # Active paid feature (started today, ends in 7 days)
                    start_date = now
                    end_date = now + timedelta(days=7)
                    days_duration = 7
                    feature_type = FeatureType.PAID_FEATURE
                    amount_paid = 50000.0  # 50,000 UZS
                    is_active = True
                    
                elif feature_scenario == 2:
                    # Future feature (starts in 3 days, ends in 33 days)
                    start_date = now + timedelta(days=3)
                    end_date = now + timedelta(days=33)
                    days_duration = 30
                    feature_type = FeatureType.MONTHLY_ALLOCATION
                    amount_paid = None
                    is_active = True
                    
                else:  # feature_scenario == 3
                    # Recently expired feature (ended 2 days ago)
                    start_date = now - timedelta(days=32)
                    end_date = now - timedelta(days=2)
                    days_duration = 30
                    feature_type = FeatureType.PAID_FEATURE
                    amount_paid = 75000.0  # 75,000 UZS
                    is_active = False
                
                # Create featured service
                featured_service = FeaturedService(
                    service_id=service.id,
                    merchant_id=merchant.id,
                    payment_id=None,  # Can be set if payment exists
                    start_date=start_date,
                    end_date=end_date,
                    days_duration=days_duration,
                    amount_paid=amount_paid,
                    feature_type=feature_type,
                    is_active=is_active
                )
                
                db.add(featured_service)
                created_count += 1
                
                status = "ACTIVE" if is_active else "EXPIRED"
                type_str = "Monthly" if feature_type == FeatureType.MONTHLY_ALLOCATION else "Paid"
                print(f"   ✅ Created {type_str} feature for '{service.name}' ({status})")
            
            # Commit all changes
            await db.commit()
            
            print("\n" + "="*60)
            print(f"✅ Successfully created {created_count} featured services!")
            print("="*60)
            print("\nFeatured services breakdown:")
            
            # Count by type and status
            active_result = await db.execute(
                select(FeaturedService).where(FeaturedService.is_active == True)
            )
            active_count = len(list(active_result.scalars().all()))
            
            monthly_result = await db.execute(
                select(FeaturedService).where(FeaturedService.feature_type == FeatureType.MONTHLY_ALLOCATION)
            )
            monthly_count = len(list(monthly_result.scalars().all()))
            
            paid_result = await db.execute(
                select(FeaturedService).where(FeaturedService.feature_type == FeatureType.PAID_FEATURE)
            )
            paid_count = len(list(paid_result.scalars().all()))
            
            print(f"  - Active features: {active_count}")
            print(f"  - Monthly allocations: {monthly_count}")
            print(f"  - Paid features: {paid_count}")
            print(f"  - Total featured services: {created_count}")
            
        except Exception as e:
            print(f"\n❌ Error seeding featured services: {e}")
            import traceback
            traceback.print_exc()
            await db.rollback()
            raise


if __name__ == "__main__":
    asyncio.run(seed_featured_services())

