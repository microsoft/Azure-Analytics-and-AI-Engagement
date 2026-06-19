import { FC, useEffect, useState } from "react";
import styles from "./styles.module.scss";
import { useNavigate } from "react-router-dom";
import Lottie from "lottie-react";
import incomingCall from "assets/IncomingCall.json";
import endCall from "assets/EndCall.json";
import { Lightbulb16Regular } from "@fluentui/react-icons";
import { Popup } from "components";
import { useMsal } from "@azure/msal-react";
import { setFileName, setSessionId } from "store";
import { useAppDispatch, useAppSelector } from "hooks";

const { StartCallAPI } = window.config;

export const IncomingCall: FC = () => {
  // const location = useLocation();
  const navigate = useNavigate();
  const dispatch = useAppDispatch();

  const { accounts } = useMsal();
  const [showPopup, setShowPopup] = useState(false);
  const [sessionId, setSession] = useState<string>("");
  const handleAcceptCall = () => {
    fetchData();
    navigate(`/customer-call-in-progress`);
  };
  const { fileName, customerId, name, avatar } = useAppSelector(
    (state) => state.config
  );
  useEffect(() => {
    // Generate session ID based on the user's unique identifier
    if (accounts.length > 0) {
      const randomNumber =
        Math.floor(Math.random() * (999999 - 100000 + 1)) + 100000;
      setSession(randomNumber.toString());
      dispatch(setSessionId(randomNumber));
    }
  }, [accounts]);
  const fetchData = async () => {
    try {
      const response = await fetch(StartCallAPI, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({ sessionID: sessionId }),
      });
      if (response.ok) {
        const data = await response.json();
        dispatch(setFileName(data?.filename));
      } else {
        console.error("Failed to fetch data");
      }
    } catch (error) {
      console.error("Error fetching data:", error);
    }
  };
  const onPlay = () => {
    const sampleAudioPlayer: HTMLAudioElement | null = document.getElementById(
      "audioPlayer"
    ) as HTMLAudioElement;
    if (sampleAudioPlayer) {
      sampleAudioPlayer.play();
    }
  };

  return (
    <div className={styles.container}>
      <div className={styles.subContainer}>
        <audio
          id="audioPlayer"
          loop
          hidden
          src="https://dreamdemoassets.blob.core.windows.net/mtc/sounds/ringtone.mp3"
          autoPlay
        />
        <Popup
          showPopup={showPopup}
          title="Instructions"
          onClose={() => {
            setShowPopup(false);
            onPlay();
          }}
          className={styles.callPopup}
        >
          <img
            src="https://dreamdemoassets.blob.core.windows.net/mtc/icoming_call_popup.png"
            alt="popup-img"
          />
          <div className={styles.instructions}>
            You're now getting a call from a customer who may have an inquiry
            regarding orders, returns, exchanges, and cancellations for the
            retail company, Contoso. You can listen to the question and respond
            using the microphone button on the next screen.
          </div>
        </Popup>
        <div className={styles.rightContainer}>
          <div className={styles.title}>Incoming Call</div>
          <div className={styles.subTitle}>{name} is calling</div>
          <img
            src="https://dreamdemoassets.blob.core.windows.net/daidemo/aoai_2_incoming_call.png"
            alt="call center before"
          />
          <div className={styles.hint}>
            <Lightbulb16Regular /> Please accept the call to proceed
          </div>
          <div className={styles.callOptions}>
            <Lottie
              onClick={handleAcceptCall}
              animationData={incomingCall}
              style={{ width: 140, cursor: "pointer" }}
            />
            <Lottie
              onClick={() => navigate("/generate-email-campaign")}
              animationData={endCall}
              style={{
                width: 140,
                transform: "rotate(135deg)",
                cursor: "pointer",
              }}
            />
          </div>
        </div>
      </div>
    </div>
  );
};
