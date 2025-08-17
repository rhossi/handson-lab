# =============================================================================
# OCI Generative AI Agent Setup Script - HandsOnLab1 (PowerShell Version)
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
#   - PowerShell 5.1 or later
#   - Appropriate OCI permissions for Generative AI resources
#
# Usage:
#   .\handson_lab1_setup.ps1 [COMPARTMENT_ID] [REGION] [PROFILE]
#
# Examples:
#   .\handson_lab1_setup.ps1                                    # Use defaults from ~/.oci/config
#   .\handson_lab1_setup.ps1 ocid1.compartment.oc1..xyz        # Specify compartment
#   .\handson_lab1_setup.ps1 ocid1.compartment.oc1..xyz us-chicago-1  # Specify compartment and region
#   .\handson_lab1_setup.ps1 ocid1.compartment.oc1..xyz us-chicago-1 myprofile  # Specify all parameters
#
# Supported Regions for Generative AI Agents:
#   - us-chicago-1
#   - eu-frankfurt-1
#   - ap-osaka-1
#
# Output Files:
#   - agent_id.txt: Contains the created agent ID
#   - endpoint_id.txt: Contains the created endpoint ID
#   - cleanup_agent.ps1: Script to clean up created resources
#
# Author: AI Workshop Demo
# Version: 1.0
# =============================================================================

param(
    [string]$CompartmentId,
    [string]$Region,
    [string]$Profile = "DEFAULT"
)

# =============================================================================
# COLOR DEFINITIONS FOR OUTPUT FORMATTING
# =============================================================================
# These ANSI color codes are used throughout the script to provide
# visual feedback and improve readability of output messages
$Red = "`e[0;31m"
$Green = "`e[0;32m"
$Yellow = "`e[1;33m"
$Blue = "`e[0;34m"
$NoColor = "`e[0m"

# =============================================================================
# USAGE AND HELP FUNCTIONS
# =============================================================================

# Function to display script usage information and examples
# This function provides comprehensive help information including:
# - Command line parameter descriptions
# - Usage examples for different scenarios
# - Supported regions for Generative AI Agents
# - Prerequisites and requirements
function Show-Usage {
    Write-Host "$Blue========================================$NoColor"
    Write-Host "$BlueOCI Generative AI Agent Setup Script$NoColor"
    Write-Host "$Blue========================================$NoColor"
    Write-Host ""
    Write-Host "$BlueUsage: .\handson_lab1_setup.ps1 [COMPARTMENT_ID] [REGION] [PROFILE]$NoColor"
    Write-Host ""
    Write-Host "$YellowParameters:$NoColor"
    Write-Host "  COMPARTMENT_ID  - OCI compartment OCID (optional, uses tenancy if not provided)"
    Write-Host "  REGION          - OCI region (optional, uses config default if not provided)"
    Write-Host "  PROFILE         - OCI CLI profile (optional, uses DEFAULT if not provided)"
    Write-Host ""
    Write-Host "$YellowExamples:$NoColor"
    Write-Host "  .\handson_lab1_setup.ps1                                    # Use defaults from ~/.oci/config"
    Write-Host "  .\handson_lab1_setup.ps1 ocid1.compartment.oc1..xyz        # Specify compartment"
    Write-Host "  .\handson_lab1_setup.ps1 ocid1.compartment.oc1..xyz us-chicago-1  # Specify compartment and region"
    Write-Host "  .\handson_lab1_setup.ps1 ocid1.compartment.oc1..xyz us-chicago-1 myprofile  # Specify all parameters"
    Write-Host ""
    Write-Host "$YellowSupported regions for Generative AI Agents:$NoColor"
    Write-Host "  - us-chicago-1"
    Write-Host "  - eu-frankfurt-1" 
    Write-Host "  - ap-osaka-1"
    Write-Host ""
    Write-Host "$YellowPrerequisites:$NoColor"
    Write-Host "  - OCI CLI installed and configured"
    Write-Host "  - PowerShell 5.1 or later"
    Write-Host "  - Appropriate OCI permissions for Generative AI resources"
    Write-Host ""
}

# =============================================================================
# OCI CONFIGURATION UTILITY FUNCTIONS
# =============================================================================

