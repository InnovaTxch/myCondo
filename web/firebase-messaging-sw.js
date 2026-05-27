/* global importScripts, firebase, self */

importScripts('https://www.gstatic.com/firebasejs/11.4.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/11.4.0/firebase-messaging-compat.js');

const firebaseConfig = {
  apiKey: 'AIzaSyB_0ddF9T9nsvZFUpBNbmvDajJGmGFu5Eo',
  authDomain: 'mycondo-356a3.firebaseapp.com',
  projectId: 'mycondo-356a3',
  storageBucket: 'mycondo-356a3.firebasestorage.app',
  messagingSenderId: '214731689591',
  appId: '1:214731689591:web:d6c75cb86379d36f810072',
  measurementId: 'G-4CPSB8TDPW',
};

firebase.initializeApp(firebaseConfig);
const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  const title =
    payload?.notification?.title || payload?.data?.title || 'myCondo';
  const body =
    payload?.notification?.body ||
    payload?.data?.body ||
    'You have a new notification.';

  self.registration.showNotification(title, {
    body,
    icon: 'icons/Icon-192.png',
    data: payload?.data || {},
  });
});
