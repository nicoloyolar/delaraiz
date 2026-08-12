import 'package:cloud_firestore/cloud_firestore.dart';

/// Gasto rendido contra una postulación a fondo aprobada (subcolección
/// `postulaciones_fondos/{postulacionId}/rendiciones`).
class RendicionModel {
  final String? id;
  final String concepto;
  final double monto;
  final String? categoria;
  final DateTime? fecha;
  final String? comprobanteUrl;

  const RendicionModel({
    this.id,
    required this.concepto,
    required this.monto,
    this.categoria,
    this.fecha,
    this.comprobanteUrl,
  });

  factory RendicionModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return RendicionModel(
      id: doc.id,
      concepto: data['concepto'] as String? ?? '',
      monto: (data['monto'] as num?)?.toDouble() ?? 0,
      categoria: data['categoria'] as String?,
      fecha: (data['fecha'] as Timestamp?)?.toDate(),
      comprobanteUrl: data['comprobanteUrl'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'concepto': concepto,
      'monto': monto,
      'categoria': categoria,
      'fecha': fecha != null ? Timestamp.fromDate(fecha!) : FieldValue.serverTimestamp(),
      'comprobanteUrl': comprobanteUrl,
    };
  }
}
