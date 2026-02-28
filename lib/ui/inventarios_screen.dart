import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../domain/models/inventario.dart';
import '../domain/models/producto.dart';
import '../domain/models/bodega.dart';
import '../resource/theme/dimens.dart';
import '../services/api_client.dart';
import '../services/inventarios_service.dart';
import '../services/productos_service.dart';
import '../services/bodegas_service.dart';
import '../states/auth_provider.dart';
import '../states/bodegas_provider.dart';
import '../states/inventarios_provider.dart';
import '../states/productos_provider.dart';
import '../ui/shared/feedback.dart';
import '../ui/shared/section_header.dart';
import '../utils/responsive.dart';

class InventariosScreen extends StatefulWidget {
  const InventariosScreen({super.key});

  @override
  State<InventariosScreen> createState() => _InventariosScreenState();
}

class _InventariosScreenState extends State<InventariosScreen> {
  late final ApiClient _client;
  late final InventariosProvider _inventariosProvider;
  late final ProductosProvider _productosProvider;
  late final BodegasProvider _bodegasProvider;

  @override
  void initState() {
    super.initState();
    _client = ApiClient();
    _inventariosProvider = InventariosProvider(InventariosService(_client));
    _productosProvider = ProductosProvider(ProductosService(_client));
    _bodegasProvider = BodegasProvider(BodegasService(_client));
    _inventariosProvider.fetchInventarios();
    _productosProvider.fetchProductos();
    _bodegasProvider.fetchBodegas();
  }

