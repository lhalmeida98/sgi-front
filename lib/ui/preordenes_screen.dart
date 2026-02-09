import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../domain/models/cliente.dart';
import '../domain/models/empresa.dart';
import '../domain/models/preorden.dart';
import '../domain/models/producto.dart';
import '../resource/theme/dimens.dart';
import '../services/api_client.dart';
import '../services/clientes_service.dart';
import '../services/empresas_service.dart';
import '../services/preordenes_service.dart';
import '../services/productos_service.dart';
import '../states/auth_provider.dart';
import '../states/clientes_provider.dart';
import '../states/empresas_provider.dart';
import '../states/preordenes_provider.dart';
import '../states/productos_provider.dart';
import '../ui/shared/feedback.dart';
import '../ui/shared/section_header.dart';
import '../utils/responsive.dart';

class PreordenesScreen extends StatefulWidget {
  const PreordenesScreen({super.key});

  @override
  State<PreordenesScreen> createState() => _PreordenesScreenState();
}

class _PreordenesScreenState extends State<PreordenesScreen> {
  late final ApiClient _client;
  late final PreordenesProvider _preordenesProvider;
  late final EmpresasProvider _empresasProvider;
  late final ClientesProvider _clientesProvider;
  late final ProductosProvider _productosProvider;

  @override
  void initState() {
    super.initState();
    _client = ApiClient();
    _preordenesProvider = PreordenesProvider(PreordenesService(_client));
    _empresasProvider = EmpresasProvider(EmpresasService(_client));
    _clientesProvider = ClientesProvider(ClientesService(_client));
    _productosProvider = ProductosProvider(ProductosService(_client));

    _preordenesProvider.fetchPreordenes();
    _empresasProvider.fetchEmpresas();
    _clientesProvider.fetchClientes();
    _productosProvider.fetchProductos();
  }

