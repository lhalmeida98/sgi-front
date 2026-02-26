import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../domain/models/cliente.dart';
import '../domain/models/empresa.dart';
import '../domain/models/preorden.dart';
import '../domain/models/producto.dart';
import '../domain/models/bodega.dart';
import '../resource/theme/dimens.dart';
import '../services/api_client.dart';
import '../services/bodegas_service.dart';
import '../services/clientes_service.dart';
import '../services/empresas_service.dart';
import '../services/preordenes_service.dart';
import '../services/productos_service.dart';
import '../states/auth_provider.dart';
import '../states/bodegas_provider.dart';
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
  late final BodegasProvider _bodegasProvider;

  @override
  void initState() {
    super.initState();
    _client = ApiClient();
    _preordenesProvider = PreordenesProvider(PreordenesService(_client));
    _empresasProvider = EmpresasProvider(EmpresasService(_client));
    _clientesProvider = ClientesProvider(ClientesService(_client));
    _productosProvider = ProductosProvider(ProductosService(_client));
    _bodegasProvider = BodegasProvider(BodegasService(_client));

    _preordenesProvider.fetchPreordenes();
    _empresasProvider.fetchEmpresas();
    _clientesProvider.fetchClientes();
    _productosProvider.fetchProductos();
    _bodegasProvider.fetchBodegas();
  }

  @override
  void dispose() {
    _preordenesProvider.dispose();
    _empresasProvider.dispose();
    _clientesProvider.dispose();
    _productosProvider.dispose();
    _bodegasProvider.dispose();
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
        ChangeNotifierProvider.value(value: _bodegasProvider),
      ],
      child: Consumer5<PreordenesProvider, EmpresasProvider, ClientesProvider,
          ProductosProvider, BodegasProvider>(
        builder: (context, preordenesProvider, empresasProvider,
            clientesProvider, productosProvider, bodegasProvider, _) {
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
          final bodegas = empresaId == null
              ? bodegasProvider.bodegas
              : bodegasProvider.bodegas
                  .where(
                    (bodega) =>
                        bodega.empresaId == null ||
                        bodega.empresaId == empresaId,
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
              productosProvider.isLoading ||
              bodegasProvider.isLoading;
          final errorMessage = preordenesProvider.errorMessage ??
              empresasProvider.errorMessage ??
              clientesProvider.errorMessage ??
              productosProvider.errorMessage ??
              bodegasProvider.errorMessage;

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
                            bodegas: bodegas,
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
                            bodegas: bodegas,
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
                      bodegas: bodegas,
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
    required List<Bodega> bodegas,
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
                bodegaId: item.bodegaId,
                productoId: item.productoId,
                cantidad: item.cantidad,
                descuento: item.descuento,
              ),
            )
            .toList() ??
        [_PreordenItemDraft(cantidad: 1, descuento: 0)];
    int? bodegaId;
    if (items.isNotEmpty) {
      final firstBodegaId = items.first.bodegaId;
      final allSame = items.every((item) => item.bodegaId == firstBodegaId);
      if (allSame) {
        bodegaId = firstBodegaId;
      }
    }

    await showDialog<void>(
      context: providerContext,
      builder: (context) {
        return AlertDialog(
          title: Text(isEditing ? 'Editar preorden' : 'Crear preorden'),
          content: StatefulBuilder(
            builder: (context, setState) {
              final availableBodegas = empresaId == null
                  ? bodegas
                  : bodegas
                      .where(
                        (bodega) =>
                            bodega.empresaId == null ||
                            bodega.empresaId == empresaId,
                      )
                      .toList();
              if (bodegaId == null && availableBodegas.length == 1) {
                bodegaId = availableBodegas.first.id;
                for (final item in items) {
                  item.bodegaId ??= bodegaId;
                }
              }
              final selectedBodegaId = availableBodegas.any(
                (bodega) => bodega.id == bodegaId,
              )
                  ? bodegaId
                  : null;
              return SizedBox(
                width: 900,
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Responsive(
                          mobile: Column(
                            children: [
                              _PreordenDatosCard(
                                empresas: empresas,
                                clientes: clientes,
                                bodegas: availableBodegas,
                                canSelectEmpresa: canSelectEmpresa,
                                empresaId: empresaId,
                                clienteId: clienteId,
                                bodegaId: selectedBodegaId,
                                dirEstablecimientoController:
                                    dirEstablecimientoController,
                                monedaController: monedaController,
                                observacionesController:
                                    observacionesController,
                                reservaInventario: reservaInventario,
                                onEmpresaChanged: (value) {
                                  setState(() {
                                    empresaId = value;
                                    bodegaId = null;
                                    for (final item in items) {
                                      item.bodegaId = null;
                                    }
                                  });
                                },
                                onClienteChanged: (value) =>
                                    setState(() => clienteId = value),
                                onBodegaChanged: (value) {
                                  setState(() {
                                    bodegaId = value;
                                    for (final item in items) {
                                      item.bodegaId = value;
                                    }
                                  });
                                },
                                onReservaChanged: (value) =>
                                    setState(() => reservaInventario = value),
                              ),
                              const SizedBox(height: defaultPadding),
                              _TotalPanel(items: items, productos: productos),
                            ],
                          ),
                          tablet: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 3,
                                child: _PreordenDatosCard(
                                  empresas: empresas,
                                  clientes: clientes,
                                  bodegas: availableBodegas,
                                  canSelectEmpresa: canSelectEmpresa,
                                  empresaId: empresaId,
                                  clienteId: clienteId,
                                  bodegaId: selectedBodegaId,
                                  dirEstablecimientoController:
                                      dirEstablecimientoController,
                                  monedaController: monedaController,
                                  observacionesController:
                                      observacionesController,
                                  reservaInventario: reservaInventario,
                                  onEmpresaChanged: (value) {
                                    setState(() {
                                      empresaId = value;
                                      bodegaId = null;
                                      for (final item in items) {
                                        item.bodegaId = null;
                                      }
                                    });
                                  },
                                  onClienteChanged: (value) =>
                                      setState(() => clienteId = value),
                                  onBodegaChanged: (value) {
                                    setState(() {
                                      bodegaId = value;
                                      for (final item in items) {
                                        item.bodegaId = value;
                                      }
                                    });
                                  },
                                  onReservaChanged: (value) =>
                                      setState(() => reservaInventario = value),
                                ),
                              ),
                              const SizedBox(width: defaultPadding),
                              Expanded(
                                flex: 2,
                                child: _TotalPanel(
                                    items: items, productos: productos),
                              ),
                            ],
                          ),
                          desktop: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 3,
                                child: _PreordenDatosCard(
                                  empresas: empresas,
                                  clientes: clientes,
                                  bodegas: availableBodegas,
                                  canSelectEmpresa: canSelectEmpresa,
                                  empresaId: empresaId,
                                  clienteId: clienteId,
                                  bodegaId: selectedBodegaId,
                                  dirEstablecimientoController:
                                      dirEstablecimientoController,
                                  monedaController: monedaController,
                                  observacionesController:
                                      observacionesController,
                                  reservaInventario: reservaInventario,
                                  onEmpresaChanged: (value) {
                                    setState(() {
                                      empresaId = value;
                                      bodegaId = null;
                                      for (final item in items) {
                                        item.bodegaId = null;
                                      }
                                    });
                                  },
                                  onClienteChanged: (value) =>
                                      setState(() => clienteId = value),
                                  onBodegaChanged: (value) {
                                    setState(() {
                                      bodegaId = value;
                                      for (final item in items) {
                                        item.bodegaId = value;
                                      }
                                    });
                                  },
                                  onReservaChanged: (value) =>
                                      setState(() => reservaInventario = value),
                                ),
                              ),
                              const SizedBox(width: defaultPadding),
                              Expanded(
                                flex: 2,
                                child: _TotalPanel(
                                    items: items, productos: productos),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: defaultPadding),
                        _PreordenItemsCard(
                          items: items,
                          productos: productos,
                          bodegas: availableBodegas,
                          onAddItem: () {
                            setState(() {
                              items.add(
                                _PreordenItemDraft(
                                  cantidad: 1,
                                  descuento: 0,
                                  bodegaId: bodegaId,
                                ),
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
                if (items.any((item) => item.bodegaId == null)) {
                  showAppToast(
                    providerContext,
                    'Asigna bodega a todos los items.',
                    isError: true,
                  );
                  return;
                }
                final provider = providerContext.read<PreordenesProvider>();
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
                          bodegaId: item.bodegaId,
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
                    provider.errorMessage ?? 'No se pudo guardar la preorden.',
                    isError: true,
                  );
                  return;
                }
                if (context.mounted) {
                  Navigator.of(context).pop();
                  showAppToast(
                    providerContext,
                    isEditing ? 'Preorden actualizada.' : 'Preorden creada.',
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

class _PreordenDatosCard extends StatelessWidget {
  const _PreordenDatosCard({
    required this.empresas,
    required this.clientes,
    required this.bodegas,
    required this.canSelectEmpresa,
    required this.empresaId,
    required this.clienteId,
    required this.bodegaId,
    required this.dirEstablecimientoController,
    required this.monedaController,
    required this.observacionesController,
    required this.reservaInventario,
    required this.onEmpresaChanged,
    required this.onClienteChanged,
    required this.onBodegaChanged,
    required this.onReservaChanged,
  });

  final List<Empresa> empresas;
  final List<Cliente> clientes;
  final List<Bodega> bodegas;
  final bool canSelectEmpresa;
  final int? empresaId;
  final int? clienteId;
  final int? bodegaId;
  final TextEditingController dirEstablecimientoController;
  final TextEditingController monedaController;
  final TextEditingController observacionesController;
  final bool reservaInventario;
  final ValueChanged<int?> onEmpresaChanged;
  final ValueChanged<int?> onClienteChanged;
  final ValueChanged<int?> onBodegaChanged;
  final ValueChanged<bool> onReservaChanged;

  @override
  Widget build(BuildContext context) {
    final availableBodegas =
        bodegas.where((bodega) => bodega.id != null).toList();
    final selectedBodegaId = availableBodegas.any(
      (bodega) => bodega.id == bodegaId,
    )
        ? bodegaId
        : null;
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final cardWidth = maxWidth > 820 ? 820.0 : maxWidth;
        return Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: cardWidth,
            child: Container(
              padding: const EdgeInsets.all(defaultPadding),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.all(Radius.circular(12)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Datos de preorden',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: defaultPadding),
                  canSelectEmpresa
                      ? DropdownButtonFormField<int>(
                          isExpanded: true,
                          value: empresaId,
                          items: empresas
                              .map(
                                (empresa) => DropdownMenuItem(
                                  value: empresa.id,
                                  child: Text(
                                    empresa.razonSocial,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: onEmpresaChanged,
                          decoration:
                              const InputDecoration(labelText: 'Empresa'),
                        )
                      : TextFormField(
                          readOnly: true,
                          initialValue: empresas
                              .firstWhere(
                                (empresa) => empresa.id == empresaId,
                                orElse: () => empresas.isNotEmpty
                                    ? empresas.first
                                    : Empresa(
                                        id: 0,
                                        ambiente: '',
                                        tipoEmision: '',
                                        razonSocial: '-',
                                        nombreComercial: '',
                                        ruc: '',
                                        dirMatriz: '',
                                        estab: '',
                                        ptoEmi: '',
                                        secuencial: '',
                                      ),
                              )
                              .razonSocial,
                          decoration:
                              const InputDecoration(labelText: 'Empresa'),
                        ),
                  const SizedBox(height: defaultPadding / 2),
                  DropdownButtonFormField<int>(
                    isExpanded: true,
                    value: clienteId,
                    items: clientes
                        .map(
                          (cliente) => DropdownMenuItem(
                            value: cliente.id,
                            child: Text(
                              cliente.razonSocial,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: onClienteChanged,
                    decoration: const InputDecoration(labelText: 'Cliente'),
                  ),
                  const SizedBox(height: defaultPadding / 2),
                  TextFormField(
                    controller: dirEstablecimientoController,
                    decoration: const InputDecoration(
                      labelText: 'Direccion establecimiento',
                    ),
                  ),
                  const SizedBox(height: defaultPadding / 2),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: monedaController,
                          decoration:
                              const InputDecoration(labelText: 'Moneda'),
                        ),
                      ),
                      const SizedBox(width: defaultPadding / 2),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          isExpanded: true,
                          value: selectedBodegaId,
                          items: availableBodegas
                              .map(
                                (bodega) => DropdownMenuItem(
                                  value: bodega.id,
                                  child: Text(
                                    bodega.nombre,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged:
                              availableBodegas.isEmpty ? null : onBodegaChanged,
                          decoration:
                              const InputDecoration(labelText: 'Bodega'),
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
                  const SizedBox(height: defaultPadding / 2),
                  SwitchListTile.adaptive(
                    value: reservaInventario,
                    onChanged: onReservaChanged,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Reservar inventario'),
                    subtitle: const Text('Bloquea stock para esta preorden.'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PreordenItemsCard extends StatelessWidget {
  const _PreordenItemsCard({
    required this.items,
    required this.productos,
    required this.bodegas,
    required this.onAddItem,
    required this.onRemoveItem,
    required this.onChanged,
  });

  final List<_PreordenItemDraft> items;
  final List<Producto> productos;
  final List<Bodega> bodegas;
  final VoidCallback onAddItem;
  final void Function(int index) onRemoveItem;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final cardWidth = maxWidth;
        return Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: cardWidth,
            child: Container(
              padding: const EdgeInsets.all(defaultPadding),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.all(Radius.circular(12)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Items',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: onAddItem,
                        icon: const Icon(Icons.add),
                        label: const Text('Agregar'),
                      ),
                    ],
                  ),
                  const SizedBox(height: defaultPadding / 2),
                  _ItemsTable(
                    items: items,
                    productos: productos,
                    bodegas: bodegas,
                    onRemoveItem: onRemoveItem,
                    onChanged: onChanged,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ItemsTable extends StatefulWidget {
  const _ItemsTable({
    required this.items,
    required this.productos,
    required this.bodegas,
    required this.onRemoveItem,
    this.onChanged,
  });

  final List<_PreordenItemDraft> items;
  final List<Producto> productos;
  final List<Bodega> bodegas;
  final void Function(int index) onRemoveItem;
  final VoidCallback? onChanged;

  @override
  State<_ItemsTable> createState() => _ItemsTableState();
}

class _ItemsTableState extends State<_ItemsTable> {
  List<Producto> _withSelectedProducto(
    List<Producto> productos,
    int? selectedId,
  ) {
    if (selectedId == null) {
      return productos;
    }
    final hasSelected = productos.any((producto) => producto.id == selectedId);
    if (hasSelected) {
      return productos;
    }
    final selected = widget.productos.cast<Producto?>().firstWhere(
        (producto) => producto?.id == selectedId,
        orElse: () => null);
    if (selected == null) {
      return productos;
    }
    return [selected, ...productos];
  }

  @override
  Widget build(BuildContext context) {
    final availableBodegas =
        widget.bodegas.where((bodega) => bodega.id != null).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(widget.items.length, (index) {
        final item = widget.items[index];
        final dropdownProductos =
            _withSelectedProducto(widget.productos, item.productoId);
        final producto = widget.productos.firstWhere(
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
        final dropdownBodegaId = availableBodegas.any(
          (bodega) => bodega.id == item.bodegaId,
        )
            ? item.bodegaId
            : null;
        final totalLinea =
            (producto.precioUnitario * item.cantidad) - item.descuento;
        return Padding(
          padding: const EdgeInsets.only(bottom: defaultPadding / 2),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                SizedBox(
                  width: 320,
                  child: DropdownButtonFormField<int>(
                    isExpanded: true,
                    value: item.productoId,
                    items: dropdownProductos
                        .map(
                          (producto) => DropdownMenuItem(
                            value: producto.id,
                            child: SizedBox(
                              width: 260,
                              child: Text(
                                '${producto.codigo} - ${producto.descripcion}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
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
                    decoration: _itemDecoration(context, 'Producto'),
                  ),
                ),
                const SizedBox(width: defaultPadding / 2),
                SizedBox(
                  width: 200,
                  child: DropdownButtonFormField<int>(
                    isExpanded: true,
                    value: dropdownBodegaId,
                    items: availableBodegas
                        .map(
                          (bodega) => DropdownMenuItem(
                            value: bodega.id,
                            child: Text(
                              bodega.nombre,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        item.bodegaId = value;
                      });
                      widget.onChanged?.call();
                    },
                    decoration: _itemDecoration(context, 'Bodega'),
                  ),
                ),
                const SizedBox(width: defaultPadding / 2),
                SizedBox(
                  width: 110,
                  child: TextFormField(
                    initialValue: item.cantidad.toString(),
                    decoration: _itemDecoration(context, 'Cantidad'),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (value) {
                      setState(() {
                        item.cantidad = double.tryParse(value) ?? 0;
                      });
                      widget.onChanged?.call();
                    },
                  ),
                ),
                const SizedBox(width: defaultPadding / 2),
                SizedBox(
                  width: 130,
                  child: TextFormField(
                    initialValue: item.descuento.toStringAsFixed(2),
                    decoration: _itemDecoration(context, 'Descuento'),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (value) {
                      setState(() {
                        item.descuento = double.tryParse(value) ?? 0;
                      });
                      widget.onChanged?.call();
                    },
                  ),
                ),
                const SizedBox(width: defaultPadding / 2),
                SizedBox(
                  width: 130,
                  child: InputDecorator(
                    decoration: _itemDecoration(context, 'Costo'),
                    child: Text(
                      producto.precioUnitario.toStringAsFixed(2),
                    ),
                  ),
                ),
                const SizedBox(width: defaultPadding / 2),
                SizedBox(
                  width: 140,
                  child: InputDecorator(
                    decoration: _itemDecoration(context, 'Total'),
                    child: Text(
                      totalLinea.toStringAsFixed(2),
                    ),
                  ),
                ),
                const SizedBox(width: defaultPadding / 2),
                IconButton(
                  onPressed: () {
                    widget.onRemoveItem(index);
                    widget.onChanged?.call();
                  },
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  InputDecoration _itemDecoration(BuildContext context, String label) {
    final theme = Theme.of(context);
    return InputDecoration(
      labelText: label,
      isDense: true,
      floatingLabelBehavior: FloatingLabelBehavior.always,
      labelStyle: theme.textTheme.labelSmall?.copyWith(
        color: theme.colorScheme.onSurface.withAlpha(180),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 12,
      ),
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
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.all(Radius.circular(12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Detalle de preorden',
            style: Theme.of(context).textTheme.titleSmall,
          ),
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
    this.bodegaId,
    this.productoId,
  });

  int? productoId;
  int? bodegaId;
  double cantidad;
  double descuento;
}
