import React, { FC, useEffect, useState } from "react";
import styles from "./styles.module.scss";
import { Button } from "@progress/kendo-react-buttons";

interface Props {
  product: any;
  setSelectedProduct: React.Dispatch<React.SetStateAction<any>>;
}

export const ProductDetails: FC<Props> = ({ product, setSelectedProduct }) => {
  const [similarProducts, setSimilarProduct] = useState([]);

  const getSimilarProducts = (url: string) => {
    fetch(
      // "https://func-image-shopping-copilot.azurewebsites.net/api/getproductimages_upload",
      "https://funcapp-shopping-assistant.azurewebsites.net/api/getproductimages_upload",
      {
        method: "POST",
        body: JSON.stringify({ url }),
      }
    )
      .then((res) => res.json())
      .then((res) => {
        setSimilarProduct((old) => res?.products ?? old);
      });
  };

  useEffect(() => {
    if (product?.url) getSimilarProducts(product?.url);
  }, [product]);

  return (
    <div className={styles.container}>
      <div className={styles.product}>
        <div>
          <img src={product?.url} alt={product?.name} />
          <img src={product?.url} alt={product?.name} />
          <img src={product?.url} alt={product?.name} />
        </div>
        <hr
          style={{
            color: "#8C8C8C",
            opacity: 0.5,
          }}
        />
        <div className={styles.similarProducts}>
          <h1>Similar Products</h1>
          <div className={styles.similarProductsContainer}>
            {similarProducts?.map((product: any, index) => (
              <div className={styles.similarProduct}>
                <div
                  onClick={() => setSelectedProduct(product)}
                  className={styles.similarProductImageContainer}
                >
                  <img src={product?.url} alt={product.name} />
                </div>
                <div className={styles.similarProductMetadata}>
                  <span
                    onClick={() => {
                      setSelectedProduct(product);
                    }}
                  >
                    <strong>{product?.name}</strong>
                  </span>
                  <span>{product?.price}</span>
                  <img
                    className={styles.similarProductShopIcon}
                    src="https://dreamdemoassets.blob.core.windows.net/openai/RL_Copilot_Cart.png"
                    alt="RL_Copilot_Cart"
                  />
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>
      <div className={styles.metadata}>
        <div>
          <div className={styles.title}>{product?.name}</div>
          <div className={styles.price}>{product?.price}</div>
          <div className={styles.description}>
            Rendered from silk shantung for a rustic look and a soft hand, the
            Tracy shorts are inspired by a best-selling silhouette from the
            Pre-Fall 2017 Collection. Crafted in Italy and detailed with a
            single pleat down each leg, these shorts are embellished with a
            "Ralph Lauren"-engraved mother-of-pearl button at the waistband.
          </div>
          <Button className={styles.btn}>Add to Bag</Button>
        </div>
        <hr
          style={{
            color: "#8C8C8C",
            opacity: 0.5,
          }}
        />
        <div>
          <div className={styles.title}>Complete the Look</div>

          <div className={styles.productLooksContainer}>
            {similarProducts?.splice(0, 3)?.map((product: any) => (
              <div className={styles.productLooks}>
                <div className={styles.imageContainer}>
                  <img src={product?.url} alt={product?.name} />
                </div>
                <div className={styles.looksMetadata}>
                  <div className={styles.metadataTitleContainer}>
                    <strong>{product?.name}</strong>
                    <div>{product?.price}</div>
                  </div>
                  <div className={styles.shoppingCart}>
                    <img
                      className={styles.shopIcon}
                      src="https://dreamdemoassets.blob.core.windows.net/openai/RL_Copilot_Cart.png"
                      alt="RL_Copilot_Cart"
                    />
                    <span>Add to Bag</span>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
};
