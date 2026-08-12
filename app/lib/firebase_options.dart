// ARCHIVO GENERADO AUTOMÁTICAMENTE — NO EDITAR A MANO EN PRODUCCIÓN.
//
// Este es un placeholder. Reemplázalo ejecutando, en la raíz del
// proyecto (con el proyecto de Firebase ya creado en la consola):
//
//   dart pub global activate flutterfire_cli
//   flutterfire configure
//
// Ese comando sobrescribe este archivo con las credenciales reales de
// tu proyecto de Firebase para Web, Android e iOS.

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
    apiKey: 'TODO-reemplazar-con-flutterfire-configure',
    appId: 'TODO-reemplazar-con-flutterfire-configure',
    messagingSenderId: 'TODO-reemplazar-con-flutterfire-configure',
    projectId: 'delaraiz-app',
    authDomain: 'delaraiz-app.firebaseapp.com',
    storageBucket: 'delaraiz-app.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'TODO-reemplazar-con-flutterfire-configure',
    appId: 'TODO-reemplazar-con-flutterfire-configure',
    messagingSenderId: 'TODO-reemplazar-con-flutterfire-configure',
    projectId: 'delaraiz-app',
    storageBucket: 'delaraiz-app.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'TODO-reemplazar-con-flutterfire-configure',
    appId: 'TODO-reemplazar-con-flutterfire-configure',
    messagingSenderId: 'TODO-reemplazar-con-flutterfire-configure',
    projectId: 'delaraiz-app',
    storageBucket: 'delaraiz-app.appspot.com',
    iosBundleId: 'cl.laraiz.delaraiz',
  );
}
