import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../domain/models/categoria.dart';
import '../domain/models/empresa.dart';
import '../resource/theme/dimens.dart';
import '../services/api_client.dart';
import '../services/categorias_service.dart';
import '../services/empresas_service.dart';
import '../states/auth_provider.dart';
import '../states/categorias_provider.dart';
import '../states/empresas_provider.dart';
import '../ui/shared/feedback.dart';
import '../ui/shared/section_header.dart';
import '../utils/responsive.dart';

class CategoriasScreen extends StatefulWidget {
  const CategoriasScreen({super.key});

  @override
  State<CategoriasScreen> createState() => _CategoriasScreenState();
}

class _CategoriasScreenState extends State<CategoriasScreen> {
  late final CategoriasProvider _categoriasProvider;
  late final EmpresasProvider _empresasProvider;

  @override
  void initState() {
    super.initState();
    final client = ApiClient();
    _categoriasProvider = CategoriasProvider(CategoriasService(client));
    _empresasProvider = EmpresasProvider(EmpresasService(client));
    _categoriasProvider.fetchCategorias();
    _empresasProvider.fetchEmpresas();
  }

  @override
  void dispose() {
    _categoriasProvider.dispose();
    _empresasProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _categoriasProvider),
        ChangeNotifierProvider.value(value: _empresasProvider),
      ],
      child: Consumer2<CategoriasProvider, EmpresasProvider>(
        builder: (context, categoriasProvider, empresasProvider, _) {
          final isMobile = Responsive.isMobile(context);
          final authProvider = context.watch<AuthProvider>();
          final empresaId = authProvider.empresaId;
          final empresas = empresaId == null
              ? empresasProvider.empresas
              : empresasProvider.empresas
                  .where((empresa) => empresa.id == empresaId)
                  .toList();
          final categorias = empresaId == null
              ? categoriasProvider.categorias
              : categoriasProvider.categorias
                  .where(
                    (categoria) =>
                        categoria.empresaId == null ||
                        categoria.empresaId == empresaId,
                  )
                  .toList();
          final errorMessage = categoriasProvider.errorMessage ??
              empresasProvider.errorMessage;
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(defaultPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeader(
                    title: 'Categorias',
                    subtitle: 'Clasificacion de productos por empresa.',
                    actions: [
                      IconButton(
                        tooltip: 'Refrescar',
                        onPressed: () {
                          categoriasProvider.fetchCategorias();
                          empresasProvider.fetchEmpresas();
                        },
                        icon: const Icon(Icons.refresh),
                      ),
                      if (isMobile)
                        IconButton(
                          tooltip: 'Crear categoria',
                          onPressed: () => _openCategoriaDialog(
                            context,
                            empresas: empresas,
                            canSelectEmpresa: authProvider.isAdmin,
                          ),
                          icon: const Icon(Icons.add),
                        )
                      else
                        FilledButton.icon(
                          onPressed: () => _openCategoriaDialog(
                            context,
                            empresas: empresas,
                            canSelectEmpresa: authProvider.isAdmin,
                          ),
                          icon: const Icon(Icons.add),
                          label: const Text('Crear categoria'),
                        ),
                    ],
                  ),
                  if (categoriasProvider.isLoading ||
                      empresasProvider.isLoading)
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
                  _CategoriasGroupedList(
                    categorias: categorias,
                    empresas: empresas,
                    onEdit: (categoria) => _openCategoriaDialog(
                      context,
                      categoria: categoria,
                      empresas: empresas,
                      canSelectEmpresa: authProvider.isAdmin,
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

  Future<void> _openCategoriaDialog(
    BuildContext providerContext, {
    Categoria? categoria,
    required List<Empresa> empresas,
    required bool canSelectEmpresa,
  }) async {
    final isEditing = categoria != null;
    final formKey = GlobalKey<FormState>();
    final nombreController =
        TextEditingController(text: categoria?.nombre ?? '');
    final descripcionController =
        TextEditingController(text: categoria?.descripcion ?? '');
    int? empresaId = categoria?.empresaId;
    if (!isEditing && empresas.length == 1) {
      empresaId ??= empresas.first.id;
    }

    await showDialog<void>(
      context: providerContext,
      builder: (context) {
        return AlertDialog(
          title: Text(isEditing ? 'Editar categoria' : 'Crear categoria'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return SizedBox(
                width: 420,
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (empresas.isNotEmpty)
                        canSelectEmpresa
                            ? DropdownButtonFormField<int>(
                                value: empresaId,
                                items: empresas
                                    .map(
                                      (empresa) => DropdownMenuItem(
                                        value: empresa.id,
                                        child: Text(empresa.razonSocial),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) {
                                  setState(() => empresaId = value);
                                },
                                decoration: const InputDecoration(
                                  labelText: 'Empresa',
                                ),
                              )
                            : TextFormField(
                                readOnly: true,
                                initialValue: empresas
                                    .firstWhere(
                                      (empresa) => empresa.id == empresaId,
                                      orElse: () => empresas.first,
                                    )
                                    .razonSocial,
                                decoration: const InputDecoration(
                                  labelText: 'Empresa',
                                ),
                              ),
                      if (empresas.isNotEmpty)
                        const SizedBox(height: defaultPadding / 2),
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
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Campo requerido';
                          }
                          return null;
                        },
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
                if (!mounted) {
                  return;
                }
                final provider =
                    providerContext.read<CategoriasProvider>();
                final payload = Categoria(
                  id: categoria?.id,
                  empresaId: empresaId,
                  nombre: nombreController.text.trim(),
                  descripcion: descripcionController.text.trim(),
                );
                final ok = isEditing
                    ? await provider.updateCategoria(payload)
                    : await provider.createCategoria(payload);
                if (!ok) {
                  showAppToast(
                    providerContext,
                    provider.errorMessage ??
                        'No se pudo guardar la categoria.',
                    isError: true,
                  );
                  return;
                }
                if (mounted) {
                  Navigator.of(context).pop();
                  showAppToast(
                    providerContext,
                    isEditing
                        ? 'Categoria actualizada.'
                        : 'Categoria creada.',
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
}

class _CategoriasGroupedList extends StatelessWidget {
  const _CategoriasGroupedList({
    required this.categorias,
    required this.empresas,
    required this.onEdit,
  });

  final List<Categoria> categorias;
  final List<Empresa> empresas;
  final void Function(Categoria categoria) onEdit;

  @override
  Widget build(BuildContext context) {
    if (categorias.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(defaultPadding),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.all(Radius.circular(10)),
        ),
        child: const Text('Sin categorias registradas.'),
      );
    }

    final empresaMap = {
      for (final empresa in empresas) empresa.id: empresa.razonSocial,
    };

    final grouped = <int?, List<Categoria>>{};
    for (final categoria in categorias) {
      grouped.putIfAbsent(categoria.empresaId, () => []).add(categoria);
    }

    final entries = grouped.entries.toList()
      ..sort((a, b) {
        final nameA = _empresaNombre(a.key, empresaMap, a.value);
        final nameB = _empresaNombre(b.key, empresaMap, b.value);
        return nameA.compareTo(nameB);
      });

    return Column(
      children: entries
          .map(
            (entry) => _EmpresaCategoriaGroup(
              empresaId: entry.key,
              empresaNombre: _empresaNombre(entry.key, empresaMap, entry.value),
              categorias: entry.value,
              onEdit: onEdit,
            ),
          )
          .toList(),
    );
  }

  String _empresaNombre(
    int? empresaId,
    Map<int?, String> empresaMap,
    List<Categoria> categorias,
  ) {
    if (empresaId == null) {
      return categorias.first.empresaNombre ?? 'Sin empresa';
    }
    return empresaMap[empresaId] ?? 'Empresa #$empresaId';
  }
}

class _EmpresaCategoriaGroup extends StatelessWidget {
  const _EmpresaCategoriaGroup({
    required this.empresaId,
    required this.empresaNombre,
    required this.categorias,
    required this.onEdit,
  });

  final int? empresaId;
  final String empresaNombre;
  final List<Categoria> categorias;
  final void Function(Categoria categoria) onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = Responsive.isMobile(context);
    return Container(
      margin: const EdgeInsets.only(bottom: defaultPadding),
      padding: const EdgeInsets.all(defaultPadding),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.all(Radius.circular(12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      empresaNombre,
                      style: theme.textTheme.titleMedium,
                    ),
                    if (empresaId != null)
                      Text(
                        'Empresa ID: $empresaId',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withAlpha(153),
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withAlpha(18),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${categorias.length} categorias',
                  style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: defaultPadding),
          if (isMobile)
            Column(
              children: categorias
                  .map(
                    (categoria) => Card(
                      child: ListTile(
                        title: Text(categoria.nombre),
                        subtitle: Text(categoria.descripcion),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          tooltip: 'Editar',
                          onPressed: () => onEdit(categoria),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            )
          else
            DataTable(
              columns: const [
                DataColumn(label: Text('Nombre')),
                DataColumn(label: Text('Descripcion')),
                DataColumn(label: Text('Acciones')),
              ],
              rows: categorias
                  .map(
                    (categoria) => DataRow(
                      cells: [
                        DataCell(Text(categoria.nombre)),
                        DataCell(Text(categoria.descripcion)),
                        DataCell(
                          IconButton(
                            tooltip: 'Editar',
                            onPressed: () => onEdit(categoria),
                            icon: const Icon(Icons.edit_outlined),
                          ),
                        ),
                      ],
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }
}
