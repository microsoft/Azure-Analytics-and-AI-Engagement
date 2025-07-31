window.config = {
  LogAPI: "https://app-common-powerbi-server.azurewebsites.net/ActivityLog/",
  SPEECH_KEY: "08829058ce334a5f950440324be656db",
  SPEECH_REGION: "eastus",
  BlobBaseUrl: "https://dreamdemoassets.blob.core.windows.net/daidemo/",
  IconBlobBaseUrl:
    "https://dreamdemoassets.blob.core.windows.net/daidemo/left-nav-icons/",

  APIUrl: "https://app-common-powerbi-server.azurewebsites.net",
  BackendAPIUrl: "https://app-openai-backend-uat.azurewebsites.net",
  // APIUrl: "https://localhost:5001",
  StartCallAPI:
    "https://func-gen-camp-call-center-prod.azurewebsites.net/api/start_call",
  // https://func-aoai2-demo-prod.azurewebsites.net/api/start_call",
  CUSTOMER_DETAILS_API:
    // "https://func-aoai2-demo-prod.azurewebsites.net/api/customerdetails",
    "https://func-gen-camp-call-center-prod.azurewebsites.net/api/customerdetails",
  EMAIL_GENERATION_API:
    // "https://func-aoai2-demo-prod.azurewebsites.net/api/predicting_customer_churn",
    "https://func-gen-camp-call-center-prod.azurewebsites.net/api/customized_machine_learning",
  INITIAL_ACTIONS: [
    "Do you have any demos for AI Design Wins?",
    "Do you have any demos for Fabric with Databricks?",
    "Are there any demos available for the latest Fabric features?",
    "Do you have any demo that shows integration of Microsoft Purview and Microsoft Fabric?",
  ],

  demoMenus: [
    {
      id: 55,
      demoId: 53,
      url: null,
      name: "Intro",
      order: 1,
      icon: "https://dreamdemoassets.blob.core.windows.net/daidemo/aoai_2_home_icon.png",
      arrowIcon: null,
      demoSubMenus: [
        {
          id: 138,
          url: "/landing-page",
          name: "Landing Page",
          icon: "https://dreamdemoassets.blob.core.windows.net/nrf/left-nav-icons/landing_icon.png",
          arrowIcon: null,
          order: 1,
          toolTip: "Landing Page",
          componentId: 3,
          componentName: "Image",
          componentParameters: [
            {
              id: 297,
              key: "url",
              value:
                "https://dreamdemoassets.blob.core.windows.net/dataandaidemo/landing_page_center.png",
            },
          ],
          externalArrows: [],
          personaId: 3,
          personaName: "April",
          personaDesignation: "Chief Executive Officer",
          personaImageUrl:
            "https://openaidemoassets.blob.core.windows.net/personas/April.png",
        },
      ],
      componentParameters: [],
      externalArrows: [],
      componentId: null,
      componentName: null,
      personaId: null,
      personaName: "April",
      personaDesignation: "Chief Executive Officer",
      personaImageUrl:
        "https://openaidemoassets.blob.core.windows.net/personas/April.png",
    },
    {
      id: 56,
      demoId: 53,
      url: null,
      name: "Innovate with AI Apps and Agents",
      toolTip: "Innovate with AI Apps and Agents",
      icon: "https://dreamdemoassets.blob.core.windows.net/dataandaidemo/left-nav-icons/withFabric_icon.png",
      arrowIcon: null,
      demoSubMenus: [
        {
          id: 3,
          url: "/elevated-customer-experience",
          name: "Elevated Customer Experience",
          icon: "https://dreamdemoassets.blob.core.windows.net/openai/shopping_assistant_icon.png",
          arrowIcon: null,
          order: 1,
          componentId: 3,
          componentName: "shopping copilot",
          componentParameters: [],
          externalArrows: [],
          personaId: 1,
          personaName: "Anna",
          personaImageUrl:
            "https://openaidemoassets.blob.core.windows.net/personas/Anna.png",
        },
      ],

      componentParameters: [],
      externalArrows: [],
      componentId: null,
      componentName: null,
      personaId: null,
      personaName: "April",
      personaDesignation: "Chief Executive Officer",
      personaImageUrl:
        "https://openaidemoassets.blob.core.windows.net/personas/April.png",
    },
  ],

  id: 410,
  userId: 85,
  customerId: 374,
  industryId: 1,
  preFillCredentials: true,
  customerName: "Contoso",
  customerEmail: "anna@city.gov.cs",
  name: "Contoso",
  password: "12345",
  title: "Contoso",
  logoImageURL:
    "https://dreamdemoassets.blob.core.windows.net/daidemo/New_Contoso/top_left_logo_CONTOSO.png",
  backgroundImageURL:
    "https://dreamdemoassets.blob.core.windows.net/daidemo/aoai_2_login_background.png",
  // "https://dreamdemoassets.blob.core.windows.net/daidemo/ai_first_event_chatbot_bg.png",
  chatImageLogoURL:
    "https://dreamdemoassets.blob.core.windows.net/daidemo/aoai_2_chat_logo.png",
  backgroundColor: null,
  primaryColor: "#00a1cbff",
  secondaryColor: "#004b76ff",
  headerImageUrl:
    "https://dreamdemoassets.blob.core.windows.net/daidemo/contoso_top_level_header_bg.png",
  headerBgColor: "rgba(97, 160, 4, 1)",
  navImageUrl:
    "https://dreamdemoassets.blob.core.windows.net/daidemo/contoso_left_nav_bg.png",
  navColor: "rgba(97, 160, 4, 1)",
  isFavorite: false,
  description: "Ask me something",
  subTitle: "Contoso",
  color: null,
  isEnabled: true,
  endPointURL: null,
  documents: [],
  campaigns: [
    {
      name: "Sustainable Elegance",
      imageUrl: "https://i.ibb.co/NYDFvrb/Earthwise-Elegance.png",
      order: 2,
      instagramText: `You are a marketing manager for a clothing company called Contoso. Write a promotional Instagram post about the launch of the company's new line of sustainable clothing. The post should include the following:
1. Start with a tagline for the post.
2. Post content with relevant emojis and hashtags.
3. A poem which describes the importance of sustainable clothing options.
4. Include a promotional offer of 50% discount and create a sense of urgency.
5. The post should contain at least 45 words.
Write an Instagram post with all of the above mentioned requirements. The post should be well segmented and closed with a poem.`,
      emailText: `You are a marketing manager for a clothing company called Contoso. Write a promotional marketing email to a customer for the launch of their new line of sustainable clothing. The email should include the following:
1. A Subject line for the email.
2. Start by greeting the customer.
3. Choose words that communicate the company's commitment to sustainability while keeping up with the latest fashion trends and elegance.
4. Include a promotional offer of 50% discount and create a sense of urgency.
5. Email should contain at least 35 words.`,
      EditPrompt:
        "A serene arrangement of flowing, natural fabrics in earthy tones, illuminated by soft, natural light. The fabrics are made from sustainable materials like organic cotton or recycled polyester. Minimalist aesthetic with a focus on texture and simplicity. ",
      bgPrompt:
        "Generate a realistic image of a convertible orange sports car on a road in a sunny day",
    },
    {
      name: "Refined Simplicity Collection",
      imageUrl: "https://i.ibb.co/SvSp7F7/minimalist.png",
      order: 3,
      instagramText: `Write an Instagram post for a company called Contoso. The post is for a promotion for a 50% discount on the launch of a new line of clothing. The new line focuses on minimalism. The post should include the following:
1. A headline for the Instagram post.
2. Choose words that communicate minimalism.
3. A poem about how the line of clothing demonstrates minimalism.
4. Include appropriate emojis in the post.
5. Include relevant Hashtags.
6. Post should contain at least 40 words.
Considering everything described above, give me an Instagram post with a post title, post content with appropriate hashtags and emojis. Close the post with a relevant poem as described above.`,
      emailText: `Write an email advertisement for a company called Contoso. The email is for a promotion for a 50% discount on the launch of a new line of clothing. The new line focuses on minimalism. The email should include the following:
1. A subject line for the email.
2. Choose words that communicate minimalism.
3. A poem about how the line of clothing demonstrates minimalism.
4. Include appropriate emojis in the email.
5. Include relevant Hashtags.
6. Email should contain at least 40 words.
Considering everything described above, give me an email with a title, content with appropriate hashtags and emojis. Close the email with a relevant poem as described above and proper greeting.`,
      EditPrompt:
        "A minimalist still life featuring a pair of metallic shoes on a round table covered with a mint green cloth. A vibrant blue fabric drapes over the table, and a bright yellow fabric hangs in the background. The overall composition is clean and modern.",
      bgPrompt: "Generate an abstract background inspired by light brown color",
    },
    {
      name: "Accessories That Make a Statement",
      // imageUrl: "https://i.ibb.co/sFVZ19T/men-accessories-v3.png",
      imageUrl:
        "https://dreamdemoassets.blob.core.windows.net/nrf/AccessoriesThatMakeStatement.jpg",
      order: 1,
      instagramText: `You are a marketing manager for a men's accessories company called Contoso. Write a promotional Instagram post about the launch of the company's new line of essential men's accessories. The post should include the following:
1. Start with a tagline for the post.
2. Post content with relevant emojis and hashtags.
3. A poem which describes the importance of sustainable men's accessories options.
4. Include a promotional offer of 50% discount and create a sense of urgency.
5. The post should contain at least 45 words.
Write an Instagram post with all of the above-mentioned requirements. The post should be well segmented and closed with a poem.`,
      emailText: `You are a marketing manager for a men's accessories company called Contoso. Write a promotional marketing email to a customer for the launch of their new line of essential men's accessories. The email should include the following:
1. A Subject line for the email.
2. Start by greeting the customer.
3. Choose words that communicate the company's commitment to sustainability while keeping up with the latest essential men's accessories.
4. Include a promotional offer of 50% discount and create a sense of urgency.
5. Email should contain at least 35 words.`,
      bgPrompt:
        "Generate a realistic image of a convertible orange sports car on a road in a sunny day",
      EditPrompt:
        "A top-down view of a black leather wallet, a pair of sunglasses with blue lenses, and a single black leather belt with a silver buckle. The belt is displayed in one continuous, intact piece, neatly coiled in a circular shape. The objects are arranged on sand near blue-green ocean waters, creating a clean and modern aesthetic.",
    },
  ],
  prompt1:
    "Taking into account all the research we have available on Litware, Fabrikam and Northiwind which company we should acquire and why?",
  prompt2:
    "What are the key customer demographics and spending behaviors of the three companies, and how do they align with our target market?",
  prompt3:
    "Evaluate the sustainability practices and ESG compliance of the three companies. Which company aligns most closely with our commitment to sustainable growth?",
  prompt4:
    "What are the major risks associated with acquiring each company, including legal, financial, and operational challenges?",
  questionPlaceHolder: "",
  iFrames: [],
  userName: "April@contoso.com",
  loginBoxImage:
    "https://dreamdemoassets.blob.core.windows.net/daidemo/New_Contoso/CONTOSO_login_visual.png",
  loginBackground:
    "https://dreamdemoassets.blob.core.windows.net/daidemo/aoai_2_login_background.png",
  // loginBackgroundColor: "#619E07",
  loginTextBoxImage:
    "https://dreamdemoassets.blob.core.windows.net/daidemo/contoso_login_text_box.png",
  disableTitle: true,
  navBarPrimaryColor: "#004b76ff",
  navBarSecondaryColor: "#004b76ff",
  navBarTextColor: "rgba(255, 255, 255, 1)",
  tabPrimaryColor: "#00a1cbff",
  tabSecondaryColor: "#004b76ff",
  dropdownPrimaryColor: "#00a1cbff",
  dropdownSecondaryColor: "#004b76ff",
  scrollBarPrimaryColor: "rgba(255, 255, 255, 0.5)",
  scrollBarSecondaryColor: "#004b76ff",
  pdfUploadApi: null,
  florenceAdApi: null,
  florenceDallEApi: null,
  dalleRegenerateAPI: null,
  dropdownTextColor: null,
  tabTextColor: "rgba(255, 255, 255, 1)",
  chatApproach: null,
  guid: "9fc02dce-55d7-4e23-8007-58566b55e3a1",
  chatCompany: null,
  DELAY_TIME: 2000,
  callCenterReportID: "2621cd34-cf08-4852-b892-a0bffc5e153b",
  callCenterReportSectionName: "ReportSection623b64746831c0065bc0",
  callCenterVideoURL: "",
  callCenterScript: `Meena: Thank you for reaching out to the City Call Center. I'm Meena, and I'm here to assist you. \nBrent: Hi Meena, I'm a concerned resident in the city. I've been hearing about the city's sustainability efforts, particularly related to air quality and green initiatives. Can you tell me more about these? \nMeena: Absolutely, Brent. We take sustainability seriously, and we have some exciting initiatives in place. First, let's talk about air quality. We've introduced a fleet of green buses that run on clean energy sources. These buses are reducing harmful emissions and contributing to cleaner air in the city. \nBrent: That's impressive. What about the sustainable buildings and the green rooftops I've heard about? \nMeena: We're equally committed to sustainable urban planning. Our new buildings incorporate proper ventilation and eco-friendly materials, ensuring better indoor air quality. The green rooftops you mentioned are indeed a part of our efforts. They help retain rainwater, reducing pressure on our drainage systems, and also play a role in temperature regulation, making our city more energy-efficient. \nBrent: It's great to see these efforts. Are there more sustainability initiatives you can tell me about? \nMeena: Of course, Brent. We have an array of programs. Recycling is a big part of our sustainability push. We also encourage urban gardening and work on waste reduction and energy efficiency initiatives. If you'd like more information or want to participate, I can provide you with details. \nBrent: That's fantastic, Meena. I'd love to learn more about the recycling programs and urban gardens. How can I get involved? \nMeena: I can certainly provide you with all the details you need. You can join our urban gardening community and participate in various recycling drives. We appreciate residents like you who actively contribute to our sustainability goals. \nBrent: Thank you, Meena. I'm excited to get involved and support these initiatives. \nMeena: We're delighted to have you on board, Brent. If you have more questions or need further information, please feel free to ask. We're here to assist you. \nBrent: Thank you, Meena. I appreciate your help. Have a great day! \nMeena: You too, Brent! Have a wonderful day, and thank you for your dedication to a greener, healthier city.`,
  callCenterCustomerImage: "customer_gm.png",
  callCenterBackendImage: "backend_gm.png",
  callCenterAgentImage: "agent_gm.png",
  callCenterExtractFromConversationWithKey:
    "Extract the following information from the conversation below:\nCall reason (key: reason)\nCaller name (key: caller_name)\nAgent Name (key: agent_name)\nCaller sentiment (key: caller_sentiment)\nSKU number (key: sku_number)\nOrder id(key: order_id)\nProduct name(key: product_name)\nStore id(key: store_id)\nStore name(key: store_name)\nA short, yet detailed summary (key: summary)\nPlease answer in JSON machine-readable format, using the keys from above.If any value is not available, it should be None.Format the output as a JSON object called “results”. Pretty print the JSON and make sure that it is properly closed at the end.",
  callCenterExtractFromConversationWithoutKey:
    // "Generate a summary of the conversation in the following format with proper numbering: \n\n1. Main reason for the conversation.\n2. Sentiment of the customer.\n3. Create a short summary of the conversation.",
    `Generate a summary of the conversation in the following format with proper numbering: \n1. Main reason for the conversation.\n2. Sentiment of the customer.\n3. How did the agent handle the conversation?\n4. What was the final outcome of the conversation?\n5. Create a short summary of the conversation.\n6. Did the agent request the order number?\n7. What SKU Number did the call correspond to?\n8. What Store ID did the call correspond to?`,
  showSettings: true,
  chatContainerBackgroundColor: "rgba(0, 75, 118, 1)",
  isSampleDemo: null,
  landingPageImage:
    "https://dreamdemoassets.blob.core.windows.net/daidemo/New_Contoso/landing_page_visual.png",
  order: 0,
  active: true,
  pdfUploadApi:
    "https://func-search-openai-dev-001-staging.azurewebsites.net/api/pdfindexer",
  florenceAdApi:
    "https://backupclientfunction.azurewebsites.net/api/campaigngenerationv3",
  florenceDallEApi:
    "https://func-recommend-images.azurewebsites.net/api/recommendimages",
  dalleRegenerateAPI:
    "https://func-florence-openai-dev001.azurewebsites.net/api/regenerate-dalle",
  summarizeConversationAPI:
    "https://chatgpttest45.openai.azure.com/daidemo/deployments/text-davinci-003/completions?api-version=2022-12-01",
  summarizeConversationAPIKey: "9dcb9b4900584019ab8f2c23eb8643d7",
  //CALL_CENTER_API: "https://func-call-center.azurewebsites.net/api/",
  // CALL_CENTER_API: "https://func-aoai2-demo-prod.azurewebsites.net/api/",
  CALL_CENTER_API:
    "https://func-gen-camp-call-center-prod.azurewebsites.net/api/",

  // endPointURL: "https://func-fabric-aistudio-dev-001.azurewebsites.net/api",
  // endPointURL: "https://enterprise-chatbot-001.azurewebsites.net/api",
  index: "ai-first-mover-index",
  container: "ai-first-mover-container",
  CEODashboardBeforeID: "ec25d000-89b4-42cf-9872-a18aa3068c52",
  CEODashboardBeforeReportID: "34c71953-7092-46be-a1d1-704273b6cbd7",
  CEODashboardBeforeReportSectionName: "e4c992de-6186-4887-a935-a45bcbb47e3a",
  tryYourOwnDataEndpoint:
    "https://enterprise-chatbot-001.azurewebsites.net/api",
  endPointURL: "https://enterprise-chatbot-001.azurewebsites.net/api",
  florenceAdApi:
    // "https://campaign-generation-prod.azurewebsites.net/api/generatecampaign?",
    "https://func-campaign-generation-rsva.azurewebsites.net/api/generatecampaign?",
  florenceDallEApi:
    "https://func-openai-florence-dev001.azurewebsites.net/api/recommendfromimage_v2",
  dalleRegenerateAPI:
    "https://func-florence-openai-dev001.azurewebsites.net/api/regenerate-dalle",
  Dalle3API:
    // "https://func-fsi2-prod.azurewebsites.net/api/create_3_images_with_dalle3?",
    "https://func-personalized-campaign-generation.azurewebsites.net/api/create_3_images_with_dalle3?",
  GPT4VAPI:
    // "https://func-fsi2-prod.azurewebsites.net/api/imageUnderstanding_gpt4v?",
    "https://func-personalized-campaign-generation.azurewebsites.net/api/imageUnderstanding_gpt4v?",
};
