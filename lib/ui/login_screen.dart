import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../resource/theme/dimens.dart';
import '../states/auth_provider.dart';
import '../states/theme_controller.dart';
import '../ui/shared/feedback.dart';
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

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = context.watch<ThemeController>();
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
            top: -120,
            right: -120,
            child: Container(
              height: 260,
              width: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.primary.withAlpha(30),
              ),
            ),
          ),
          Positioned(
            bottom: -140,
            left: -140,
            child: Container(
              height: 300,
              width: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.primary.withAlpha(18),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(defaultPadding),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: Responsive(
                    mobile: _LoginCard(
                      formKey: _formKey,
                      identifierController: _identifierController,
                      passwordController: _passwordController,
                      obscure: _obscure,
                      onToggleObscure: () {
                        setState(() => _obscure = !_obscure);
                      },
                      onSubmit: () => _handleLogin(context),
                      onToggleTheme: controller.toggleTheme,
                      isDark: controller.isDark,
                    ),
                    tablet: Row(
                      children: [
                        Expanded(
                          child: _BrandPanel(),
                        ),
                        const SizedBox(width: defaultPadding),
                        Expanded(
                          child: _LoginCard(
                            formKey: _formKey,
                            identifierController: _identifierController,
                            passwordController: _passwordController,
                            obscure: _obscure,
                            onToggleObscure: () {
                              setState(() => _obscure = !_obscure);
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
                          child: _BrandPanel(),
                        ),
                        const SizedBox(width: defaultPadding * 2),
                        Expanded(
                          flex: 4,
                          child: _LoginCard(
                            formKey: _formKey,
                            identifierController: _identifierController,
                            passwordController: _passwordController,
                            obscure: _obscure,
                            onToggleObscure: () {
                              setState(() => _obscure = !_obscure);
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
    final ok = await authProvider.login(
      usuarioOrEmail: _identifierController.text.trim(),
      password: _passwordController.text.trim(),
    );
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
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(defaultPadding * 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
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
                'assets/images/logo.png',
                height: 38,
              ),
              const SizedBox(width: 12),
              Text(
                'SGI Facturacion',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: defaultPadding),
          Text(
            'Accede al panel empresarial con control por empresa y roles.',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: defaultPadding / 2),
          Text(
            'Emision de facturas, inventario y clientes en un solo lugar.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withAlpha(160),
            ),
          ),
          const SizedBox(height: defaultPadding * 2),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _FeatureChip(label: 'Material 3'),
              _FeatureChip(label: 'Multi-empresa'),
              _FeatureChip(label: 'Seguridad JWT'),
              _FeatureChip(label: 'Modo claro/oscuro'),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  const _FeatureChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
    required this.formKey,
    required this.identifierController,
    required this.passwordController,
    required this.obscure,
    required this.onToggleObscure,
    required this.onSubmit,
    required this.onToggleTheme,
    required this.isDark,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController identifierController;
  final TextEditingController passwordController;
  final bool obscure;
  final VoidCallback onToggleObscure;
  final VoidCallback onSubmit;
  final VoidCallback onToggleTheme;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = context.watch<AuthProvider>();
    return Container(
      padding: const EdgeInsets.all(defaultPadding * 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26),
            blurRadius: 30,
            offset: const Offset(0, 18),
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
                tooltip: isDark
                    ? 'Cambiar a modo claro'
                    : 'Cambiar a modo oscuro',
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
          const SizedBox(height: defaultPadding * 1.5),
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
                const SizedBox(height: defaultPadding),
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
              ],
            ),
          ),
          const SizedBox(height: defaultPadding),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: authProvider.isLoading ? null : onSubmit,
                  icon: authProvider.isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
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
