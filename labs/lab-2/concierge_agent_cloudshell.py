from oci.addons.adk import Agent, AgentClient, tool
from oci.addons.adk.tool.prebuilt import AgenticRagTool
import requests
import json
import os
from dotenv import load_dotenv
import oci

# Load environment variables from .env file
load_dotenv()

# Load configuration from environment variables
TAVILY_API_KEY = os.getenv("TAVILY_API_KEY")
AGENT_ENDPOINT_ID = os.getenv("AGENT_ENDPOINT_ID")
KNOWLEDGE_BASE_ID = os.getenv("KNOWLEDGE_BASE_ID")

# Validate that required environment variables are set
if not TAVILY_API_KEY:
    raise ValueError("TAVILY_API_KEY environment variable is required")
if not AGENT_ENDPOINT_ID:
    raise ValueError("AGENT_ENDPOINT_ID environment variable is required")
if not KNOWLEDGE_BASE_ID:
    raise ValueError("KNOWLEDGE_BASE_ID environment variable is required")

print(f"Using Agent Endpoint ID: {AGENT_ENDPOINT_ID}")
print(f"Using Knowledge Base ID: {KNOWLEDGE_BASE_ID}")

@tool
def web_search(query: str):
    """
    Performs a web search using the Tavily API.

    Args:
        query: The search query string.

    Returns:
        A dictionary with the search results or an error message string.
    """
    # The API endpoint URL
    url = "https://api.tavily.com/search"

    # Use the API key from environment variables
    api_key = TAVILY_API_KEY 

    # The headers for the request, including content type and authorization
    headers = {
        "Content-Type": "application/json",
        "Authorization": f"Bearer {api_key}",
    }

    # The data payload for the request, using the function's query argument
    payload = {
        "query": query,
        "search_depth": "advanced"
    }

    try:
        # Make the POST request to the API
        response = requests.post(url, headers=headers, json=payload)

        # Raise an exception for bad status codes (4xx or 5xx)
        response.raise_for_status() 

        # Return the JSON response from the API
        return response.json()

    except requests.exceptions.HTTPError as errh:
        return f"Http Error: {errh}"
    except requests.exceptions.ConnectionError as errc:
        return f"Error Connecting: {errc}"
    except requests.exceptions.Timeout as errt:
        return f"Timeout Error: {errt}"
    except requests.exceptions.RequestException as err:
        return f"Oops: Something Else: {err}"


