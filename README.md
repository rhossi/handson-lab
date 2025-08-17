# Hands-On Lab Setup

This repository contains cross-platform setup scripts for creating an Oracle Cloud Infrastructure (OCI) Generative AI Agent with security features disabled for hands-on lab exercises.

## Overview

The setup scripts automate the creation of the infrastructure required by :

- Generative AI Agents and endpoints
- Knowledge Bases
- RAG Tools
- An agent endpoint with security features disabled
- All necessary configuration files for easy cleanup

## Quick Start

### 1. Setup

#### Setting up UV

**macOS/Linux:**

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

**Windows:**

```powershell
powershell -c "irm https://astral.sh/uv/install.ps1 | iex"
```

#### Setting up OCI CLI

**macOS (using Homebrew):**

```bash
brew install oci-cli
```

**Linux (Ubuntu/Debian):**

```bash
bash -c "$(curl -L https://raw.githubusercontent.com/oracle/oci-cli/master/scripts/install/install.sh)"
```

**Windows:**
Download and install from [Oracle's official documentation](https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/cliinstall.htm)

#### OCI CLI Configuration

Configure your OCI CLI with your credentials:

```bash
oci setup config
```

You'll need:

- Tenancy OCID
- User OCID  
- Region
- Private key file path
- Fingerprint

### 2. Download/Clone the Repository

```bash
git clone git@github.com:rhossi/handson-lab.git
cd handson-lab
```

Or download the repository as a ZIP file and extract it to your desired location.

### 3. Installing Dependencies

**For macOS/Linux:**

Install `jq` for JSON parsing:

```bash
# macOS
brew install jq

# Linux (Ubuntu/Debian)
sudo apt-get install jq
```

**For Windows:**
PowerShell 5.1 or later is required (included with Windows 10/11). No additional tools needed.

## Available Scripts (optional)

This step is optional. Setting up the required lab infrastructure takes about 30 minutes. You can either create everything manually by following the lab guide or run the provided scripts to automate the setup and save time.

| Platform | Script | Description |
|----------|--------|-------------|
| **macOS/Linux** | `lab-2/setup.sh` | Bash script for Unix-based systems |
| **Windows** | `lab-2/setup.ps1` | PowerShell script for Windows |
| **Cleanup (macOS/Linux)** | `lab-2/cleanup.sh` | Bash cleanup script |
| **Cleanup (Windows)** | `lab-2/cleanup.ps1` | PowerShell cleanup script |

## Supported Regions

The script supports the following regions for Generative AI Agents:

- `us-chicago-1`
- `eu-frankfurt-1`
- `ap-osaka-1`

## Usage

### macOS/Linux (Bash)

**Basic Usage:**

Run the script with default settings (uses your OCI config):

```bash
chmod +x lab-2/setup.sh
.lab2/setup.sh
```

**Advanced Usage:**

Specify compartment, region, and profile:

```bash
.lab2/setup.sh [COMPARTMENT_ID] [REGION] [PROFILE]
```

**Examples:**

```bash
# Use defaults from ~/.oci/config
./lab2/setup.sh

# Specify compartment only
./lab2/setup.sh ocid1.compartment.oc1..xyz

# Specify compartment and region
./lab2/setup.sh ocid1.compartment.oc1..xyz us-chicago-1

# Specify all parameters
./lab2/setup.sh ocid1.compartment.oc1..xyz us-chicago-1 myprofile
```

### Windows (PowerShell)

**Basic Usage:**

Run the script with default settings (uses your OCI config):

```powershell
.\lab-2\setup.ps1
```

**Advanced Usage:**

Specify compartment, region, and profile:

```powershell
.\lab-2\setup.ps1 [COMPARTMENT_ID] [REGION] [PROFILE]
```

**Examples:**

```powershell
# Use defaults from ~/.oci/config
.\lab-2\setup.ps1

# Specify compartment only
.\lab-2\setup.ps1 ocid1.compartment.oc1..xyz

# Specify compartment and region
.\lab-2\setup.ps1 ocid1.compartment.oc1..xyz us-chicago-1

# Specify all parameters
.\setup.ps1 ocid1.compartment.oc1..xyz us-chicago-1 myprofile
```

**Note for Windows Users:**

If you encounter execution policy restrictions, you may need to run:

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

## What the Script Does

### 1. Configuration Setup

- Validates OCI CLI configuration
- Determines compartment ID (uses tenancy if not specified)
- Sets region (from config or command line)
- Validates region support for Generative AI Agents

### 2. Agent Creation

Creates a Generative AI Agent with:

- **Name:** HandsOnLab1
- **Description:** Generative AI Agent for Hands-On Lab - Security features disabled
- **Welcome Message:** "Hello! I'm HandsOnLab1, your AI assistant. How can I help you today?"
- **Wait State:** SUCCEEDED (waits for successful creation)

### 3. Endpoint Creation

Creates an agent endpoint with:

- **Security Features:** All disabled for lab purposes
- **Content Moderation:** Disabled
- **Session Configuration:** 1-hour idle timeout
- **Wait State:** SUCCEEDED

### 4. Output Files

The script creates several files for reference.

- `*-agent_id.txt` - The created agent's OCID
- `*-endpoint_id.txt` - The created endpoint's OCID
- `*-endpoint_url.txt` - The endpoint URL for API calls
- `*-cleanup_agent.sh` - Script to delete the agent and endpoint

## Security Configuration

⚠️ **Important:** This setup disables security features for lab purposes:

- **Content Moderation:** DISABLED
- **Prompt Injection Protection:** DISABLED  
- **PII Detection:** DISABLED

**Do not use this configuration in production environments.**

## Cleanup

When you're done with the lab, clean up the resources:

### macOS/Linux

```bash
./lab-2/cleanup_agent.sh [PROFILE]
```

**Examples:**

```bash
# Use default profile
./lab-2/cleanup_agent.sh

# Use specific profile
./lab-2/cleanup_agent.sh myprofile
```

### Windows

```powershell
.\lab-2\cleanup_agent.ps1 [PROFILE]
```

**Examples:**

```powershell
# Use default profile
.\cleanup_agent.ps1

# Use specific profile
.\cleanup_agent.ps1 myprofile
```

The cleanup scripts will:

1. Delete the agent endpoint
2. Delete the agent
3. Remove temporary files

## Support

For issues with:

- **OCI CLI:** [Oracle CLI Documentation](https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/cliinstall.htm)
- **Generative AI Agents:** [OCI Generative AI Documentation](https://docs.oracle.com/en-us/iaas/Content/generative-ai/home.htm)
- **API Reference:** [OCI API Documentation](https://docs.oracle.com/en-us/iaas/api/)

---

**Note:** This setup is designed for educational purposes and hands-on labs. Always review security configurations before using in production environments.
