import { FieldRenderProps, FieldWrapper } from "@progress/kendo-react-form";
import { Label, Error, Hint } from "@progress/kendo-react-labels";
import { Input as KendoInput } from "@progress/kendo-react-inputs";

export const Input = (fieldRenderProps: FieldRenderProps) => {
  const {
    validationMessage,
    touched,
    label,
    id,
    valid,
    disabled,
    hint,
    type,
    optional,
    ...others
  } = fieldRenderProps;

  const showValidationMessage: string | false | null =
    touched && validationMessage;
  const showHint: boolean = !showValidationMessage && hint;
  const hintId: string = showHint ? `${id}_hint` : "";
  const errorId: string = showValidationMessage ? `${id}_error` : "";

  return (
    <FieldWrapper>
      <Label
        editorId={id}
        editorValid={valid}
        editorDisabled={disabled}
        optional={optional}
      >
        {label}
      </Label>
      <div className={"k-form-field-wrap"}>
        <KendoInput
          valid={valid}
          type={type}
          id={id}
          disabled={disabled}
          ariaDescribedBy={`${hintId} ${errorId}`}
          {...others}
        />
        {showHint && <Hint id={hintId}>{hint}</Hint>}
        {showValidationMessage && (
          <Error id={errorId}>{validationMessage}</Error>
        )}
      </div>
    </FieldWrapper>
  );
};
