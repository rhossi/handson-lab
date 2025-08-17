#!/bin/bash

# =============================================================================
# OCI Generative AI Agent Setup Script - HandsOnLab2
# =============================================================================
# 
# This script automates the creation of OCI Generative AI resources with the
# following features:
#   - Creates an OCI bucket for storing knowledge base files
#   - Uploads TripAdvisor reviews markdown file to the bucket
#   - Creates a knowledge base with the uploaded file
#   - Creates a RAG tool using the knowledge base
#   - Creates a Generative AI Agent named "Hotel_Concierge_Agent" (without tools)
#   - Creates a Generative AI Agent named "Hotel_Concierge_Agent_ADK" (for ADK)
#   - Creates endpoints for both agents with security features disabled
#   - Configures session timeout and content moderation settings
#   - Handles work requests and asynchronous operations
#   - Provides comprehensive error handling and debugging
#   - Creates cleanup scripts for resource management
#
# Prerequisites:
#   - OCI CLI installed and configured
#   - jq command-line JSON processor
#   - Appropriate OCI permissions for Generative AI resources
#
# Usage:
#   ./handson_lab2_setup.sh [COMPARTMENT_ID] [REGION] [PROFILE]
#
# Examples:
#   ./handson_lab2_setup.sh                                    # Use defaults from ~/.oci/config
#   ./handson_lab2_setup.sh ocid1.compartment.oc1..xyz        # Specify compartment
#   ./handson_lab2_setup.sh ocid1.compartment.oc1..xyz us-chicago-1  # Specify compartment and region
#   ./handson_lab2_setup.sh ocid1.compartment.oc1..xyz us-chicago-1 myprofile  # Specify all parameters
#
# Supported Regions for Generative AI Agents:
#   - us-chicago-1
#   - eu-frankfurt-1
#   - ap-osaka-1
#
# Output Files:
#   hotel_concierge_bucket_id.txt: Contains the bucket ID
#   hotel_concierge_kb_id.txt: Contains the knowledge base ID
#   hotel_concierge_rag_tool_id.txt: Contains the RAG tool ID
#   hotel_concierge_agent_id.txt: Contains the first agent ID
#   hotel_concierge_agent_adk_id.txt: Contains the second agent ID
#   hotel_concierge_endpoint_id.txt: Contains the first endpoint ID
#   hotel_concierge_adk_endpoint_id.txt: Contains the second endpoint ID
#   tripadvisor_reviews_object_name.txt: Contains the uploaded object name
#   cleanup_agents.sh: Script to clean up created resources
#
# Author: AI Workshop Demo
# Version: 2.0
# =============================================================================

# =============================================================================
# COLOR DEFINITIONS FOR OUTPUT FORMATTING
# =============================================================================
# These ANSI color codes are used throughout the script to provide
# visual feedback and improve readability of output messages
RED='\033[0;31m'      # Red for errors and warnings
GREEN='\033[0;32m'    # Green for success messages
YELLOW='\033[1;33m'   # Yellow for informational messages and prompts
BLUE='\033[0;34m'     # Blue for section headers and debug info
NC='\033[0m'          # No Color - reset to default terminal color

# =============================================================================
# USAGE AND HELP FUNCTIONS
# =============================================================================

# Function to display script usage information and examples
# This function provides comprehensive help information including:
# - Command line parameter descriptions
# - Usage examples for different scenarios
# - Supported regions for Generative AI Agents
# - Prerequisites and requirements
show_usage() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}OCI Generative AI Agent Setup Script - Lab 2${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
    echo -e "${BLUE}Usage: $0 [COMPARTMENT_ID] [REGION] [PROFILE]${NC}"
    echo ""
    echo -e "${YELLOW}Parameters:${NC}"
    echo "  COMPARTMENT_ID  - OCI compartment OCID (optional, uses tenancy if not provided)"
    echo "  REGION          - OCI region (optional, uses config default if not provided)"
    echo "  PROFILE         - OCI CLI profile (optional, uses DEFAULT if not provided)"
    echo ""
    echo -e "${YELLOW}Examples:${NC}"
    echo "  $0                                                    # Use defaults from ~/.oci/config"
    echo "  $0 ocid1.compartment.oc1..xyz                       # Specify compartment"
    echo "  $0 ocid1.compartment.oc1..xyz us-chicago-1          # Specify compartment and region"
    echo "  $0 ocid1.compartment.oc1..xyz us-chicago-1 myprofile # Specify all parameters"
    echo ""
    echo -e "${YELLOW}Supported regions for Generative AI Agents:${NC}"
    echo "  - us-chicago-1"
    echo "  - eu-frankfurt-1" 
    echo "  - ap-osaka-1"
    echo ""
    echo -e "${YELLOW}Prerequisites:${NC}"
    echo "  - OCI CLI installed and configured"
    echo "  - jq command-line JSON processor"
    echo "  - Appropriate OCI permissions for Generative AI resources"
    echo ""
    echo -e "${YELLOW}Resources Created:${NC}"
    echo "  - OCI Bucket: ai-workshop-labs-datasets"
    echo "  - Knowledge Base: Hotel_Concierge_Knowledge_Base"
    echo "  - RAG Tool: Hotel_Concierge_RAG_Tool"
    echo "  - Hotel_Concierge_Agent: Basic agent with RAG tool"
    echo "  - Hotel_Concierge_Agent_ADK: Agent for ADK development"
    echo ""
}

# =============================================================================
# OCI CONFIGURATION UTILITY FUNCTIONS
# =============================================================================

