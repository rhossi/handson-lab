# =============================================================================
# OCI Generative AI Agent Cleanup Script - Simplified PowerShell Version
# =============================================================================
# 
# This script cleans up all OCI Generative AI resources created by the setup script.
# It reads OCIDs from the GENERATED_OCIDS.txt file and deletes resources in the
# correct dependency order.
#
# Usage: .\cleanup.ps1 [PROFILE]
#
# =============================================================================

param([string]$Profile = "DEFAULT")

$OCIDS_FILE = "GENERATED_OCIDS.txt"

# Color definitions
$Red = "`e[0;31m"
$Green = "`e[0;32m"
$Yellow = "`e[1;33m"
$Blue = "`e[0;34m"
$NoColor = "`e[0m"

Write-Host "$Yellow Cleaning up OCI Generative AI resources (profile: $Profile)... $NoColor"

# Function to build base OCI command with profile
function Build-OciCmd {
    param([string]$Profile)
    
    if ($Profile -eq "DEFAULT") {
        return "oci"
    } else {
        return "oci --profile $Profile"
    }
}

# Function to read OCID from GENERATED_OCIDS.txt
function Get-Ocid {
    param([string]$Key)
    
    if (Test-Path $OCIDS_FILE) {
        $content = Get-Content $OCIDS_FILE
        $line = $content | Where-Object { $_ -match "^$Key=" }
        if ($line) {
            return $line.Split('=')[1]
        }
    }
    return ""
}

# Check if OCIDs file exists
if (-not (Test-Path $OCIDS_FILE)) {
    Write-Host "$Red Error: $OCIDS_FILE not found $NoColor"
    Write-Host "$Yellow Make sure you're running this script from the directory where the setup script was executed. $NoColor"
    exit 1
}

# Track if any cleanup operations were performed
$cleanupPerformed = $false
$baseCmd = Build-OciCmd -Profile $Profile

# Clean up agent endpoints first (dependency order)
$endpointId = Get-Ocid -Key "HOTEL_CONCIERGE_AGENT_ENDPOINT_ID"
if ($endpointId) {
    $cleanupPerformed = $true
    Write-Host "$Yellow Deleting Hotel Concierge ADK agent endpoint... $NoColor"
    
    $cmd = "$baseCmd generative-ai-agent agent-endpoint delete --agent-endpoint-id '$endpointId' --force --wait-for-state DELETED --max-wait-seconds 1800"
    
    try {
        Invoke-Expression $cmd | Out-Null
        Write-Host "$Green ✓ Hotel Concierge ADK agent endpoint deleted $NoColor"
    } catch {
        Write-Host "$Red ✗ Failed to delete Hotel Concierge ADK agent endpoint $NoColor"
    }
}

# Clean up agents
$agentId = Get-Ocid -Key "HOTEL_CONCIERGE_AGENT_ID"
if ($agentId) {
    $cleanupPerformed = $true
    Write-Host "$Yellow Deleting Hotel Concierge agent... $NoColor"
    
    $cmd = "$baseCmd generative-ai-agent agent delete --agent-id '$agentId' --force --wait-for-state DELETED --max-wait-seconds 1800"
    
    try {
        Invoke-Expression $cmd | Out-Null
        Write-Host "$Green ✓ Hotel Concierge agent deleted $NoColor"
    } catch {
        Write-Host "$Red ✗ Failed to delete Hotel Concierge agent $NoColor"
    }
}

$agentAdkId = Get-Ocid -Key "HOTEL_CONCIERGE_AGENT_ADK_ID"
if ($agentAdkId) {
    $cleanupPerformed = $true
    Write-Host "$Yellow Deleting Hotel Concierge ADK agent... $NoColor"
    
    $cmd = "$baseCmd generative-ai-agent agent delete --agent-id '$agentAdkId' --force --wait-for-state DELETED --max-wait-seconds 1800"
    
    try {
        Invoke-Expression $cmd | Out-Null
        Write-Host "$Green ✓ Hotel Concierge ADK agent deleted $NoColor"
    } catch {
        Write-Host "$Red ✗ Failed to delete Hotel Concierge ADK agent $NoColor"
    }
}

# Clean up knowledge base
$kbId = Get-Ocid -Key "KNOWLEDGEBASE_ID"
if ($kbId) {
    $cleanupPerformed = $true
    Write-Host "$Yellow Deleting knowledge base... $NoColor"
    
    $cmd = "$baseCmd generative-ai knowledge-base delete --knowledge-base-id '$kbId' --force --wait-for-state DELETED --max-wait-seconds 1800"
    
    try {
        Invoke-Expression $cmd | Out-Null
        Write-Host "$Green ✓ Knowledge base deleted $NoColor"
    } catch {
        Write-Host "$Red ✗ Failed to delete knowledge base $NoColor"
    }
}

# Clean up bucket
$bucketId = Get-Ocid -Key "BUCKET_ID"
if ($bucketId) {
    $cleanupPerformed = $true
    Write-Host "$Yellow Deleting bucket and contents... $NoColor"
    
    # Delete all objects in the bucket first
    Write-Host "$Yellow Deleting objects from bucket... $NoColor"
    $cmd = "$baseCmd os object bulk-delete --bucket-name 'ai-workshop-labs-datasets' --force"
    try {
        Invoke-Expression $cmd | Out-Null
    } catch {
        Write-Host "$Yellow Warning: Could not delete bucket objects $NoColor"
    }
    
    # Delete the bucket
    $cmd = "$baseCmd os bucket delete --bucket-name 'ai-workshop-labs-datasets' --force"
    try {
        Invoke-Expression $cmd | Out-Null
        Write-Host "$Green ✓ Bucket deleted $NoColor"
    } catch {
        Write-Host "$Red ✗ Failed to delete bucket $NoColor"
    }
}

# Clean up OCIDs file
if (Test-Path $OCIDS_FILE) {
    Remove-Item $OCIDS_FILE -Force
    Write-Host "$Green ✓ OCIDs file removed $NoColor"
}

# Provide appropriate final message
if ($cleanupPerformed) {
    Write-Host "$Green Cleanup complete! $NoColor"
} else {
    Write-Host "$Yellow No cleanup performed - no valid OCIDs found in $OCIDS_FILE. $NoColor"
}
