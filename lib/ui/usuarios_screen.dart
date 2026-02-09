import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../domain/models/rol.dart';
import '../domain/models/usuario.dart';
import '../resource/theme/dimens.dart';
import '../services/api_client.dart';
import '../services/roles_service.dart';
import '../services/usuarios_service.dart';
import '../states/roles_provider.dart';
import '../states/auth_provider.dart';
import '../states/usuarios_provider.dart';
import '../ui/shared/feedback.dart';
import '../ui/shared/section_header.dart';
import '../utils/responsive.dart';

class UsuariosScreen extends StatefulWidget {
  const UsuariosScreen({super.key});

  @override
  State<UsuariosScreen> createState() => _UsuariosScreenState();
}

class _UsuariosScreenState extends State<UsuariosScreen> {
  late final UsuariosProvider _provider;
  late final RolesProvider _rolesProvider;

  @override
  void initState() {
    super.initState();
    _provider = UsuariosProvider(UsuariosService(ApiClient()));
    _rolesProvider = RolesProvider(RolesService(ApiClient()));
    _provider.fetchUsuarios();
    _rolesProvider.fetchRoles();
  }

  @override
  void dispose() {
    _provider.dispose();
    _rolesProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _provider),
        ChangeNotifierProvider.value(value: _rolesProvider),
      ],
      child: Consumer2<UsuariosProvider, RolesProvider>(
        builder: (context, provider, rolesProvider, _) {
          final isMobile = Responsive.isMobile(context);
          if (!authProvider.isAdmin) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(defaultPadding),
                child: Container(
                  padding: const EdgeInsets.all(defaultPadding),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: const BorderRadius.all(Radius.circular(12)),
                  ),
                  child: const Text('Acceso disponible solo para ADMIN.'),
                ),
              ),
            );
          }

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(defaultPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeader(
                    title: 'Usuarios',
                    subtitle: 'Gestion de usuarios y roles por empresa.',
                    actions: [
                      IconButton(
                        tooltip: 'Refrescar',
                        onPressed: () {
                          provider.fetchUsuarios();
                          rolesProvider.fetchRoles();
                        },
                        icon: const Icon(Icons.refresh),
                      ),
                      if (isMobile)
                        IconButton(
                          tooltip: 'Crear usuario',
                          onPressed: () => _openUsuarioDialog(
                            context,
                            roles: rolesProvider.roles,
                          ),
                          icon: const Icon(Icons.add),
                        )
                      else
                        FilledButton.icon(
                          onPressed: () => _openUsuarioDialog(
                            context,
                            roles: rolesProvider.roles,
                          ),
                          icon: const Icon(Icons.add),
                          label: const Text('Crear usuario'),
                        ),
                    ],
                  ),
                  if (provider.isLoading)
                    const Padding(
                      padding: EdgeInsets.only(top: defaultPadding / 2),
                      child: LinearProgressIndicator(),
                    ),
                  if (provider.errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: defaultPadding / 2),
                      child: Text(
                        provider.errorMessage!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  const SizedBox(height: defaultPadding),
                  _UsuariosList(
                    usuarios: provider.usuarios,
                    onEdit: (usuario) =>
                        _openUsuarioDialog(
                          context,
                          usuario: usuario,
                          roles: rolesProvider.roles,
                        ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _openUsuarioDialog(
    BuildContext providerContext, {
    Usuario? usuario,
    required List<Rol> roles,
  }) async {
    final isEditing = usuario != null;
    final formKey = GlobalKey<FormState>();
    final nombreController = TextEditingController(text: usuario?.nombre ?? '');
    final emailController = TextEditingController(text: usuario?.email ?? '');
    final passwordController = TextEditingController();
    var rol = (usuario?.rol ?? 'USER').toUpperCase();
    final roleNames =
        roles.map((item) => item.nombre.toUpperCase()).toList();
    if (roleNames.isNotEmpty && !roleNames.contains(rol)) {
      rol = roleNames.first;
    }
    var activo = usuario?.activo ?? true;

    await showDialog<void>(
      context: providerContext,
      builder: (context) {
        return AlertDialog(
          title: Text(isEditing ? 'Editar usuario' : 'Crear usuario'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return SizedBox(
                width: 420,
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nombreController,
                        decoration: const InputDecoration(labelText: 'Nombre'),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Campo requerido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: defaultPadding / 2),
                      TextFormField(
                        controller: emailController,
                        decoration: const InputDecoration(labelText: 'Email'),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Campo requerido';
                          }
                          if (!value.contains('@')) {
                            return 'Email invalido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: defaultPadding / 2),
                      DropdownButtonFormField<String>(
                        value: roleNames.contains(rol) ? rol : null,
                        items: (roleNames.isNotEmpty
                                ? roleNames
                                : const ['ADMIN', 'USER'])
                            .map(
                              (item) => DropdownMenuItem(
                                value: item.toUpperCase(),
                                child: Text(item.toUpperCase()),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => rol = value.toUpperCase());
                          }
                        },
                        decoration: const InputDecoration(labelText: 'Rol'),
                      ),
                      const SizedBox(height: defaultPadding / 2),
                      TextFormField(
                        controller: passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: isEditing
                              ? 'Nueva contrasena (opcional)'
                              : 'Contrasena',
                        ),
                        validator: (value) {
                          if (!isEditing &&
                              (value == null || value.trim().isEmpty)) {
                            return 'Campo requerido';
                          }
                          if (value != null && value.isNotEmpty) {
                            if (value.trim().length < 6) {
                              return 'Minimo 6 caracteres';
                            }
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: defaultPadding / 2),
                      SwitchListTile(
                        value: activo,
                        onChanged: (value) {
                          setState(() => activo = value);
                        },
                        title: const Text('Activo'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) {
                  return;
                }
                final provider =
                    providerContext.read<UsuariosProvider>();
                final payload = Usuario(
                  id: usuario?.id,
                  nombre: nombreController.text.trim(),
                  email: emailController.text.trim(),
                  rol: rol.toUpperCase(),
                  activo: activo,
                );
                final password = passwordController.text.trim();
                final ok = isEditing
                    ? await provider.updateUsuario(
                        payload,
                        password: password.isEmpty ? null : password,
                      )
                    : await provider.createUsuario(
                        payload,
                        password: password,
                      );
                if (!ok) {
                  showAppToast(
                    providerContext,
                    provider.errorMessage ?? 'No se pudo guardar el usuario.',
                    isError: true,
                  );
                  return;
                }
                if (context.mounted) {
                  Navigator.of(context).pop();
                  showAppToast(
                    providerContext,
                    isEditing ? 'Usuario actualizado.' : 'Usuario creado.',
                  );
                }
              },
              child: Text(isEditing ? 'Guardar' : 'Crear'),
            ),
          ],
        );
      },
    );

    nombreController.dispose();
    emailController.dispose();
    passwordController.dispose();
  }
}

class _UsuariosList extends StatelessWidget {
  const _UsuariosList({
    required this.usuarios,
    required this.onEdit,
  });

  final List<Usuario> usuarios;
  final void Function(Usuario usuario) onEdit;

  @override
  Widget build(BuildContext context) {
    if (usuarios.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(defaultPadding),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.all(Radius.circular(10)),
        ),
        child: const Text('Sin usuarios registrados.'),
      );
    }

    if (Responsive.isMobile(context)) {
      return Column(
        children: usuarios
            .map(
              (usuario) => Card(
                child: ListTile(
                  title: Text(usuario.nombre),
                  subtitle: Text(usuario.email),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _EstadoChip(activo: usuario.activo),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => onEdit(usuario),
                      ),
                    ],
                  ),
                ),
              ),
            )
            .toList(),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final cardWidth = maxWidth > 980 ? 980.0 : maxWidth;
        return Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: cardWidth,
            child: Container(
              padding: const EdgeInsets.all(defaultPadding),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.all(Radius.circular(10)),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Nombre')),
                    DataColumn(label: Text('Email')),
                    DataColumn(label: Text('Rol')),
                    DataColumn(label: Text('Activo')),
                    DataColumn(label: Text('Acciones')),
                  ],
                  rows: usuarios
                      .map(
                        (usuario) => DataRow(
                          cells: [
                            DataCell(Text(usuario.nombre)),
                            DataCell(Text(usuario.email)),
                            DataCell(Text(usuario.rol)),
                            DataCell(_EstadoChip(activo: usuario.activo)),
                            DataCell(
                              IconButton(
                                icon: const Icon(Icons.edit_outlined),
                                onPressed: () => onEdit(usuario),
                              ),
                            ),
                          ],
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _EstadoChip extends StatelessWidget {
  const _EstadoChip({required this.activo});

  final bool activo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = activo ? Colors.green : theme.colorScheme.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(24),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        activo ? 'Activo' : 'Inactivo',
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
