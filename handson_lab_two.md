## **OCI Generative AI Agents Workshop: Building an AI-Powered Hotel Concierge**

**Story Continuation:** In our last workshop, you, as the hotel manager, were impressed by how OCI Generative AI could instantly analyze and translate a single guest review. The success of that pilot has led to a new project: creating a true "AI Concierge." Instead of looking at one review at a time, this AI agent will have knowledge of **all** guest feedback and will even be able to search for external information to help you solve guest problems more effectively.

**Use Case:** We will create a **Generative AI Agent** that uses the entire Trip Advisor review dataset as its knowledge base (a technique called Retrieval-Augmented Generation or RAG). We will then ask the agent complex questions that require it to synthesize information from multiple reviews. Finally, we'll simulate how this agent could use a function/tool to search the internet for real-time information related to a guest's comment.

**Dataset:** We will continue using the "Trip Advisor Hotel Reviews" dataset from Kaggle.

[https://www.kaggle.com/datasets/andrewmvd/trip-advisor-hotel-reviews](https://www.kaggle.com/datasets/andrewmvd/trip-advisor-hotel-reviews)

### **Part 1: The All-Knowing Concierge (RAG in the Console) \- (20 mins)**

In this part, we give our agent a memory by letting it read all the hotel reviews at once.

#### **Step 1: Create the Knowledge Base (10 mins)**

1. **Upload Dataset to Object Storage:**  
   * In the OCI Console, navigate to **Storage** \> **Object Storage & Archive Storage**.  
   * Create a new bucket named hotel-reviews-knowledge-base.  
   * Upload the tripadvisor\_hotel\_reviews.csv file you downloaded from Kaggle into this bucket.  
2. **Create a Knowledge Base in Gen AI Agents:**  
   * Navigate to **Analytics & AI** \> **AI Services** \> **Generative AI Agents**.  
   * On the left menu, click **Knowledge Bases**, then **Create knowledge base**.  
   * Name it Hotel\_Reviews\_KB.  
   * For the data source, select the hotel-reviews-knowledge-base bucket you just created. The service will now process the CSV file, making it searchable. This may take a few minutes.

#### **Step 2: Create and Test the Agent (10 mins)**

1. **Create the Agent:**  
   * On the left menu, click **Agents**, then **Create agent**.  
   * Name your agent AI\_Hotel\_Concierge.  
   * Click **Next** to go to the "Add Tool" screen.  
2. **Add the RAG Tool:**  
   * Click **Add tool** and select **Retrieval Augmented Generation**.  
   * Select the Hotel\_Reviews\_KB you created in the previous step. This connects your agent to the review data.  
   * Click **Create**.  
3. **Chat with Your Agent:**  
   * Once the agent is active, click **Launch chat**.  
   * Now, ask questions that require searching across the whole dataset. Try these prompts:  
     * "Summarize the most common positive comments people make about their rooms."  
     * "Are there any negative reviews that mention the check-in process? Please provide a quote from one of them."  
     * "What do Spanish-speaking guests say about the food?"  
   * You'll see the agent provide answers based on the content of the CSV file, complete with citations.

### **Part 2: The Problem-Solving Concierge (Simulating Function Calls) \- (10 mins)**

Now, let's give our agent a new skill: the ability to look for information *outside* of its knowledge base.

#### **Step 3: The Scenario and the Simulated Tool**

1. **The Scenario:** A guest left a review saying, "The hotel was great, but the streets were completely blocked on Saturday because of some marathon, making it impossible to get a taxi." Your agent's knowledge base contains the review, but it knows nothing about a marathon. To help the guest, you need to know what event they are talking about.  
2. **Simulating a Function Call:** In a real application built with the ADK (Agent Development Kit), you would give the agent a search\_internet(query) tool. For this console-based workshop, we will simulate this by telling the agent in our prompt to *act as if* it has this tool.

#### **Step 4: Test the Function Call Simulation**

1. **Go back to the chat** with your AI\_Hotel\_Concierge.  
2. **Use a prompt that implies a tool is needed:**  
   A guest mentioned that on October 22, 2023, their visit to the London property was disrupted by a marathon. I need to draft an apology. 

   First, act as if you have an internet search tool. Use it to find out which marathon was happening in London on that date. 

   Then, based on that information, draft a short, empathetic apology email to the guest.

3. **Review the Output:** The underlying model is smart enough to understand the instruction. It will use its general world knowledge to identify the likely marathon and then use that "retrieved" information to complete the second part of the task—drafting the email. This demonstrates the agent's reasoning capability and how it would use a tool if one were provided via code.

### **Conclusion & Value**

You have now completed the journey from a simple AI analyst to building a sophisticated AI Agent.

* **Part 1** showed how **RAG** can turn a static dataset into a dynamic, searchable knowledge base, allowing you to uncover deep insights from all your business data.  
* **Part 2** demonstrated the concept of **Function Calling**, showing how an agent can be extended to interact with external systems, find real-time information, and take action, moving from a simple chatbot to a true AI assistant.

This two-part workshop series shows the clear path for adopting Generative AI in the enterprise: start simple in the console to prove value, and then scale to powerful, integrated AI Agents to solve complex, real-world business problems.
