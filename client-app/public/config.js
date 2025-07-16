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
        // {
        //   id: 139,
        //   url: "/snackable-selection",
        //   name: "Snackable Selection",
        //   icon: "https://dreamdemoassets.blob.core.windows.net/nrf/left-nav-icons/landing_icon.png",
        //   arrowIcon: null,
        //   order: 2,
        //   toolTip: "Snackable Selection",
        //   componentId: 3,
        //   componentName: "landing page",
        //   componentParameters: [
        //     {
        //       id: 297,
        //       key: "url",
        //       value:
        //         "https://dreamdemoassets.blob.core.windows.net/dataandaidemo/landing_page_center.png",
        //     },
        //   ],
        //   externalArrows: [],
        //   personaId: 3,
        //   personaName: "April",
        //   personaDesignation: "Chief Executive Officer",
        //   personaImageUrl:
        //     "https://openaidemoassets.blob.core.windows.net/personas/April.png",
        // },
        // {
        //   id: 140,
        //   url: "/world-map",
        //   name: "World Map",
        //   icon: "https://dreamdemoassets.blob.core.windows.net/nrf/left-nav-icons/map_icon.png",
        //   arrowIcon: null,
        //   toolTip: "World Map",
        //   order: 2,
        //   componentId: 1,
        //   componentName: "Power BI Report",
        //   componentParameters: [
        //     {
        //       id: 298,
        //       key: "url",
        //       value:
        //         // "https://app.powerbi.com/groups/102eb9b7-4dc0-449f-b9cb-e1b9432d00cd/reports/fe978f66-f448-437d-9d40-c42b8a2c6f30/ReportSectionae2d438d3737f6ada513?experience=power-bi&clientSideAuth=0",
        //         "https://app.powerbi.com/groups/644a4412-d11e-4c52-b984-e6f88ba57eca/reports/c903a727-9ffd-4af2-addf-dff38f0c2975/ReportSectionae2d438d3737f6ada513?experience=power-bi",
        //     },
        //     {
        //       id: 1,
        //       key: "background",
        //       value: "black",
        //     },
        //   ],
        //   externalArrows: [],
        //   personaId: 3,
        //   personaName: "April",
        //   personaDesignation: "Chief Executive Officer",
        //   personaImageUrl:
        //     "https://openaidemoassets.blob.core.windows.net/personas/April.png",
        // },

        // {
        //   id: 141,
        //   url: "/miami-beach",
        //   name: "Miami Beach",
        //   toolTip: "Miami Beach",
        //   icon: "https://dreamdemoassets.blob.core.windows.net/nrf/left-nav-icons/beach_icon.png",
        //   arrowIcon: null,
        //   order: 3,
        //   componentId: 5,
        //   componentName: "Beach View",
        //   componentParameters: [],
        //   externalArrows: [],
        //   personaId: 3,
        //   personaName: "April",
        //   personaDesignation: "Chief Executive Officer",
        //   personaImageUrl:
        //     "https://openaidemoassets.blob.core.windows.net/personas/April.png",
        // },
        // {
        //   id: 142,
        //   url: "/executive-dashboard-before",
        //   name: "Executive Dashboard - Before",
        //   toolTip: "Executive Dashboard - Before",
        //   icon: "https://dreamdemoassets.blob.core.windows.net/nrf/left-nav-icons/dashboard_icon.png",
        //   arrowIcon: null,
        //   order: 4,
        //   componentId: 2,
        //   componentName: "power bi report",
        //   componentParameters: [
        //     // {
        //     //   id: 300,
        //     //   key: "reportUrl",
        //     //   value:
        //     //     "https://app.powerbi.com/groups/102eb9b7-4dc0-449f-b9cb-e1b9432d00cd/reports/0a875433-9d0a-4806-83de-3cd51f91666b/ReportSection5f752c6bde03670c8284?experience=power-bi&clientSideAuth=0",
        //     // },
        //     {
        //       id: 301,
        //       key: "url",
        //       value:
        //         "https://app.powerbi.com/groups/644a4412-d11e-4c52-b984-e6f88ba57eca/reports/96b223c6-0cd2-464b-9c79-954f27ff2d37/6b87181dfdb54f206075?experience=power-bi",
        //     },
        //   ],
        //   externalArrows: [],
        //   personaId: 3,
        //   personaName: "April",
        //   personaDesignation: "Chief Executive Officer",
        //   personaImageUrl:
        //     "https://openaidemoassets.blob.core.windows.net/personas/April.png",
        // },
        // {
        //   id: 143,
        //   url: "/org-chart",
        //   name: "Org Chart",
        //   toolTip: "Org Chart",
        //   icon: "https://dreamdemoassets.blob.core.windows.net/dataandaidemo/OrgChartUpdated.png",
        //   arrowIcon: null,
        //   order: 5,
        //   componentId: 3,
        //   componentName: "Image",
        //   componentParameters: [
        //     {
        //       id: 302,
        //       key: "url",
        //       // value: "https://nrfcdn.azureedge.net/fab_db_2_org_chart.gif",
        //       value:
        //         "https://dreamdemoassets.blob.core.windows.net/herodemos/heroDemosOrgChartV1.png",
        //     },
        //   ],
        //   externalArrows: [],
        //   personaId: 3,
        //   personaName: "April",
        //   personaDesignation: "Chief Executive Officer",
        //   personaImageUrl:
        //     "https://openaidemoassets.blob.core.windows.net/personas/April.png",
        // },
        // {
        //   id: 144,
        //   url: "/retail-strategy-virtual-advisor",
        //   name: "Retail Strategy Virtual Advisor",
        //   icon: "https://fsi.azureedge.net/left-nav-icons/icon5_2.png",
        //   arrowIcon: "",
        //   order: 1,
        //   componentId: 3,
        //   componentName: "chat bot",
        //   componentParameters: [
        //     {
        //       key: "url",
        //       value: "",
        //     },
        //   ],
        //   externalArrows: [],
        //   personaId: 3,
        //   personaName: "Geraldine",
        //   personaDesignation: "Chief Customer Officer",
        //   personaImageUrl:
        //     "https://openaidemoassets.blob.core.windows.net/personas/Hannah.png",
        // },
        // {
        //   id: 56,
        //   url: "/retail-strategy-virtual-advisor",
        //   name: "Retail Strategy Virtual Advisor",
        //   toolTip: "Retail Strategy Virtual Advisor",
        //   icon: "https://dreamdemoassets.blob.core.windows.net/dataandaidemo/OrgChartUpdated.png",
        //   arrowIcon: null,
        //   order: 5,
        //   componentId: 3,
        //   componentName: "chat bot",
        //   componentParameters: [
        //     {
        //       key: "url",
        //       value: "",
        //     },
        //   ],
        //   externalArrows: [],
        //   personaId: 3,
        //   personaName: "Geraldine",
        //   personaDesignation: "Chief Customer Officer",
        //   personaImageUrl:
        //     "https://openaidemoassets.blob.core.windows.net/personas/Hannah.png",
        // },
        // {
        //   id: 56,
        //   demoId: 53,
        //   url: null,
        //   name: "Retail Strategy",
        //   toolTip: "Retail Strategy",
        //   icon: "https://dreamdemoassets.blob.core.windows.net/daidemo/retail_before_event_icon.png",
        //   arrowIcon: null,
        //   demoSubMenus: [
        //     {
        //       id: 144,
        //       url: "/retail-strategy-virtual-advisor",
        //       name: "Retail Strategy Virtual Advisor",
        //       icon: "https://fsi.azureedge.net/left-nav-icons/icon5_2.png",
        //       arrowIcon: "",
        //       order: 1,
        //       componentId: 3,
        //       componentName: "chat bot",
        //       componentParameters: [
        //         {
        //           key: "url",
        //           value: "",
        //         },
        //       ],
        //       externalArrows: [],
        //       personaId: 3,
        //       personaName: "Geraldine",
        //       personaDesignation: "Chief Customer Officer",
        //       personaImageUrl:
        //         "https://openaidemoassets.blob.core.windows.net/personas/Hannah.png",
        //     },
        //   ],
        //   componentParameters: [],
        //   externalArrows: [],
        //   componentId: null,
        //   componentName: null,
        //   personaId: null,
        //   personaName: "April",
        //   personaDesignation: "Chief Executive Officer",
        //   personaImageUrl:
        //     "https://openaidemoassets.blob.core.windows.net/personas/April.png",
        // },
        // {
        //   id: 144,
        //   url: "/current-state-architecture",
        //   name: "Current State Architecture",
        //   toolTip: "Current State Architecture",
        //   icon: "https://dreamdemoassets.blob.core.windows.net/nrf/left-nav-icons/arch_icon.png",
        //   arrowIcon: "",
        //   order: 1,
        //   componentId: 3,
        //   componentName: "Image",
        //   componentParameters: [
        //     {
        //       id: 303,
        //       key: "url",
        //       // value:
        //       //   "https://dreamdemoassets.blob.core.windows.net/nrf/fab_db_2_current_arch_diagram.png",
        //       value:
        //         "https://dreamdemoassets.blob.core.windows.net/nrf/fab_db_2_current_arch_diagram_v2.png",
        //     },
        //   ],
        //   externalArrows: [],
        //   personaId: 3,
        //   personaName: "Rupesh",
        //   personaDesignation: "Chief Data Officer",
        //   personaImageUrl:
        //     "https://openaidemoassets.blob.core.windows.net/personas/Rupesh.png",
        // },

        // {
        //   id: 144,
        //   url: "/introduction-to-microsoft-fabric",
        //   name: "Introduction to Microsoft Fabric",
        //   toolTip: "Introduction to Microsoft Fabric",
        //   icon: "https://dreamdemoassets.blob.core.windows.net/nrf/left-nav-icons/arch_icon.png",
        //   arrowIcon: "",
        //   order: 1,
        //   componentId: 3,
        //   componentName: "Image",
        //   componentParameters: [
        //     {
        //       id: 303,
        //       key: "url",
        //       // value:F
        //       //   "https://dreamdemoassets.blob.core.windows.net/nrf/fab_db_2_current_arch_diagram.png",
        //       value:
        //         "https://dreamdemoassets.blob.core.windows.net/nrf/introduction-to-microsoft-fabric.jpg",
        //     },
        //   ],
        //   externalArrows: [],
        //   personaId: 3,
        //   personaName: "Rupesh",
        //   personaDesignation: "Chief Data Officer",
        //   personaImageUrl:
        //     "https://openaidemoassets.blob.core.windows.net/personas/Rupesh.png",
        // },
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

    // {
    //   id: 144,
    //   url: "/dream-demo-architecture",
    //   name: "DREAM Demo Architecture​",
    //   icon: "https://dreamdemoassets.blob.core.windows.net/daidemo/retail_arch_icon.png",
    //   arrowIcon: "",
    //   order: 1,
    //   componentId: 3,
    //   componentName: "Image",
    //   componentParameters: [
    //     {
    //       id: 303,
    //       key: "url",
    //       value:
    //         "https://dreamdemoassets.blob.core.windows.net/herodemos/AzureHeroDemoArchV1.png",
    //     },
    //   ],
    //   externalArrows: [],
    //   personaId: 3,
    //   personaName: "Rupesh",
    //   personaDesignation: "Chief Data Officer",
    //   personaImageUrl:
    //     "https://openaidemoassets.blob.core.windows.net/personas/Rupesh.png",
    // },
    // {
    //   url: "/dream-demo-architecture",
    //   name: "DREAM Demo Architecture",
    //   toolTip: "DREAM Demo Architecture",
    //   icon: "https://dreamdemoassets.blob.core.windows.net/dataandaidemo/left-nav-icons/dreamdemoarch_icon.png",
    //   arrowIcon: null,
    //   order: 2,
    //   componentId: 3,
    //   componentName: "ArchImage",
    //   // componentParameters: [
    //   //   {
    //   //     key: "url",
    //   //     // value: "https://nrfcdn.azureedge.net/data_ai_big_demo_archV1.gif",
    //   //     value:
    //   //       "https://dreamdemoassets.blob.core.windows.net/herodemos/AzureDREAMDemoArchitectureV3.png",
    //   //       // "https://dreamdemoassets.blob.core.windows.net/herodemos/AHD_Arch.png",
    //   //   },
    //   //   { key: "originalSize", value: "true" },
    //   // ],
    //   componentParameters: [
    //     {
    //       key: "simplifiedUrl",
    //       // value: "https://dreamdemoassets.blob.core.windows.net/herodemos/AzureDREAMDemoArchitectureV3.png"
    //       value:
    //         "https://dreamdemoassets.blob.core.windows.net/herodemos/AHD_Arch.png",
    //     },
    //     {
    //       key: "detailedUrl",
    //       // value: "https://dreamdemoassets.blob.core.windows.net/herodemos/AHD_Arch.png"
    //       value:
    //         "https://dreamdemoassets.blob.core.windows.net/herodemos/AzureDREAMDemoArchitectureV3.png",
    //     },
    //     { key: "originalSize", value: "true" },
    //   ],
    //   externalArrows: [],
    //   personaId: null,
    //   personaName: "Rupesh",
    //   personaDesignation: "Chief Data Officer",
    //   personaImageUrl:
    //     "https://openaidemoassets.blob.core.windows.net/personas/Rupesh.png",
    // },

    // {
    //   id: 56,
    //   demoId: 53,
    //   url: null,
    //   name: "With Microsoft Fabric",
    //   toolTip: "With Microsoft Fabric",
    //   icon: "https://dreamdemoassets.blob.core.windows.net/dataandaidemo/left-nav-icons/withFabric_icon.png",
    //   arrowIcon: null,
    //   demoSubMenus: [
    //     {
    //       url: "/data-engineering",
    //       name: "Data Engineering",
    //       toolTip: "Data Engineering",
    //       videoDisabled: false,
    //       clickbyclickDisabled: false,
    //       liveHostedDisabled: false,
    //       productDemoVideoDisabled: true,
    //       title: "Data Engineering",
    //       icon: "https://dreamdemoassets.blob.core.windows.net/nrf/left-nav-icons/click_by_click_icon.png",
    //       arrowIcon: null,
    //       order: 3,
    //       componentId: 6,
    //       showArchDiagram: true,
    //       componentName: "videoWIthClickByClick",
    //       liveHostedList: [
    //         {
    //           id: 1,
    //           text: "Demo Download",
    //           url: "https://microsoft.sharepoint.com/:u:/t/Demochamp868/ESeqg26qN3hLvLERVwb4_cQBo_Df8wrsVXv1ORT1wDcykw?e=fTYzLc",
    //         },
    //         {
    //           id: 2,
    //           text: "Live Demo Portal",
    //           url: "https://admin.cloudlabs.ai/#/main",
    //         },
    //       ],
    //       video: [
    //         {
    //           id: 1,
    //           name: "product1",
    //           thumbnailImage: "",
    //           navigateUrl: "",
    //         },
    //       ],
    //       dropDownMenu: [
    //         {
    //           id: 1,
    //           text: "Data Engineering",
    //           videoPlayurl:
    //             "https://ep-default-mediakind-common-demo.eastus.streaming.mediakind.com/Data_Ingestion1/Data_Ingestion.ism/manifest(format=m3u8-cmaf)",
    //         },
    //         {
    //           id: 2,
    //           text: "Data Pipelines",
    //           videoPlayurl:
    //             "https://ep-default-mediakind-common-demo.eastus.streaming.mediakind.com/e9cf446a-43c8-4823-8cee-2831ba341521/DataEngineeringV01.ism/manifest(format=m3u8-cmaf)",
    //         },
    //         {
    //           id: 3,
    //           text: "Processing Large Dataset with Spark",
    //           videoPlayurl:
    //             "https://ep-default-mediakind-common-demo.eastus.streaming.mediakind.com/9ab03a6a-9406-4a32-ad2d-b414ea3309ec/DataIngestionforAzureHeroDemosV1.ism/manifest(format=m3u8-cmaf)",
    //         },
    //       ],
    //       componentParameters: [
    //         {
    //           key: "video",
    //           value:
    //             "https://ep-default-mediakind-common-demo.eastus.streaming.mediakind.com/Data_Ingestion1/Data_Ingestion.ism/manifest(format=m3u8-cmaf)",
    //         },
    //         {
    //           key: "videoName1",
    //           value: "Data Engineering",
    //         },
    //         {
    //           key: "videoName2",
    //           value: "Data Pipelines",
    //         },
    //         {
    //           key: "videoUrl1",
    //           value:
    //             "https://ep-default-mediakind-common-demo.eastus.streaming.mediakind.com/Data_Ingestion1/Data_Ingestion.ism/manifest(format=m3u8-cmaf)",
    //         },
    //         {
    //           key: "videoUrl2",
    //           value:
    //             "https://ep-default-mediakind-common-demo.eastus.streaming.mediakind.com/e9cf446a-43c8-4823-8cee-2831ba341521/DataEngineeringV01.ism/manifest(format=m3u8-cmaf)",
    //         },
    //         {
    //           key: "clickByClick",
    //           value:
    //             "https://regale.cloud/microsoft/play/3655/microsoft-fabric-individual-sections-for-web-app-embedding-20#/0/0",
    //         },
    //         {
    //           key: "videoType",
    //           value: "clickVideo",
    //         },
    //         {
    //           key: "liveHosted",
    //           value:
    //             "https://microsoft.sharepoint.com/:u:/t/Demochamp868/ESeqg26qN3hLvLERVwb4_cQBo_Df8wrsVXv1ORT1wDcykw?e=fTYzLc",
    //         },
    //         {
    //           key: "productDemoVideo",
    //           value:
    //             "https://microsoft.seismic.com/Link/Content/DCfXJm2DFTMmC842b687QfjQmgfV",
    //         },
    //       ],
    //       video: [
    //         {
    //           id: 1,
    //           name: "product1",
    //           thumbnailImage: "",
    //           navigateUrl: "",
    //         },
    //       ],
    //       externalArrows: [],
    //       personaId: null,
    //       personaName: "Eva",
    //       personaDesignation: "Data Engineer",
    //       personaImageUrl:
    //         "https://openaidemoassets.blob.core.windows.net/personas/Eva.png",
    //     },

    //     {
    //       url: "/Business-Challenge-and-Vision",
    //       name: "Business Challenge and Vision",
    //       toolTip: "Business Challenge and Vision",
    //       videoDisabled: false,
    //       clickbyclickDisabled: false,
    //       liveHostedDisabled: false,
    //       productDemoVideoDisabled: true,
    //       title: "Business Challenge and Vision",
    //       icon: "https://dreamdemoassets.blob.core.windows.net/nrf/left-nav-icons/click_by_click_icon.png",
    //       arrowIcon: null,
    //       order: 3,
    //       componentId: 6,
    //       showArchDiagram: true,
    //       liveHostedList: [
    //         {
    //           id: 1,
    //           text: "Demo Download",
    //           url: "https://microsoft.sharepoint.com/:u:/t/Demochamp868/ESeqg26qN3hLvLERVwb4_cQBo_Df8wrsVXv1ORT1wDcykw?e=fTYzLc",
    //         },
    //         {
    //           id: 2,
    //           text: "Live Demo Portal",
    //           url: "https://admin.cloudlabs.ai/#/main",
    //         },
    //       ],
    //       componentName: "videoWIthClickByClick",
    //       video: [
    //         {
    //           id: 1,
    //           name: "product1",
    //           thumbnailImage: "",
    //           navigateUrl: "",
    //         },
    //       ],
    //       dropDownMenu: [
    //         {
    //           id: 1,
    //           text: "Business Challenge and Vision",
    //           videoPlayurl:
    //             "https://ep-default-mediakind-common-demo.eastus.streaming.mediakind.com/e9cf446a-43c8-4823-8cee-2831ba341521/DataEngineeringV01.ism/manifest(format=m3u8-cmaf)",
    //         },

    //         // {
    //         //   id: 3,
    //         //   text: "Lakehouse Creation",
    //         //   videoPlayurl:
    //         //     "https://ep-default-mediakind-common-demo.eastus.streaming.mediakind.com/b872c8b5-d7d2-4acc-95b6-f14c01f28aca/Lakehouse_Creation_01.ism/manifest(format=m3u8-cmaf)",
    //         // },
    //       ],
    //       componentParameters: [
    //         {
    //           key: "video",
    //           value:
    //             "https://ep-default-mediakind-common-demo.eastus.streaming.mediakind.com/e9cf446a-43c8-4823-8cee-2831ba341521/DataEngineeringV01.ism/manifest(format=m3u8-cmaf)",
    //         },
    //         {
    //           key: "videoName1",
    //           value: "Data Engineering",
    //         },
    //         {
    //           key: "videoName2",
    //           value: "Data Pipelines",
    //         },
    //         {
    //           key: "videoUrl1",
    //           value: "",
    //         },
    //         {
    //           key: "videoUrl2",
    //           value:
    //             "https://ep-default-mediakind-common-demo.eastus.streaming.mediakind.com/e9cf446a-43c8-4823-8cee-2831ba341521/DataEngineeringV01.ism/manifest(format=m3u8-cmaf)",
    //         },
    //         {
    //           key: "clickByClick",
    //           value:
    //             "https://regale.cloud/microsoft/play/3655/microsoft-fabric-individual-sections-for-web-app-embedding-20#/0/0",
    //         },
    //         {
    //           key: "videoType",
    //           value: "clickVideo",
    //         },
    //         {
    //           key: "liveHosted",
    //           value:
    //             "https://microsoft.sharepoint.com/:u:/t/Demochamp868/ESeqg26qN3hLvLERVwb4_cQBo_Df8wrsVXv1ORT1wDcykw?e=fTYzLc",
    //         },
    //         {
    //           key: "productDemoVideo",
    //           value:
    //             "https://microsoft.seismic.com/Link/Content/DCfXJm2DFTMmC842b687QfjQmgfV",
    //         },
    //       ],
    //       video: [
    //         {
    //           id: 1,
    //           name: "product1",
    //           thumbnailImage: "",
    //           navigateUrl: "",
    //         },
    //       ],
    //       externalArrows: [],
    //       personaId: null,
    //       personaName: "Eva",
    //       personaDesignation: "Data Engineer",
    //       personaImageUrl:
    //         "https://openaidemoassets.blob.core.windows.net/personas/Eva.png",
    //     },

    //     {
    //       url: "/drive-down-operating-costs",
    //       name: "Drive down operating costs with Unified Data and Real-Time Decisions",
    //       toolTip:
    //         "Drive down operating costs with Unified Data and Real-Time Decisions",
    //       videoDisabled: false,
    //       clickbyclickDisabled: false,
    //       liveHostedDisabled: false,
    //       productDemoVideoDisabled: true,
    //       title:
    //         "Drive down operating costs with Unified Data and Real-Time Decisions",
    //       icon: "https://dreamdemoassets.blob.core.windows.net/nrf/left-nav-icons/click_by_click_icon.png",
    //       arrowIcon: null,
    //       order: 3,
    //       componentId: 6,
    //       showArchDiagram: true,
    //       liveHostedList: [
    //         {
    //           id: 1,
    //           text: "Demo Download",
    //           url: "https://microsoft.sharepoint.com/:u:/t/Demochamp868/ESeqg26qN3hLvLERVwb4_cQBo_Df8wrsVXv1ORT1wDcykw?e=fTYzLc",
    //         },
    //         {
    //           id: 2,
    //           text: "Live Demo Portal",
    //           url: "https://admin.cloudlabs.ai/#/main",
    //         },
    //       ],
    //       componentName: "videoWIthClickByClick",
    //       video: [
    //         {
    //           id: 1,
    //           name: "product1",
    //           thumbnailImage: "",
    //           navigateUrl: "",
    //         },
    //       ],
    //       dropDownMenu: [
    //         {
    //           id: 1,
    //           text: "Drive down operating costs",
    //           videoPlayurl: "",
    //         },

    //         // {
    //         //   id: 3,
    //         //   text: "Lakehouse Creation",
    //         //   videoPlayurl:
    //         //     "https://ep-default-mediakind-common-demo.eastus.streaming.mediakind.com/b872c8b5-d7d2-4acc-95b6-f14c01f28aca/Lakehouse_Creation_01.ism/manifest(format=m3u8-cmaf)",
    //         // },
    //       ],
    //       componentParameters: [
    //         {
    //           key: "video",
    //           value: "",
    //         },
    //         {
    //           key: "videoName1",
    //           value: "Data Engineering",
    //         },
    //         {
    //           key: "videoName2",
    //           value: "Data Pipelines",
    //         },
    //         {
    //           key: "videoUrl1",
    //           value: "",
    //         },
    //         {
    //           key: "videoUrl2",
    //           value:
    //             "https://ep-default-mediakind-common-demo.eastus.streaming.mediakind.com/e9cf446a-43c8-4823-8cee-2831ba341521/DataEngineeringV01.ism/manifest(format=m3u8-cmaf)",
    //         },
    //         {
    //           key: "clickByClick",
    //           value:
    //             "https://regale.cloud/microsoft/play/3655/microsoft-fabric-individual-sections-for-web-app-embedding-20#/0/0",
    //         },
    //         {
    //           key: "videoType",
    //           value: "clickVideo",
    //         },
    //         {
    //           key: "liveHosted",
    //           value:
    //             "https://microsoft.sharepoint.com/:u:/t/Demochamp868/ESeqg26qN3hLvLERVwb4_cQBo_Df8wrsVXv1ORT1wDcykw?e=fTYzLc",
    //         },
    //         {
    //           key: "productDemoVideo",
    //           value:
    //             "https://microsoft.seismic.com/Link/Content/DCfXJm2DFTMmC842b687QfjQmgfV",
    //         },
    //       ],
    //       video: [
    //         {
    //           id: 1,
    //           name: "product1",
    //           thumbnailImage: "",
    //           navigateUrl: "",
    //         },
    //       ],
    //       externalArrows: [],
    //       personaId: null,
    //       personaName: "Eva",
    //       personaDesignation: "Data Engineer",
    //       personaImageUrl:
    //         "https://openaidemoassets.blob.core.windows.net/personas/Eva.png",
    //     },
    //     {
    //       url: "/reduce-churn-rates",
    //       name: "Reduce churn rates with Predictive Insights & AI-Powered Action",
    //       toolTip:
    //         "Reduce churn rates with Predictive Insights & AI-Powered Action",
    //       videoDisabled: false,
    //       clickbyclickDisabled: false,
    //       liveHostedDisabled: false,
    //       productDemoVideoDisabled: true,
    //       title:
    //         "Reduce churn rates with Predictive Insights & AI-Powered Action",
    //       icon: "https://dreamdemoassets.blob.core.windows.net/nrf/left-nav-icons/click_by_click_icon.png",
    //       arrowIcon: null,
    //       order: 3,
    //       componentId: 6,
    //       showArchDiagram: true,
    //       liveHostedList: [
    //         {
    //           id: 1,
    //           text: "Demo Download",
    //           url: "https://microsoft.sharepoint.com/:u:/t/Demochamp868/ESeqg26qN3hLvLERVwb4_cQBo_Df8wrsVXv1ORT1wDcykw?e=fTYzLc",
    //         },
    //         {
    //           id: 2,
    //           text: "Live Demo Portal",
    //           url: "https://admin.cloudlabs.ai/#/main",
    //         },
    //       ],
    //       componentName: "videoWIthClickByClick",
    //       video: [
    //         {
    //           id: 1,
    //           name: "product1",
    //           thumbnailImage: "",
    //           navigateUrl: "",
    //         },
    //       ],
    //       dropDownMenu: [
    //         {
    //           id: 1,
    //           text: "Reduce churn rates with Predictive Insights ",
    //           videoPlayurl: "",
    //         },

    //         // {
    //         //   id: 3,
    //         //   text: "Lakehouse Creation",
    //         //   videoPlayurl:
    //         //     "https://ep-default-mediakind-common-demo.eastus.streaming.mediakind.com/b872c8b5-d7d2-4acc-95b6-f14c01f28aca/Lakehouse_Creation_01.ism/manifest(format=m3u8-cmaf)",
    //         // },
    //       ],
    //       componentParameters: [
    //         {
    //           key: "video",
    //           value: "",
    //         },
    //         {
    //           key: "videoName1",
    //           value: "Data Engineering",
    //         },
    //         {
    //           key: "videoName2",
    //           value: "Data Pipelines",
    //         },
    //         {
    //           key: "videoUrl1",
    //           value: "",
    //         },
    //         {
    //           key: "videoUrl2",
    //           value:
    //             "https://ep-default-mediakind-common-demo.eastus.streaming.mediakind.com/e9cf446a-43c8-4823-8cee-2831ba341521/DataEngineeringV01.ism/manifest(format=m3u8-cmaf)",
    //         },
    //         {
    //           key: "clickByClick",
    //           value:
    //             "https://regale.cloud/microsoft/play/3655/microsoft-fabric-individual-sections-for-web-app-embedding-20#/0/0",
    //         },
    //         {
    //           key: "videoType",
    //           value: "clickVideo",
    //         },
    //         {
    //           key: "liveHosted",
    //           value:
    //             "https://microsoft.sharepoint.com/:u:/t/Demochamp868/ESeqg26qN3hLvLERVwb4_cQBo_Df8wrsVXv1ORT1wDcykw?e=fTYzLc",
    //         },
    //         {
    //           key: "productDemoVideo",
    //           value:
    //             "https://microsoft.seismic.com/Link/Content/DCfXJm2DFTMmC842b687QfjQmgfV",
    //         },
    //       ],
    //       video: [
    //         {
    //           id: 1,
    //           name: "product1",
    //           thumbnailImage: "",
    //           navigateUrl: "",
    //         },
    //       ],
    //       externalArrows: [],
    //       personaId: null,
    //       personaName: "Eva",
    //       personaDesignation: "Data Engineer",
    //       personaImageUrl:
    //         "https://openaidemoassets.blob.core.windows.net/personas/Eva.png",
    //     },
    //     {
    //       url: "/drive-down-compliance-alerts-and-vulnerabilities",
    //       name: "Drive down compliance alerts and vulnerabilities",
    //       toolTip: "Drive down compliance alerts and vulnerabilities",
    //       videoDisabled: false,
    //       clickbyclickDisabled: false,
    //       liveHostedDisabled: false,
    //       productDemoVideoDisabled: true,
    //       title: "Drive down compliance alerts and vulnerabilities",
    //       icon: "https://dreamdemoassets.blob.core.windows.net/nrf/left-nav-icons/click_by_click_icon.png",
    //       arrowIcon: null,
    //       order: 3,
    //       componentId: 6,
    //       showArchDiagram: true,
    //       liveHostedList: [
    //         {
    //           id: 1,
    //           text: "Demo Download",
    //           url: "https://microsoft.sharepoint.com/:u:/t/Demochamp868/ESeqg26qN3hLvLERVwb4_cQBo_Df8wrsVXv1ORT1wDcykw?e=fTYzLc",
    //         },
    //         {
    //           id: 2,
    //           text: "Live Demo Portal",
    //           url: "https://admin.cloudlabs.ai/#/main",
    //         },
    //       ],
    //       componentName: "videoWIthClickByClick",
    //       video: [
    //         {
    //           id: 1,
    //           name: "product1",
    //           thumbnailImage: "",
    //           navigateUrl: "",
    //         },
    //       ],
    //       dropDownMenu: [
    //         {
    //           id: 1,
    //           text: "Drive down compliance alerts and vulnerabilities",
    //           videoPlayurl: "",
    //         },

    //         // {
    //         //   id: 3,
    //         //   text: "Lakehouse Creation",
    //         //   videoPlayurl:
    //         //     "https://ep-default-mediakind-common-demo.eastus.streaming.mediakind.com/b872c8b5-d7d2-4acc-95b6-f14c01f28aca/Lakehouse_Creation_01.ism/manifest(format=m3u8-cmaf)",
    //         // },
    //       ],
    //       componentParameters: [
    //         {
    //           key: "video",
    //           value: "",
    //         },
    //         {
    //           key: "videoName1",
    //           value: "Data Engineering",
    //         },
    //         {
    //           key: "videoName2",
    //           value: "Data Pipelines",
    //         },
    //         {
    //           key: "videoUrl1",
    //           value: "",
    //         },
    //         {
    //           key: "videoUrl2",
    //           value:
    //             "https://ep-default-mediakind-common-demo.eastus.streaming.mediakind.com/e9cf446a-43c8-4823-8cee-2831ba341521/DataEngineeringV01.ism/manifest(format=m3u8-cmaf)",
    //         },
    //         {
    //           key: "clickByClick",
    //           value:
    //             "https://regale.cloud/microsoft/play/3655/microsoft-fabric-individual-sections-for-web-app-embedding-20#/0/0",
    //         },
    //         {
    //           key: "videoType",
    //           value: "clickVideo",
    //         },
    //         {
    //           key: "liveHosted",
    //           value:
    //             "https://microsoft.sharepoint.com/:u:/t/Demochamp868/ESeqg26qN3hLvLERVwb4_cQBo_Df8wrsVXv1ORT1wDcykw?e=fTYzLc",
    //         },
    //         {
    //           key: "productDemoVideo",
    //           value:
    //             "https://microsoft.seismic.com/Link/Content/DCfXJm2DFTMmC842b687QfjQmgfV",
    //         },
    //       ],
    //       video: [
    //         {
    //           id: 1,
    //           name: "product1",
    //           thumbnailImage: "",
    //           navigateUrl: "",
    //         },
    //       ],
    //       externalArrows: [],
    //       personaId: null,
    //       personaName: "Eva",
    //       personaDesignation: "Data Engineer",
    //       personaImageUrl:
    //         "https://openaidemoassets.blob.core.windows.net/personas/Eva.png",
    //     },
    //     {
    //       url: "/ai-agents",
    //       name: "AI Agents + Insights from OneLake",
    //       toolTip: "AI Agents + Insights from OneLake",
    //       videoDisabled: false,
    //       clickbyclickDisabled: false,
    //       liveHostedDisabled: false,
    //       productDemoVideoDisabled: true,
    //       title: "AI Agents + Insights from OneLake",
    //       icon: "https://dreamdemoassets.blob.core.windows.net/nrf/left-nav-icons/click_by_click_icon.png",
    //       arrowIcon: null,
    //       order: 3,
    //       componentId: 6,
    //       showArchDiagram: true,
    //       liveHostedList: [
    //         {
    //           id: 1,
    //           text: "Demo Download",
    //           url: "https://microsoft.sharepoint.com/:u:/t/Demochamp868/ESeqg26qN3hLvLERVwb4_cQBo_Df8wrsVXv1ORT1wDcykw?e=fTYzLc",
    //         },
    //         {
    //           id: 2,
    //           text: "Live Demo Portal",
    //           url: "https://admin.cloudlabs.ai/#/main",
    //         },
    //       ],
    //       componentName: "videoWIthClickByClick",
    //       video: [
    //         {
    //           id: 1,
    //           name: "product1",
    //           thumbnailImage: "",
    //           navigateUrl: "",
    //         },
    //       ],
    //       dropDownMenu: [
    //         {
    //           id: 1,
    //           text: "AI Agents + Insights from OneLake",
    //           videoPlayurl:
    //             "https://ep-default-mediakind-common-demo.eastus.streaming.mediakind.com/AI_Agents_nsights/AI_Agents_nsights.ism/manifest(format=m3u8-cmaf)",
    //         },

    //         // {
    //         //   id: 3,
    //         //   text: "Lakehouse Creation",
    //         //   videoPlayurl:
    //         //     "https://ep-default-mediakind-common-demo.eastus.streaming.mediakind.com/b872c8b5-d7d2-4acc-95b6-f14c01f28aca/Lakehouse_Creation_01.ism/manifest(format=m3u8-cmaf)",
    //         // },
    //       ],
    //       componentParameters: [
    //         {
    //           key: "video",
    //           value:
    //             // "https://ep-default-mediakind-common-demo.eastus.streaming.mediakind.com/ff17f0c3-e505-4fe1-810e-7605cef72349/AIAgentsInsightsfromOneLakeV2.ism/manifest(format=m3u8-cmaf)",
    //             "https://ep-default-mediakind-common-demo.eastus.streaming.mediakind.com/AI_Agents_Insights_from_OneLake_v1/AI_Agents_Insights_from_OneLake_.ism/manifest(format=m3u8-cmaf)",
    //         },
    //         {
    //           key: "videoName1",
    //           value: "Data Engineering",
    //         },
    //         {
    //           key: "videoName2",
    //           value: "Data Pipelines",
    //         },
    //         {
    //           key: "videoUrl1",
    //           value: "",
    //         },
    //         {
    //           key: "videoUrl2",
    //           value:
    //             "https://ep-default-mediakind-common-demo.eastus.streaming.mediakind.com/e9cf446a-43c8-4823-8cee-2831ba341521/DataEngineeringV01.ism/manifest(format=m3u8-cmaf)",
    //         },
    //         {
    //           key: "clickByClick",
    //           value:
    //             "https://regale.cloud/microsoft/play/3655/microsoft-fabric-individual-sections-for-web-app-embedding-20#/0/0",
    //         },
    //         {
    //           key: "videoType",
    //           value: "clickVideo",
    //         },
    //         {
    //           key: "liveHosted",
    //           value:
    //             "https://microsoft.sharepoint.com/:u:/t/Demochamp868/ESeqg26qN3hLvLERVwb4_cQBo_Df8wrsVXv1ORT1wDcykw?e=fTYzLc",
    //         },
    //         {
    //           key: "productDemoVideo",
    //           value:
    //             "https://microsoft.seismic.com/Link/Content/DCfXJm2DFTMmC842b687QfjQmgfV",
    //         },
    //       ],
    //       video: [
    //         {
    //           id: 1,
    //           name: "product1",
    //           thumbnailImage: "",
    //           navigateUrl: "",
    //         },
    //       ],
    //       externalArrows: [],
    //       personaId: null,
    //       personaName: "Eva",
    //       personaDesignation: "Data Engineer",
    //       personaImageUrl:
    //         "https://openaidemoassets.blob.core.windows.net/personas/Eva.png",
    //     },
    //     {
    //       url: "/security-governance-and-scaling",
    //       name: "Security, Governance, and Scaling",
    //       toolTip: "Security, Governance, and Scaling",
    //       videoDisabled: false,
    //       clickbyclickDisabled: false,
    //       liveHostedDisabled: false,
    //       productDemoVideoDisabled: true,
    //       title: "Security, Governance, and Scaling",
    //       icon: "https://dreamdemoassets.blob.core.windows.net/nrf/left-nav-icons/click_by_click_icon.png",
    //       arrowIcon: null,
    //       order: 3,
    //       componentId: 6,
    //       showArchDiagram: true,
    //       liveHostedList: [
    //         {
    //           id: 1,
    //           text: "Demo Download",
    //           url: "https://microsoft.sharepoint.com/:u:/t/Demochamp868/ESeqg26qN3hLvLERVwb4_cQBo_Df8wrsVXv1ORT1wDcykw?e=fTYzLc",
    //         },
    //         {
    //           id: 2,
    //           text: "Live Demo Portal",
    //           url: "https://admin.cloudlabs.ai/#/main",
    //         },
    //       ],
    //       componentName: "videoWIthClickByClick",
    //       video: [
    //         {
    //           id: 1,
    //           name: "product1",
    //           thumbnailImage: "",
    //           navigateUrl: "",
    //         },
    //       ],
    //       dropDownMenu: [
    //         {
    //           id: 1,
    //           text: "Security, Governance, and Scaling",
    //           videoPlayurl:
    //             "https://ep-default-mediakind-common-demo.eastus.streaming.mediakind.com/Security_Governance/Security_Governance.ism/manifest(format=m3u8-cmaf)",
    //         },

    //         // {
    //         //   id: 3,
    //         //   text: "Lakehouse Creation",
    //         //   videoPlayurl:
    //         //     "https://ep-default-mediakind-common-demo.eastus.streaming.mediakind.com/b872c8b5-d7d2-4acc-95b6-f14c01f28aca/Lakehouse_Creation_01.ism/manifest(format=m3u8-cmaf)",
    //         // },
    //       ],
    //       componentParameters: [
    //         {
    //           key: "video",
    //           value:
    //             "https://ep-default-mediakind-common-demo.eastus.streaming.mediakind.com/Security_Governance/Security_Governance.ism/manifest(format=m3u8-cmaf)",
    //         },
    //         {
    //           key: "videoName1",
    //           value: "Data Engineering",
    //         },
    //         {
    //           key: "videoName2",
    //           value: "Data Pipelines",
    //         },
    //         {
    //           key: "videoUrl1",
    //           value: "",
    //         },
    //         {
    //           key: "videoUrl2",
    //           value:
    //             "https://ep-default-mediakind-common-demo.eastus.streaming.mediakind.com/e9cf446a-43c8-4823-8cee-2831ba341521/DataEngineeringV01.ism/manifest(format=m3u8-cmaf)",
    //         },
    //         {
    //           key: "clickByClick",
    //           value:
    //             "https://regale.cloud/microsoft/play/3655/microsoft-fabric-individual-sections-for-web-app-embedding-20#/0/0",
    //         },
    //         {
    //           key: "videoType",
    //           value: "clickVideo",
    //         },
    //         {
    //           key: "liveHosted",
    //           value:
    //             "https://microsoft.sharepoint.com/:u:/t/Demochamp868/ESeqg26qN3hLvLERVwb4_cQBo_Df8wrsVXv1ORT1wDcykw?e=fTYzLc",
    //         },
    //         {
    //           key: "productDemoVideo",
    //           value:
    //             "https://microsoft.seismic.com/Link/Content/DCfXJm2DFTMmC842b687QfjQmgfV",
    //         },
    //       ],
    //       video: [
    //         {
    //           id: 1,
    //           name: "product1",
    //           thumbnailImage: "",
    //           navigateUrl: "",
    //         },
    //       ],
    //       externalArrows: [],
    //       personaId: null,
    //       personaName: "Eva",
    //       personaDesignation: "Data Engineer",
    //       personaImageUrl:
    //         "https://openaidemoassets.blob.core.windows.net/personas/Eva.png",
    //     },
    //     // {
    //     //   url: "/data-wrangler",
    //     //   name: "Data Wrangler",
    //     //   toolTip: "Data Wrangler",
    //     //   videoDisabled: false,
    //     //   clickbyclickDisabled: false,
    //     //   liveHostedDisabled: false,
    //     //   productDemoVideoDisabled: true,
    //     //   title: "Data Wrangler",
    //     //   icon: "https://dreamdemoassets.blob.core.windows.net/nrf/left-nav-icons/click_by_click_icon.png",
    //     //   arrowIcon: null,
    //     //   order: 3,
    //     //   componentId: 6,
    //     //   componentName: "videoWIthClickByClick",
    //     //   video: [
    //     //     {
    //     //       id: 1,
    //     //       name: "product1",
    //     //       thumbnailImage: "",
    //     //       navigateUrl: "",
    //     //     },
    //     //   ],
    //     //   dropDownMenu: [
    //     //     {
    //     //       id: 1,
    //     //       text: "Data Engineering",
    //     //       videoPlayurl:
    //     //         "https://simdemo.azureedge.net/dai/videos/data-engineering/index.html",
    //     //     },
    //     //     {
    //     //       id: 2,
    //     //       text: "Data Pipelines",
    //     //       videoPlayurl:
    //     //         "https://ep-default-mediakind-common-demo.eastus.streaming.mediakind.com/e9cf446a-43c8-4823-8cee-2831ba341521/DataEngineeringV01.ism/manifest(format=m3u8-cmaf)",
    //     //     },
    //     //     // {
    //     //     //   id: 3,
    //     //     //   text: "Lakehouse Creation",
    //     //     //   videoPlayurl:
    //     //     //     "https://ep-default-mediakind-common-demo.eastus.streaming.mediakind.com/b872c8b5-d7d2-4acc-95b6-f14c01f28aca/Lakehouse_Creation_01.ism/manifest(format=m3u8-cmaf)",
    //     //     // },
    //     //   ],
    //     //   componentParameters: [
    //     //     {
    //     //       key: "video",
    //     //       value:
    //     //         "https://simdemo.azureedge.net/dai/videos/data-engineering/index.html",
    //     //     },
    //     //     {
    //     //       key: "videoName1",
    //     //       value: "Data Engineering",
    //     //     },
    //     //     {
    //     //       key: "videoName2",
    //     //       value: "Data Pipelines",
    //     //     },
    //     //     {
    //     //       key: "videoUrl1",
    //     //       value:
    //     //         "https://simdemo.azureedge.net/dai/videos/data-engineering/index.html",
    //     //     },
    //     //     {
    //     //       key: "videoUrl2",
    //     //       value:
    //     //         "https://ep-default-mediakind-common-demo.eastus.streaming.mediakind.com/e9cf446a-43c8-4823-8cee-2831ba341521/DataEngineeringV01.ism/manifest(format=m3u8-cmaf)",
    //     //     },
    //     //     {
    //     //       key: "clickByClick",
    //     //       value:
    //     //         "https://regale.cloud/microsoft/play/3655/microsoft-fabric-individual-sections-for-web-app-embedding-20#/0/0",
    //     //     },
    //     //     {
    //     //       key: "videoType",
    //     //       value: "clickVideo",
    //     //     },
    //     //     {
    //     //       key: "liveHosted",
    //     //       value:
    //     //         "https://microsoft.sharepoint.com/:u:/t/Demochamp868/ESeqg26qN3hLvLERVwb4_cQBo_Df8wrsVXv1ORT1wDcykw?e=fTYzLc",
    //     //     },
    //     //     {
    //     //       key: "productDemoVideo",
    //     //       value:
    //     //         "https://microsoft.seismic.com/Link/Content/DCfXJm2DFTMmC842b687QfjQmgfV",
    //     //     },
    //     //   ],
    //     //   video: [
    //     //     {
    //     //       id: 1,
    //     //       name: "product1",
    //     //       thumbnailImage: "",
    //     //       navigateUrl: "",
    //     //     },
    //     //   ],
    //     //   externalArrows: [],
    //     //   personaId: null,
    //     //   personaName: "Eva",
    //     //   personaDesignation: "Data Engineer",
    //     //   personaImageUrl:
    //     //     "https://openaidemoassets.blob.core.windows.net/personas/Eva.png",
    //     // },
    //     {
    //       url: "/real-time-intelligence",
    //       name: "Real-time Intelligence in Fabric",
    //       toolTip: "Real-time Intelligence in Fabric",
    //       videoDisabled: false,
    //       clickbyclickDisabled: false,
    //       liveHostedDisabled: false,
    //       productDemoVideoDisabled: true,
    //       title: "Real-time Intelligence in Fabric",
    //       icon: "https://dreamdemoassets.blob.core.windows.net/nrf/left-nav-icons/click_by_click_icon.png",
    //       arrowIcon: null,
    //       order: 3,
    //       componentId: 6,
    //       showArchDiagram: true,
    //       liveHostedList: [
    //         {
    //           id: 1,
    //           text: "Demo Download",
    //           url: "https://microsoft.sharepoint.com/:u:/t/Demochamp868/ESeqg26qN3hLvLERVwb4_cQBo_Df8wrsVXv1ORT1wDcykw?e=fTYzLc",
    //         },
    //         {
    //           id: 2,
    //           text: "Live Demo Portal",
    //           url: "https://admin.cloudlabs.ai/#/main",
    //         },
    //       ],
    //       componentName: "videoWIthClickByClick",
    //       video: [
    //         {
    //           id: 1,
    //           name: "product1",
    //           thumbnailImage: "",
    //           navigateUrl: "",
    //         },
    //       ],

    //       dropDownMenu: [
    //         {
    //           id: 1,
    //           text: "Real-Time Intelligence & Data Activator",
    //           videoPlayurl:
    //             "https://ep-default-mediakind-common-demo.eastus.streaming.mediakind.com/c2aeea69-148e-48af-9736-fa91b6cfb109/RTIV6.ism/manifest(format=m3u8-cmaf)",
    //         },
    //         // {
    //         //   id: 2,
    //         //   text: "RTI + Data Activator",
    //         //   videoPlayurl:
    //         //     "https://ep-default-mediakind-common-demo.eastus.streaming.mediakind.com/9a0d0f2c-e724-46f5-a8ec-16513b7a7f09/Data_AI_Real_TimeIntelligence_V0.ism/manifest(format=m3u8-cmaf)",
    //         // },
    //       ],

    //       componentParameters: [
    //         {
    //           key: "video",
    //           value:
    //             "https://ep-default-mediakind-common-demo.eastus.streaming.mediakind.com/c2aeea69-148e-48af-9736-fa91b6cfb109/RTIV6.ism/manifest(format=m3u8-cmaf)",
    //         },
    //         {
    //           key: "videoName1",
    //           value: "Real-Time Intelligence & Data Activator",
    //         },
    //         {
    //           key: "videoName2",
    //           value: "RTI + Data Activator",
    //         },
    //         {
    //           key: "videoUrl1",
    //           value:
    //             "https://simdemo.azureedge.net/dai/videos/rti-data-activator-2/index.html",
    //         },
    //         {
    //           key: "videoUrl2",
    //           value:
    //             "https://ep-default-mediakind-common-demo.eastus.streaming.mediakind.com/9a0d0f2c-e724-46f5-a8ec-16513b7a7f09/Data_AI_Real_TimeIntelligence_V0.ism/manifest(format=m3u8-cmaf)",
    //         },
    //         {
    //           key: "videoType",
    //           value: "clickVideo",
    //         },

    //         {
    //           key: "clickByClick",
    //           value:
    //             "https://regale.cloud/microsoft/play/3655/microsoft-fabric-individual-sections-for-web-app-embedding-20#/11/0",
    //         },
    //         {
    //           key: "liveHosted",
    //           value:
    //             "https://microsoft.sharepoint.com/:u:/t/Demochamp868/ETzYtTGijFBJvbtSjxXYnEQB3xnWrxoY3frx3ElSV6r6ag?e=M5QVeo",
    //         },
    //         {
    //           key: "productDemoVideo",
    //           value:
    //             "https://microsoft.sharepoint.com/:v:/t/Demochamp868/EfA8AqPmGqRKjk7_xmjO428BDfUmQvbE3WJiC8rhFqSHPA?e=CYykmZ",
    //         },
    //       ],
    //       video: [
    //         {
    //           id: 1,
    //           name: "product1",
    //           thumbnailImage: "",
    //           navigateUrl: "",
    //         },
    //       ],
    //       externalArrows: [],
    //       personaId: null,
    //       personaName: "Eva",
    //       personaDesignation: "Data Engineer",
    //       personaImageUrl:
    //         "https://openaidemoassets.blob.core.windows.net/personas/Eva.png",
    //     },
    //     {
    //       url: "/mirrored-azure-databricks",
    //       name: "Mirrored Azure Databricks Unity Catalog in Fabric",
    //       toolTip: "Mirrored Azure Databricks Unity Catalog in Fabric",
    //       videoDisabled: false,
    //       clickbyclickDisabled: false,
    //       liveHostedDisabled: false,
    //       productDemoVideoDisabled: true,
    //       title: "Mirrored Azure Databricks Unity Catalog in Fabric",
    //       icon: "https://dreamdemoassets.blob.core.windows.net/nrf/left-nav-icons/click_by_click_icon.png",
    //       arrowIcon: null,
    //       order: 3,
    //       componentId: 6,
    //       showArchDiagram: true,
    //       liveHostedList: [
    //         {
    //           id: 1,
    //           text: "Demo Download",
    //           url: "https://microsoft.sharepoint.com/:u:/t/Demochamp868/ESeqg26qN3hLvLERVwb4_cQBo_Df8wrsVXv1ORT1wDcykw?e=fTYzLc",
    //         },
    //         {
    //           id: 2,
    //           text: "Live Demo Portal",
    //           url: "https://admin.cloudlabs.ai/#/main",
    //         },
    //       ],
    //       componentName: "videoWIthClickByClick",
    //       video: [
    //         {
    //           id: 1,
    //           name: "product1",
    //           thumbnailImage: "",
    //           navigateUrl: "",
    //         },
    //       ],
    //       dropDownMenu: [
    //         {
    //           id: 1,
    //           text: "Mirrored ADB Catalog",
    //           videoPlayurl:
    //             "https://simdemo.azureedge.net/dai/videos/mirrored-azure-databricks-catalog/index.html",
    //         },
    //         {
    //           id: 2,
    //           text: "Databricks Integration",
    //           videoPlayurl:
    //             "https://ep-default-mediakind-common-demo.eastus.streaming.mediakind.com/efd9b9b1-1e81-4009-b4b9-392187332bb7/AzureDatabricksIntegration_V01_2.ism/manifest(format=m3u8-cmaf)",
    //         },
    //       ],
    //       componentParameters: [
    //         {
    //           key: "video",
    //           value:
    //             // "https://mediasvcprodhealthcare-usw22.streaming.media.azure.net/c4abd415-743f-4eeb-9f7b-31768bd63c56/Unity_Catalogue_Video_V06.ism/manifest",
    //             // "https://ep-default-mediakind-common-demo.eastus.streaming.mediakind.com/d5906b10-9213-46d6-89c8-ae733c8f65d9/Azure_Databricks_Integration_V02.ism/manifest(format=m3u8-cmaf)",
    //             "https://simdemo.azureedge.net/dai/videos/mirrored-azure-databricks-catalog/index.html",
    //         },
    //         {
    //           key: "videoType",
    //           value: "clickVideo",
    //         },
    //         {
    //           key: "videoName1",
    //           value: "Mirrored ADB Catalog",
    //         },
    //         {
    //           key: "videoName2",
    //           value: "Databricks Integration",
    //         },
    //         {
    //           key: "videoUrl1",
    //           value:
    //             "https://simdemo.azureedge.net/dai/videos/mirrored-azure-databricks-catalog/index.html",
    //         },
    //         {
    //           key: "videoUrl2",
    //           value:
    //             "https://ep-default-mediakind-common-demo.eastus.streaming.mediakind.com/efd9b9b1-1e81-4009-b4b9-392187332bb7/AzureDatabricksIntegration_V01_2.ism/manifest(format=m3u8-cmaf)",
    //         },
    //         {
    //           key: "liveHosted",
    //           value:
    //             "https://microsoft.sharepoint.com/teams/DataandAIReadinessCoolTeam/Shared Documents/General/_____Data & AI Big Demo/../../../../../:u:/t/Demochamp868/Eelfm8bxIP9BjCbpLTXlZpwB4lvTBgWeaAzwKcz6jbWCBA?e=RG0bTH",
    //         },
    //         {
    //           key: "clickByClick",
    //           value:
    //             "https://regale.cloud/microsoft/play/3655/microsoft-fabric-individual-sections-for-web-app-embedding-20#/6/0",
    //         },
    //         {
    //           key: "productDemoVideo",
    //           value:
    //             "https://microsoft.sharepoint.com/:v:/t/Demochamp868/EdU8Amzq0lJIhJGfLRDIHVIByv9mTsScNyZE69_NfJT3oA?e=jE9hoh",
    //         },
    //       ],
    //       video: [
    //         {
    //           id: 1,
    //           name: "product1",
    //           thumbnailImage: "",
    //           navigateUrl: "",
    //         },
    //       ],
    //       externalArrows: [],
    //       personaId: null,
    //       personaName: "Eva",
    //       personaDesignation: "Data Engineer",
    //       personaImageUrl:
    //         "https://openaidemoassets.blob.core.windows.net/personas/Eva.png",
    //     },
    //     {
    //       url: "/copilot-for-data-science-in-fabric",
    //       name: "Copilot for Data Science in Fabric",
    //       toolTip: "Copilot for Data Science in Fabric",
    //       videoDisabled: false,
    //       clickbyclickDisabled: false,
    //       liveHostedDisabled: false,
    //       productDemoVideoDisabled: false,
    //       title: "Copilot for Data Science in Fabric",
    //       icon: "https://dreamdemoassets.blob.core.windows.net/nrf/left-nav-icons/click_by_click_icon.png",
    //       arrowIcon: null,
    //       order: 3,
    //       componentId: 6,
    //       showArchDiagram: true,
    //       componentName: "videoWIthClickByClick",
    //       liveHostedList: [
    //         {
    //           id: 1,
    //           text: "Demo Download",
    //           url: "https://microsoft.sharepoint.com/:u:/t/Demochamp868/ESeqg26qN3hLvLERVwb4_cQBo_Df8wrsVXv1ORT1wDcykw?e=fTYzLc",
    //         },
    //         {
    //           id: 2,
    //           text: "Live Demo Portal",
    //           url: "https://admin.cloudlabs.ai/#/main",
    //         },
    //       ],
    //       dropDownMenu: [
    //         {
    //           id: 1,
    //           text: "Data Science",
    //           videoPlayurl:
    //             "https://ep-default-mediakind-common-demo.eastus.streaming.mediakind.com/47861ae1-4c0a-4bfc-bf1f-569e97a109e5/Scenario2Chapter3DataScienceAIWo.ism/manifest(format=m3u8-cmaf)",
    //         },
    //         // {
    //         //   id: 2,
    //         //   text: "Copilot in Notebook",
    //         //   videoPlayurl:
    //         //     "https://ep-default-mediakind-common-demo.eastus.streaming.mediakind.com/612789e2-a7c5-4123-9c95-464e405c4b6f/DataScienceV001.ism/manifest(format=m3u8-cmaf)",
    //         // },
    //       ],
    //       video: [
    //         {
    //           id: 1,
    //           name: "End-to-end AI powered solution development",
    //           thumbnailImage:
    //             "https://dreamdemoassets.blob.core.windows.net/dataandaidemo/dataScience1.jfif",
    //           navigateUrl:
    //             "https://microsoft.sharepoint.com/:v:/t/Demochamp868/EV0vNT4ws2NEsMYyN5BoSxgBJeW2oQJuaPXuakLoZIRHWQ?e=DgCliN",
    //         },
    //         {
    //           id: 2,
    //           name: "AI Powered Analytics",
    //           thumbnailImage:
    //             "https://dreamdemoassets.blob.core.windows.net/dataandaidemo/datascience2.png",
    //           navigateUrl:
    //             "https://microsoft.sharepoint.com/:v:/t/Demochamp868/EV0vNT4ws2NEsMYyN5BoSxgBJeW2oQJuaPXuakLoZIRHWQ?e=DgCliN",
    //         },
    //       ],

    //       componentParameters: [
    //         {
    //           key: "video",
    //           value:
    //             "https://ep-default-mediakind-common-demo.eastus.streaming.mediakind.com/47861ae1-4c0a-4bfc-bf1f-569e97a109e5/Scenario2Chapter3DataScienceAIWo.ism/manifest(format=m3u8-cmaf)",
    //         },
    //         {
    //           key: "videoType",
    //           value: "clickVideo",
    //         },
    //         {
    //           key: "videoName1",
    //           value: "Data Science",
    //         },
    //         {
    //           key: "videoName2",
    //           value: "Copilot in Notebook",
    //         },
    //         {
    //           key: "videoUrl1",
    //           value:
    //             "https://simdemo.azureedge.net/dai/videos/data-science/index.html",
    //         },
    //         {
    //           key: "videoUrl2",
    //           value:
    //             "https://ep-default-mediakind-common-demo.eastus.streaming.mediakind.com/612789e2-a7c5-4123-9c95-464e405c4b6f/DataScienceV001.ism/manifest(format=m3u8-cmaf)",
    //         },

    //         {
    //           key: "clickByClick",
    //           value:
    //             "https://regale.cloud/microsoft/play/3655/microsoft-fabric-individual-sections-for-web-app-embedding-20#/2/0",
    //         },
    //         {
    //           key: "liveHosted",
    //           value:
    //             "https://microsoft.sharepoint.com/:u:/t/Demochamp868/EayQ2ugZA-hNu0XZVxFJMPABi9ByS0vnr5iNkW3QF90Zjw?e=Wx9Dmv",
    //         },
    //         {
    //           key: "productDemoVideo",
    //           value:
    //             "https://microsoft.sharepoint.com/:v:/t/Demochamp868/EblKYhCku7VAqSCogiUO9xUB8Jo-7Y1Ww6y3AYg5qvrDQQ?e=WNCJQb",
    //         },
    //       ],

    //       externalArrows: [],
    //       personaId: null,
    //       personaName: "Eva",
    //       personaDesignation: "Data Engineer",
    //       personaImageUrl:
    //         "https://openaidemoassets.blob.core.windows.net/personas/Eva.png",
    //     },
    //     {
    //       name: "Power BI experience",
    //       title: "Power BI experience",
    //       url: "/powerbi-experience",
    //       icon: "https://dreamdemoassets.blob.core.windows.net/nrf/left-nav-icons/video_2_icon.png",
    //       arrowIcon: null,
    //       toolTip: "Power BI experience",
    //       order: 5,
    //       videoDisabled: false,
    //       clickbyclickDisabled: false,
    //       liveHostedDisabled: false,
    //       productDemoVideoDisabled: false,
    //       componentId: 6,
    //       showArchDiagram: true,
    //       liveHostedList: [
    //         {
    //           id: 1,
    //           text: "Demo Download",
    //           url: "https://microsoft.sharepoint.com/:u:/t/Demochamp868/ESeqg26qN3hLvLERVwb4_cQBo_Df8wrsVXv1ORT1wDcykw?e=fTYzLc",
    //         },
    //         {
    //           id: 2,
    //           text: "Live Demo Portal",
    //           url: "https://admin.cloudlabs.ai/#/main",
    //         },
    //       ],
    //       componentName: "videoWIthClickByClick",
    //       dropDownMenu: [
    //         {
    //           id: 1,
    //           text: "Power BI experience",
    //           videoPlayurl:
    //             "https://simdemo.azureedge.net/dai/videos/copilot-in-power-bi/index.html",
    //         },
    //       ],
    //       video: [
    //         {
    //           id: 1,
    //           name: "Improved Copilot for report authoring",
    //           thumbnailImage:
    //             "https://dreamdemoassets.blob.core.windows.net/dataandaidemo/dataScience1.jfif",
    //           navigateUrl:
    //             "https://microsoft.sharepoint.com/:v:/t/Demochamp868/EdbTlQ1iwg1OsgmTktvchGkBeRHkmLRc_5_wfAvd2oLEsQ?e=Pig4bz",
    //         },
    //       ],
    //       componentParameters: [
    //         {
    //           key: "video",
    //           value:
    //             "https://simdemo.azureedge.net/dai/videos/copilot-in-power-bi/index.html",
    //         },
    //         {
    //           key: "videoType",
    //           value: "clickVideo",
    //         },
    //         {
    //           key: "videoName1",
    //           value: "Power BI experience",
    //         },
    //         {
    //           key: "videoName2",
    //           value: "",
    //         },
    //         {
    //           key: "videoUrl1",
    //           value:
    //             "https://simdemo.azureedge.net/dai/videos/copilot-in-power-bi/index.html",
    //         },
    //         {
    //           key: "videoUrl2",
    //           value: "",
    //         },
    //         {
    //           key: "clickByClick",
    //           value:
    //             "https://regale.cloud/microsoft/play/2939/copilot-for-power-bi-in-microsoft-fabric-dream-demo-english-portuguese-version#/0/0",
    //         },
    //         {
    //           key: "liveHosted",
    //           value:
    //             "https://microsoft.sharepoint.com/teams/DataandAIReadinessCoolTeam/Shared Documents/General/_____Data & AI Big Demo/../../../../../:u:/t/Demochamp868/ETKbNQMXlihKoygJwfS1mSkBH_ZVTex0GD4i0qk0Yrf9EA?e=jg3Rpg",
    //         },
    //         {
    //           key: "productDemoVideo",
    //           value:
    //             "https://microsoft.sharepoint.com/:v:/t/Demochamp868/EdbTlQ1iwg1OsgmTktvchGkBeRHkmLRc_5_wfAvd2oLEsQ?e=Pig4bz",
    //         },
    //       ],
    //       externalArrows: [],
    //       personaId: null,
    //       personaName: "April",
    //       personaDesignation: "Chief Executive Officer",
    //       personaImageUrl:
    //         "https://openaidemoassets.blob.core.windows.net/personas/April.png",
    //     },
    //     {
    //       url: "/copilot-for-power-bi-in-fabric",
    //       name: "Copilot for Power BI in Fabric",
    //       toolTip: "Copilot for Power BI in Fabric",
    //       videoDisabled: false,
    //       clickbyclickDisabled: false,
    //       liveHostedDisabled: false,
    //       productDemoVideoDisabled: true,
    //       title: "Copilot for Power BI in Fabric",
    //       icon: "https://dreamdemoassets.blob.core.windows.net/nrf/left-nav-icons/click_by_click_icon.png",
    //       arrowIcon: null,
    //       order: 3,
    //       componentId: 6,
    //       showArchDiagram: true,
    //       liveHostedList: [
    //         {
    //           id: 1,
    //           text: "Demo Download",
    //           url: "https://microsoft.sharepoint.com/:u:/t/Demochamp868/ESeqg26qN3hLvLERVwb4_cQBo_Df8wrsVXv1ORT1wDcykw?e=fTYzLc",
    //         },
    //         {
    //           id: 2,
    //           text: "Live Demo Portal",
    //           url: "https://admin.cloudlabs.ai/#/main",
    //         },
    //       ],
    //       componentName: "videoWIthClickByClick",

    //       dropDownMenu: [
    //         {
    //           id: 1,
    //           text: "Power BI experience",
    //           videoPlayurl:
    //             "https://ep-default-mediakind-common-demo.eastus.streaming.mediakind.com/c31acdda-ab88-4dc4-88f0-0f839a7f44dd/Power_BI_Latest.ism/manifest(format=m3u8-cmaf)",
    //         },
    //       ],
    //       video: [
    //         {
    //           id: 1,
    //           name: "Improved Copilot for report authoring",
    //           thumbnailImage:
    //             "https://dreamdemoassets.blob.core.windows.net/dataandaidemo/dataScience1.jfif",
    //           navigateUrl:
    //             "https://microsoft.sharepoint.com/:v:/t/Demochamp868/EdbTlQ1iwg1OsgmTktvchGkBeRHkmLRc_5_wfAvd2oLEsQ?e=Pig4bz",
    //         },
    //       ],
    //       componentParameters: [
    //         {
    //           key: "video",
    //           value:
    //             // "https://ep-default-mediakind-common-demo.eastus.streaming.mediakind.com/c31acdda-ab88-4dc4-88f0-0f839a7f44dd/Power_BI_Latest.ism/manifest(format=m3u8-cmaf)",
    //             "https://ep-default-mediakind-common-demo.eastus.streaming.mediakind.com/fae37a2a-2717-459f-9516-5baf969a2c02/Copilot_for_Power_BI_Hero_Demo_2.ism/manifest(format=m3u8-cmaf)",
    //         },
    //         {
    //           key: "videoType",
    //           value: "clickVideo",
    //         },
    //         {
    //           key: "videoName1",
    //           value: "Power BI experience",
    //         },
    //         {
    //           key: "videoName2",
    //           value: "",
    //         },
    //         {
    //           key: "videoUrl1",
    //           value:
    //             "https://simdemo.azureedge.net/dai/videos/copilot-in-power-bi/index.html",
    //         },
    //         {
    //           key: "videoUrl2",
    //           value: "",
    //         },
    //         {
    //           key: "clickByClick",
    //           value:
    //             "https://regale.cloud/microsoft/play/2939/copilot-for-power-bi-in-microsoft-fabric-dream-demo-english-portuguese-version#/0/0",
    //         },
    //         {
    //           key: "liveHosted",
    //           value:
    //             "https://microsoft.sharepoint.com/teams/DataandAIReadinessCoolTeam/Shared Documents/General/_____Data & AI Big Demo/../../../../../:u:/t/Demochamp868/ETKbNQMXlihKoygJwfS1mSkBH_ZVTex0GD4i0qk0Yrf9EA?e=jg3Rpg",
    //         },
    //         {
    //           key: "productDemoVideo",
    //           value:
    //             "https://microsoft.sharepoint.com/:v:/t/Demochamp868/EV61ruvCH8JMsekKVICxEBkBqd9N7gejv-AJcVMu2TqEDw?e=mY1GfM",
    //         },
    //       ],
    //       video: [
    //         {
    //           id: 1,
    //           name: "product1",
    //           thumbnailImage: "",
    //           navigateUrl: "",
    //         },
    //       ],
    //       externalArrows: [],
    //       personaId: null,
    //       personaName: "Eva",
    //       personaDesignation: "Data Engineer",
    //       personaImageUrl:
    //         "https://openaidemoassets.blob.core.windows.net/personas/Eva.png",
    //     },
    //     {
    //       url: "/building-new-app-with-copilot-agent-mode",
    //       name: "Building a New App with Copilot Agent Mode",
    //       toolTip: "Building a New App with Copilot Agent Mode",
    //       videoDisabled: false,
    //       clickbyclickDisabled: false,
    //       liveHostedDisabled: false,
    //       productDemoVideoDisabled: true,
    //       title: "Building a New App with Copilot Agent Mode",
    //       icon: "https://dreamdemoassets.blob.core.windows.net/nrf/left-nav-icons/click_by_click_icon.png",
    //       arrowIcon: null,
    //       order: 3,
    //       componentId: 6,
    //       showArchDiagram: true,
    //       liveHostedList: [
    //         {
    //           id: 1,
    //           text: "Demo Download",
    //           url: "https://microsoft.sharepoint.com/:u:/t/Demochamp868/ESeqg26qN3hLvLERVwb4_cQBo_Df8wrsVXv1ORT1wDcykw?e=fTYzLc",
    //         },
    //         {
    //           id: 2,
    //           text: "Live Demo Portal",
    //           url: "https://admin.cloudlabs.ai/#/main",
    //         },
    //       ],
    //       componentName: "videoWIthClickByClick",

    //       dropDownMenu: [
    //         {
    //           id: 1,
    //           text: "Building a New App with Copilot Agent Mode",
    //           videoPlayurl:
    //             "https://ep-default-mediakind-common-demo.eastus.streaming.mediakind.com/1c6b83c1-ea06-4c87-8756-f5c9d40e5f99/Github_Copilot2.ism/manifest(format=m3u8-cmaf)",
    //         },
    //          {
    //           id: 2,
    //           text: "Agentic DevOps in Actions",
    //           videoPlayurl: "https://ep-default-mediakind-common-demo.eastus.streaming.mediakind.com/5195a142-5223-4078-a64f-d758dafc99b1/Agentic_Devops_GitHub_Copilot_Az.ism/manifest(format=m3u8-cmaf)",
    //         },
    //       ],
    //       video: [
    //         {
    //           id: 1,
    //           name: "Improved Copilot for report authoring",
    //           thumbnailImage:
    //             "https://dreamdemoassets.blob.core.windows.net/dataandaidemo/dataScience1.jfif",
    //           navigateUrl:
    //             "https://microsoft.sharepoint.com/:v:/t/Demochamp868/EdbTlQ1iwg1OsgmTktvchGkBeRHkmLRc_5_wfAvd2oLEsQ?e=Pig4bz",
    //         },
    //       ],
    //       componentParameters: [
    //         {
    //           key: "video",
    //           value:
    //             "https://ep-default-mediakind-common-demo.eastus.streaming.mediakind.com/1c6b83c1-ea06-4c87-8756-f5c9d40e5f99/Github_Copilot2.ism/manifest(format=m3u8-cmaf)",
    //         },
    //         {
    //           key: "videoType",
    //           value: "clickVideo",
    //         },
    //         {
    //           key: "videoName1",
    //           value: "Power BI experience",
    //         },
    //         {
    //           key: "videoName2",
    //           value: "Agentic DevOps in Actions",
    //         },
    //         {
    //           key: "videoUrl1",
    //           value:
    //             "https://simdemo.azureedge.net/dai/videos/copilot-in-power-bi/index.html",
    //         },
    //         {
    //           key: "videoUrl2",
    //           value: "",
    //         },
    //         {
    //           key: "clickByClick",
    //           value:
    //             "https://regale.cloud/microsoft/play/2939/copilot-for-power-bi-in-microsoft-fabric-dream-demo-english-portuguese-version#/0/0",
    //         },
    //         {
    //           key: "liveHosted",
    //           value:
    //             "https://microsoft.sharepoint.com/teams/DataandAIReadinessCoolTeam/Shared Documents/General/_____Data & AI Big Demo/../../../../../:u:/t/Demochamp868/ETKbNQMXlihKoygJwfS1mSkBH_ZVTex0GD4i0qk0Yrf9EA?e=jg3Rpg",
    //         },
    //         {
    //           key: "productDemoVideo",
    //           value:
    //             "https://microsoft.sharepoint.com/:v:/t/Demochamp868/EV61ruvCH8JMsekKVICxEBkBqd9N7gejv-AJcVMu2TqEDw?e=mY1GfM",
    //         },
    //       ],
    //       video: [
    //         {
    //           id: 1,
    //           name: "product1",
    //           thumbnailImage: "",
    //           navigateUrl: "",
    //         },
    //       ],
    //       externalArrows: [],
    //       personaId: null,
    //       personaName: "Eva",
    //       personaDesignation: "Data Engineer",
    //       personaImageUrl:
    //         "https://openaidemoassets.blob.core.windows.net/personas/Eva.png",
    //     },
    //   ],

    //   componentParameters: [],
    //   externalArrows: [],
    //   componentId: null,
    //   componentName: null,
    //   personaId: null,
    //   personaName: "April",
    //   personaDesignation: "Chief Executive Officer",
    //   personaImageUrl:
    //     "https://openaidemoassets.blob.core.windows.net/personas/April.png",
    // },
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

        // {
        //   id: 3,
        //   url: "/Product-on-Hold",
        //   name: "Product on Hold",
        //   icon: "https://dreamdemoassets.blob.core.windows.net/openai/shopping_assistant_icon.png",
        //   arrowIcon: null,
        //   order: 1,
        //   componentId: 3,
        //   componentName: "hold shopping copilot",
        //   componentParameters: [],
        //   externalArrows: [],
        //   personaId: 1,
        //   personaName: "Anna",
        //   personaImageUrl:
        //     "https://openaidemoassets.blob.core.windows.net/personas/Anna.png",
        // },

        // {
        //   id: 3,
        //   url: "/smarter-inventory-control",
        //   name: "Smarter Inventory Control",
        //   icon: "https://dreamdemoassets.blob.core.windows.net/openai/reports_icon.png",
        //   arrowIcon: "",
        //   order: 1,
        //   componentId: 3,
        //   componentName: "sales performance",
        //   componentParameters: [
        //     {
        //       key: "url",
        //       value:
        //         "https://app.powerbi.com/groups/644a4412-d11e-4c52-b984-e6f88ba57eca/reports/a486cf2c-70ff-4996-bea7-654fc3d83de2/0d8648dfa488793af4c0?experience=power-bi",
        //       // "https://app.powerbi.com/groups/5ebd665f-b65f-417b-b061-4eaf8a9e08a5/reports/87b83bb8-5dbd-4f9c-8c00-a9d371522190/f189c7f5cd6e336109db?experience=power-bi&clientSideAuth=0",
        //     },
        //   ],
        //   externalArrows: [],
        //   personaId: 1,
        //   personaName: "Albert",
        //   personaDesignation: "Chief Merchandising Officer",
        //   personaImageUrl:
        //     "https://dreamdemoassets.blob.core.windows.net/aidemo/AlbertAvtarV1.png",
        // },
        // {
        //   url: "/assessment-strategy",
        //   name: "Assessment and Strategy",
        //   toolTip: "Assessment and Strategy",
        //   videoDisabled: false,
        //   clickbyclickDisabled: false,
        //   liveHostedDisabled: false,
        //   productDemoVideoDisabled: true,
        //   showArchDiagram: false,
        //   title: "Assessment and Strategy",
        //   icon: "https://dreamdemoassets.blob.core.windows.net/nrf/left-nav-icons/click_by_click_icon.png",
        //   arrowIcon: null,
        //   order: 3,
        //   componentId: 6,
        //   liveHostedList: [
        //     {
        //       id: 1,
        //       text: "Demo Download",
        //       url: "https://microsoft.sharepoint.com/:u:/t/Demochamp868/ESeqg26qN3hLvLERVwb4_cQBo_Df8wrsVXv1ORT1wDcykw?e=fTYzLc",
        //     },
        //     {
        //       id: 2,
        //       text: "Live Demo Portal",
        //       url: "https://admin.cloudlabs.ai/#/main",
        //     },
        //   ],
        //   componentName: "videoWIthClickByClick",
        //   video: [
        //     {
        //       id: 1,
        //       name: "product1",
        //       thumbnailImage: "",
        //       navigateUrl: "",
        //     },
        //   ],
        //   dropDownMenu: [
        //     {
        //       id: 1,
        //       text: "Assessment and Strategy",
        //       videoPlayurl: "",
        //     },

        //     // {
        //     //   id: 3,
        //     //   text: "Lakehouse Creation",
        //     //   videoPlayurl:
        //     //     "https://ep-default-mediakind-common-demo.eastus.streaming.mediakind.com/b872c8b5-d7d2-4acc-95b6-f14c01f28aca/Lakehouse_Creation_01.ism/manifest(format=m3u8-cmaf)",
        //     // },
        //   ],
        //   componentParameters: [
        //     {
        //       key: "video",
        //       value: "",
        //     },
        //     {
        //       key: "videoName1",
        //       value: "Data Engineering",
        //     },
        //     {
        //       key: "videoName2",
        //       value: "Data Pipelines",
        //     },
        //     {
        //       key: "videoUrl1",
        //       value: "",
        //     },
        //     {
        //       key: "videoUrl2",
        //       value:
        //         "https://ep-default-mediakind-common-demo.eastus.streaming.mediakind.com/e9cf446a-43c8-4823-8cee-2831ba341521/DataEngineeringV01.ism/manifest(format=m3u8-cmaf)",
        //     },
        //     {
        //       key: "clickByClick",
        //       value:
        //         "https://regale.cloud/microsoft/play/3655/microsoft-fabric-individual-sections-for-web-app-embedding-20#/0/0",
        //     },
        //     {
        //       key: "videoType",
        //       value: "clickVideo",
        //     },
        //     {
        //       key: "liveHosted",
        //       value:
        //         "https://microsoft.sharepoint.com/:u:/t/Demochamp868/ESeqg26qN3hLvLERVwb4_cQBo_Df8wrsVXv1ORT1wDcykw?e=fTYzLc",
        //     },
        //     {
        //       key: "productDemoVideo",
        //       value:
        //         "https://microsoft.seismic.com/Link/Content/DCfXJm2DFTMmC842b687QfjQmgfV",
        //     },
        //   ],
        //   video: [
        //     {
        //       id: 1,
        //       name: "product1",
        //       thumbnailImage: "",
        //       navigateUrl: "",
        //     },
        //   ],
        //   externalArrows: [],
        //   personaId: null,
        //   personaName: "Eva",
        //   personaDesignation: "Data Engineer",
        //   personaImageUrl:
        //     "https://openaidemoassets.blob.core.windows.net/personas/Eva.png",
        // },
        // {
        //   url: "/migration-tools-best-practices",
        //   name: "Migration Tools & Best Practices",
        //   toolTip: "Migration Tools & Best Practices",
        //   videoDisabled: false,
        //   clickbyclickDisabled: false,
        //   liveHostedDisabled: false,
        //   productDemoVideoDisabled: true,
        //   title: "Migration Tools & Best Practices",
        //   icon: "https://dreamdemoassets.blob.core.windows.net/nrf/left-nav-icons/click_by_click_icon.png",
        //   arrowIcon: null,
        //   order: 3,
        //   componentId: 6,
        //   showArchDiagram: false,
        //   liveHostedList: [
        //     {
        //       id: 1,
        //       text: "Demo Download",
        //       url: "https://microsoft.sharepoint.com/:u:/t/Demochamp868/ESeqg26qN3hLvLERVwb4_cQBo_Df8wrsVXv1ORT1wDcykw?e=fTYzLc",
        //     },
        //     {
        //       id: 2,
        //       text: "Live Demo Portal",
        //       url: "https://admin.cloudlabs.ai/#/main",
        //     },
        //   ],
        //   componentName: "videoWIthClickByClick",
        //   video: [
        //     {
        //       id: 1,
        //       name: "product1",
        //       thumbnailImage: "",
        //       navigateUrl: "",
        //     },
        //   ],
        //   dropDownMenu: [
        //     {
        //       id: 1,
        //       text: "Migration Tools & Best Practices",
        //       videoPlayurl: "",
        //     },

        //     // {
        //     //   id: 3,
        //     //   text: "Lakehouse Creation",
        //     //   videoPlayurl:
        //     //     "https://ep-default-mediakind-common-demo.eastus.streaming.mediakind.com/b872c8b5-d7d2-4acc-95b6-f14c01f28aca/Lakehouse_Creation_01.ism/manifest(format=m3u8-cmaf)",
        //     // },
        //   ],
        //   componentParameters: [
        //     {
        //       key: "video",
        //       value: "",
        //     },
        //     {
        //       key: "videoName1",
        //       value: "Data Engineering",
        //     },
        //     {
        //       key: "videoName2",
        //       value: "Data Pipelines",
        //     },
        //     {
        //       key: "videoUrl1",
        //       value: "",
        //     },
        //     {
        //       key: "videoUrl2",
        //       value:
        //         "https://ep-default-mediakind-common-demo.eastus.streaming.mediakind.com/e9cf446a-43c8-4823-8cee-2831ba341521/DataEngineeringV01.ism/manifest(format=m3u8-cmaf)",
        //     },
        //     {
        //       key: "clickByClick",
        //       value:
        //         "https://regale.cloud/microsoft/play/3655/microsoft-fabric-individual-sections-for-web-app-embedding-20#/0/0",
        //     },
        //     {
        //       key: "videoType",
        //       value: "clickVideo",
        //     },
        //     {
        //       key: "liveHosted",
        //       value:
        //         "https://microsoft.sharepoint.com/:u:/t/Demochamp868/ESeqg26qN3hLvLERVwb4_cQBo_Df8wrsVXv1ORT1wDcykw?e=fTYzLc",
        //     },
        //     {
        //       key: "productDemoVideo",
        //       value:
        //         "https://microsoft.seismic.com/Link/Content/DCfXJm2DFTMmC842b687QfjQmgfV",
        //     },
        //   ],
        //   video: [
        //     {
        //       id: 1,
        //       name: "product1",
        //       thumbnailImage: "",
        //       navigateUrl: "",
        //     },
        //   ],
        //   externalArrows: [],
        //   personaId: null,
        //   personaName: "Eva",
        //   personaDesignation: "Data Engineer",
        //   personaImageUrl:
        //     "https://openaidemoassets.blob.core.windows.net/personas/Eva.png",
        // },
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

    // {
    //   url: null,
    //   name: "Demo Finale",
    //   order: 5,
    //   icon: "https://dreamdemoassets.blob.core.windows.net/daidemo/post-fabric-icon.png",
    //   arrowIcon: null,
    //   demoSubMenus: [
    //     {
    //       url: "/executive-dashboard-after",
    //       name: "Executive Dashboard - After",
    //       icon: "https://dreamdemoassets.blob.core.windows.net/nrf/left-nav-icons/dashboard_icon.png",
    //       arrowIcon: null,
    //       order: 3,
    //       componentId: 2,
    //       componentName: "power bi report",
    //       componentParameters: [
    //         // {
    //         //   key: "reportUrl",
    //         //   value:
    //         //     "https://app.powerbi.com/groups/102eb9b7-4dc0-449f-b9cb-e1b9432d00cd/reports/0a875433-9d0a-4806-83de-3cd51f91666b/ReportSection68cb8066934630a72b53?experience=power-bi&clientSideAuth=0",
    //         // },
    //         {
    //           id: 303,
    //           key: "url",
    //           value:
    //             "https://app.powerbi.com/groups/644a4412-d11e-4c52-b984-e6f88ba57eca/reports/96b223c6-0cd2-464b-9c79-954f27ff2d37/9f72400e8d8a6c59b4a1?experience=power-bi",
    //         },
    //       ],
    //       externalArrows: [],
    //       personaId: null,
    //       personaName: "April",
    //       personaDesignation: "Chief Executive Officer",
    //       personaImageUrl:
    //         "https://openaidemoassets.blob.core.windows.net/personas/April.png",
    //     },
    //     {
    //       url: "/finale-video",
    //       name: "Finale Video",
    //       title: "Finale Video",
    //       icon: "https://dreamdemoassets.blob.core.windows.net/nrf/left-nav-icons/video_2_icon.png",
    //       arrowIcon: null,
    //       order: 4,
    //       componentId: 4,
    //       componentName: "Video",
    //       componentParameters: [
    //         {
    //           key: "url",
    //           value:
    //             // "https://mediasvcprodhealthcare-usw22.streaming.media.azure.net/8ae7b990-b99a-4264-8ad5-f30a4ded2ba5/Fabcon_Finale_V05.ism/manifest",
    //             "https://ep-default-mediakind-common-demo.eastus.streaming.mediakind.com/478f2de7-60f4-458f-bfbb-0c4cce74acee/MCFRFinalevideowithmusic _V05_Jo.ism/manifest(format=m3u8-cmaf)",
    //         },
    //       ],
    //       externalArrows: [],
    //       personaId: null,
    //       personaName: "April",
    //       personaDesignation: "Chief Executive Officer",
    //       personaImageUrl:
    //         "https://openaidemoassets.blob.core.windows.net/personas/April.png",
    //     },
    //     {
    //       id: 144,
    //       url: "/wip",
    //       name: "wip​",
    //       icon: "https://dreamdemoassets.blob.core.windows.net/daidemo/retail_arch_icon.png",
    //       arrowIcon: "",
    //       order: 1,
    //       componentId: 3,
    //       componentName: "Image",
    //       componentParameters: [
    //         {
    //           id: 303,
    //           key: "url",
    //           value:
    //             "https://dreamdemoassets.blob.core.windows.net/nrf/wip.png",
    //         },
    //       ],
    //       externalArrows: [],
    //       personaId: 3,
    //       personaName: "Rupesh",
    //       personaDesignation: "Chief Data Officer",
    //       personaImageUrl:
    //         "https://openaidemoassets.blob.core.windows.net/personas/Rupesh.png",
    //     },
    //   ],
    //   componentParameters: [],
    //   externalArrows: [],
    //   componentId: null,
    //   componentName: null,
    //   personaId: null,
    //   personaName: "April",
    //   personaDesignation: "Chief Executive Officer",
    //   personaImageUrl:
    //     "https://openaidemoassets.blob.core.windows.net/personas/April.png",
    // },
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
