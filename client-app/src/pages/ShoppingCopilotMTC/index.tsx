import { useCallback, useEffect, useRef, useState } from "react";
import styles from "./styles.module.scss";
import {
  Action,
  Chat,
  ChatMessageBoxProps,
  ChatMessageSendEvent,
  Message,
  User,
} from "@progress/kendo-react-conversational-ui";
import axios from "axios";
import {
  AddCircle32Filled,
  Camera28Filled,
  Dismiss24Regular,
  Mic28Filled,
  Video28Filled,
  SubtractCircle32Filled,
  Speaker224Filled,
  SpeakerMute24Filled,
} from "@fluentui/react-icons";
import { useMic } from "hooks/useMic";

import { Answer, Popup } from "components";
import { Button } from "@progress/kendo-react-buttons";
import ImageUploading, { ImageListType } from "react-images-uploading";
import { IconButton } from "@fluentui/react";
import { useAppDispatch, useAppSelector } from "hooks";
import {
  setHeldCard,
  setHoldCount,
  setSelectedButtonId,
  setShowDefaultLooks,
} from "store";
import Slider from "react-slick";
import { useMsal } from "@azure/msal-react";
import { INITIAL_PRODUCTS, WARDROBE_PRODUCTS } from "./Constants";
import { PageType } from "types";
import {
  TabStrip,
  TabStripSelectEventArguments,
  TabStripTab,
} from "@progress/kendo-react-layout";
import React from "react";
import Webcam from "react-webcam";
import { Architecture, CartIcon } from "assets";
import Fridge from "../../assets/images/silver-refrigerator-white-background-urban-energy-yankeecore-style.jpg";
import Grill from "../../assets/images/stainless-steel-grill-with-word-grill-it.jpg";
import OrganizedCabinet from "../../assets/images/organized-cabinet-home.png";
import PaintBrush from "../../assets/images/paint-brushes-paint-background.jpg";
import Paint from "../../assets/images/spilled-colourful-liquid-from-bucket-3d-render-isolated-png-background.jpg";
import Drill from "../../assets/images/drill-machine-white-background.png";
import Furniture from "../../assets/images/grey-comfortable-armchair-isolated-white-background.png";
import potioFurniture from "../../assets/images/398700090_bb6ccc01-b117-42e2-a288-649982040cb9.png";
import bannerContainder from "../../assets/images/Banner-Container.png";
import frostedBlue from "../../assets/images/frosted-blue.png";
import whisperingBlue from "../../assets/images/whispering-blue.png";

import Garden from "../../assets/images/red-anthurium-plant-gray-pot (1).png";
import CrossIcon from "../../assets/images/cross-icon.png";
import { product } from "ramda";
import AddToCart from "assets/AddToCart";
import AddToCartHoldIcon from "assets/AddToCartHoldIcon";

const categories = [
  {
    label: "Appliances",
    img: "https://dreamdemoassets.blob.core.windows.net/herodemos/silver-refrigerator-white-background-urban-energy-yankeecore-style.png",
  },
  {
    label: "Grills",
    img: "https://dreamdemoassets.blob.core.windows.net/herodemos/stainless-steel-grill-with-word-grill-it.png",
  },
  { label: "Storage & Organization", img: OrganizedCabinet },
  {
    label: "Paint Accessories",
    img: "https://dreamdemoassets.blob.core.windows.net/herodemos/paint-brushes-paint-background.png",
  },
  {
    label: "Paint",
    img: "https://dreamdemoassets.blob.core.windows.net/herodemos/spilled-colourful-liquid-from-bucket-3d-render-isolated-png-background.png",
  },
  { label: "Tools", img: Drill },
  { label: "Furniture & Decor", img: Furniture },
  { label: "Patio Furniture", img: potioFurniture },
  { label: "Garden Center", img: Garden },
];

const { BlobBaseUrl, SPEECH_REGION, SPEECH_KEY } = window.config;
const COPILOT_API =""
  
const SESSIONS_API =
  ""
const IMAGE_UPLOAD_API =
  ""
const VIDEO_UPLOAD_API =
 ""

const SUGGESTED_ACTIONS: Action[] = [
  // {
  //   type: "reply",
  //   value: "I am an avid shopper, suggest me some cc with high rewards?",
  // },
  {
    type: "reply",
    value:
      "Hi. I want to paint my living room, but I'm not sure what shade I want or how much paint I'll need.",
  },
  {
    type: "reply",
    value:
      "Hello, I need some help with paint for my living room. I haven’t picked out a color or figured out how many gallons I'll need yet.",
  },
  {
    type: "reply",
    value:
      "I’d like to get some paint for my living room. Can you send me some color options and tell me how much paint I'll need?",
  },
];

function convertMessages(inputMessages: Message[]) {
  const convertedMessages = [];
  let currentMessage: any = {};

  for (let i = 0; i < inputMessages.length; i++) {
    const authorId = inputMessages[i].author.id;
    const messageText = inputMessages[i].text;

    if (authorId === "bot") {
      if ("bot" in currentMessage) {
        convertedMessages.push(currentMessage);
        currentMessage = {};
      }
      currentMessage.bot = messageText;
    } else if (authorId === "user") {
      if ("user" in currentMessage) {
        convertedMessages.push(currentMessage);
        currentMessage = {};
      }
      currentMessage.user = messageText;
    }
  }

  if (Object.keys(currentMessage).length > 0) {
    convertedMessages.push(currentMessage);
  }

  return convertedMessages;
}

const NEW_SESSION = {
  sessionId: 0,
  text: "New Chat",
};