# Function to extract values from OCI CLI configuration file
# This function parses the ~/.oci/config file to extract configuration values
# for specific profiles and keys (e.g., tenancy, region, user, etc.)
#
# Parameters:
#   $1 - Configuration key to extract (e.g., "tenancy", "region", "user")
#   $2 - OCI profile name (defaults to "DEFAULT")
#
# Returns:
#   - The configuration value if found
#   - Empty string if not found or config file doesn't exist
#   - Exit code 1 if config file doesn't exist
get_oci_config_value() {
    local key="$1"
    local profile="${2:-DEFAULT}"
    local config_file="$HOME/.oci/config"
    
    # Check if OCI config file exists
    if [ ! -f "$config_file" ]; then
        echo ""
        return 1
    fi
    
    # Use awk to parse the config file and extract the specified key value
    # This handles the INI-style format of the OCI config file
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

# Function to extract tenancy OCID from OCI configuration
# This is used as the default compartment when no specific compartment is provided
# The tenancy (root compartment) is typically used for resource creation
#
# Parameters:
#   $1 - OCI profile name (defaults to "DEFAULT")
#
# Returns:
#   - Tenancy OCID if found in config
#   - Empty string if not found
get_tenancy_compartment() {
    local profile="${1:-DEFAULT}"
    get_oci_config_value "tenancy" "$profile"
}

# =============================================================================
# CONFIGURATION SETUP AND VALIDATION
# =============================================================================

# Function to initialize and validate script configuration
# This function handles the setup of all configuration parameters including:
# - OCI profile selection
# - Compartment ID resolution (command line or config file)
# - Region validation and selection
# - Parameter validation and error handling
#
# Parameters:
#   $1 - Compartment ID from command line (optional)
#   $2 - Region from command line (optional)
#   $3 - OCI profile from command line (optional, defaults to DEFAULT)
#
# Global Variables Set:
#   PROFILE - OCI CLI profile to use
#   COMPARTMENT_ID - Target compartment for resource creation
#   REGION - Target region for resource creation
setup_config() {
    local cmd_compartment="$1"
    local cmd_region="$2"
    local cmd_profile="${3:-DEFAULT}"
    
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}OCI Generative AI Agent Setup Script - Lab 2${NC}"
    echo -e "${BLUE}========================================${NC}"
    
    # Set and validate OCI profile
    PROFILE="$cmd_profile"
    echo -e "${YELLOW}Using OCI profile: ${PROFILE}${NC}"
    
    # Determine compartment ID - prioritize command line argument over config file
    if [ -n "$cmd_compartment" ]; then
        COMPARTMENT_ID="$cmd_compartment"
        echo -e "${YELLOW}Using compartment from command line${NC}"
    else
        # Fallback to OCI config file - use tenancy as default compartment
        COMPARTMENT_ID=$(get_tenancy_compartment "$PROFILE")
        if [ -z "$COMPARTMENT_ID" ]; then
            echo -e "${RED}Error: Could not determine compartment ID${NC}"
            echo -e "${RED}Please provide it as a command line parameter or ensure ~/.oci/config is properly configured${NC}"
            show_usage
            exit 1
        fi
        echo -e "${YELLOW}Using tenancy (root compartment) from ~/.oci/config${NC}"
    fi
    
    # Determine region - prioritize command line argument over config file
    if [ -n "$cmd_region" ]; then
        REGION="$cmd_region"
        echo -e "${YELLOW}Using region from command line${NC}"
    else
        # Fallback to OCI config file
        REGION=$(get_oci_config_value "region" "$PROFILE")
        if [ -z "$REGION" ]; then
            echo -e "${RED}Error: Could not determine region${NC}"
            echo -e "${RED}Please provide it as a command line parameter or ensure ~/.oci/config is properly configured${NC}"
            show_usage
            exit 1
        fi
        echo -e "${YELLOW}Using region from ~/.oci/config${NC}"
    fi
    
    # Display final configuration
    echo -e "${BLUE}Configuration:${NC}"
    echo -e "  Profile: ${PROFILE}"
    echo -e "  Compartment ID: ${COMPARTMENT_ID}"
    echo -e "  Region: ${REGION}"
    echo ""
    
    # Validate region supports Generative AI Agents
    case "$REGION" in
        us-chicago-1|eu-frankfurt-1|ap-osaka-1)
            echo -e "${GREEN}✓ Region ${REGION} supports Generative AI Agents${NC}"
            ;;
        *)
            echo -e "${YELLOW}Warning: Region ${REGION} may not support Generative AI Agents${NC}"
            echo -e "${YELLOW}Supported regions: us-chicago-1, eu-frankfurt-1, ap-osaka-1${NC}"
            read -p "Continue anyway? (y/N): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                exit 1
            fi
            ;;
    esac
}

# =============================================================================
# OCI CLI VALIDATION
# =============================================================================

# Function to validate OCI CLI configuration and connectivity
# This function performs a test API call to verify that:
# - OCI CLI is properly configured
# - Authentication credentials are valid
# - Network connectivity to OCI is working
# - User has appropriate permissions for the target compartment
#
# The function uses a simple compartment get operation as a connectivity test
# since it requires minimal permissions and is fast to execute
check_oci_config() {
    echo -e "${YELLOW}Checking OCI CLI configuration...${NC}"
    
    # Build test command based on profile configuration
    local test_command
    if [ "$PROFILE" = "DEFAULT" ]; then
        test_command="oci iam compartment get --compartment-id $COMPARTMENT_ID --region $REGION"
    else
        test_command="oci iam compartment get --compartment-id $COMPARTMENT_ID --region $REGION --profile $PROFILE"
    fi
    
    # Execute test command and check for success
    if ! $test_command &>/dev/null; then
        echo -e "${RED}Error: OCI CLI not properly configured for profile '$PROFILE'${NC}"
        echo -e "${RED}Please run 'oci setup config' or check your ~/.oci/config file${NC}"
        echo -e "${RED}Common issues:${NC}"
        echo -e "${RED}  - Invalid API key or passphrase${NC}"
        echo -e "${RED}  - Incorrect tenancy/user OCID${NC}"
        echo -e "${RED}  - Network connectivity issues${NC}"
        echo -e "${RED}  - Insufficient permissions for compartment access${NC}"
        exit 1
    fi
    echo -e "${GREEN}✓ OCI CLI is properly configured for profile '$PROFILE'${NC}"
}

# =============================================================================
# OCI COMMAND BUILDING UTILITIES
# =============================================================================

# Function to construct base OCI CLI command with consistent parameters
# This function ensures that all OCI commands use the same region and profile
# configuration, reducing code duplication and ensuring consistency
#
# Returns:
#   - Base OCI command string with region and profile parameters
#   - Handles both DEFAULT and custom profile configurations
build_base_oci_command() {
    if [ "$PROFILE" = "DEFAULT" ]; then
        echo "oci --region $REGION"
    else
        echo "oci --region $REGION --profile $PROFILE"
    fi
}

# =============================================================================
# OCI BUCKET AND KNOWLEDGE BASE OPERATIONS
# =============================================================================

