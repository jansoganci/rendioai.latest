#!/bin/bash

# Get Test Data Script
# This script helps retrieve USER_ID, THEME_ID, and other test data from Supabase

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔍 Getting Test Data from Supabase${NC}\n"

# Configuration
SUPABASE_URL="https://ojcnjxzctnwbmupggoxq.supabase.co"
SUPABASE_PROJECT_REF="ojcnjxzctnwbmupggoxq"

echo -e "${YELLOW}Note: This script requires Supabase CLI to be installed and configured.${NC}\n"
echo -e "${YELLOW}If you don't have Supabase CLI, use the SQL queries below in Supabase Dashboard SQL Editor.${NC}\n"

# Check if supabase CLI is available
if ! command -v supabase &> /dev/null; then
    echo -e "${YELLOW}⚠️  Supabase CLI not found.${NC}"
    echo -e "${YELLOW}Please run these SQL queries in Supabase Dashboard → SQL Editor:${NC}\n"
    
    echo -e "${GREEN}SQL Queries:${NC}"
    echo "----------------------------------------"
    echo ""
    echo "-- Get USER_ID"
    echo "SELECT id, credits_remaining FROM users WHERE credits_remaining > 0 LIMIT 1;"
    echo ""
    echo "-- Get THEME_ID"
    echo "SELECT id, name FROM themes WHERE is_available = true LIMIT 1;"
    echo ""
    echo "-- Verify active model"
    echo "SELECT id, name, provider_model_id, pricing_type, base_price"
    echo "FROM models"
    echo "WHERE is_active = true AND is_available = true;"
    echo ""
    echo "----------------------------------------"
    echo ""
    echo -e "${YELLOW}To get ANON_KEY:${NC}"
    echo "1. Go to: https://supabase.com/dashboard"
    echo "2. Select project: $SUPABASE_PROJECT_REF"
    echo "3. Navigate to: Project Settings → API"
    echo "4. Copy the 'anon' key (public key)"
    echo ""
    exit 0
fi

# Check if linked to project
if ! supabase projects list &> /dev/null; then
    echo -e "${YELLOW}⚠️  Not logged in to Supabase CLI${NC}"
    echo -e "${YELLOW}Run: supabase login${NC}\n"
    exit 1
fi

echo -e "${GREEN}✅ Supabase CLI found${NC}\n"

# Get USER_ID
echo -e "${BLUE}1. Getting USER_ID...${NC}"
USER_QUERY="SELECT id, credits_remaining FROM users WHERE credits_remaining > 0 LIMIT 1;"
echo "Query: $USER_QUERY"
echo ""

# Note: This requires supabase db execute or direct SQL access
# For now, we'll provide the SQL and instructions

echo -e "${YELLOW}To execute via Supabase CLI:${NC}"
echo "supabase db execute --query \"$USER_QUERY\""
echo ""

# Get THEME_ID
echo -e "${BLUE}2. Getting THEME_ID...${NC}"
THEME_QUERY="SELECT id, name FROM themes WHERE is_available = true LIMIT 1;"
echo "Query: $THEME_QUERY"
echo ""

echo -e "${YELLOW}To execute via Supabase CLI:${NC}"
echo "supabase db execute --query \"$THEME_QUERY\""
echo ""

# Get ANON_KEY info
echo -e "${BLUE}3. Getting ANON_KEY...${NC}"
echo -e "${YELLOW}ANON_KEY must be retrieved from Supabase Dashboard:${NC}"
echo "1. Go to: https://supabase.com/dashboard"
echo "2. Select project: $SUPABASE_PROJECT_REF"
echo "3. Navigate to: Project Settings → API"
echo "4. Copy the 'anon' key (public key)"
echo ""

# Summary
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}📋 Test Data Summary${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${YELLOW}Required Information:${NC}"
echo "  • USER_ID: [Run SQL query above]"
echo "  • THEME_ID: [Run SQL query above]"
echo "  • ANON_KEY: [Get from Dashboard]"
echo ""
echo -e "${YELLOW}Optional (has defaults):${NC}"
echo "  • PROMPT: Any text (e.g., 'A beautiful sunset')"
echo "  • IMAGE_URL: https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800&h=600&fit=crop"
echo "  • SETTINGS: { duration: 4, resolution: 'auto', aspect_ratio: 'auto' }"
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

