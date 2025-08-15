## **OCI Generative AI Agents Workshop: Building an AI-Powered Hotel Concierge**

**Story Continuation:** In our last workshop, you, as the hotel manager, were impressed by how OCI Generative AI could instantly analyze and translate a single guest review. The success of that pilot has led to a new project: creating a true "AI Concierge." Instead of looking at one review at a time, this AI agent will have knowledge of **all** guest feedback. Now, using the OCI Agent Development Kit (ADK), we will give it a real tool to search the internet and solve guest problems with live information.

**Use Case:** We will create a **Generative AI Agent** that uses the entire Trip Advisor review dataset as its knowledge base (RAG). We will then use a local Python script and the OCI ADK to enhance this agent with a custom web\_search tool, allowing it to answer questions that require both internal knowledge and real-time external information.

**Dataset:** We will continue using the "Trip Advisor Hotel Reviews" dataset from Kaggle.

[https://www.kaggle.com/datasets/andrewmv/trip-advisor-hotel-reviews](https://www.google.com/search?q=https://www.kaggle.com/datasets/andrewmv/trip-advisor-hotel-reviews)

### **Part 1: Console Setup and RAG Test (20 mins)**

*In this part, we will prepare the necessary resources and test the RAG functionality in the OCI Console.*

#### **Step 1: Create the Knowledge Base**

1. **Upload Dataset to Object Storage:**  
   * In the OCI Console, navigate to **Storage** \> **Object Storage & Archive Storage**.  
   * Create a new bucket named hotel-reviews-knowledge-base.  
   * Upload the tripadvisor\_hotel\_reviews.csv file into this bucket.  
2. **Create a Knowledge Base in Gen AI Agents:**  
   * Navigate to **Analytics & AI** \> **AI Services** \> **Generative AI Agents**.  
   * On the left menu, click **Knowledge Bases**, then **Create knowledge base**.  
   * Name it Hotel\_Reviews\_KB.  
   * For the data source, select the hotel-reviews-knowledge-base bucket.

#### **Step 2: Create, Test, and Prepare the Agent**

1. **Create the Agent with RAG Tool:**  
   * On the left menu, click **Agents**, then **Create agent**.  
   * Name your agent AI\_Hotel\_Concierge.  
   * Click **Next**.  
   * Click **Add tool** and select **Retrieval Augmented Generation**.  
   * Select the Hotel\_Reviews\_KB you created.  
   * Click **Next**.  
2. **Create an Endpoint:**  
   * On the next screen, select **Automatically create an endpoint for this agent**. This is essential for the ADK to connect later.  
   * Click **Next**, then **Create agent**.  
3. **Chat with and Test Your RAG Agent:**  
   * Once the agent is active, click **Launch chat**.  
   * Test its knowledge from the dataset to confirm the RAG tool is working:  
     * "Summarize the most common positive comments people make about their rooms."  
     * "Are there any negative reviews that mention the check-in process?"  
4. **Gather Required OCIDs:**  
   * Navigate to the **Knowledge Bases** page, click on your Hotel\_Reviews\_KB, and copy its **OCID**.  
   * Navigate to the **Agents** page, click on your AI\_Hotel\_Concierge agent, go to the **Endpoints** tab, and copy the **Endpoint OCID**.  
   * Save these two OCIDs. You will need them for the Python script.

### **Part 2: The Problem-Solving Concierge (Live Tool with OCI ADK) \- (15 mins)**

*This part moves from the console to your local machine to run the Python script.*

#### **Step 3: Create and Run the ADK Script**

1. **Setup Your Local Environment:**  
   * Ensure you have Python 3.10+ and an OCI configuration file (\~/.oci/config).  
   * Create and activate a virtual environment:  
     python3 \-m venv oci-agent-env  
     source oci-agent-env/bin/activate

   * Install libraries:  
     pip install "oci\[adk\]" requests

2. **Create the Python Script:**  
   * Create a new file named run\_concierge\_agent.py.  
   * Copy the following code into this file.

from oci.addons.adk import Agent, AgentClient, tool  
from oci.addons.adk.tool.prebuilt import AgenticRagTool  
import requests  
import json  
import os

@tool  
def web\_search(query: str):  
    """  
    Performs a web search using the Tavily API.

    Args:  
        query: The search query string.

    Returns:  
        A dictionary with the search results or an error message string.  
    """  
    \# The API endpoint URL  
    url \= "https://api.tavily.com/search"

    \# \--- IMPORTANT \---  
    \# Replace with your actual Tavily API key.  
    \# It's recommended to store this securely, e.g., as an environment variable  
    api\_key \= "tvly-dev-\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*" 

    \# The headers for the request  
    headers \= {  
        "Content-Type": "application/json",  
        "Authorization": f"Bearer {api\_key}",  
    }  
    payload \= {  
        "query": query  
    }

    try:  
        response \= requests.post(url, headers=headers, json=payload)  
        response.raise\_for\_status()   
        return response.json()  
    except requests.exceptions.RequestException as e:  
        return f"An error occurred: {e}"

def main():  
    """  
    Initializes the AgentClient, defines tools, sets up the agent, and runs a query.  
    """  
    client \= AgentClient(  
        auth\_type="api\_key",  
        profile="DEFAULT",  
        region="us-chicago-1" \# Ensure this matches your agent's region  
    )

    \# \--- IMPORTANT \---  
    \# Replace with the Knowledge Base OCID you copied from the OCI Console.  
    knowledge\_base\_id \= "\<replace with your knowledge base id\>"

    \# Create a RAG tool that uses the knowledge base.  
    user\_review\_rag\_tool \= AgenticRagTool(  
        name="User\_Review\_RAG\_tool",  
        description="Use this tool to retrieve user reviews from the knowledge base.",  
        knowledge\_base\_ids=\[knowledge\_base\_id\],  
    )

    \# Create the agent instance.  
    agent \= Agent(  
        client=client,  
        \# \--- IMPORTANT \---  
        \# Replace with the Agent Endpoint OCID you copied from the OCI Console.  
        agent\_endpoint\_id="\<replace with your agent endpoint id\>",  
        instructions="You are a Hotel Concierge. You are responsible for analyzing and responding to user reviews.",  
        tools=\[user\_review\_rag\_tool, web\_search\]  
    )

    \# The setup() command synchronizes the tools with the agent in the OCI service.  
    print("Setting up agent and synchronizing tools...")  
    agent.setup()  
    print("Setup complete.")

    \# Define the user query to run against the agent.  
    input\_query \= """  
        A guest mentioned that on October 22, 2023, their visit to the London property was disrupted by a marathon. I need to draft an apology.  
        First, use your web\_search tool to find out which marathon was happening in London on that date.  
        Then, based on that information, draft a short, empathetic apology email to the guest.  
    """

    print("\\nRunning query against the agent...")  
    response \= agent.run(input\_query)

    print("\\n--- Agent Response \---")  
    response.pretty\_print()

if \_\_name\_\_ \== "\_\_main\_\_":  
    main()

3. **Update Placeholders in the Script:**  
   * Replace \<replace with your knowledge base id\> with the Knowledge Base OCID.  
   * Replace \<replace with your agent endpoint id\> with the Agent Endpoint OCID you just gathered.  
   * Replace the placeholder tvly-dev-\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\* with your Tavily AI API key.  
4. **Run the Agent:**  
   * Execute the script from your terminal:  
     python run\_concierge\_agent.py

   * The script will connect to your existing agent. The agent.setup() command will synchronize the tools, notice the new web\_search tool in your code, and add it to your agent's capabilities without removing the RAG tool you added in the console. It will then run the query and print the final response.

### **Conclusion & Value**

You have now successfully built and extended a Generative AI Agent with a custom, live tool.

* **Part 1** showed how **RAG** can turn a static dataset into a dynamic, searchable knowledge base, allowing you to uncover deep insights from all your business data directly in the OCI console.  
* **Part 2** demonstrated how the **OCI ADK** bridges the gap between the AI agent in the cloud and your own custom code. By adding a web\_search tool, you transformed the agent from a simple data retriever into an active problem-solver that can use real-time, external information to take action.

This two-part workshop series shows the clear path for adopting Generative AI in the enterprise: start simple in the console to prove value, and then scale to powerful, integrated AI Agents to solve complex, real-world business problems.