# Function to create or get an existing OCI bucket for storing knowledge base files
# This function creates a bucket with the specified name and configuration, or gets
# the existing bucket if it already exists:
# - Custom bucket name
# - Public read access for knowledge base integration
# - Checks if bucket exists before creating
# - Extracts and stores the bucket ID for later use
#
# Parameters:
#   $1 - Bucket name
#   $2 - Output file name for bucket ID
#
# Global Variables Set:
#   BUCKET_ID - The OCID of the bucket (created or existing)
#   BUCKET_RESPONSE - Raw response from the bucket API
#
# Output Files:
#   $2 - Contains the bucket OCID for later reference
create_bucket() {
    local bucket_name="$1"
    local output_file="$2"
    
    echo -e "${YELLOW}Checking if bucket '${bucket_name}' exists...${NC}"
    
    # Build the OCI command to check if bucket exists
    local base_cmd=$(build_base_oci_command)
    local check_cmd="$base_cmd os bucket get --bucket-name '$bucket_name'"
    
    # Check if bucket already exists
    local check_response=$(eval $check_cmd 2>/dev/null)
    local check_exit_code=$?
    
    if [ $check_exit_code -eq 0 ]; then
        # Bucket exists, extract its ID
        BUCKET_ID=$(echo "$check_response" | jq -r '.data.id' 2>/dev/null)
        
        if [ "$BUCKET_ID" = "null" ] || [ -z "$BUCKET_ID" ]; then
            echo -e "${RED}✗ Failed to extract bucket ID from existing bucket${NC}"
            return 1
        fi
        
        echo -e "${GREEN}✓ Bucket '${bucket_name}' already exists!${NC}"
        echo -e "${BLUE}Bucket ID: ${BUCKET_ID}${NC}"
        echo "$BUCKET_ID" > "$output_file"
        return 0
    else
        # Bucket doesn't exist, create it
        echo -e "${YELLOW}Creating OCI bucket '${bucket_name}'...${NC}"
        
        # Build the OCI command for bucket creation
        local create_cmd="$base_cmd os bucket create \
            --compartment-id '$COMPARTMENT_ID' \
            --name '$bucket_name' \
            --public-access-type 'ObjectRead' \
            --versioning 'Disabled'"
        
        echo -e "${BLUE}Running: ${create_cmd}${NC}"
        
        # Execute the command and capture output
        BUCKET_RESPONSE=$(eval $create_cmd 2>/tmp/bucket_error.log)
        BUCKET_EXIT_CODE=$?
        BUCKET_ERROR=$(cat /tmp/bucket_error.log 2>/dev/null || echo "")
        
        if [ $BUCKET_EXIT_CODE -eq 0 ]; then
            # Extract bucket ID from the response
            BUCKET_ID=$(echo "$BUCKET_RESPONSE" | jq -r '.data.id' 2>/dev/null)
            
            # Validate that we successfully extracted a bucket ID
            if [ "$BUCKET_ID" = "null" ] || [ -z "$BUCKET_ID" ]; then
                echo -e "${RED}✗ Failed to extract bucket ID from response${NC}"
                echo -e "${RED}Response: ${BUCKET_RESPONSE}${NC}"
                if [ -n "$BUCKET_ERROR" ]; then
                    echo -e "${RED}Error output: ${BUCKET_ERROR}${NC}"
                fi
                return 1
            fi
            
            # Success - save bucket ID and return
            echo -e "${GREEN}✓ Bucket '${bucket_name}' created successfully!${NC}"
            echo -e "${BLUE}Bucket ID: ${BUCKET_ID}${NC}"
            echo "$BUCKET_ID" > "$output_file"
            return 0
        else
            # Handle creation failure
            echo -e "${RED}✗ Failed to create bucket '${bucket_name}'${NC}"
            echo -e "${RED}Response: ${BUCKET_RESPONSE}${NC}"
            if [ -n "$BUCKET_ERROR" ]; then
                echo -e "${RED}Error output: ${BUCKET_ERROR}${NC}"
            fi
            return 1
        fi
    fi
}

# Function to upload a file to an OCI bucket
# This function uploads a local file to the specified bucket:
# - Uses the file name as the object name
# - Sets appropriate content type for markdown files
# - Shows progress for large files
# - Waits for the upload to complete
# - Returns the object name for later reference
#
# Parameters:
#   $1 - Local file path
#   $2 - Bucket name
#   $3 - Output file name for object name
#
# Global Variables Set:
#   OBJECT_NAME - The name of the uploaded object
#   UPLOAD_RESPONSE - Raw response from the upload API
#
# Output Files:
#   $3 - Contains the object name for later reference
upload_file_to_bucket() {
    local file_path="$1"
    local bucket_name="$2"
    local output_file="$3"
    
    echo -e "${YELLOW}Uploading file '${file_path}' to bucket '${bucket_name}'...${NC}"
    
    # Check if file exists
    if [ ! -f "$file_path" ]; then
        echo -e "${RED}✗ File not found: ${file_path}${NC}"
        return 1
    fi
    
    # Get file size for progress indication
    local file_size=$(stat -f%z "$file_path" 2>/dev/null || stat -c%s "$file_path" 2>/dev/null || echo "unknown")
    if [ "$file_size" != "unknown" ]; then
        echo -e "${BLUE}File size: ${file_size} bytes${NC}"
    fi
    
    # Get the file name from the path
    local file_name=$(basename "$file_path")
    OBJECT_NAME="$file_name"
    
    # Build the OCI command for file upload
    local base_cmd=$(build_base_oci_command)
    local cmd="$base_cmd os object put \
        --bucket-name '$bucket_name' \
        --name '$file_name' \
        --file '$file_path' \
        --content-type 'text/markdown' \
        --force"
    
    echo -e "${BLUE}Running: ${cmd}${NC}"
    echo -e "${YELLOW}Uploading... This may take a while for large files.${NC}"
    
    # Execute the command and capture output
    UPLOAD_RESPONSE=$(eval $cmd 2>/tmp/upload_error.log)
    UPLOAD_EXIT_CODE=$?
    UPLOAD_ERROR=$(cat /tmp/upload_error.log 2>/dev/null || echo "")
    
    if [ $UPLOAD_EXIT_CODE -eq 0 ]; then
        # Success - save object name and return
        echo -e "${GREEN}✓ File '${file_name}' uploaded successfully!${NC}"
        echo -e "${BLUE}Object name: ${OBJECT_NAME}${NC}"
        echo "$OBJECT_NAME" > "$output_file"
        return 0
    else
        # Handle upload failure
        echo -e "${RED}✗ Failed to upload file '${file_name}'${NC}"
        echo -e "${RED}Response: ${UPLOAD_RESPONSE}${NC}"
        if [ -n "$UPLOAD_ERROR" ]; then
            echo -e "${RED}Error output: ${UPLOAD_ERROR}${NC}"
        fi
        return 1
    fi
}

