import { createSlice } from "@reduxjs/toolkit";
import type { PayloadAction } from "@reduxjs/toolkit";
import { PageType } from "types";
import { Message } from "@progress/kendo-react-conversational-ui";

interface Demo {
  chat: boolean;
  shopping: boolean;
  campaign: boolean;
}

// Define a type for the slice state
interface ConfigState {
  pageType: PageType;
  pageTitle: string;
  persona: string;
  timeline: string;
  selectedButtonId: number | null;
  showDefaultLooks: boolean;
  shoppingGender: string;
  shoppingStyle: string;
  messages: Message[];
  avatar: string;
  name: string;
  selectedDemos: Demo;
  fileName: string;
  customerId: number;
  sessionId: number | null;
  churnResult: number;
  hideTooltips: boolean;
  customerDetails: any;
  customerReview: string;
  email: any;
  question: string;
  allowCallInProgress: boolean;
  notificationCount: number;
  reImaginedDemoComplete: boolean;
  reImaginedScalingDemoComplete: boolean;
  ActiveTileGlobally: string;
  ActiveTileNumber: string;
  showPopup: boolean;
  sideBarMenu: any;
  sideBarMenuExpanded: boolean;
  demoMenus: any;
  solutionPlayGlobally: string;
  previousTileGlobally: string;
  switchOn: boolean;
  solutionPlay: string;
  defaultLandingPage: boolean;
  childNodes: any;
  cardSelected: string;
  demoFlowSelected: string;
  currentTile: string;
  personaID: string;
  useCaseID: string;
  showAIPersona: boolean;
  isLevel1FlowOn: boolean;
  customerSelectionDetails: any;
  selectedTileId: any;
  heldProducts: any;
  holdCount: number;
}

