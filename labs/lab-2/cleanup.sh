#!/bin/bash

# =============================================================================
# OCI Generative AI Agent Cleanup Script - Enhanced Version
# =============================================================================
# 
# This script cleans up all OCI Generative AI resources created by the setup script.
# It reads OCIDs from the GENERATED_OCIDS.txt file and deletes resources in the
# correct dependency order: endpoints -> tools -> agents -> knowledge base -> bucket
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

# Function to wait for work request to complete
wait_for_work_request() {
    local work_request_id="$1"
    local base_cmd="$2"
    local max_wait=1800
    local wait_interval=30
    local elapsed=0
    
    echo -e "${YELLOW}Waiting for work request to complete...${NC}"
    
    while [ $elapsed -lt $max_wait ]; do
        local status=$(eval "$base_cmd generative-ai-agent work-request get --work-request-id '$work_request_id'" 2>/dev/null | jq -r '.data.status' 2>/dev/null)
        
        case $status in
            "SUCCEEDED")
                echo -e "${GREEN}✓ Work request completed successfully${NC}"
                return 0
                ;;
            "FAILED"|"CANCELED")
                echo -e "${RED}✗ Work request failed with status: $status${NC}"
                return 1
                ;;
            "ACCEPTED"|"IN_PROGRESS"|"WAITING"|"NEEDS_ATTENTION"|"CANCELING")
                echo -e "${YELLOW}Work request status: $status (elapsed: ${elapsed}s)${NC}"
                sleep $wait_interval
                elapsed=$((elapsed + wait_interval))
                ;;
            *)
                echo -e "${YELLOW}Unknown work request status: $status${NC}"
                sleep $wait_interval
                elapsed=$((elapsed + wait_interval))
                ;;
        esac
    done
    
    echo -e "${RED}✗ Work request timed out after ${max_wait}s${NC}"
    return 1
}

# Function to delete agent endpoints
delete_agent_endpoints() {
    local agent_id="$1"
    local base_cmd="$2"
    
    echo -e "${YELLOW}Listing endpoints for agent: $agent_id${NC}"
    
    # List endpoints for the agent
    local endpoints=$(eval "$base_cmd generative-ai-agent agent-endpoint list --agent-id '$agent_id'" 2>/dev/null | jq -r '.data[] | .id' 2>/dev/null)
    
    if [ -n "$endpoints" ]; then
        echo "$endpoints" | while read -r endpoint_id; do
            if [ -n "$endpoint_id" ] && [ "$endpoint_id" != "null" ]; then
                echo -e "${YELLOW}Deleting endpoint: $endpoint_id${NC}"
                
                # Delete endpoint and wait for completion
                local delete_response=$(eval "$base_cmd generative-ai-agent agent-endpoint delete --agent-endpoint-id '$endpoint_id' --force" 2>&1)
                local work_request_id=$(echo "$delete_response" | jq -r '.data.id' 2>/dev/null)
                
                if [ -n "$work_request_id" ] && [ "$work_request_id" != "null" ]; then
                    wait_for_work_request "$work_request_id" "$base_cmd"
                else
                    echo -e "${GREEN}✓ Endpoint deleted immediately${NC}"
                fi
            fi
        done
    else
        echo -e "${YELLOW}No endpoints found for agent${NC}"
    fi
}

# Function to delete agent tools
delete_agent_tools() {
    local agent_id="$1"
    local base_cmd="$2"
    
    echo -e "${YELLOW}Listing tools for agent: $agent_id${NC}"
    
    # List tools for the agent
    local tools=$(eval "$base_cmd generative-ai-agent tool list --agent-id '$agent_id'" 2>/dev/null | jq -r '.data[] | .id' 2>/dev/null)
    
    if [ -n "$tools" ]; then
        echo "$tools" | while read -r tool_id; do
            if [ -n "$tool_id" ] && [ "$tool_id" != "null" ]; then
                echo -e "${YELLOW}Deleting tool: $tool_id${NC}"
                
                # Delete tool and wait for completion
                local delete_response=$(eval "$base_cmd generative-ai-agent tool delete --tool-id '$tool_id' --force" 2>&1)
                local work_request_id=$(echo "$delete_response" | jq -r '.data.id' 2>/dev/null)
                
                if [ -n "$work_request_id" ] && [ "$work_request_id" != "null" ]; then
                    wait_for_work_request "$work_request_id" "$base_cmd"
                else
                    echo -e "${GREEN}✓ Tool deleted immediately${NC}"
                fi
            fi
        done
    else
        echo -e "${YELLOW}No tools found for agent${NC}"
    fi
}

