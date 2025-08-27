# OCI Generative AI Agent Setup - Hands-On Lab 1

This repository contains cross-platform setup scripts for creating an Oracle Cloud Infrastructure (OCI) Generative AI Agent with security features disabled for hands-on lab exercises.

## Overview

The setup scripts automate the creation of:

- A Generative AI Agent named "HandsOnLab1"
- An agent endpoint with security features disabled
- All necessary configuration files for easy cleanup

## Quick Start

### 1. Setup

#### Setting up Git and Git LFS

**macOS:**

```bash
brew install git
brew install git-lfs
git lfs install
```

**Windows:**

1. Download and install Git from [git-scm.com](https://git-scm.com/download/win).
2. Download and install Git LFS from [git-lfs.github.com](https://git-lfs.github.com/).
3. Open a new Git Bash or terminal window and run:

    ```bash
    git lfs install
    ```

**Linux (Ubuntu/Debian):**

```bash
sudo apt-get update
sudo apt-get install git
curl -s https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh | sudo bash
sudo apt-get install git-lfs
git lfs install
```

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

### 2. Download/Clone the Repository and Setup the environment

```bash
# OCI CloudShell
csruntimectl python set python-3.12

# macOS/Linux/Windows
git clone git@github.com:rhossi/handson-lab.git
cd handson-lab
uv venv

# macOS/Linux
source .venv/bin/activate

# Windows
.venv/bin/activate.ps1

# macOS/Linux/Windows
uv pip install -e .
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
.lab2/handson_lab1_setup.sh
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
- **Wait State:** SUCCEEDED (waits for successful creation)

### 3. Endpoint Creation

Creates an agent endpoint with:

- **Security Features:** All disabled for lab purposes
- **Content Moderation:** Disabled
- **Session Configuration:** 1-hour idle timeout
- **Wait State:** SUCCEEDED  (waits for successful creation)

### 4. Output Files

The script creates several files for reference:

- `agent_id.txt` - The created agent's OCID
- `endpoint_id.txt` - The created endpoint's OCID
- `endpoint_url.txt` - The endpoint URL for API calls
- `cleanup_agent.sh` - Script to delete the agent and endpoint

## Security Configuration

⚠️ **Important:** This setup disables security features for lab purposes:

- **Content Moderation:** DISABLED
- **Prompt Injection Protection:** DISABLED  
- **PII Detection:** DISABLED

**Do not use this configuration in production environments.**

## Testing Your Agent

### 1. OCI Console Testing

1. Go to OCI Console → Analytics & AI → Generative AI Agents
2. Find your "HandsOnLab1" agent
3. Use the built-in chat interface to test

### 2. Using Agent Development Kit (ADK)

```bash
# Create and activate new virtual environment and install OCI and ADK
uv init
source .venv/bin/activate
uv add oci
uv add "oci[adk]"
```

```python
# Copy the endpoint_id from the endpoint_id.txt file and create your agent
from typing import Dict, Any
from oci.addons.adk import Agent, AgentClient, tool

@tool
def get_weather(location: str) -> Dict[str, Any]:
    """Get the weather for a given location.

    Args:
      location(str): The location for which weather is queried
    """
    return {"location": location, "temperature": 72, "unit": "F"}


def main():
    client = AgentClient(
        auth_type="api_key",
        region="us-chicago-1"
    )

    agent = Agent(
        client=client,
        agent_endpoint_id="<<get the endpoint from the endpoint_id.txt file in your lab home folder>>",
        instructions="Perform weather queries using the given tools",
        tools=[get_weather]
    )

    agent.setup()

    input = "Is it cold in Seattle?"
    response = agent.run(input)

    response.pretty_print()

if __name__ == "__main__":
    main()
```

```bash
# Run your agent
python main.py
```

## Cleanup

When you're done with the lab, clean up the resources:

### macOS/Linux

```bash
./cleanup_agent.sh [PROFILE]
```

**Examples:**

```bash
# Use default profile
./cleanup_agent.sh

# Use specific profile
./cleanup_agent.sh myprofile
```

### Windows

```powershell
.\cleanup_agent.ps1 [PROFILE]
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

## Troubleshooting

### Common Issues

**1. "Invalid value for '--wait-for-state': invalid choice: ACTIVE"**

- ✅ **Fixed:** The script now uses `SUCCEEDED` instead of `ACTIVE`

**2. "OCI CLI not properly configured"**

- Run `oci setup config` to configure your credentials
- Ensure your ~/.oci/config file exists and is properly formatted

**3. "jq is required but not installed"**

- Install jq: `brew install jq` (macOS) or `sudo apt-get install jq` (Linux)
- **Windows users:** Use the PowerShell script which doesn't require jq

**4. "Region may not support Generative AI Agents"**

- Use one of the supported regions: `us-chicago-1`, `eu-frankfurt-1`, `ap-osaka-1`

**5. "Could not determine compartment ID"**

- Provide compartment ID as a command line parameter
- Ensure your OCI config has a valid tenancy OCID

### Getting Help

**Show script usage:**

```bash
# macOS/Linux
./handson_lab1_setup.sh --help

# Windows
.\handson_lab1_setup.ps1 --help
```

**Check OCI CLI version:**

```bash
oci --version
```

**Test OCI CLI configuration:**

```bash
oci iam compartment list --limit 1
```

## File Structure

```
HandsOnLab1/
├── handson_lab1_setup.sh    # Main setup script (macOS/Linux)
├── handson_lab1_setup.ps1   # Main setup script (Windows)
├── cleanup_agent.sh         # Generated cleanup script (macOS/Linux)
├── cleanup_agent.ps1        # Generated cleanup script (Windows)
├── README.md                # This file
├── agent_id.txt            # Generated agent OCID
├── endpoint_id.txt         # Generated endpoint OCID
└── endpoint_url.txt        # Generated endpoint URL
```

## Next Steps

After successful setup:

1. **Test the agent** using the OCI Console
2. **Explore the API** using the endpoint URL
3. **Integrate with applications** using the provided credentials
4. **Clean up resources** when finished

## Support

For issues with:

- **OCI CLI:** [Oracle CLI Documentation](https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/cliinstall.htm)
- **Generative AI Agents:** [OCI Generative AI Documentation](https://docs.oracle.com/en-us/iaas/Content/generative-ai/home.htm)
- **API Reference:** [OCI API Documentation](https://docs.oracle.com/en-us/iaas/api/)

---

**Note:** This setup is designed for educational purposes and hands-on labs. Always review security configurations before using in production environments.
