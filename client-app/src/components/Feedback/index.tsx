import { Button } from "@progress/kendo-react-buttons";
import {
  Field,
  Form,
  FormElement,
  FormSubmitClickEvent,
} from "@progress/kendo-react-form";
import { Popup } from "@progress/kendo-react-popup";
import { FC, useRef, useState } from "react";
import {
  emailValidator,
  Input,
  FormTextArea,
  RatingInput,
  ratingValidator,
  feedbackValidator,
} from "components/Form";

import styles from "./styles.module.scss";

const Feedback: FC = () => {
  const [showFeedbackModal, setShowFeedbackModal] = useState(false);
  const ref = useRef(null);

  const handleSubmit = ({ values, isValid }: FormSubmitClickEvent) => {
    isValid && setShowFeedbackModal(false);
  };

  return (
    <>
      <button
        ref={ref}
        className={`k-button k-button-md k-rounded-md k-button-solid k-button-solid-base ${styles.feedbackBtn}`}
        style={{ visibility: showFeedbackModal ? "hidden" : "visible" }}
        onClick={() => setShowFeedbackModal(true)}
      >
        Feedback?
      </button>
      <Popup
        anchor={ref?.current}
        show={showFeedbackModal}
        popupClass={styles.popup}
        onClose={() => setShowFeedbackModal(false)}
      >
        <>
          <span
            onClick={() => setShowFeedbackModal(false)}
            className="k-icon k-i-close"
          ></span>

          <Form
            initialValues={{
              email: "",
              feedback: "",
              rating: null,
            }}
            onSubmitClick={handleSubmit}
            render={(formRenderProps) => (
              <div className={styles.form}>
                <h3>Submit your feedback</h3>
                <h6>We would like your feedback to improve our website.</h6>
                <Field
                  id="email"
                  name="email"
                  label="Email"
                  type="email"
                  placeholder="Enter your email"
                  validator={emailValidator}
                  component={Input}
                />
                <h6>What is your opinion of this demo?</h6>
                <Field
                  id="rating"
                  name={"rating"}
                  value={formRenderProps.valueGetter("rating")}
                  component={RatingInput}
                  required
                  validation={ratingValidator}
                />
                <hr />
                <h6>Please leave your feedback below:</h6>
                <FormElement>
                  <fieldset className={"k-form-fieldset"}>
                    <Field
                      id={"feedback"}
                      name={"feedback"}
                      max={200}
                      value={formRenderProps.valueGetter("feedback")}
                      component={FormTextArea}
                      validator={feedbackValidator}
                    />
                    <div className="k-form-buttons k-justify-content-end">
                      <Button
                        className={styles.sendBtn}
                        type={"submit"}
                        disabled={!formRenderProps.allowSubmit}
                      >
                        Send
                      </Button>
                    </div>
                  </fieldset>
                </FormElement>
              </div>
            )}
          />
        </>
      </Popup>
    </>
  );
};

export default Feedback;
