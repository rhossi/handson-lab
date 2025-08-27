## **OCI Generative AI Agents Workshop: Building an Agentic Hotel Concierge**

**Maria's Next Challenge - From Individual Reviews to Pattern Recognition:**

Three months have passed since Maria, the General Manager of the Grand Plaza Hotel in Ho Chi Minh City, implemented her AI-powered review analysis system. The transformation has been remarkable - she can now instantly understand and respond to reviews in any language, from Vietnamese to Chinese to Korean. Her response times have improved dramatically, and guest satisfaction scores are up.

But Maria has discovered a new challenge that's even more complex than language barriers.

**The Pattern Problem:**

While Maria can now analyze individual reviews with perfect accuracy, she has no way to know whether a guest's complaint is an isolated incident or part of a larger pattern affecting many customers. For example:

- When a guest complained about "noisy construction work" last week, Maria responded with a standard apology and room discount. But what if this was the 20th similar complaint this month?
- When a business traveler mentioned "slow Wi-Fi in the conference room," Maria had no way to check if this was a recurring issue across multiple guests.
- When a guest mentioned being "disrupted by a marathon event," Maria had to manually search the internet to understand what event they were referring to.

**The Manual Research Burden:**

Maria's team now spends hours every day:

- Manually searching through spreadsheets to find similar complaints
- Checking multiple review platforms (TripAdvisor, Booking.com, Google Reviews) for patterns
- Researching external events and information on the internet
- Cross-referencing dates, locations, and guest types to identify trends

This manual process is:

- **Time-consuming** - taking hours that could be spent on guest service
- **Error-prone** - missing important patterns due to human oversight
- **Inconsistent** - different staff members might interpret patterns differently
- **Reactive** - only identifying problems after they've affected multiple guests

**The Real Cost:**

Last month, Maria discovered that 47 guests had complained about the same Wi-Fi issue over a three-week period. By the time her team manually identified this pattern, the problem had already affected guest satisfaction scores and led to several negative social media posts. The cost of this delayed response was estimated at $15,000 in lost bookings and reputation damage.

Maria needs a solution that can instantly access her entire guest feedback database, identify patterns and trends, and automatically search for real-time information to provide context for guest complaints.

**The Solution - Maria's Agentic Hotel Concierge:**

We're going to build Maria an AI Concierge that doesn't just analyze one review at a time, but has **complete knowledge** of all her guest feedback through Retrieval Augmented Generation (RAG). This AI agent will be able to:

- **Instantly search** through thousands of reviews to find relevant information
- **Identify patterns** and trends across her entire guest database
- **Provide context-aware responses** based on historical data
- **Solve real-time problems** by combining internal knowledge with live internet information

**How This Solves Maria's Pattern Problem:**

Instead of manually searching through spreadsheets when a guest complains about Wi-Fi, Maria can now ask her AI Concierge: "How many guests have complained about Wi-Fi connectivity in the past month?" The AI will instantly search through all her reviews and provide a comprehensive analysis, helping her identify patterns and respond appropriately.

When a guest mentions a "marathon disruption," Maria's AI Concierge can automatically search the internet to find information about the specific event and then draft a personalized apology based on both the current situation and historical guest experiences with similar events.

**The Evolution of Maria's AI Journey:**

Building on our success with single review analysis in Lab 1, we're now creating a true "AI Concierge" that can access Maria's entire knowledge base. Using the OCI Agent Development Kit (ADK), we'll give this AI agent the ability to not only understand all her guest feedback but also search the internet to solve problems in real-time.

**From Reactive to Proactive:**

Maria's AI Concierge will transform her hotel's approach from reactive (responding to individual complaints) to proactive (identifying and addressing patterns before they become widespread problems). This is the next step in her journey toward truly intelligent hospitality management.

**Use Case:** We will create a **Generative AI Agent** that uses the entire Trip Advisor review dataset as its knowledge base (RAG). We will then use a local Python script and the OCI ADK to enhance this agent with a custom web\_search tool, allowing it to answer questions that require both internal knowledge and real-time external information.