# Function to create a knowledge base
# This function creates a knowledge base with the specified configuration:
# - Custom display name and description
# - Uses default index configuration
# - Waits for the creation work request to complete
# - Extracts and stores the knowledge base ID for later use
#
# Parameters:
#   $1 - Knowledge base display name
#   $2 - Knowledge base description
#   $3 - Output file name for knowledge base ID
#
# Global Variables Set:
#   KB_ID - The OCID of the created knowledge base
#   KB_RESPONSE - Raw response from the knowledge base creation API
#
# Output Files:
#   $3 - Contains the knowledge base OCID for later reference
create_knowledge_base() {
    local display_name="$1"
    local description="$2"
    local output_file="$3"
    
    echo -e "${YELLOW}Creating Knowledge Base '${display_name}'...${NC}"
    
    # Create index configuration JSON for the knowledge base
    local index_config=$(cat <<EOF
{
  "indexConfigType": "DEFAULT_INDEX_CONFIG",
  "shouldEnableHybridSearch": true
}
EOF
)
    
    # Save index configuration to temporary file
    local index_config_file="/tmp/kb_index_config.json"
    echo "$index_config" > "$index_config_file"
    
    echo -e "${BLUE}Running: $base_cmd generative-ai-agent knowledge-base create --compartment-id \"$COMPARTMENT_ID\" --display-name \"$display_name\" --description \"$description\" --index-config file://$index_config_file --wait-for-state SUCCEEDED --max-wait-seconds 1800${NC}"
    
    # Execute the command and capture output
    local base_cmd=$(build_base_oci_command)
    KB_RESPONSE=$($base_cmd generative-ai-agent knowledge-base create \
        --compartment-id "$COMPARTMENT_ID" \
        --display-name "$display_name" \
        --description "$description" \
        --index-config file://$index_config_file \
        --wait-for-state SUCCEEDED \
        --max-wait-seconds 1800 2>/tmp/kb_error.log)
    KB_EXIT_CODE=$?
    KB_ERROR=$(cat /tmp/kb_error.log 2>/dev/null || echo "")
    
    # Clean up temporary file
    rm -f "$index_config_file"
    
    if [ $KB_EXIT_CODE -eq 0 ]; then
        # Extract knowledge base ID from the work request response
        # The knowledge base ID is in the resources array of the work request
        KB_ID=$(echo "$KB_RESPONSE" | jq -r '.data.resources[0].identifier' 2>/dev/null)
        
        # Fallback extraction if the primary method fails
        if [ "$KB_ID" = "null" ] || [ -z "$KB_ID" ]; then
            # Try alternative JSON path for knowledge base ID
            KB_ID=$(echo "$KB_RESPONSE" | jq -r '.data.id' 2>/dev/null)
        fi
        
        # Validate that we successfully extracted a knowledge base ID
        if [ "$KB_ID" = "null" ] || [ -z "$KB_ID" ]; then
            echo -e "${RED}✗ Failed to extract knowledge base ID from response${NC}"
            echo -e "${RED}Response: ${KB_RESPONSE}${NC}"
            if [ -n "$KB_ERROR" ]; then
                echo -e "${RED}Error output: ${KB_ERROR}${NC}"
            fi
            return 1
        fi
        
        # Success - save knowledge base ID and return
        echo -e "${GREEN}✓ Knowledge Base '${display_name}' created successfully!${NC}"
        echo -e "${BLUE}Knowledge Base ID: ${KB_ID}${NC}"
        echo "$KB_ID" > "$output_file"
        return 0
    else
        # Handle creation failure
        echo -e "${RED}✗ Failed to create knowledge base '${display_name}'${NC}"
        echo -e "${RED}Response: ${KB_RESPONSE}${NC}"
        if [ -n "$KB_ERROR" ]; then
            echo -e "${RED}Error output: ${KB_ERROR}${NC}"
        fi
        return 1
    fi
}

# Function to create a data source for a knowledge base
# This function creates a data source that points to object storage:
# - Links the knowledge base to the uploaded document
# - Uses object storage location for document ingestion
# - Waits for the creation work request to complete
#
# Parameters:
#   $1 - Knowledge base ID
#   $2 - Bucket name containing the document
#   $3 - Object name of the document
#   $4 - Output file name for data source ID
#
# Global Variables Set:
#   DS_ID - The OCID of the created data source
#   DS_RESPONSE - Raw response from the data source creation API
#
# Output Files:
#   $4 - Contains the data source OCID for later reference
create_data_source() {
    local knowledge_base_id="$1"
    local bucket_name="$2"
    local object_name="$3"
    local output_file="$4"
    
    echo -e "${YELLOW}Creating Data Source for Knowledge Base...${NC}"
    
    # Get the namespace for the bucket
    local base_cmd=$(build_base_oci_command)
    local namespace_cmd="$base_cmd os bucket get --bucket-name '$bucket_name'"
    local namespace_response=$(eval $namespace_cmd 2>/dev/null)
    local namespace=$(echo "$namespace_response" | jq -r '.data.namespace' 2>/dev/null)
    
    if [ "$namespace" = "null" ] || [ -z "$namespace" ]; then
        echo -e "${RED}✗ Failed to get namespace for bucket '${bucket_name}'${NC}"
        return 1
    fi
    
    echo -e "${BLUE}Using namespace: ${namespace}${NC}"
    
    # Create object storage prefixes configuration
    local prefixes_config=$(cat <<EOF
[
  {
    "bucketName": "$bucket_name",
    "namespaceName": "$namespace",
    "objectName": "$object_name"
  }
]
EOF
)
    
    # Save prefixes configuration to temporary file
    local prefixes_config_file="/tmp/ds_prefixes_config.json"
    echo "$prefixes_config" > "$prefixes_config_file"
    
    echo -e "${BLUE}Running: $base_cmd generative-ai-agent data-source create-object-storage-ds --compartment-id \"$COMPARTMENT_ID\" --knowledge-base-id \"$knowledge_base_id\" --data-source-config-object-storage-prefixes file://$prefixes_config_file --wait-for-state SUCCEEDED --max-wait-seconds 1800${NC}"
    
    # Execute the command and capture output
    DS_RESPONSE=$($base_cmd generative-ai-agent data-source create-object-storage-ds \
        --compartment-id "$COMPARTMENT_ID" \
        --knowledge-base-id "$knowledge_base_id" \
        --data-source-config-object-storage-prefixes file://$prefixes_config_file \
        --wait-for-state SUCCEEDED \
        --max-wait-seconds 1800 2>/tmp/ds_error.log)
    DS_EXIT_CODE=$?
    DS_ERROR=$(cat /tmp/ds_error.log 2>/dev/null || echo "")
    
    # Clean up temporary file
    rm -f "$prefixes_config_file"
    
    if [ $DS_EXIT_CODE -eq 0 ]; then
        # Extract data source ID from the response
        DS_ID=$(echo "$DS_RESPONSE" | jq -r '.data.id' 2>/dev/null)
        
        # Validate that we successfully extracted a data source ID
        if [ "$DS_ID" = "null" ] || [ -z "$DS_ID" ]; then
            echo -e "${RED}✗ Failed to extract data source ID from response${NC}"
            echo -e "${RED}Response: ${DS_RESPONSE}${NC}"
            if [ -n "$DS_ERROR" ]; then
                echo -e "${RED}Error output: ${DS_ERROR}${NC}"
            fi
            return 1
        fi
        
        # Success - save data source ID and return
        echo -e "${GREEN}✓ Data Source created successfully!${NC}"
        echo -e "${BLUE}Data Source ID: ${DS_ID}${NC}"
        echo "$DS_ID" > "$output_file"
        return 0
    else
        # Handle creation failure
        echo -e "${RED}✗ Failed to create data source${NC}"
        echo -e "${RED}Response: ${DS_RESPONSE}${NC}"
        if [ -n "$DS_ERROR" ]; then
            echo -e "${RED}Error output: ${DS_ERROR}${NC}"
        fi
        return 1
    fi
}

# Function to create a RAG tool configuration using knowledge base ID
# This function creates a RAG tool configuration that references an existing knowledge base:
# - Uses the knowledge base ID for RAG tool configuration
# - Returns the configuration for use in RAG tool creation
#
# Parameters:
#   $1 - Knowledge base ID
#   $2 - Output file name for RAG tool config
#
# Global Variables Set:
#   RAG_CONFIG - The RAG tool configuration JSON
#
# Output Files:
#   $2 - Contains the RAG tool configuration for later reference
create_rag_tool_config() {
    local knowledge_base_id="$1"
    local output_file="$2"
    
    echo -e "${YELLOW}Creating RAG Tool configuration...${NC}"
    
    # Create RAG tool configuration JSON using knowledge base ID
    RAG_CONFIG=$(cat <<EOF
{
  "toolConfigType": "RAG_TOOL_CONFIG",
  "knowledgeBaseConfigs": [
    {
      "knowledgeBaseId": "$knowledge_base_id"
    }
  ]
}
EOF
)
    
    # Save configuration to file
    echo "$RAG_CONFIG" > "$output_file"
    
    echo -e "${GREEN}✓ RAG Tool configuration created successfully!${NC}"
    echo -e "${BLUE}Configuration saved to: ${output_file}${NC}"
    return 0
}



