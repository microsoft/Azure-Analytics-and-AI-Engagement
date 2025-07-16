import axios from 'axios';
import { FC, useEffect, useState } from 'react';
// import {
//   Notification as KendoNotification,
//   NotificationGroup,
// } from '@progress/kendo-react-notification';
// import { Fade } from '@progress/kendo-react-animation';

const { APIUrl } = window.config;

interface Props {
  message: any;
  setMessage: React.Dispatch<React.SetStateAction<any>>;
}

export const Notification: FC<Props> = ({ message, setMessage }) => {
  const [socket, setSocket] = useState<any>(null);

  useEffect(() => {
    axios
      .get(APIUrl + '/api/get_ws_url')
      .then((res) => {
        // Create a WebSocket connection when the component mounts
        const newSocket = new WebSocket(res.data); // Replace with your WebSocket server URL

        newSocket.onopen = () => {
          console.log('WebSocket connection established');
          setSocket(newSocket);
        };

        newSocket.onmessage = (event) => {
          // setShow(true);
          const receivedMessage = event.data;
          setMessage(JSON.parse(receivedMessage));
        };

        newSocket.onclose = () => {
          console.log('WebSocket connection closed');
        };

        newSocket.onerror = (error) => {
          console.error('WebSocket error:', error);
        };

        // Clean up the WebSocket connection when the component unmounts
        return () => {
          if (socket) {
            socket.close();
          }
        };
      })
      .catch((err) => console.log({ err }));
  }, []);

  // useEffect(() => {
  // if (message) setTimeout(() => setShow(false), 5000);
  // }, [message]);

  return (
    <div>
      {/* <NotificationGroup
        style={{
          top: 70,
          right: 20,
          alignItems: 'flex-start',
          flexWrap: 'wrap-reverse',
        }}
      >
        <Fade>
          {show && message?.text && (
            <KendoNotification
              type={{ style: 'success', icon: true }}
              closable={true}
              onClose={() => setShow(false)}
            >
              <span>{message?.text}</span>
            </KendoNotification>
          )}
        </Fade>
      </NotificationGroup> */}
    </div>
  );
};
