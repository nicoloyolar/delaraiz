import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/actividad_model.dart';
import '../models/banda_model.dart';
import '../models/bitacora_entry_model.dart';
import '../models/componente_model.dart';
import '../models/credencial_model.dart';
import '../models/cupon_acceso_model.dart';
import '../models/cupon_model.dart';
import '../models/documento_model.dart';
import '../models/espacio_model.dart';
import '../models/evento_model.dart';
import '../models/local_model.dart';
import '../models/persona_model.dart';
import '../models/postulacion_fondo_model.dart';
import '../models/proyecto_miembro_model.dart';
import '../models/proyecto_model.dart';
import '../models/rendicion_model.dart';
import '../services/auth_service.dart';
import '../services/banda_service.dart';
import '../services/credencial_service.dart';
import '../services/cupon_acceso_service.dart';
import '../services/cupones_service.dart';
import '../services/documento_service.dart';
import '../services/espacio_service.dart';
import '../services/evento_service.dart';
import '../services/fondo_service.dart';
import '../services/local_service.dart';
import '../services/persona_service.dart';
import '../services/proyecto_service.dart';
import '../services/socios_admin_service.dart';
import '../services/theme_service.dart';

/// --- Servicios (singletons de la app) ---

final bandaServiceProvider = Provider<BandaService>((ref) => BandaService());

final documentoServiceProvider = Provider<DocumentoService>((ref) => DocumentoService());

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final proyectoServiceProvider = Provider<ProyectoService>((ref) => ProyectoService());

final espacioServiceProvider = Provider<EspacioService>((ref) => EspacioService());

final eventoServiceProvider = Provider<EventoService>((ref) => EventoService());

final personaServiceProvider = Provider<PersonaService>((ref) => PersonaService());

final fondoServiceProvider = Provider<FondoService>((ref) => FondoService());

final credencialServiceProvider = Provider<CredencialService>((ref) => CredencialService());

final sociosAdminServiceProvider = Provider<SociosAdminService>((ref) => SociosAdminService());

final cuponesServiceProvider = Provider<CuponesService>((ref) => CuponesService());

final themeServiceProvider = Provider<ThemeService>((ref) => ThemeService());

/// --- Modo claro/oscuro (agregado 2026-08-24) ---

/// Controla el [ThemeMode] activo y lo persiste vía [ThemeService] cada vez
/// que cambia. Se inicializa en `main()` con el valor ya cargado desde
/// `SharedPreferences` (override del provider), para no mostrar un
/// parpadeo con el modo por defecto antes de aplicar el guardado.
class ThemeModeController extends StateNotifier<ThemeMode> {
  ThemeModeController(this._service, [ThemeMode inicial = ThemeMode.dark]) : super(inicial);

  final ThemeService _service;

  Future<void> cambiar(ThemeMode mode) async {
    state = mode;
    await _service.guardar(mode);
  }
}

final themeModeProvider = StateNotifierProvider<ThemeModeController, ThemeMode>((ref) {
  return ThemeModeController(ref.watch(themeServiceProvider));
});

/// --- Autenticación ---

/// Emite el usuario actual cada vez que cambia la sesión. El router lo
/// observa para decidir si redirige a `/admin/login` o al dashboard, y la
/// pantalla de credencial lo usa para saber si mostrar el login/registro o
/// la credencial ya activa.
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

/// --- Credencial digital de socio (agregado 2026-08-12) ---

/// La credencial del socio autenticado actualmente, o `null` si no hay
/// sesión iniciada o no existe ningún documento para su correo. Se
/// recalcula solo cuando cambia la sesión (no es un `.family` por email
/// suelto, para no tener que pasarle el correo a mano desde cada pantalla).
final credencialActualProvider = StreamProvider.autoDispose<CredencialModel?>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user?.email == null) {
    return Stream.value(null);
  }
  return ref.watch(credencialServiceProvider).streamCredencial(user!.email!);
});

/// --- Mantenedor de Socios (panel admin, agregado 2026-08-14) ---

final sociosStreamProvider = StreamProvider.autoDispose<List<CredencialModel>>((ref) {
  return ref.watch(sociosAdminServiceProvider).streamSocios();
});

