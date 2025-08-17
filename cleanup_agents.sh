#!/bin/bash

# Cleanup script for Hotel Concierge agents and related resources
# Usage: ./cleanup_agents.sh [PROFILE]

PROFILE="${1:-DEFAULT}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}Cleaning up Hotel Concierge agents, endpoints, and related resources (profile: $PROFILE)...${NC}"

# Function to build base OCI command with profile
build_base_oci_command() {
    if [ "$PROFILE" = "DEFAULT" ]; then
        echo "oci"
    else
        echo "oci --profile $PROFILE"
    fi
}

# Clean up first agent endpoint
if [ -f "hotel_concierge_endpoint_id.txt" ]; then
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
fi

# Clean up second agent endpoint
if [ -f "hotel_concierge_adk_endpoint_id.txt" ]; then
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
fi

# Clean up first agent
if [ -f "hotel_concierge_agent_id.txt" ]; then
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
fi

# Clean up second agent
if [ -f "hotel_concierge_agent_adk_id.txt" ]; then
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
fi

# Clean up RAG tool
if [ -f "hotel_concierge_rag_tool_id.txt" ]; then
    TOOL_ID=$(cat hotel_concierge_rag_tool_id.txt)
    echo -e "${YELLOW}Deleting Hotel Concierge RAG tool...${NC}"
    
    base_cmd=$(build_base_oci_command)
    cmd="$base_cmd generative-ai-agent tool delete \
        --tool-id '$TOOL_ID' \
        --force \
        --wait-for-state DELETED \
        --max-wait-seconds 1800"
    
    eval $cmd
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Hotel Concierge RAG tool deleted${NC}"
        rm -f hotel_concierge_rag_tool_id.txt
    else
        echo -e "${RED}✗ Failed to delete Hotel Concierge RAG tool${NC}"
    fi
fi

# Clean up RAG tool configuration file
if [ -f "hotel_concierge_rag_config.json" ]; then
    echo -e "${YELLOW}Removing RAG tool configuration file...${NC}"
    rm -f hotel_concierge_rag_config.json
    echo -e "${GREEN}✓ RAG tool configuration file removed${NC}"
fi

# Clean up data source
if [ -f "hotel_concierge_ds_id.txt" ]; then
    DS_ID=$(cat hotel_concierge_ds_id.txt)
    echo -e "${YELLOW}Deleting Hotel Concierge data source...${NC}"
    
    base_cmd=$(build_base_oci_command)
    cmd="$base_cmd generative-ai-agent data-source delete \
        --data-source-id '$DS_ID' \
        --force \
        --wait-for-state DELETED \
        --max-wait-seconds 1800"
    
    eval $cmd
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Hotel Concierge data source deleted${NC}"
        rm -f hotel_concierge_ds_id.txt
    else
        echo -e "${RED}✗ Failed to delete Hotel Concierge data source${NC}"
    fi
fi

# Clean up knowledge base
if [ -f "hotel_concierge_kb_id.txt" ]; then
    KB_ID=$(cat hotel_concierge_kb_id.txt)
    echo -e "${YELLOW}Deleting Hotel Concierge knowledge base...${NC}"
    
    base_cmd=$(build_base_oci_command)
    cmd="$base_cmd generative-ai-agent knowledge-base delete \
        --knowledge-base-id '$KB_ID' \
        --force \
        --wait-for-state DELETED \
        --max-wait-seconds 1800"
    
    eval $cmd
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Hotel Concierge knowledge base deleted${NC}"
        rm -f hotel_concierge_kb_id.txt
    else
        echo -e "${RED}✗ Failed to delete Hotel Concierge knowledge base${NC}"
    fi
fi

# Clean up bucket (delete all objects first)
if [ -f "hotel_concierge_bucket_id.txt" ]; then
    BUCKET_ID=$(cat hotel_concierge_bucket_id.txt)
    echo -e "${YELLOW}Deleting Hotel Concierge bucket and contents...${NC}"
    
    base_cmd=$(build_base_oci_command)
    
    # Delete all objects in the bucket first
    echo -e "${YELLOW}Deleting objects from bucket...${NC}"
    cmd="$base_cmd os object bulk-delete --bucket-name 'ai-workshop-labs-datasets' --force"
    eval $cmd
    
    # Delete the bucket
    cmd="$base_cmd os bucket delete --bucket-name 'ai-workshop-labs-datasets' --force"
    eval $cmd
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Hotel Concierge bucket deleted${NC}"
        rm -f hotel_concierge_bucket_id.txt
    else
        echo -e "${RED}✗ Failed to delete Hotel Concierge bucket${NC}"
    fi
fi

# Clean up temporary files
rm -f tripadvisor_reviews_object_name.txt

echo -e "${GREEN}Cleanup complete!${NC}"
