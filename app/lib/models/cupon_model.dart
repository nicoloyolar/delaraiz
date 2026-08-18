/// Cupón de descuento para membresías — agregado 2026-08-18, a pedido del
/// usuario para que la directiva pueda aportar con un % de descuento (hasta
/// 100%, o sea $0 de cobro real) sin dejar de pasar por el flujo real de
/// Flow. El cupón real vive en Flow (`/coupon/create`); este modelo refleja
/// el CPT `cdlr_cupon` del sitio PHP, que es la libreta que relaciona un
/// código legible con el ID numérico de Flow — no vive en Firestore, por
/// eso este modelo no tiene un `fromFirestore()` como el resto de la app.
class CuponModel {
  final int id;
  final String codigo;
  final int flowCouponId;
  final double descuentoPct;
  final int usosMaximos;
  final int usosActuales;
  final bool activo;
  final String expira;
  final String creadoEn;

  const CuponModel({
    required this.id,
    required this.codigo,
    required this.flowCouponId,
    required this.descuentoPct,
    required this.usosMaximos,
    required this.usosActuales,
    required this.activo,
    required this.expira,
    required this.creadoEn,
  });

  bool get esIlimitado => usosMaximos == 0;

  bool get expirado {
    if (expira.isEmpty) return false;
    final fecha = DateTime.tryParse(expira);
    return fecha != null && fecha.isBefore(DateTime.now());
  }

  factory CuponModel.fromJson(Map<String, dynamic> json) {
    return CuponModel(
      id: (json['id'] as num).toInt(),
      codigo: json['codigo'] as String? ?? '',
      flowCouponId: (json['flowCouponId'] as num?)?.toInt() ?? 0,
      descuentoPct: (json['descuentoPct'] as num?)?.toDouble() ?? 0,
      usosMaximos: (json['usosMaximos'] as num?)?.toInt() ?? 0,
      usosActuales: (json['usosActuales'] as num?)?.toInt() ?? 0,
      activo: json['activo'] as bool? ?? false,
      expira: json['expira'] as String? ?? '',
      creadoEn: json['creadoEn'] as String? ?? '',
    );
  }
}