  @override
  void dispose() {
    _preordenesProvider.dispose();
    _empresasProvider.dispose();
    _clientesProvider.dispose();
    _productosProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _preordenesProvider),
        ChangeNotifierProvider.value(value: _empresasProvider),
        ChangeNotifierProvider.value(value: _clientesProvider),
        ChangeNotifierProvider.value(value: _productosProvider),
      ],
      child: Consumer4<PreordenesProvider, EmpresasProvider, ClientesProvider,
          ProductosProvider>(
        builder: (context, preordenesProvider, empresasProvider,
            clientesProvider, productosProvider, _) {
          final authProvider = context.watch<AuthProvider>();
          final empresaId = authProvider.empresaId;
          final empresas = empresaId == null
              ? empresasProvider.empresas
              : empresasProvider.empresas
                  .where((empresa) => empresa.id == empresaId)
                  .toList();
          final clientes = empresaId == null
              ? clientesProvider.clientes
              : clientesProvider.clientes
                  .where(
                    (cliente) =>
                        cliente.empresaId == null ||
                        cliente.empresaId == empresaId,
                  )
                  .toList();
          final productos = empresaId == null
              ? productosProvider.productos
              : productosProvider.productos
                  .where(
                    (producto) =>
                        producto.empresaId == null ||
                        producto.empresaId == empresaId,
                  )
                  .toList();
          final preordenes = empresaId == null
              ? preordenesProvider.preordenes
              : preordenesProvider.preordenes
                  .where((preorden) => preorden.empresaId == empresaId)
                  .toList();
          final isMobile = Responsive.isMobile(context);
          final isLoading = preordenesProvider.isLoading ||
              empresasProvider.isLoading ||
              clientesProvider.isLoading ||
              productosProvider.isLoading;
          final errorMessage = preordenesProvider.errorMessage ??
              empresasProvider.errorMessage ??
              clientesProvider.errorMessage ??
              productosProvider.errorMessage;

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(defaultPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeader(
                    title: 'Preordenes',
                    subtitle: 'Gestion de preordenes y reserva de stock.',
                    actions: [
                      IconButton(
                        tooltip: 'Refrescar',
                        onPressed: preordenesProvider.fetchPreordenes,
                        icon: const Icon(Icons.refresh),
                      ),
                      if (isMobile)
                        IconButton(
                          tooltip: 'Crear preorden',
                          onPressed: () => _openPreordenDialog(
                            context,
                            empresas: empresas,
                            clientes: clientes,
                            productos: productos,
                            defaultEmpresaId: empresaId,
                            canSelectEmpresa: authProvider.isAdmin,
                          ),
                          icon: const Icon(Icons.add),
                        )
                      else
                        FilledButton.icon(
                          onPressed: () => _openPreordenDialog(
                            context,
                            empresas: empresas,
                            clientes: clientes,
                            productos: productos,
                            defaultEmpresaId: empresaId,
                            canSelectEmpresa: authProvider.isAdmin,
                          ),
                          icon: const Icon(Icons.add),
                          label: const Text('Crear preorden'),
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
                  _PreordenesList(
                    preordenes: preordenes,
                    onEdit: (preorden) => _openPreordenDialog(
                      context,
                      preorden: preorden,
                      empresas: empresas,
                      clientes: clientes,
                      productos: productos,
                      defaultEmpresaId: empresaId,
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

  Future<void> _openPreordenDialog(
    BuildContext providerContext, {
    Preorden? preorden,
    required List<Empresa> empresas,
    required List<Cliente> clientes,
    required List<Producto> productos,
    int? defaultEmpresaId,
    required bool canSelectEmpresa,
  }) async {
    final isEditing = preorden != null;
    final formKey = GlobalKey<FormState>();
    final dirEstablecimientoController = TextEditingController(
      text: preorden?.dirEstablecimiento ?? '',
    );
    final monedaController =
        TextEditingController(text: preorden?.moneda ?? 'USD');
    final observacionesController = TextEditingController(
      text: preorden?.observaciones ?? '',
    );
    int? empresaId = preorden?.empresaId ?? defaultEmpresaId;
    if (!isEditing && empresaId == null && empresas.length == 1) {
      empresaId = empresas.first.id;
    }
    int? clienteId = preorden?.clienteId;
    var reservaInventario = preorden?.reservaInventario ?? true;
    final items = preorden?.items
            .map(
              (item) => _PreordenItemDraft(
                productoId: item.productoId,
                cantidad: item.cantidad,
                descuento: item.descuento,
              ),
            )
            .toList() ??
        [_PreordenItemDraft(cantidad: 1, descuento: 0)];

    await showDialog<void>(
      context: providerContext,
      builder: (context) {
        return AlertDialog(
          title: Text(isEditing ? 'Editar preorden' : 'Crear preorden'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return SizedBox(
                width: 680,
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                                validator: (value) {
                                  if (value == null) {
                                    return 'Seleccione empresa';
                                  }
                                  return null;
                                },
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
                        const SizedBox(height: defaultPadding / 2),
                        DropdownButtonFormField<int>(
                          value: clienteId,
                          items: clientes
                              .map(
                                (cliente) => DropdownMenuItem(
                                  value: cliente.id,
                                  child: Text(cliente.razonSocial),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            setState(() => clienteId = value);
                          },
                          decoration:
                              const InputDecoration(labelText: 'Cliente'),
                          validator: (value) {
                            if (value == null) {
                              return 'Seleccione cliente';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: defaultPadding / 2),
                        TextFormField(
                          controller: dirEstablecimientoController,
                          decoration: const InputDecoration(
                            labelText: 'Direccion establecimiento',
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Campo requerido';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: defaultPadding / 2),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: monedaController,
                                decoration:
                                    const InputDecoration(labelText: 'Moneda'),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Campo requerido';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: defaultPadding / 2),
                            Expanded(
                              child: SwitchListTile(
                                value: reservaInventario,
                                onChanged: (value) {
                                  setState(() => reservaInventario = value);
                                },
                                contentPadding: EdgeInsets.zero,
                                title: const Text('Reserva inventario'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: defaultPadding / 2),
                        TextFormField(
                          controller: observacionesController,
                          maxLines: 2,
                          decoration:
                              const InputDecoration(labelText: 'Observaciones'),
                        ),
                        const SizedBox(height: defaultPadding),
                        _ItemsTable(
                          items: items,
                          productos: productos,
                          onAddItem: () {
                            setState(() {
                              items.add(
                                _PreordenItemDraft(cantidad: 1, descuento: 0),
                              );
                            });
                          },
                          onRemoveItem: (index) {
                            if (items.length == 1) {
                              return;
                            }
                            setState(() {
                              items.removeAt(index);
                            });
                          },
                          onChanged: () => setState(() {}),
                        ),
                        const SizedBox(height: defaultPadding),
                        _TotalPanel(items: items, productos: productos),
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
                if (items.any(
                    (item) => item.productoId == null || item.cantidad <= 0)) {
                  showAppToast(
                    providerContext,
                    'Completa los items con producto y cantidad.',
                    isError: true,
                  );
                  return;
                }
                final provider =
                    providerContext.read<PreordenesProvider>();
                final payload = Preorden(
                  id: preorden?.id,
                  empresaId: empresaId!,
                  clienteId: clienteId!,
                  dirEstablecimiento: dirEstablecimientoController.text.trim(),
                  moneda: monedaController.text.trim(),
                  observaciones: observacionesController.text.trim(),
                  reservaInventario: reservaInventario,
                  items: items
                      .map(
                        (item) => PreordenItem(
                          productoId: item.productoId!,
                          cantidad: item.cantidad,
                          descuento: item.descuento,
                        ),
                      )
                      .toList(),
                );
                final ok = isEditing
                    ? await provider.updatePreorden(payload)
                    : await provider.createPreorden(payload);
                if (!ok) {
                  showAppToast(
                    providerContext,
                    provider.errorMessage ??
                        'No se pudo guardar la preorden.',
                    isError: true,
                  );
                  return;
                }
                if (context.mounted) {
                  Navigator.of(context).pop();
                  showAppToast(
                    providerContext,
                    isEditing
                        ? 'Preorden actualizada.'
                        : 'Preorden creada.',
                  );
                }
              },
              child: Text(isEditing ? 'Guardar' : 'Crear'),
            ),
          ],
        );
      },
    );

    dirEstablecimientoController.dispose();
    monedaController.dispose();
    observacionesController.dispose();
  }
}

class _ItemsTable extends StatefulWidget {
  const _ItemsTable({
    required this.items,
    required this.productos,
    required this.onAddItem,
    required this.onRemoveItem,
    this.onChanged,
  });

  final List<_PreordenItemDraft> items;
  final List<Producto> productos;
  final VoidCallback onAddItem;
  final void Function(int index) onRemoveItem;
  final VoidCallback? onChanged;

  @override
  State<_ItemsTable> createState() => _ItemsTableState();
}

class _ItemsTableState extends State<_ItemsTable> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Items', style: Theme.of(context).textTheme.titleSmall),
            const Spacer(),
            TextButton.icon(
              onPressed: widget.onAddItem,
              icon: const Icon(Icons.add),
              label: const Text('Agregar'),
            ),
          ],
        ),
        const SizedBox(height: defaultPadding / 2),
        Column(
          children: List.generate(widget.items.length, (index) {
            final item = widget.items[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: defaultPadding / 2),
              child: Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: DropdownButtonFormField<int>(
                      value: item.productoId,
                      items: widget.productos
                          .map(
                            (producto) => DropdownMenuItem(
                              value: producto.id,
                              child: Text(
                                '${producto.codigo} - ${producto.descripcion}',
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          item.productoId = value;
                        });
                        widget.onChanged?.call();
                      },
                      decoration: const InputDecoration(labelText: 'Producto'),
                    ),
                  ),
                  const SizedBox(width: defaultPadding / 2),
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      initialValue: item.cantidad.toString(),
                      decoration: const InputDecoration(labelText: 'Cantidad'),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        setState(() {
                          item.cantidad = int.tryParse(value) ?? 0;
                        });
                        widget.onChanged?.call();
                      },
                    ),
                  ),
                  const SizedBox(width: defaultPadding / 2),
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      initialValue: item.descuento.toStringAsFixed(2),
                      decoration: const InputDecoration(labelText: 'Descuento'),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        setState(() {
                          item.descuento = double.tryParse(value) ?? 0;
                        });
                        widget.onChanged?.call();
                      },
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      widget.onRemoveItem(index);
                      widget.onChanged?.call();
                    },
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _TotalPanel extends StatelessWidget {
  const _TotalPanel({required this.items, required this.productos});

  final List<_PreordenItemDraft> items;
  final List<Producto> productos;

  @override
  Widget build(BuildContext context) {
    double subtotal = 0;
    double descuentoTotal = 0;
    for (final item in items) {
      final producto = productos.firstWhere(
        (producto) => producto.id == item.productoId,
        orElse: () => Producto(
          id: 0,
          codigo: '-',
          descripcion: '-',
          precioUnitario: 0,
          categoriaId: 0,
          impuestoId: 0,
        ),
      );
      subtotal += producto.precioUnitario * item.cantidad;
      descuentoTotal += item.descuento;
    }
    final total = subtotal - descuentoTotal;

    return Container(
      padding: const EdgeInsets.all(defaultPadding),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withAlpha(204),
        borderRadius: const BorderRadius.all(Radius.circular(10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Totales', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: defaultPadding / 2),
          _TotalRow(label: 'Subtotal', value: subtotal),
          _TotalRow(label: 'Descuento', value: descuentoTotal),
          const Divider(),
          _TotalRow(label: 'Total', value: total, isEmphasis: true),
        ],
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({
    required this.label,
    required this.value,
    this.isEmphasis = false,
  });

  final String label;
  final double value;
  final bool isEmphasis;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: isEmphasis ? FontWeight.w600 : FontWeight.normal,
        );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(value.toStringAsFixed(2), style: style),
        ],
      ),
    );
  }
}

class _PreordenesList extends StatelessWidget {
  const _PreordenesList({
    required this.preordenes,
    required this.onEdit,
  });

  final List<Preorden> preordenes;
  final void Function(Preorden preorden) onEdit;

  @override
  Widget build(BuildContext context) {
    if (preordenes.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(defaultPadding),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.all(Radius.circular(10)),
        ),
        child: const Text('Sin preordenes registradas.'),
      );
    }

    if (Responsive.isMobile(context)) {
      return Column(
        children: preordenes
            .map(
              (preorden) => Card(
                child: ListTile(
                  title: Text('Preorden #${preorden.id ?? '-'}'),
                  subtitle: Text(preorden.dirEstablecimiento),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    tooltip: 'Editar',
                    onPressed: () => onEdit(preorden),
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
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('ID')),
                  DataColumn(label: Text('Empresa')),
                  DataColumn(label: Text('Cliente')),
                  DataColumn(label: Text('Moneda')),
                  DataColumn(label: Text('Reserva')),
                  DataColumn(label: Text('Acciones')),
                ],
                rows: preordenes
                    .map(
                      (preorden) => DataRow(
                        cells: [
                          DataCell(Text(preorden.id?.toString() ?? '-')),
                          DataCell(Text(preorden.empresaId.toString())),
                          DataCell(Text(preorden.clienteId.toString())),
                          DataCell(Text(preorden.moneda)),
                          DataCell(
                            Text(preorden.reservaInventario ? 'Si' : 'No'),
                          ),
                          DataCell(
                            IconButton(
                              tooltip: 'Editar',
                              onPressed: () => onEdit(preorden),
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
        );
      },
    );
  }
}

class _PreordenItemDraft {
  _PreordenItemDraft({
    required this.cantidad,
    required this.descuento,
    this.productoId,
  });

  int? productoId;
  int cantidad;
  double descuento;
}
