# web/ — Sitio institucional (PHP)

Esta carpeta está reservada para el sitio web de la Corporación de La Raíz,
desarrollado en PHP en paralelo a la app (`app/`). Todavía no tiene código —
este README es el único archivo por ahora, para que la carpeta quede
versionada desde ya.

## Cómo traer el proyecto PHP existente aquí

El proyecto PHP hoy vive en otra máquina, como archivos sueltos sin Git
todavía. Pasos para integrarlo:

```bash
# 1. En la máquina donde está el sitio PHP, clona este repositorio
git clone https://github.com/nicoloyolar/delaraiz.git
cd delaraiz

# 2. Copia (o mueve) los archivos del sitio PHP existente dentro de web/
#    (reemplaza esta línea por el comando real según dónde estén tus archivos)
cp -r /ruta/a/tu/sitio-php/. web/

# 3. Revisa que no se cuelen archivos que no correspondan
#    (credenciales, .env, carpetas de dependencias — ver .gitignore en la raíz)
git status

# 4. Sube los cambios
git add web/
git commit -m "Agrega el sitio web PHP al monorepo"
git push
```

A partir de ahí, el desarrollo del sitio sigue normalmente dentro de `web/`,
en esa misma máquina — sin tocar `app/`.

## Usar la paleta y tipografía compartidas

En el `<head>` de tus plantillas PHP:

```html
<link rel="stylesheet" href="/design-system/brand.css">
```

Eso expone las variables CSS (`--lr-accent`, `--lr-background`, etc.)
documentadas en [`../design-system/README.md`](../design-system/README.md).
Ajusta la ruta según cómo sirvas archivos estáticos en tu configuración de
PHP (podría necesitar copiarse a `web/public/` o similar según tu estructura).
