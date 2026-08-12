import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/banda_model.dart';
import '../../models/proyecto_model.dart';
import '../../providers/providers.dart';
import '../../utils/validators.dart';

/// Formulario público de postulación de bandas.
///
/// Cualquier banda puede acceder a esta pantalla (no requiere sesión) y
/// enviar sus datos, enlaces y dossier/rider técnico en PDF. El proyecto
/// contra el que se postula es el que la Corporación haya marcado como
/// "acepta postulaciones de bandas" desde el panel admin (ver tab "Info"
/// del detalle de un proyecto) — así, abrir o cerrar postulaciones para
/// un festival u otro es un toggle, no un cambio de código. Al enviar,
/// [BandaService.crearPostulacion] sube los archivos a Storage y crea el
/// documento en Firestore.
class PostulacionFormScreen extends ConsumerStatefulWidget {
  const PostulacionFormScreen({super.key});

  @override
  ConsumerState<PostulacionFormScreen> createState() =>
      _PostulacionFormScreenState();
}

class _PostulacionFormScreenState extends ConsumerState<PostulacionFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nombreGrupoCtrl = TextEditingController();
  final _comunaCtrl = TextEditingController();
  final _generoCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _correoCtrl = TextEditingController();
  final _nombreRepCtrl = TextEditingController();
  final _rutRepCtrl = TextEditingController();
  final _spotifyCtrl = TextEditingController();
  final _youtubeCtrl = TextEditingController();
  final _instagramCtrl = TextEditingController();
  final _materialCtrl = TextEditingController();

  PlatformFile? _dossier;
  PlatformFile? _riderTecnico;

  bool _enviando = false;

  @override
  void dispose() {
    _nombreGrupoCtrl.dispose();
    _comunaCtrl.dispose();
    _generoCtrl.dispose();
    _telefonoCtrl.dispose();
    _correoCtrl.dispose();
    _nombreRepCtrl.dispose();
    _rutRepCtrl.dispose();
    _spotifyCtrl.dispose();
    _youtubeCtrl.dispose();
    _instagramCtrl.dispose();
    _materialCtrl.dispose();
    super.dispose();
  }

  Future<void> _seleccionarArchivo({required bool esDossier}) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true, // fuerza a traer los bytes en memoria (necesario en Web)
    );
    if (result == null || result.files.isEmpty) return;

    setState(() {
      if (esDossier) {
        _dossier = result.files.single;
      } else {
        _riderTecnico = result.files.single;
      }
    });
  }

  Future<void> _enviarPostulacion(ProyectoModel proyecto) async {
    if (!_formKey.currentState!.validate()) return;

    if (_dossier == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes adjuntar el Dossier en PDF.')),
      );
      return;
    }

    setState(() => _enviando = true);

    try {
      final banda = BandaModel(
        nombreGrupo: _nombreGrupoCtrl.text.trim(),
        comuna: _comunaCtrl.text.trim(),
        generoMusical: _generoCtrl.text.trim(),
        telefonoContacto: _telefonoCtrl.text.trim(),
        correoContacto: _correoCtrl.text.trim(),
        nombreRepresentante: _nombreRepCtrl.text.trim(),
        rutRepresentante: _rutRepCtrl.text.trim(),
        linkSpotify: _valorOrNull(_spotifyCtrl.text),
        linkYoutube: _valorOrNull(_youtubeCtrl.text),
        linkInstagram: _valorOrNull(_instagramCtrl.text),
        linkMaterialAudiovisual: _valorOrNull(_materialCtrl.text),
      );

      await ref.read(bandaServiceProvider).crearPostulacion(
            banda: banda,
            proyectoId: proyecto.id!,
            dossierBytes: _dossier!.bytes,
            dossierNombreArchivo: _dossier!.name,
            riderTecnicoBytes: _riderTecnico?.bytes,
            riderTecnicoNombreArchivo: _riderTecnico?.name,
          );

      if (!mounted) return;
      await _mostrarConfirmacion(proyecto.nombre);
      _limpiarFormulario();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ocurrió un error al enviar tu postulación: $e')),
      );
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  String? _valorOrNull(String value) => value.trim().isEmpty ? null : value.trim();

  void _limpiarFormulario() {
    _formKey.currentState!.reset();
    _nombreGrupoCtrl.clear();
    _comunaCtrl.clear();
    _generoCtrl.clear();
    _telefonoCtrl.clear();
    _correoCtrl.clear();
    _nombreRepCtrl.clear();
    _rutRepCtrl.clear();
    _spotifyCtrl.clear();
    _youtubeCtrl.clear();
    _instagramCtrl.clear();
    _materialCtrl.clear();
    setState(() {
      _dossier = null;
      _riderTecnico = null;
    });
  }

  Future<void> _mostrarConfirmacion(String nombreProyecto) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: Colors.green, size: 48),
        title: const Text('¡Postulación enviada!'),
        content: Text(
          'Gracias por postular a "$nombreProyecto". La Corporación de La '
          'Raíz revisará tu material y te contactará a través de los datos '
          'proporcionados.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final proyectoAsync = ref.watch(proyectoPublicoActivoProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Postulación de Bandas'),
        actions: [
          IconButton(
            tooltip: 'Ingreso administrativo',
            icon: const Icon(Icons.admin_panel_settings_outlined),
            onPressed: () => context.push('/admin/login'),
          ),
        ],
      ),
      body: proyectoAsync.when(
        data: (proyecto) {
          if (proyecto == null) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'En este momento no hay postulaciones de bandas abiertas. '
                  'Vuelve a revisar más adelante o contacta a la Corporación de La Raíz.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return _construirFormulario(context, proyecto);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error al cargar el formulario: $error')),
      ),
    );
  }

  Widget _construirFormulario(BuildContext context, ProyectoModel proyecto) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Corporación de La Raíz · Concepción',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Completa el formulario para postular tu banda a "${proyecto.nombre}".',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),

                _seccion('Datos de la banda'),
                _campoTexto(_nombreGrupoCtrl, 'Nombre del grupo',
                    validator: (v) => Validators.requerido(v, campo: 'El nombre del grupo')),
                _campoTexto(_comunaCtrl, 'Ciudad / comuna',
                    validator: (v) => Validators.requerido(v, campo: 'La comuna')),
                _campoTexto(_generoCtrl, 'Género musical',
                    validator: (v) => Validators.requerido(v, campo: 'El género musical')),
                _campoTexto(_telefonoCtrl, 'Teléfono de contacto',
                    keyboardType: TextInputType.phone, validator: Validators.telefono),
                _campoTexto(_correoCtrl, 'Correo de contacto',
                    keyboardType: TextInputType.emailAddress, validator: Validators.email),

                const SizedBox(height: 16),
                _seccion('Representante'),
                _campoTexto(_nombreRepCtrl, 'Nombre del representante',
                    validator: (v) => Validators.requerido(v, campo: 'El nombre del representante')),
                _campoTexto(_rutRepCtrl, 'RUT del representante',
                    hint: 'Ej: 12.345.678-5', validator: Validators.rutChileno),

                const SizedBox(height: 16),
                _seccion('Enlaces (opcional)'),
                _campoTexto(_spotifyCtrl, 'Link de Spotify',
                    keyboardType: TextInputType.url, validator: Validators.urlOpcional),
                _campoTexto(_youtubeCtrl, 'Link de YouTube',
                    keyboardType: TextInputType.url, validator: Validators.urlOpcional),
                _campoTexto(_instagramCtrl, 'Link de Instagram',
                    keyboardType: TextInputType.url, validator: Validators.urlOpcional),
                _campoTexto(_materialCtrl, 'Material audiovisual (link)',
                    keyboardType: TextInputType.url, validator: Validators.urlOpcional),

                const SizedBox(height: 16),
                _seccion('Archivos adjuntos'),
                _selectorArchivo(
                  titulo: 'Dossier (PDF) *',
                  archivo: _dossier,
                  onSeleccionar: () => _seleccionarArchivo(esDossier: true),
                ),
                const SizedBox(height: 12),
                _selectorArchivo(
                  titulo: 'Rider técnico (PDF, opcional)',
                  archivo: _riderTecnico,
                  onSeleccionar: () => _seleccionarArchivo(esDossier: false),
                ),

                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _enviando ? null : () => _enviarPostulacion(proyecto),
                    child: _enviando
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Enviar postulación'),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _seccion(String titulo) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(
          titulo,
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
      );

  Widget _campoTexto(
    TextEditingController controller,
    String label, {
    String? hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(labelText: label, hintText: hint),
        validator: validator,
      ),
    );
  }

  Widget _selectorArchivo({
    required String titulo,
    required PlatformFile? archivo,
    required VoidCallback onSeleccionar,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.picture_as_pdf_outlined,
              color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: Theme.of(context).textTheme.bodyMedium),
                Text(
                  archivo?.name ?? 'Ningún archivo seleccionado',
                  style: Theme.of(context).textTheme.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: onSeleccionar,
            child: Text(archivo == null ? 'Elegir PDF' : 'Cambiar'),
          ),
        ],
      ),
    );
  }
}
