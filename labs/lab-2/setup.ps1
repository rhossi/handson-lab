# =============================================================================
# OCI Generative AI Agent Setup Script - Simplified PowerShell Version
# =============================================================================
# 
# This script creates OCI Generative AI resources and outputs all OCIDs to
# a single GENERATED_OCIDS.txt file for easy reference and cleanup.
#
# Prerequisites:
#   - OCI CLI installed and configured
#   - PowerShell 5.1 or later
#   - Appropriate OCI permissions for Generative AI resources
#
# Usage:
#   .\setup.ps1 [COMPARTMENT_ID] [REGION] [PROFILE]
#
# Examples:
#   .\setup.ps1                                    # Use defaults from ~/.oci/config
#   .\setup.ps1 ocid1.compartment.oc1..xyz        # Specify compartment
#   .\setup.ps1 ocid1.compartment.oc1..xyz us-chicago-1  # Specify compartment and region
#   .\setup.ps1 ocid1.compartment.oc1..xyz us-chicago-1 myprofile  # Specify all parameters
#
# Output:
#   GENERATED_OCIDS.txt - Contains all created resource OCIDs
#
# =============================================================================

param(
    [string]$CompartmentId,
    [string]$Region,
    [string]$Profile = "DEFAULT"
)

# Color definitions
$Red = "`e[0;31m"
$Green = "`e[0;32m"
$Yellow = "`e[1;33m"
$Blue = "`e[0;34m"
$NoColor = "`e[0m"

# Global variables
$OCIDS_FILE = "GENERATED_OCIDS.txt"

# Function to display usage
function Show-Usage {
    Write-Host "$Blue OCI Generative AI Agent Setup Script $NoColor"
    Write-Host ""
    Write-Host "$Blue Usage: .\setup.ps1 [COMPARTMENT_ID] [REGION] [PROFILE] $NoColor"
    Write-Host ""
    Write-Host "$Yellow Parameters: $NoColor"
    Write-Host "  COMPARTMENT_ID  - OCI compartment OCID (optional)"
    Write-Host "  REGION          - OCI region (optional)"
    Write-Host "  PROFILE         - OCI CLI profile (optional, defaults to DEFAULT)"
    Write-Host ""
    Write-Host "$Yellow Examples: $NoColor"
    Write-Host "  .\setup.ps1                                    # Use defaults"
    Write-Host "  .\setup.ps1 ocid1.compartment.oc1..xyz        # Specify compartment"
    Write-Host "  .\setup.ps1 ocid1.compartment.oc1..xyz us-chicago-1  # Specify compartment and region"
    Write-Host ""
    Write-Host "$Yellow Output: $NoColor"
    Write-Host "  GENERATED_OCIDS.txt - Contains all created resource OCIDs"
}

# Function to get OCI config value
function Get-OciConfigValue {
    param(
        [string]$Key,
        [string]$Profile = "DEFAULT"
    )
    
    $configFile = "$env:USERPROFILE\.oci\config"
    
    if (-not (Test-Path $configFile)) {
        return ""
    }
    
    $content = Get-Content $configFile
    $inSection = $false
    
    foreach ($line in $content) {
        if ($line -eq "[$Profile]") {
            $inSection = $true
            continue
        }
        if ($line -match "^\[" -and $inSection) {
            $inSection = $false
        }
        if ($inSection -and $line -match "^$Key=") {
            return $line.Substring($Key.Length + 1).Trim()
        }
    }
    return ""
}

# Function to build base OCI command
function Build-OciCmd {
    param([string]$Profile)
    
    if ($Profile -eq "DEFAULT") {
        return "oci"
    } else {
        return "oci --profile $Profile"
    }
}

