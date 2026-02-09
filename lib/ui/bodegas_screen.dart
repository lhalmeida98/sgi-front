import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../domain/models/bodega.dart';
import '../resource/theme/dimens.dart';
import '../services/api_client.dart';
import '../services/bodegas_service.dart';
import '../states/auth_provider.dart';
import '../states/bodegas_provider.dart';
import '../ui/shared/feedback.dart';
import '../ui/shared/section_header.dart';
import '../utils/responsive.dart';

class BodegasScreen extends StatefulWidget {
  const BodegasScreen({super.key});

  @override
  State<BodegasScreen> createState() => _BodegasScreenState();
}

class _BodegasScreenState extends State<BodegasScreen> {
  late final BodegasProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = BodegasProvider(BodegasService(ApiClient()));
    _provider.fetchBodegas();
  }

  @override
  void dispose() {
    _provider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _provider,
      child: Consumer<BodegasProvider>(
        builder: (context, provider, _) {
          final isMobile = Responsive.isMobile(context);
          final authProvider = context.watch<AuthProvider>();
          final empresaId = authProvider.empresaId;
          final bodegas = empresaId == null
              ? provider.bodegas
              : provider.bodegas
                  .where(
                    (bodega) =>
                        bodega.empresaId == null ||
                        bodega.empresaId == empresaId,
                  )
                  .toList();
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(defaultPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeader(
                    title: 'Bodegas',
                    subtitle: 'Administracion de bodegas y ubicaciones.',
                    actions: [
                      IconButton(
                        tooltip: 'Refrescar',
                        onPressed: provider.fetchBodegas,
                        icon: const Icon(Icons.refresh),
                      ),
                      if (isMobile)
                        IconButton(
                          tooltip: 'Crear bodega',
                          onPressed: () => _openBodegaDialog(context),
                          icon: const Icon(Icons.add),
                        )
                      else
                        FilledButton.icon(
                          onPressed: () => _openBodegaDialog(context),
                          icon: const Icon(Icons.add),
                          label: const Text('Crear bodega'),
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
                  _BodegasList(
                    bodegas: bodegas,
                    onEdit: (bodega) =>
                        _openBodegaDialog(context, bodega: bodega),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _openBodegaDialog(
    BuildContext providerContext, {
    Bodega? bodega,
  }) async {
    final isEditing = bodega != null;
    final formKey = GlobalKey<FormState>();
    final nombreController = TextEditingController(text: bodega?.nombre ?? '');
    final descripcionController =
        TextEditingController(text: bodega?.descripcion ?? '');
    final direccionController =
        TextEditingController(text: bodega?.direccion ?? '');
    var activa = bodega?.activa ?? true;

    await showDialog<void>(
      context: providerContext,
      builder: (context) {
        return AlertDialog(
          title: Text(isEditing ? 'Editar bodega' : 'Crear bodega'),
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
                        controller: descripcionController,
                        decoration:
                            const InputDecoration(labelText: 'Descripcion'),
                      ),
                      const SizedBox(height: defaultPadding / 2),
                      TextFormField(
                        controller: direccionController,
                        decoration:
                            const InputDecoration(labelText: 'Direccion'),
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
                        title: const Text('Activa'),
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
                    providerContext.read<BodegasProvider>();
                final payload = Bodega(
                  id: bodega?.id,
                  nombre: nombreController.text.trim(),
                  descripcion: descripcionController.text.trim(),
                  direccion: direccionController.text.trim(),
                  activa: activa,
                );
                final ok = isEditing
                    ? await provider.updateBodega(payload)
                    : await provider.createBodega(payload);
                if (!ok) {
                  showAppToast(
                    providerContext,
                    provider.errorMessage ?? 'No se pudo guardar la bodega.',
                    isError: true,
                  );
                  return;
                }
                if (context.mounted) {
                  Navigator.of(context).pop();
                  showAppToast(
                    providerContext,
                    isEditing ? 'Bodega actualizada.' : 'Bodega creada.',
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
    direccionController.dispose();
  }
}

class _BodegasList extends StatelessWidget {
  const _BodegasList({
    required this.bodegas,
    required this.onEdit,
  });

  final List<Bodega> bodegas;
  final void Function(Bodega bodega) onEdit;

  @override
  Widget build(BuildContext context) {
    if (bodegas.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(defaultPadding),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.all(Radius.circular(10)),
        ),
        child: const Text('Sin bodegas registradas.'),
      );
    }

    if (Responsive.isMobile(context)) {
      return Column(
        children: bodegas
            .map(
              (bodega) => Card(
                child: ListTile(
                  title: Text(bodega.nombre),
                  subtitle: Text(bodega.direccion),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => onEdit(bodega),
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
                    DataColumn(label: Text('Descripcion')),
                    DataColumn(label: Text('Direccion')),
                    DataColumn(label: Text('Activa')),
                    DataColumn(label: Text('Acciones')),
                  ],
                  rows: bodegas
                      .map(
                        (bodega) => DataRow(
                          cells: [
                            DataCell(Text(bodega.nombre)),
                            DataCell(Text(bodega.descripcion)),
                            DataCell(Text(bodega.direccion)),
                            DataCell(_EstadoChip(activa: bodega.activa)),
                            DataCell(
                              IconButton(
                                icon: const Icon(Icons.edit_outlined),
                                onPressed: () => onEdit(bodega),
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
  const _EstadoChip({required this.activa});

  final bool activa;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = activa ? Colors.green : theme.colorScheme.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(24),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        activa ? 'Activa' : 'Inactiva',
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
