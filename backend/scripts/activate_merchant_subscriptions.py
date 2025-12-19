"""
Script to activate subscriptions for merchants who don't have an active subscription.
This is useful for merchants who registered before the auto-activation feature was implemented.
"""
import asyncio
import sys
from pathlib import Path
from datetime import date
from dateutil.relativedelta import relativedelta

# Add the app directory to the Python path
sys.path.append(str(Path(__file__).parent.parent))

from sqlalchemy import select
from app.core.database import AsyncSessionLocal
from app.models import (
    Merchant,
    MerchantSubscription,
    TariffPlan,
    SubscriptionStatus
)
from app.repositories.payment_repository import PaymentRepository


async def activate_subscriptions_for_merchants():
    """Activate subscriptions for all merchants without active subscriptions."""
    print("Starting subscription activation for merchants...")
    
    async with AsyncSessionLocal() as db:
        try:
            payment_repo = PaymentRepository(db)
            
            # Get all merchants
            merchant_stmt = select(Merchant)
            merchant_result = await db.execute(merchant_stmt)
            merchants = merchant_result.scalars().all()
            
            print(f"Found {len(merchants)} merchants")
            
            # Try to get "Start" tariff plan first
            start_tariff = await payment_repo.get_tariff_plan_by_name("Start")
            
            # If "Start" doesn't exist, try "Basic"
            if not start_tariff:
                print("'Start' tariff plan not found, trying 'Basic'...")
                start_tariff = await payment_repo.get_tariff_plan_by_name("Basic")
            
            # If still not found, get the first active plan (sorted by price)
            if not start_tariff:
                print("'Basic' tariff plan not found, getting first active plan...")
                active_plans = await payment_repo.get_active_tariff_plans()
                if not active_plans:
                    print("❌ ERROR: No active tariff plans found in database!")
                    print("Please run the seed script first to create tariff plans.")
                    return
                # Sort by price and get the cheapest plan
                active_plans.sort(key=lambda p: p.price_per_month)
                start_tariff = active_plans[0]
            
            print(f"Using tariff plan: '{start_tariff.name}' (ID: {start_tariff.id}, Price: {start_tariff.price_per_month} UZS/month)")
            
            activated_count = 0
            skipped_count = 0
            
            for merchant in merchants:
                # Check if merchant already has an active subscription
                existing_subscription = await payment_repo.get_merchant_active_subscription(merchant.id)
                
                if existing_subscription:
                    print(f"  ⏭️  Merchant {merchant.id} ({merchant.business_name}) already has an active subscription, skipping...")
                    skipped_count += 1
                    continue
                
                # Calculate dates for 2 months
                start_date = date.today()
                end_date = start_date + relativedelta(months=2)
                
                # Create subscription without payment (payment_id is None)
                subscription = MerchantSubscription(
                    merchant_id=merchant.id,
                    tariff_plan_id=start_tariff.id,
                    payment_id=None,  # No payment required for auto-activation
                    start_date=start_date,
                    end_date=end_date,
                    status=SubscriptionStatus.ACTIVE
                )
                
                db.add(subscription)
                await db.flush()
                
                print(f"  ✅ Activated '{start_tariff.name}' subscription for merchant {merchant.id} ({merchant.business_name}) until {end_date}")
                activated_count += 1
            
            # Commit all subscriptions
            await db.commit()
            
            print("\n" + "="*60)
            print(f"✅ Successfully activated {activated_count} subscriptions")
            print(f"⏭️  Skipped {skipped_count} merchants (already have active subscriptions)")
            print("="*60)
            
        except Exception as e:
            await db.rollback()
            print(f"\n❌ ERROR: Failed to activate subscriptions: {str(e)}")
            import traceback
            traceback.print_exc()
            raise


if __name__ == "__main__":
    asyncio.run(activate_subscriptions_for_merchants())

