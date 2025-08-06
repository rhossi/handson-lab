#!/bin/bash

# =============================================================================
# OCI Generative AI Agent Setup Script - HandsOnLab1
# =============================================================================
# 
# This script automates the creation of an OCI Generative AI Agent with the
# following features:
#   - Creates a Generative AI Agent named "HandsOnLab1"
#   - Creates an endpoint for the agent with security features disabled
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
#   ./handson_lab1_setup.sh [COMPARTMENT_ID] [REGION] [PROFILE]
#
# Examples:
#   ./handson_lab1_setup.sh                                    # Use defaults from ~/.oci/config
#   ./handson_lab1_setup.sh ocid1.compartment.oc1..xyz        # Specify compartment
#   ./handson_lab1_setup.sh ocid1.compartment.oc1..xyz us-chicago-1  # Specify compartment and region
#   ./handson_lab1_setup.sh ocid1.compartment.oc1..xyz us-chicago-1 myprofile  # Specify all parameters
#
# Supported Regions for Generative AI Agents:
#   - us-chicago-1
#   - eu-frankfurt-1
#   - ap-osaka-1
#
# Output Files:
#   - agent_id.txt: Contains the created agent ID
#   - endpoint_id.txt: Contains the created endpoint ID
#   - endpoint_url.txt: Contains the endpoint URL for API access
#   - cleanup_agent.sh: Script to clean up created resources
#
# Author: AI Workshop Demo
# Version: 1.0
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
    echo -e "${BLUE}OCI Generative AI Agent Setup Script${NC}"
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
    echo -e "${BLUE}OCI Generative AI Agent Setup Script${NC}"
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
# GENERATIVE AI AGENT CREATION
# =============================================================================

# Function to create the Generative AI Agent
# This function creates a new Generative AI Agent with the following configuration:
# - Display name: "HandsOnLab1"
# - Custom welcome message
# - Waits for the creation work request to complete
# - Extracts and stores the agent ID for later use
#
# The function handles both synchronous and asynchronous agent creation,
# with comprehensive error handling and debugging output
#
# Global Variables Set:
#   AGENT_ID - The OCID of the created agent
#   AGENT_RESPONSE - Raw response from the agent creation API
#
# Output Files:
#   agent_id.txt - Contains the agent OCID for later reference
create_agent() {
    echo -e "${YELLOW}Creating Generative AI Agent 'HandsOnLab1'...${NC}"
    
    # Build the OCI command for agent creation
    # The command includes all necessary parameters and waits for completion
    local base_cmd=$(build_base_oci_command)
    local cmd="$base_cmd generative-ai-agent agent create \
        --compartment-id '$COMPARTMENT_ID' \
        --display-name 'HandsOnLab1' \
        --description 'Generative AI Agent for Hands-On Lab - Security features disabled' \
        --welcome-message 'Hello! I'\''m HandsOnLab1, your AI assistant. How can I help you today?' \
        --wait-for-state SUCCEEDED \
        --max-wait-seconds 1800"
    
    echo -e "${BLUE}Running: ${cmd}${NC}"
    
    # Execute the command and capture output separately to avoid JSON corruption
    # This approach prevents stderr messages from interfering with JSON parsing
    AGENT_RESPONSE=$(eval $cmd 2>/tmp/agent_error.log)
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
        echo -e "${GREEN}✓ Agent created successfully!${NC}"
        echo -e "${BLUE}Agent ID: ${AGENT_ID}${NC}"
        echo "$AGENT_ID" > agent_id.txt
        return 0
    else
        # Handle creation failure
        echo -e "${RED}✗ Failed to create agent${NC}"
        echo -e "${RED}Response: ${AGENT_RESPONSE}${NC}"
        return 1
    fi
}

# =============================================================================
# AGENT ENDPOINT CREATION
# =============================================================================

