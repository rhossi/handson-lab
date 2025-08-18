#!/bin/bash

# =============================================================================
# OCI Generative AI Agent Setup Script - Simplified Version
# =============================================================================
# 
# This script creates OCI Generative AI resources and outputs all OCIDs to
# a single GENERATED_OCIDS.txt file for easy reference and cleanup.
#
# Prerequisites:
#   - OCI CLI installed and configured
#   - jq command-line JSON processor
#   - Appropriate OCI permissions for Generative AI resources
#
# Usage:
#   ./setup.sh [COMPARTMENT_ID] [REGION] [PROFILE]
#
# Examples:
#   ./setup.sh                                    # Use defaults from ~/.oci/config
#   ./setup.sh ocid1.compartment.oc1..xyz        # Specify compartment
#   ./setup.sh ocid1.compartment.oc1..xyz us-chicago-1  # Specify compartment and region
#   ./setup.sh ocid1.compartment.oc1..xyz us-chicago-1 myprofile  # Specify all parameters
#
# Output:
#   GENERATED_OCIDS.txt - Contains all created resource OCIDs
#
# =============================================================================

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Global variables
PROFILE="DEFAULT"
COMPARTMENT_ID=""
REGION=""
OCIDS_FILE="GENERATED_OCIDS.txt"
DEBUG=false

# Function to display usage
show_usage() {
    echo -e "${BLUE}OCI Generative AI Agent Setup Script${NC}"
    echo ""
    echo -e "${BLUE}Usage: $0 [COMPARTMENT_ID] [REGION] [PROFILE] [--debug]${NC}"
    echo ""
    echo -e "${YELLOW}Parameters:${NC}"
    echo "  COMPARTMENT_ID  - OCI compartment OCID (optional)"
    echo "  REGION          - OCI region (optional)"
    echo "  PROFILE         - OCI CLI profile (optional, defaults to DEFAULT)"
    echo "  --debug         - Enable debug output (optional)"
    echo ""
    echo -e "${YELLOW}Examples:${NC}"
    echo "  $0                                    # Use defaults"
    echo "  $0 ocid1.compartment.oc1..xyz        # Specify compartment"
    echo "  $0 ocid1.compartment.oc1..xyz us-chicago-1  # Specify compartment and region"
    echo "  $0 --debug                            # Enable debug mode"
    echo ""
    echo -e "${YELLOW}Output:${NC}"
    echo "  GENERATED_OCIDS.txt - Contains all created resource OCIDs"
}

# Function to debug output
debug_log() {
    if [ "$DEBUG" = true ]; then
        echo -e "${BLUE}[DEBUG] $1${NC}"
    fi
}