// Define the initial state using that type
const initialState: ConfigState = {
  customerSelectionDetails: {
    id: "po4",

    personaID: "C004",
    name: "Liam Williams",
    PersonaImg: "LiamWilliamsV1",
    cardType: "",
    age: "35 Years",
    city: "New York City",
    jobTime: "Full-Time Employee",
    position: "Senior Manager, Operations",
    annualIncome: "$150,000",
    debtToIncomeRatio: "15%",
    creditScore: "780",
    risk_appetite: "Conservative",
    assets: "$500,000",
    savingGoals: "Retirement",
    recommendedCardTitle: "Elite Rewards Plus",
    recommendedCardTitle2: "Travel Plus",
    services1:
      "https://dreamdemoassets.blob.core.windows.net/openai/SavingsAccount.png",
    services2:
      "https://dreamdemoassets.blob.core.windows.net/openai/Checkingaccountv2.png",
    services3:
      "https://dreamdemoassets.blob.core.windows.net/openai/creditCardImage.png",
    services4:
      "https://dreamdemoassets.blob.core.windows.net/openai/Mortgage.png",
    services5:
      "https://dreamdemoassets.blob.core.windows.net/openai/investmentAccoutnColorImage.png",
    services6:
      "https://dreamdemoassets.blob.core.windows.net/openai/studentLoanImage.png",
    services7:
      "https://dreamdemoassets.blob.core.windows.net/openai/AutoLoan.png",
    services8:
      "https://dreamdemoassets.blob.core.windows.net/openai/noneImage.png",
    colorImages:
      "https://dreamdemoassets.blob.core.windows.net/openai/investmentAccoutnColorImage.png",
    CCDetailsCard: "cc4",
    CCDetailsImageURL:
      "https://staidemodev.blob.core.windows.net/aidw-configurable-retail-images/elite_rewards_plus.png",
    CCDetailsId: "WG-PR-201",
    CCDetailsImageURL2:
      "https://staidemodev.blob.core.windows.net/aidw-configurable-retail-images/travel_plus.jfif",
    CCDetailsId2: "WG-TD-101",
    CCDetailsAnnualFee: "$550",
    CCDetailsPunchLine: "Experience exclusivity with Elite Rewards Plus!",
    CCDetailsPunchLine2: "Earn as you roam with Travel Plus!",
    CCDetailsRewards: "2 points per $1 on travel and dining",
    apr: "14.99%",
    apr2: "18.99%",

    annualIncome2: "$85,000",
    CCDetailsAnnualFee2: "$0",
    debtToIncomeRatio2: "23%",
    creditScore2: "730",
    description:
      "Earn 75,000 online bonus points after spending $5,000 in the first 90 days. Earn 2 points for every $1 spent on travel and dining.",
    description2:
      "Earn 25,000 online bonus points after spending $1,000 in the first 90 days. Earn unlimited 1.5 points for every $1 spent on all purchases.",
    CCDetailsRewards2: "1.5 points per $1 on all purchases",
    cardDetails: {
      InvestingSolutions: [
        {
          product_code: "OM-401",
          name: "Contoso Leaf Blower",
          type: "Investing Solutions",
          fees: "0.50% advisory fee",
          accountMinimun: "$1,000+",
          TargetAudience: "Socially responsible investors",
          description:
            " Lightweight, battery-powered blower ideal for clearing leaves and debris",
          imageURL:
            "https://dreamdemoassets.blob.core.windows.net/herodemos/ContosoLeafBlowerV1.png",
          punchLine:
            "Lightweight, battery-powered blower ideal for clearing leaves and debris",
        },
        {
          product_code: "OM-402",
          name: "Weather Guard Deck Sealer",
          type: "Investing Solutions",
          fees: "Custom fees based on assets",
          accountMinimun: "$100,000+",
          TargetAudience: "High-net-worth individuals",
          description:
            "Long-lasting wood sealant that protects outdoor surfaces from moisture and sun damage ",
          imageURL:
            "https://dreamdemoassets.blob.core.windows.net/herodemos/WeatherGuardDeckSealerV1.png",
          punchLine:
            "Long-lasting wood sealant that protects outdoor surfaces from moisture and sun damage ",
        },
        {
          product_code: "OM-403",
          name: "Quick Trim Hedge Cutter",
          type: "Investing Solutions",
          fees: "Varies by account type",
          accountMinimun: "$0 for most accounts",
          TargetAudience: "Retirement savers",
          description:
            "Cordless trimmer with adjustable blades for clean, precise garden shaping",
          imageURL:
            "https://dreamdemoassets.blob.core.windows.net/herodemos/QuicktrimHedgeCutterV1.png",
          punchLine:
            "Cordless trimmer with adjustable blades for clean, precise garden shaping.",
        },
      ],
      SavingsAccount: [],
      Credit: [
        {
          product_code: "SA-401",
          name: "Measure Mate Pro",
          type: "Certificates of Deposit (CDs)",
          description:
            "AI-powered digital measuring tool for accurate cuts and layouts.",
          imageURL:
            "https://dreamdemoassets.blob.core.windows.net/herodemos/MeasureMateProV1.png",
          punchLine:
            "AI-powered digital measuring tool for accurate cuts and layouts.",
          minimumDeposite: "$100,000 ",
          earlyWithdrawalPenalty: "Yes, higher than standard CDs",
          apy_range: "0.10% - 3.50%",
        },
        {
          product_code: "SA-402",
          name: "Project Planner AR",
          type: "Certificates of Deposit (CDs)",
          description:
            "Augmented reality app to visualize materials and placements in your space.",
          imageURL:
            "https://dreamdemoassets.blob.core.windows.net/herodemos/ProjectPlannerARV1.png",
          punchLine:
            "Augmented reality app to visualize materials and placements in your space.",
          minimumDeposite: "$5,000",
          earlyWithdrawalPenalty: "Yes, except for rate change",
          apy_range: "0.50% - 3.00%",
        },
        {
          product_code: "SA-404",
          name: "Contoso Build Cam",
          type: "Certificates of Deposit (CDs)",
          description:
            "Time-lapse camera to document and review project progress.",
          imageURL:
            "https://dreamdemoassets.blob.core.windows.net/herodemos/ContosoBuildCamV1.png",
          punchLine: "Promotional CD with high short-term yield",
          minimumDeposite: "$10,000",
          earlyWithdrawalPenalty:
            "Time-lapse camera to document and review project progress.",
          apy_range: "Up to 4.00%",
        },
      ],
      CDs: [
        {
          product_code: "AF-601",
          name: "Smart Shelf AI Monitor",
          type: "Credit",
          annualFess: "$75 ",
          card_apr: "17.49%",
          rewards:
            "3% cashback on sustainable purchases like EV charging and renewable energy",

          description:
            "Detects low stock in real time to trigger automatic restocking alerts.",
          imageURL:
            "https://dreamdemoassets.blob.core.windows.net/herodemos/SmartShelfAIMoniV1.png",
          punchLine:
            "Detects low stock in real time to trigger automatic restocking alerts",
        },
        {
          product_code: "AF-602",
          name: " Contoso Express Locker",
          type: "Credit",
          annualFess: "$0",
          card_apr: "16.99%",
          rewards: "1.5% cashback on groceries and gas, 1% on other purchases",
          description:
            "Self-service pickup station for flexible, after-hours order collection ",
          imageURL:
            "https://dreamdemoassets.blob.core.windows.net/herodemos/ContosoExpressLockerV1.png",
          punchLine:
            "Self-service pickup station for flexible, after-hours order collection",
        },
        {
          product_code: "OG-504",
          name: "Rain Save Irrigation System",
          type: "Credit",
          annualFess: "$550",
          card_apr: "23.99%",
          rewards: "2 points per dollar on luxury purchases, VIP experiences",

          description:
            "AI-automated watering system that adjusts based on weather data",
          imageURL:
            "https://dreamdemoassets.blob.core.windows.net/herodemos/RainSaveIrrigationSystemV1.png",
          punchLine:
            "AI-automated watering system that adjusts based on weather data.",
        },
      ],
      CheckingAccounts: [],
      HomeLoansMortgages: [],
      AutoLoans: [],
    },
    investingReson: "Recommended solutions for seasonal upkeep",
    cdsReason: "Ensure product access and service reliability.",
    creaditReason: "Enhance your project outcomes with AI-guided precision.",
  },
  holdCount: 0,
  showAIPersona: false,
  isLevel1FlowOn: false,
  personaID: "nl1-1",
  useCaseID: "nl2-1",
  currentTile: "All Personas",
  pageType: PageType.LandingPage,
  pageTitle: "Landing Page",
  persona: "",
  timeline: "",
  shoppingGender: "female",
  shoppingStyle: "casual",
  selectedButtonId: null,
  showDefaultLooks: false,
  messages: [],
  avatar: "asian_female",
  name: "Sarah Ali",
  fileName: "",
  sessionId: null,
  customerId: 50482,
  hideTooltips: false,
  demoFlowSelected: "EndToEnd",
  selectedDemos: {
    chat: false,
    campaign: false,
    shopping: false,
  },
  churnResult: 0,
  customerDetails: {},
  customerReview: "",
  email: null,
  question: "",
  allowCallInProgress: false,
  notificationCount: 0,
  reImaginedDemoComplete: false,
  ActiveTileGlobally: "",
  ActiveTileNumber: "",
  reImaginedScalingDemoComplete: false,
  showPopup: false,
  sideBarMenu: null,
  sideBarMenuExpanded: false,
  demoMenus: [],
  solutionPlayGlobally: "",
  previousTileGlobally: "",
  switchOn: false,
  solutionPlay: "",
  defaultLandingPage: false,
  childNodes: "",
  cardSelected: "",
  selectedTileId: "",
  heldProducts: [],
};

