import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../resource/theme/dimens.dart';
import '../../../states/auth_provider.dart';
import '../../../states/menu_app_controller.dart';
import '../../../states/theme_controller.dart';
import '../../../utils/responsive.dart';

class Header extends StatelessWidget {
  const Header({super.key});

  @override
  Widget build(BuildContext context) {
    if (Responsive.isMobile(context)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.menu),
                onPressed: context.read<MenuAppController>().controlMenu,
              ),
              Expanded(child: _HeaderGreeting()),
              const ThemeToggleButton(),
              const SizedBox(width: defaultPadding / 2),
              const ProfileCard(),
            ],
          ),
          const SizedBox(height: defaultPadding),
          const SearchField(),
        ],
      );
    }

    return Row(
      children: [
        if (!Responsive.isDesktop(context))
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: context.read<MenuAppController>().controlMenu,
          ),
        const Expanded(
          flex: 2,
          child: _HeaderGreeting(),
        ),
        const SizedBox(width: defaultPadding),
        const Expanded(
          flex: 3,
          child: SearchField(),
        ),
        const SizedBox(width: defaultPadding),
        const ThemeToggleButton(),
        const SizedBox(width: defaultPadding),
        const ProfileCard(),
      ],
    );
  }
}

class _HeaderGreeting extends StatelessWidget {
  const _HeaderGreeting();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = context.watch<AuthProvider>();
    final name = _resolveName(authProvider.email);
    final dateLabel = DateFormat('EEEE, d MMMM y', 'es_EC')
        .format(DateTime.now())
        .replaceFirstMapped(
          RegExp(r'^.'),
          (match) => match.group(0)!.toUpperCase(),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Buen dia, $name',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          dateLabel,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withAlpha(160),
          ),
        ),
      ],
    );
  }

  String _resolveName(String? email) {
    if (email == null || email.trim().isEmpty) {
      return 'Usuario';
    }
    final parts = email.split('@');
    if (parts.isEmpty || parts.first.trim().isEmpty) {
      return 'Usuario';
    }
    final raw = parts.first.replaceAll(RegExp(r'[^a-zA-Z0-9]'), ' ');
    final words = raw.split(' ').where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) {
      return 'Usuario';
    }
    return words
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }
}

class ProfileCard extends StatelessWidget {
  const ProfileCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = context.watch<AuthProvider>();
    final name = authProvider.email ?? 'Usuario';
    final subtitle = authProvider.rol == null
        ? 'Sesion activa'
        : '${authProvider.rol} • Empresa ${authProvider.empresaId ?? '-'}';
    return PopupMenuButton<String>(
      tooltip: 'Sesion',
      onSelected: (value) {
        if (value == 'logout') {
          context.read<AuthProvider>().logout();
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem<String>(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout, size: 18),
              SizedBox(width: 8),
              Text('Cerrar sesion'),
            ],
          ),
        ),
      ],
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: defaultPadding,
          vertical: defaultPadding / 2,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.all(Radius.circular(10)),
          border: Border.all(color: theme.colorScheme.outline.withAlpha(153)),
        ),
        child: Row(
          children: [
            Image.asset(
              "assets/images/profile_pic.png",
              height: 38,
            ),
            if (!Responsive.isMobile(context))
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: defaultPadding / 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurface.withAlpha(160),
                      ),
                    ),
                  ],
                ),
              ),
            Icon(Icons.keyboard_arrow_down, color: theme.colorScheme.onSurface),
          ],
        ),
      ),
    );
  }
}

class SearchField extends StatelessWidget {
  const SearchField({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TextField(
      decoration: InputDecoration(
        hintText: "Buscar endpoint o modulo",
        fillColor: theme.colorScheme.surface,
        filled: true,
        border: const OutlineInputBorder(
          borderSide: BorderSide.none,
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
        suffixIcon: InkWell(
          onTap: () {},
          child: Container(
            padding: EdgeInsets.all(defaultPadding * 0.75),
            margin: EdgeInsets.symmetric(horizontal: defaultPadding / 2),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: const BorderRadius.all(Radius.circular(10)),
            ),
            child: SvgPicture.asset("assets/icons/Search.svg"),
          ),
        ),
      ),
    );
  }
}

class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ThemeController>();
    final isDark = controller.isDark;

    return IconButton(
      tooltip: isDark ? "Cambiar a modo claro" : "Cambiar a modo oscuro",
      onPressed: controller.toggleTheme,
      icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
    );
  }
}