# Function to get OCI config value
get_oci_config_value() {
    local key="$1"
    local profile="${2:-DEFAULT}"
    local config_file="$HOME/.oci/config"
    
    if [ ! -f "$config_file" ]; then
        echo ""
        return 1
    fi
    
    awk -v profile="[$profile]" -v key="$key" '
        $0 == profile { in_section = 1; next }
        /^\[/ && in_section { in_section = 0 }
        in_section && $0 ~ "^" key "=" { 
            gsub("^" key "=", ""); 
            gsub(/^[ \t]+|[ \t]+$/, ""); 
            print; 
            exit 
        }
    ' "$config_file"
}

# Function to build base OCI command
build_oci_cmd() {
    if [ "$PROFILE" = "DEFAULT" ]; then
        echo "oci"
    else
        echo "oci --profile $PROFILE"
    fi
}

# Function to setup configuration
setup_config() {
    local cmd_compartment="$1"
    local cmd_region="$2"
    local cmd_profile="${3:-DEFAULT}"
    
    echo -e "${BLUE}Setting up configuration...${NC}"
    
    PROFILE="$cmd_profile"
    echo -e "${YELLOW}Using OCI profile: ${PROFILE}${NC}"
    
    # Determine compartment ID
    if [ -n "$cmd_compartment" ]; then
        COMPARTMENT_ID="$cmd_compartment"
    else
        COMPARTMENT_ID=$(get_oci_config_value "tenancy" "$PROFILE")
        if [ -z "$COMPARTMENT_ID" ]; then
            echo -e "${RED}Error: Could not determine compartment ID${NC}"
            echo -e "${RED}Please provide it as a command line parameter or ensure ~/.oci/config is properly configured${NC}"
            exit 1
        fi
    fi
    
    # Determine region
    if [ -n "$cmd_region" ]; then
        REGION="$cmd_region"
    else
        REGION=$(get_oci_config_value "region" "$PROFILE")
        if [ -z "$REGION" ]; then
            echo -e "${RED}Error: Could not determine region${NC}"
            echo -e "${RED}Please provide it as a command line parameter or ensure ~/.oci/config is properly configured${NC}"
            exit 1
        fi
    fi
    
    echo -e "${GREEN}Configuration:${NC}"
    echo -e "  Profile: ${PROFILE}"
    echo -e "  Compartment ID: ${COMPARTMENT_ID}"
    echo -e "  Region: ${REGION}"
    echo ""
}

# Function to check OCI CLI
check_oci_cli() {
    echo -e "${YELLOW}Checking OCI CLI configuration...${NC}"
    
    if ! command -v oci &> /dev/null; then
        echo -e "${RED}Error: OCI CLI is not installed${NC}"
        exit 1
    fi
    
    if ! command -v jq &> /dev/null; then
        echo -e "${RED}Error: jq is required but not installed${NC}"
        echo -e "${YELLOW}Install with: sudo apt-get install jq (Ubuntu/Debian) or brew install jq (macOS)${NC}"
        exit 1
    fi
    
    # Test OCI connectivity
    local base_cmd=$(build_oci_cmd)
    local test_cmd="$base_cmd iam compartment get --compartment-id $COMPARTMENT_ID --region $REGION"
    
    if ! eval $test_cmd &> /dev/null; then
        echo -e "${RED}Error: OCI CLI configuration test failed${NC}"
        echo -e "${RED}Please check your OCI CLI configuration and permissions${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✓ OCI CLI configuration validated${NC}"
}

# Function to create bucket
create_bucket() {
    echo -e "${YELLOW}Creating bucket...${NC}"
    
    local base_cmd=$(build_oci_cmd)
    local bucket_name="ai-workshop-labs-datasets"
    
    debug_log "Checking if bucket '$bucket_name' already exists..."
    
    # Check if bucket already exists
    local check_response=$(eval "$base_cmd os bucket get --bucket-name '$bucket_name' --region '$REGION'" 2>/dev/null)
    local check_exit_code=$?
    debug_log "Bucket check exit code: $check_exit_code"
    
    if [ $check_exit_code -eq 0 ]; then
        local bucket_id=$(echo "$check_response" | jq -r '.data.id' 2>/dev/null)
        debug_log "Existing bucket ID: $bucket_id"
        if [ "$bucket_id" != "null" ] && [ -n "$bucket_id" ]; then
            echo "$bucket_id" > temp_bucket_id.txt
            echo -e "${GREEN}✓ Bucket already exists: $bucket_id${NC}"
            return 0
        fi
    fi
    
    debug_log "Creating bucket '$bucket_name'..."
    debug_log "Command: $base_cmd os bucket create --compartment-id '$COMPARTMENT_ID' --name '$bucket_name' --region '$REGION' --public-access-type NoPublicAccess --storage-tier Standard"
    
    # Create bucket
    local response=$(eval "$base_cmd os bucket create \
        --compartment-id '$COMPARTMENT_ID' \
        --name '$bucket_name' \
        --region '$REGION' \
        --public-access-type NoPublicAccess \
        --storage-tier Standard" 2>&1)
    
    local exit_code=$?
    debug_log "Bucket creation exit code: $exit_code"
    debug_log "Bucket creation response: $response"
    
    if [ $exit_code -eq 0 ]; then
        # Try to extract bucket ID from JSON response
        local bucket_id=$(echo "$response" | jq -r '.data.id' 2>/dev/null)
        debug_log "Extracted bucket ID: $bucket_id"
        if [ "$bucket_id" != "null" ] && [ -n "$bucket_id" ]; then
            echo "$bucket_id" > temp_bucket_id.txt
            echo -e "${GREEN}✓ Bucket created: $bucket_id${NC}"
            return 0
        else
            echo -e "${RED}✗ Failed to extract bucket ID from response${NC}"
            echo -e "${RED}Response: $response${NC}"
            return 1
        fi
    else
        echo -e "${RED}✗ Failed to create bucket (exit code: $exit_code)${NC}"
        echo -e "${RED}Response: $response${NC}"
        return 1
    fi
}

# Function to upload file to bucket
upload_file_to_bucket() {
    echo -e "${YELLOW}Uploading file to bucket...${NC}"
    
    local base_cmd=$(build_oci_cmd)
    local bucket_name="ai-workshop-labs-datasets"
    local file_path="$(dirname $(dirname $(pwd)))/labs/datasets/TripAdvisorReviewsMultiLang.md"
    local object_name="TripAdvisorReviewsMultiLang.md"
    
    if [ ! -f "$file_path" ]; then
        echo -e "${RED}Error: File not found: $file_path${NC}"
        return 1
    fi
    
    debug_log "Uploading file '$file_path' to bucket '$bucket_name' as '$object_name'..."
    debug_log "Command: $base_cmd os object put --bucket-name '$bucket_name' --name '$object_name' --file '$file_path' --force --region '$REGION'"
    
    local response=$(eval "$base_cmd os object put \
        --bucket-name '$bucket_name' \
        --name '$object_name' \
        --file '$file_path' \
        --force \
        --region '$REGION'" 2>&1)
    
    local exit_code=$?
    debug_log "File upload exit code: $exit_code"
    debug_log "File upload response: $response"
    
    if [ $exit_code -eq 0 ]; then
        echo "$object_name" > temp_object_name.txt
        echo -e "${GREEN}✓ File uploaded: $object_name${NC}"
        return 0
    else
        echo -e "${RED}✗ Failed to upload file (exit code: $exit_code)${NC}"
        echo -e "${RED}Response: $response${NC}"
        return 1
    fi
}

# Function to create knowledge base
create_knowledge_base() {
    echo -e "${YELLOW}Creating knowledge base...${NC}"
    
    local base_cmd=$(build_oci_cmd)
    local name="Hotel_Concierge_Knowledge_Base"
    local description="Knowledge base containing TripAdvisor reviews for hotel concierge services"
    
    debug_log "Creating knowledge base '$name'..."
    debug_log "Command: $base_cmd generative-ai-agent knowledge-base create --compartment-id '$COMPARTMENT_ID' --display-name '$name' --description '$description' --index-config '{\"indexConfigType\": \"DEFAULT_INDEX_CONFIG\", \"shouldEnableHybridSearch\": true}' --region '$REGION'"
    
    local response=$(eval "$base_cmd generative-ai-agent knowledge-base create \
        --compartment-id '$COMPARTMENT_ID' \
        --display-name '$name' \
        --description '$description' \
        --index-config '{\"indexConfigType\": \"DEFAULT_INDEX_CONFIG\", \"shouldEnableHybridSearch\": true}' \
        --region '$REGION'" 2>&1)
    
    local exit_code=$?
    debug_log "Knowledge base creation exit code: $exit_code"
    debug_log "Knowledge base creation response: $response"
    
    if [ $exit_code -eq 0 ]; then
        # Try to extract knowledge base ID from JSON response
        local kb_id=$(echo "$response" | jq -r '.data.id' 2>/dev/null)
        debug_log "Extracted knowledge base ID: $kb_id"
        if [ "$kb_id" != "null" ] && [ -n "$kb_id" ]; then
            echo "$kb_id" > temp_kb_id.txt
            echo -e "${GREEN}✓ Knowledge base created: $kb_id${NC}"
            return 0
        else
            echo -e "${RED}✗ Failed to extract knowledge base ID from response${NC}"
            echo -e "${RED}Response: $response${NC}"
            return 1
        fi
    else
        echo -e "${RED}✗ Failed to create knowledge base (exit code: $exit_code)${NC}"
        echo -e "${RED}Response: $response${NC}"
        return 1
    fi
}

# Function to create data source
create_data_source() {
    echo -e "${YELLOW}Creating data source...${NC}"
    
    local base_cmd=$(build_oci_cmd)
    local kb_id=$(cat temp_kb_id.txt)
    local bucket_name="ai-workshop-labs-datasets"
    local object_name=$(cat temp_object_name.txt)
    
    # Get namespace first
    local ns_response=$(eval "$base_cmd os ns get" 2>/dev/null)
    local namespace=""
    if [ $? -eq 0 ]; then
        namespace=$(echo "$ns_response" | jq -r '.data' 2>/dev/null)
        if [ "$namespace" = "null" ] || [ -z "$namespace" ]; then
            echo -e "${RED}✗ Failed to get namespace${NC}"
            return 1
        fi
    else
        echo -e "${RED}✗ Failed to get namespace${NC}"
        return 1
    fi
    
    debug_log "Creating data source..."
    debug_log "Command: $base_cmd generative-ai-agent data-source create-object-storage-ds --compartment-id '$COMPARTMENT_ID' --knowledge-base-id '$kb_id' --display-name 'TripAdvisor Reviews Data Source' --description 'Data source for TripAdvisor reviews' --data-source-config-object-storage-prefixes '[{\"namespaceName\": \"$namespace\", \"bucketName\": \"$bucket_name\", \"prefix\": \"$object_name\"}]' --region '$REGION'"
    
    local response=$(eval "$base_cmd generative-ai-agent data-source create-object-storage-ds \
        --compartment-id '$COMPARTMENT_ID' \
        --knowledge-base-id '$kb_id' \
        --display-name 'TripAdvisor Reviews Data Source' \
        --description 'Data source for TripAdvisor reviews' \
        --data-source-config-object-storage-prefixes '[{\"namespaceName\": \"$namespace\", \"bucketName\": \"$bucket_name\", \"prefix\": \"$object_name\"}]' \
        --region '$REGION'" 2>&1)
    
    local exit_code=$?
    debug_log "Data source creation exit code: $exit_code"
    debug_log "Data source creation response: $response"
    
    if [ $exit_code -eq 0 ]; then
        # Try to extract data source ID from JSON response
        local ds_id=$(echo "$response" | jq -r '.data.id' 2>/dev/null)
        debug_log "Extracted data source ID: $ds_id"
        if [ "$ds_id" != "null" ] && [ -n "$ds_id" ]; then
            echo "$ds_id" > temp_ds_id.txt
            echo -e "${GREEN}✓ Data source created: $ds_id${NC}"
            return 0
        else
            echo -e "${RED}✗ Failed to extract data source ID from response${NC}"
            echo -e "${RED}Response: $response${NC}"
            return 1
        fi
    else
        echo -e "${RED}✗ Failed to create data source (exit code: $exit_code)${NC}"
        echo -e "${RED}Response: $response${NC}"
        return 1
    fi
}

# Function to create agent
create_agent() {
    local name="$1"
    local description="$2"
    local greeting="$3"
    local output_file="$4"
    
    echo -e "${YELLOW}Creating agent: $name...${NC}"
    
    local base_cmd=$(build_oci_cmd)
    
    # Create temporary file for welcome message to avoid shell escaping issues
    local temp_welcome_file="temp_welcome_$$.txt"
    echo "$greeting" > "$temp_welcome_file"
    
    debug_log "Creating agent '$name'..."
    debug_log "Command: $base_cmd generative-ai-agent agent create --compartment-id '$COMPARTMENT_ID' --display-name '$name' --description '$description' --welcome-message file://$temp_welcome_file --region '$REGION'"
    
    local response=$(eval "$base_cmd generative-ai-agent agent create \
        --compartment-id '$COMPARTMENT_ID' \
        --display-name '$name' \
        --description '$description' \
        --welcome-message file://$temp_welcome_file \
        --region '$REGION'" 2>&1)
    
    # Clean up temporary file
    rm -f "$temp_welcome_file"
    
    local exit_code=$?
    if [ $exit_code -eq 0 ]; then
        # Try to extract agent ID from JSON response
        local agent_id=$(echo "$response" | jq -r '.data.id' 2>/dev/null)
        if [ "$agent_id" != "null" ] && [ -n "$agent_id" ]; then
            echo "$agent_id" > "$output_file"
            echo -e "${GREEN}✓ Agent created: $agent_id${NC}"
            return 0
        else
            echo -e "${RED}✗ Failed to extract agent ID from response${NC}"
            echo -e "${RED}Response: $response${NC}"
            return 1
        fi
    else
        echo -e "${RED}✗ Failed to create agent (exit code: $exit_code)${NC}"
        echo -e "${RED}Response: $response${NC}"
        return 1
    fi
}

# Function to create RAG tool
create_rag_tool() {
    echo -e "${YELLOW}Creating RAG tool...${NC}"
    
    local base_cmd=$(build_oci_cmd)
    local agent_id=$(cat temp_agent_id.txt)
    local kb_id=$(cat temp_kb_id.txt)
    
    debug_log "Creating RAG tool..."
    debug_log "Command: $base_cmd generative-ai-agent tool create --agent-id '$agent_id' --compartment-id '$COMPARTMENT_ID' --description 'RAG tool for hotel concierge services using TripAdvisor reviews' --tool-config '{\"toolConfigType\": \"RAG_TOOL_CONFIG\", \"knowledgeBaseConfigs\": [{\"knowledgeBaseId\": \"$kb_id\"}]}' --region '$REGION'"
    
    local response=$(eval "$base_cmd generative-ai-agent tool create \
        --agent-id '$agent_id' \
        --compartment-id '$COMPARTMENT_ID' \
        --description 'RAG tool for hotel concierge services using TripAdvisor reviews' \
        --tool-config '{\"toolConfigType\": \"RAG_TOOL_CONFIG\", \"knowledgeBaseConfigs\": [{\"knowledgeBaseId\": \"$kb_id\"}]}' \
        --region '$REGION'" 2>&1)
    
    local exit_code=$?
    debug_log "RAG tool creation exit code: $exit_code"
    debug_log "RAG tool creation response: $response"
    
    if [ $exit_code -eq 0 ]; then
        # Try to extract tool ID from JSON response
        local tool_id=$(echo "$response" | jq -r '.data.id' 2>/dev/null)
        debug_log "Extracted tool ID: $tool_id"
        if [ "$tool_id" != "null" ] && [ -n "$tool_id" ]; then
            echo "$tool_id" > temp_rag_tool_id.txt
            echo -e "${GREEN}✓ RAG tool created: $tool_id${NC}"
            return 0
        else
            echo -e "${RED}✗ Failed to extract tool ID from response${NC}"
            echo -e "${RED}Response: $response${NC}"
            return 1
        fi
    else
        echo -e "${RED}✗ Failed to create RAG tool (exit code: $exit_code)${NC}"
        echo -e "${RED}Response: $response${NC}"
        return 1
    fi
}

# Function to create agent endpoint
create_agent_endpoint() {
    local agent_id_file="$1"
    local name="$2"
    local description="$3"
    local output_file="$4"
    
    echo -e "${YELLOW}Creating endpoint: $name...${NC}"
    
    local base_cmd=$(build_oci_cmd)
    local agent_id=$(cat "$agent_id_file")
    
    debug_log "Creating endpoint '$name'..."
    debug_log "Command: $base_cmd generative-ai-agent agent-endpoint create --agent-id '$agent_id' --compartment-id '$COMPARTMENT_ID' --display-name '$name' --description '$description' --region '$REGION'"
    
    local response=$(eval "$base_cmd generative-ai-agent agent-endpoint create \
        --agent-id '$agent_id' \
        --compartment-id '$COMPARTMENT_ID' \
        --display-name '$name' \
        --description '$description' \
        --region '$REGION'" 2>&1)
    
    local exit_code=$?
    if [ $exit_code -eq 0 ]; then
        # Try to extract endpoint ID from JSON response
        local endpoint_id=$(echo "$response" | jq -r '.data.id' 2>/dev/null)
        if [ "$endpoint_id" != "null" ] && [ -n "$endpoint_id" ]; then
            echo "$endpoint_id" > "$output_file"
            echo -e "${GREEN}✓ Endpoint created: $endpoint_id${NC}"
            return 0
        else
            echo -e "${RED}✗ Failed to extract endpoint ID from response${NC}"
            echo -e "${RED}Response: $response${NC}"
            return 1
        fi
    else
        echo -e "${RED}✗ Failed to create endpoint (exit code: $exit_code)${NC}"
        echo -e "${RED}Response: $response${NC}"
        return 1
    fi
}

# Function to generate OCIDs file
generate_ocids_file() {
    echo -e "${YELLOW}Generating OCIDs file...${NC}"
    
    # Read all temporary files
    local bucket_id=$(cat temp_bucket_id.txt 2>/dev/null || echo "")
    local kb_id=$(cat temp_kb_id.txt 2>/dev/null || echo "")
    local ds_id=$(cat temp_ds_id.txt 2>/dev/null || echo "")
    local rag_tool_id=$(cat temp_rag_tool_id.txt 2>/dev/null || echo "")
    local agent_id=$(cat temp_agent_id.txt 2>/dev/null || echo "")
    local agent_adk_id=$(cat temp_agent_adk_id.txt 2>/dev/null || echo "")
    local endpoint_id=$(cat temp_endpoint_id.txt 2>/dev/null || echo "")
    local endpoint_adk_id=$(cat temp_endpoint_adk_id.txt 2>/dev/null || echo "")
    
    # Create the OCIDs file
    cat > "$OCIDS_FILE" << EOF
# this info will be used by ADK agent
KNOWLEDGEBASE_ID=$kb_id
HOTEL_CONCIERGE_AGENT_ENDPOINT_ID=$endpoint_adk_id

# this other info will be used by the script to cleanup resources
HOTEL_CONCIERGE_AGENT_ID=$agent_id
HOTEL_CONCIERGE_AGENT_ADK_ID=$agent_adk_id
KNOWLEDGEBASE_ID=$kb_id
BUCKET_ID=$bucket_id
EOF
    
    echo -e "${GREEN}✓ OCIDs file generated: $OCIDS_FILE${NC}"
}

# Function to cleanup temporary files
cleanup_temp_files() {
    rm -f temp_*.txt
}

# Function to display summary
display_summary() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}Setup Summary${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
    echo -e "${GREEN}All resources created successfully!${NC}"
    echo ""
    echo -e "${YELLOW}Created Resources:${NC}"
    echo "  - Bucket: ai-workshop-labs-datasets"
    echo "  - Knowledge Base: Hotel_Concierge_Knowledge_Base"
    echo "  - Data Source: TripAdvisor Reviews Data Source"
    echo "  - RAG Tool: Hotel_Concierge_RAG_Tool"
    echo "  - Agent: Hotel_Concierge_Agent"
    echo "  - Agent ADK: Hotel_Concierge_Agent_ADK"
    echo "  - Endpoint: Hotel_Concierge_Agent-endpoint"
    echo "  - Endpoint ADK: Hotel_Concierge_Agent_ADK-endpoint"
    echo ""
    echo -e "${YELLOW}Output File:${NC}"
    echo "  - $OCIDS_FILE (contains all OCIDs)"
    echo ""
    echo -e "${YELLOW}Next Steps:${NC}"
    echo "  - Use the OCIDs in $OCIDS_FILE for your applications"
    echo "  - The ADK agent endpoint ID is: HOTEL_CONCIERGE_AGENT_ENDPOINT_ID"
    echo "  - Use the cleanup script to remove resources when done"
}

