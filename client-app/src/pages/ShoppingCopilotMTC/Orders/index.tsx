import styles from './styles.module.scss';
import React, { FC } from 'react';
import { Order, OrderHistory } from '../../../types/order.models';

interface Props {
  orderHistory: OrderHistory;
  onOrderItemExpanded: (value: string, value2: string) => void;
}

export const Orders: FC<Props> = ({ orderHistory, onOrderItemExpanded }) => {
  return (
    <React.Fragment>
      {orderHistory && (
        <div className={styles.container}>
          <div className={styles.topContainer}>
            <div className={styles.userImage}>
              <img
                src={orderHistory.profileImageUrl}
                alt={orderHistory.emailAddress}
              />
            </div>
            <div>
              <div className={styles.userDetailContainer}>
                <div>
                  <p className={styles.header}>Name</p>
                  <p className={styles.text}>
                    {orderHistory.firstName} {orderHistory.lastName}
                  </p>
                </div>
                <div>
                  <p className={styles.header}>Phone</p>
                  <p className={styles.text}>{orderHistory.phoneNumber}</p>
                </div>
                <div>
                  <p className={styles.header}>Email</p>
                  <p className={styles.text}>{orderHistory.emailAddress}</p>
                </div>
              </div>
              <div className={styles.addressContainer}>
                <p className={styles.header}>Address</p>
                {orderHistory.addresses && (
                  <p className={styles.text}>
                    {orderHistory.addresses[0].addressLine1},{' '}
                    {orderHistory.addresses[0].city},{' '}
                    {orderHistory.addresses[0].state},{' '}
                    {orderHistory.addresses[0].zipCode}
                  </p>
                )}
              </div>
            </div>
          </div>

          <div className={styles.horizontalLine}></div>
          <div className={styles.tableContainer}>
            <table>
              <thead>
                <tr>
                  <th className={styles.orderIdColumn}>Order Id</th>
                  <th className={styles.statusColumn}>Status</th>
                  <th className={styles.orderDateColumn}>Ordered On</th>
                  <th className={styles.orderTotalColumn}>Order Total</th>
                  <th style={{ width: 50 }}></th>
                </tr>
              </thead>
              <tbody>
                {orderHistory &&
                  orderHistory.orders &&
                  orderHistory.orders.map((order: Order, index) => (
                    <tr role="row" key={order.id}>
                      <td>{order.id}</td>
                      <td>{order.status} </td>
                      <td>{new Date(order.orderedOn).toLocaleDateString()} </td>
                      <td>{String(order.orderedTotal)} </td>
                      <td>
                        <span
                          onClick={() =>
                            onOrderItemExpanded(
                              order.id,
                              order?.orderedTotal?.toString()
                            )
                          }
                          className="k-icon k-i-arrow-chevron-down"
                          style={{ opacity: 0.4, paddingRight: 10 }}
                        />{' '}
                      </td>
                    </tr>
                  ))}
              </tbody>
            </table>
          </div>
        </div>
      )}
    </React.Fragment>
  );
};
