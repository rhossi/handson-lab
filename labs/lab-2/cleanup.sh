#!/bin/bash

# Cleanup script for Hotel Concierge agents
# Usage: ./cleanup.sh [PROFILE]

PROFILE="${1:-DEFAULT}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${YELLOW}Cleaning up Hotel Concierge agents and endpoints (profile: $PROFILE)...${NC}"

# Track if any cleanup operations were performed
CLEANUP_PERFORMED=false

# Function to build base OCI command with profile
build_base_oci_command() {
    if [ "$PROFILE" = "DEFAULT" ]; then
        echo "oci"
    else
        echo "oci --profile $PROFILE"
    fi
}

# Clean up first agent endpoint (Hotel_Concierge_Agent)
if [ -f "hotel_concierge_endpoint_id.txt" ]; then
    CLEANUP_PERFORMED=true
    ENDPOINT_ID=$(cat hotel_concierge_endpoint_id.txt)
    echo -e "${YELLOW}Deleting Hotel Concierge agent endpoint...${NC}"
    
    base_cmd=$(build_base_oci_command)
    cmd="$base_cmd generative-ai-agent agent-endpoint delete \
        --agent-endpoint-id '$ENDPOINT_ID' \
        --force \
        --wait-for-state DELETED \
        --max-wait-seconds 1800"
    
    eval $cmd
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Hotel Concierge agent endpoint deleted${NC}"
        rm -f hotel_concierge_endpoint_id.txt
    else
        echo -e "${RED}✗ Failed to delete Hotel Concierge agent endpoint${NC}"
    fi
else
    echo -e "${BLUE}⚠ No Hotel Concierge agent endpoint ID file found (hotel_concierge_endpoint_id.txt)${NC}"
fi

# Clean up second agent endpoint (Hotel_Concierge_Agent_ADK)
if [ -f "hotel_concierge_adk_endpoint_id.txt" ]; then
    CLEANUP_PERFORMED=true
    ENDPOINT_ID=$(cat hotel_concierge_adk_endpoint_id.txt)
    echo -e "${YELLOW}Deleting Hotel Concierge ADK agent endpoint...${NC}"
    
    base_cmd=$(build_base_oci_command)
    cmd="$base_cmd generative-ai-agent agent-endpoint delete \
        --agent-endpoint-id '$ENDPOINT_ID' \
        --force \
        --wait-for-state DELETED \
        --max-wait-seconds 1800"
    
    eval $cmd
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Hotel Concierge ADK agent endpoint deleted${NC}"
        rm -f hotel_concierge_adk_endpoint_id.txt
    else
        echo -e "${RED}✗ Failed to delete Hotel Concierge ADK agent endpoint${NC}"
    fi
else
    echo -e "${BLUE}⚠ No Hotel Concierge ADK agent endpoint ID file found (hotel_concierge_adk_endpoint_id.txt)${NC}"
fi

# Clean up first agent (Hotel_Concierge_Agent)
if [ -f "hotel_concierge_agent_id.txt" ]; then
    CLEANUP_PERFORMED=true
    AGENT_ID=$(cat hotel_concierge_agent_id.txt)
    echo -e "${YELLOW}Deleting Hotel Concierge agent...${NC}"
    
    base_cmd=$(build_base_oci_command)
    cmd="$base_cmd generative-ai-agent agent delete \
        --agent-id '$AGENT_ID' \
        --force \
        --wait-for-state DELETED \
        --max-wait-seconds 1800"
    
    eval $cmd
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Hotel Concierge agent deleted${NC}"
        rm -f hotel_concierge_agent_id.txt
    else
        echo -e "${RED}✗ Failed to delete Hotel Concierge agent${NC}"
    fi
else
    echo -e "${BLUE}⚠ No Hotel Concierge agent ID file found (hotel_concierge_agent_id.txt)${NC}"
fi

# Clean up second agent (Hotel_Concierge_Agent_ADK)
if [ -f "hotel_concierge_agent_adk_id.txt" ]; then
    CLEANUP_PERFORMED=true
    AGENT_ID=$(cat hotel_concierge_agent_adk_id.txt)
    echo -e "${YELLOW}Deleting Hotel Concierge ADK agent...${NC}"
    
    base_cmd=$(build_base_oci_command)
    cmd="$base_cmd generative-ai-agent agent delete \
        --agent-id '$AGENT_ID' \
        --force \
        --wait-for-state DELETED \
        --max-wait-seconds 1800"
    
    eval $cmd
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Hotel Concierge ADK agent deleted${NC}"
        rm -f hotel_concierge_agent_adk_id.txt
    else
        echo -e "${RED}✗ Failed to delete Hotel Concierge ADK agent${NC}"
    fi
else
    echo -e "${BLUE}⚠ No Hotel Concierge ADK agent ID file found (hotel_concierge_agent_adk_id.txt)${NC}"
fi

# Provide appropriate final message based on whether cleanup was performed
if [ "$CLEANUP_PERFORMED" = true ]; then
    echo -e "${GREEN}Cleanup complete!${NC}"
else
    echo -e "${YELLOW}No cleanup performed - no agent or endpoint ID files were found.${NC}"
    echo -e "${YELLOW}Make sure you're running this script from the directory where the setup script was executed.${NC}"
fi