export const ShoppingCopilotMTC = () => {
  const {
    shoppingStyle,
    shoppingGender,
    customerDetails,
    showDefaultLooks,
    customerSelectionDetails,
    heldProducts,
    holdCount,
  } = useAppSelector((state) => state.config);

  const dispatch = useAppDispatch();
  const [chatText, setChatText] = useState<any>();
  const [isActive, setIsActive] = useState<boolean>(false);
  const [isActiveSpan2, setIsActiveSpan2] = useState<boolean>(false);
  const [isApply, setIsApply] = useState<boolean>(false);
  const [isSelected, setIsSelected] = useState<any>();
  const [compareAutoData, setCompareAutoData] = useState<any>([]);
  const [compareData, setCompareData] = useState<any>([]);
  const [compareHoldCard, setCompareHoldCard] = useState<any>([]);
  const [creditCardNumber, setCreditCardNumber] = useState<any>([]);
  const [compareCDsData, setCompareCDsData] = useState<any>([]);
  const [imageCheck, setImageCheck] = useState<boolean>(false);
  const [showHoldUI, setShowHoldUI] = useState(false);
  const [remainingTime, setRemainingTime] = useState("");
  // const heldCard = useAppSelector((state) => state.config.heldCard);

  const [compareCheckingAccountsData, setCompareCheckingAccountsData] =
    useState<any>([]);

  const [compareHomeLoansMortgagesData, setCompareHomeLoansMortgagesData] =
    useState<any>([]);
  const [compareInvestingSolutionsData, setCompareInvestingSolutionsData] =
    useState<any>([]);
  const [compareSavingsAccountData, setCompareSavingsSavingsAccountData] =
    useState<any>([]);

  // const [applyCardNumber, setApplyCardNumber] = useState<number>(0);
  const [sessionId, setSessionId] = useState<string>("");
  const [sessions, setSessions] = useState<any[]>([NEW_SESSION]);
  const [selectedSession, setSelectedSession] = useState<any>(NEW_SESSION);
  const { accounts } = useMsal();
  const [notification, setNotification] = useState(null);
  const notificationRef = useRef(null);
  const [products, setProducts] = useState<any>(INITIAL_PRODUCTS);
  const [coraResponse, setCoraResponse] = useState<any>();
  const [isReplaced, setIsReplaced] = useState(false);
  const [backgroundImage, setBackgroundImage] = useState("");
  const [isPressed, setIsPressed] = useState(false);
  const timerRef: any = useRef(null);
  const [showCamera, setShowCamera] = useState(false);
  const [showVideoCamera, setShowVideoCamera] = useState(false);
  const [text] = useState("");
  const anchor = useRef(null);
  const [show, setShow] = useState(false);
  const [showVideo, setShowVideo] = useState(false);
  const [imgSrc, setImgSrc] = useState("");
  const [images] = useState<ImageListType>([]);
  const [actions, setActions] = useState<Action[]>(SUGGESTED_ACTIONS);
  const [cartProducts, setCartProducts] = useState<any[]>([]);
  const [showThoughtProcessPopup, setShowThoughtProcessPopup] = useState(false);
  const [selectionItem, setSelectionItem] = useState<any>({});
  const [showCart, setShowCart] = useState(false);
  const [showWardrobe, setShowWardrobe] = useState(false);
  const [showArchPopup, setShowArchPopup] = useState(false);
  const [showPopArchitecture, setShowPopArchitecture] = useState(false);
  const [hasUploadedImage, setHasUploadedImages] = useState(false);
  const [timeToHold, setTimeToHold] = useState<any>();
  const [wardrobeProducts, setWardrobeProducts] =
    useState<any>(WARDROBE_PRODUCTS);
  const [isMuted, setIsMuted] = useState(true);
  let [addNotify, setAddNotify] = useState(false);
  let [removeNotify, setRemoveNotify] = useState(false);
  const [buttonGlow, setButtonGlow] = useState({
    isProceed: false,
    isChat: true,
  });
  const [showCartUI, setShowCartUI] = useState(false);

 const paints = [
    {
      id: "OM-401",
      title: "Whispering Blue",
      price: 47.99,
      rating: 4.5,
      reviews: 635,
      description:
        "Imagine a gentle breeze carrying the soft hues of a whispering blue, reminiscent of a tranquil sky at dawn.",
      image:
        "https://dreamdemoassets.blob.core.windows.net/herodemos/furniturehardwoodflooragainstbluewallV1.png",
    },
    {
      id: "OM-402",
      title: "Vibrant Sunshine Yellow",
      price: 15.99,
      rating: 4.3,
      reviews: 529,
      description:
        "Imagine a sunshine yellow hue that wraps around you like a warm summer, reminiscent of a serene summer morning.",
      image:
        "https://dreamdemoassets.blob.core.windows.net/herodemos/closeupspraybottle_v1.png",
    },
  ];
  const AUTHORS: User[] = [
    {
      id: "bot",
      name: "Cora",
      avatarUrl:
        "https://dreamdemoassets.blob.core.windows.net/mtc/mtc_bot_icon.png",
    },
    {
      id: "user",
      name: "Customer",
      avatarUrl: `https://dreamdemoassets.blob.core.windows.net/openai/AI_First_Movers_User_Icon.png`,
    },
  ];

  const INITIAL_MESSAGE = [
    {
      author: AUTHORS[0],
      text: `Hi Joe! Excited to help you with your next DIY project. What can I assist you with today?`,
      suggestedActions: SUGGESTED_ACTIONS,
      tokens: 13,
    },
  ];

  const [showPopup, setShowPopup] = useState(true);
  const [messages, setMessages] = useState<any[]>(INITIAL_MESSAGE);
  const [checkTime, setCheckTime] = useState(new Date());
  const [cardImage, setCardImage] = useState(
    "https://dreamdemoassets.blob.core.windows.net/openai/woodgrove_product_page_ui.png"
  );
  const [response, setResponse] = useState(false);
  useEffect(() => {
    if (accounts.length > 0) {
    }
  }, [accounts]);
  // useEffect(() => {
  //   getSessions();
  // }, []);

  useEffect(() => {
    notificationRef.current = notification;
  }, [notification]);
  let selectedLook;
  if (shoppingStyle === "casual" && shoppingGender === "female") {
    selectedLook = "Look 2";
  } else if (shoppingStyle === "formal" && shoppingGender === "female") {
    selectedLook = "Look 1";
  } else if (shoppingStyle === "casual" && shoppingGender === "male") {
    selectedLook = "Look 3";
  } else if (shoppingStyle === "formal" && shoppingGender === "male") {
    selectedLook = "Look 4";
  }

  const onChange = (imageList: ImageListType) => {
    if (imageList.length)
      onImageUpload(imageList[0].file, imageList[0].dataURL);
    setShow(false);
  };

  let popupTitle = " ";

  const [issueToken, setIssueToken] = useState("");
  const [isDelete, setIsDelete] = useState(false);
  useEffect(() => {
    const filteredProducts = Object.keys(products).reduce((acc: any, key) => {
      const [gender, style] = key.split(" ");
      if (gender === shoppingGender && style === shoppingStyle) {
        acc[key] = products[key];
      }
      return acc;
    }, {});
    setIsReplaced(false);
    setProducts(filteredProducts);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [shoppingGender, shoppingStyle]);

  const deleteSession = () => {
    axios
      .post(COPILOT_API, {
        history: convertMessages(messages),
        gender: shoppingGender,
        style: shoppingStyle,
        sessionid: selectedSession?.sessionId,
        retrieve_session: false,
        delete_session: true,
      })
      .then((res) => {
        getSessions();
        setSelectedSession(sessions[0]);
        setMessages(INITIAL_MESSAGE);
      })
      .catch((err) => console.log({ err }))
      .finally(() => setIsDelete(false));
  };

  useEffect(() => {
    // const heldProductStr = localStorage.getItem('heldProducts');
    // const data = heldProductStr ? JSON.parse(heldProductStr) : [];
    // dispatch(setHeldCard(data));
  }, []);

  const generateNewSession = () => {
    const randomNumber =
      Math.floor(Math.random() * (999999 - 100000 + 1)) + 100000;
    setSessionId(randomNumber.toString());
    return {
      sessionId: randomNumber.toString(),
      text: "New Chat",
    };
  };

  const getSessions = () => {
    axios
      .get(SESSIONS_API)
      .then((res) => {
        const newSession = generateNewSession();
        setSessions([
          newSession,
          ...res.data.map((s: any) => ({
            sessionId: s.sessionId,
            text: s.sessionId,
          })),
        ]);
        setSelectedSession(newSession);
      })
      .catch((err) => console.log({ err }));
  };

  const generateToken = () => {
    if (!SPEECH_KEY || !SPEECH_REGION) {
      console.log(
        "Speech service configuration is missing. Please check your SPEECH_KEY and SPEECH_REGION."
      );
      return;
}
    axios
      .post(
        `https://${SPEECH_REGION}.api.cognitive.microsoft.com/sts/v1.0/issueToken`,
        {},
        {
          headers: {
            "Ocp-Apim-Subscription-Key": SPEECH_KEY,
          },
          responseType: "text",
        }
      )
      .then((res) => setIssueToken(res.data))
    .catch((err) => {
        console.log(
          "Failed to get speech token. Please check your Azure Speech credentials."
        );
        console.error(err);
      });
  };

  useEffect(() => {
    if (!issueToken) {
      generateToken();
    }
  }, [issueToken]);
  const generateAudio = (text: string) => {
    const id = +new Date();
    let xml = `<speak version=\'1.0\' xml:lang="en-US">
    <voice xml:id='${id}' xml:lang='en-US' xml:gender='Female' name='en-US-CoraNeural'>${text.replaceAll(
      "&",
      "and"
    )}</voice>
    </speak>`;

    fetch(
      `https://${SPEECH_REGION}.tts.speech.microsoft.com/cognitiveservices/v1`,
      {
        body: xml,
        method: "post",
        headers: {
          "X-Microsoft-OutputFormat": "riff-48khz-16bit-mono-pcm",
          "Content-Type": "application/ssml+xml",
          Authorization: "Bearer " + issueToken,
        },
      }
    )
      .then((response) => {
        if (!response.ok) {
          throw new Error(`HTTP error! Status: ${response.status}`);
        }
        return response.arrayBuffer();
      })
      .then((res) => {
        const audioBlob = new Blob([res], { type: "audio/mp3" });
        const audioUrl = URL.createObjectURL(audioBlob);
        const sampleAudioPlayer: HTMLAudioElement | null =
          document.getElementById("sampleAudioPlayer") as HTMLAudioElement;
        if (sampleAudioPlayer) {
          sampleAudioPlayer.src = audioUrl;
          sampleAudioPlayer.play();
        }
      })
      .catch((err) => {
        generateAudio(text);
      });
  };

  const onDefaultLooksClick = (id: number) => {
    onTextSend(`Look ${id} selected.`);
    dispatch(setShowDefaultLooks(false));
  };

  const onImageUpload = async (file?: File, dataURL?: string) => {
    setImageCheck(true);

    setHasUploadedImages(true);
    const userMessage: Message = {
      author: AUTHORS[1],
      text: "",
      timestamp: new Date(),
      attachments: [
        {
          content: dataURL,
          contentType: "image",
        },
      ],
    };
    setMessages((old) => [
      ...old,
      userMessage,
      { author: AUTHORS[0], typing: true },
    ]);
    const history = convertMessages(messages);

    const formData: any = new FormData();
    formData.append("image", file);
    formData.append("history", JSON.stringify(history));
    formData.append("query", "");
    formData.append("image", "true");

    axios
      .post(COPILOT_API, {
        query: "",
        image: true,
      })
      .then(({ data }) => {
        if (data) {
          if (Object.keys(data.products).length > 0) {
            setResponse(true);
          } else {
            setResponse(false);
          }
          generateAudio(data?.answer);

          setProducts(data.products);
          setCoraResponse(data.products);

          setMessages((old) => {
            const newArray = [
              ...old.slice(0, old.length - 2),
              {
                ...userMessage,
                tokens: data.question_tokens,
              },
              {
                author: AUTHORS[0],
                text: data.answer,
                timestamp: new Date(),
                data_points: data.data_points,
                thoughts: data.thinking,
                tokens: data.answer_tokens,
                suggestedActions: data.suggestions?.map((s: any) => ({
                  type: "reply",
                  value: s,
                })),
              } as Message,
            ];

            return newArray;
          });

          setSessions((old: any) => {
            const arr = old.map((s: any) =>
              s.text === "New Chat"
                ? { sessionId: s.sessionId, text: s.sessionId }
                : s
            );
            const newSession = generateNewSession();

            return [newSession, ...arr];
          });
          setSelectedSession((old: any) => ({
            sessionId: old.sessionId,
            text: old.sessionId,
          }));

          if (data?.show_default_looks) {
            dispatch(setSelectedButtonId(null));
            dispatch(setShowDefaultLooks(true));
          } else {
            dispatch(setShowDefaultLooks(false));
          }
        } else {
        }
        data?.display_msg && setIsChatEnded(true);
        setBackgroundImage(
          data?.background_img?.img?.replaceAll(" ", "%20") ?? ""
        );
        setIsReplaced(true);
        setProducts(data?.products ?? {});
        setCoraResponse(data.products);
        setHasUploadedImages(false);
        // const formattedProducts = Object.values(data?.shopping_cart?.[0])
        //   .flat()
        //   .map((product: any, index) => ({
        //     ...product,
        //     checked: true,
        //     id: index,
        //   }));
        setButtonGlow((old) => ({
          ...old,
          isChat: false,
          isProceed: true,
        }));
        // setCartProducts(formattedProducts ?? []);

        //    if ( data?.answer) {
        //      setMessages((old) => {
        //        const newArray = [
        //          ...old.slice(0, old.length - 1),
        //          {
        //            author: AUTHORS[0],
        //            text: res.answer,
        //            timestamp: new Date(),
        //            data_points:  data?.data_points,
        //            thoughts: res?.thoughts,
        //          },
        //        ];
        //        return newArray;
        //      });
        //    } else {
        //      setMessages((old) => [...old.slice(0, old.length - 1)]);
        //    }
        //    setIsReplaced(true);
        //    setProducts(res?.products ?? {});
        //    setHasUploadedImages(false);
      })
      .catch((e) => console.log(e));
  };

  const onTextSend = (text: string) => {
    onMessageSend(undefined, text);
  };

  const [sttFromMic] = useMic(text, onTextSend);
  const [isChatEnded, setIsChatEnded] = useState(false);

  const onMessageSend = (e?: ChatMessageSendEvent, text?: string) => {
    isChatEnded && setIsChatEnded(false);
    setChatText(e?.message.text);
    const userMessage = {
      author: AUTHORS[1],
      text: text?.trim() ?? e!.message.text?.trim(),
      timestamp: e?.message.timestamp ?? new Date(),
    };
    const filteredSuggestedActions = actions.filter(
      (item) => item.value !== e?.message.text
    );
    setButtonGlow((old) => ({
      ...old,
      isChat: false,
      isProceed: true,
    }));

    setMessages((old) => [
      ...old,
      userMessage,
      { author: AUTHORS[0], typing: true },
    ]);
    const historyMessages = [...messages, userMessage];
    historyMessages.shift();
    axios
      .post(COPILOT_API, {
        // history: [{ user: userMessage.text }],
        // history: convertMessages(historyMessages),
        // persona_id: customerSelectionDetails.personaID,
        query: hasUploadedImage ? "" : e?.message.text, //userMessage.text,
        image: hasUploadedImage,
      })
      .then(({ data }) => {
      
        // data.products && data.products.length > 0
//         data.answer = `{
//     "products": {},
//     "answer": "I can suggest some paint colors\u2014would you be able to tell me a bit about the room or show me a picture?",
//     "thinking": "The customer wants to paint their room and is looking for both shade suggestions and paint sprayer options. Given the size, a 4 to 5 gallon quantity is recommended. To enhance their experience, presenting stylish color options alongside helpful tools like sprayers supports ease and inspiration.",
//     "suggestions": []
// }`
//         data.answer = `
// <h5><b>Room Overview</b></h5>

// <p><b>Primary Use</b>: Relaxing, reading, occasional entertaining</p>
// <p><b>Style</b>: Cozy with a mix of modern and natural textures</p>
// <p><b>Mood Desired</b>: Vibrant but not too bold; earthy or calming tones preferred</p>

// <h5><b>Lighting</b></h5>
// <p><b>Natural Light:</b> Abundant in the morning (east-facing window)</p>
// <p><b>Artificial Light:</b> Floor lamp used in the evening</p>
// <p><b>Curtains:</b> Light gray, semi-sheer</p>

// <h5><b>Walls & Ceiling</b></h5>
// <p><b>Wall Color</b>: Off-white (considering a change)</p>
// <p><b>Decor</b>: Abstract painting (blues and greens) above the couch</p>
// <p><b>Ceiling</b>: Flat, white, with a ceiling fan</p>

// <h5><b>Flooring</b></h5>
// <p><b>Material</b>: Warm brown wood</p>
// <p><b>Rug</b>: Patterned rug under the coffee table</p>
  
// <h5><b>Furniture
// </b>
// </h5>
// <p><b>Main Seating</b>: Beige couch with colorful cushions</p>
// <p><b>Other Furniture</b>: Small desk by the window</p>
// <p><b>Style</b>: Mix of wood, fabric, and some metal</p>

// <h5><b>Plants & Decor</b></h5>
// <p><b>Plants</b>: Several, including hanging plants near the window</p>
// <p><b>Bookshelf</b>: Filled with books and decorative items</p>

// <h5><b>Color Preferences</b></h5>
// <p><b>Likes</b>: Earthy tones (e.g., sage, terracotta), calming colors</p>
// <p><b>Dislikes</b>: Overly bold or dark shades</p>
// <p><b>Transition</b>: Should coordinate with nearby kitchen (white cabinets, green tiles)</p>

// <h5><b>Practical Considerations</b></h5>
// <p><b>Occupants</b>: No pets or kids</p>
// <p><b>Maintenance</b>: Not a major concern</p>

        // `;
        
        data.answer =  `:🛋️ The room is primarily used for relaxing, reading, and occasional entertaining. 
          It has a cozy style that blends modern and natural textures, aiming for a vibrant yet calming
           mood with earthy tones. 💡 Natural light is abundant in the morning thanks to an east-facing window 🌅,
            while a floor lamp provides illumination in the evening 🛋️. Light gray, semi-sheer curtains 🪟
            soften the space. 🎨 The walls are currently off-white (with a possible color change in mind),
            and an abstract painting in blues and greens hangs above the couch 🖼️. The ceiling is flat, white,
             and features a ceiling fan 🌀. 🪵 The flooring is warm brown wood, complemented by a patterned
             rug under the coffee table 🧶. 🪑 Furniture includes a beige couch with colorful cushions,
              a small desk by the window 🧑‍💻, and a mix of wood, fabric, and metal elements. 🪴 Several plants,
               including hanging ones near the window 🌿, add freshness, while a bookshelf filled with books
                and decorative items 📚 enhances the decor. 🎨 Preferred colors include earthy tones like sage and terracotta
                 🌱🧡, avoiding overly bold or dark shades, and the palette is designed to coordinate with a nearby kitchen
                  featuring white cabinets and green tiles 🍽️. 🧹 There are no pets or children in the space,
                  and maintenance is not a major concern 🧽.`

        if (data.products) {
          if (Object.keys(data.products).length > 0) {
            setResponse(true);
          } else {
            setResponse(false);
          }
          generateAudio(data?.answer);

          setProducts(data.products);
          setCoraResponse(data.products);

          setMessages((old) => {
            const newArray = [
              ...old.slice(0, old.length - 2),
              {
                ...userMessage,
                // tokens: data.question_tokens,
              },
              {
                author: AUTHORS[0],
                text: JSON.stringify(data.answer, null, 2),
                timestamp: new Date(),
                // data_points: data.data_points,
                thoughts: data.thinking,
                // tokens: data.answer_tokens,
                suggestedActions: data.suggestions?.map((s: any) => ({
                  type: "reply",
                  value: s,
                })),
              } as Message,
            ];

            return newArray;
          });

          setSessions((old: any) => {
            const arr = old.map((s: any) =>
              s.text === "New Chat"
                ? { sessionId: s.sessionId, text: s.sessionId }
                : s
            );
            const newSession = generateNewSession();

            return [newSession, ...arr];
          });
          setSelectedSession((old: any) => ({
            sessionId: old.sessionId,
            text: old.sessionId,
          }));

          if (data?.show_default_looks) {
            dispatch(setSelectedButtonId(null));
            dispatch(setShowDefaultLooks(true));
          } else {
            dispatch(setShowDefaultLooks(false));
          }
        } else {
        }
        data?.display_msg && setIsChatEnded(true);
        setBackgroundImage(
          data?.background_img?.img?.replaceAll(" ", "%20") ?? ""
        );
        setIsReplaced(true);
        setProducts(data?.products ?? {});
        setCoraResponse(data.products);

        // const formattedProducts = Object.values(data?.shopping_cart?.[0])
        //   .flat()
        //   .map((product: any, index) => ({
        //     ...product,
        //     checked: true,
        //     id: index,
        //   }));
        setButtonGlow((old) => ({
          ...old,
          isChat: false,
          isProceed: true,
        }));
        // setCartProducts(formattedProducts ?? []);
      })
      .catch((e) => {
        console.log(e);
        
        // Fallback data when API fails
        const fallbackData = {
          answer: `:🛋️ The room is primarily used for relaxing, reading, and occasional entertaining. 
          It has a cozy style that blends modern and natural textures, aiming for a vibrant yet calming
           mood with earthy tones. 💡 Natural light is abundant in the morning thanks to an east-facing window 🌅,
            while a floor lamp provides illumination in the evening 🛋️. Light gray, semi-sheer curtains 🪟
            soften the space. 🎨 The walls are currently off-white (with a possible color change in mind),
            and an abstract painting in blues and greens hangs above the couch 🖼️. The ceiling is flat, white,
             and features a ceiling fan 🌀. 🪵 The flooring is warm brown wood, complemented by a patterned
             rug under the coffee table 🧶. 🪑 Furniture includes a beige couch with colorful cushions,
              a small desk by the window 🧑‍💻, and a mix of wood, fabric, and metal elements. 🪴 Several plants,
               including hanging ones near the window 🌿, add freshness, while a bookshelf filled with books
                and decorative items 📚 enhances the decor. 🎨 Preferred colors include earthy tones like sage and terracotta
                 🌱🧡, avoiding overly bold or dark shades, and the palette is designed to coordinate with a nearby kitchen
                  featuring white cabinets and green tiles 🍽️. 🧹 There are no pets or children in the space,
                  and maintenance is not a major concern 🧽.`
//           answer: `
// <h5><b>Room Overview</b></h5>

// <p><b>Primary Use</b>: Relaxing, reading, occasional entertaining</p>
// <p><b>Style</b>: Cozy with a mix of modern and natural textures</p>
// <p><b>Mood Desired</b>: Vibrant but not too bold; earthy or calming tones preferred</p>

// <h5><b>Lighting</b></h5>
// <p><b>Natural Light:</b> Abundant in the morning (east-facing window)</p>
// <p><b>Artificial Light:</b> Floor lamp used in the evening</p>
// <p><b>Curtains:</b> Light gray, semi-sheer</p>

// <h5><b>Walls & Ceiling</b></h5>
// <p><b>Wall Color</b>: Off-white (considering a change)</p>
// <p><b>Decor</b>: Abstract painting (blues and greens) above the couch</p>
// <p><b>Ceiling</b>: Flat, white, with a ceiling fan</p>

// <h5><b>Flooring</b></h5>
// <p><b>Material</b>: Warm brown wood</p>
// <p><b>Rug</b>: Patterned rug under the coffee table</p>
  
// <h5><b>Furniture
// </b>
// </h5>
// <p><b>Main Seating</b>: Beige couch with colorful cushions</p>
// <p><b>Other Furniture</b>: Small desk by the window</p>
// <p><b>Style</b>: Mix of wood, fabric, and some metal</p>

// <h5><b>Plants & Decor</b></h5>
// <p><b>Plants</b>: Several, including hanging plants near the window</p>
// <p><b>Bookshelf</b>: Filled with books and decorative items</p>

// <h5><b>Color Preferences</b></h5>
// <p><b>Likes</b>: Earthy tones (e.g., sage, terracotta), calming colors</p>
// <p><b>Dislikes</b>: Overly bold or dark shades</p>
// <p><b>Transition</b>: Should coordinate with nearby kitchen (white cabinets, green tiles)</p>

// <h5><b>Practical Considerations</b></h5>
// <p><b>Occupants</b>: No pets or kids</p>
// <p><b>Maintenance</b>: Not a major concern</p>

          // `,
          ,
          thinking: "The API failed, showing fallback room analysis data to maintain user experience.",
          products: {},
          suggestions: []
        };

        // Generate audio for fallback answer
        generateAudio(fallbackData.answer);

        // Update messages with fallback data
        setMessages((old) => {
          const newArray = [
            ...old.slice(0, old.length - 2),
            {
              ...userMessage,
            },
            {
              author: AUTHORS[0],
              text: fallbackData.answer,
              timestamp: new Date(),
              thoughts: fallbackData.thinking,
              suggestedActions: fallbackData.suggestions?.map((s: any) => ({
                type: "reply",
                value: s,
              })),
            } as Message,
          ];

          return newArray;
        });

        // Set response state
        setResponse(false);
        setProducts({});
        setCoraResponse({});
        setIsReplaced(true);
        setButtonGlow((old) => ({
          ...old,
          isChat: false,
          isProceed: true,
        }));
      });
  };

  useEffect(() => {
    const element = document.getElementsByClassName(
      "k-message-list k-avatars"
    )?.[0];

    if (element) {
      element.scrollTop = element.scrollHeight;
    }
  }, [messages]);

  const AttachmentTemplate = (props: any) => {
    let attachment = props.item;
    return (
      <div className="k-card k-card-type-rich">
        <div className="k-card-body quoteCard">
          <img
            style={{ maxHeight: "124px" }}
            src={attachment.content}
            draggable={false}
            alt="content"
          />
        </div>
      </div>
    );
  };

  const handleMouseDown = () => {
    setIsPressed(true);
    timerRef.current = setTimeout(() => {
      (sttFromMic as any)();
    }, 1000);
  };

  const handleMouseUp = () => {
    clearTimeout(timerRef.current);
    setIsPressed(false);
  };

  const videoWebCamRef = useRef<Webcam>(null);
  const mediaRecorderRef = useRef<MediaRecorder | null>(null);
  const [capturing, setCapturing] = useState<boolean>(false);
  const [recordedChunks, setRecordedChunks] = useState<any>([]);
  const [selectedCard, setSelectedCard] = useState<any>([]);
  const [selectedApply, setSelectedApply] = useState<any>([]);

  const handleStartCaptureClick = useCallback(() => {
    if (videoWebCamRef.current) {
      setCapturing(true);
      mediaRecorderRef.current = new MediaRecorder(
        videoWebCamRef.current.stream as MediaStream,
        {
          mimeType: "video/webm",
        }
      );
      mediaRecorderRef.current.addEventListener(
        "dataavailable",
        handleDataAvailable
      );
      mediaRecorderRef.current.start();
    }
  }, [videoWebCamRef, setCapturing, mediaRecorderRef]);

  const handleDataAvailable = useCallback(
    ({ data }: { data: any }) => {
      if (data.size > 0) {
        setRecordedChunks((prev: any) => [...prev, data]);
      }
    },
    [setRecordedChunks]
  );

  const handleStopCaptureClick = useCallback(() => {
    if (mediaRecorderRef.current) {
      mediaRecorderRef.current.stop();
      setCapturing(false);
    }
  }, [mediaRecorderRef, setCapturing]);

  function convertBase64ToFile(base64: string, filename: string) {
    const base64WithoutPrefix = base64.split(",")[1];
    const binaryString = window.atob(base64WithoutPrefix);
    const length = binaryString.length;
    const bytes = new Uint8Array(length);

    for (let i = 0; i < length; i++) {
      bytes[i] = binaryString.charCodeAt(i);
    }

    const blob = new Blob([bytes], { type: "application/octet-stream" });
    const file = new File([blob], filename, {
      type: "application/octet-stream",
    });

    return file;
  }

  const webcamRef = useRef<Webcam | null>(null);
  const capture = useCallback(() => {
    const imageSrc = webcamRef?.current?.getScreenshot();
    if (imageSrc) {
      setImgSrc(imageSrc);
    }
  }, [webcamRef]);

  const customMessage = (props: ChatMessageBoxProps) => {
    return (
      <>
        {props.messageInput}
        {props.sendButton}
        <div
          ref={anchor}
          onClick={() => {
            setShow((old) => !old);
            setShowVideo(false);
          }}
        >
          <Camera28Filled style={{ cursor: "pointer" }}></Camera28Filled>
        </div>
        <div
          ref={anchor}
          onClick={() => {
            setShowVideo((old) => !old);
            setShow(false);
          }}
        >
          <Video28Filled style={{ cursor: "pointer" }}></Video28Filled>
        </div>
        <div
          title="Hold to Speak, Please wait for 2-3 seconds while holding down the mic button before you begin to speak."
          onMouseDown={handleMouseDown}
          onMouseUp={handleMouseUp}
          onMouseLeave={handleMouseUp}
          style={{ opacity: !isPressed ? 1 : 0.5 }}
        >
          <Mic28Filled className={styles.mic} />
        </div>
      </>
    );
  };

  const [selectedProduct, setSelectedProduct] = useState<any>(null);

  const chatRef = useRef<Chat | null>(null);

  useEffect(() => {
    const element = document.getElementsByClassName(
      "k-message-list k-avatars"
    )?.[0];
    const spanElement = document.createElement("span");

    spanElement.classList.add(styles.chatEndedMessage);
    spanElement.textContent = "Chat has ended.";

    if (isChatEnded && element) {
      element.scrollTop = element.scrollHeight;
    }
  }, [isChatEnded]);

  const MessageTemplate = (props: any) => {
    return props.item.text ? (
      <div className="k-bubble" key={props.item?.id}>
        {/* {props.item?.thoughts && (
          <div
            className={styles.bulbPositioning}
            style={{
              cursor: "pointer",
              display: "flex",
              justifyContent: "flex-end",
            }}
          >
            <IconButton
              style={{ color: "black" }}
              iconProps={{ iconName: "Lightbulb" }}
              title="Show thought process"
              onClick={() => {
                setSelectionItem(props.item);
                setShowThoughtProcessPopup(true);
              }}
            />
          </div>
        )} */}
        {/* {props.item.text} */}
        <p dangerouslySetInnerHTML={{ __html: props.item.text }}></p>
      </div>
    ) : (
      props.item.video && (
        <div
          className="k-bubble"
          style={{ backgroundColor: "#fff", borderColor: "#fff" }}
          key={props.item?.id}
        >
          <video width={200} controls loop autoPlay src={props.item.video} />
        </div>
      )
    );
  };

  const onToggle = (flag: boolean) => {
    setAddNotify(flag);
    if (flag) {
      setTimeout(() => {
        setAddNotify(false);
      }, 2000);
    }
  };
  const onRemoveToggle = (flag: boolean) => {
    setRemoveNotify(flag);
    if (flag) {
      setTimeout(() => {
        setRemoveNotify(false);
      }, 2000);
    }
  };

  const [selectedFile, setSelectedFile] = useState(null);
  const fileInputRef: any = useRef(null);

  const handleFileChange = (event: any) => {
    const file = event.target.files[0];

    const validVideoFormats = /\.(mp4|mov|mkv|avi|flv|webm)$/i;

    if (file && !validVideoFormats.test(file.name)) {
      alert("Please upload a valid video format.");
      return;
    }

    setSelectedFile(file);
    handleUpload(file);
  };
  const handleUpload = (file: any) => {
    setShowVideo(false);

    if (file) {
      const userMessage: any = {
        author: AUTHORS[1],
        text: "",
        timestamp: new Date(),
        video: URL.createObjectURL(file),
      };
      setMessages((old) => [
        ...old,
        userMessage,
        { author: AUTHORS[0], typing: true },
      ]);

      const formData: any = new FormData();
      formData.append("video", file);
      axios.post(VIDEO_UPLOAD_API, formData).then((res: any) => {
        if (res?.data?.answer) {
          setMessages((old) => {
            const newArray = [
              ...old.slice(0, old.length - 1),
              {
                author: AUTHORS[0],
                text: res.data?.answer,
                timestamp: new Date(),
                data_points: res?.data?.data_points,
                thoughts: res.data?.thoughts,
              },
            ];
            return newArray;
          });
        } else {
          setMessages((old) => [...old.slice(0, old.length - 1)]);
        }
        setIsReplaced(true);
        setProducts(res?.data?.products ?? {});
      });
      setSelectedFile(null);
    } else {
      alert("Please select a file to upload.");
    }
  };

  const handleClick = () => {
    fileInputRef.current.click();
  };

  const getVideoLink = () => {
    const blob = new Blob(recordedChunks, {
      type: "video/webm",
    });
    const url = URL.createObjectURL(blob);
    return url;
  };

  const [selectedProducts, setSelectedProducts] = useState<{
    [id: string]: number;
  }>({});

  const handleSpanText1 = (data: any) => {
    // setSelectedProducts((prevSelected: any) =>
    //   prevSelected.includes(data.id)
    //     ? prevSelected.filter((productCode: any) => productCode !== data.id)
    //     : [...prevSelected, data.id]
    // );

    setSelectedProducts((prev) => {
      const currentQty = prev[data.id] || 0;
      return {
        ...prev,
        [data.id]: currentQty + 1,
      };
    });
    const { id, type } = data; // Use id as the unique identifier
    const isCardSelected = compareData.some((item: any) => item.id === id);
    if (isCardSelected) {
      // Remove the card from compareData
      setCompareData((prev: any) => prev.filter((item: any) => item.id !== id));
      // setApplyCardNumber(applyCardNumber - 1);
    } else {
      // Add the card to compareData
      setCompareData((prev: any) => [...prev, data]);
      // setApplyCardNumber(applyCardNumber + 1);
    }
  };

  const handleSpanText2 = (data: any) => {
    setIsSelected(data.id);

    // setIsActiveSpan2(true);
    if (!selectedApply.includes(data.id)) {
      setSelectedApply((prevSelected: any) => [...prevSelected, data.id]);
    }
    // setIsApply(true);
  };
  const [showCompareCard, setshowCompareCard] = useState(false);
  const handleShowCompareCard = () => {
    // setshowCompareCard(true);
    // setShowPopup(false);
  };
  const handleResponseData = (product: any) => {
    setIsSelected(product.id);
    setIsActive(true);
    // setApplyCardNumber(applyCardNumber + 1);
    compareData.push(product);

    if (!selectedCard.includes(product.id)) {
      setSelectedCard((prevSelected: any) => [...prevSelected, product.id]);
    }
  };
  const handleNavigation = () => {
    setshowCompareCard(false);
    setShowPopup(true);
  };

  const [selectedTap, setSelectedTap] = useState(0);
  const handleSelect = (e: TabStripSelectEventArguments) => {
    setSelectedTap(e.selected);
  };

  const onRemoveItem = (data: any) => {
    setSelectedProducts((prev: any) => {
      const { [data.id]: _, ...rest } = prev;
      return rest;
    });
  };

  const handleDecrement = (product: any) => {
    console.log("hello");
    setSelectedProducts((prev) => {
      const currentQty = prev[product.id] || 0;
      if (currentQty <= 1) {
        const { [product.id]: _, ...rest } = prev;
        return rest;
      }
      return {
        ...prev,
        [product.id]: currentQty - 1,
      };
    });
  };


  function calculateRemainingTime(heldAt: any, cardType: any) {
    const heldTime = new Date(heldAt).getTime();
    const now = new Date().getTime();
    let diffMs;

    if (cardType === "Paint Shade") {
      diffMs = 24 * 60 * 60 * 1000 - (now - heldTime);
    } else {
      diffMs = 3 * 60 * 60 * 1000 - (now - heldTime);
    }

    if (diffMs <= 0) return "Expired";

    console.log("diffMs", diffMs);

    const hours = Math.floor(diffMs / (1000 * 60 * 60));
    const minutes = Math.floor((diffMs % (1000 * 60 * 60)) / (1000 * 60));
    const seconds = Math.floor((diffMs % (1000 * 60)) / 1000);

    return `${hours}h ${minutes}m ${seconds}s`;
  }

  const applyCardNumber = Object.values(selectedProducts).reduce(
    (sum, qty) => sum + qty,
    0
  );

  const handleOnHold = (card: any) => {
    // dispatch(setHoldCount(holdCount + 1));
    // const heldProduct = {
    //   ...product,
    //   quantity: selectedProducts[product.id] || 1,
    //   heldAt: new Date().toISOString(),
    // };

    // const existingHeld = [...heldProducts]; // from useAppSelector
    // const isAlreadyHeld = existingHeld.some((p) => p.id === heldProduct.id);
    // if (!isAlreadyHeld) {
    //   const updatedHeld = [...existingHeld, heldProduct];
    //   dispatch(setHeldCard(updatedHeld));
    // }
    const { id } = card;
    const isCardSelected = compareHoldCard.some((item: any) => item.id === id);

    if (isCardSelected) {
      // setCompareHoldCard((prev: any) =>
      //   prev.filter((item: any) => item.id !== id)
      // );
      dispatch(setHeldCard(compareHoldCard));
      // dispatch(setHoldCount(compareHoldCard.length));
      dispatch(setHoldCount(holdCount + 1));
    } else {
      setCompareHoldCard((prev: any) => [...prev, card]);
      dispatch(setHeldCard(compareHoldCard));
      dispatch(setHoldCount(holdCount + 1));
      // dispatch(setHoldCount(compareHoldCard.length));
    }
  };

  useEffect(() => {
    if (coraResponse && coraResponse["Paint Sprayers"]?.length > 0) {
      setShowCartUI(false);
    }
  }, [coraResponse]);


  return (
    <div className={styles.container}>
      <div className={styles.subContainer}>
        {showHoldUI ? (
          <div className={styles.responseImageContainer}>
            <div className={styles.responseDetails}>
              <div className={styles.responseCards1}>
                {heldProducts.length > 0 ? (
                  <div className={styles.familyCreditCardContainer}>
                    <div className={styles.viewCartHeader}>
                      <p className={styles.yourCart}>Your Cart</p>
                      <div className={styles.resumeshopping}>
                        <p
                          className={styles.shopping}
                          onClick={() => setShowHoldUI(false)}
                        >
                          Resume Shopping
                        </p>
                        <p className={styles.checkout}>Checkout</p>
                      </div>
                    </div>

                    <div className={styles.threeCards}>
                      {heldProducts.map(
                        (product: any) => (
                          console.log("product inside the hold", product),
                          (
                            <div
                              className={styles.cardDetails}
                              key={product.id}
                            >
                              <div className={styles.creditCardHeader}>
                                <img
                                  className={styles.cardImage}
                                  src={product.imageURL}
                                  alt={product.id}
                                />
                              </div>
                              <div className={styles.creditCardInfo}>
                                <p className={styles.cardName}>
                                  <span>{product.name}</span>
                                  <span className={styles.CPrice}>
                                    {product.price}
                                  </span>
                                </p>
                                <p className={styles.productCode}>
                                  {product.id}
                                </p>
                                <p className={styles.punchLinewarp}>
                                  {product.description}
                                </p>
                                <p className={styles.cardName}>
                                  <span>
                                    Hold Qty :{" "}
                                    <span className={styles.cartQuantity}>
                                      {product.quantity || 1}
                                    </span>
                                  </span>
                                  <span>
                                    Time :{" "}
                                    <span className={styles.cartQuantity}>
                                      {calculateRemainingTime(
                                        checkTime,
                                        product.type
                                      )}
                                      {/* {
                                     {calculateRemainingTime(checkTime,product.type)}
                                  } */}
                                    </span>
                                  </span>
                                </p>
                              </div>
                            </div>
                          )
                        )
                      )}
                    </div>
                  </div>
                ) : (
                  <p>No products on hold.</p>
                )}
              </div>
            </div>
          </div>
        ) : response ? (
          <div className={styles.responseImageContainer}>
            <div className={styles.responseDetails}>
              <div className={styles.responseCards1}>
                <>
                  {" "}
                  {!showCartUI ? (
                    <div className={styles.familyCreditCardContainer}>
                      <>
                        {coraResponse["Paint Shades"]?.length > 0 ? (
                          <div className={styles.mainCard}>
                            <div className={styles.cardType}>
                              <p>
                                <span>Paint Shades</span>{" "}
                              </p>
                              <p className={styles.cart}>
                                <CartIcon color="#fff" />
                                {applyCardNumber === 0 ? (
                                  <span className={styles.cartName}>
                                    Cart {applyCardNumber}{" "}
                                  </span>
                                ) : (
                                  <span
                                    className={styles.viewCart}
                                    onClick={() => setShowCartUI(true)}
                                  >
                                    View cart {applyCardNumber}
                                  </span>
                                )}
                              </p>
                            </div>
                            <div className={styles.threeCards}>
                              {coraResponse["Paint Shades"]?.map(
                                (card: any) => {
                                  return (
                                    <>
                                      <div className={styles.cardDetails}>
                                        <div
                                          className={styles.creditCardHeader}
                                        >
                                          <img
                                            className={styles.cardImage}
                                            src={card.imageURL}
                                            alt={card.id}
                                          />
                                        </div>
                                        <div className={styles.creditCardInfo}>
                                          <div className={styles.cardPrice}>
                                            <p className={styles.cardName}>
                                              <span>{card.name}</span>
                                              <span className={styles.CPrice}>
                                                {card.price}
                                              </span>
                                            </p>
                                            {/* <p className={styles.CPrice}>
                                          {card.price}
                                        </p> */}
                                          </div>

                                          <p className={styles.productCode}>
                                            {card.id}
                                          </p>
                                          <p className={styles.punchLinewarp}>
                                            {card.description}
                                          </p>
                                          <div
                                            className={styles.buttonContainer}
                                          >
                                            {/* {compareData
                                            .map((item: any) => item.id)
                                            .includes(card.id) ? (
                                            <button
                                              onClick={() =>
                                                handleSpanText1(card)
                                              }
                                            >
                                              Remove From Cart
                                            </button>
                                          ) : (
                                            <button
                                              onClick={() =>
                                                handleSpanText1(card)
                                              }
                                            >
                                              Add to Cart
                                            </button>
                                          )} */}
                                            {selectedProducts[card.id] > 0 ? (
                                              <div
                                                className={styles.qytControl}
                                              >
                                                <button
                                                  className={styles.decrement}
                                                  onClick={() =>
                                                    handleDecrement(card)
                                                  }
                                                >
                                                  <span>-</span>
                                                </button>
                                                <span
                                                  className={styles.quantity}
                                                >
                                                  {selectedProducts[card.id]}
                                                </span>
                                                <button
                                                  className={styles.increment}
                                                  onClick={() =>
                                                    handleSpanText1(card)
                                                  }
                                                >
                                                  <span>+</span>
                                                </button>
                                              </div>
                                            ) : (
                                              <div
                                                onClick={() =>
                                                  handleSpanText1(card)
                                                }
                                                className={
                                                  styles.addtocartbutton
                                                }
                                              >
                                                <button>Add to Cart</button>
                                              </div>
                                            )}
                                          </div>
                                        </div>
                                      </div>
                                    </>
                                  );
                                }
                              )}
                            </div>
                          </div>
                        ) : (
                          ""
                        )}
                        {coraResponse["Paint Sprayers"]?.length > 0 ? (
                          <div className={styles.mainCard}>
                            <div className={styles.cardType}>
                              <p>
                                <span>Paint Sprayers </span>
                              </p>
                              <p className={styles.cart}>
                                <CartIcon color="#fff" />
                                {applyCardNumber === 0 ? (
                                  <span className={styles.cartName}>
                                    Cart {applyCardNumber}{" "}
                                  </span>
                                ) : (
                                  <span
                                    className={styles.viewCart}
                                    onClick={() => setShowCartUI(true)}
                                  >
                                    View cart {applyCardNumber}
                                  </span>
                                )}
                              </p>
                            </div>
                            <div className={styles.threeCards}>
                              {products["Paint Sprayers"].map((card: any) => {
                                return (
                                  <>
                                    <div className={styles.cardDetails}>
                                      <div className={styles.creditCardHeader}>
                                        <img
                                          className={styles.cardImage}
                                          src={card.imageURL}
                                          alt={card.id}
                                        />
                                      </div>
                                      <div className={styles.creditCardInfo}>
                                        <p className={styles.cardName}>
                                          <span>{card.name}</span>
                                          <span className={styles.CPrice}>
                                            {card.price}
                                          </span>
                                        </p>
                                        <p className={styles.productCode}>
                                          {card.id}
                                        </p>
                                        <p className={styles.punchLinewarp}>
                                          {card.description}
                                        </p>
                                        {/* <div className={styles.buttonContainer}>
                                          {compareData
                                            .map((item: any) => item.id)
                                            .includes(card.id) ? (
                                            <button
                                              onClick={() =>
                                                handleSpanText1(card)
                                              }
                                            >
                                              Remove From Cart
                                            </button>
                                          ) : (
                                            <button
                                              onClick={() =>
                                                handleSpanText1(card)
                                              }
                                            >
                                              Add to Cart
                                            </button>
                                          )}
                                        </div> */}
                                        <div className={styles.buttonContainer}>
                                          {/* {compareData
                                            .map((item: any) => item.id)
                                            .includes(card.id) ? (
                                            <button
                                              onClick={() =>
                                                handleSpanText1(card)
                                              }
                                            >
                                              Remove From Cart
                                            </button>
                                          ) : (
                                            <button
                                              onClick={() =>
                                                handleSpanText1(card)
                                              }
                                            >
                                              Add to Cart
                                            </button>
                                          )} */}
                                          {selectedProducts[card.id] > 0 ? (
                                            <div className={styles.qytControl}>
                                              <button
                                                className={styles.decrement}
                                                onClick={() =>
                                                  handleDecrement(card)
                                                }
                                              >
                                                -
                                              </button>
                                              <span className={styles.quantity}>
                                                {selectedProducts[card.id]}
                                              </span>
                                              <button
                                                className={styles.increment}
                                                onClick={() =>
                                                  handleSpanText1(card)
                                                }
                                              >
                                                +
                                              </button>
                                            </div>
                                          ) : (
                                            <div
                                              onClick={() =>
                                                handleSpanText1(card)
                                              }
                                              className={styles.addtocartbutton}
                                            >
                                              <button>Add to Cart</button>
                                            </div>
                                          )}
                                        </div>
                                      </div>
                                    </div>
                                  </>
                                );
                              })}
                            </div>
                          </div>
                        ) : (
                          ""
                        )}
                        {coraResponse["Paint Accessories "]?.length > 0 ? (
                          <div className={styles.mainCard}>
                            <div className={styles.cardType}>
                              <p>
                                <span>Paint Accessories </span>
                              </p>
                              <p className={styles.cart}>
                                <CartIcon color="#fff" />
                                {applyCardNumber === 0 ? (
                                  <span className={styles.cartName}>
                                    Cart {applyCardNumber}{" "}
                                  </span>
                                ) : (
                                  <span
                                    className={styles.viewCart}
                                    onClick={() => setShowCartUI(true)}
                                  >
                                    View cart {applyCardNumber}
                                  </span>
                                )}
                              </p>
                            </div>
                            <div className={styles.threeCards}>
                              {products["Paint Accessories "].map(
                                (card: any) => {
                                  return (
                                    <>
                                      <div className={styles.cardDetails}>
                                        <div
                                          className={styles.creditCardHeader}
                                        >
                                          <img
                                            className={styles.cardImage}
                                            src={card.imageURL}
                                            alt={card.id}
                                          />
                                        </div>
                                        <div className={styles.creditCardInfo}>
                                          <p className={styles.cardName}>
                                            <span>{card.name}</span>
                                            <span className={styles.CPrice}>
                                              {card.price}
                                            </span>
                                          </p>
                                          <p className={styles.productCode}>
                                            {card.id}
                                          </p>
                                          <p className={styles.punchLinewarp}>
                                            {card.description}
                                          </p>
                                          {/* <div className={styles.buttonContainer}>
                                          {compareData
                                            .map((item: any) => item.id)
                                            .includes(card.id) ? (
                                            <button
                                              onClick={() =>
                                                handleSpanText1(card)
                                              }
                                            >
                                              Remove From Cart
                                            </button>
                                          ) : (
                                            <button
                                              onClick={() =>
                                                handleSpanText1(card)
                                              }
                                            >
                                              Add to Cart
                                            </button>
                                          )}
                                        </div> */}
                                          <div
                                            className={styles.buttonContainer}
                                          >
                                            {/* {compareData
                                            .map((item: any) => item.id)
                                            .includes(card.id) ? (
                                            <button
                                              onClick={() =>
                                                handleSpanText1(card)
                                              }
                                            >
                                              Remove From Cart
                                            </button>
                                          ) : (
                                            <button
                                              onClick={() =>
                                                handleSpanText1(card)
                                              }
                                            >
                                              Add to Cart
                                            </button>
                                          )} */}
                                            {selectedProducts[card.id] > 0 ? (
                                              <div
                                                className={styles.qytControl}
                                              >
                                                <button
                                                  className={styles.decrement}
                                                  onClick={() =>
                                                    handleDecrement(card)
                                                  }
                                                >
                                                  -
                                                </button>
                                                <span
                                                  className={styles.quantity}
                                                >
                                                  {selectedProducts[card.id]}
                                                </span>
                                                <button
                                                  className={styles.increment}
                                                  onClick={() =>
                                                    handleSpanText1(card)
                                                  }
                                                >
                                                  +
                                                </button>
                                              </div>
                                            ) : (
                                              <div
                                                onClick={() =>
                                                  handleSpanText1(card)
                                                }
                                                className={
                                                  styles.addtocartbutton
                                                }
                                              >
                                                <button>Add to Cart</button>
                                              </div>
                                            )}
                                          </div>
                                        </div>
                                      </div>
                                    </>
                                  );
                                }
                              )}
                            </div>
                          </div>
                        ) : (
                          ""
                        )}
                      </>
                    </div>
                  ) : (
                    <div className={styles.familyCreditCardContainer}>
                      <div className={styles.viewCartHeader}>
                        <p className={styles.yourCart}>Your Cart</p>
                        <div className={styles.resumeshopping}>
                          <p
                            className={styles.checkout}
                            onClick={() => setShowHoldUI(true)}
                            style={{ width: "150px", cursor: "pointer" }}
                          >
                            Product on Hold ({holdCount}
                            {/* {heldProducts.length > 0
                              ? `${heldProducts.length}`
                              : "0"} */}
                            )
                          </p>
                          <p
                            className={styles.shopping}
                            onClick={() => setShowCartUI(false)}
                          >
                            Resume Shopping
                          </p>
                          <p className={styles.checkout}>Checkout</p>
                        </div>
                      </div>
                      <div className={styles.threeCards}>
                        {compareData.map((product: any) => {
                          // const product = coraResponse["Paint Shades"].find(
                          //   (p: any) => p.id === id
                          // );

                          return (
                            <div className={styles.cardDetails}>
                              <div className={styles.creditCardHeader}>
                                <img
                                  className={styles.cardImage}
                                  src={product.imageURL}
                                  alt={product.id}
                                />
                              </div>
                              <div className={styles.creditCardInfo}>
                                <div className={styles.cardPrice}>
                                  <p className={styles.cardName}>
                                    <span>{product.name}</span>
                                    <span className={styles.CPrice}>
                                      {product.price}
                                    </span>
                                  </p>
                                </div>

                                <p className={styles.productCode}>
                                  {product.id}
                                </p>
                                <p className={styles.punchLinewarp}>
                                  {product.description}
                                </p>

                                {/* <p>
                                  Cart Qty :{" "}
                                  <span className={styles.cartQuantity}>
                                    {quantity}
                                  </span>
                                </p> */}
                                <div className={styles.checkOutContainer}>
                                  <button className={styles.pickUp}>
                                    Pick up
                                  </button>
                                  <button
                                    className={styles.Hold}
                                    onClick={() => handleOnHold(product)}
                                  >
                                    Hold
                                  </button>
                                  <button className={styles.delivery}>
                                    Delivery
                                  </button>
                                  <button
                                    className={styles.removeItem}
                                    onClick={() => onRemoveItem(product)}
                                  >
                                    X
                                  </button>
                                </div>
                              </div>
                            </div>
                          );
                        })}
                      </div>
                    </div>
                  )}
                </>
              </div>
            </div>
          </div>
        ) : (
          <div className={showPopup ? styles.mainCont2 : styles.mainCont1}>
            <div className={styles.CreditCardContainer}>
              {/* ADDED NEW UI HERE*/}
              {customerSelectionDetails.name == "Liam Williams" && (
                <div className={styles.familyCreditCardContainer}>
                  <div>
                    <h2 className={styles.header}>
                      Splash into Summer Savings!
                    </h2>
                    <h3 className={styles.subHeader}>
                      <span>Summer Savings!</span>
                      <span></span>
                      <span></span>
                    </h3>

                    <div className={styles.categoriesGrid}>
                      {categories.map((item) => (
                        <div key={item.label} className={styles.categoryCard}>
                          <img
                            src={item.img}
                            alt={item.label}
                            className={styles.categoryImage}
                          />
                          <p className={styles.categoryLabel}>{item.label}</p>
                        </div>
                      ))}
                    </div>
                  </div>
                </div>
                // <div className={styles.familyCreditCardContainer}>
                //   <div className={styles.interiorPaint}>
                //     <div className={styles.breadcrumb}>
                //       Home / Color paints / <span>Interior paints</span>
                //     </div>
                //     <div className={styles.banner}>
                //       <img
                //         src={bannerContainder}
                //         alt="Banner"
                //         className={styles.bannerImage}
                //       />
                //     </div>
                //     <div className={styles.cardContainer}>
                //       {paints.map((paint) => (
                //         <div key={paint.id} className={styles.card}>
                //           <img
                //             src={paint.image}
                //             alt={paint.title}
                //             className={styles.paintImage}
                //           />
                //           <div className={styles.info}>
                //             <div className={styles.infotitle}>
                //               <h3>{paint.title}</h3>
                //               <p className={styles.price}>${paint.price}</p>
                //             </div>
                //             <p className={styles.code}>{paint.id}</p>
                //             <p className={styles.description}>
                //               {paint.description}
                //             </p>
                //             <div className={styles.priceReview}>
                //               <span className={styles.rating}>
                //                 ⭐⭐⭐⭐ {paint.rating} ({paint.reviews})
                //               </span>
                //             </div>
                //             <div className={styles.actions}>
                //               <button className={styles.addToCart}>
                //                 Add to Cart
                //               </button>
                //               <button className={styles.requestHold}>
                //                 Request a Hold
                //               </button>
                //             </div>
                //           </div>
                //         </div>
                //       ))}
                //     </div>
                //   </div>
                // </div>
              )}
            </div>
          </div>
        )}

        {!showPopup && (
          <img
            className={styles.chatIcon}
            src={`https://dreamdemoassets.blob.core.windows.net/openai/aoai_2_sc_icon.png`}
            alt="chat-icon"
            onClick={() => setShowPopup(true)}
          />
        )}
        {showPopup && (
          <div
            className={`${styles.chatContainer}  ${
              showThoughtProcessPopup && styles.thoughtProcessChatContainer
            }`}
          >
            <div className={styles.chatHeader}>
              <h1 style={{ margin: 0 }}>Cora – Your DIY Agent</h1>
              <audio
                hidden
                controls
                id="sampleAudioPlayer"
                muted={isMuted}
              ></audio>
              <div className={styles.actionButtonsContainer}>
                <Button
                  title="Mute"
                  className={styles.muteButton}
                  onClick={() => setIsMuted(!isMuted)}
                >
                  {!isMuted ? (
                    <Speaker224Filled className={styles.speaker} />
                  ) : (
                    <SpeakerMute24Filled className={styles.speaker} />
                  )}
                </Button>
              </div>
              <Dismiss24Regular
                onClick={() => setShowPopup(false)}
                style={{ cursor: "pointer" }}
              />
            </div>
            <Chat
              messageTemplate={MessageTemplate}
              attachmentTemplate={AttachmentTemplate}
              onMessageSend={onMessageSend}
              className={`${styles.chat} ${
                showDefaultLooks && styles.disableChatBot
              }`}
              user={AUTHORS[1]}
              messages={messages}
              ref={chatRef}
              messageBox={customMessage}
            />

            {selectionItem && showThoughtProcessPopup && (
              <div className={styles.thoughtProcessPopup}>
                <div className={styles.thoughtProcessPopupHeader}>
                  <h1>Thought Process</h1>
                  <span
                    className={`k-icon k-i-close ${styles.closeBtn}`}
                    onClick={() => {
                      setShowThoughtProcessPopup(false);
                    }}
                  ></span>
                </div>
                <div
                  className={styles.body}
                  dangerouslySetInnerHTML={{
                    __html: (selectionItem as any)?.thoughts,
                  }}
                ></div>
              </div>
            )}

            {isChatEnded && (
              <span className={styles.chatEndedMessage}>Chat has ended.</span>
            )}
            {show && (
              <div className={styles["popup-content"]}>
                {/* <Button
                  className={styles.btn}
                  style={{ width: 150 }}
                  onClick={() => {
                    setShowCamera(true);
                    setShow(false);
                  }}
                >
                  Take a Picture
                </Button>
                <span
                  style={{
                    color: "var(--secondary-color)",
                    margin: 0,
                    padding: 0,
                    fontWeight: 700,
                  }}
                >
                  or
                </span> */}
                <ImageUploading
                  value={images}
                  onChange={onChange}
                  allowNonImageType={false}
                  multiple={false}
                >
                  {({ imageList, onImageUpload, onImageRemoveAll }) => {
                    return (
                      <div
                        className={`upload__image-wrapper ${styles.imageWrapper}`}
                        style={{ width: "100%" }}
                      >
                        <Button
                          style={{ width: "100%" }}
                          className={styles.btn}
                          onClick={() => onImageUpload()}
                          id="#file"
                        >
                          Upload Photo
                        </Button>
                      </div>
                    );
                  }}
                </ImageUploading>
              </div>
            )}
            {showVideo && (
              <div className={styles["popup-content"]}>
                <Button
                  className={styles.btn}
                  style={{ width: 150 }}
                  onClick={() => {
                    setShowVideoCamera(true);
                    setShowVideo(false);
                  }}
                >
                  Record a video
                </Button>
                <span
                  style={{
                    color: "var(--secondary-color)",
                    margin: 0,
                    padding: 0,
                    fontWeight: 700,
                  }}
                >
                  or
                </span>
                <input
                  type="file"
                  onChange={handleFileChange}
                  style={{ display: "none" }}
                  ref={fileInputRef}
                />
                <Button
                  style={{ width: "100%" }}
                  className={styles.btn}
                  onClick={() => handleClick()}
                  id="#file"
                >
                  Select File
                </Button>
              </div>
            )}
          </div>
        )}
      </div>

      {/* <div className="arcButtonsContainer">
        <div onClick={() => setShowPopArchitecture(true)}>
          <img
            className={styles.archImages}
            src="https://dreamdemoassets.blob.core.windows.net/nrf/architectureButton.png"
          />
        </div>
      </div> */}

      {/* <Popup
        showPopup={showPopArchitecture}
        title={popupTitle}
        onClose={() => setShowPopArchitecture(false)}
        dialogWidth={1400}
        dialogHeight={960}
      >
        <ArchitectureWithTags
          pageTitle={"Architecture diagram"}
          pageType={PageType.Architecture}
          imageUrl={
            "https://dreamdemoassets.blob.core.windows.net/herodemos/AzureHeroDemo1aArchV2.png"
          }
          // tags={[
          //   {
          //     tagName: "Enter your question",
          //     tagDescription: "Enter your question",
          //   },
          // ]}
        />
      </Popup> */}
    </div>
  );
};