# Function to delete agent
delete_agent() {
    local agent_id="$1"
    local base_cmd="$2"
    
    echo -e "${YELLOW}Deleting agent: $agent_id${NC}"
    
    # Delete agent and wait for completion
    local delete_response=$(eval "$base_cmd generative-ai-agent agent delete --agent-id '$agent_id' --force" 2>&1)
    local work_request_id=$(echo "$delete_response" | jq -r '.data.id' 2>/dev/null)
    
    if [ -n "$work_request_id" ] && [ "$work_request_id" != "null" ]; then
        wait_for_work_request "$work_request_id" "$base_cmd"
    else
        echo -e "${GREEN}✓ Agent deleted immediately${NC}"
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

# Get agent IDs from the OCIDs file
AGENT_ID=$(get_ocid "HOTEL_CONCIERGE_AGENT_ID")
AGENT_ADK_ID=$(get_ocid "HOTEL_CONCIERGE_AGENT_ADK_ID")

# Clean up agents in dependency order
if [ -n "$AGENT_ID" ]; then
    CLEANUP_PERFORMED=true
    echo -e "${YELLOW}Cleaning up Hotel Concierge Agent: $AGENT_ID${NC}"
    
    # Delete endpoints first
    delete_agent_endpoints "$AGENT_ID" "$base_cmd"
    
    # Delete tools
    delete_agent_tools "$AGENT_ID" "$base_cmd"
    
    # Delete agent
    delete_agent "$AGENT_ID" "$base_cmd"
fi

if [ -n "$AGENT_ADK_ID" ]; then
    CLEANUP_PERFORMED=true
    echo -e "${YELLOW}Cleaning up Hotel Concierge ADK Agent: $AGENT_ADK_ID${NC}"
    
    # Delete endpoints first
    delete_agent_endpoints "$AGENT_ADK_ID" "$base_cmd"
    
    # Delete tools
    delete_agent_tools "$AGENT_ADK_ID" "$base_cmd"
    
    # Delete agent
    delete_agent "$AGENT_ADK_ID" "$base_cmd"
fi

# Clean up knowledge base
KB_ID=$(get_ocid "KNOWLEDGEBASE_ID")
if [ -n "$KB_ID" ]; then
    CLEANUP_PERFORMED=true
    echo -e "${YELLOW}Deleting knowledge base: $KB_ID${NC}"
    
    # Delete knowledge base and wait for completion
    local delete_response=$(eval "$base_cmd generative-ai-agent knowledge-base delete --knowledge-base-id '$KB_ID' --force" 2>&1)
    local work_request_id=$(echo "$delete_response" | jq -r '.data.id' 2>/dev/null)
    
    if [ -n "$work_request_id" ] && [ "$work_request_id" != "null" ]; then
        wait_for_work_request "$work_request_id" "$base_cmd"
    else
        echo -e "${GREEN}✓ Knowledge base deleted immediately${NC}"
    fi
fi

# Clean up bucket
BUCKET_ID=$(get_ocid "BUCKET_ID")
if [ -n "$BUCKET_ID" ]; then
    CLEANUP_PERFORMED=true
    echo -e "${YELLOW}Deleting bucket and contents...${NC}"
    
    # Delete all objects in the bucket first
    echo -e "${YELLOW}Deleting objects from bucket...${NC}"
    eval "$base_cmd os object bulk-delete --bucket-name 'ai-workshop-labs-datasets' --force" 2>/dev/null
    
    # Delete the bucket
    if eval "$base_cmd os bucket delete --bucket-name 'ai-workshop-labs-datasets' --force" 2>/dev/null; then
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
