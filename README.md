# De La Raíz — monorepo

Corporación de La Raíz (Concepción, Chile): cultura y arte, recuperación de
espacios. Este repositorio reúne los dos proyectos digitales de la
corporación, cada uno desarrollado de forma independiente pero compartiendo
una misma identidad visual.

```
delaraiz/
├── app/              # Plataforma interna de gestión (Flutter + Firebase)
├── web/              # Sitio institucional (PHP) — en construcción
├── design-system/     # Paleta, tipografía y tokens compartidos por ambos
└── README.md          # Este archivo
```

## Qué es cada carpeta

- **[`app/`](app/)** — la plataforma interna: gestión de proyectos
  culturales, espacios recuperados, equipo/voluntariado, financiamiento y el
  formulario público de postulación de bandas. Ver [`app/README.md`](app/README.md)
  para arquitectura, módulos y puesta en marcha.
- **[`web/`](web/)** — el sitio web institucional, en PHP. Ver
  [`web/README.md`](web/README.md).
- **[`design-system/`](design-system/)** — la paleta de colores y la
  tipografía de la marca, en un formato que ambos lados pueden consumir
  (`tokens.json` + `brand.css`), para que la app y el sitio se vean como la
  misma marca sin duplicar valores a ojo.

## Cómo se trabaja aquí

Cada proyecto se desarrolla desde su propia máquina/entorno, apuntando solo
a su carpeta:

- Quien trabaja en la **app** abre `app/` como raíz de su proyecto en su
  editor (ahí están `pubspec.yaml`, `lib/`, etc.) y corre los comandos de
  Flutter desde dentro de esa carpeta.
- Quien trabaja en el **sitio web** hace lo mismo dentro de `web/`.
- Ambos comparten este único repositorio de GitHub y pueden tomar del otro
  lo que necesiten de `design-system/`, pero no dependen del código interno
  del otro proyecto.

## A futuro: credenciales y suscripciones

Está planeado un sistema de acceso para personas con una suscripción pagada,
compartido entre ambos proyectos. Todavía no está decidido si la fuente de
verdad de usuarios será el sitio PHP o Firebase Auth (que ya usa la app) —
ver la nota al final de [`design-system/README.md`](design-system/README.md).