# Function to setup configuration
function Setup-Config {
    param(
        [string]$CmdCompartment,
        [string]$CmdRegion,
        [string]$CmdProfile
    )
    
    Write-Host "$Blue Setting up configuration... $NoColor"
    
    $script:Profile = $CmdProfile
    Write-Host "$Yellow Using OCI profile: $Profile $NoColor"
    
    # Determine compartment ID
    if ($CmdCompartment) {
        $script:CompartmentId = $CmdCompartment
    } else {
        $script:CompartmentId = Get-OciConfigValue -Key "tenancy" -Profile $Profile
        if (-not $script:CompartmentId) {
            Write-Host "$Red Error: Could not determine compartment ID $NoColor"
            Write-Host "$Red Please provide it as a command line parameter or ensure ~/.oci/config is properly configured $NoColor"
            exit 1
        }
    }
    
    # Determine region
    if ($CmdRegion) {
        $script:Region = $CmdRegion
    } else {
        $script:Region = Get-OciConfigValue -Key "region" -Profile $Profile
        if (-not $script:Region) {
            Write-Host "$Red Error: Could not determine region $NoColor"
            Write-Host "$Red Please provide it as a command line parameter or ensure ~/.oci/config is properly configured $NoColor"
            exit 1
        }
    }
    
    Write-Host "$Green Configuration: $NoColor"
    Write-Host "  Profile: $Profile"
    Write-Host "  Compartment ID: $CompartmentId"
    Write-Host "  Region: $Region"
    Write-Host ""
}

# Function to check OCI CLI
function Test-OciCli {
    Write-Host "$Yellow Checking OCI CLI configuration... $NoColor"
    
    if (-not (Get-Command oci -ErrorAction SilentlyContinue)) {
        Write-Host "$Red Error: OCI CLI is not installed $NoColor"
        exit 1
    }
    
    # Test OCI connectivity
    $baseCmd = Build-OciCmd -Profile $Profile
    $testCmd = "$baseCmd iam compartment get --compartment-id $CompartmentId --region $Region"
    
    try {
        Invoke-Expression $testCmd | Out-Null
    } catch {
        Write-Host "$Red Error: OCI CLI configuration test failed $NoColor"
        Write-Host "$Red Please check your OCI CLI configuration and permissions $NoColor"
        exit 1
    }
    
    Write-Host "$Green ✓ OCI CLI configuration validated $NoColor"
}

# Function to create bucket
function New-Bucket {
    Write-Host "$Yellow Creating bucket... $NoColor"
    
    $baseCmd = Build-OciCmd -Profile $Profile
    $bucketName = "ai-workshop-labs-datasets"
    
    $cmd = "$baseCmd os bucket create --compartment-id '$CompartmentId' --name '$bucketName' --region '$Region' --public-access-type NoPublicAccess --storage-tier Standard"
    
    try {
        $response = Invoke-Expression $cmd | ConvertFrom-Json
        $bucketId = $response.data.id
        $bucketId | Out-File -FilePath "temp_bucket_id.txt" -Encoding UTF8
        Write-Host "$Green ✓ Bucket created: $bucketId $NoColor"
        return $true
    } catch {
        Write-Host "$Red ✗ Failed to create bucket: $($_.Exception.Message) $NoColor"
        return $false
    }
}

# Function to upload file to bucket
function Upload-FileToBucket {
    Write-Host "$Yellow Uploading file to bucket... $NoColor"
    
    $baseCmd = Build-OciCmd -Profile $Profile
    $bucketName = "ai-workshop-labs-datasets"
    $filePath = Join-Path (Split-Path (Split-Path (Get-Location))) "labs\datasets\TripAdvisorReviewsMultiLang.md"
    $objectName = "TripAdvisorReviewsMultiLang.md"
    
    if (-not (Test-Path $filePath)) {
        Write-Host "$Red Error: File not found: $filePath $NoColor"
        return $false
    }
    
    $cmd = "$baseCmd os object put --bucket-name '$bucketName' --name '$objectName' --file '$filePath' --region '$Region'"
    
    try {
        Invoke-Expression $cmd | Out-Null
        $objectName | Out-File -FilePath "temp_object_name.txt" -Encoding UTF8
        Write-Host "$Green ✓ File uploaded: $objectName $NoColor"
        return $true
    } catch {
        Write-Host "$Red ✗ Failed to upload file: $($_.Exception.Message) $NoColor"
        return $false
    }
}

