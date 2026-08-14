import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/actividad_model.dart';
import '../models/banda_model.dart';
import '../models/bitacora_entry_model.dart';
import '../models/componente_model.dart';
import '../models/credencial_model.dart';
import '../models/documento_model.dart';
import '../models/espacio_model.dart';
import '../models/persona_model.dart';
import '../models/postulacion_fondo_model.dart';
import '../models/proyecto_miembro_model.dart';
import '../models/proyecto_model.dart';
import '../models/rendicion_model.dart';
import '../services/auth_service.dart';
import '../services/banda_service.dart';
import '../services/credencial_service.dart';
import '../services/documento_service.dart';
import '../services/espacio_service.dart';
import '../services/fondo_service.dart';
import '../services/persona_service.dart';
import '../services/proyecto_service.dart';

/// --- Servicios (singletons de la app) ---

final bandaServiceProvider = Provider<BandaService>((ref) => BandaService());

final documentoServiceProvider = Provider<DocumentoService>((ref) => DocumentoService());

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final proyectoServiceProvider = Provider<ProyectoService>((ref) => ProyectoService());

final espacioServiceProvider = Provider<EspacioService>((ref) => EspacioService());

final personaServiceProvider = Provider<PersonaService>((ref) => PersonaService());

final fondoServiceProvider = Provider<FondoService>((ref) => FondoService());

final credencialServiceProvider = Provider<CredencialService>((ref) => CredencialService());

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

/// --- Documentación institucional ---

final categoriaDocumentoFiltroProvider = StateProvider<CategoriaDocumento?>((ref) => null);

final textoBusquedaDocumentosProvider = StateProvider<String>((ref) => '');

final documentosStreamProvider = StreamProvider.autoDispose<List<DocumentoModel>>((ref) {
  final service = ref.watch(documentoServiceProvider);
  final categoria = ref.watch(categoriaDocumentoFiltroProvider);
  final texto = ref.watch(textoBusquedaDocumentosProvider);

  return service.streamDocumentos(categoria: categoria, texto: texto);
});
