# OCI Generative AI Agent Setup - Hands-On Lab 1

This repository contains a setup script for creating an Oracle Cloud Infrastructure (OCI) Generative AI Agent with security features disabled for hands-on lab exercises.

## Overview

The `handson_lab1_setup.sh` script automates the creation of:

- A Generative AI Agent named "HandsOnLab1"
- An agent endpoint with security features disabled
- All necessary configuration files for easy cleanup

## Prerequisites

### 1. OCI CLI Installation

Install the OCI CLI on your system:

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

### 2. OCI CLI Configuration

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

### 3. Required Tools

Install `jq` for JSON parsing:

**macOS:**

```bash
brew install jq
```

**Linux (Ubuntu/Debian):**

```bash
sudo apt-get install jq
```

## Supported Regions

The script supports the following regions for Generative AI Agents:

- `us-chicago-1`
- `eu-frankfurt-1`
- `ap-osaka-1`

## Usage

### Basic Usage

Run the script with default settings (uses your OCI config):

```bash
./handson_lab1_setup.sh
```

### Advanced Usage

Specify compartment, region, and profile:

```bash
./handson_lab1_setup.sh [COMPARTMENT_ID] [REGION] [PROFILE]
```

### Examples

**Use defaults from ~/.oci/config:**

```bash
./handson_lab1_setup.sh
```

**Specify compartment only:**

```bash
./handson_lab1_setup.sh ocid1.compartment.oc1..xyz
```

**Specify compartment and region:**

```bash
./handson_lab1_setup.sh ocid1.compartment.oc1..xyz us-chicago-1
```

**Specify all parameters:**

```bash
./handson_lab1_setup.sh ocid1.compartment.oc1..xyz us-chicago-1 myprofile
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

The cleanup script will:

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

**4. "Region may not support Generative AI Agents"**

- Use one of the supported regions: `us-chicago-1`, `eu-frankfurt-1`, `ap-osaka-1`

**5. "Could not determine compartment ID"**

- Provide compartment ID as a command line parameter
- Ensure your OCI config has a valid tenancy OCID

### Getting Help

**Show script usage:**

```bash
./handson_lab1_setup.sh --help
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
├── handson_lab1_setup.sh    # Main setup script
├── README.md                # This file
├── cleanup_agent.sh         # Generated cleanup script
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
