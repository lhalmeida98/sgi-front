import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../domain/models/accion.dart';
import '../domain/models/rol.dart';
import '../resource/theme/dimens.dart';
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
                                accionesDisponibles:
                                    rolesProvider.accionesDisponibles,
                              );
                            } else {
                              _openAccionDialog(context);
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
                                accionesDisponibles:
                                    rolesProvider.accionesDisponibles,
                              );
                            } else {
                              _openAccionDialog(context);
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
                    )
                  else
                    _AccionesList(
                      acciones: accionesProvider.acciones,
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
    required List<Accion> accionesDisponibles,
  }) async {
    final formKey = GlobalKey<FormState>();
    final nombreController = TextEditingController();
    final descripcionController = TextEditingController();
    final selected = <String>{};

    await showDialog<void>(
      context: providerContext,
      builder: (context) {
        return AlertDialog(
          title: const Text('Crear rol'),
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
                                  label: Text(accion.codigo),
                                  selected: selected.contains(accion.codigo),
                                  onSelected: (value) {
                                    setState(() {
                                      if (value) {
                                        selected.add(accion.codigo);
                                      } else {
                                        selected.remove(accion.codigo);
                                      }
                                    });
                                  },
                                ),
                              )
                              .toList(),
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
                final payload = Rol(
                  nombre: nombreController.text.trim(),
                  descripcion: descripcionController.text.trim(),
                  permisos: selected.toList(),
                );
                final provider = providerContext.read<RolesProvider>();
                final ok = await provider.createRol(payload);
                if (!ok) {
                  showAppToast(
                    providerContext,
                    provider.errorMessage ?? 'No se pudo crear el rol.',
                    isError: true,
                  );
                  return;
                }
                if (context.mounted) {
                  Navigator.of(context).pop();
                  showAppToast(providerContext, 'Rol creado.');
                }
              },
              child: const Text('Crear'),
            ),
          ],
        );
      },
    );

    nombreController.dispose();
    descripcionController.dispose();
  }

  Future<void> _openAccionDialog(BuildContext providerContext) async {
    final formKey = GlobalKey<FormState>();
    final codigoController = TextEditingController();
    final descripcionController = TextEditingController();
    var activa = true;

    await showDialog<void>(
      context: providerContext,
      builder: (context) {
        return AlertDialog(
          title: const Text('Crear accion'),
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
                  codigo: codigoController.text.trim().toUpperCase(),
                  descripcion: descripcionController.text.trim(),
                  activo: activa,
                );
                final provider = providerContext.read<AccionesProvider>();
                final ok = await provider.createAccion(payload);
                if (!ok) {
                  showAppToast(
                    providerContext,
                    provider.errorMessage ?? 'No se pudo crear la accion.',
                    isError: true,
                  );
                  return;
                }
                if (context.mounted) {
                  Navigator.of(context).pop();
                  showAppToast(providerContext, 'Accion creada.');
                }
              },
              child: const Text('Crear'),
            ),
          ],
        );
      },
    );

    codigoController.dispose();
    descripcionController.dispose();
  }
}

class _RolesList extends StatelessWidget {
  const _RolesList({required this.roles});

  final List<Rol> roles;

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

    if (Responsive.isMobile(context)) {
      return Column(
        children: roles
            .map(
              (rol) => Card(
                child: ListTile(
                  title: Text(rol.nombre),
                  subtitle: Text(rol.descripcion),
                  trailing: Text('${rol.permisos.length} permisos'),
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
                                children: rol.permisos
                                    .map(
                                      (permiso) => Chip(
                                        label: Text(permiso),
                                      ),
                                    )
                                    .toList(),
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

class _AccionesList extends StatelessWidget {
  const _AccionesList({required this.acciones});

  final List<Accion> acciones;

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
                  title: Text(accion.codigo),
                  subtitle: Text(accion.descripcion),
                  trailing: _EstadoChip(activo: accion.activo),
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
                    DataColumn(label: Text('Codigo')),
                    DataColumn(label: Text('Descripcion')),
                    DataColumn(label: Text('Activo')),
                  ],
                  rows: acciones
                      .map(
                        (accion) => DataRow(
                          cells: [
                            DataCell(Text(accion.codigo)),
                            DataCell(Text(accion.descripcion)),
                            DataCell(_EstadoChip(activo: accion.activo)),
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
