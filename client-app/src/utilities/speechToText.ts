import axios from "axios";
import Cookie from "universal-cookie";
import startCase from "lodash.startcase";
import { converge, eq, pipe, prop, toLower } from "fp-tools";
import { cond, replace } from "ramda";

const { SPEECH_KEY, SPEECH_REGION } = window.config;

export async function getTokenOrRefresh() {
  const cookie = new Cookie();
  const speechToken = cookie.get("speech-token");

  if (speechToken === undefined) {
    const headers = {
      headers: {
        "Ocp-Apim-Subscription-Key": SPEECH_KEY,
        "Content-Type": "application/x-www-form-urlencoded",
      },
    };

    try {
      const res = await axios.post(
        `https://${SPEECH_REGION}.api.cognitive.microsoft.com/sts/v1.0/issueToken`,
        null,
        headers
      );
      const token = res.data;
      const region = SPEECH_REGION;
      cookie.set("speech-token", region + ":" + token, {
        maxAge: 540,
        path: "/",
      });
      return { authToken: token, region: region };
    } catch (err) {
      return { authToken: null, error: err };
    }
  } else {
    const idx = speechToken.indexOf(":");
    return {
      authToken: speechToken.slice(idx + 1),
      region: speechToken.slice(0, idx),
    };
  }
}

export const formatTaxId = (taxId: string) => {
  return taxId.length === 9
    ? taxId.replace(/(\d{3})(\d{2})(\d{4})/, "$1-$2-$3")
    : taxId;
};
export const formatPhoneNumber = (phone: string) => {
  return phone.length === 10
    ? phone.replace(/(\d{3})(\d{3})(\d{4})/, "($1) $2-$3")
    : phone;
};
export const removePunctuation = replace(/[.,/#!?$%^&*;:{}=\-_`~()]/g, "");
export const clean = pipe(removePunctuation, toLower);

export const handleVoiceEdit = (updateUser: Function) =>
  cond([
    [
      pipe(prop("field"), eq("name")),
      converge(updateUser, [prop("field"), pipe(prop("value"), startCase)]),
    ],
    [() => true, converge(updateUser, [prop("field"), prop("value")])],
  ]);
