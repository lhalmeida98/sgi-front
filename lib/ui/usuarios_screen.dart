import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';

import '../domain/models/empresa.dart';
import '../domain/models/rol.dart';
import '../domain/models/usuario.dart';
import '../domain/models/usuario_empresa.dart';
import '../resource/theme/dimens.dart';
import '../routing/app_sections.dart';
import '../services/api_client.dart';
import '../services/empresas_service.dart';
import '../services/roles_service.dart';
import '../services/usuarios_service.dart';
import '../states/roles_provider.dart';
import '../states/auth_provider.dart';
import '../states/empresas_provider.dart';
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
  late final EmpresasProvider _empresasProvider;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    final client = ApiClient();
    _provider = UsuariosProvider(UsuariosService(client));
    _rolesProvider = RolesProvider(RolesService(client));
    _empresasProvider = EmpresasProvider(EmpresasService(client));
    _rolesProvider.fetchRoles();
    _empresasProvider.fetchEmpresas();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      _provider.fetchUsuarios(includeAll: authProvider.isAdmin);
    });
  }

  @override
  void dispose() {
    _provider.dispose();
    _rolesProvider.dispose();
    _empresasProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _provider),
        ChangeNotifierProvider.value(value: _rolesProvider),
        ChangeNotifierProvider.value(value: _empresasProvider),
      ],
      child: Consumer3<UsuariosProvider, RolesProvider, EmpresasProvider>(
        builder: (context, provider, rolesProvider, empresasProvider, _) {
          final isMobile = Responsive.isMobile(context);
          if (!authProvider.canAccessSection(AppSection.usuarios)) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(defaultPadding),
                child: Container(
                  padding: const EdgeInsets.all(defaultPadding),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: const BorderRadius.all(Radius.circular(12)),
                  ),
                  child: const Text('Acceso no disponible.'),
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
                    title: 'Administración de usuarios',
                    searchHint: 'Buscar...',
                    onSearchChanged: (value) {
                      setState(() => _searchQuery = value);
                    },
                    actions: [
                      IconButton(
                        tooltip: 'Refrescar',
                        onPressed: () {
                          provider.fetchUsuarios(
                            includeAll: authProvider.isAdmin,
                          );
                          rolesProvider.fetchRoles();
                          empresasProvider.fetchEmpresas();
                        },
                        icon: const Icon(Icons.refresh),
                      ),
                      if (isMobile)
                        IconButton(
                          tooltip: 'Nuevo',
                          onPressed: () => _openUsuarioDialog(
                            context,
                            roles: rolesProvider.roles,
                            empresas: empresasProvider.empresas,
                          ),
                          icon: const Icon(Icons.add),
                        )
                      else
                        FilledButton.icon(
                          onPressed: () => _openUsuarioDialog(
                            context,
                            roles: rolesProvider.roles,
                            empresas: empresasProvider.empresas,
                          ),
                          icon: const Icon(Icons.add),
                          label: const Text('Nuevo'),
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
                    usuarios: _filterUsuarios(
                      provider.usuarios,
                      _searchQuery,
                    ),
                    onViewEmpresas: (usuario) =>
                        _openEmpresasDialog(context, usuario),
                    onEdit: (usuario) => _openUsuarioDialog(
                      context,
                      usuario: usuario,
                      roles: rolesProvider.roles,
                      empresas: empresasProvider.empresas,
                    ),
                    onDelete: (usuario) =>
                        _confirmDeleteUsuario(context, usuario),
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
    required List<Empresa> empresas,
  }) async {
    final isEditing = usuario != null;
    final formKey = GlobalKey<FormState>();
    final nombreController = TextEditingController(text: usuario?.nombre ?? '');
    final usuarioController =
        TextEditingController(text: usuario?.usuario ?? '');
    final emailController = TextEditingController(text: usuario?.email ?? '');
    final passwordController = TextEditingController();
    final roleNames = roles.map((item) => item.nombre.toUpperCase()).toList();
    final initialRoles =
        usuario?.roles.map((role) => role.toUpperCase()).toSet() ?? {};
    final availableRolesSet = <String>{
      ...roleNames.map((role) => role.toUpperCase()),
      ...initialRoles,
    };
    final availableRoles = availableRolesSet.isNotEmpty
        ? (availableRolesSet.toList()..sort())
        : const ['ADMIN', 'USER'];
    if (initialRoles.isEmpty && availableRoles.isNotEmpty) {
      initialRoles.add(availableRoles.first);
    }
    final rolesFieldKey = GlobalKey<FormFieldState<Set<String>>>();
    var activo = usuario?.activo ?? true;
    final usuariosService = UsuariosService(ApiClient());
    var empresasUsuario = usuario?.empresas ?? <UsuarioEmpresa>[];
    if (isEditing && usuario?.id != null && empresasUsuario.isEmpty) {
      try {
        empresasUsuario =
            await usuariosService.fetchUsuarioEmpresas(usuario!.id!);
      } catch (_) {}
    }
    final selectedEmpresaIds = <int>{};
    int? principalEmpresaId;
    for (final empresa in empresasUsuario) {
      selectedEmpresaIds.add(empresa.empresaId);
      if (empresa.principal && principalEmpresaId == null) {
        principalEmpresaId = empresa.empresaId;
      }
    }
    if (selectedEmpresaIds.isEmpty && empresas.isNotEmpty) {
      final firstId = empresas
          .firstWhere((e) => e.id != null, orElse: () => empresas.first)
          .id;
      if (firstId != null) {
        selectedEmpresaIds.add(firstId);
        principalEmpresaId = firstId;
      }
    }
    int? empresaSeleccionadaId = empresas.isNotEmpty
        ? empresas
            .firstWhere((e) => e.id != null, orElse: () => empresas.first)
            .id
        : null;

    await showDialog<void>(
      context: providerContext,
      builder: (context) {
        return AlertDialog(
          title: Text(isEditing ? 'Editar usuario' : 'Crear usuario'),
          content: StatefulBuilder(
            builder: (context, setState) {
              void safeSetState(VoidCallback fn) {
                if (!context.mounted) {
                  return;
                }
                final phase = SchedulerBinding.instance.schedulerPhase;
                if (phase == SchedulerPhase.persistentCallbacks ||
                    phase == SchedulerPhase.postFrameCallbacks) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (context.mounted) {
                      setState(fn);
                    }
                  });
                } else {
                  setState(fn);
                }
              }

              final maxWidth = MediaQuery.of(context).size.width;
              final isWide = maxWidth >= 720;
              final dialogWidth = isWide ? 720.0 : 420.0;
              final fieldWidth =
                  isWide ? (dialogWidth - defaultPadding) / 2 : dialogWidth;
              return ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: dialogWidth,
                  maxHeight: MediaQuery.of(context).size.height * 0.8,
                  minWidth: 280,
                ),
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: defaultPadding,
                          runSpacing: defaultPadding,
                          children: [
                            SizedBox(
                              width: fieldWidth,
                              child: TextFormField(
                                controller: nombreController,
                                decoration: const InputDecoration(
                                  labelText: 'Nombre',
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Campo requerido';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            SizedBox(
                              width: fieldWidth,
                              child: TextFormField(
                                controller: usuarioController,
                                decoration: const InputDecoration(
                                  labelText: 'Usuario',
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Campo requerido';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            SizedBox(
                              width: fieldWidth,
                              child: TextFormField(
                                controller: emailController,
                                decoration: const InputDecoration(
                                  labelText: 'Email',
                                ),
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
                            ),
                          ],
                        ),
                        const SizedBox(height: defaultPadding),
                        FormField<Set<String>>(
                          key: rolesFieldKey,
                          initialValue: initialRoles,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Seleccione al menos un rol';
                            }
                            return null;
                          },
                          builder: (state) {
                            return InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'Roles',
                                errorText: state.errorText,
                                border: const OutlineInputBorder(),
                                contentPadding: const EdgeInsets.all(12),
                              ),
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: availableRoles
                                    .map(
                                      (role) => FilterChip(
                                        label: Text(role),
                                        selected: state.value?.contains(role) ??
                                            false,
                                        onSelected: (selected) {
                                          final updated = Set<String>.from(
                                            state.value ?? {},
                                          );
                                          if (selected) {
                                            updated.add(role);
                                          } else {
                                            updated.remove(role);
                                          }
                                          state.didChange(updated);
                                        },
                                      ),
                                    )
                                    .toList(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: defaultPadding),
                        if (empresas.isEmpty)
                          Text(
                            'Sin empresas disponibles.',
                            style: Theme.of(context).textTheme.bodySmall,
                          )
                        else
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Empresas',
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              const SizedBox(height: defaultPadding / 2),
                              isWide
                                  ? Row(
                                      children: [
                                        Expanded(
                                          child: DropdownButtonFormField<int>(
                                            isExpanded: true,
                                            value: empresaSeleccionadaId,
                                            decoration: const InputDecoration(
                                              labelText: 'Agregar empresa',
                                            ),
                                            items: empresas
                                                .where((e) => e.id != null)
                                                .map(
                                                  (empresa) => DropdownMenuItem(
                                                    value: empresa.id,
                                                    child: Text(
                                                      empresa.nombreComercial
                                                              .isNotEmpty
                                                          ? empresa
                                                              .nombreComercial
                                                          : empresa.razonSocial,
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                )
                                                .toList(),
                                            onChanged: (value) {
                                              safeSetState(() {
                                                empresaSeleccionadaId = value;
                                              });
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        FilledButton.tonal(
                                          onPressed:
                                              empresaSeleccionadaId == null
                                                  ? null
                                                  : () {
                                                      safeSetState(() {
                                                        selectedEmpresaIds.add(
                                                          empresaSeleccionadaId!,
                                                        );
                                                        principalEmpresaId ??=
                                                            empresaSeleccionadaId;
                                                      });
                                                    },
                                          child: const Text('Agregar'),
                                        ),
                                      ],
                                    )
                                  : Column(
                                      children: [
                                        DropdownButtonFormField<int>(
                                          isExpanded: true,
                                          value: empresaSeleccionadaId,
                                          decoration: const InputDecoration(
                                            labelText: 'Agregar empresa',
                                          ),
                                          items: empresas
                                              .where((e) => e.id != null)
                                              .map(
                                                (empresa) => DropdownMenuItem(
                                                  value: empresa.id,
                                                  child: Text(
                                                    empresa.nombreComercial
                                                            .isNotEmpty
                                                        ? empresa
                                                            .nombreComercial
                                                        : empresa.razonSocial,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              )
                                              .toList(),
                                          onChanged: (value) {
                                            safeSetState(() {
                                              empresaSeleccionadaId = value;
                                            });
                                          },
                                        ),
                                        const SizedBox(
                                          height: defaultPadding / 2,
                                        ),
                                        SizedBox(
                                          width: double.infinity,
                                          child: FilledButton.tonal(
                                            onPressed: empresaSeleccionadaId ==
                                                    null
                                                ? null
                                                : () {
                                                    safeSetState(() {
                                                      selectedEmpresaIds.add(
                                                        empresaSeleccionadaId!,
                                                      );
                                                      principalEmpresaId ??=
                                                          empresaSeleccionadaId;
                                                    });
                                                  },
                                            child: const Text('Agregar'),
                                          ),
                                        ),
                                      ],
                                    ),
                              const SizedBox(height: defaultPadding / 2),
                              if (selectedEmpresaIds.isEmpty)
                                Text(
                                  'Selecciona al menos una empresa.',
                                  style: Theme.of(context).textTheme.bodySmall,
                                )
                              else
                                Column(
                                  children: selectedEmpresaIds.map((empresaId) {
                                    final empresa = empresas.firstWhere(
                                      (item) => item.id == empresaId,
                                      orElse: () => empresas.first,
                                    );
                                    final label =
                                        empresa.nombreComercial.isNotEmpty
                                            ? empresa.nombreComercial
                                            : empresa.razonSocial;
                                    return Container(
                                      margin: const EdgeInsets.only(
                                        bottom: defaultPadding / 2,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .surface,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .outline
                                              .withAlpha(90),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Radio<int>(
                                            value: empresaId,
                                            groupValue: principalEmpresaId,
                                            onChanged: (value) {
                                              safeSetState(
                                                () =>
                                                    principalEmpresaId = value,
                                              );
                                            },
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              label,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.close),
                                            onPressed: () {
                                              safeSetState(() {
                                                selectedEmpresaIds
                                                    .remove(empresaId);
                                                if (principalEmpresaId ==
                                                    empresaId) {
                                                  principalEmpresaId =
                                                      selectedEmpresaIds.isEmpty
                                                          ? null
                                                          : selectedEmpresaIds
                                                              .first;
                                                }
                                              });
                                            },
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                            ],
                          ),
                        const SizedBox(height: defaultPadding),
                        Wrap(
                          spacing: defaultPadding,
                          runSpacing: defaultPadding,
                          children: [
                            SizedBox(
                              width: fieldWidth,
                              child: TextFormField(
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
                            ),
                            SizedBox(
                              width: fieldWidth,
                              child: SwitchListTile(
                                value: activo,
                                onChanged: (value) {
                                  safeSetState(() => activo = value);
                                },
                                title: const Text('Activo'),
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
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
                final selectedRoles = rolesFieldKey.currentState?.value ?? {};
                if (selectedRoles.isEmpty) {
                  rolesFieldKey.currentState?.validate();
                  return;
                }
                if (empresas.isNotEmpty && selectedEmpresaIds.isEmpty) {
                  showAppToast(
                    providerContext,
                    'Selecciona al menos una empresa.',
                    isError: true,
                  );
                  return;
                }
                final principalId = principalEmpresaId ??
                    (selectedEmpresaIds.isNotEmpty
                        ? selectedEmpresaIds.first
                        : null);
                final empresasPayload = selectedEmpresaIds
                    .map(
                      (empresaId) => UsuarioEmpresa(
                        empresaId: empresaId,
                        principal: principalId == empresaId,
                      ),
                    )
                    .toList();
                final provider = providerContext.read<UsuariosProvider>();
                final payload = Usuario(
                  id: usuario?.id,
                  nombre: nombreController.text.trim(),
                  usuario: usuarioController.text.trim(),
                  email: emailController.text.trim(),
                  roles: selectedRoles.toList(),
                  empresas: empresasPayload,
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
    usuarioController.dispose();
    emailController.dispose();
    passwordController.dispose();
  }

  Future<void> _openEmpresasDialog(
    BuildContext providerContext,
    Usuario usuario,
  ) async {
    if (usuario.id == null) {
      showAppToast(
        providerContext,
        'Usuario sin ID para consultar empresas.',
        isError: true,
      );
      return;
    }
    final service = UsuariosService(ApiClient());
    List<UsuarioEmpresa> empresasUsuario = [];
    try {
      empresasUsuario = await service.fetchUsuarioEmpresas(usuario.id!);
    } catch (error) {
      showAppToast(
        providerContext,
        'No se pudo cargar empresas del usuario.',
        isError: true,
      );
      return;
    }
    if (!providerContext.mounted) {
      return;
    }
    await showDialog<void>(
      context: providerContext,
      builder: (context) {
        return AlertDialog(
          title: Text('Empresas de ${usuario.nombre}'),
          content: SizedBox(
            width: 520,
            child: empresasUsuario.isEmpty
                ? const Text('Sin empresas asociadas.')
                : ListView(
                    shrinkWrap: true,
                    children: empresasUsuario.map((item) {
                      final empresa = item.empresa;
                      final label = empresa?.nombreComercial.isNotEmpty == true
                          ? empresa!.nombreComercial
                          : empresa?.razonSocial ?? item.empresaId.toString();
                      final ruc = empresa?.ruc ?? '';
                      return ListTile(
                        leading: Icon(
                          item.principal ? Icons.star : Icons.business,
                        ),
                        title: Text(label),
                        subtitle: ruc.isEmpty ? null : Text('RUC: $ruc'),
                        trailing:
                            item.principal ? const Text('Principal') : null,
                      );
                    }).toList(),
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmDeleteUsuario(
    BuildContext providerContext,
    Usuario usuario,
  ) async {
    if (usuario.id == null) {
      showAppToast(
        providerContext,
        'Usuario sin ID para eliminar.',
        isError: true,
      );
      return;
    }
    final shouldDelete = await showDialog<bool>(
      context: providerContext,
      builder: (context) {
        return AlertDialog(
          title: const Text('Eliminar usuario'),
          content: Text(
            'Deseas eliminar el usuario "${usuario.nombre}"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );
    if (shouldDelete != true) {
      return;
    }
    final provider = providerContext.read<UsuariosProvider>();
    final ok = await provider.deleteUsuario(usuario.id!);
    if (!ok) {
      showAppToast(
        providerContext,
        provider.errorMessage ?? 'No se pudo eliminar el usuario.',
        isError: true,
      );
      return;
    }
    showAppToast(providerContext, 'Usuario eliminado.');
  }
}

List<Usuario> _filterUsuarios(List<Usuario> usuarios, String query) {
  final term = query.trim().toLowerCase();
  if (term.isEmpty) {
    return usuarios;
  }
  return usuarios.where((usuario) {
    final id = usuario.id?.toString() ?? '';
    final nombre = usuario.nombre.toLowerCase();
    final username = usuario.usuario.toLowerCase();
    final email = usuario.email.toLowerCase();
    final roles = usuario.roles.join(' ').toLowerCase();
    final telefono = usuario.telefono?.toLowerCase() ?? '';
    final empresa = _empresaPrincipalLabel(usuario).toLowerCase();
    return id.contains(term) ||
        nombre.contains(term) ||
        username.contains(term) ||
        email.contains(term) ||
        roles.contains(term) ||
        telefono.contains(term) ||
        empresa.contains(term);
  }).toList();
}

class _UsuariosList extends StatelessWidget {
  const _UsuariosList({
    required this.usuarios,
    required this.onViewEmpresas,
    required this.onEdit,
    required this.onDelete,
  });

  final List<Usuario> usuarios;
  final void Function(Usuario usuario) onViewEmpresas;
  final void Function(Usuario usuario) onEdit;
  final void Function(Usuario usuario) onDelete;

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
                  subtitle: Text(
                    'Usuario: ${usuario.usuario}\n'
                    'Email: ${usuario.email}\n'
                    'Roles: ${usuario.roles.join(', ')}\n'
                    'Telefono: ${usuario.telefono ?? '-'}\n'
                    'Autorizar correo: ${_autorizaCorreoLabel(usuario.autorizaCorreo)}\n'
                    'Empresa principal: ${_empresaPrincipalLabel(usuario)}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _StatusBadge(value: usuario.activo),
                      IconButton(
                        icon: const Icon(Icons.business_outlined),
                        onPressed: () => onViewEmpresas(usuario),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => onEdit(usuario),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => onDelete(usuario),
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
                    DataColumn(label: Text('Id')),
                    DataColumn(label: Text('Usuario')),
                    DataColumn(label: Text('Autorizar correo')),
                    DataColumn(label: Text('Roles')),
                    DataColumn(label: Text('Correo')),
                    DataColumn(label: Text('Telefono')),
                    DataColumn(label: Text('Estado')),
                    DataColumn(label: Text('Acciones')),
                  ],
                  rows: usuarios
                      .map(
                        (usuario) => DataRow(
                          cells: [
                            DataCell(Text(usuario.id?.toString() ?? '-')),
                            DataCell(Text(usuario.usuario)),
                            DataCell(
                              _StatusBadge(
                                value: usuario.autorizaCorreo,
                                activeLabel: 'ACTIVO',
                                inactiveLabel: 'INACTIVO',
                                nullLabel: 'N/A',
                              ),
                            ),
                            DataCell(
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: usuario.roles.isEmpty
                                    ? [
                                        const Text('-'),
                                      ]
                                    : usuario.roles
                                        .map((rol) => _RoleBadge(label: rol))
                                        .toList(),
                              ),
                            ),
                            DataCell(Text(usuario.email)),
                            DataCell(Text(usuario.telefono ?? '-')),
                            DataCell(_StatusBadge(value: usuario.activo)),
                            DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _ActionButton(
                                    icon: Icons.business_outlined,
                                    onPressed: () => onViewEmpresas(usuario),
                                  ),
                                  _ActionButton(
                                    icon: Icons.edit_outlined,
                                    onPressed: () => onEdit(usuario),
                                  ),
                                  _ActionButton(
                                    icon: Icons.delete_outline,
                                    onPressed: () => onDelete(usuario),
                                    isDestructive: true,
                                  ),
                                ],
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

String _empresaPrincipalLabel(Usuario usuario) {
  final principal = usuario.empresaPrincipal;
  if (principal == null) {
    return '-';
  }
  final empresa = principal.empresa;
  if (empresa != null) {
    if (empresa.nombreComercial.isNotEmpty) {
      return empresa.nombreComercial;
    }
    if (empresa.razonSocial.isNotEmpty) {
      return empresa.razonSocial;
    }
  }
  return principal.empresaId.toString();
}

String _autorizaCorreoLabel(bool? value) {
  if (value == null) {
    return 'N/A';
  }
  return value ? 'ACTIVO' : 'INACTIVO';
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.value,
    this.activeLabel = 'ACTIVO',
    this.inactiveLabel = 'INACTIVO',
    this.nullLabel = 'N/A',
  });

  final bool? value;
  final String activeLabel;
  final String inactiveLabel;
  final String nullLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isActive = value == true;
    final isInactive = value == false;
    final label = value == null
        ? nullLabel
        : isActive
            ? activeLabel
            : inactiveLabel;
    final color = value == null
        ? theme.colorScheme.onSurface.withAlpha(140)
        : isActive
            ? Colors.green
            : theme.colorScheme.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(24),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = const Color(0xFF3B82F6);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg.withAlpha(230),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.onPressed,
    this.isDestructive = false,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color =
        isDestructive ? theme.colorScheme.error : theme.colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          height: 34,
          width: 34,
          decoration: BoxDecoration(
            color: color.withAlpha(230),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
      ),
    );
  }
}
