import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/app_colors.dart';
import '../../app/app_palette.dart';
import '../../models/credencial_model.dart';
import '../../providers/providers.dart';
import '../../utils/validators.dart';
import '../../widgets/pill.dart';
import 'cupon_acceso_widget.dart';

/// Credencial digital de socio — agregado 2026-08-12.
///
/// A diferencia del Dashboard admin, esta pantalla SÍ permite auto-registro
/// (cualquiera puede crear una cuenta con su correo), porque no es viable
/// crear a mano la cuenta de cada persona que se suscribe en `/membresia/`
/// del sitio PHP. Tener una cuenta acá no da ningún acceso administrativo —
/// eso lo decide `firestore.rules` aparte (ver `esAdminActivo()`).
///
/// Estados posibles:
/// 1. Sin sesión → formulario de login/registro.
/// 2. Con sesión, sin credencial encontrada para ese correo → aviso.
/// 3. Con sesión y credencial encontrada → la credencial en vivo.
class CredencialScreen extends ConsumerWidget {
  const CredencialScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mi credencial')),
      body: authState.when(
        data: (user) => user == null
            ? const _FormularioAcceso()
            : const _VistaCredencial(),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
    );
  }
}

class _FormularioAcceso extends ConsumerStatefulWidget {
  const _FormularioAcceso();

  @override
  ConsumerState<_FormularioAcceso> createState() => _FormularioAccesoState();
}

class _FormularioAccesoState extends ConsumerState<_FormularioAcceso> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _esRegistro = false;
  bool _cargando = false;
  String? _error;
  String? _mensajeRecuperacion;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  /// Recuperar contraseña — agregado 2026-09-23 (antes no existía ningún
  /// camino para esto). Usa el mismo campo de email ya escrito, para no
  /// pedir el dato dos veces.
  Future<void> _recuperarContrasena() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      setState(() => _error = 'Escribe tu correo arriba primero, para saber a dónde mandar el link.');
      return;
    }
    setState(() {
      _cargando = true;
      _error = null;
      _mensajeRecuperacion = null;
    });
    try {
      await ref.read(authServiceProvider).enviarCorreoRecuperacion(email);
      if (mounted) {
        setState(() => _mensajeRecuperacion =
            'Si existe una cuenta con ese correo, te mandamos un link para cambiar tu contraseña — revisa spam también.');
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() => _error = ref.read(authServiceProvider).mensajeError(e));
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _enviar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _cargando = true;
      _error = null;
    });

    final authService = ref.read(authServiceProvider);
    try {
      if (_esRegistro) {
        await authService.crearCuenta(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
        );
      } else {
        await authService.signIn(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
        );
      }
      // No hace falta navegar a mano: CredencialScreen observa
      // authStateProvider y cambia sola a _VistaCredencial.
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() => _error = authService.mensajeError(e));
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Icons.badge_outlined, size: 48, color: AppColors.accent),
                const SizedBox(height: 16),
                Text(
                  _esRegistro ? 'Crea tu cuenta de socio' : 'Ingresa a tu credencial',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Usa el mismo correo con el que te suscribiste en /membresia/.',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                if (_error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      _error!,
                      style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                if (_mensajeRecuperacion != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.seleccionadaSoft,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(_mensajeRecuperacion!, textAlign: TextAlign.center),
                  ),
                  const SizedBox(height: 16),
                ],
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Correo'),
                  validator: Validators.email,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Contraseña'),
                  validator: (v) => Validators.requerido(v, campo: 'La contraseña'),
                  onFieldSubmitted: (_) => _enviar(),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _cargando ? null : _enviar,
                  child: _cargando
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(_esRegistro ? 'Crear cuenta' : 'Ingresar'),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _cargando
                      ? null
                      : () => setState(() {
                            _esRegistro = !_esRegistro;
                            _error = null;
                            _mensajeRecuperacion = null;
                          }),
                  child: Text(
                    _esRegistro
                        ? '¿Ya tienes cuenta? Inicia sesión'
                        : '¿Primera vez? Crea tu cuenta',
                  ),
                ),
                if (!_esRegistro)
                  TextButton(
                    onPressed: _cargando ? null : _recuperarContrasena,
                    child: const Text('¿Olvidaste tu contraseña?'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _VistaCredencial extends ConsumerWidget {
  const _VistaCredencial();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final credencialAsync = ref.watch(credencialActualProvider);

    return credencialAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
      data: (credencial) {
        if (credencial == null) {
          return _SinCredencial(email: FirebaseAuth.instance.currentUser?.email ?? '');
        }
        return _TarjetaCredencial(credencial: credencial);
      },
    );
  }
}