export const configSlice = createSlice({
  name: "persona",
  // `createSlice` will infer the state type from the `initialState` argument
  initialState,
  reducers: {
    // Use the PayloadAction type to declare the contents of `action.payload`
    setPageTitle: (state, action: PayloadAction<string>) => {
      state.pageTitle = action.payload;
    },
    setCustomerSelectionDetails: (state, action) => {
      state.customerSelectionDetails = action.payload;
    },
    setPersonaID: (state, action: PayloadAction<string>) => {
      state.personaID = action.payload;
    },
    setshowAIPersona: (state, action: PayloadAction<boolean>) => {
      state.showAIPersona = action.payload;
    },
    setIsLevel1FlowOn: (state, action: PayloadAction<boolean>) => {
      state.isLevel1FlowOn = action.payload;
    },
    setSelectedTileId: (state, action: PayloadAction<any>) => {
      state.selectedTileId = action.payload;
    },
    setUseCaseID: (state, action: PayloadAction<string>) => {
      state.useCaseID = action.payload;
    },
    setPageType: (state, action: PayloadAction<PageType>) => {
      state.pageType = action.payload;
    },
    setPersona: (state, action: PayloadAction<string>) => {
      state.persona = action.payload;
    },
    setTimeline: (state, action: PayloadAction<string>) => {
      state.timeline = action.payload;
    },
    setShoppingGender: (state, action: PayloadAction<string>) => {
      state.shoppingGender = action.payload;
    },
    setShoppingStyle: (state, action) => {
      state.shoppingStyle = action.payload;
    },

    setSelectedButtonId: (state, action) => {
      state.selectedButtonId = action.payload;
    },

    setFileName: (state, action) => {
      state.fileName = action.payload;
    },
    setShowDefaultLooks: (state, action) => {
      state.showDefaultLooks = action.payload;
    },
    setMessages: (state, action: PayloadAction<Message[]>) => {
      state.messages = action.payload;
    },
    setAvatar: (state, action: PayloadAction<string>) => {
      state.avatar = action.payload;
    },
    setName: (state, action: PayloadAction<string>) => {
      state.name = action.payload;
    },
    setSessionId: (state, action: PayloadAction<number>) => {
      state.sessionId = action.payload;
    },
    setSelectedDemos: (state, action: PayloadAction<Demo>) => {
      state.selectedDemos = action.payload;
    },
    setCustomerId: (state, action: PayloadAction<number>) => {
      state.customerId = action.payload;
    },
    setHideTooltips: (state, action) => {
      state.hideTooltips = action.payload;
    },

    setChurnResult: (state, action) => {
      state.churnResult = action.payload;
    },
    setCurrentTile: (state, action) => {
      state.currentTile = action.payload;
    },
    setCustomerDetails: (state, action) => {
      state.customerDetails = action.payload;
    },
    setCustomerReview: (state, action) => {
      state.customerReview = action.payload;
    },
    setEmail: (state, action) => {
      state.email = action.payload;
    },
    setHoldCount: (state, action) => {
      state.holdCount = action.payload;
    },
    setSelectedQuestion: (state, action) => {
      state.question = action.payload;
    },
    setAllowCallInProgress: (state, action) => {
      state.allowCallInProgress = action.payload;
    },
    setNotificationCount: (state) => {
      state.notificationCount = state.notificationCount + 1;
    },
    setReImaginedDemoComplete: (state, action: PayloadAction<boolean>) => {
      state.reImaginedDemoComplete = action.payload;
    },
    setReImaginedScalingDemoComplete: (
      state,
      action: PayloadAction<boolean>
    ) => {
      state.reImaginedScalingDemoComplete = action.payload;
    },
    setActiveTileGlobally: (state, action) => {
      state.ActiveTileGlobally = action.payload;
    },
    setActiveTileNumber: (state, action) => {
      state.ActiveTileNumber = action.payload;
    },
    setShowPopup: (state, action) => {
      state.showPopup = action.payload;
    },
    setSideBarCurrentItemMenu: (state, action) => {
      state.sideBarMenu = action.payload;
    },
    setSideBarMenunextExpanded: (state, action) => {
      state.sideBarMenuExpanded = action.payload;
    },
    setDemoMenus(state, action) {
      state.demoMenus = action.payload;
    },
    setSolutionPlayGlobally(state, action) {
      state.solutionPlayGlobally = action.payload;
    },
    setPreviousTileGlobally(state, action) {
      state.previousTileGlobally = action.payload;
    },
    setSwitchOn: (state, action) => {
      state.switchOn = action.payload;
    },
    setSolutionPlay: (state, action) => {
      state.solutionPlay = action.payload;
    },
    setDefaultLandingPage: (state, action) => {
      state.defaultLandingPage = action.payload;
    },
    setChildNodes: (state, action) => {
      state.childNodes = action.payload;
    },
    setCardSelected: (state, action) => {
      state.cardSelected = action.payload;
    },
    setDemoFlowSelected: (state, action) => {
      state.demoFlowSelected = action.payload;
    },
    setHeldCard(state, action) {
      state.heldProducts = action.payload;
    },
  },
});