  @override
  void dispose() {
    _inventariosProvider.dispose();
    _productosProvider.dispose();
    _bodegasProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _inventariosProvider),
        ChangeNotifierProvider.value(value: _productosProvider),
        ChangeNotifierProvider.value(value: _bodegasProvider),
      ],
      child: Consumer3<InventariosProvider, ProductosProvider, BodegasProvider>(
        builder: (context, inventariosProvider, productosProvider,
            bodegasProvider, _) {
          final authProvider = context.watch<AuthProvider>();
          final empresaId = authProvider.empresaId;
          final inventarios = empresaId == null
              ? inventariosProvider.inventarios
              : inventariosProvider.inventarios
                  .where(
                    (inventario) =>
                        inventario.empresaId == null ||
                        inventario.empresaId == empresaId,
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
          final isMobile = Responsive.isMobile(context);
          final errorMessage = inventariosProvider.errorMessage ??
              productosProvider.errorMessage ??
              bodegasProvider.errorMessage;
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(defaultPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeader(
                    title: 'Inventarios',
                    subtitle: 'Control de stock y alertas.',
                    actions: [
                      IconButton(
                        tooltip: 'Refrescar',
                        onPressed: inventariosProvider.fetchInventarios,
                        icon: const Icon(Icons.refresh),
                      ),
                      if (isMobile)
                        IconButton(
                          tooltip: 'Actualizar stock',
                          onPressed: () => _openInventarioDialog(
                            context,
                            productos: productos,
                            bodegas: bodegas,
                          ),
                          icon: const Icon(Icons.add),
                        )
                      else
                        FilledButton.icon(
                          onPressed: () => _openInventarioDialog(
                            context,
                            productos: productos,
                            bodegas: bodegas,
                          ),
                          icon: const Icon(Icons.add),
                          label: const Text('Actualizar stock'),
                        ),
                    ],
                  ),
                  if (inventariosProvider.isLoading ||
                      productosProvider.isLoading ||
                      bodegasProvider.isLoading)
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
                  _InventariosList(
                    inventarios: inventarios,
                    productos: productos,
                    onEdit: (inventario) => _openInventarioDialog(
                      context,
                      inventario: inventario,
                      productos: productos,
                      bodegas: bodegas,
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

  Future<void> _openInventarioDialog(
    BuildContext providerContext, {
    Inventario? inventario,
    required List<Producto> productos,
    required List<Bodega> bodegas,
  }) async {
    final isEditing = inventario != null;
    final formKey = GlobalKey<FormState>();
    final stockActualController = TextEditingController(
      text: inventario?.stockActual.toString() ?? '',
    );
    final stockMinimoController = TextEditingController(
      text: inventario?.stockMinimo.toString() ?? '',
    );
    final stockMaximoController = TextEditingController(
      text: inventario?.stockMaximo.toString() ?? '',
    );
    final ubicacionController =
        TextEditingController(text: inventario?.ubicacion ?? '');
    final costoPromedioController = TextEditingController(
      text: inventario?.costoPromedio.toStringAsFixed(2) ?? '',
    );
    int? productoId = inventario?.productoId;
    int? bodegaId = inventario?.bodegaId;
    var isFetching = false;

    Future<void> fetchDetalle(StateSetter setState) async {
      if (productoId == null || bodegaId == null) {
        return;
      }
      setState(() => isFetching = true);
      final detalle = await _inventariosProvider.fetchInventarioDetalle(
        productoId: productoId!,
        bodegaId: bodegaId!,
      );
      if (detalle != null) {
        stockActualController.text = detalle.stockActual.toString();
        stockMinimoController.text = detalle.stockMinimo.toString();
        stockMaximoController.text = detalle.stockMaximo.toString();
        ubicacionController.text = detalle.ubicacion;
        costoPromedioController.text = detalle.costoPromedio.toStringAsFixed(2);
      } else {
        showAppToast(
          providerContext,
          _inventariosProvider.errorMessage ?? 'Inventario no encontrado.',
          isError: true,
        );
      }
      if (providerContext.mounted) {
        setState(() => isFetching = false);
      }
    }

    await showDialog<void>(
      context: providerContext,
      builder: (context) {
        return AlertDialog(
          title: Text(isEditing ? 'Editar inventario' : 'Actualizar stock'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return SizedBox(
                width: 520,
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isCompact = constraints.maxWidth < 520;
                          final children = <Widget>[
                            Expanded(
                              child: DropdownButtonFormField<int>(
                                value: productoId,
                                isExpanded: true,
                                items: productos
                                    .map(
                                      (producto) => DropdownMenuItem(
                                        value: producto.id,
                                        child: Text(
                                          '${producto.codigo} - ${producto.descripcion}',
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) async {
                                  setState(() => productoId = value);
                                  await fetchDetalle(setState);
                                },
                                decoration: const InputDecoration(
                                    labelText: 'Producto'),
                                validator: (value) {
                                  if (value == null) {
                                    return 'Seleccione producto';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            SizedBox(
                              width: isCompact ? 0 : defaultPadding / 2,
                              height: isCompact ? defaultPadding / 2 : 0,
                            ),
                            Expanded(
                              child: DropdownButtonFormField<int>(
                                value: bodegaId,
                                isExpanded: true,
                                items: bodegas
                                    .where((bodega) => bodega.id != null)
                                    .map(
                                      (bodega) => DropdownMenuItem(
                                        value: bodega.id!,
                                        child: Text(
                                          bodega.nombre,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) async {
                                  setState(() => bodegaId = value);
                                  await fetchDetalle(setState);
                                },
                                decoration:
                                    const InputDecoration(labelText: 'Bodega'),
                                validator: (value) {
                                  if (value == null) {
                                    return 'Seleccione bodega';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ];

                          if (isCompact) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                children[0],
                                const SizedBox(height: defaultPadding / 2),
                                children[2],
                              ],
                            );
                          }

                          return Row(children: children);
                        },
                      ),
                      if (isFetching)
                        const Padding(
                          padding: EdgeInsets.only(top: defaultPadding / 2),
                          child: LinearProgressIndicator(),
                        ),
                      const SizedBox(height: defaultPadding / 2),
                      TextFormField(
                        controller: stockActualController,
                        decoration:
                            const InputDecoration(labelText: 'Stock actual'),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Campo requerido';
                          }
                          if (int.tryParse(value.trim()) == null) {
                            return 'Debe ser numerico';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: defaultPadding / 2),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: stockMinimoController,
                              decoration: const InputDecoration(
                                labelText: 'Stock minimo',
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Requerido';
                                }
                                if (int.tryParse(value.trim()) == null) {
                                  return 'Numerico';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: defaultPadding / 2),
                          Expanded(
                            child: TextFormField(
                              controller: stockMaximoController,
                              decoration: const InputDecoration(
                                labelText: 'Stock maximo',
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Requerido';
                                }
                                if (int.tryParse(value.trim()) == null) {
                                  return 'Numerico';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: defaultPadding / 2),
                      TextFormField(
                        controller: ubicacionController,
                        decoration:
                            const InputDecoration(labelText: 'Ubicacion'),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Campo requerido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: defaultPadding / 2),
                      TextFormField(
                        controller: costoPromedioController,
                        decoration:
                            const InputDecoration(labelText: 'Costo promedio'),
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
                final provider = providerContext.read<InventariosProvider>();
                final payload = Inventario(
                  id: inventario?.id,
                  productoId: productoId!,
                  bodegaId: bodegaId,
                  stockActual:
                      int.tryParse(stockActualController.text.trim()) ?? 0,
                  stockMinimo:
                      int.tryParse(stockMinimoController.text.trim()) ?? 0,
                  stockMaximo:
                      int.tryParse(stockMaximoController.text.trim()) ?? 0,
                  ubicacion: ubicacionController.text.trim(),
                  costoPromedio:
                      double.tryParse(costoPromedioController.text.trim()) ?? 0,
                );
                final ok = isEditing
                    ? await provider.updateInventarioDetalle(payload)
                    : await provider.upsertInventario(payload);
                if (!ok) {
                  showAppToast(
                    providerContext,
                    provider.errorMessage ??
                        'No se pudo actualizar el inventario.',
                    isError: true,
                  );
                  return;
                }
                if (context.mounted) {
                  Navigator.of(context).pop();
                  showAppToast(
                    providerContext,
                    isEditing
                        ? 'Inventario actualizado.'
                        : 'Inventario registrado.',
                  );
                }
              },
              child: Text(isEditing ? 'Guardar' : 'Crear'),
            ),
          ],
        );
      },
    );

    stockActualController.dispose();
    stockMinimoController.dispose();
    stockMaximoController.dispose();
    ubicacionController.dispose();
    costoPromedioController.dispose();
  }
}

class _InventariosList extends StatelessWidget {
  const _InventariosList({
    required this.inventarios,
    required this.productos,
    required this.onEdit,
  });

  final List<Inventario> inventarios;
  final List<Producto> productos;
  final void Function(Inventario inventario) onEdit;

  String _productoNombre(Inventario inventario) {
    final direct = inventario.productoNombre?.trim();
    if (direct != null && direct.isNotEmpty) {
      return direct;
    }
    final descripcion = inventario.productoDescripcion?.trim();
    if (descripcion != null && descripcion.isNotEmpty) {
      return descripcion;
    }
    return productos
        .firstWhere(
          (producto) => producto.id == inventario.productoId,
          orElse: () => Producto(
            id: 0,
            codigo: '- ',
            descripcion: 'Sin producto',
            precioUnitario: 0,
            categoriaId: 0,
            impuestoId: 0,
          ),
        )
        .descripcion;
  }

  @override
  Widget build(BuildContext context) {
    if (inventarios.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(defaultPadding),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.all(Radius.circular(10)),
        ),
        child: const Text('Sin inventario disponible.'),
      );
    }

    if (Responsive.isMobile(context)) {
      return Column(
        children: inventarios
            .map(
              (inventario) => Card(
                child: ListTile(
                  title: Text(_productoNombre(inventario)),
                  subtitle: Text(
                    [
                      if (inventario.bodegaNombre != null &&
                          inventario.bodegaNombre!.isNotEmpty)
                        'Bodega: ${inventario.bodegaNombre}',
                      'Stock: ${inventario.stockActual} (min ${inventario.stockMinimo})',
                      if (inventario.precioVenta != null)
                        'PVP: ${inventario.precioVenta!.toStringAsFixed(2)}',
                      if ((inventario.margenPorcentaje ??
                              inventario.margenPorcentajeGlobal) !=
                          null)
                        'Margen: ${(inventario.margenPorcentaje ?? inventario.margenPorcentajeGlobal)!.toStringAsFixed(2)}%',
                    ].join(' · '),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (inventario.isLowStock)
                        const Icon(Icons.warning, color: Colors.redAccent)
                      else
                        const Icon(Icons.check_circle, color: Colors.green),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        tooltip: 'Editar',
                        onPressed: () => onEdit(inventario),
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
                    DataColumn(label: Text('Producto')),
                    DataColumn(label: Text('Bodega')),
                    DataColumn(label: Text('Stock')),
                    DataColumn(label: Text('Min')),
                    DataColumn(label: Text('Max')),
                    DataColumn(label: Text('Ubicacion')),
                    DataColumn(label: Text('Costo promedio')),
                    DataColumn(label: Text('PVP')),
                    DataColumn(label: Text('Margen %')),
                    DataColumn(label: Text('Acciones')),
                  ],
                  rows: inventarios
                      .map(
                        (inventario) => DataRow(
                          color: MaterialStateProperty.resolveWith<Color?>(
                            (states) => inventario.isLowStock
                                ? Colors.redAccent.withAlpha(26)
                                : null,
                          ),
                          cells: [
                            DataCell(
                              Text(_productoNombre(inventario)),
                            ),
                            DataCell(Text(inventario.bodegaNombre ?? '-')),
                            DataCell(Text(inventario.stockActual.toString())),
                            DataCell(Text(inventario.stockMinimo.toString())),
                            DataCell(Text(inventario.stockMaximo.toString())),
                            DataCell(Text(inventario.ubicacion)),
                            DataCell(
                              Text(inventario.costoPromedio.toStringAsFixed(2)),
                            ),
                            DataCell(
                              Text(
                                (inventario.precioVenta ?? 0)
                                    .toStringAsFixed(2),
                              ),
                            ),
                            DataCell(
                              Text(
                                (inventario.margenPorcentaje ??
                                        inventario.margenPorcentajeGlobal ??
                                        0)
                                    .toStringAsFixed(2),
                              ),
                            ),
                            DataCell(
                              IconButton(
                                tooltip: 'Editar',
                                onPressed: () => onEdit(inventario),
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