# Function to create knowledge base
function New-KnowledgeBase {
    Write-Host "$Yellow Creating knowledge base... $NoColor"
    
    $baseCmd = Build-OciCmd -Profile $Profile
    $name = "Hotel_Concierge_Knowledge_Base"
    $description = "Knowledge base containing TripAdvisor reviews for hotel concierge services"
    
    $cmd = "$baseCmd generative-ai knowledge-base create --compartment-id '$CompartmentId' --display-name '$name' --description '$description' --region '$Region'"
    
    try {
        $response = Invoke-Expression $cmd | ConvertFrom-Json
        $kbId = $response.data.id
        $kbId | Out-File -FilePath "temp_kb_id.txt" -Encoding UTF8
        Write-Host "$Green ✓ Knowledge base created: $kbId $NoColor"
        return $true
    } catch {
        Write-Host "$Red ✗ Failed to create knowledge base: $($_.Exception.Message) $NoColor"
        return $false
    }
}

# Function to create data source
function New-DataSource {
    Write-Host "$Yellow Creating data source... $NoColor"
    
    $baseCmd = Build-OciCmd -Profile $Profile
    $kbId = Get-Content "temp_kb_id.txt" -ErrorAction SilentlyContinue
    $bucketName = "ai-workshop-labs-datasets"
    $objectName = Get-Content "temp_object_name.txt" -ErrorAction SilentlyContinue
    
    # Get namespace
    $nsResponse = Invoke-Expression "$baseCmd os ns get" | ConvertFrom-Json
    $namespace = $nsResponse.data
    
    $dataSourceDetails = @{
        bucket = $bucketName
        namespace = $namespace
        object = $objectName
    } | ConvertTo-Json -Compress
    
    $cmd = "$baseCmd generative-ai knowledge-base data-source create --knowledge-base-id '$kbId' --display-name 'TripAdvisor Reviews Data Source' --description 'Data source for TripAdvisor reviews' --data-source-details '$dataSourceDetails' --region '$Region'"
    
    try {
        $response = Invoke-Expression $cmd | ConvertFrom-Json
        $dsId = $response.data.id
        $dsId | Out-File -FilePath "temp_ds_id.txt" -Encoding UTF8
        Write-Host "$Green ✓ Data source created: $dsId $NoColor"
        return $true
    } catch {
        Write-Host "$Red ✗ Failed to create data source: $($_.Exception.Message) $NoColor"
        return $false
    }
}

# Function to create agent
function New-Agent {
    param(
        [string]$Name,
        [string]$Description,
        [string]$Greeting,
        [string]$OutputFile
    )
    
    Write-Host "$Yellow Creating agent: $Name... $NoColor"
    
    $baseCmd = Build-OciCmd -Profile $Profile
    $agentConfig = @{
        greeting = $Greeting
    } | ConvertTo-Json -Compress
    
    $cmd = "$baseCmd generative-ai-agent agent create --compartment-id '$CompartmentId' --display-name '$Name' --description '$Description' --agent-config '$agentConfig' --region '$Region'"
    
    try {
        $response = Invoke-Expression $cmd | ConvertFrom-Json
        $agentId = $response.data.id
        $agentId | Out-File -FilePath $OutputFile -Encoding UTF8
        Write-Host "$Green ✓ Agent created: $agentId $NoColor"
        return $true
    } catch {
        Write-Host "$Red ✗ Failed to create agent: $($_.Exception.Message) $NoColor"
        return $false
    }
}

