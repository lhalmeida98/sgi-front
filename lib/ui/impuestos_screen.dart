import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../domain/models/impuesto.dart';
import '../resource/theme/dimens.dart';
import '../services/api_client.dart';
import '../services/impuestos_service.dart';
import '../states/auth_provider.dart';
import '../states/impuestos_provider.dart';
import '../ui/shared/feedback.dart';
import '../ui/shared/section_header.dart';
import '../utils/responsive.dart';

class ImpuestosScreen extends StatefulWidget {
  const ImpuestosScreen({super.key});

  @override
  State<ImpuestosScreen> createState() => _ImpuestosScreenState();
}

class _ImpuestosScreenState extends State<ImpuestosScreen> {
  late final ImpuestosProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = ImpuestosProvider(ImpuestosService(ApiClient()));
    _provider.fetchImpuestos();
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
      child: Consumer<ImpuestosProvider>(
        builder: (context, provider, _) {
          final authProvider = context.watch<AuthProvider>();
          final empresaId = authProvider.empresaId;
          final impuestos = empresaId == null
              ? provider.impuestos
              : provider.impuestos
                  .where(
                    (impuesto) =>
                        impuesto.empresaId == null ||
                        impuesto.empresaId == empresaId,
                  )
                  .toList();
          final isMobile = Responsive.isMobile(context);
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(defaultPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeader(
                    title: 'Impuestos',
                    subtitle: 'Reglas de IVA y tributos.',
                    actions: [
                      IconButton(
                        tooltip: 'Refrescar',
                        onPressed: provider.fetchImpuestos,
                        icon: const Icon(Icons.refresh),
                      ),
                      if (isMobile)
                        IconButton(
                          tooltip: 'Crear impuesto',
                          onPressed: () => _openImpuestoDialog(context),
                          icon: const Icon(Icons.add),
                        )
                      else
                        FilledButton.icon(
                          onPressed: () => _openImpuestoDialog(context),
                          icon: const Icon(Icons.add),
                          label: const Text('Crear impuesto'),
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
                  _ImpuestosList(
                    impuestos: impuestos,
                    onEdit: (impuesto) =>
                        _openImpuestoDialog(context, impuesto: impuesto),
                    onToggleActivo: (impuesto, value) =>
                        _toggleActivo(context, impuesto, value),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _openImpuestoDialog(
    BuildContext providerContext, {
    Impuesto? impuesto,
  }) async {
    final isEditing = impuesto != null;
    final formKey = GlobalKey<FormState>();
    final codigoController =
        TextEditingController(text: impuesto?.codigo ?? '');
    final codigoPorcentajeController =
        TextEditingController(text: impuesto?.codigoPorcentaje ?? '');
    final tarifaController = TextEditingController(
      text: impuesto != null ? impuesto.tarifa.toStringAsFixed(2) : '',
    );
    final descripcionController =
        TextEditingController(text: impuesto?.descripcion ?? '');
    var activo = impuesto?.activo ?? true;

    await showDialog<void>(
      context: providerContext,
      builder: (context) {
        return AlertDialog(
          title: Text(isEditing ? 'Editar impuesto' : 'Crear impuesto'),
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
                        controller: codigoPorcentajeController,
                        decoration:
                            const InputDecoration(labelText: 'Codigo porcentaje'),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Campo requerido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: defaultPadding / 2),
                      TextFormField(
                        controller: tarifaController,
                        decoration: const InputDecoration(labelText: 'Tarifa (%)'),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Campo requerido';
                          }
                          if (double.tryParse(value.trim()) == null) {
                            return 'Debe ser numerico';
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
                    providerContext.read<ImpuestosProvider>();
                final payload = Impuesto(
                  id: impuesto?.id,
                  codigo: codigoController.text.trim(),
                  codigoPorcentaje: codigoPorcentajeController.text.trim(),
                  tarifa: double.tryParse(tarifaController.text.trim()) ?? 0,
                  descripcion: descripcionController.text.trim(),
                  activo: activo,
                );
                final ok = isEditing
                    ? await provider.updateImpuesto(payload)
                    : await provider.createImpuesto(payload);
                if (!ok) {
                  showAppToast(
                    providerContext,
                    provider.errorMessage ??
                        'No se pudo guardar el impuesto.',
                    isError: true,
                  );
                  return;
                }
                if (context.mounted) {
                  Navigator.of(context).pop();
                  showAppToast(
                    providerContext,
                    isEditing
                        ? 'Impuesto actualizado.'
                        : 'Impuesto creado.',
                  );
                }
              },
              child: Text(isEditing ? 'Guardar' : 'Crear'),
            ),
          ],
        );
      },
    );

    codigoController.dispose();
    codigoPorcentajeController.dispose();
    tarifaController.dispose();
    descripcionController.dispose();
  }

  Future<void> _toggleActivo(
    BuildContext providerContext,
    Impuesto impuesto,
    bool value,
  ) async {
    final provider = providerContext.read<ImpuestosProvider>();
    final ok = await provider.toggleActivo(impuesto, value);
    if (ok && providerContext.mounted) {
      showAppToast(providerContext, 'Impuesto actualizado.');
    } else if (providerContext.mounted) {
      showAppToast(
        providerContext,
        provider.errorMessage ?? 'No se pudo actualizar.',
        isError: true,
      );
    }
  }
}

class _ImpuestosList extends StatelessWidget {
  const _ImpuestosList({
    required this.impuestos,
    required this.onEdit,
    required this.onToggleActivo,
  });

  final List<Impuesto> impuestos;
  final void Function(Impuesto impuesto) onEdit;
  final void Function(Impuesto impuesto, bool value) onToggleActivo;

  @override
  Widget build(BuildContext context) {
    if (impuestos.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(defaultPadding),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.all(Radius.circular(10)),
        ),
        child: const Text('Sin impuestos registrados.'),
      );
    }

    if (Responsive.isMobile(context)) {
      return Column(
        children: impuestos
            .map(
              (impuesto) => Card(
                child: ListTile(
                  title: Text(impuesto.descripcion),
                  subtitle:
                      Text('Tarifa: ${impuesto.tarifa.toStringAsFixed(2)}%'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Switch(
                        value: impuesto.activo,
                        onChanged: (value) =>
                            onToggleActivo(impuesto, value),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        tooltip: 'Editar',
                        onPressed: () => onEdit(impuesto),
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
        final cardWidth = maxWidth > 1100 ? 980.0 : maxWidth;
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
                    DataColumn(label: Text('Porcentaje')),
                    DataColumn(label: Text('Tarifa')),
                    DataColumn(label: Text('Descripcion')),
                    DataColumn(label: Text('Activo')),
                    DataColumn(label: Text('Acciones')),
                  ],
                  rows: impuestos
                      .map(
                        (impuesto) => DataRow(
                          cells: [
                            DataCell(Text(impuesto.codigo)),
                            DataCell(Text(impuesto.codigoPorcentaje)),
                            DataCell(
                              Text('${impuesto.tarifa.toStringAsFixed(2)}%'),
                            ),
                            DataCell(Text(impuesto.descripcion)),
                            DataCell(
                              Switch(
                                value: impuesto.activo,
                                onChanged: (value) =>
                                    onToggleActivo(impuesto, value),
                              ),
                            ),
                            DataCell(
                              IconButton(
                                tooltip: 'Editar',
                                onPressed: () => onEdit(impuesto),
                                icon: const Icon(Icons.edit_outlined),
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
