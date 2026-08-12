/// Validadores de campos reutilizados por los formularios de la app.
class Validators {
  Validators._();

  static final RegExp _emailRegex =
      RegExp(r'^[\w\.\-]+@[\w\-]+\.[\w\-.]+$');

  // Acepta formatos comunes chilenos: +56912345678, 912345678, 22 2345678, etc.
  static final RegExp _phoneRegex = RegExp(r'^[+]?[\d\s]{8,15}$');

  static String? requerido(String? value, {String campo = 'Este campo'}) {
    if (value == null || value.trim().isEmpty) {
      return '$campo es obligatorio.';
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El correo es obligatorio.';
    }
    if (!_emailRegex.hasMatch(value.trim())) {
      return 'Ingresa un correo válido.';
    }
    return null;
  }

  static String? telefono(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El teléfono es obligatorio.';
    }
    if (!_phoneRegex.hasMatch(value.trim())) {
      return 'Ingresa un teléfono válido.';
    }
    return null;
  }

  /// Valida el formato y dígito verificador de un RUT chileno
  /// (acepta con o sin puntos, con guión antes del dígito verificador).
  static String? rutChileno(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El RUT es obligatorio.';
    }
    final limpio = value.replaceAll('.', '').replaceAll('-', '').trim().toUpperCase();
    if (limpio.length < 2) return 'Ingresa un RUT válido.';

    final cuerpo = limpio.substring(0, limpio.length - 1);
    final dv = limpio.substring(limpio.length - 1);
    if (!RegExp(r'^\d+$').hasMatch(cuerpo)) return 'Ingresa un RUT válido.';

    int suma = 0;
    int multiplicador = 2;
    for (int i = cuerpo.length - 1; i >= 0; i--) {
      suma += int.parse(cuerpo[i]) * multiplicador;
      multiplicador = multiplicador == 7 ? 2 : multiplicador + 1;
    }
    final resto = 11 - (suma % 11);
    final dvEsperado = switch (resto) {
      11 => '0',
      10 => 'K',
      _ => resto.toString(),
    };

    if (dv != dvEsperado) return 'El RUT ingresado no es válido.';
    return null;
  }

  /// Para enlaces opcionales: si el usuario escribió algo, debe parecer
  /// una URL válida; si dejó el campo vacío, se acepta (no es obligatorio).
  static String? urlOpcional(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final uri = Uri.tryParse(value.trim());
    if (uri == null || !(uri.isScheme('HTTP') || uri.isScheme('HTTPS'))) {
      return 'Ingresa una URL válida (debe comenzar con http:// o https://).';
    }
    return null;
  }
}
