#!/bin/bash

# =============================================================================
# OCI Generative AI Agent Cleanup Script - Simplified Version
# =============================================================================
# 
# This script cleans up all OCI Generative AI resources created by the setup script.
# It reads OCIDs from the GENERATED_OCIDS.txt file and deletes resources in the
# correct dependency order.
#
# Usage: ./cleanup.sh [PROFILE]
#
# =============================================================================

PROFILE="${1:-DEFAULT}"
OCIDS_FILE="GENERATED_OCIDS.txt"

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${YELLOW}Cleaning up OCI Generative AI resources (profile: $PROFILE)...${NC}"

# Function to build base OCI command with profile
build_base_oci_command() {
    if [ "$PROFILE" = "DEFAULT" ]; then
        echo "oci"
    else
        echo "oci --profile $PROFILE"
    fi
}

# Function to read OCID from GENERATED_OCIDS.txt
get_ocid() {
    local key="$1"
    if [ -f "$OCIDS_FILE" ]; then
        grep "^$key=" "$OCIDS_FILE" | cut -d'=' -f2
    else
        echo ""
    fi
}

# Check if OCIDs file exists
if [ ! -f "$OCIDS_FILE" ]; then
    echo -e "${RED}Error: $OCIDS_FILE not found${NC}"
    echo -e "${YELLOW}Make sure you're running this script from the directory where the setup script was executed.${NC}"
    exit 1
fi

# Track if any cleanup operations were performed
CLEANUP_PERFORMED=false
base_cmd=$(build_base_oci_command)

# Clean up agent endpoints first (dependency order)
ENDPOINT_ID=$(get_ocid "HOTEL_CONCIERGE_AGENT_ENDPOINT_ID")
if [ -n "$ENDPOINT_ID" ]; then
    CLEANUP_PERFORMED=true
    echo -e "${YELLOW}Deleting Hotel Concierge ADK agent endpoint...${NC}"
    
    cmd="$base_cmd generative-ai-agent agent-endpoint delete \
        --agent-endpoint-id '$ENDPOINT_ID' \
        --force \
        --wait-for-state SUCCEEDED \
        --max-wait-seconds 1800"
    
    if eval $cmd; then
        echo -e "${GREEN}✓ Hotel Concierge ADK agent endpoint deleted${NC}"
    else
        echo -e "${RED}✗ Failed to delete Hotel Concierge ADK agent endpoint${NC}"
    fi
fi

# Clean up agents
AGENT_ID=$(get_ocid "HOTEL_CONCIERGE_AGENT_ID")
if [ -n "$AGENT_ID" ]; then
    CLEANUP_PERFORMED=true
    echo -e "${YELLOW}Deleting Hotel Concierge agent...${NC}"
    
    cmd="$base_cmd generative-ai-agent agent delete \
        --agent-id '$AGENT_ID' \
        --force \
        --wait-for-state SUCCEEDED \
        --max-wait-seconds 1800"
    
    if eval $cmd; then
        echo -e "${GREEN}✓ Hotel Concierge agent deleted${NC}"
    else
        echo -e "${RED}✗ Failed to delete Hotel Concierge agent${NC}"
    fi
fi

AGENT_ADK_ID=$(get_ocid "HOTEL_CONCIERGE_AGENT_ADK_ID")
if [ -n "$AGENT_ADK_ID" ]; then
    CLEANUP_PERFORMED=true
    echo -e "${YELLOW}Deleting Hotel Concierge ADK agent...${NC}"
    
    cmd="$base_cmd generative-ai-agent agent delete \
        --agent-id '$AGENT_ADK_ID' \
        --force \
        --wait-for-state SUCCEEDED \
        --max-wait-seconds 1800"
    
    if eval $cmd; then
        echo -e "${GREEN}✓ Hotel Concierge ADK agent deleted${NC}"
    else
        echo -e "${RED}✗ Failed to delete Hotel Concierge ADK agent${NC}"
    fi
fi

# Clean up knowledge base
KB_ID=$(get_ocid "KNOWLEDGEBASE_ID")
if [ -n "$KB_ID" ]; then
    CLEANUP_PERFORMED=true
    echo -e "${YELLOW}Deleting knowledge base...${NC}"
    
    cmd="$base_cmd generative-ai-agent knowledge-base delete \
        --knowledge-base-id '$KB_ID' \
        --force \
        --wait-for-state SUCCEEDED \
        --max-wait-seconds 1800"
    
    if eval $cmd; then
        echo -e "${GREEN}✓ Knowledge base deleted${NC}"
    else
        echo -e "${RED}✗ Failed to delete knowledge base${NC}"
    fi
fi

# Clean up bucket
BUCKET_ID=$(get_ocid "BUCKET_ID")
if [ -n "$BUCKET_ID" ]; then
    CLEANUP_PERFORMED=true
    echo -e "${YELLOW}Deleting bucket and contents...${NC}"
    
    # Delete all objects in the bucket first
    echo -e "${YELLOW}Deleting objects from bucket...${NC}"
    cmd="$base_cmd os object bulk-delete --bucket-name 'ai-workshop-labs-datasets' --force"
    eval $cmd
    
    # Delete the bucket
    cmd="$base_cmd os bucket delete --bucket-name 'ai-workshop-labs-datasets' --force"
    if eval $cmd; then
        echo -e "${GREEN}✓ Bucket deleted${NC}"
    else
        echo -e "${RED}✗ Failed to delete bucket${NC}"
    fi
fi

# Clean up OCIDs file
if [ -f "$OCIDS_FILE" ]; then
    rm -f "$OCIDS_FILE"
    echo -e "${GREEN}✓ OCIDs file removed${NC}"
fi

# Provide appropriate final message
if [ "$CLEANUP_PERFORMED" = true ]; then
    echo -e "${GREEN}Cleanup complete!${NC}"
else
    echo -e "${YELLOW}No cleanup performed - no valid OCIDs found in $OCIDS_FILE.${NC}"
fi