# Function to create RAG tool
function New-RagTool {
    Write-Host "$Yellow Creating RAG tool... $NoColor"
    
    $baseCmd = Build-OciCmd -Profile $Profile
    $agentId = Get-Content "temp_agent_id.txt" -ErrorAction SilentlyContinue
    $kbId = Get-Content "temp_kb_id.txt" -ErrorAction SilentlyContinue
    
    $toolConfig = @{
        knowledgeBaseId = $kbId
    } | ConvertTo-Json -Compress
    
    $cmd = "$baseCmd generative-ai-agent agent-tool create --agent-id '$agentId' --display-name 'Hotel_Concierge_RAG_Tool' --description 'RAG tool for hotel concierge services using TripAdvisor reviews' --tool-config '$toolConfig' --region '$Region'"
    
    try {
        $response = Invoke-Expression $cmd | ConvertFrom-Json
        $toolId = $response.data.id
        $toolId | Out-File -FilePath "temp_rag_tool_id.txt" -Encoding UTF8
        Write-Host "$Green ✓ RAG tool created: $toolId $NoColor"
        return $true
    } catch {
        Write-Host "$Red ✗ Failed to create RAG tool: $($_.Exception.Message) $NoColor"
        return $false
    }
}

# Function to create agent endpoint
function New-AgentEndpoint {
    param(
        [string]$AgentIdFile,
        [string]$Name,
        [string]$Description,
        [string]$OutputFile
    )
    
    Write-Host "$Yellow Creating endpoint: $Name... $NoColor"
    
    $baseCmd = Build-OciCmd -Profile $Profile
    $agentId = Get-Content $AgentIdFile -ErrorAction SilentlyContinue
    
    $cmd = "$baseCmd generative-ai-agent agent-endpoint create --agent-id '$agentId' --display-name '$Name' --description '$Description' --region '$Region'"
    
    try {
        $response = Invoke-Expression $cmd | ConvertFrom-Json
        $endpointId = $response.data.id
        $endpointId | Out-File -FilePath $OutputFile -Encoding UTF8
        Write-Host "$Green ✓ Endpoint created: $endpointId $NoColor"
        return $true
    } catch {
        Write-Host "$Red ✗ Failed to create endpoint: $($_.Exception.Message) $NoColor"
        return $false
    }
}

# Function to generate OCIDs file
function New-OcidsFile {
    Write-Host "$Yellow Generating OCIDs file... $NoColor"
    
    # Read all temporary files
    $bucketId = Get-Content "temp_bucket_id.txt" -ErrorAction SilentlyContinue
    $kbId = Get-Content "temp_kb_id.txt" -ErrorAction SilentlyContinue
    $dsId = Get-Content "temp_ds_id.txt" -ErrorAction SilentlyContinue
    $ragToolId = Get-Content "temp_rag_tool_id.txt" -ErrorAction SilentlyContinue
    $agentId = Get-Content "temp_agent_id.txt" -ErrorAction SilentlyContinue
    $agentAdkId = Get-Content "temp_agent_adk_id.txt" -ErrorAction SilentlyContinue
    $endpointId = Get-Content "temp_endpoint_id.txt" -ErrorAction SilentlyContinue
    $endpointAdkId = Get-Content "temp_endpoint_adk_id.txt" -ErrorAction SilentlyContinue
    
    # Create the OCIDs file
    @"
# this info will be used by ADK agent
KNOWLEDGEBASE_ID=$kbId
HOTEL_CONCIERGE_AGENT_ENDPOINT_ID=$endpointAdkId

# this other info will be used by the script to cleanup resources
HOTEL_CONCIERGE_AGENT_ID=$agentId
HOTEL_CONCIERGE_AGENT_ADK_ID=$agentAdkId
KNOWLEDGEBASE_ID=$kbId
BUCKET_ID=$bucketId
"@ | Out-File -FilePath $OCIDS_FILE -Encoding UTF8
    
    Write-Host "$Green ✓ OCIDs file generated: $OCIDS_FILE $NoColor"
}

