#!/bin/bash

# Script to create dummy featured services using curl (admin endpoint)
# Usage: ./create_featured_services.sh

BASE_URL="http://195.200.29.240:8000"
ADMIN_PHONE="901234567"
ADMIN_OTP="123456"
API_BASE="${BASE_URL}/api/v1"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "=========================================="
echo "Creating Dummy Featured Services (Admin)"
echo "=========================================="
echo ""

# Step 1: Authenticate as admin
echo -e "${YELLOW}Step 1: Authenticating as admin...${NC}"
AUTH_RESPONSE=$(curl -s -X POST "${API_BASE}/auth/verify-otp" \
  -H "Content-Type: application/json" \
  -d "{
    \"phone_number\": \"${ADMIN_PHONE}\",
    \"otp_code\": \"${ADMIN_OTP}\"
  }")

ACCESS_TOKEN=$(echo $AUTH_RESPONSE | grep -o '"access_token":"[^"]*' | cut -d'"' -f4)

if [ -z "$ACCESS_TOKEN" ]; then
  echo -e "${RED}❌ Failed to authenticate as admin. Response:${NC}"
  echo "$AUTH_RESPONSE"
  exit 1
fi

echo -e "${GREEN}✅ Authenticated as admin${NC}"
echo ""

# Step 2: Get list of services
echo -e "${YELLOW}Step 2: Fetching services...${NC}"
SERVICES_RESPONSE=$(curl -s -X GET "${API_BASE}/services/?limit=50" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}")

# Extract service IDs (handle both .items[] and .services[] formats)
SERVICE_IDS=$(echo "$SERVICES_RESPONSE" | grep -o '"id":"[^"]*' | cut -d'"' -f4 | head -20)

if [ -z "$SERVICE_IDS" ]; then
  echo -e "${RED}❌ No services found${NC}"
  echo "Response: $SERVICES_RESPONSE"
  exit 1
fi

SERVICE_COUNT=$(echo "$SERVICE_IDS" | wc -l)
echo -e "${GREEN}✅ Found ${SERVICE_COUNT} services${NC}"
echo ""

# Step 3: Create featured services for first 10 services
echo -e "${YELLOW}Step 3: Creating featured services...${NC}"
echo ""

CREATED=0
FAILED=0
SKIPPED=0
COUNT=0

for SERVICE_ID in $SERVICE_IDS; do
  if [ $COUNT -ge 10 ]; then
    break
  fi
  
  COUNT=$((COUNT + 1))
  echo -e "${BLUE}[${COUNT}/10] Featuring service: ${SERVICE_ID}${NC}"
  
  # Create featured service using admin endpoint
  FEATURED_RESPONSE=$(curl -s -X POST "${API_BASE}/services/admin/feature" \
    -H "Authorization: Bearer ${ACCESS_TOKEN}" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "service_id=${SERVICE_ID}&duration_days=30&feature_type=monthly_allocation")
  
  # Check if successful (look for id field in response)
  if echo "$FEATURED_RESPONSE" | grep -q '"id"' > /dev/null 2>&1; then
    FEATURED_ID=$(echo "$FEATURED_RESPONSE" | grep -o '"id":"[^"]*' | head -1 | cut -d'"' -f4)
    echo -e "  ${GREEN}✅ Created featured service (ID: ${FEATURED_ID})${NC}"
    CREATED=$((CREATED + 1))
  else
    ERROR_MSG=$(echo "$FEATURED_RESPONSE" | grep -o '"detail":"[^"]*' | cut -d'"' -f4 | head -1)
    if [ -z "$ERROR_MSG" ]; then
      ERROR_MSG=$(echo "$FEATURED_RESPONSE" | grep -o '"message":"[^"]*' | cut -d'"' -f4 | head -1)
    fi
    if echo "$ERROR_MSG" | grep -qi "already featured" > /dev/null 2>&1; then
      echo -e "  ${YELLOW}⚠️  Service already featured${NC}"
      SKIPPED=$((SKIPPED + 1))
    else
      echo -e "  ${RED}❌ Failed: ${ERROR_MSG:-Unknown error}${NC}"
      FAILED=$((FAILED + 1))
    fi
  fi
  
  echo ""
done

echo "=========================================="
echo -e "${GREEN}✅ Created: ${CREATED} featured services${NC}"
if [ $SKIPPED -gt 0 ]; then
  echo -e "${YELLOW}⚠️  Skipped: ${SKIPPED}${NC}"
fi
if [ $FAILED -gt 0 ]; then
  echo -e "${RED}❌ Failed: ${FAILED}${NC}"
fi
echo "=========================================="

