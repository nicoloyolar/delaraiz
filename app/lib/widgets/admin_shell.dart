import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/app_colors.dart';
import '../providers/providers.dart';

/// Secciones disponibles en la navegación del panel administrativo.
enum AdminRoute { resumen, proyectos, espacios, equipo, financiamiento, socios, cupones, documentos, configuracion }

/// Layout compartido del panel admin: sidebar de navegación + contenido.
/// Todas las pantallas de `/admin/*` se envuelven en este shell para que
/// la navegación entre secciones sea consistente.
class AdminShell extends StatelessWidget {
  const AdminShell({super.key, required this.currentRoute, required this.child});

  final AdminRoute currentRoute;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final mostrarSidebar = constraints.maxWidth >= 900;
          return Row(
            children: [
              if (mostrarSidebar) _Sidebar(currentRoute: currentRoute),
              Expanded(child: child),
            ],
          );
        },
      ),
    );
  }
}

class _Sidebar extends ConsumerWidget {
  const _Sidebar({required this.currentRoute});

  final AdminRoute currentRoute;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: 248,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(right: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.accent, Color(0xFFFFA23D)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('La Raíz', style: Theme.of(context).textTheme.titleMedium),
                      Text(
                        'Corporación Cultural',
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          const SizedBox(height: 12),
          // La lista de secciones va en un `Expanded` + `ListView` (en vez de
          // apilarse directo en el `Column` de altura fija de afuera) para
          // que, si en el futuro se agregan más secciones y ya no caben en
          // pantallas más bajas, hagan scroll en vez de desbordar en
          // silencio (bug real encontrado 2026-08-14 al sumar "Socios").
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _NavItem(
                  icon: Icons.dashboard_outlined,
                  label: 'Resumen',
                  activo: currentRoute == AdminRoute.resumen,
                  onTap: () => context.go('/admin'),
                ),
                _NavItem(
                  icon: Icons.auto_awesome_mosaic_outlined,
                  label: 'Proyectos',
                  activo: currentRoute == AdminRoute.proyectos,
                  onTap: () => context.go('/admin/proyectos'),
                ),
                _NavItem(
                  icon: Icons.location_city_outlined,
                  label: 'Espacios',
                  activo: currentRoute == AdminRoute.espacios,
                  onTap: () => context.go('/admin/espacios'),
                ),
                _NavItem(
                  icon: Icons.groups_outlined,
                  label: 'Equipo',
                  activo: currentRoute == AdminRoute.equipo,
                  onTap: () => context.go('/admin/equipo'),
                ),
                _NavItem(
                  icon: Icons.savings_outlined,
                  label: 'Financiamiento',
                  activo: currentRoute == AdminRoute.financiamiento,
                  onTap: () => context.go('/admin/financiamiento'),
                ),
                _NavItem(
                  icon: Icons.card_membership_outlined,
                  label: 'Socios',
                  activo: currentRoute == AdminRoute.socios,
                  onTap: () => context.go('/admin/socios'),
                ),
                _NavItem(
                  icon: Icons.sell_outlined,
                  label: 'Cupones',
                  activo: currentRoute == AdminRoute.cupones,
                  onTap: () => context.go('/admin/cupones'),
                ),
                _NavItem(
                  icon: Icons.folder_copy_outlined,
                  label: 'Documentación',
                  activo: currentRoute == AdminRoute.documentos,
                  onTap: () => context.go('/admin/documentos'),
                ),
                const _NavItem(icon: Icons.settings_outlined, label: 'Configuración', proximamente: true),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: _NavItem(
              icon: Icons.campaign_outlined,
              label: 'Formulario público',
              onTap: () => context.push('/'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
            child: _NavItem(
              icon: Icons.badge_outlined,
              label: 'Vista pública (socio)',
              onTap: () => context.push('/credencial'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: _NavItem(
              icon: Icons.logout_rounded,
              label: 'Cerrar sesión',
              onTap: () => ref.read(authServiceProvider).signOut(),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    this.activo = false,
    this.proximamente = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool activo;
  final bool proximamente;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final habilitado = !proximamente;
    final color = activo
        ? AppColors.accent
        : (habilitado ? AppColors.textSecondary : AppColors.textMuted);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Material(
        color: activo ? AppColors.accentSoft : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: habilitado ? onTap : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Icon(icon, size: 20, color: color),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: color,
                      fontWeight: activo ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ),
                if (proximamente)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Pronto',
                      style: TextStyle(fontSize: 10, color: AppColors.textMuted),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