class _SinCredencial extends ConsumerWidget {
  const _SinCredencial({required this.email});

  final String email;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search_off, size: 48, color: context.colors.textMuted),
              const SizedBox(height: 16),
              Text(
                'No encontramos una membresía activa para $email.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              const Text(
                'Si acabas de postular en /membresia/, puede tardar unos minutos en '
                'reflejarse acá. Si el problema persiste, escríbenos.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () => ref.read(authServiceProvider).signOut(),
                child: const Text('Cerrar sesión'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TarjetaCredencial extends ConsumerWidget {
  const _TarjetaCredencial({required this.credencial});

  final CredencialModel credencial;

  Color get _colorEstado {
    switch (credencial.estado) {
      case EstadoCredencial.activo:
        return AppColors.seleccionada;
      case EstadoCredencial.pendiente:
      case EstadoCredencial.moroso:
        return AppColors.pendiente;
      case EstadoCredencial.cancelado:
      case EstadoCredencial.rechazado:
        return AppColors.rechazada;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Formato numérico, sin nombres de mes: igual que el resto de la app
    // (ver banda_card.dart, proyecto_info_tab.dart, etc.) — usar 'MMMM'
    // (nombre del mes en letras) requeriría inicializar datos de locale
    // ('es') que este proyecto no inicializa en ningún lado todavía.
    final formatoFecha = DateFormat('dd/MM/yyyy');

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: AppColors.accentSoft,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(Icons.badge, color: AppColors.accent, size: 28),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Corporación de La Raíz',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                Text(
                                  credencial.nombre.isEmpty ? credencial.email : credencial.nombre,
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Pill(label: 'Socio ${credencial.plan.label}', color: AppColors.accent),
                          const SizedBox(width: 8),
                          Pill(label: credencial.estado.label, color: _colorEstado),
                        ],
                      ),
                      if (credencial.estado == EstadoCredencial.activo &&
                          credencial.proximoCobro != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          'Próximo cobro: ${formatoFecha.format(credencial.proximoCobro!)}',
                          style: TextStyle(color: context.colors.textSecondary),
                        ),
                      ],
                      if (credencial.activadoEn != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Socio desde: ${formatoFecha.format(credencial.activadoEn!)}',
                          style: TextStyle(color: context.colors.textMuted, fontSize: 12),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tus beneficios', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 12),
                      // Encontrado en la auditoría de "Credencial del
                      // Suscriptor" (2026-09-23): antes esta lista se
                      // mostraba igual de completa aunque el estado fuera
                      // "cancelado"/"rechazado" — solo el Pill de arriba
                      // cambiaba de color, nada acá avisaba que ya no
                      // aplican.
                      if (credencial.estado != EstadoCredencial.activo)
                        Text(
                          'Tus beneficios no están disponibles mientras la membresía '
                          'no esté activa.',
                          style: TextStyle(color: context.colors.textMuted, fontStyle: FontStyle.italic),
                        )
                      else
                        ...credencial.plan.beneficios.map(
                          (beneficio) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.check_circle, size: 18, color: AppColors.seleccionada),
                                const SizedBox(width: 8),
                                Expanded(child: Text(beneficio)),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              CuponAccesoSection(credencial: credencial),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => ref.read(authServiceProvider).signOut(),
                child: const Text('Cerrar sesión'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
