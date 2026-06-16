import { FC, useEffect, useState } from 'react';
import { Button } from '@progress/kendo-react-buttons';
import axios from 'axios';
import styles from './styles.module.scss';
import { Payment } from '../Payment';
import { EmptyCartIcon } from 'assets';
import { useAppSelector } from 'hooks';

const { OrderAPI, CustomerId } = window.config;

interface Props {
  address: any;
  onGoBack: () => void;
  cartLoading: boolean;
  cartDetails: any;
  orderDetails: any;
  getCart: () => void;
  paymentFailedDemo?: boolean;
  onShoppingPageGoBack: () => void;
}

export const Cart: FC<Props> = ({
  onGoBack,
  address,
  cartLoading,
  cartDetails,
  orderDetails,
  getCart,
  paymentFailedDemo,
  onShoppingPageGoBack,
}) => {
  const [showPayment, setShowPayment] = useState(false);
  const { reImaginedDemoComplete, reImaginedScalingDemoComplete } =
    useAppSelector((state) => state.config);

  const onCartRemove = (data: any) => {
    axios
      .delete(
        `${OrderAPI}/Cart/${CustomerId}/${cartDetails?.orders?.[0]?.id}/${data?.product?.[0]?.productId}`
      )
      .then((res) => {})
      .catch((err) => {})
      .finally(() => getCart());
  };

  return showPayment ? (
    <Payment
      address={address}
      cartDetails={cartDetails}
      orderDetails={orderDetails}
      onGoBack={() => {
        setShowPayment(false);
        onGoBack();
      }}
      paymentFailedDemo={paymentFailedDemo}
    />
  ) : !cartLoading && !orderDetails?.lineItems?.length ? (
    <div className={styles.popupContainer}>
      <div className={styles.checkoutPopup}>
        <EmptyCartIcon />
        <h2>Looks like your care it empty!</h2>
        <Button className={styles.backButton} onClick={onShoppingPageGoBack}>
          Go to Shopping Page
        </Button>
      </div>
    </div>
  ) : orderDetails?.lineItems?.length > 0 ? (
    <div className={`${styles.container}`}>
      <div className={styles.cartContainer}>
        <div className={styles.cartTitle}>
          My Cart{' '}
          {orderDetails?.lineItems?.length > 0 && (
            <span>
              ({orderDetails?.lineItems?.length}{' '}
              {orderDetails?.lineItems?.length > 1 ? 'Items' : 'Item'})
            </span>
          )}
        </div>

        <div className={styles.productsContainer}>
          {orderDetails?.lineItems?.map((i: any, index: number) => (
            <>
              <div className={styles.productContainer}>
                <div className={styles.productDetail}>
                  <img
                    style={{ height: 175 }}
                    src={i?.product?.[0]?.imageUrl}
                    alt={i?.product?.[0]?.productName}
                  />
                  <div className={styles.metadata}>
                    <div>
                      <p className={styles.productName}>
                        {i?.product?.[0]?.productName}
                      </p>
                    </div>
                    <p className={styles.quantity}>Quantity: {i?.quantity}</p>
                    <p
                      className={styles.remove}
                      onClick={() => onCartRemove(i)}
                    >
                      Remove
                    </p>
                  </div>
                </div>
                <div className={styles.orderDetail}>${i?.lineAmount} </div>
              </div>
              {/* {index + 1 !== orderDetails?.lineItems?.length && (
              <div className={styles.lineBreak}></div>
            )} */}
            </>
          ))}
        </div>
      </div>
      {cartDetails?.orders?.[0]?.orderedTotal > 0 && (
        <div className={styles.checkoutContainer}>
          <div className={styles['checkout-header']}>ORDER DETAILS</div>

          <div className={styles['checkout-table']}>
            <div className={styles['table-col']} style={{ fontSize: 18 }}>
              <div style={{ fontWeight: 600 }}>PRICE</div>
              <div style={{ fontWeight: 600 }}>TOTAL</div>
            </div>
            <div className={styles.horizontalLine} />
            <div className={styles['table-col']} style={{ fontWeight: 600 }}>
              <div>$ {cartDetails?.orders?.[0]?.orderedTotal}</div>
              <div>$ {cartDetails?.orders?.[0]?.orderedTotal}</div>
            </div>
            <div className={styles.horizontalLine} />
            <div className={styles['table-col']}>
              <div>SUBTOTAL</div>
              <div style={{ fontWeight: 600 }}>
                $ {cartDetails?.orders?.[0]?.orderedTotal}
              </div>
            </div>
            <div className={styles.horizontalLine} />
            <div className={styles['table-col']}>
              <div>ESTIMATED TOTAL</div>
              <div style={{ fontWeight: 600 }}>
                $ {cartDetails?.orders?.[0]?.orderedTotal}
              </div>
            </div>
            <div style={{ paddingTop: 40 }}>
              <button
                className={`${
                  !reImaginedDemoComplete &&
                  !reImaginedScalingDemoComplete &&
                  'glow'
                } ${styles['checkout-btn']}`}
                onClick={() => setShowPayment(true)}
              >
                PROCEED TO CHECKOUT
              </button>
            </div>
            <div className={styles['contact-info']}>
              <div>
                NEED ASSISTANT? <strong>EMAIL US</strong>
              </div>
              <div>
                ALL TRANSACTIONS ARE SAFE AND SECURE.{' '}
                <strong>SECURITY POLICY</strong>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  ) : (
    <></>
  );
};
