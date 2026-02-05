// Firebase Cloud Messaging Service Worker
// 웹 푸시 알림 백그라운드 수신 처리
// firebase_options.dart의 web 설정과 동일한 값 사용
importScripts('https://www.gstatic.com/firebasejs/11.0.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/11.0.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyC7GHNBsS21CL7ZKa-5MGd_6ogOk4v8g4k',
  authDomain: 'letsmeet-8def5.firebaseapp.com',
  projectId: 'letsmeet-8def5',
  storageBucket: 'letsmeet-8def5.firebasestorage.app',
  messagingSenderId: '225419812075',
  appId: '1:225419812075:web:7421d1841d06782f8972ae',
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Background message:', payload);
  const title = payload.notification?.title || 'LetsMeet';
  const options = {
    body: payload.notification?.body || '',
    icon: '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',
    data: payload.data || {},
  };
  self.registration.showNotification(title, options);
});
