import { getter } from "@progress/kendo-react-common";

const emailRegex = new RegExp(/\S+@\S+\.\S+/);
export const emailValidator = (value: string) =>
  emailRegex.test(value) ? "" : "Please enter a valid email.";

export const ratingValidator = (value: number) =>
  value ? "" : "Please rate us.";

export const feedbackValidator = (value: string) =>
  !value ? "Please enter your feedback." : "";

const nameRegex = new RegExp(/^[a-zA-Z]+ [a-zA-Z]+$/);
export const nameValidator = (value: string) =>
  nameRegex.test(value) ? "Please enter your name." : "";

const name = getter("name");
const email = getter("email");
export const validator = (values: any) => {
  if (name(values) && email(values)) {
    return;
  }

  return {
    name: "Please enter your name.",
    email: "Please enter your email.",
  };
};
