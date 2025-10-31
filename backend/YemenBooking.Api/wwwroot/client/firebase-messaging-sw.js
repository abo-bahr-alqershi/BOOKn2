/* eslint-disable no-undef */
importScripts('https://www.gstatic.com/firebasejs/10.12.2/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.12.2/firebase-messaging-compat.js');

// TODO: replace with your Firebase web config
firebase.initializeApp({
  apiKey: "your-api-key",
  authDomain: "your-auth-domain",
  projectId: "your-project-id",
  storageBucket: "your-storage-bucket",
  messagingSenderId: "your-messaging-sender-id",
  appId: "your-app-id"
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage(function(payload) {
  const data = payload.data || {};
  const notificationTitle = (payload.notification && payload.notification.title) || 'New message';
  const notificationOptions = {
    body: (payload.notification && payload.notification.body) || '',
    icon: '/icons/chat-icon.png',
    data
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});

self.addEventListener('notificationclick', function(event) {
  event.notification.close();
  const data = event.notification.data || {};
  event.waitUntil(self.clients.matchAll({ type: 'window', includeUncontrolled: true }).then(function(clientList) {
    for (const client of clientList) {
      if ('focus' in client) {
        client.postMessage({ type: 'fcm-message', payload: data });
        return client.focus();
      }
    }
    if (self.clients.openWindow) {
      return self.clients.openWindow('/');
    }
  }));
});

