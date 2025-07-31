import { FieldRenderProps } from "@progress/kendo-react-form";
import { Rating } from "@progress/kendo-react-inputs";
import { Error } from "@progress/kendo-react-labels";

export const RatingInput = (fieldRenderProps: FieldRenderProps) => {
  const { touched, validationMessage, value, ...others } = fieldRenderProps;
  return (
    <div>
      <Rating value={value} {...others} />
      {touched && !Boolean(value) && <Error>Please rate us</Error>}
    </div>
  );
};
