// Firebase Cloud Messaging Service Worker
// This file handles background notifications for the SmartBin app

importScripts('https://www.gstatic.com/firebasejs/9.0.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/9.0.0/firebase-messaging-compat.js');

// Initialize Firebase in the service worker
firebase.initializeApp({
  apiKey: 'AIzaSyCO8ru2HgT_AIs25e3Jrr6TNWNa3LJua0A',
  authDomain: 'smartbin-c8ef7.firebaseapp.com',
  projectId: 'smartbin-c8ef7',
  storageBucket: 'smartbin-c8ef7.firebasestorage.app',
  messagingSenderId: '431080313189',
  appId: '1:431080313189:web:1004f0ddb812225d48918c'
});

// Retrieve an instance of Firebase Messaging
const messaging = firebase.messaging();

// Handle background messages
messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Received background message:', payload);
  
  const notificationTitle = payload.notification.title || 'SmartBin Alert';
  const notificationOptions = {
    body: payload.notification.body || 'You have a new notification',
    icon: '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',
    tag: 'smartbin-notification',
    requireInteraction: false,
    data: payload.data
  };

  return self.registration.showNotification(notificationTitle, notificationOptions);
});

// Handle notification clicks
self.addEventListener('notificationclick', (event) => {
  console.log('[firebase-messaging-sw.js] Notification clicked:', event);
  event.notification.close();

  // Open the app when notification is clicked
  event.waitUntil(
    clients.openWindow('/')
  );
});