# Main function
main() {
    # Parse command line arguments
    local args=("$@")
    local compartment_id=""
    local region=""
    local profile=""
    
    for arg in "${args[@]}"; do
        case $arg in
            -h|--help)
                show_usage
                exit 0
                ;;
            --debug)
                DEBUG=true
                ;;
            *)
                if [ -z "$compartment_id" ]; then
                    compartment_id="$arg"
                elif [ -z "$region" ]; then
                    region="$arg"
                elif [ -z "$profile" ]; then
                    profile="$arg"
                fi
                ;;
        esac
    done
    
    debug_log "Arguments: compartment_id=$compartment_id, region=$region, profile=$profile, debug=$DEBUG"
    
    # Setup configuration
    setup_config "$compartment_id" "$region" "$profile"
    
    # Check OCI CLI
    check_oci_cli
    
    # Create resources
    if create_bucket && \
       upload_file_to_bucket && \
       create_knowledge_base && \
       create_data_source && \
       create_agent "Hotel_Concierge_Agent" "Hotel Concierge Agent for basic interactions" "Hello! I'm your Hotel Concierge Agent. How can I assist you with your stay today?" "temp_agent_id.txt" && \
       create_rag_tool && \
       create_agent_endpoint "temp_agent_id.txt" "Hotel_Concierge_Agent-endpoint" "Endpoint for Hotel Concierge Agent" "temp_endpoint_id.txt" && \
       create_agent "Hotel_Concierge_Agent_ADK" "Hotel Concierge Agent for ADK development" "Hello! I'm your Hotel Concierge Agent for ADK development. I can help you with advanced hotel services and tools." "temp_agent_adk_id.txt" && \
       create_agent_endpoint "temp_agent_adk_id.txt" "Hotel_Concierge_Agent_ADK-endpoint" "Endpoint for Hotel Concierge Agent ADK" "temp_endpoint_adk_id.txt"; then
        
        # Generate OCIDs file
        generate_ocids_file
        
        # Display summary
        display_summary
        
        # Cleanup temporary files
        cleanup_temp_files
        
        echo -e "${GREEN}🎉 Setup completed successfully!${NC}"
    else
        echo -e "${RED}Setup failed. Please check the error messages above.${NC}"
        cleanup_temp_files
        exit 1
    fi
}

# Execute main function
main "$@"