# Function to create a RAG tool using RAG tool configuration
# This function creates a RAG tool with the specified configuration:
# - Custom display name and description
# - Uses the RAG tool configuration file
# - Requires an agent ID to attach the tool to
# - Waits for the creation work request to complete
# - Extracts and stores the tool ID for later use
#
# Parameters:
#   $1 - Tool display name
#   $2 - Tool description
#   $3 - Agent ID to attach the tool to
#   $4 - RAG tool config file
#   $5 - Output file name for tool ID
#
# Global Variables Set:
#   TOOL_ID - The OCID of the created tool
#   TOOL_RESPONSE - Raw response from the tool creation API
#
# Output Files:
#   $5 - Contains the tool OCID for later reference
create_rag_tool() {
    local display_name="$1"
    local description="$2"
    local agent_id="$3"
    local rag_config_file="$4"
    local output_file="$5"
    
    echo -e "${YELLOW}Creating RAG Tool '${display_name}'...${NC}"
    
    # Build the OCI command for RAG tool creation
    local base_cmd=$(build_base_oci_command)
    
    echo -e "${BLUE}Running: $base_cmd generative-ai-agent tool create --agent-id \"$agent_id\" --compartment-id \"$COMPARTMENT_ID\" --display-name \"$display_name\" --description \"$description\" --tool-config file://$rag_config_file --wait-for-state SUCCEEDED --max-wait-seconds 1800${NC}"
    
    # Execute the command and capture output
    TOOL_RESPONSE=$($base_cmd generative-ai-agent tool create \
        --agent-id "$agent_id" \
        --compartment-id "$COMPARTMENT_ID" \
        --display-name "$display_name" \
        --description "$description" \
        --tool-config file://$rag_config_file \
        --wait-for-state SUCCEEDED \
        --max-wait-seconds 1800 2>/tmp/tool_error.log)
    TOOL_EXIT_CODE=$?
    TOOL_ERROR=$(cat /tmp/tool_error.log 2>/dev/null || echo "")
    
    if [ $TOOL_EXIT_CODE -eq 0 ]; then
        # Extract tool ID from the work request response
        TOOL_ID=$(echo "$TOOL_RESPONSE" | jq -r '.data.resources[0].identifier' 2>/dev/null)
        
        # Fallback extraction if the primary method fails
        if [ "$TOOL_ID" = "null" ] || [ -z "$TOOL_ID" ]; then
            TOOL_ID=$(echo "$TOOL_RESPONSE" | jq -r '.data.id' 2>/dev/null)
        fi
        
        # Validate that we successfully extracted a tool ID
        if [ "$TOOL_ID" = "null" ] || [ -z "$TOOL_ID" ]; then
            echo -e "${RED}✗ Failed to extract tool ID from response${NC}"
            echo -e "${RED}Response: ${TOOL_RESPONSE}${NC}"
            if [ -n "$TOOL_ERROR" ]; then
                echo -e "${RED}Error output: ${TOOL_ERROR}${NC}"
            fi
            return 1
        fi
        
        # Success - save tool ID and return
        echo -e "${GREEN}✓ RAG Tool '${display_name}' created successfully!${NC}"
        echo -e "${BLUE}Tool ID: ${TOOL_ID}${NC}"
        echo "$TOOL_ID" > "$output_file"
        return 0
    else
        # Handle creation failure
        echo -e "${RED}✗ Failed to create RAG tool '${display_name}'${NC}"
        echo -e "${RED}Response: ${TOOL_RESPONSE}${NC}"
        if [ -n "$TOOL_ERROR" ]; then
            echo -e "${RED}Error output: ${TOOL_ERROR}${NC}"
        fi
        return 1
    fi
}

# =============================================================================
# GENERATIVE AI AGENT CREATION
# =============================================================================

# Function to create a Generative AI Agent
# This function creates a new Generative AI Agent with the specified configuration:
# - Custom display name and description
# - Custom welcome message
# - Waits for the creation work request to complete
# - Extracts and stores the agent ID for later use
#
# The function handles both synchronous and asynchronous agent creation,
# with comprehensive error handling and debugging output
#
# Parameters:
#   $1 - Agent display name
#   $2 - Agent description
#   $3 - Welcome message
#   $4 - Output file name for agent ID
#
# Global Variables Set:
#   AGENT_ID - The OCID of the created agent
#   AGENT_RESPONSE - Raw response from the agent creation API
#
# Output Files:
#   $4 - Contains the agent OCID for later reference
create_agent() {
    local display_name="$1"
    local description="$2"
    local welcome_message="$3"
    local output_file="$4"
    
    echo -e "${YELLOW}Creating Generative AI Agent '${display_name}'...${NC}"
    
    # Build the OCI command for agent creation
    # The command includes all necessary parameters and waits for completion
    local base_cmd=$(build_base_oci_command)
    
    echo -e "${BLUE}Running: $base_cmd generative-ai-agent agent create --compartment-id \"$COMPARTMENT_ID\" --display-name \"$display_name\" --description \"$description\" --welcome-message \"$welcome_message\" --wait-for-state SUCCEEDED --max-wait-seconds 1800${NC}"
    
    # Execute the command and capture output separately to avoid JSON corruption
    # This approach prevents stderr messages from interfering with JSON parsing
    # Use direct command execution instead of eval to avoid quote issues
    AGENT_RESPONSE=$($base_cmd generative-ai-agent agent create \
        --compartment-id "$COMPARTMENT_ID" \
        --display-name "$display_name" \
        --description "$description" \
        --welcome-message "$welcome_message" \
        --wait-for-state SUCCEEDED \
        --max-wait-seconds 1800 2>/tmp/agent_error.log)
    AGENT_EXIT_CODE=$?
    AGENT_ERROR=$(cat /tmp/agent_error.log 2>/dev/null || echo "")
    
    if [ $AGENT_EXIT_CODE -eq 0 ]; then
        # Debug: Show the raw response for troubleshooting
        echo -e "${BLUE}Debug: Raw response length: ${#AGENT_RESPONSE} characters${NC}"
        
        # Extract agent ID from the work request response
        # The agent ID is typically found in the resources array of the work request
        AGENT_ID=$(echo "$AGENT_RESPONSE" | jq -r '.data.resources[0].identifier' 2>/dev/null)
        echo -e "${BLUE}Debug: Extracted agent ID: '${AGENT_ID}'${NC}"
        
        # Fallback extraction if the primary method fails
        if [ "$AGENT_ID" = "null" ] || [ -z "$AGENT_ID" ]; then
            # Try alternative JSON path for agent ID
            AGENT_ID=$(echo "$AGENT_RESPONSE" | jq -r '.data.id' 2>/dev/null)
            echo -e "${BLUE}Debug: Fallback agent ID: '${AGENT_ID}'${NC}"
        fi
        
        # Validate that we successfully extracted an agent ID
        if [ "$AGENT_ID" = "null" ] || [ -z "$AGENT_ID" ]; then
            echo -e "${RED}✗ Failed to extract agent ID from response${NC}"
            echo -e "${RED}Response: ${AGENT_RESPONSE}${NC}"
            if [ -n "$AGENT_ERROR" ]; then
                echo -e "${RED}Error output: ${AGENT_ERROR}${NC}"
            fi
            return 1
        fi
        
        # Success - save agent ID and return
        echo -e "${GREEN}✓ Agent '${display_name}' created successfully!${NC}"
        echo -e "${BLUE}Agent ID: ${AGENT_ID}${NC}"
        echo "$AGENT_ID" > "$output_file"
        return 0
    else
        # Handle creation failure
        echo -e "${RED}✗ Failed to create agent '${display_name}'${NC}"
        echo -e "${RED}Response: ${AGENT_RESPONSE}${NC}"
        return 1
    fi
}