def main():
    print("=== OCI Cloud Shell Agent Setup ===")
    print(f"Configured Agent Endpoint ID: {AGENT_ENDPOINT_ID}")
    print(f"Configured Knowledge Base ID: {KNOWLEDGE_BASE_ID}")
    print()

    # For Cloud Shell, try different authentication methods
    client = None
    
    # Method 1: Try using the same config as OCI CLI
    try:
        print("Trying to use OCI CLI configuration...")
        import oci.config
        config = oci.config.from_file()
        client = AgentClient(
            config=config,
            region="us-chicago-1"
        )
        print("✓ Successfully initialized AgentClient using CLI config")
    except Exception as e:
        print(f"✗ Failed to initialize with CLI config: {e}")
        
        # Method 2: Try instance principal authentication
        try:
            print("Trying instance principal authentication...")
            client = AgentClient(
                auth_type="instance_principal",
                region="us-chicago-1"
            )
            print("✓ Successfully initialized AgentClient using instance principal")
        except Exception as e2:
            print(f"✗ Failed to initialize with instance principal: {e2}")
            
            # Method 3: Try using environment variables
            try:
                print("Trying environment-based authentication...")
                client = AgentClient(
                    region="us-chicago-1"
                )
                print("✓ Successfully initialized AgentClient using environment auth")
            except Exception as e3:
                print(f"✗ Failed to initialize with environment auth: {e3}")
                raise RuntimeError("All authentication methods failed. Please check your OCI configuration.")

    print("\n=== Checking Agent Endpoint Access ===")

    # First, let's try to directly access the configured agent endpoint
    try:
        print(f"Trying to access configured agent endpoint: {AGENT_ENDPOINT_ID}")
        response = client._mgmt_client.get_agent_endpoint(AGENT_ENDPOINT_ID)
        print(f"✓ Agent endpoint found: {response.data.display_name}")
        print(f"  Status: {response.data.lifecycle_state}")
        print(f"  Compartment: {response.data.compartment_id}")

        # If we can access it, proceed with the rest of the setup
        return setup_and_run_agent(client)

    except Exception as e:
        print(f"✗ Agent endpoint verification failed: {e}")
        print("\nThis could mean:")
        print("1. The agent endpoint ID in your .env file is incorrect")
        print("2. The agent endpoint doesn't exist")
        print("3. You don't have permission to access it")
        print()

    print("=== Checking for Available Agent Endpoints ===")

    # Try to list agent endpoints without specifying compartment
    try:
        print("Attempting to list all accessible agent endpoints...")
        response = client._mgmt_client.list_agent_endpoints()
        available_endpoints = response.data
        print(f"✓ Found {len(available_endpoints)} agent endpoints")
    except Exception as e:
        print(f"✗ Failed to list agent endpoints: {e}")

        # Try with a common compartment ID
        try:
            print("Trying with common compartment ID...")
            response = client._mgmt_client.list_agent_endpoints(
                compartment_id="ocid1.compartment.oc1..aaaaaaaawkt7k4dmzrmcu6xtxkq4eyqoea5uma4n63lyfmpptjqdsda2qkkq"
            )
            available_endpoints = response.data
            print(f"✓ Found {len(available_endpoints)} agent endpoints in common compartment")
        except Exception as e2:
            print(f"✗ Failed to list agent endpoints in common compartment: {e2}")
            available_endpoints = []

    if available_endpoints:
        print("\nAvailable Agent Endpoints:")
        for i, endpoint in enumerate(available_endpoints, 1):
            print(f"  {i}. {endpoint.id}")
            print(f"     Name: {endpoint.display_name}")
            print(f"     Status: {endpoint.lifecycle_state}")
            print(f"     Compartment: {endpoint.compartment_id}")
            print()

        print("Please update your .env file with one of the available endpoint IDs above.")
        print("Then re-run the script.")
        return
    else:
        print("\nNo agent endpoints found!")
        print("\nThis means you need to create an agent endpoint first.")
        print("\nSteps to create an agent endpoint:")
        print("1. Go to OCI Console: https://cloud.oracle.com")
        print("2. Navigate to AI Services > Generative AI Agents")
        print("3. Click 'Create Agent Endpoint'")
        print("4. Follow the setup wizard")
        print("5. Copy the agent endpoint OCID to your .env file")
        print("\nAlternatively, if you're following a lab guide:")
        print("- Check if the lab has specific instructions for creating agent endpoints")
        print("- Verify you're in the correct compartment")
        print("- Check if the lab provides pre-created agent endpoints")
        return


def setup_and_run_agent(client):
    """Setup and run the agent once we have a valid endpoint"""
    # Create a RAG tool that uses the knowledge base
    print(f"\nCreating RAG tool with knowledge base: {KNOWLEDGE_BASE_ID}")
    user_review_rag_tool = AgenticRagTool(
        name="User Review RAG tool",
        description="Use this tool to retrieve user reviews from the knowledge base.",
        knowledge_base_ids=[KNOWLEDGE_BASE_ID],
    )

    # Create the agent with the RAG tool
    print("Creating agent...")
    agent = Agent(
        client=client,
        agent_endpoint_id=AGENT_ENDPOINT_ID,
        instructions="You are a Hotel Concierge. You are responsible for analyzing and responding to user reviews. You can use a RAG search tool to find information about the users reviews, and a web search tool to find any additional information you need.",
        tools=[user_review_rag_tool, web_search]
    )

    # Set up the agent once
    print("Setting up agent...")
    try:
        agent.setup()
        print("✓ Agent setup completed successfully")
    except Exception as e:
        print(f"✗ Agent setup failed: {e}")
        raise

    # Run the agent with a user query
    print("\nRunning agent with query...")
    input = """
        A guest mentioned share the following review:

        "I stayed here on August 15th at your hotel in Gunnersbury Park and it was one of the worst nights of my trip.
        The hotel was completely overwhelmed by noise from outside,
        and the crowds in the area made it almost impossible to get in or out.
        Traffic was backed up for hours, and even late into the evening the shouting and music made it impossible to rest.
        For a supposedly quiet neighborhood, the disruption was unacceptable"

        First, act as if you have an internet search tool. Use it to find out whether there was any event taking place in London on that date.

        Then, based on that information, draft a short, empathetic apology email to the guest.
    """

    try:
        response = agent.run(input)
        print("\n=== Agent Response ===")
        response.pretty_print()
    except Exception as e:
        print(f"✗ Agent execution failed: {e}")
        raise

if __name__ == "__main__":
    main()
