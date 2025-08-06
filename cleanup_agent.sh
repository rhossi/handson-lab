#!/bin/bash

# Cleanup script for HandsOnLab1 agent
# Usage: ./cleanup_agent.sh [PROFILE]

PROFILE="${1:-DEFAULT}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}Cleaning up HandsOnLab1 agent and endpoint (profile: $PROFILE)...${NC}"

# Function to build base OCI command with profile
build_base_oci_command() {
    if [ "$PROFILE" = "DEFAULT" ]; then
        echo "oci"
    else
        echo "oci --profile $PROFILE"
    fi
}

# Read IDs from files
if [ -f "endpoint_id.txt" ]; then
    ENDPOINT_ID=$(cat endpoint_id.txt)
    echo -e "${YELLOW}Deleting agent endpoint...${NC}"
    
    base_cmd=$(build_base_oci_command)
    cmd="$base_cmd generative-ai-agent agent-endpoint delete \
        --agent-endpoint-id '$ENDPOINT_ID' \
        --force \
        --wait-for-state SUCCEEDED \
        --max-wait-seconds 1800"
    
    eval $cmd
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Agent endpoint deleted${NC}"
        rm -f endpoint_id.txt
    else
        echo -e "${RED}✗ Failed to delete agent endpoint${NC}"
    fi
fi

if [ -f "agent_id.txt" ]; then
    AGENT_ID=$(cat agent_id.txt)
    echo -e "${YELLOW}Deleting agent...${NC}"
    
    base_cmd=$(build_base_oci_command)
    cmd="$base_cmd generative-ai-agent agent delete \
        --agent-id '$AGENT_ID' \
        --force \
        --wait-for-state SUCCEEDED \
        --max-wait-seconds 1800"
    
    eval $cmd
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Agent deleted${NC}"
        rm -f agent_id.txt
    else
        echo -e "${RED}✗ Failed to delete agent${NC}"
    fi
fi

echo -e "${GREEN}Cleanup complete!${NC}"
