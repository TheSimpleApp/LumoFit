#!/bin/bash

# Script to trigger a Codemagic build immediately using the API
# Usage: ./trigger_codemagic_build.sh [API_TOKEN] [APP_ID] [BRANCH]

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Triggering Codemagic build...${NC}"

# Get parameters or prompt for them
API_TOKEN=${1:-$CODEMAGIC_API_TOKEN}
APP_ID=${2:-$CODEMAGIC_APP_ID}
BRANCH=${3:-$(git branch --show-current)}
WORKFLOW_ID="ios-release"

# Check if API token is provided
if [ -z "$API_TOKEN" ]; then
    echo -e "${YELLOW}⚠️  Codemagic API token not found.${NC}"
    echo "Please provide your API token:"
    echo "  1. Get it from: https://codemagic.io/settings"
    echo "  2. Run: export CODEMAGIC_API_TOKEN='your-token'"
    echo "  3. Or pass it as first argument: ./trigger_codemagic_build.sh YOUR_TOKEN"
    exit 1
fi

# Check if App ID is provided
if [ -z "$APP_ID" ]; then
    echo -e "${YELLOW}⚠️  Codemagic App ID not found.${NC}"
    echo "Please provide your App ID:"
    echo "  1. Find it in your Codemagic dashboard URL or settings"
    echo "  2. Run: export CODEMAGIC_APP_ID='your-app-id'"
    echo "  3. Or pass it as second argument: ./trigger_codemagic_build.sh TOKEN APP_ID"
    exit 1
fi

echo -e "${BLUE}📍 Branch: ${BRANCH}${NC}"
echo -e "${BLUE}🔨 Workflow: ${WORKFLOW_ID}${NC}"
echo -e "${BLUE}📱 App ID: ${APP_ID}${NC}"

# Trigger build via API
echo -e "${BLUE}⏳ Starting build...${NC}"

RESPONSE=$(curl -s -X POST "https://api.codemagic.io/builds" \
    -H "Content-Type: application/json" \
    -H "x-auth-token: ${API_TOKEN}" \
    -d "{
        \"appId\": \"${APP_ID}\",
        \"workflowId\": \"${WORKFLOW_ID}\",
        \"branch\": \"${BRANCH}\"
    }")

# Check if build was triggered successfully
if echo "$RESPONSE" | grep -q "buildId\|id"; then
    BUILD_ID=$(echo "$RESPONSE" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4 || echo "unknown")
    echo -e "${GREEN}✅ Build triggered successfully!${NC}"
    echo -e "${GREEN}📊 Build ID: ${BUILD_ID}${NC}"
    echo -e "${BLUE}🔗 View build: https://codemagic.io/app/${APP_ID}/build/${BUILD_ID}${NC}"
else
    echo -e "${YELLOW}⚠️  Response: ${RESPONSE}${NC}"
    echo -e "${YELLOW}❌ Failed to trigger build. Please check your API token and App ID.${NC}"
    exit 1
fi