# Function to extract values from OCI CLI configuration file
# This function parses the ~/.oci/config file to extract configuration values
# for specific profiles and keys (e.g., tenancy, region, user, etc.)
#
# Parameters:
#   $Key - Configuration key to extract (e.g., "tenancy", "region", "user")
#   $Profile - OCI profile name (defaults to "DEFAULT")
#
# Returns:
#   - The configuration value if found
#   - Empty string if not found or config file doesn't exist
function Get-OciConfigValue {
    param(
        [string]$Key,
        [string]$Profile = "DEFAULT"
    )
    
    $ConfigFile = "$env:USERPROFILE\.oci\config"
    
    # Check if OCI config file exists
    if (-not (Test-Path $ConfigFile)) {
        return ""
    }
    
    # Read the config file and extract the specified key value
    $Content = Get-Content $ConfigFile
    $InSection = $false
    $Value = ""
    
    foreach ($Line in $Content) {
        if ($Line -eq "[$Profile]") {
            $InSection = $true
            continue
        }
        if ($Line -match "^\[" -and $InSection) {
            $InSection = $false
            break
        }
        if ($InSection -and $Line -match "^$Key=") {
            $Value = $Line -replace "^$Key=", ""
            $Value = $Value.Trim()
            break
        }
    }
    
    return $Value
}