/// --- Cupones de descuento (agregado 2026-08-18) ---
///
/// No es un StreamProvider como el resto de la app: los cupones no viven en
/// Firestore (ver `CuponesService`), así que no hay un stream en vivo al que
/// suscribirse. Después de crear un cupón o cambiarle el estado, la pantalla
/// llama `ref.invalidate(cuponesListProvider)` para refrescar la lista.
final cuponesListProvider = FutureProvider.autoDispose<List<CuponModel>>((ref) {
  return ref.watch(cuponesServiceProvider).listar();
});

/// --- Locales adheridos + cupón de acceso QR de Embajador (agregado 2026-09-23) ---

final localServiceProvider = Provider<LocalService>((ref) => LocalService());

final cuponAccesoServiceProvider = Provider<CuponAccesoService>((ref) => CuponAccesoService());

final localesTodosProvider = StreamProvider.autoDispose<List<LocalModel>>((ref) {
  return ref.watch(localServiceProvider).streamTodos();
});

final localesActivosProvider = StreamProvider.autoDispose<List<LocalModel>>((ref) {
  return ref.watch(localServiceProvider).streamActivos();
});

/// El cupón vigente del socio autenticado actualmente, o `null` — mismo
/// criterio que `credencialActualProvider` (se recalcula solo con la
/// sesión, no hace falta pasar el email a mano).
final cuponVigentePropioProvider = StreamProvider.autoDispose<CuponAccesoModel?>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user?.email == null) {
    return Stream.value(null);
  }
  return ref.watch(cuponAccesoServiceProvider).streamVigentePropio(user!.email!);
});

/// --- Proyectos ---

final proyectosStreamProvider = StreamProvider.autoDispose<List<ProyectoModel>>((ref) {
  return ref.watch(proyectoServiceProvider).streamProyectos();
});

final proyectoDetalleProvider =
    StreamProvider.autoDispose.family<ProyectoModel?, String>((ref, id) {
  return ref.watch(proyectoServiceProvider).streamProyecto(id);
});

/// Proyecto con las postulaciones de bandas abiertas al público — lo usa
/// el formulario público (`/`) para saber contra qué proyecto postular.
final proyectoPublicoActivoProvider = StreamProvider.autoDispose<ProyectoModel?>((ref) {
  return ref.watch(proyectoServiceProvider).streamProyectoConPostulacionesAbiertas();
});

final actividadesStreamProvider =
    StreamProvider.autoDispose.family<List<ActividadModel>, String>((ref, proyectoId) {
  return ref.watch(proyectoServiceProvider).streamActividades(proyectoId);
});

final bitacoraStreamProvider =
    StreamProvider.autoDispose.family<List<BitacoraEntryModel>, String>((ref, proyectoId) {
  return ref.watch(proyectoServiceProvider).streamBitacora(proyectoId);
});

final componentesStreamProvider =
    StreamProvider.autoDispose.family<List<ComponenteModel>, String>((ref, proyectoId) {
  return ref.watch(proyectoServiceProvider).streamComponentes(proyectoId);
});

final equipoProyectoStreamProvider =
    StreamProvider.autoDispose.family<List<ProyectoMiembroModel>, String>((ref, proyectoId) {
  return ref.watch(proyectoServiceProvider).streamEquipoProyecto(proyectoId);
});

/// --- Bandas (bandas_postulaciones), ahora colgando de un Proyecto ---

/// `null` representa el filtro "Todas".
final filtroEstadoProvider = StateProvider<EstadoPostulacion?>((ref) => null);

final textoBusquedaProvider = StateProvider<String>((ref) => '');

/// Stream reactivo de postulaciones de un proyecto específico, combinando
/// ambos filtros — usado en el tab "Bandas" del detalle de un proyecto.
final postulacionesPorProyectoProvider =
    StreamProvider.autoDispose.family<List<BandaModel>, String>((ref, proyectoId) {
  final service = ref.watch(bandaServiceProvider);
  final filtroEstado = ref.watch(filtroEstadoProvider);
  final textoBusqueda = ref.watch(textoBusquedaProvider);

  return service.streamPostulaciones(
    proyectoId: proyectoId,
    filtroEstado: filtroEstado,
    textoBusqueda: textoBusqueda,
  );
});