# Function to cleanup temporary files
function Remove-TempFiles {
    Get-ChildItem -Path "temp_*.txt" -ErrorAction SilentlyContinue | Remove-Item -Force
}

# Function to display summary
function Show-Summary {
    Write-Host "$Blue ======================================== $NoColor"
    Write-Host "$Blue Setup Summary $NoColor"
    Write-Host "$Blue ======================================== $NoColor"
    Write-Host ""
    Write-Host "$Green All resources created successfully! $NoColor"
    Write-Host ""
    Write-Host "$Yellow Created Resources: $NoColor"
    Write-Host "  - Bucket: ai-workshop-labs-datasets"
    Write-Host "  - Knowledge Base: Hotel_Concierge_Knowledge_Base"
    Write-Host "  - Data Source: TripAdvisor Reviews Data Source"
    Write-Host "  - RAG Tool: Hotel_Concierge_RAG_Tool"
    Write-Host "  - Agent: Hotel_Concierge_Agent"
    Write-Host "  - Agent ADK: Hotel_Concierge_Agent_ADK"
    Write-Host "  - Endpoint: Hotel_Concierge_Agent-endpoint"
    Write-Host "  - Endpoint ADK: Hotel_Concierge_Agent_ADK-endpoint"
    Write-Host ""
    Write-Host "$Yellow Output File: $NoColor"
    Write-Host "  - $OCIDS_FILE (contains all OCIDs)"
    Write-Host ""
    Write-Host "$Yellow Next Steps: $NoColor"
    Write-Host "  - Use the OCIDs in $OCIDS_FILE for your applications"
    Write-Host "  - The ADK agent endpoint ID is: HOTEL_CONCIERGE_AGENT_ENDPOINT_ID"
    Write-Host "  - Use the cleanup script to remove resources when done"
}

# Main function
function Main {
    # Parse command line arguments
    if ($CompartmentId -eq "-h" -or $CompartmentId -eq "--help") {
        Show-Usage
        exit 0
    }
    
    # Setup configuration
    Setup-Config -CmdCompartment $CompartmentId -CmdRegion $Region -CmdProfile $Profile
    
    # Check OCI CLI
    Test-OciCli
    
    # Create resources
    if ((New-Bucket) -and 
        (Upload-FileToBucket) -and 
        (New-KnowledgeBase) -and 
        (New-DataSource) -and 
        (New-Agent -Name "Hotel_Concierge_Agent" -Description "Hotel Concierge Agent for basic interactions" -Greeting "Hello! I'm your Hotel Concierge Agent. How can I assist you with your stay today?" -OutputFile "temp_agent_id.txt") -and 
        (New-RagTool) -and 
        (New-AgentEndpoint -AgentIdFile "temp_agent_id.txt" -Name "Hotel_Concierge_Agent-endpoint" -Description "Endpoint for Hotel Concierge Agent" -OutputFile "temp_endpoint_id.txt") -and 
        (New-Agent -Name "Hotel_Concierge_Agent_ADK" -Description "Hotel Concierge Agent for ADK development" -Greeting "Hello! I'm your Hotel Concierge Agent for ADK development. I can help you with advanced hotel services and tools." -OutputFile "temp_agent_adk_id.txt") -and 
        (New-AgentEndpoint -AgentIdFile "temp_agent_adk_id.txt" -Name "Hotel_Concierge_Agent_ADK-endpoint" -Description "Endpoint for Hotel Concierge Agent ADK" -OutputFile "temp_endpoint_adk_id.txt")) {
        
        # Generate OCIDs file
        New-OcidsFile
        
        # Display summary
        Show-Summary
        
        # Cleanup temporary files
        Remove-TempFiles
        
        Write-Host "$Green 🎉 Setup completed successfully! $NoColor"
    } else {
        Write-Host "$Red Setup failed. Please check the error messages above. $NoColor"
        Remove-TempFiles
        exit 1
    }
}

# Execute main function
Main 