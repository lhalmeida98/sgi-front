import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../domain/models/accion.dart';
import '../domain/models/rol.dart';
import '../resource/theme/dimens.dart';
import '../routing/app_sections.dart';
import '../services/acciones_service.dart';
import '../services/api_client.dart';
import '../services/roles_service.dart';
import '../states/acciones_provider.dart';
import '../states/auth_provider.dart';
import '../states/roles_provider.dart';
import '../ui/shared/feedback.dart';
import '../ui/shared/section_header.dart';
import '../utils/responsive.dart';

enum RolesSection { roles, acciones }

class RolesScreen extends StatefulWidget {
  const RolesScreen({super.key});

  @override
  State<RolesScreen> createState() => _RolesScreenState();
}

class _RolesScreenState extends State<RolesScreen> {
  late final RolesProvider _rolesProvider;
  late final AccionesProvider _accionesProvider;
  RolesSection _section = RolesSection.roles;

  @override
  void initState() {
    super.initState();
    final client = ApiClient();
    _rolesProvider = RolesProvider(RolesService(client));
    _accionesProvider = AccionesProvider(AccionesService(client));
    _rolesProvider.fetchRoles();
    _rolesProvider.fetchAccionesDisponibles();
    _accionesProvider.fetchAcciones();
  }

  @override
  void dispose() {
    _rolesProvider.dispose();
    _accionesProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _rolesProvider),
        ChangeNotifierProvider.value(value: _accionesProvider),
      ],
      child: Consumer2<RolesProvider, AccionesProvider>(
        builder: (context, rolesProvider, accionesProvider, _) {
          if (!authProvider.canAccessSection(AppSection.roles)) {
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

          final isMobile = Responsive.isMobile(context);
          final isLoading =
              rolesProvider.isLoading || accionesProvider.isLoading;
          final errorMessage = rolesProvider.errorMessage ??
              accionesProvider.errorMessage;

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(defaultPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeader(
                    title: 'Roles y acciones',
                    subtitle: 'Gestion de permisos del sistema.',
                    actions: [
                      SegmentedButton<RolesSection>(
                        segments: const [
                          ButtonSegment(
                            value: RolesSection.roles,
                            label: Text('Roles'),
                            icon: Icon(Icons.admin_panel_settings),
                          ),
                          ButtonSegment(
                            value: RolesSection.acciones,
                            label: Text('Acciones'),
                            icon: Icon(Icons.rule_folder_outlined),
                          ),
                        ],
                        selected: {_section},
                        onSelectionChanged: (value) {
                          setState(() => _section = value.first);
                        },
                      ),
                      const SizedBox(width: defaultPadding / 2),
                      IconButton(
                        tooltip: 'Refrescar',
                        onPressed: () {
                          rolesProvider.fetchRoles();
                          rolesProvider.fetchAccionesDisponibles();
                          accionesProvider.fetchAcciones();
                        },
                        icon: const Icon(Icons.refresh),
                      ),
                      if (isMobile)
                        IconButton(
                          tooltip: _section == RolesSection.roles
                              ? 'Crear rol'
                              : 'Crear accion',
                          onPressed: () {
                            if (_section == RolesSection.roles) {
                              _openRolDialog(
                                context,
                                rol: null,
                                accionesDisponibles:
                                    rolesProvider.accionesDisponibles,
                              );
                            } else {
                              _openAccionDialog(
                                context,
                                accion: null,
                              );
                            }
                          },
                          icon: const Icon(Icons.add),
                        )
                      else
                        FilledButton.icon(
                          onPressed: () {
                            if (_section == RolesSection.roles) {
                              _openRolDialog(
                                context,
                                rol: null,
                                accionesDisponibles:
                                    rolesProvider.accionesDisponibles,
                              );
                            } else {
                              _openAccionDialog(
                                context,
                                accion: null,
                              );
                            }
                          },
                          icon: const Icon(Icons.add),
                          label: Text(
                            _section == RolesSection.roles
                                ? 'Crear rol'
                                : 'Crear accion',
                          ),
                        ),
                    ],
                  ),
                  if (isLoading)
                    const Padding(
                      padding: EdgeInsets.only(top: defaultPadding / 2),
                      child: LinearProgressIndicator(),
                    ),
                  if (errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: defaultPadding / 2),
                      child: Text(
                        errorMessage,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  const SizedBox(height: defaultPadding),
                  if (_section == RolesSection.roles)
                    _RolesList(
                      roles: rolesProvider.roles,
                      accionesDisponibles:
                          rolesProvider.accionesDisponibles,
                      onEdit: (rol) => _openRolDialog(
                        context,
                        rol: rol,
                        accionesDisponibles:
                            rolesProvider.accionesDisponibles,
                      ),
                      onDelete: (rol) =>
                          _confirmDeleteRol(context, rol),
                    )
                  else
                    _AccionesList(
                      acciones: accionesProvider.acciones,
                      onEdit: (accion) => _openAccionDialog(
                        context,
                        accion: accion,
                      ),
                      onDelete: (accion) =>
                          _confirmDeleteAccion(context, accion),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _openRolDialog(
    BuildContext providerContext, {
    Rol? rol,
    required List<Accion> accionesDisponibles,
  }) async {
    final isEditing = rol != null;
    final formKey = GlobalKey<FormState>();
    final nombreController =
        TextEditingController(text: rol?.nombre ?? '');
    final descripcionController =
        TextEditingController(text: rol?.descripcion ?? '');
    var activo = rol?.activo ?? true;
    final selectedIds = <int>{};
    if (rol != null) {
      selectedIds.addAll(rol.accionesIds);
    }
    if (selectedIds.isEmpty && rol != null && rol.permisos.isNotEmpty) {
      final permisosSet =
          rol.permisos.map((item) => item.toUpperCase()).toSet();
      for (final accion in accionesDisponibles) {
        if (accion.id == null) {
          continue;
        }
        final codigo = accion.codigo.toUpperCase();
        final nombre = accion.nombre.toUpperCase();
        if (permisosSet.contains(codigo) || permisosSet.contains(nombre)) {
          selectedIds.add(accion.id!);
        }
      }
    }

    await showDialog<void>(
      context: providerContext,
      builder: (context) {
        return AlertDialog(
          title: Text(isEditing ? 'Editar rol' : 'Crear rol'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return SizedBox(
                width: 460,
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                        controller: descripcionController,
                        decoration:
                            const InputDecoration(labelText: 'Descripcion'),
                      ),
                      const SizedBox(height: defaultPadding),
                      Text(
                        'Permisos',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: defaultPadding / 2),
                      if (accionesDisponibles.isEmpty)
                        Text(
                          'Sin acciones disponibles.',
                          style: Theme.of(context).textTheme.bodySmall,
                        )
                      else
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: accionesDisponibles
                              .map(
                                (accion) => FilterChip(
                                  label: Text(
                                    accion.nombre.isNotEmpty
                                        ? accion.nombre
                                        : accion.codigo,
                                  ),
                                  selected: accion.id != null &&
                                      selectedIds.contains(accion.id),
                                  onSelected: (value) {
                                    setState(() {
                                      if (accion.id == null) {
                                        return;
                                      }
                                      if (value) {
                                        selectedIds.add(accion.id!);
                                      } else {
                                        selectedIds.remove(accion.id);
                                      }
                                    });
                                  },
                                ),
                              )
                              .toList(),
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
                if (selectedIds.isEmpty) {
                  showAppToast(
                    providerContext,
                    'Selecciona al menos una accion.',
                    isError: true,
                  );
                  return;
                }
                final payload = Rol(
                  id: rol?.id,
                  nombre: nombreController.text.trim(),
                  descripcion: descripcionController.text.trim(),
                  accionesIds: selectedIds.toList(),
                  activo: activo,
                );
                final provider = providerContext.read<RolesProvider>();
                final ok = isEditing
                    ? await provider.updateRol(payload)
                    : await provider.createRol(payload);
                if (!ok) {
                  showAppToast(
                    providerContext,
                    provider.errorMessage ?? 'No se pudo guardar el rol.',
                    isError: true,
                  );
                  return;
                }
                if (context.mounted) {
                  Navigator.of(context).pop();
                  showAppToast(
                    providerContext,
                    isEditing ? 'Rol actualizado.' : 'Rol creado.',
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
    descripcionController.dispose();
  }

  Future<void> _openAccionDialog(
    BuildContext providerContext, {
    Accion? accion,
  }) async {
    final isEditing = accion != null;
    final formKey = GlobalKey<FormState>();
    final nombreController =
        TextEditingController(text: accion?.nombre ?? '');
    final codigoController =
        TextEditingController(text: accion?.codigo ?? '');
    final descripcionController =
        TextEditingController(text: accion?.descripcion ?? '');
    final urlController = TextEditingController(text: accion?.url ?? '');
    final iconoController =
        TextEditingController(text: accion?.icono ?? '');
    final tipoController = TextEditingController(text: accion?.tipo ?? '');
    var activa = accion?.activo ?? true;

    await showDialog<void>(
      context: providerContext,
      builder: (context) {
        return AlertDialog(
          title: Text(isEditing ? 'Editar accion' : 'Crear accion'),
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
                        controller: codigoController,
                        decoration: const InputDecoration(labelText: 'Codigo'),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Campo requerido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: defaultPadding / 2),
                      TextFormField(
                        controller: descripcionController,
                        decoration:
                            const InputDecoration(labelText: 'Descripcion'),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Campo requerido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: defaultPadding / 2),
                      TextFormField(
                        controller: urlController,
                        decoration: const InputDecoration(labelText: 'URL'),
                      ),
                      const SizedBox(height: defaultPadding / 2),
                      TextFormField(
                        controller: iconoController,
                        decoration: const InputDecoration(labelText: 'Icono'),
                      ),
                      const SizedBox(height: defaultPadding / 2),
                      TextFormField(
                        controller: tipoController,
                        decoration: const InputDecoration(labelText: 'Tipo'),
                      ),
                      const SizedBox(height: defaultPadding / 2),
                      SwitchListTile(
                        value: activa,
                        onChanged: (value) {
                          setState(() => activa = value);
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
                final payload = Accion(
                  id: accion?.id,
                  nombre: nombreController.text.trim(),
                  codigo: codigoController.text.trim(),
                  descripcion: descripcionController.text.trim(),
                  url: urlController.text.trim(),
                  icono: iconoController.text.trim(),
                  tipo: tipoController.text.trim(),
                  activo: activa,
                );
                final provider = providerContext.read<AccionesProvider>();
                final ok = isEditing
                    ? await provider.updateAccion(payload)
                    : await provider.createAccion(payload);
                if (!ok) {
                  showAppToast(
                    providerContext,
                    provider.errorMessage ?? 'No se pudo guardar la accion.',
                    isError: true,
                  );
                  return;
                }
                if (context.mounted) {
                  Navigator.of(context).pop();
                  showAppToast(
                    providerContext,
                    isEditing ? 'Accion actualizada.' : 'Accion creada.',
                  );
                  providerContext
                      .read<RolesProvider>()
                      .fetchAccionesDisponibles();
                }
              },
              child: Text(isEditing ? 'Guardar' : 'Crear'),
            ),
          ],
        );
      },
    );

    nombreController.dispose();
    codigoController.dispose();
    descripcionController.dispose();
    urlController.dispose();
    iconoController.dispose();
    tipoController.dispose();
  }

  Future<void> _confirmDeleteRol(
    BuildContext providerContext,
    Rol rol,
  ) async {
    if (rol.id == null) {
      showAppToast(
        providerContext,
        'Rol sin ID para eliminar.',
        isError: true,
      );
      return;
    }
    final shouldDelete = await showDialog<bool>(
      context: providerContext,
      builder: (context) {
        return AlertDialog(
          title: const Text('Eliminar rol'),
          content: Text(
            'Deseas eliminar el rol "${rol.nombre}"?',
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
    final provider = providerContext.read<RolesProvider>();
    final ok = await provider.deleteRol(rol.id!);
    if (!ok) {
      showAppToast(
        providerContext,
        provider.errorMessage ?? 'No se pudo eliminar el rol.',
        isError: true,
      );
      return;
    }
    showAppToast(providerContext, 'Rol eliminado.');
  }

  Future<void> _confirmDeleteAccion(
    BuildContext providerContext,
    Accion accion,
  ) async {
    if (accion.id == null) {
      showAppToast(
        providerContext,
        'Accion sin ID para eliminar.',
        isError: true,
      );
      return;
    }
    final shouldDelete = await showDialog<bool>(
      context: providerContext,
      builder: (context) {
        return AlertDialog(
          title: const Text('Eliminar accion'),
          content: Text(
            'Deseas eliminar la accion "${accion.nombre}"?',
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
    final provider = providerContext.read<AccionesProvider>();
    final ok = await provider.deleteAccion(accion.id!);
    if (!ok) {
      showAppToast(
        providerContext,
        provider.errorMessage ?? 'No se pudo eliminar la accion.',
        isError: true,
      );
      return;
    }
    showAppToast(providerContext, 'Accion eliminada.');
    providerContext.read<RolesProvider>().fetchAccionesDisponibles();
  }
}

class _RolesList extends StatelessWidget {
  const _RolesList({
    required this.roles,
    required this.accionesDisponibles,
    required this.onEdit,
    required this.onDelete,
  });

  final List<Rol> roles;
  final List<Accion> accionesDisponibles;
  final void Function(Rol rol) onEdit;
  final void Function(Rol rol) onDelete;

  @override
  Widget build(BuildContext context) {
    if (roles.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(defaultPadding),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.all(Radius.circular(10)),
        ),
        child: const Text('Sin roles registrados.'),
      );
    }

    final accionesById = <int, Accion>{
      for (final accion in accionesDisponibles)
        if (accion.id != null) accion.id!: accion,
    };

    if (Responsive.isMobile(context)) {
      return Column(
        children: roles
            .map(
              (rol) => Card(
                child: ListTile(
                  title: Text(rol.nombre),
                  subtitle: Text(rol.descripcion),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _EstadoChip(activo: rol.activo),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => onEdit(rol),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => onDelete(rol),
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
        final cardWidth = maxWidth > 1000 ? 1000.0 : maxWidth;
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
                    DataColumn(label: Text('Descripcion')),
                    DataColumn(label: Text('Permisos')),
                    DataColumn(label: Text('Activo')),
                    DataColumn(label: Text('Acciones')),
                  ],
                  rows: roles
                      .map(
                        (rol) => DataRow(
                          cells: [
                            DataCell(Text(rol.nombre)),
                            DataCell(Text(rol.descripcion)),
                            DataCell(
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: _resolveRolAccionesLabels(
                                  rol,
                                  accionesById,
                                )
                                    .map(
                                      (label) => Chip(
                                        label: Text(label),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ),
                            DataCell(_EstadoChip(activo: rol.activo)),
                            DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined),
                                    onPressed: () => onEdit(rol),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline),
                                    onPressed: () => onDelete(rol),
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

List<String> _resolveRolAccionesLabels(
  Rol rol,
  Map<int, Accion> accionesById,
) {
  final seen = <String>{};
  if (rol.accionesIds.isNotEmpty) {
    final labels = <String>[];
    for (final accionId in rol.accionesIds) {
      final accion = accionesById[accionId];
      if (accion != null) {
        final label =
            accion.nombre.isNotEmpty ? accion.nombre : accion.codigo;
        if (seen.add(label)) {
          labels.add(label);
        }
      } else {
        final label = '#$accionId';
        if (seen.add(label)) {
          labels.add(label);
        }
      }
    }
    return labels;
  }
  if (rol.permisos.isNotEmpty) {
    final labels = <String>[];
    for (final permiso in rol.permisos) {
      if (seen.add(permiso)) {
        labels.add(permiso);
      }
    }
    return labels;
  }
  return const [];
}

class _AccionesList extends StatelessWidget {
  const _AccionesList({
    required this.acciones,
    required this.onEdit,
    required this.onDelete,
  });

  final List<Accion> acciones;
  final void Function(Accion accion) onEdit;
  final void Function(Accion accion) onDelete;

  @override
  Widget build(BuildContext context) {
    if (acciones.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(defaultPadding),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.all(Radius.circular(10)),
        ),
        child: const Text('Sin acciones registradas.'),
      );
    }

    if (Responsive.isMobile(context)) {
      return Column(
        children: acciones
            .map(
              (accion) => Card(
                child: ListTile(
                  title: Text(
                    accion.nombre.isNotEmpty ? accion.nombre : accion.codigo,
                  ),
                  subtitle: Text(
                    accion.descripcion.isEmpty ? '-' : accion.descripcion,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _EstadoChip(activo: accion.activo),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => onEdit(accion),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => onDelete(accion),
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
        final cardWidth = maxWidth > 1000 ? 1000.0 : maxWidth;
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
                    DataColumn(label: Text('Codigo')),
                    DataColumn(label: Text('Descripcion')),
                    DataColumn(label: Text('URL')),
                    DataColumn(label: Text('Tipo')),
                    DataColumn(label: Text('Activo')),
                    DataColumn(label: Text('Acciones')),
                  ],
                  rows: acciones
                      .map(
                        (accion) => DataRow(
                          cells: [
                            DataCell(
                              Text(
                                accion.nombre.isNotEmpty
                                    ? accion.nombre
                                    : accion.codigo,
                              ),
                            ),
                            DataCell(Text(accion.codigo)),
                            DataCell(
                              Text(
                                accion.descripcion.isEmpty
                                    ? '-'
                                    : accion.descripcion,
                              ),
                            ),
                            DataCell(
                              Text(accion.url.isEmpty ? '-' : accion.url),
                            ),
                            DataCell(
                              Text(accion.tipo.isEmpty ? '-' : accion.tipo),
                            ),
                            DataCell(_EstadoChip(activo: accion.activo)),
                            DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined),
                                    onPressed: () => onEdit(accion),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline),
                                    onPressed: () => onDelete(accion),
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
