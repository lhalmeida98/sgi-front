import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../resource/theme/dimens.dart';
import '../../states/menu_app_controller.dart';
import '../../utils/responsive.dart';
import '../home/components/header.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.searchHint,
    this.onSearchChanged,
    this.actions = const [],
  });

  final String title;
  final String? subtitle;
  final String? searchHint;
  final ValueChanged<String>? onSearchChanged;
  final List<Widget> actions;

  bool get _showSearch => searchHint != null && onSearchChanged != null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = Responsive.isMobile(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!Responsive.isDesktop(context))
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: context.read<MenuAppController>().controlMenu,
          ),
        Expanded(
          child: isMobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleLarge,
                    ),
                    if (subtitle != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          subtitle!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withAlpha(153),
                          ),
                        ),
                      ),
                    if (_showSearch)
                      Padding(
                        padding: const EdgeInsets.only(
                          top: defaultPadding / 2,
                        ),
                        child: _SearchField(
                          hintText: searchHint!,
                          onChanged: onSearchChanged!,
                        ),
                      ),
                    if (actions.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(
                          top: defaultPadding / 2,
                        ),
                        child: Wrap(
                          spacing: defaultPadding / 2,
                          runSpacing: defaultPadding / 2,
                          children: actions,
                        ),
                      ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleLarge,
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withAlpha(153),
                        ),
                      ),
                  ],
                ),
        ),
        if (!isMobile) ...[
          if (_showSearch)
            Expanded(
              flex: 2,
              child: _SearchField(
                hintText: searchHint!,
                onChanged: onSearchChanged!,
              ),
            ),
          if (actions.isNotEmpty) const SizedBox(width: defaultPadding),
          ...actions,
          const SizedBox(width: defaultPadding),
          const ThemeToggleButton(),
          const SizedBox(width: defaultPadding),
          const ProfileCard(),
        ],
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.hintText,
    required this.onChanged,
  });

  final String hintText;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TextField(
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hintText,
        fillColor: theme.colorScheme.surface,
        filled: true,
        border: const OutlineInputBorder(
          borderSide: BorderSide.none,
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
        suffixIcon: Padding(
          padding: const EdgeInsets.all(defaultPadding * 0.6),
          child: SvgPicture.asset(
            'assets/icons/Search.svg',
            colorFilter: ColorFilter.mode(
              theme.colorScheme.onSurface.withAlpha(153),
              BlendMode.srcIn,
            ),
          ),
        ),
      ),
    );
  }
}
