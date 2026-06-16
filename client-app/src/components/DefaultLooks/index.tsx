import React, { FC, useState } from "react";
import styles from "./styles.module.scss";
import { Button } from "@progress/kendo-react-buttons";
import { useAppDispatch, useAppSelector } from "hooks";
import {
  setShoppingStyle,
  setShoppingGender,
  setSelectedButtonId,
  setShowDefaultLooks,
} from "store";

const imageGroups = [
  {
    id: 1,
    images: [
      "https://dreamdemoassets.blob.core.windows.net/mtc/mtc_female_p4.png",
      "https://dreamdemoassets.blob.core.windows.net/mtc/mtc_female_p1.png",
      "https://dreamdemoassets.blob.core.windows.net/mtc/mtc_female_p2.png",
    ],
  },
  {
    id: 3,
    images: [
      "https://dreamdemoassets.blob.core.windows.net/mtc/mtc_male_p2.png",
      "https://dreamdemoassets.blob.core.windows.net/mtc/mtc_male_p5.png",
      "https://dreamdemoassets.blob.core.windows.net/mtc/mtc_male_p3.png",
    ],
  },
  {
    id: 2,
    images: [
      "https://dreamdemoassets.blob.core.windows.net/mtc/mtc_female_p3.png",
      "https://dreamdemoassets.blob.core.windows.net/mtc/mtc_male_p6.png",
      "https://dreamdemoassets.blob.core.windows.net/mtc/mtc_male_p7.png",
    ],
  },
  {
    id: 4,
    images: [
      "https://dreamdemoassets.blob.core.windows.net/mtc/mtc_male_p4.png",
      "https://dreamdemoassets.blob.core.windows.net/mtc/mtc_male_p1.png",
      "https://dreamdemoassets.blob.core.windows.net/mtc/mtc_female_p5.png",
    ],
  },
  // Define more image groups as needed
];

interface Props {
  onClick?: (groupId: number) => void;
}

export const DefaultLooks: FC<Props> = ({ onClick }) => {
  const dispatch = useAppDispatch();
  const [selectedImages, setSelectedImages] = useState<string[]>([]);
  const { selectedButtonId } = useAppSelector((state) => state.config);

  const handleGroupButtonClick = (groupId: number) => {
    if (groupId === selectedButtonId) {
      // Unselect the button if it's already selected

      dispatch(setSelectedButtonId(null));
      setSelectedImages([]);
    } else {
      // Select the new button
      dispatch(setSelectedButtonId(groupId));

      switch (groupId) {
        case 1:
          dispatch(setShoppingStyle("casual"));
          dispatch(setShoppingGender("female"));
          break;
        case 2:
          dispatch(setShoppingStyle("formal"));
          dispatch(setShoppingGender("female"));
          break;
        case 3:
          dispatch(setShoppingStyle("casual"));
          dispatch(setShoppingGender("male"));
          break;
        case 4:
          dispatch(setShoppingStyle("formal"));
          dispatch(setShoppingGender("male"));
          break;
      }

      if (groupId === 1 || groupId === 2) dispatch(setShoppingGender("female"));
      else dispatch(setShoppingGender("male"));

      const groupImages =
        imageGroups.find((group) => group.id === groupId)?.images || [];
      setSelectedImages(groupImages);

      onClick?.(groupId);
    }
  };

  return (
    <div className={styles.shoppingCardContainer}>
      {imageGroups.map((group) => {
        const isSelected = group.id === selectedButtonId;
        return (
          <div
            key={group.id}
            className={`${
              isSelected ? styles.selectedSingleCard : styles.singleCard
            } ${isSelected && styles.glow}`}
          >
            <div className="">
              <div className={styles.titleContainer}>Look {group.id}</div>
            </div>
            <div className={styles.imagesGroup}>
              {group.images.map((img) => (
                <div className={styles.image} key={img}>
                  <img
                    // className={isSelected ? styles.glowOnly : ""}
                    src={img}
                    alt="look"
                  />
                </div>
              ))}
            </div>
            <div
              style={{
                display: "flex",
                justifyContent: "center",
                alignItems: "center",
                marginTop: "6px",
                marginBottom: "4px",
              }}
            >
              <Button
                className={styles.cardButton}
                style={{
                  border: isSelected
                    ? "2px solid transparent"
                    : "2px solid #fff",
                  backgroundColor: isSelected ? "#0F3A7A" : "#07659E",
                }}
                onClick={() => handleGroupButtonClick(group.id)}
              >
                <span style={{ color: "white" }}>
                  {" "}
                  {isSelected ? "Deselect" : "Select"}{" "}
                </span>
              </Button>
            </div>
          </div>
        );
      })}
    </div>
  );
};
