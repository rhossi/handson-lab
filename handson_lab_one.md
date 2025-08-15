## **OCI Generative AI Workshop: Enhancing Guest Experience in Hospitality**

**Industry:** Hospitality & Tourism

**Story:** Imagine you are the manager of a global hotel chain with properties all over the world. You receive thousands of online reviews every week from guests in many different languages. To maintain a high standard of service, you need to quickly understand this feedback, identify common themes (both good and bad), and respond to guests promptly. Manually translating and summarizing each review is impossible at scale. How can you use AI to instantly analyze feedback from an international guest, understand their sentiment, and translate it for your records? This workshop shows you exactly how to build that workflow.

**Use Case:** We will use the **OCI Generative AI** service playground to analyze hotel reviews from international travelers. We will ask the model to summarize a non-English review, analyze its sentiment, and then translate it into English for a manager who doesn't speak the original language.

**Dataset:** We'll use the "Trip Advisor Hotel Reviews" dataset from Kaggle. This dataset is perfect as it contains reviews in multiple languages.

[https://www.kaggle.com/datasets/andrewmvd/trip-advisor-hotel-reviews](https://www.kaggle.com/datasets/andrewmvd/trip-advisor-hotel-reviews)

### **Workshop Steps (20-30 minutes)**

This workshop is designed to be completed entirely within the OCI Generative AI Playground.

#### **Step 1: Get Your Sample Text (5 mins)**

1. **Download Sample Data:** Go to the Kaggle dataset link and download the tripadvisor\_hotel\_reviews.csv file.  
2. **Copy a Non-English Review:** Open the CSV file in a spreadsheet program. The dataset contains reviews in Spanish, French, Italian, German, and more. Find a review that is clearly not in English and copy the entire text from the "Review" column into your clipboard.

#### **Step 2: Navigate to the OCI Generative AI Playground (5 mins)**

1. **Find the Service:** In the OCI Console, go to **Analytics & AI** \> **AI Services** \> **Generative AI**.  
2. **Launch the Playground:** Inside the Generative AI service page, click on **Playground** to open the interactive interface.

#### **Step 3: Summarize and Analyze the Review in its Original Language (10 mins)**

1. **Select the Right Model:** In the Playground, choose one of the "Grok" models. These models have strong multilingual capabilities.  
2. **Craft Your Prompt:** Your prompt will ask the model to perform two tasks at once: summarization and sentiment analysis.  
3. **Paste and Instruct:** In the input box, type the following prompt, and then paste the non-English review you copied in Step 1 right after it:
   ```
   Analyze the following hotel review. First, provide a one-paragraph summary of the review in its original language. After the summary, identify the sentiment as Positive, Negative, or Neutral.

   Here is the review:  
   [PASTE THE NON-ENGLISH REVIEW TEXT HERE]
   ```
5. **Generate and Review:** Click the **Generate** button. The AI model will read the review and, in the output box, generate a summary in the *original language* (e.g., Spanish) and then provide the overall sentiment. This shows the model's ability to comprehend and work within different languages.

#### **Step 4: Translate the Review for Management (5 mins)**

1. **Start a New Chat:** Clear the input and output from the previous step.  
2. **Craft a Translation Prompt:** In the input box, type a simple, direct prompt for translation:
   ```
   Translate the following hotel review into English:

   [PASTE THE SAME NON-ENGLISH REVIEW TEXT HERE]
   ```
4. **Generate and Review:** Click **Generate**. The model will now provide a full and accurate English translation of the guest's review, making it immediately understandable for an English-speaking manager.

### **Conclusion & Value**

In this short workshop, you've successfully proven the value of using OCI Generative AI to handle international customer feedback. 

With just two prompts, you were able to:

* **Summarize** a review in its native language.  
* **Analyze** the guest's sentiment.  
* **Translate** the entire review into English.

This is a great first step, but it's just the beginning. Imagine the true power if your AI could have a conversation with you, not just about one review, but with knowledge of all the reviews in your entire dataset. What if it could not only analyze feedback but also help you solve the problems guests raise by finding new information?

This is where we move from simple analysis to true intelligence. In our next lab, we will take this concept to the next level by building an AI Concierge using the OCI Generative AI Agents service. We will give our AI a memory of all guest feedback and even teach it new skills, transforming it from a simple tool into a powerful assistant.