/// Stream global sin filtros, usado para calcular los KPIs cruzados del
/// Resumen ejecutivo.
final todasLasBandasProvider = StreamProvider.autoDispose<List<BandaModel>>((ref) {
  return ref.watch(bandaServiceProvider).streamPostulaciones();
});

/// --- Vista de detalle: carga puntual de una postulación por ID ---
/// (se usa al entrar directo a `/admin/banda/:id`, por ejemplo al
/// recargar la página en el navegador).
final bandaDetalleProvider =
    FutureProvider.autoDispose.family<BandaModel?, String>((ref, id) {
  return ref.watch(bandaServiceProvider).obtenerPostulacion(id);
});

/// --- Espacios recuperados ---

final espaciosStreamProvider = StreamProvider.autoDispose<List<EspacioModel>>((ref) {
  return ref.watch(espacioServiceProvider).streamEspacios();
});

final espacioDetalleProvider =
    StreamProvider.autoDispose.family<EspacioModel?, String>((ref, id) {
  return ref.watch(espacioServiceProvider).streamEspacio(id);
});

final proyectosDelEspacioProvider =
    StreamProvider.autoDispose.family<List<ProyectoModel>, String>((ref, espacioId) {
  return ref.watch(espacioServiceProvider).streamProyectosDelEspacio(espacioId);
});

/// --- Equipo y voluntarios (personas) ---

final textoBusquedaPersonasProvider = StateProvider<String>((ref) => '');

final personasStreamProvider = StreamProvider.autoDispose<List<PersonaModel>>((ref) {
  final texto = ref.watch(textoBusquedaPersonasProvider);
  return ref.watch(personaServiceProvider).streamPersonas(texto: texto);
});

/// --- Fondos y financiamiento ---

final postulacionesFondosStreamProvider = StreamProvider.autoDispose<List<PostulacionFondoModel>>((ref) {
  return ref.watch(fondoServiceProvider).streamPostulacionesFondos();
});

final postulacionesFondosPorProyectoProvider =
    StreamProvider.autoDispose.family<List<PostulacionFondoModel>, String>((ref, proyectoId) {
  return ref.watch(fondoServiceProvider).streamPostulacionesFondos(proyectoId: proyectoId);
});

final fondoDetalleProvider =
    StreamProvider.autoDispose.family<PostulacionFondoModel?, String>((ref, id) {
  return ref.watch(fondoServiceProvider).streamPostulacionFondo(id);
});

final rendicionesStreamProvider =
    StreamProvider.autoDispose.family<List<RendicionModel>, String>((ref, postulacionId) {
  return ref.watch(fondoServiceProvider).streamRendiciones(postulacionId);
});

/// --- Agenda de eventos (agregada 2026-08-18) ---
///
/// `null` en el filtro de proyecto representa "todos los proyectos" — mismo
/// criterio que `filtroEstadoProvider` para las postulaciones de bandas.
final filtroProyectoAgendaProvider = StateProvider<String?>((ref) => null);

/// Día seleccionado y mes visible del calendario — agregado 2026-08-18 al
/// sumar la vista de calendario interactivo (antes había un toggle "mostrar
/// pasados", que dejó de tener sentido: con un calendario de verdad, se
/// navega a cualquier mes pasado o futuro con las flechas, no hace falta un
/// interruptor aparte).
final diaSeleccionadoAgendaProvider = StateProvider<DateTime>((ref) => DateTime.now());
final diaEnFocoAgendaProvider = StateProvider<DateTime>((ref) => DateTime.now());

final eventosStreamProvider = StreamProvider.autoDispose<List<EventoModel>>((ref) {
  final proyectoId = ref.watch(filtroProyectoAgendaProvider);
  return ref.watch(eventoServiceProvider).streamEventos(proyectoId: proyectoId);
});

/// --- Documentación institucional ---

final categoriaDocumentoFiltroProvider = StateProvider<CategoriaDocumento?>((ref) => null);

final textoBusquedaDocumentosProvider = StateProvider<String>((ref) => '');

final documentosStreamProvider = StreamProvider.autoDispose<List<DocumentoModel>>((ref) {
  final service = ref.watch(documentoServiceProvider);
  final categoria = ref.watch(categoriaDocumentoFiltroProvider);
  final texto = ref.watch(textoBusquedaDocumentosProvider);

  return service.streamDocumentos(categoria: categoria, texto: texto);
});