# =============================================================================
# AGENT ENDPOINT CREATION
# =============================================================================

# Function to create an endpoint for a Generative AI Agent
# This function creates an endpoint with the specified configuration:
# - Custom display name
# - Waits for the creation work request to complete
# - Extracts and stores the endpoint ID for later use
#
# The function handles both synchronous and asynchronous endpoint creation,
# with comprehensive error handling and debugging output
#
# Parameters:
#   $1 - Agent ID file path
#   $2 - Endpoint display name
#   $3 - Endpoint description
#   $4 - Output file name for endpoint ID
#
# Global Variables Set:
#   ENDPOINT_ID - The OCID of the created endpoint
#   ENDPOINT_RESPONSE - Raw response from the endpoint creation API
#
# Output Files:
#   $4 - Contains the endpoint OCID for later reference
create_agent_endpoint() {
    local agent_id_file="$1"
    local display_name="$2"
    local description="$3"
    local output_file="$4"
    
    echo -e "${YELLOW}Creating Agent Endpoint '${display_name}'...${NC}"
    
    # Read the agent ID from the file created by the agent creation function
    local agent_id=$(cat "$agent_id_file")
    
    # Build the OCI command for endpoint creation
    # The command includes all necessary parameters and waits for completion
    local base_cmd=$(build_base_oci_command)
    
    echo -e "${BLUE}Running: $base_cmd generative-ai-agent agent-endpoint create --agent-id \"$agent_id\" --compartment-id \"$COMPARTMENT_ID\" --display-name \"$display_name\" --description \"$description\" --wait-for-state SUCCEEDED --max-wait-seconds 1800${NC}"
    
    # Execute the command and capture output separately to avoid JSON corruption
    # This approach prevents stderr messages from interfering with JSON parsing
    # Use direct command execution instead of eval to avoid quote issues
    ENDPOINT_RESPONSE=$($base_cmd generative-ai-agent agent-endpoint create \
        --agent-id "$agent_id" \
        --compartment-id "$COMPARTMENT_ID" \
        --display-name "$display_name" \
        --description "$description" \
        --wait-for-state SUCCEEDED \
        --max-wait-seconds 1800 2>/tmp/endpoint_error.log)
    ENDPOINT_EXIT_CODE=$?
    ENDPOINT_ERROR=$(cat /tmp/endpoint_error.log 2>/dev/null || echo "")
    
    if [ $ENDPOINT_EXIT_CODE -eq 0 ]; then
        # Debug: Show the raw response for troubleshooting
        echo -e "${BLUE}Debug: Raw response length: ${#ENDPOINT_RESPONSE} characters${NC}"
        
        # Extract endpoint ID from the work request response
        # The endpoint ID is typically found in the resources array of the work request
        ENDPOINT_ID=$(echo "$ENDPOINT_RESPONSE" | jq -r '.data.resources[0].identifier' 2>/dev/null)
        echo -e "${BLUE}Debug: Extracted endpoint ID: '${ENDPOINT_ID}'${NC}"
        
        # Fallback extraction if the primary method fails
        if [ "$ENDPOINT_ID" = "null" ] || [ -z "$ENDPOINT_ID" ]; then
            # Try alternative JSON path for endpoint ID
            ENDPOINT_ID=$(echo "$ENDPOINT_RESPONSE" | jq -r '.data.id' 2>/dev/null)
            echo -e "${BLUE}Debug: Fallback endpoint ID: '${ENDPOINT_ID}'${NC}"
        fi
        
        # Validate that we successfully extracted an endpoint ID
        if [ "$ENDPOINT_ID" = "null" ] || [ -z "$ENDPOINT_ID" ]; then
            echo -e "${RED}✗ Failed to extract endpoint ID from response${NC}"
            echo -e "${RED}Response: ${ENDPOINT_RESPONSE}${NC}"
            if [ -n "$ENDPOINT_ERROR" ]; then
                echo -e "${RED}Error output: ${ENDPOINT_ERROR}${NC}"
            fi
            return 1
        fi
        
        # Success - save endpoint ID and return
        echo -e "${GREEN}✓ Agent endpoint '${display_name}' created successfully!${NC}"
        echo -e "${BLUE}Endpoint ID: ${ENDPOINT_ID}${NC}"
        echo "$ENDPOINT_ID" > "$output_file"
        return 0
    else
        # Handle creation failure
        echo -e "${RED}✗ Failed to create agent endpoint '${display_name}'${NC}"
        echo -e "${RED}Response: ${ENDPOINT_RESPONSE}${NC}"
        return 1
    fi
}

# =============================================================================
# OUTPUT AND DISPLAY FUNCTIONS
# =============================================================================

