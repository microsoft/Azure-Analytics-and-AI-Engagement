import React, { useState } from "react";
import styles from "./styles.module.css";
import successImage from "./successImage.png"; // Placeholder for the success image
import failureImage from "./failureImage.png"; // Placeholder for the failure image
import { Success } from "assets/Success";
import { Failure } from "assets/Failure";
import { Button } from "@progress/kendo-react-buttons";
import { useNavigate } from "react-router-dom";

const Checkout = ({ cartItems }: any) => {
  const [orderPlaced, setOrderPlaced] = useState(false);
  const [orderStatus, setOrderStatus] = useState<"success" | "failure" | null>(
    null
  );

  const navigate = useNavigate();

  const [shippingInfo, setShippingInfo] = useState({
    firstName: "Ashley",
    lastName: "Shields",
    address: "836 Clarendon Avenue",
    city: "Aurora",
    state: "California",
    zip: "19318",
    phone: "XXX-XXX-1270",
  });
  const [paymentInfo, setPaymentInfo] = useState({
    cardName: "Ashley Shields",
    cardNumber: "XXXX XXXX XXXX 2895",
    expiry: "06/29",
    cvv: "XXX",
  });

  const totalPrice = cartItems.reduce(
    (acc: any, item: any) => acc + parseFloat(item.price.replace("$", "")),
    0
  );

  const handleInputChange = (e: any, field: any, section: any) => {
    const value = e.target.value;
    section === "shipping"
      ? setShippingInfo({ ...shippingInfo, [field]: value })
      : setPaymentInfo({ ...paymentInfo, [field]: value });
  };

  const handleOrder = () => {
    const urlContainsScaling = window.location.href.includes("scaling");
    setOrderPlaced(true);
    setOrderStatus(urlContainsScaling ? "success" : "failure");
  };

  // Render success or failure UI
  if (orderPlaced) {
    return (
      <div className={styles.checkoutPage}>
        {orderStatus === "success" ? (
          <div className={styles.result}>
            <Success></Success>{" "}
            <div className={styles.resultText}>Order Successful</div>
            <div>
              Thanks for shopping! Your order has been placed successfully
            </div>
            <Button className={styles.continueBtn} onClick={() => navigate(`/call-center-before-sentiment`)}>Continue Shopping</Button>
          </div>
        ) : (
          <div className={styles.result}>
            <Failure></Failure>{" "}
            <div className={styles.resultText}>Oops, transaction failed</div>
            <div>Please try again later</div>{" "}
            <Button className={styles.continueBtn} onClick={() => navigate(`/azure-cosmos-db-highlights`)}>Continue Shopping</Button>
          </div>
        )}
      </div>
    );
  }

  return (
    <div className={styles.checkoutPage}>
      <div className={styles.container}>
        <div className={styles.deliveryInfo}>
          <h2>Delivery Info</h2>
          <div className={styles.deliveryGrid}>
            <input
              type="text"
              placeholder="First name"
              value={shippingInfo.firstName}
              onChange={(e) => handleInputChange(e, "firstName", "shipping")}
            />
            <input
              type="text"
              placeholder="Last name"
              value={shippingInfo.lastName}
              onChange={(e) => handleInputChange(e, "lastName", "shipping")}
            />
            <input
              type="text"
              placeholder="Address"
              className={styles.addressInput}
              value={shippingInfo.address}
              onChange={(e) => handleInputChange(e, "address", "shipping")}
            />
            <input
              type="text"
              placeholder="City"
              value={shippingInfo.city}
              onChange={(e) => handleInputChange(e, "city", "shipping")}
            />
            <input
              type="text"
              placeholder="State"
              value={shippingInfo.state}
              onChange={(e) => handleInputChange(e, "state", "shipping")}
            />
            <input
              type="text"
              placeholder="Zip"
              value={shippingInfo.zip}
              onChange={(e) => handleInputChange(e, "zip", "shipping")}
            />
            <input
              type="text"
              placeholder="Phone"
              value={shippingInfo.phone}
              onChange={(e) => handleInputChange(e, "phone", "shipping")}
            />
          </div>
        </div>

        <div className={styles.paymentMethod}>
          <h2>Payment Method</h2>
          <input
            type="text"
            placeholder="Name on card"
            value={paymentInfo.cardName}
            onChange={(e) => handleInputChange(e, "cardName", "payment")}
          />
          <input
            type="text"
            placeholder="Card number"
            value={paymentInfo.cardNumber}
            onChange={(e) => handleInputChange(e, "cardNumber", "payment")}
          />
          <div className={styles.cardDetails}>
            <input
              type="text"
              placeholder="Expiry"
              value={paymentInfo.expiry}
              onChange={(e) => handleInputChange(e, "expiry", "payment")}
            />
            <input
              type="text"
              placeholder="CVV"
              value={paymentInfo.cvv}
              onChange={(e) => handleInputChange(e, "cvv", "payment")}
            />
          </div>
          <div className={styles.alternatePayment}>
            <p>Another Payment Method</p>
            <p>Credit or Debit card</p>
            <p>Cash on delivery / Pay on delivery</p>
          </div>
          <button className={styles.payBtn} onClick={handleOrder}>
            Pay now ${totalPrice}
          </button>
        </div>
      </div>
    </div>
  );
};

export default Checkout;
