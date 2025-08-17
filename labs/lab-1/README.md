## **OCI Generative AI Workshop: Enhancing Guest Experience in Hospitality**

**Industry:** Hospitality & Tourism

**The Real-World Problem:**

Maria is the General Manager of the Grand Plaza Hotel in Ho Chi Minh City, Vietnam. Every morning, she faces the same overwhelming challenge: her inbox is flooded with guest reviews in multiple languages - Vietnamese, English, Chinese, Korean, and more.

Yesterday, she received a detailed Vietnamese review from a business traveler that seemed important, but she couldn't understand it. Her Vietnamese-speaking staff member was on vacation, and Web Translation Tools gave her a confusing, broken translation that didn't capture the guest's true sentiment. By the time she got a proper translation two days later, the guest had already posted a follow-up complaint on social media about the hotel's slow response.

This isn't just Maria's problem - it's a daily reality for hotel managers worldwide. According to recent industry data:

- **67% of international hotels** receive reviews in languages their management doesn't speak
- **89% of guests** expect a response to their review within 24 hours
- **Hotels that respond quickly** to negative reviews see a 12% increase in booking rates
- **Lost revenue** from poor review management costs the average hotel $50,000+ annually

**The Solution - AI-Powered Review Analysis:**

What if Maria could instantly understand every review, regardless of language? What if she could get a clear summary of what the guest experienced, understand their emotional state, and have a perfect English translation for her records - all in under 30 seconds?

This workshop shows you exactly how to build that workflow using Oracle Cloud Infrastructure's Generative AI service. You'll learn how to transform an incomprehensible foreign-language review into actionable business intelligence that helps you make better decisions and provide better guest experiences.

**Why This Matters:**

Beyond just translation, this technology solves real business problems:

- **Prevent Guest Escalation:** Catch and address issues before they become social media crises
- **Improve Response Times:** From hours/days to seconds/minutes
- **Enhance Guest Satisfaction:** Show guests you care by responding quickly and appropriately
- **Increase Revenue:** Better reviews lead to more bookings and higher room rates
- **Operational Efficiency:** Free up staff time for more valuable guest interactions

**Your Mission:** You'll step into Maria's shoes and use AI to analyze a real Vietnamese hotel review, just like she would in her daily workflow. By the end of this workshop, you'll have the skills to handle international guest feedback with confidence and speed.

**Use Case:** We will use the **OCI Generative AI** service playground to analyze hotel reviews from international travelers. We will ask the model to summarize a non-English review, analyze its sentiment, and then translate it into English for a manager who doesn't speak the original language.

**Dataset**: We’ll use the multi language TripAdvisor Hotel Reviews dataset from [NIAID (Vietnamese)]((https://data.niaid.nih.gov/resources?id=zenodo_7967493)). To keep the workshop efficient, we’ve prepared trimmed versions of the dataset that can be downloaded from OCI Buckets.

Download the dataset from OCI Buckets: [Multi Language TripAdvisor Hotel Reviews](#)

### **Workshop Steps (20-30 minutes)**

This workshop is designed to be completed entirely within the OCI Generative AI Playground.

#### **Step 1: Get Your Sample Text (5 mins)**

1. **Download Sample English and Vietnamese Data:**
ADD LINKS TO BUCKET

2. **Copy a Non-English Review:** Open the Vietnamese file in a spreadsheet program.

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

Congratulations! You've just solved Maria's daily problem and demonstrated the power of AI in hospitality management.

**What You've Accomplished:**

In just 20-30 minutes, you've successfully:

- **Summarized** a review in its native language - understanding the guest's experience without losing cultural context
- **Analyzed** the guest's sentiment - quickly identifying if this requires immediate attention or can be handled routinely  
- **Translated** the entire review into English - creating a permanent record for management and future reference

**The Business Impact:**

This simple workflow transforms how hotels handle international feedback:

- **Time Savings:** From hours of manual translation to seconds of AI analysis
- **Accuracy:** Professional-grade translations that capture nuance and sentiment
- **Consistency:** Every review gets the same level of attention, regardless of language
- **Scalability:** Handle hundreds of reviews daily without additional staff

**Real-World Application:**

Back in Ho Chi Minh City, Maria can now:

1. **Immediately understand** every Vietnamese review that comes in
2. **Prioritize responses** based on sentiment analysis
3. **Maintain detailed records** in English for corporate reporting
4. **Respond within hours** instead of days, preventing guest escalation

**The Journey Continues:**

This is just the beginning of your AI-powered hospitality transformation. In our next workshop, we'll take this concept to the next level by building an **AI Concierge** that doesn't just analyze one review at a time, but has access to your entire guest feedback database.

Imagine an AI that can:

- **Search through thousands of reviews** to find patterns and trends
- **Identify recurring issues** across multiple properties
- **Provide recommendations** based on historical data
- **Solve real-time problems** by combining your data with live internet information

This is where we move from simple analysis to true intelligence - transforming your hotel's guest experience from reactive to proactive, from manual to automated, and from overwhelmed to empowered.

Ready to build your AI Concierge? Let's continue to Lab 2!
