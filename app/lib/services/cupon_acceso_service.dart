import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../models/cupon_acceso_model.dart';

/// Cupón de acceso QR de Embajador — agregado 2026-09-23 (diseño confirmado
/// con la directiva, PROYECTO.md sección 9.15/9.25). La generación es un
/// escritura directa a Firestore (el propio socio crea su propio cupón, ver
/// `firestore.rules`) — a diferencia de la validación (que consume el
/// cupón), que pasa por el sitio PHP porque quien valida en el local no
/// tiene cuenta de Firebase (ver `ValidarCuponScreen`).
class CuponAccesoService {
  CuponAccesoService({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  static const String _collectionPath = 'cupones_acceso';
  static const _uuid = Uuid();

  CollectionReference<Map<String, dynamic>> get _collection => _firestore.collection(_collectionPath);

  /// El cupón vigente del socio, si tiene uno — usado tanto para mostrarlo
  /// en su credencial como para bloquear la generación de uno nuevo mientras
  /// el actual no expire o se use.
  Stream<CuponAccesoModel?> streamVigentePropio(String email) {
    return _collection
        .where('socioEmail', isEqualTo: email.trim().toLowerCase())
        .where('estado', isEqualTo: 'vigente')
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      final cupon = CuponAccesoModel.fromFirestore(snapshot.docs.first);
      // Un cupón vigente-pero-ya-expirado no cuenta como "tiene uno activo"
      // — dejarlo bloqueando la generación de uno nuevo para siempre sería
      // un candado sin llave (nada lo pasa a "expirado" activamente).
      return cupon.estaVigente ? cupon : null;
    });
  }

  /// Crea un cupón nuevo — código largo y aleatorio (UUID v4, no adivinable),
  /// vigente por 12 horas desde ahora. No revalida acá que el socio no tenga
  /// ya uno vigente (la pantalla ya lo bloquea con [streamVigentePropio]) —
  /// una carrera exacta entre 2 clics es un caso extremo aceptable para esta
  /// funcionalidad de bajo volumen, no justifica una Cloud Function aparte.
  Future<void> crear({
    required String socioEmail,
    required String socioNombre,
    required String localId,
    required String localNombre,
  }) {
    final codigo = _uuid.v4().replaceAll('-', '');
    final ahora = DateTime.now();
    return _collection.doc(codigo).set({
      'socioEmail': socioEmail.trim().toLowerCase(),
      'socioNombre': socioNombre,
      'localId': localId,
      'localNombre': localNombre,
      'generadoEn': Timestamp.fromDate(ahora),
      'expiraEn': Timestamp.fromDate(ahora.add(const Duration(hours: 12))),
      'estado': 'vigente',
    });
  }
}
