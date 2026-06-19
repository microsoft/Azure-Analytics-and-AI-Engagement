import React, { useEffect, useState } from "react";
import {
  AudioConfig,
  ResultReason,
  SpeechConfig,
  SpeechRecognizer,
  // @ts-ignore
} from "microsoft-cognitiveservices-speech-sdk";
import { handleVoiceEdit, getTokenOrRefresh } from "utilities";

export const useMic = (field: string, updateUser: Function) => {
  const [active, setActive] = React.useState(false);
  const [tokenObj, setTokenObj] = useState<any>({});
  const fetch = async () => {
    const token = await getTokenOrRefresh();
    setTokenObj(token);
  };

  useEffect(() => {
    fetch();
  }, []);

  const sttFromMic = async () => {
    // const tokenObj = await getTokenOrRefresh();
    const speechConfig = SpeechConfig.fromAuthorizationToken(
      tokenObj.authToken,
      tokenObj.region
    );
    speechConfig.speechRecognitionLanguage = "en-US";

    const audioConfig = AudioConfig.fromDefaultMicrophoneInput();
    const recognizer = new SpeechRecognizer(speechConfig, audioConfig);

    setActive(true);

    recognizer.recognizeOnceAsync((result: any) => {
      if (result.reason === ResultReason.RecognizedSpeech) {
        updateUser(result.text);
        setActive(false);
      } else {
        setActive(false);
      }
    });
  };
  return [sttFromMic, active];
};