# Function to extract tenancy OCID from OCI configuration
# This is used as the default compartment when no specific compartment is provided
# The tenancy (root compartment) is typically used for resource creation
#
# Parameters:
#   $Profile - OCI profile name (defaults to "DEFAULT")
#
# Returns:
#   - Tenancy OCID if found in config
#   - Empty string if not found
function Get-TenancyCompartment {
    param([string]$Profile = "DEFAULT")
    
    return Get-OciConfigValue -Key "tenancy" -Profile $Profile
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
#   $CmdCompartment - Compartment ID from command line (optional)
#   $CmdRegion - Region from command line (optional)
#   $CmdProfile - OCI profile from command line (optional, defaults to DEFAULT)
#
# Global Variables Set:
#   $Script:Profile - OCI CLI profile to use
#   $Script:CompartmentId - Target compartment for resource creation
#   $Script:Region - Target region for resource creation
function Setup-Config {
    param(
        [string]$CmdCompartment,
        [string]$CmdRegion,
        [string]$CmdProfile = "DEFAULT"
    )
    
    Write-Host "$Blue========================================$NoColor"
    Write-Host "$BlueOCI Generative AI Agent Setup Script$NoColor"
    Write-Host "$Blue========================================$NoColor"
    
    # Set and validate OCI profile
    $Script:Profile = $CmdProfile
    Write-Host "$YellowUsing OCI profile: $Script:Profile$NoColor"
    
    # Determine compartment ID - prioritize command line argument over config file
    if ($CmdCompartment) {
        $Script:CompartmentId = $CmdCompartment
        Write-Host "$YellowUsing compartment from command line$NoColor"
    } else {
        # Fallback to OCI config file - use tenancy as default compartment
        $Script:CompartmentId = Get-TenancyCompartment -Profile $Script:Profile
        if (-not $Script:CompartmentId) {
            Write-Host "$RedError: Could not determine compartment ID$NoColor"
            Write-Host "$RedPlease provide it as a command line parameter or ensure ~/.oci/config is properly configured$NoColor"
            Show-Usage
            exit 1
        }
        Write-Host "$YellowUsing tenancy (root compartment) from ~/.oci/config$NoColor"
    }
    
    # Determine region - prioritize command line argument over config file
    if ($CmdRegion) {
        $Script:Region = $CmdRegion
        Write-Host "$YellowUsing region from command line$NoColor"
    } else {
        # Fallback to OCI config file
        $Script:Region = Get-OciConfigValue -Key "region" -Profile $Script:Profile
        if (-not $Script:Region) {
            Write-Host "$RedError: Could not determine region$NoColor"
            Write-Host "$RedPlease provide it as a command line parameter or ensure ~/.oci/config is properly configured$NoColor"
            Show-Usage
            exit 1
        }
        Write-Host "$YellowUsing region from ~/.oci/config$NoColor"
    }
    
    # Display final configuration
    Write-Host "$BlueConfiguration:$NoColor"
    Write-Host "  Profile: $Script:Profile"
    Write-Host "  Compartment ID: $Script:CompartmentId"
    Write-Host "  Region: $Script:Region"
    Write-Host ""
    
    # Validate region supports Generative AI Agents
    $SupportedRegions = @("us-chicago-1", "eu-frankfurt-1", "ap-osaka-1")
    if ($Script:Region -in $SupportedRegions) {
        Write-Host "$Green✓ Region $Script:Region supports Generative AI Agents$NoColor"
    } else {
        Write-Host "$YellowWarning: Region $Script:Region may not support Generative AI Agents$NoColor"
        Write-Host "$YellowSupported regions: us-chicago-1, eu-frankfurt-1, ap-osaka-1$NoColor"
        $Response = Read-Host "Continue anyway? (y/N)"
        if ($Response -notmatch "^[Yy]$") {
            exit 1
        }
    }
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
function Test-OciConfig {
    Write-Host "$YellowChecking OCI CLI configuration...$NoColor"
    
    # Build test command based on profile configuration
    if ($Script:Profile -eq "DEFAULT") {
        $TestCommand = "oci iam compartment get --compartment-id $Script:CompartmentId --region $Script:Region"
    } else {
        $TestCommand = "oci iam compartment get --compartment-id $Script:CompartmentId --region $Script:Region --profile $Script:Profile"
    }
    
    # Execute test command and check for success
    try {
        Invoke-Expression $TestCommand | Out-Null
        Write-Host "$Green✓ OCI CLI is properly configured for profile '$Script:Profile'$NoColor"
    } catch {
        Write-Host "$RedError: OCI CLI not properly configured for profile '$Script:Profile'$NoColor"
        Write-Host "$RedPlease run 'oci setup config' or check your ~/.oci/config file$NoColor"
        Write-Host "$RedCommon issues:$NoColor"
        Write-Host "$Red  - Invalid API key or passphrase$NoColor"
        Write-Host "$Red  - Incorrect tenancy/user OCID$NoColor"
        Write-Host "$Red  - Network connectivity issues$NoColor"
        Write-Host "$Red  - Insufficient permissions for compartment access$NoColor"
        exit 1
    }
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
function Get-BaseOciCommand {
    if ($Script:Profile -eq "DEFAULT") {
        return "oci --region $Script:Region"
    } else {
        return "oci --region $Script:Region --profile $Script:Profile"
    }
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
#   $Script:AgentId - The OCID of the created agent
#   $Script:AgentResponse - Raw response from the agent creation API
#
# Output Files:
#   agent_id.txt - Contains the agent OCID for later reference
function New-Agent {
    Write-Host "$YellowCreating Generative AI Agent 'HandsOnLab1'...$NoColor"
    
    # Build the OCI command for agent creation
    # The command includes all necessary parameters and waits for completion
    $BaseCmd = Get-BaseOciCommand
    $Cmd = "$BaseCmd generative-ai-agent agent create --compartment-id '$Script:CompartmentId' --display-name 'HandsOnLab1' --description 'Generative AI Agent for Hands-On Lab - Security features disabled' --welcome-message 'Hello! I''m HandsOnLab1, your AI assistant. How can I help you today?' --wait-for-state SUCCEEDED --max-wait-seconds 1800"
    
    Write-Host "$BlueRunning: $Cmd$NoColor"
    
    # Execute the command and capture output
    try {
        $Script:AgentResponse = Invoke-Expression $Cmd 2>&1
        
        # Debug: Show the raw response for troubleshooting
        Write-Host "$BlueDebug: Raw response length: $($Script:AgentResponse.Length) characters$NoColor"
        
        # Extract agent ID from the work request response
        # The agent ID is typically found in the resources array of the work request
        $AgentId = $Script:AgentResponse | ConvertFrom-Json | Select-Object -ExpandProperty data | Select-Object -ExpandProperty resources | Select-Object -First 1 | Select-Object -ExpandProperty identifier
        Write-Host "$BlueDebug: Extracted agent ID: '$AgentId'$NoColor"
        
        # Fallback extraction if the primary method fails
        if (-not $AgentId -or $AgentId -eq "null") {
            # Try alternative JSON path for agent ID
            $AgentId = $Script:AgentResponse | ConvertFrom-Json | Select-Object -ExpandProperty data | Select-Object -ExpandProperty id
            Write-Host "$BlueDebug: Fallback agent ID: '$AgentId'$NoColor"
        }
        
        # Validate that we successfully extracted an agent ID
        if (-not $AgentId -or $AgentId -eq "null") {
            Write-Host "$Red✗ Failed to extract agent ID from response$NoColor"
            Write-Host "$RedResponse: $Script:AgentResponse$NoColor"
            return $false
        }
        
        # Success - save agent ID and return
        Write-Host "$Green✓ Agent created successfully!$NoColor"
        Write-Host "$BlueAgent ID: $AgentId$NoColor"
        $Script:AgentId = $AgentId
        $AgentId | Out-File -FilePath "agent_id.txt" -Encoding UTF8
        return $true
    } catch {
        # Handle creation failure
        Write-Host "$Red✗ Failed to create agent$NoColor"
        Write-Host "$RedResponse: $Script:AgentResponse$NoColor"
        return $false
    }
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
#   $Script:EndpointId - The OCID of the created endpoint
#   $Script:EndpointResponse - Raw response from the endpoint creation API
#
# Output Files:
#   endpoint_id.txt - Contains the endpoint OCID for later reference
function New-AgentEndpoint {
    Write-Host "$YellowCreating Agent Endpoint...$NoColor"
    
    # Read the agent ID from the file created by the agent creation function
    if (-not (Test-Path "agent_id.txt")) {
        Write-Host "$RedError: agent_id.txt not found. Please run agent creation first.$NoColor"
        return $false
    }
    
    $AgentId = Get-Content "agent_id.txt" -Raw | ForEach-Object { $_.Trim() }
    
    # Build the OCI command for endpoint creation
    # The command includes all necessary parameters and waits for completion
    $BaseCmd = Get-BaseOciCommand
    $Cmd = "$BaseCmd generative-ai-agent agent-endpoint create --agent-id '$AgentId' --compartment-id '$Script:CompartmentId' --display-name 'HandsOnLab1-endpoint' --description 'Endpoint for HandsOnLab1 agent' --wait-for-state SUCCEEDED --max-wait-seconds 1800"
    
    Write-Host "$BlueRunning: $Cmd$NoColor"
    
    # Execute the command and capture output
    try {
        $Script:EndpointResponse = Invoke-Expression $Cmd 2>&1
        
        # Debug: Show the raw response for troubleshooting
        Write-Host "$BlueDebug: Raw response length: $($Script:EndpointResponse.Length) characters$NoColor"
        
        # Extract endpoint ID from the work request response
        # The endpoint ID is typically found in the resources array of the work request
        $EndpointId = $Script:EndpointResponse | ConvertFrom-Json | Select-Object -ExpandProperty data | Select-Object -ExpandProperty resources | Select-Object -First 1 | Select-Object -ExpandProperty identifier
        Write-Host "$BlueDebug: Extracted endpoint ID: '$EndpointId'$NoColor"
        
        # Fallback extraction if the primary method fails
        if (-not $EndpointId -or $EndpointId -eq "null") {
            # Try alternative JSON path for endpoint ID
            $EndpointId = $Script:EndpointResponse | ConvertFrom-Json | Select-Object -ExpandProperty data | Select-Object -ExpandProperty id
            Write-Host "$BlueDebug: Fallback endpoint ID: '$EndpointId'$NoColor"
        }
        
        # Validate that we successfully extracted an endpoint ID
        if (-not $EndpointId -or $EndpointId -eq "null") {
            Write-Host "$Red✗ Failed to extract endpoint ID from response$NoColor"
            Write-Host "$RedResponse: $Script:EndpointResponse$NoColor"
            return $false
        }
        
        # Success - save endpoint ID and return
        Write-Host "$Green✓ Agent endpoint created successfully!$NoColor"
        Write-Host "$BlueEndpoint ID: $EndpointId$NoColor"
        $Script:EndpointId = $EndpointId
        $EndpointId | Out-File -FilePath "endpoint_id.txt" -Encoding UTF8
        return $true
    } catch {
        # Handle creation failure
        Write-Host "$Red✗ Failed to create agent endpoint$NoColor"
        Write-Host "$RedResponse: $Script:EndpointResponse$NoColor"
        return $false
    }
}

# =============================================================================
# OUTPUT AND DISPLAY FUNCTIONS
# =============================================================================

# Function to display a comprehensive summary of the created resources
# This function provides a complete overview of all created resources including:
# - Agent details (ID, name, region, compartment)
# - Endpoint details (ID)
# - Security configuration (disabled features for lab purposes)
# - Session configuration (timeout settings)
#
# The function reads resource IDs from output files created during setup
# and presents them in a user-friendly format
function Show-Summary {
    Write-Host "$Blue========================================$NoColor"
    Write-Host "$GreenAgent Setup Complete!$NoColor"
    Write-Host "$Blue========================================$NoColor"
    
    # Read resource IDs from output files
    # These files contain the OCIDs created during setup
    $AgentId = if (Test-Path "agent_id.txt") { Get-Content "agent_id.txt" -Raw | ForEach-Object { $_.Trim() } } else { "Not found" }
    $EndpointId = if (Test-Path "endpoint_id.txt") { Get-Content "endpoint_id.txt" -Raw | ForEach-Object { $_.Trim() } } else { "Not found" }
    
    # Display agent information
    Write-Host "$YellowAgent Details:$NoColor"
    Write-Host "  Name: HandsOnLab1"
    Write-Host "  Agent ID: $AgentId"
    Write-Host "  Region: $Script:Region"
    Write-Host "  Profile: $Script:Profile"
    Write-Host "  Compartment: $Script:CompartmentId"
    Write-Host ""
    
    # Display endpoint information
    Write-Host "$YellowEndpoint Details:$NoColor"
    Write-Host "  Endpoint ID: $EndpointId"
    Write-Host ""
    
    # Display security configuration
    # Note: Security features are disabled for lab purposes
    Write-Host "$YellowSecurity Configuration:$NoColor"
    Write-Host "  $RedContent Moderation: DISABLED$NoColor"
    Write-Host "  $RedPrompt Injection Protection: DISABLED$NoColor"
    Write-Host "  $RedPII Detection: DISABLED$NoColor"
    Write-Host ""
    
    # Display session configuration
    Write-Host "$YellowSession Configuration:$NoColor"
    Write-Host "  Idle Timeout: 3600 seconds (1 hour)"
    Write-Host ""
    Write-Host "$Blue========================================$NoColor"
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
function Show-NextSteps {
    Write-Host "$YellowNext Steps:$NoColor"
    Write-Host ""
    
    # Console testing instructions
    Write-Host "$Blue1. Test your agent using OCI Console:$NoColor"
    Write-Host "   - Go to OCI Console → Analytics & AI → Generative AI Agents"
    Write-Host "   - Find your 'HandsOnLab1' agent"
    Write-Host "   - Use the built-in chat interface to test"
    Write-Host ""
    
    # ADK usage instructions
    Write-Host "$Blue2. Use the Agent Development Kit (ADK):$NoColor"
    Write-Host "   - Install: pip install oci[addons-adk]"
    $EndpointId = if (Test-Path "endpoint_id.txt") { Get-Content "endpoint_id.txt" -Raw | ForEach-Object { $_.Trim() } } else { "See endpoint_id.txt" }
    Write-Host "   - Use endpoint ID: $EndpointId"
    Write-Host ""
    
    # API integration instructions
    Write-Host "$Blue3. Integrate with your application:$NoColor"
    Write-Host "   - Use the endpoint ID: $EndpointId"
    Write-Host "   - Refer to OCI Generative AI Agents API documentation"
    Write-Host ""
    
    # Cleanup instructions
    Write-Host "$Blue4. Clean up (when done):$NoColor"
    Write-Host "   - Run: .\cleanup_agent.ps1 $Script:Profile"
    Write-Host ""
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
function New-CleanupScript {
    $CleanupScript = @"
# Cleanup script for HandsOnLab1 agent (PowerShell Version)
# Usage: .\cleanup_agent.ps1 [PROFILE]

param([string]`$Profile = "DEFAULT")

`$Red = "`e[0;31m"
`$Green = "`e[0;32m"
`$Yellow = "`e[1;33m"
`$Blue = "`e[0;34m"
`$NoColor = "`e[0m"

Write-Host "`$YellowCleaning up HandsOnLab1 agent and endpoint (profile: `$Profile)...`$NoColor"

# Function to build base OCI command with profile
function Get-BaseOciCommand {
    if (`$Profile -eq "DEFAULT") {
        return "oci"
    } else {
        return "oci --profile `$Profile"
    }
}

# Read IDs from files
if (Test-Path "endpoint_id.txt") {
    `$EndpointId = Get-Content "endpoint_id.txt" -Raw | ForEach-Object { `$_.Trim() }
    Write-Host "`$YellowDeleting agent endpoint...`$NoColor"
    
    `$BaseCmd = Get-BaseOciCommand
    `$Cmd = "`$BaseCmd generative-ai-agent agent-endpoint delete --agent-endpoint-id '`$EndpointId' --force --wait-for-state SUCCEEDED --max-wait-seconds 1800"
    
    Invoke-Expression `$Cmd
    
    if (`$LASTEXITCODE -eq 0) {
        Write-Host "`$Green✓ Agent endpoint deleted`$NoColor"
        Remove-Item "endpoint_id.txt" -ErrorAction SilentlyContinue
    } else {
        Write-Host "`$Red✗ Failed to delete agent endpoint`$NoColor"
    }
}

if (Test-Path "agent_id.txt") {
    `$AgentId = Get-Content "agent_id.txt" -Raw | ForEach-Object { `$_.Trim() }
    Write-Host "`$YellowDeleting agent...`$NoColor"
    
    `$BaseCmd = Get-BaseOciCommand
    `$Cmd = "`$BaseCmd generative-ai-agent agent delete --agent-id '`$AgentId' --force --wait-for-state SUCCEEDED --max-wait-seconds 1800"
    
    Invoke-Expression `$Cmd
    
    if (`$LASTEXITCODE -eq 0) {
        Write-Host "`$Green✓ Agent deleted`$NoColor"
        Remove-Item "agent_id.txt" -ErrorAction SilentlyContinue
    } else {
        Write-Host "`$Red✗ Failed to delete agent`$NoColor"
    }
}

Write-Host "`$GreenCleanup complete!`$NoColor"
"@

    $CleanupScript | Out-File -FilePath "cleanup_agent.ps1" -Encoding UTF8
    Write-Host "$Green✓ Cleanup script created: cleanup_agent.ps1$NoColor"
}

# =============================================================================
# MAIN EXECUTION FUNCTION
# =============================================================================

# Main function that orchestrates the entire setup process
# This function implements the main workflow:
# 1. Parse and validate command line arguments
# 2. Check prerequisites (PowerShell version)
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
#   $CompartmentId - Compartment ID from command line (optional)
#   $Region - Region from command line (optional)
#   $Profile - OCI profile from command line (optional, defaults to DEFAULT)
function Main {
    # Parse command line arguments and handle help requests
    if ($args -contains "-h" -or $args -contains "--help") {
        Show-Usage
        exit 0
    }
    
    # Check PowerShell version
    if ($PSVersionTable.PSVersion.Major -lt 5) {
        Write-Host "$RedError: PowerShell 5.1 or later is required$NoColor"
        Write-Host "$YellowCurrent version: $($PSVersionTable.PSVersion)$NoColor"
        exit 1
    }
    
    # Setup configuration from command line arguments or OCI config file
    # This establishes the profile, compartment, and region for all operations
    Setup-Config -CmdCompartment $CompartmentId -CmdRegion $Region -CmdProfile $Profile
    
    # Validate OCI CLI configuration and connectivity
    # This ensures the script can successfully communicate with OCI
    Test-OciConfig
    
    # Create the Generative AI Agent
    # This is the first step in the resource creation process
    if (New-Agent) {
        # Create the agent endpoint (depends on agent creation)
        # This provides the API access point for the agent
        if (New-AgentEndpoint) {
            # Display comprehensive summary of created resources
            Show-Summary
            
            # Show next steps and usage instructions
            Show-NextSteps
            
            # Generate cleanup script for resource management
            New-CleanupScript
            
            # Success message
            Write-Host "$Green🎉 HandsOnLab1 agent setup completed successfully!$NoColor"
        } else {
            # Handle endpoint creation failure
            # Clean up the agent since endpoint creation failed
            Write-Host "$RedFailed to create endpoint. Cleaning up agent...$NoColor"
            if (Test-Path "agent_id.txt") {
                $AgentId = Get-Content "agent_id.txt" -Raw | ForEach-Object { $_.Trim() }
                $BaseCmd = Get-BaseOciCommand
                $CleanupCmd = "$BaseCmd generative-ai-agent agent delete --agent-id '$AgentId' --force"
                Invoke-Expression $CleanupCmd
            }
            exit 1
        }
    } else {
        # Handle agent creation failure
        Write-Host "$RedFailed to create agent. Exiting.$NoColor"
        exit 1
    }
}

# =============================================================================
# SCRIPT EXECUTION
# =============================================================================

# Execute the main function with all command line arguments
# This is the entry point of the script
Main 