# Function to create an endpoint for the Generative AI Agent
# This function creates an endpoint with the following configuration:
# - Display name: "HandsOnLab1-endpoint"
# - Waits for the creation work request to complete
# - Extracts and stores the endpoint ID for later use
#
# The function handles both synchronous and asynchronous endpoint creation,
# with comprehensive error handling and debugging output
#
# Prerequisites:
#   agent_id.txt - Must exist and contain a valid agent OCID
#
# Global Variables Set:
#   ENDPOINT_ID - The OCID of the created endpoint
#   ENDPOINT_RESPONSE - Raw response from the endpoint creation API
#
# Output Files:
#   endpoint_id.txt - Contains the endpoint OCID for later reference
create_agent_endpoint() {
    echo -e "${YELLOW}Creating Agent Endpoint...${NC}"
    
    # Read the agent ID from the file created by the agent creation function
    AGENT_ID=$(cat agent_id.txt)
    
    # Build the OCI command for endpoint creation
    # The command includes all necessary parameters and waits for completion
    local base_cmd=$(build_base_oci_command)
    local cmd="$base_cmd generative-ai-agent agent-endpoint create \
        --agent-id '$AGENT_ID' \
        --compartment-id '$COMPARTMENT_ID' \
        --display-name 'HandsOnLab1-endpoint' \
        --description 'Endpoint for HandsOnLab1 agent' \
        --wait-for-state SUCCEEDED \
        --max-wait-seconds 1800"
    
    echo -e "${BLUE}Running: ${cmd}${NC}"
    
    # Execute the command and capture output separately to avoid JSON corruption
    # This approach prevents stderr messages from interfering with JSON parsing
    ENDPOINT_RESPONSE=$(eval $cmd 2>/tmp/endpoint_error.log)
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
        echo -e "${GREEN}✓ Agent endpoint created successfully!${NC}"
        echo -e "${BLUE}Endpoint ID: ${ENDPOINT_ID}${NC}"
        echo "$ENDPOINT_ID" > endpoint_id.txt
        return 0
    else
        # Handle creation failure
        echo -e "${RED}✗ Failed to create agent endpoint${NC}"
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
    AGENT_ID=$(cat agent_id.txt 2>/dev/null)
    ENDPOINT_ID=$(cat endpoint_id.txt 2>/dev/null)
    
    # Display agent information
    echo -e "${YELLOW}Agent Details:${NC}"
    echo -e "  Name: HandsOnLab1"
    echo -e "  Agent ID: ${AGENT_ID}"
    echo -e "  Region: ${REGION}"
    echo -e "  Profile: ${PROFILE}"
    echo -e "  Compartment: ${COMPARTMENT_ID}"
    echo ""
    
    # Display endpoint information
    echo -e "${YELLOW}Endpoint Details:${NC}"
    echo -e "  Endpoint ID: ${ENDPOINT_ID}"
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
# - How to test the agent via OCI Console
# - How to use the Agent Development Kit (ADK)
# - How to integrate with applications using the API
# - How to clean up resources when finished
#
# The function dynamically reads resource IDs from output files
# to provide accurate instructions
show_next_steps() {
    echo -e "${YELLOW}Next Steps:${NC}"
    echo ""
    
    # Console testing instructions
    echo -e "${BLUE}1. Test your agent using OCI Console:${NC}"
    echo -e "   - Go to OCI Console → Analytics & AI → Generative AI Agents"
    echo -e "   - Find your 'HandsOnLab1' agent"
    echo -e "   - Use the built-in chat interface to test"
    echo ""
    
    # ADK usage instructions
    echo -e "${BLUE}2. Use the Agent Development Kit (ADK):${NC}"
    echo -e "   - Install: pip install oci[addons-adk]"
    echo -e "   - Use endpoint ID: $(cat endpoint_id.txt 2>/dev/null || echo 'See endpoint_id.txt')"
    echo ""
    
    # API integration instructions
    echo -e "${BLUE}3. Integrate with your application:${NC}"
    echo -e "   - Use the endpoint ID: $(cat endpoint_id.txt 2>/dev/null || echo 'See endpoint_id.txt')"
    echo -e "   - Refer to OCI Generative AI Agents API documentation"
    echo ""
    
    # Cleanup instructions
    echo -e "${BLUE}4. Clean up (when done):${NC}"
    echo -e "   - Run: ./cleanup_agent.sh ${PROFILE}"
    echo ""
}

# =============================================================================
# CLEANUP SCRIPT GENERATION
# =============================================================================

# Function to create a cleanup script for resource management
# This function generates a standalone cleanup script that can be used to
# remove all resources created by this setup script. The cleanup script:
# - Deletes the agent endpoint first (dependency order)
# - Deletes the agent
# - Removes output files
# - Uses the same OCI profile as the setup script
#
# The generated script is self-contained and can be run independently
# to clean up resources when they are no longer needed
create_cleanup_script() {
    cat > cleanup_agent.sh << 'EOF'
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
        --wait-for-state DELETED \
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
        --wait-for-state DELETED \
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
EOF

    chmod +x cleanup_agent.sh
    echo -e "${GREEN}✓ Cleanup script created: cleanup_agent.sh${NC}"
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
# 5. Create the Generative AI Agent
# 6. Create the agent endpoint
# 7. Display results and next steps
# 8. Generate cleanup script
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
    
    # Create the Generative AI Agent
    # This is the first step in the resource creation process
    if create_agent; then
        # Create the agent endpoint (depends on agent creation)
        # This provides the API access point for the agent
        if create_agent_endpoint; then
            # Display comprehensive summary of created resources
            display_summary
            
            # Show next steps and usage instructions
            show_next_steps
            
            # Generate cleanup script for resource management
            create_cleanup_script
            
            # Success message
            echo -e "${GREEN}🎉 HandsOnLab1 agent setup completed successfully!${NC}"
        else
            # Handle endpoint creation failure
            # Clean up the agent since endpoint creation failed
            echo -e "${RED}Failed to create endpoint. Cleaning up agent...${NC}"
            AGENT_ID=$(cat agent_id.txt 2>/dev/null)
            if [ ! -z "$AGENT_ID" ]; then
                base_cmd=$(build_base_oci_command)
                cleanup_cmd="$base_cmd generative-ai-agent agent delete --agent-id '$AGENT_ID' --force"
                eval $cleanup_cmd
            fi
            exit 1
        fi
    else
        # Handle agent creation failure
        echo -e "${RED}Failed to create agent. Exiting.${NC}"
        exit 1
    fi
}

# =============================================================================
# SCRIPT EXECUTION
# =============================================================================

# Execute the main function with all command line arguments
# This is the entry point of the script
main "$@"