# Function to display a comprehensive summary of the created resources
# This function provides a complete overview of all created resources including:
# - Agent details (ID, name, region, compartment)
# - Endpoint details (ID, URL for API access)
# - Knowledge base and RAG tool details
# - Security configuration (disabled features for lab purposes)
# - Session configuration (timeout settings)
#
# The function reads resource IDs from output files created during setup
# and presents them in a user-friendly format
display_summary() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${GREEN}Agent Setup Complete!${NC}"
    echo -e "${BLUE}========================================${NC}"
    
    # Read resource IDs from output files
    # These files contain the OCIDs created during setup
    HOTEL_CONCIERGE_BUCKET_ID=$(cat hotel_concierge_bucket_id.txt 2>/dev/null)
    HOTEL_CONCIERGE_KB_ID=$(cat hotel_concierge_kb_id.txt 2>/dev/null)
    HOTEL_CONCIERGE_DS_ID=$(cat hotel_concierge_ds_id.txt 2>/dev/null)
    HOTEL_CONCIERGE_RAG_TOOL_ID=$(cat hotel_concierge_rag_tool_id.txt 2>/dev/null)
    HOTEL_CONCIERGE_AGENT_ID=$(cat hotel_concierge_agent_id.txt 2>/dev/null)
    HOTEL_CONCIERGE_AGENT_ADK_ID=$(cat hotel_concierge_agent_adk_id.txt 2>/dev/null)
    HOTEL_CONCIERGE_ENDPOINT_ID=$(cat hotel_concierge_endpoint_id.txt 2>/dev/null)
    HOTEL_CONCIERGE_ADK_ENDPOINT_ID=$(cat hotel_concierge_adk_endpoint_id.txt 2>/dev/null)
    
    # Display knowledge base resources
    echo -e "${YELLOW}Knowledge Base Resources:${NC}"
    echo -e "  Bucket: ai-workshop-labs-datasets"
    echo -e "  Bucket ID: ${HOTEL_CONCIERGE_BUCKET_ID}"
    echo -e "  Knowledge Base: Hotel_Concierge_Knowledge_Base"
    echo -e "  Knowledge Base ID: ${HOTEL_CONCIERGE_KB_ID}"
    echo -e "  Data Source ID: ${HOTEL_CONCIERGE_DS_ID}"
    echo -e "  RAG Tool Config: hotel_concierge_rag_config.json"
    echo -e "  RAG Tool: Hotel_Concierge_RAG_Tool"
    echo -e "  RAG Tool ID: ${HOTEL_CONCIERGE_RAG_TOOL_ID}"
    echo ""
    
    # Display first agent information
    echo -e "${YELLOW}Hotel Concierge Agent (Basic):${NC}"
    echo -e "  Name: Hotel_Concierge_Agent"
    echo -e "  Agent ID: ${HOTEL_CONCIERGE_AGENT_ID}"
    echo -e "  Endpoint ID: ${HOTEL_CONCIERGE_ENDPOINT_ID}"
    echo ""
    
    # Display second agent information
    echo -e "${YELLOW}Hotel Concierge Agent (ADK):${NC}"
    echo -e "  Name: Hotel_Concierge_Agent_ADK"
    echo -e "  Agent ID: ${HOTEL_CONCIERGE_AGENT_ADK_ID}"
    echo -e "  Endpoint ID: ${HOTEL_CONCIERGE_ADK_ENDPOINT_ID}"
    echo ""
    
    # Display common configuration
    echo -e "${YELLOW}Common Configuration:${NC}"
    echo -e "  Region: ${REGION}"
    echo -e "  Profile: ${PROFILE}"
    echo -e "  Compartment: ${COMPARTMENT_ID}"
    echo ""
    
    # Display security configuration
    # Note: Security features are disabled for lab purposes
    echo -e "${YELLOW}Security Configuration:${NC}"
    echo -e "  ${RED}Content Moderation: DISABLED${NC}"
    echo -e "  ${RED}Prompt Injection Protection: DISABLED${NC}"
    echo -e "  ${RED}PII Detection: DISABLED${NC}"
    echo ""
    
    # Display session configuration
    echo -e "${YELLOW}Session Configuration:${NC}"
    echo -e "  Idle Timeout: 3600 seconds (1 hour)"
    echo ""
    echo -e "${BLUE}========================================${NC}"
}

# Function to display next steps and usage instructions
# This function provides guidance on how to use the created resources including:
# - How to test the agents via OCI Console
# - How to use the Agent Development Kit (ADK)
# - How to integrate with applications using the API
# - How to use the knowledge base and RAG tool
# - How to clean up resources when finished
#
# The function dynamically reads resource IDs from output files
# to provide accurate instructions
show_next_steps() {
    echo -e "${YELLOW}Next Steps:${NC}"
    echo ""
    
    # Knowledge base and RAG tool information
    echo -e "${BLUE}1. Knowledge Base and RAG Tool:${NC}"
    echo -e "   - RAG Tool Config: hotel_concierge_rag_config.json"
    echo -e "   - RAG Tool ID: $(cat hotel_concierge_rag_tool_id.txt 2>/dev/null || echo 'See hotel_concierge_rag_tool_id.txt')"
    echo -e "   - Bucket: ai-workshop-labs-datasets"
    echo -e "   - Uploaded file: TripAdvisorReviewsMultiLang.md"
    echo ""
    
    # Console testing instructions
    echo -e "${BLUE}2. Test your agents using OCI Console:${NC}"
    echo -e "   - Go to OCI Console → Analytics & AI → Generative AI Agents"
    echo -e "   - Find your 'Hotel_Concierge_Agent' and 'Hotel_Concierge_Agent_ADK'"
    echo -e "   - Use the built-in chat interface to test"
    echo ""
    
    # ADK usage instructions
    echo -e "${BLUE}3. Use the Agent Development Kit (ADK):${NC}"
    echo -e "   - Install: pip install oci[addons-adk]"
    echo -e "   - Use ADK agent endpoint ID: $(cat hotel_concierge_adk_endpoint_id.txt 2>/dev/null || echo 'See hotel_concierge_adk_endpoint_id.txt')"
    echo ""
    
    # API integration instructions
    echo -e "${BLUE}4. Integrate with your application:${NC}"
    echo -e "   - Basic agent endpoint ID: $(cat hotel_concierge_endpoint_id.txt 2>/dev/null || echo 'See hotel_concierge_endpoint_id.txt')"
    echo -e "   - ADK agent endpoint ID: $(cat hotel_concierge_adk_endpoint_id.txt 2>/dev/null || echo 'See hotel_concierge_adk_endpoint_id.txt')"
    echo -e "   - Refer to OCI Generative AI Agents API documentation"
    echo ""
    
    # Cleanup instructions
    echo -e "${BLUE}5. Clean up (when done):${NC}"
    echo -e "   - Run: ./cleanup_agents.sh ${PROFILE}"
    echo ""
}

# =============================================================================
# CLEANUP SCRIPT GENERATION
# =============================================================================

# Function to create a cleanup script for resource management
# This function generates a standalone cleanup script that can be used to
# remove all resources created by this setup script. The cleanup script:
# - Deletes the agent endpoints first (dependency order)
# - Deletes the agents
# - Removes output files
# - Uses the same OCI profile as the setup script
#
# The generated script is self-contained and can be run independently
# to clean up resources when they are no longer needed
create_cleanup_script() {
    cat > cleanup_agents.sh << 'EOF'
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
EOF

    chmod +x cleanup_agents.sh
    echo -e "${GREEN}✓ Cleanup script created: cleanup_agents.sh${NC}"
}

# =============================================================================
# MAIN EXECUTION FUNCTION
# =============================================================================

