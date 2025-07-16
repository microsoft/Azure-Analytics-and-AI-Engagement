import styles from '../OrderDetails/styles.module.scss';
import { FC, useEffect, useState } from 'react';
import { OrderDetail, Order, ProductDetail } from '../../../types/order.models';

const { OrderAPI } = window.config;

export const OrderDetails: FC<any> = ({ orderId, orderTotal }) => {
  const [orderDetail, setOrderDetail] = useState<OrderDetail>();

  const getOrderDetail = (orderId: String) => {
    fetch(OrderAPI + '/Order/' + orderId)
      .then((res) => res.json())
      .then((res) => {
        if (res) {
          let orderInfo: Order = {
            id: res.id,
            orderedOn: res.orderedOn,
            orderedTotal: res.orderedTotal,
            status: res.status,
            shippedOn: res.shippedOn,
          };

          let detail: OrderDetail = {
            order: orderInfo,
            items: res.lineItems,
          };

          setOrderDetail(detail);
        }
      });
  };

  useEffect(() => {
    getOrderDetail(orderId);
  }, [orderId]);
  return (
    <div className={styles.container}>
      <table>
        <thead>
          <tr className={styles.headerRow}>
            <th className={styles.orderIdColumn}>Order Id</th>
            <th className={styles.statusColumn}>Status</th>
            <th className={styles.orderDateColumn}>Ordered On</th>
            <th className={styles.orderTotalColumn}>Order Total</th>
            <th style={{ width: 50 }}></th>
          </tr>
        </thead>
        <tbody>
          <tr>
            <td>{orderDetail?.order?.id}</td>
            <td>{orderDetail?.order?.status} </td>
            <td>
              {orderDetail &&
              orderDetail.order &&
              orderDetail.order.orderedOn !== undefined
                ? new Date(orderDetail.order.orderedOn).toLocaleDateString()
                : ''}{' '}
            </td>
            <td>{orderTotal}</td>
            <td>
              <span
                className="k-icon k-i-arrow-chevron-up"
                style={{ opacity: 0.4 }}
              />{' '}
            </td>
          </tr>
        </tbody>
      </table>
      <hr style={{ marginBottom: 0 }}></hr>
      <div className={styles.itemContainer}>
        {orderDetail?.items?.map((lineItem: ProductDetail, index) => (
          <div
            className={styles.lineItemContainer}
            key={lineItem.product[0].productId + '_' + index}
          >
            <div className={styles.userImage}>
              <img
                src={lineItem?.product[0].imageUrl}
                alt={lineItem?.product[0].productName}
              />
            </div>
            <div className={styles.productIdColumn}>
              <p className={styles.header}>Product Id</p>
              <p className={styles.text}>{lineItem?.product[0].productId}</p>
            </div>
            <div className={styles.productNameColumn}>
              <p className={styles.header}>Product Name</p>
              <p className={styles.text}>{lineItem?.product[0].productName}</p>
            </div>
            <div className={styles.quantityColumn}>
              <p className={styles.header}>Quantity</p>
              <p className={styles.text}>{String(lineItem?.quantity)}</p>
            </div>
            <div className={styles.amountColumn}>
              <p className={styles.header}>Amount</p>
              <p className={styles.text}>${String(lineItem?.lineAmount)}</p>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
};
