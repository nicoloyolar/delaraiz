// ARCHIVO GENERADO AUTOMÁTICAMENTE POR `flutterfire configure` — NO EDITAR A
// MANO. Credenciales REALES del proyecto de Firebase `delaraiz-app`
// (conectado 2026-08-17/18) — ya no es un placeholder. Si algún día se
// recrea el proyecto o se agrega otra plataforma, volver a correr:
//
//   flutterfire configure -p delaraiz-app

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions no ha sido configurado para esta plataforma. '
          'Ejecuta `flutterfire configure` para generar las credenciales.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDjGPRcsVFAUpzx4RSjKSmz9A0M5CWJqxY',
    appId: '1:490044936327:web:a65955df18c58192f3e822',
    messagingSenderId: '490044936327',
    projectId: 'delaraiz-app',
    authDomain: 'delaraiz-app.firebaseapp.com',
    storageBucket: 'delaraiz-app.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDk0YDoR-jg9x39SyaKFWoZ0c73ffs5DwM',
    appId: '1:490044936327:android:a2629574c4f5cc82f3e822',
    messagingSenderId: '490044936327',
    projectId: 'delaraiz-app',
    storageBucket: 'delaraiz-app.firebasestorage.app',
  );
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDfT-o4ZF-6AerdESOn42Z6iv5lDxsKrdU',
    appId: '1:490044936327:ios:98696d1f7e88e6aaf3e822',
    messagingSenderId: '490044936327',
    projectId: 'delaraiz-app',
    storageBucket: 'delaraiz-app.firebasestorage.app',
    iosBundleId: 'cl.laraiz.delaraiz',
  );
}
