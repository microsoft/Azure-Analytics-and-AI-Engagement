import { FC, useState } from 'react';
import { Button } from '@progress/kendo-react-buttons';
import axios from 'axios';
import { CheckIcon, PaymentFailedIcon } from 'assets';
import styles from './styles.module.scss';
import { Input, RadioButton } from '@progress/kendo-react-inputs';
import {
  Form,
  Field,
  FormElement,
  FormRenderProps,
  FormSubmitClickEvent,
} from '@progress/kendo-react-form';
import { useAppDispatch } from 'hooks';
import {
  setReImaginedDemoComplete,
  setReImaginedScalingDemoComplete,
} from 'store';

const { OrderAPI, CustomerId } = window.config;

interface Props {
  cartDetails: any;
  orderDetails: any;
  onGoBack: () => void;
  address: any;
  paymentFailedDemo?: boolean;
}
const firstName = 'Ashley';
const lastName = 'Shields';
const addressDetail = '836 Clarendon Avenue';
const city = 'Aurora';
const state = 'California';
const zip = '19318';
const phone = 'XXX-XXX-1270';

const cardholdername = 'Ashley Shields';
const cardnumber = 'XXXX XXXX XXXX 2895';
const expiry = '06/29';
const cvv = 'XXX';
export const Payment: FC<Props> = ({
  onGoBack,
  cartDetails,
  orderDetails,
  paymentFailedDemo,
}) => {
  const dispatch = useAppDispatch();
  const [showCheckoutPopup, setShowCheckoutPopup] = useState(false);

  const onCheckout = () => {
    if (paymentFailedDemo) {
      setShowCheckoutPopup(true);
      dispatch(setReImaginedDemoComplete(true));
    } else {
      axios
        .post(OrderAPI + '/Payment/' + CustomerId)
        .then((res) => {
          setShowCheckoutPopup(true);
          !paymentFailedDemo &&
            dispatch(setReImaginedScalingDemoComplete(true));
        })
        .catch((err) => console.log({ err }));
    }
  };

  const handleSubmit = ({ values }: FormSubmitClickEvent) => {};

  if (showCheckoutPopup) {
    return (
      <div className={styles.popupContainer}>
        <div
          className={styles.checkoutPopup}
          style={{
            ...(paymentFailedDemo && {
              width: '500px',
            }),
          }}
        >
          {paymentFailedDemo ? <PaymentFailedIcon /> : <CheckIcon />}
          <h2
            style={{
              ...(paymentFailedDemo && {
                color: '#e68838',
              }),
            }}
          >
            {paymentFailedDemo ? 'Oops,Transaction Failed' : 'Order Successful'}
          </h2>
          <p>
            {paymentFailedDemo
              ? 'Please try again later.'
              : 'Thanks for shopping! Your order has been placed successfully.'}
          </p>
          <Button
            className={`${styles.backButton}`}
            style={{
              ...(paymentFailedDemo && {
                backgroundColor: '#e68838',
              }),
            }}
            onClick={onGoBack}
          >
            {paymentFailedDemo ? 'Go to cart' : 'Go Back'}
          </Button>
        </div>
      </div>
    );
  }

  return (
    <div className={`${styles.container}`}>
      <div className={styles.topContainer}>
        <div className={styles.userAndCardDetailContainer}>
          <div className={styles.userDetailContainer}>
            <span style={{ fontWeight: 'bold' }}>Delivery Info</span>
            <hr />
            <Form
              initialValues={{
                firstName,
                lastName,
                addressDetail,
                city,
                state,
                zip,
                phone,
              }}
              key={firstName}
              onSubmitClick={handleSubmit}
              render={({ onSubmit }: FormRenderProps) => (
                <FormElement
                  style={{
                    color: '#0c3561',
                  }}
                >
                  <div
                    className={styles.userAndCardDetailContainer}
                    style={{ paddingBottom: 10 }}
                  >
                    <Field
                      id="firstname"
                      name="firstname"
                      label="First name"
                      type="text"
                      placeholder={firstName}
                      component={Input}
                    />
                    <Field
                      id="lastname"
                      name="lastname"
                      label="Last name"
                      type="text"
                      placeholder={lastName}
                      component={Input}
                    />
                  </div>
                  <div style={{ paddingBottom: 10 }}>
                    <Field
                      id="addressDetail"
                      name="addressDetail"
                      label="Address"
                      type="text"
                      placeholder={addressDetail}
                      component={Input}
                    />
                  </div>

                  <div
                    className={styles.userAndCardDetailContainer}
                    style={{ paddingBottom: 10 }}
                  >
                    <Field
                      id="city"
                      name="city"
                      label="City"
                      type="text"
                      placeholder={city}
                      component={Input}
                    />
                    <Field
                      id="state"
                      name="state"
                      label="State"
                      type="text"
                      placeholder={state}
                      component={Input}
                    />
                  </div>
                  <div className={styles.userAndCardDetailContainer}>
                    <Field
                      id="zip"
                      name="zip"
                      label="Zip"
                      type="text"
                      placeholder={zip}
                      component={Input}
                    />
                    <Field
                      id="phone"
                      name="phone"
                      label="Phone"
                      type="text"
                      placeholder={phone}
                      component={Input}
                    />
                  </div>
                </FormElement>
              )}
            />
          </div>
          <div className={styles.cardDetailContainer}>
            <span style={{ fontWeight: 'bold' }}>Payment Method</span>
            <hr />
            <Form
              initialValues={{
                cardnumber,
                expiry,
                cvv,
              }}
              key={firstName}
              onSubmitClick={handleSubmit}
              render={({ onSubmit }: FormRenderProps) => (
                <FormElement
                  style={{
                    color: '#0c3561',
                  }}
                >
                  <div
                    className={styles.userAndCardDetailContainer}
                    style={{ paddingBottom: 10 }}
                  >
                    <Field
                      id="cardholdername"
                      name="cardholdername"
                      label="card holder name"
                      type="text"
                      placeholder={cardholdername}
                      component={Input}
                    />
                    <Field
                      id="cardnumber"
                      name="cardnumber"
                      label="card number"
                      type="text"
                      placeholder="Card number"
                      component={Input}
                    />
                  </div>

                  <div
                    className={styles.userAndCardDetailContainer}
                    style={{ paddingBottom: 10 }}
                  >
                    <Field
                      id="expiry"
                      name="expiry"
                      label="expiry"
                      type="text"
                      placeholder="Expiry"
                      component={Input}
                    />
                    <Field
                      id="cvv"
                      name="cvv"
                      label="cvv"
                      type="text"
                      placeholder="CVV"
                      component={Input}
                    />
                  </div>
                </FormElement>
              )}
            />
            <span style={{ fontWeight: 'bold' }}>Another payment method</span>
            <hr />
            <div className={styles.cardsContainer}>
              <div>
                <RadioButton
                  name="group3"
                  disabled={true}
                  checked={false}
                  label="Credit or debit card"
                />
              </div>
              <div>
                <RadioButton
                  name="group3"
                  disabled={true}
                  checked={false}
                  label="Net Banking"
                />
              </div>

              <div>
                <RadioButton
                  name="group3"
                  disabled={true}
                  checked={true}
                  label="Cash on Delivery/Pay on Delivery"
                />
              </div>
            </div>
          </div>
        </div>
        <div className={styles.orderSummaryContainer}>
          <div className={styles.orderDetailContainer}>
            <span style={{ fontWeight: 'bold' }}>Order Summary</span>
            <hr />
            {orderDetails?.lineItems?.map((i: any, index: number) => (
              <>
                <div className={styles.orderItemContainer}>
                  <div className={styles.orderItemImageContainer}>
                    <img
                      style={{ height: 170 }}
                      src={i?.product?.[0]?.imageUrl}
                      alt={i?.product?.[0]?.productName}
                    />
                  </div>
                  <p>Qty: {i?.quantity}</p>
                </div>
              </>
            ))}
          </div>
          <div className={styles.amountContainer}>
            <div className={styles.subTotalContainer}>
              <div>Total Amount :</div>
              <div>$ {cartDetails?.orders?.[0]?.orderedTotal}</div>
            </div>
            <div className={styles.subTotalContainer}>
              <div>Delivery:</div>
              <div>$ 0.00</div>
            </div>
            <hr />
            <div className={styles.totalContainer}>
              <div>Order Total:</div>
              <div>$ {cartDetails?.orders?.[0]?.orderedTotal}</div>
            </div>

            <Button
              className={`glow ${styles.paymentButton}`}
              onClick={() => onCheckout()}
            >
              Pay now $ {cartDetails?.orders?.[0]?.orderedTotal}
            </Button>
          </div>
        </div>
      </div>
    </div>
  );
};