**Dataset:** We’ll continue to use the multi language TripAdvisor Hotel Reviews dataset from [NIAID (Vietnamese)](https://data.niaid.nih.gov/resources?id=zenodo_7967493). To keep the workshop efficient, we’ve prepared trimmed versions of the dataset that can be downloaded from the lab repository on github. We will use the CSV version to manually copy some examples. The Markdown version will be used only to create the Knowledge Base. You can find the dataset in labs/datasets folder of this GitHub repository.

### **Part 1: Console Setup and RAG Test (20 mins)**

*In this part, we will prepare the necessary resources and test the RAG functionality in the OCI Console.*

#### **Step 1: Create the Knowledge Base**

1. **Upload Downloaded Dataset to Object Storage:**  
   - In the OCI Console, navigate to **Storage** \> **Object Storage & Archive Storage**.  
   - Create a new bucket named ai-workshop-labs-datasets.  
   - Upload the TripAdvisorReviewsMultiLang.md file into this bucket.

2. **Create a Knowledge Base in Gen AI Agents:**  
   - Navigate to **Analytics & AI** \> **AI Services** \> **Generative AI Agents**.  
   - On the left menu, click **Knowledge Bases**, then **Create knowledge base**.  
   - Name it Hotel\_Reviews\_KB.  
   - For the data source, select the ai-workshop-labs-datasets bucket.

#### **Step 2: Create and test the First Agent**

Note: If you ran the setup scripts, go straight to bullet 3.

1. **Create the Agent with RAG Tool:**  
   - On the left menu, click **Agents**, then **Create agent**.  
   - Name your agent Hotel\_Concierge\_Agent.  
   - Click **Next**.  
   - Click **Add tool** and select **Retrieval Augmented Generation**.  
   - Select the Hotel\_Reviews\_KB you created.  
   - Click **Next**.  
2. **Create an Endpoint:**  
   - On the next screen, select **Automatically create an endpoint for this agent**. This is essential for the ADK to connect later.  
   - Click **Next**, then **Create agent**.  
3. **Chat with and Test Your RAG Agent:**  
   - Once the agent is active, click **Launch chat**.  
   - Test its knowledge from the dataset to confirm the RAG tool is working:  
     - "Summarize the most common positive comments people make about their rooms."  
     - "Are there any negative reviews that mention the check-in process?"  

### **Part 2: The Problem-Solving Concierge (Live Tool with OCI ADK) \- (15 mins)**

*This part moves from the console to your local machine to run the Python script.*

#### **Step 3: Create another agent to use with OCI ADK (Agent Development Toolkit) Script**

Note: If you ran the setup scripts, go straight to bullet 3.

1. **Create the Agent with RAG Tool:**  
   - On the left menu, click **Agents**, then **Create agent**.  
   - Name your agent Hotel\_Concierge\_Agent\_ADK.  
   - Click **Next**.  
2. **Create an Endpoint:**  
   - On the next screen, select **Automatically create an endpoint for this agent**. This is essential for the ADK to connect later.  
   - Click **Next**, then **Create agent**.  

4. **Open GitHub Repository you cloned in your text editor:**  

5. **Update Placeholders in the .env file:**
   - Copy .env.example file to .env
   - Open .env file
   - Replace the placeholder \<replace with your knowledge base id\> with the KNOWLEDGEBASE_ID from the GENERATED_OCIDS.txt file
   - Replace the placeholder \<replace with your agent endpoint id\> with the HOTEL_CONCIERGE_AGENT_ADK_ENDPOINT_ID from the GENERATED_OCIDS.txt file
   - Replace the placeholder \<replace with your tavily api key\> with your Tavily AI API key from https://www.tavily.com/

6. **Run the Agent:**  
   - Execute the script from your terminal:  
     python concierge\_agent.py

   - The script will connect to your existing agent. The agent.setup() command will synchronize the tools, notice the new web\_search tool in your code, and add it to your agent's capabilities without removing the RAG tool you added in the console. It will then run the query and print the final response.

### **Conclusion & Value**

Congratulations! You've successfully transformed Maria's hotel guest feedback system from a manual, reactive process into an intelligent, proactive AI-powered solution.

**What You've Accomplished:**

- **Part 1 - RAG Foundation:** You've created a knowledge base that gives Maria's AI agent access to **all** her guest feedback. Instead of manually searching through thousands of reviews, her AI can now instantly find relevant information, identify patterns, and provide insights that would take her team hours to discover.

- **Part 2 - Real-World Problem Solving:** You've enhanced Maria's AI agent with the ability to search the internet in real-time. Now her concierge can not only understand guest complaints based on historical data but also find current information to solve problems immediately.

**The Business Impact for Maria:**

- **Faster Response Times:** From hours of manual research to instant answers
- **Proactive Problem Solving:** Identify and address issues before they affect multiple guests
- **Improved Guest Satisfaction:** Provide more accurate, helpful responses based on comprehensive data
- **Operational Efficiency:** Free up staff time for more valuable guest interactions

**Maria's Complete Transformation Journey:**

This two-part workshop series demonstrates Maria's evolution in AI adoption:

1. **Lab 1 - Start Simple:** Maria learned to analyze individual reviews in any language
2. **Lab 2, Part 1 - Scale with RAG:** Maria gained access to her entire guest feedback database
3. **Lab 2, Part 2 - Extend with Tools:** Maria's AI can now search the internet for real-time information

**Back in Ho Chi Minh City:**

Maria now has a powerful AI Concierge that can:

- **Instantly identify patterns** in guest complaints (like the Wi-Fi issue that affected 47 guests)
- **Search the internet** for current events affecting her guests (like the marathon disruption)
- **Draft personalized responses** based on both historical data and real-time information
- **Prevent guest escalation** by addressing issues before they become widespread

**The Journey Forward:**

Maria now has a foundation for building even more sophisticated AI agents that can handle complex guest requests, predict service needs, and continuously improve her hotel's guest experience through data-driven insights. Her Grand Plaza Hotel is well on its way to becoming a truly AI-powered hospitality leader in Vietnam.

**From Language Barriers to Pattern Recognition:**

Maria's journey from struggling with Vietnamese reviews to having an AI Concierge that can identify patterns across thousands of reviews and search the internet in real-time represents the complete transformation of hospitality management through AI. She's moved from reactive to proactive, from overwhelmed to empowered, and from manual to intelligent.