# Main function that orchestrates the entire setup process
# This function implements the main workflow:
# 1. Parse and validate command line arguments
# 2. Check prerequisites (jq installation)
# 3. Setup configuration (profile, compartment, region)
# 4. Validate OCI CLI configuration
# 5. Create the first Generative AI Agent (Hotel_Concierge_Agent)
# 6. Create the first agent endpoint
# 7. Create the second Generative AI Agent (Hotel_Concierge_Agent_ADK)
# 8. Create the second agent endpoint
# 9. Display results and next steps
# 10. Generate cleanup script
#
# The function includes comprehensive error handling and cleanup
# to ensure resources are properly managed even on failure
#
# Parameters:
#   $@ - Command line arguments (compartment_id, region, profile)
main() {
    # Parse command line arguments and handle help requests
    if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
        show_usage
        exit 0
    fi
    
    # Check if jq is installed (required for JSON parsing)
    # jq is used throughout the script to extract values from API responses
    if ! command -v jq &> /dev/null; then
        echo -e "${RED}Error: jq is required but not installed${NC}"
        echo -e "${YELLOW}Install with: sudo apt-get install jq (Ubuntu/Debian) or brew install jq (macOS)${NC}"
        exit 1
    fi
    
    # Setup configuration from command line arguments or OCI config file
    # This establishes the profile, compartment, and region for all operations
    setup_config "$1" "$2" "$3"
    
    # Validate OCI CLI configuration and connectivity
    # This ensures the script can successfully communicate with OCI
    check_oci_config
    
    # Create bucket for knowledge base files
    if create_bucket \
        "ai-workshop-labs-datasets" \
        "hotel_concierge_bucket_id.txt"; then
        
        # Upload markdown file to bucket
        if upload_file_to_bucket \
            "$(pwd)/labs/datasets/TripAdvisorReviewsMultiLang.md" \
            "ai-workshop-labs-datasets" \
            "tripadvisor_reviews_object_name.txt"; then
            
                        # Create knowledge base first
            if create_knowledge_base \
                "Hotel_Concierge_Knowledge_Base" \
                "Knowledge base containing TripAdvisor reviews for hotel concierge services" \
                "hotel_concierge_kb_id.txt"; then
                
                # Create data source for the knowledge base
                if create_data_source \
                    "$(cat hotel_concierge_kb_id.txt)" \
                    "ai-workshop-labs-datasets" \
                    "$(cat tripadvisor_reviews_object_name.txt)" \
                    "hotel_concierge_ds_id.txt"; then
                    
                    # Create RAG tool configuration using knowledge base ID
                    if create_rag_tool_config \
                        "$(cat hotel_concierge_kb_id.txt)" \
                        "hotel_concierge_rag_config.json"; then
                
                # Create the first Generative AI Agent (Hotel_Concierge_Agent)
                if create_agent \
                    "Hotel_Concierge_Agent" \
                    "Hotel Concierge Agent for basic interactions without tools" \
                    "Hello! I'm your Hotel Concierge Agent. How can I assist you with your stay today?" \
                    "hotel_concierge_agent_id.txt"; then
                    
                    # Create RAG tool and attach to the first agent
                    if create_rag_tool \
                        "Hotel_Concierge_RAG_Tool" \
                        "RAG tool for hotel concierge services using TripAdvisor reviews" \
                        "$(cat hotel_concierge_agent_id.txt)" \
                        "hotel_concierge_rag_config.json" \
                        "hotel_concierge_rag_tool_id.txt"; then
                            
                            # Create the first agent endpoint
                            if create_agent_endpoint \
                                "hotel_concierge_agent_id.txt" \
                                "Hotel_Concierge_Agent-endpoint" \
                                "Endpoint for Hotel Concierge Agent" \
                                "hotel_concierge_endpoint_id.txt"; then
                                
                                # Create the second Generative AI Agent (Hotel_Concierge_Agent_ADK)
                                if create_agent \
                                    "Hotel_Concierge_Agent_ADK" \
                                    "Hotel Concierge Agent for ADK development with tools" \
                                    "Hello! I'm your Hotel Concierge Agent for ADK development. I can help you with advanced hotel services and tools." \
                                    "hotel_concierge_agent_adk_id.txt"; then
                                    
                                    # Create the second agent endpoint
                                    if create_agent_endpoint \
                                        "hotel_concierge_agent_adk_id.txt" \
                                        "Hotel_Concierge_Agent_ADK-endpoint" \
                                        "Endpoint for Hotel Concierge Agent ADK" \
                                        "hotel_concierge_adk_endpoint_id.txt"; then
                                        
                                        # Display comprehensive summary of created resources
                                        display_summary
                                        
                                        # Show next steps and usage instructions
                                        show_next_steps
                                        
                                        # Generate cleanup script for resource management
                                        create_cleanup_script
                                        
                                        # Success message
                                        echo -e "${GREEN}🎉 Hotel Concierge agents setup completed successfully!${NC}"
                                    else
                                        # Handle second endpoint creation failure
                                        echo -e "${RED}Failed to create second endpoint. Cleaning up second agent...${NC}"
                                        AGENT_ID=$(cat hotel_concierge_agent_adk_id.txt 2>/dev/null)
                                        if [ ! -z "$AGENT_ID" ]; then
                                            base_cmd=$(build_base_oci_command)
                                            cleanup_cmd="$base_cmd generative-ai-agent agent delete --agent-id '$AGENT_ID' --force"
                                            eval $cleanup_cmd
                                        fi
                                        exit 1
                                    fi
                                else
                                    # Handle second agent creation failure
                                    echo -e "${RED}Failed to create second agent. Exiting.${NC}"
                                    exit 1
                                fi
                            else
                                # Handle first endpoint creation failure
                                echo -e "${RED}Failed to create first endpoint. Cleaning up first agent...${NC}"
                                AGENT_ID=$(cat hotel_concierge_agent_id.txt 2>/dev/null)
                                if [ ! -z "$AGENT_ID" ]; then
                                    base_cmd=$(build_base_oci_command)
                                    cleanup_cmd="$base_cmd generative-ai-agent agent delete --agent-id '$AGENT_ID' --force"
                                    eval $cleanup_cmd
                                fi
                                exit 1
                            fi
                    else
                        # Handle RAG tool creation failure
                        echo -e "${RED}Failed to create RAG tool. Cleaning up first agent...${NC}"
                        AGENT_ID=$(cat hotel_concierge_agent_id.txt 2>/dev/null)
                        if [ ! -z "$AGENT_ID" ]; then
                            base_cmd=$(build_base_oci_command)
                            cleanup_cmd="$base_cmd generative-ai-agent agent delete --agent-id '$AGENT_ID' --force"
                            eval $cleanup_cmd
                        fi
                        exit 1
                    fi
                else
                    # Handle first agent creation failure
                    echo -e "${RED}Failed to create first agent. Exiting.${NC}"
                    exit 1
                fi
            else
                # Handle RAG tool configuration creation failure
                echo -e "${RED}Failed to create RAG tool configuration. Exiting.${NC}"
                exit 1
            fi
                    else
                # Handle data source creation failure
                echo -e "${RED}Failed to create data source. Exiting.${NC}"
                exit 1
            fi
        else
            # Handle knowledge base creation failure
            echo -e "${RED}Failed to create knowledge base. Exiting.${NC}"
            exit 1
        fi
        else
            # Handle file upload failure
            echo -e "${RED}Failed to upload file to bucket. Exiting.${NC}"
            exit 1
        fi
    else
        # Handle bucket creation failure
        echo -e "${RED}Failed to create bucket. Exiting.${NC}"
        exit 1
    fi
}

# =============================================================================
# SCRIPT EXECUTION
# =============================================================================

# Execute the main function with all command line arguments
# This is the entry point of the script
main "$@"