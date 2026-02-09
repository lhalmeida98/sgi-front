import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../routing/app_sections.dart';
import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../../states/auth_provider.dart';
import '../../states/menu_app_controller.dart';
import '../../ui/clientes_screen.dart';
import '../../ui/empresas_screen.dart';
import '../../ui/facturacion_screen.dart';
import '../../ui/impuestos_screen.dart';
import '../../ui/inventarios_screen.dart';
import '../../ui/bodegas_screen.dart';
import '../../ui/preordenes_screen.dart';
import '../../ui/productos_screen.dart';
import '../../ui/home/dashboard_screen.dart';
import '../../ui/login_screen.dart';
import '../../ui/usuarios_screen.dart';
import '../../ui/roles_screen.dart';
import '../../ui/categorias_screen.dart';
import '../../utils/responsive.dart';
import 'components/side_menu.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late final AuthProvider _authProvider;

  @override
  void initState() {
    super.initState();
    _authProvider = AuthProvider(AuthService(ApiClient()));
  }

  @override
  void dispose() {
    _authProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _authProvider,
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          if (!authProvider.isAuthenticated) {
            return const LoginScreen();
          }
          return const _MainShell();
        },
      ),
    );
  }
}

class _MainShell extends StatelessWidget {
  const _MainShell();

  @override
  Widget build(BuildContext context) {
    final menuController = context.watch<MenuAppController>();
    final authProvider = context.watch<AuthProvider>();
    final activeSection = menuController.activeSection;
    if (!authProvider.isAdmin &&
        (activeSection == AppSection.usuarios ||
            activeSection == AppSection.empresas ||
            activeSection == AppSection.roles)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        menuController.setSection(AppSection.dashboard);
      });
    }
    return Scaffold(
      key: context.read<MenuAppController>().scaffoldKey,
      drawer: const SideMenu(),
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (Responsive.isDesktop(context))
              Expanded(
                child: const SideMenu(),
              ),
            Expanded(
              flex: 5,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _resolveSection(activeSection),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _resolveSection(AppSection section) {
    switch (section) {
      case AppSection.dashboard:
        return const DashboardScreen(key: ValueKey('dashboard'));
      case AppSection.empresas:
        return const EmpresasScreen(key: ValueKey('empresas'));
      case AppSection.categorias:
        return const CategoriasScreen(key: ValueKey('categorias'));
      case AppSection.impuestos:
        return const ImpuestosScreen(key: ValueKey('impuestos'));
      case AppSection.productos:
        return const ProductosScreen(key: ValueKey('productos'));
      case AppSection.clientes:
        return const ClientesScreen(key: ValueKey('clientes'));
      case AppSection.inventarios:
        return const InventariosScreen(key: ValueKey('inventarios'));
      case AppSection.bodegas:
        return const BodegasScreen(key: ValueKey('bodegas'));
      case AppSection.preordenes:
        return const PreordenesScreen(key: ValueKey('preordenes'));
      case AppSection.facturacion:
        return const FacturacionScreen(key: ValueKey('facturacion'));
      case AppSection.usuarios:
        return const UsuariosScreen(key: ValueKey('usuarios'));
      case AppSection.roles:
        return const RolesScreen(key: ValueKey('roles'));
    }
  }
}
