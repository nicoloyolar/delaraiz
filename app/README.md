# De La Raíz — Plataforma de gestión cultural

App Flutter (Web + Móvil) para la **Corporación de La Raíz** (Concepción, Chile):
plataforma interna de gestión de la corporación —proyectos, espacios
recuperados, equipo/voluntariado y financiamiento— más el formulario
público de postulación de bandas (usado hoy por **La Grúa del Rock**),
todo sobre Firebase.

## Módulos

- **Proyectos**: la entidad central. Cada iniciativa de la Corporación
  (La Grúa del Rock, Festival de Lagunas, futuras) con sus propias
  actividades, bitácora de avances (con fotos), componentes (checklist de
  equipos/materiales/servicios), equipo asignado y, cuando corresponde,
  postulaciones de bandas y postulaciones a fondos. Un proyecto puede
  marcarse como el que recibe postulaciones públicas de bandas en un
  momento dado — es un toggle desde el panel, no un cambio de código.
- **Espacios**: espacios físicos recuperados o en gestión (tenencia,
  estado legal, fotos, documentación). El historial de uso de un espacio
  se deriva consultando qué proyectos lo referencian, no se duplica.
- **Equipo y voluntarios**: directorio de personas de la Corporación.
  Hoy el acceso al sistema es un único rol admin; el directorio ya
  permite asignar personas a proyectos y queda listo para roles más
  granulares.
- **Financiamiento**: postulaciones a fondos concursables vinculadas a un
  proyecto, con sus rendiciones de gastos.
- **Bandas**: postulación pública (ruta "/") y gestión de postulaciones,
  ahora como una sub-sección de un Proyecto en vez de un caso aparte.
- **Documentación institucional**: estatutos, actas, contratos, informes.

## Estructura

```
lib/
  app/            # Tema Material 3, colores de estado y rutas (go_router)
  models/         # Proyecto, Actividad, BitacoraEntry, Componente, Espacio,
                  # Persona, Usuario, PostulacionFondo, Rendicion, Banda, Documento
  services/       # Un servicio por colección de Firestore (+ Storage cuando aplica)
  providers/      # Providers de Riverpod
  screens/
    public/       # Formulario público de postulación (ruta "/")
    admin/        # Resumen, Proyectos, Espacios, Equipo, Financiamiento,
                  # Documentación, Login (rutas "/admin/*", protegidas)
  widgets/        # Cards y chips reutilizables (Pill, ProyectoCard, EspacioCard, FondoCard...)
  utils/          # Validadores de formulario (email, teléfono, RUT chileno)
firebase/
  firestore.rules # Reglas de seguridad de Firestore
  storage.rules   # Reglas de seguridad de Storage
```

## Puesta en marcha

Este código fue generado sin el Flutter SDK disponible en el entorno, por lo
que **faltan generar los proyectos nativos** (`android/`, `ios/`, `web/`, etc.).
Con Flutter instalado, desde la raíz del proyecto:

```bash
# 1. Genera las carpetas de plataforma sobre el código ya escrito
flutter create --platforms=web,android,ios .

# 2. Instala dependencias
flutter pub get

# 3. Conecta el proyecto a Firebase (crea el proyecto antes en
#    https://console.firebase.google.com si no existe)
dart pub global activate flutterfire_cli
flutterfire configure
#    Esto sobrescribe lib/firebase_options.dart con las credenciales reales.

# 4. Habilita en la Consola de Firebase:
#    - Authentication → método "Correo/contraseña" (crear ahí las cuentas
#      de la directiva; no hay auto-registro en la app).
#    - Firestore Database (modo producción).
#    - Storage.

# 5. Despliega las reglas de seguridad
firebase deploy --only firestore:rules,storage:rules

# 6. Ejecuta la app
flutter run -d chrome        # Web
flutter run                  # Móvil (con un emulador/dispositivo conectado)
```

## Colecciones de Firestore

```
proyectos/{id}                         # entidad central
  /actividades/{id}
  /bitacora/{id}                       # avances + fotos
  /componentes/{id}                    # checklist de equipos/materiales/servicios
  /equipo/{id}                         # personas asignadas a este proyecto
bandas_postulaciones/{id}              # + proyectoId (a qué proyecto pertenece)
espacios/{id}
personas/{id}
usuarios/{uid}                         # base para roles futuros (hoy: solo admin)
postulaciones_fondos/{id}
  /rendiciones/{id}
documentos_institucionales/{id}
```

`bandas_postulaciones` conserva su forma original (`nombreGrupo`, `comuna`,
`generoMusical`, contacto, representante con RUT validado, links opcionales,
dossier/rider en Storage, `estado`) y suma `proyectoId`.

## Decisiones de diseño relevantes

- **Proyecto como entidad central**: actividades, bitácora, componentes y
  equipo son subcolecciones de un proyecto porque solo se consultan en su
  contexto — nunca "todas las actividades de todos los proyectos" a la vez.
  Espacios y Financiamiento son colecciones top-level porque sí necesitan
  vistas globales cruzadas independientes del proyecto.
- **Postulaciones públicas de bandas por toggle**: el formulario público
  postula contra el proyecto marcado con `aceptaPostulacionesBandas: true`
  (a lo más uno a la vez). Abrir/cerrar postulaciones para un festival u
  otro es un cambio de datos desde el panel, no de código.
- **Un solo rol por ahora**: `usuarios/{uid}` existe desde ya para no tener
  que migrar el modelo de datos cuando se necesiten roles más granulares
  (coordinador de proyecto, voluntario), pero hoy todo usuario autenticado
  tiene acceso total (ver `firestore.rules`).
- **Sin auto-registro admin**: las cuentas de la directiva se crean manualmente
  en la Consola de Firebase; el panel nunca expone un flujo de registro.
- **Lectura pública en Storage**: `storage.rules` permite `read` público sobre
  los PDFs de dossier/rider de bandas, porque `getDownloadURL()` lo necesita
  para que la banda obtenga su propio enlace justo después de subir el
  archivo, siendo anónima. La URL resultante incluye un token no
  adivinable. Si se requiere privacidad estricta, cambiar a URLs firmadas
  vía Cloud Functions. El resto de los archivos (fotos de bitácora,
  documentación de espacios, comprobantes de rendición) son de acceso
  exclusivamente autenticado.
- **Búsqueda en cliente**: los filtros de texto se aplican sobre el
  resultado del stream de Firestore (no hay búsqueda "contains" nativa sin
  un servicio externo como Algolia); es suficiente para el volumen
  esperado de una corporación cultural local.
