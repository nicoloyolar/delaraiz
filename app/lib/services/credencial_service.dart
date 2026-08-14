import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/credencial_model.dart';

/// Servicio de acceso a la colección `credenciales` — solo lectura desde la
/// app (ver comentario en [CredencialModel] y `firestore.rules`). Cada
/// documento lo escribe el sitio PHP mediante una cuenta de servicio, nunca
/// la app.
class CredencialService {
  CredencialService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  static const String _collectionPath = 'credenciales';

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(_collectionPath);

  /// El ID del documento es el correo del socio, siempre en minúsculas y
  /// sin espacios — mismo criterio que usa el sitio PHP al sincronizar, así
  /// que hay que normalizar igual acá para que ambos lados busquen el mismo
  /// documento.
  static String idDesdeCorreo(String email) => email.trim().toLowerCase();

  /// Transmite la credencial del socio con ese correo, o `null` si no
  /// existe ningún documento (ej. la persona nunca postuló, o su correo no
  /// coincide con el que usó al pagar en Flow).
  Stream<CredencialModel?> streamCredencial(String email) {
    final id = idDesdeCorreo(email);
    return _collection.doc(id).snapshots().map((doc) {
      if (!doc.exists) return null;
      return CredencialModel.fromFirestore(doc);
    });
  }
}