export const {
  setCustomerSelectionDetails,
  setSelectedTileId,
  setPersonaID,
  setUseCaseID,
  setPageType,
  setPageTitle,
  setshowAIPersona,
  setPersona,
  setTimeline,
  setSelectedButtonId,
  setShoppingGender,
  setShoppingStyle,
  setShowDefaultLooks,
  setMessages,
  setCurrentTile,
  setAvatar,
  setName,
  setFileName,
  setSessionId,
  setCustomerId,
  setHideTooltips,
  setChurnResult,
  setCustomerDetails,
  setCustomerReview,
  setEmail,
  setHoldCount,
  setSelectedQuestion,
  setAllowCallInProgress,
  setSelectedDemos,
  setNotificationCount,
  setReImaginedDemoComplete,
  setReImaginedScalingDemoComplete,
  setActiveTileGlobally,
  setActiveTileNumber,
  setShowPopup,
  setSideBarCurrentItemMenu,
  setSideBarMenunextExpanded,
  setDemoMenus,
  setSolutionPlayGlobally,
  setPreviousTileGlobally,
  setSwitchOn,
  setSolutionPlay,
  setDefaultLandingPage,
  setChildNodes,
  setCardSelected,
  setDemoFlowSelected,
  setHeldCard,
  setIsLevel1FlowOn,
} = configSlice.actions;

export default configSlice.reducer;
