import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../ui/login/login_layout_tokens.dart';
import '../services/auth_storage.dart';
import '../states/auth_provider.dart';
import '../states/theme_controller.dart';
import '../ui/shared/feedback.dart';
import '../utils/app_responsive.dart';
import '../utils/responsive.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;
  bool _rememberIdentifier = false;

  @override
  void initState() {
    super.initState();
    _restoreRememberedIdentifier();
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _restoreRememberedIdentifier() async {
    final remembered = await AuthStorage.readRememberedIdentifier();
    if (!mounted || remembered == null) {
      return;
    }
    setState(() {
      _rememberIdentifier = true;
      _identifierController.text = remembered;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = context.watch<ThemeController>();
    final responsive = AppResponsive.of(context);
    final tokens = LoginLayoutTokens.fromResponsive(responsive);
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.colorScheme.primary.withAlpha(38),
                    theme.colorScheme.surface,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: -tokens.topBlobOffset,
            right: -tokens.topBlobOffset,
            child: Container(
              height: tokens.topBlobSize,
              width: tokens.topBlobSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.primary.withAlpha(30),
              ),
            ),
          ),
          Positioned(
            bottom: -tokens.bottomBlobOffset,
            left: -tokens.bottomBlobOffset,
            child: Container(
              height: tokens.bottomBlobSize,
              width: tokens.bottomBlobSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.primary.withAlpha(18),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(tokens.pagePadding),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: tokens.maxWidth),
                  child: Responsive(
                    mobile: _LoginCard(
                      tokens: tokens,
                      formKey: _formKey,
                      identifierController: _identifierController,
                      passwordController: _passwordController,
                      rememberIdentifier: _rememberIdentifier,
                      obscure: _obscure,
                      onToggleObscure: () {
                        setState(() => _obscure = !_obscure);
                      },
                      onRememberIdentifierChanged: (value) {
                        setState(() => _rememberIdentifier = value);
                      },
                      onSubmit: () => _handleLogin(context),
                      onToggleTheme: controller.toggleTheme,
                      isDark: controller.isDark,
                    ),
                    tablet: Row(
                      children: [
                        Expanded(
                          child: _BrandPanel(tokens: tokens),
                        ),
                        SizedBox(width: tokens.tabletPanelGap),
                        Expanded(
                          child: _LoginCard(
                            tokens: tokens,
                            formKey: _formKey,
                            identifierController: _identifierController,
                            passwordController: _passwordController,
                            rememberIdentifier: _rememberIdentifier,
                            obscure: _obscure,
                            onToggleObscure: () {
                              setState(() => _obscure = !_obscure);
                            },
                            onRememberIdentifierChanged: (value) {
                              setState(() => _rememberIdentifier = value);
                            },
                            onSubmit: () => _handleLogin(context),
                            onToggleTheme: controller.toggleTheme,
                            isDark: controller.isDark,
                          ),
                        ),
                      ],
                    ),
                    desktop: Row(
                      children: [
                        Expanded(
                          flex: 5,
                          child: _BrandPanel(tokens: tokens),
                        ),
                        SizedBox(width: tokens.desktopPanelGap),
                        Expanded(
                          flex: 4,
                          child: _LoginCard(
                            tokens: tokens,
                            formKey: _formKey,
                            identifierController: _identifierController,
                            passwordController: _passwordController,
                            rememberIdentifier: _rememberIdentifier,
                            obscure: _obscure,
                            onToggleObscure: () {
                              setState(() => _obscure = !_obscure);
                            },
                            onRememberIdentifierChanged: (value) {
                              setState(() => _rememberIdentifier = value);
                            },
                            onSubmit: () => _handleLogin(context),
                            onToggleTheme: controller.toggleTheme,
                            isDark: controller.isDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogin(BuildContext context) async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final authProvider = context.read<AuthProvider>();
    final identifier = _identifierController.text.trim();
    final ok = await authProvider.login(
      usuarioOrEmail: identifier,
      password: _passwordController.text.trim(),
    );
    if (ok) {
      if (_rememberIdentifier) {
        await AuthStorage.saveRememberedIdentifier(identifier);
      } else {
        await AuthStorage.clearRememberedIdentifier();
      }
    }
    if (!ok && context.mounted) {
      showAppToast(
        context,
        authProvider.errorMessage ?? 'Credenciales invalidas.',
        isError: true,
      );
    }
  }
}

class _BrandPanel extends StatelessWidget {
  const _BrandPanel({required this.tokens});

  final LoginLayoutTokens tokens;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.all(tokens.panelPadding),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(tokens.cardRadius),
        color: theme.colorScheme.surface.withAlpha(180),
        border: Border.all(color: theme.colorScheme.outline.withAlpha(120)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Image.asset(
                'assets/images/LogoVuala.png',
                height: tokens.logoHeight,
              ),
              SizedBox(width: tokens.inlineGap),
              Text(
                'Facturación',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SizedBox(height: tokens.sectionGap),
          Text(
            'Accede al panel principal.',
            style: theme.textTheme.bodyLarge,
          ),
          SizedBox(height: tokens.sectionGap / 2),
          Text(
            'Emision de facturas, inventario y clientes en un solo lugar.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withAlpha(160),
            ),
          ),
          SizedBox(height: tokens.sectionGap * 2),
          Wrap(
            spacing: tokens.inlineGap,
            runSpacing: tokens.inlineGap,
            children: [
              _FeatureChip(label: 'SGI', tokens: tokens),
              _FeatureChip(label: 'Multi-empresa', tokens: tokens),
              _FeatureChip(label: 'Seguridad JWT', tokens: tokens),
              _FeatureChip(label: 'Modo claro/oscuro', tokens: tokens),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  const _FeatureChip({
    required this.label,
    required this.tokens,
  });

  final String label;
  final LoginLayoutTokens tokens;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: tokens.inlineGap,
        vertical: tokens.chipVerticalPadding,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: theme.colorScheme.primary.withAlpha(20),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.onSurface,
        ),
      ),
    );
  }
}

class _LoginCard extends StatelessWidget {
  const _LoginCard({
    required this.tokens,
    required this.formKey,
    required this.identifierController,
    required this.passwordController,
    required this.rememberIdentifier,
    required this.obscure,
    required this.onToggleObscure,
    required this.onRememberIdentifierChanged,
    required this.onSubmit,
    required this.onToggleTheme,
    required this.isDark,
  });

  final LoginLayoutTokens tokens;
  final GlobalKey<FormState> formKey;
  final TextEditingController identifierController;
  final TextEditingController passwordController;
  final bool rememberIdentifier;
  final bool obscure;
  final VoidCallback onToggleObscure;
  final ValueChanged<bool> onRememberIdentifierChanged;
  final VoidCallback onSubmit;
  final VoidCallback onToggleTheme;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = context.watch<AuthProvider>();
    return Container(
      padding: EdgeInsets.all(tokens.panelPadding),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(tokens.cardRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26),
            blurRadius: tokens.cardShadowBlur,
            offset: Offset(0, tokens.cardShadowOffsetY),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Iniciar sesion',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                tooltip:
                    isDark ? 'Cambiar a modo claro' : 'Cambiar a modo oscuro',
                onPressed: onToggleTheme,
                icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
              ),
            ],
          ),
          Text(
            'Acceso corporativo con control por roles.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withAlpha(160),
            ),
          ),
          SizedBox(height: tokens.sectionGap * 1.5),
          Form(
            key: formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: identifierController,
                  decoration:
                      const InputDecoration(labelText: 'Usuario o email'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Campo requerido';
                    }
                    return null;
                  },
                ),
                SizedBox(height: tokens.sectionGap),
                TextFormField(
                  controller: passwordController,
                  obscureText: obscure,
                  decoration: InputDecoration(
                    labelText: 'Contrasena',
                    suffixIcon: IconButton(
                      onPressed: onToggleObscure,
                      icon: Icon(
                        obscure ? Icons.visibility : Icons.visibility_off,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Campo requerido';
                    }
                    if (value.trim().length < 6) {
                      return 'Minimo 6 caracteres';
                    }
                    return null;
                  },
                ),
                SizedBox(height: tokens.sectionGap / 2),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  dense: true,
                  value: rememberIdentifier,
                  onChanged: (value) =>
                      onRememberIdentifierChanged(value ?? false),
                  title: const Text('Recordar usuario'),
                ),
              ],
            ),
          ),
          SizedBox(height: tokens.sectionGap),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: authProvider.isLoading ? null : onSubmit,
                  icon: authProvider.isLoading
                      ? SizedBox(
                          width: tokens.loadingSize,
                          height: tokens.loadingSize,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.login),
                  label: const Text('Ingresar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
