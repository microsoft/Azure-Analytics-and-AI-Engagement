import { Slider } from "@progress/kendo-react-inputs";
import { FC } from "react";
import styles from "./styles.module.scss";

interface Props {
  label: string;
  value: number;
  onChange: (value: number) => void;
  min: number;
  max: number;
  isDisabled?: boolean;
}

export const RangeSlider: FC<Props> = ({
  label,
  value,
  onChange,
  min,
  max,
  isDisabled = false,
}) => {
  return (
    <div style={{ marginBottom: "8px" }}>
      <label>
        {label}: {Math.round(value)} (Range: {min} - {max})
      </label>
      <br />
      <Slider
        className={label.includes("Churn") ? styles.rangeSlider : ""}
        min={min}
        disabled={isDisabled}
        max={max}
        value={value}
        onChange={(e) => onChange(+(e.value as number).toFixed(0))}
      />
    </div>
  );
};
