# Design system — De La Raíz

Paleta y tipografía compartidas entre `app/` (Flutter) y `web/` (sitio PHP),
para que ambos se vean como la misma marca sin copiar valores a ojo.

## Archivos

- **`tokens.json`** — fuente de verdad legible por humanos y por herramientas.
  No se consume automáticamente desde ningún lado todavía (no hay build step
  que lo inyecte); es la referencia contra la que se revisan los otros dos.
- **`brand.css`** — el mismo set de valores como variables CSS, listo para
  que el sitio PHP lo incluya con `<link rel="stylesheet">` o lo importe.
- `app/lib/app/app_colors.dart` y `app/lib/app/app_theme.dart` — el
  equivalente en Dart, usado por la app Flutter.

## Cómo mantenerlos sincronizados

No hay generación automática (a propósito: son pocos valores y agregar un
build step no se justifica todavía). Si cambia un color o la tipografía:

1. Actualiza `tokens.json` primero — es el que documenta la intención.
2. Refleja el cambio en `brand.css` (para el sitio PHP).
3. Refleja el cambio en `app/lib/app/app_colors.dart` (para la app).

## Paleta actual

| Token | Valor | Uso |
|---|---|---|
| `background` | `#0B0B0F` | Fondo general (tema oscuro tipo dashboard) |
| `surface` | `#16161D` | Tarjetas, paneles |
| `accent` | `#FF6A3D` | Acento de marca — "luces de escenario" de La Grúa del Rock |
| `seleccionada` | `#2ED573` | Estado positivo/aprobado |
| `pendiente` | `#FFC107` | Estado en espera |
| `rechazada` | `#FF4757` | Estado negativo/rechazado |

Tipografía: **Manrope** (Google Fonts) en toda la marca.

## Sobre el sistema de credenciales/suscripciones (a futuro)

Cuando se integre el sistema de cuentas con suscripción pagada (mencionado
para el sitio PHP), conviene decidir entonces si:

- el PHP es la fuente de verdad de usuarios/suscripciones y la app Flutter
  valida contra su API, o
- se centraliza en Firebase Auth (que ya usa la app) y el PHP valida contra
  Firebase.

Todavía no se ha tomado esa decisión — se deja anotado aquí para no perderlo
de vista cuando se retome.
