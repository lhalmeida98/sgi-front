import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../domain/models/categoria.dart';
import '../domain/models/impuesto.dart';
import '../domain/models/producto.dart';
import '../resource/theme/dimens.dart';
import '../services/api_client.dart';
import '../services/categorias_service.dart';
import '../services/impuestos_service.dart';
import '../services/productos_service.dart';
import '../states/auth_provider.dart';
import '../states/categorias_provider.dart';
import '../states/impuestos_provider.dart';
import '../states/productos_provider.dart';
import '../ui/shared/feedback.dart';
import '../ui/shared/section_header.dart';
import '../utils/responsive.dart';

class ProductosScreen extends StatefulWidget {
  const ProductosScreen({super.key});

  @override
  State<ProductosScreen> createState() => _ProductosScreenState();
}

class _ProductosScreenState extends State<ProductosScreen> {
  String _query = '';

  late final ApiClient _client;
  late final ProductosProvider _productosProvider;
  late final CategoriasProvider _categoriasProvider;
  late final ImpuestosProvider _impuestosProvider;

  @override
  void initState() {
    super.initState();
    _client = ApiClient();
    _productosProvider = ProductosProvider(ProductosService(_client));
    _categoriasProvider = CategoriasProvider(CategoriasService(_client));
    _impuestosProvider = ImpuestosProvider(ImpuestosService(_client));
    _productosProvider.fetchProductos();
    _categoriasProvider.fetchCategorias();
    _impuestosProvider.fetchImpuestos();
  }

  @override
  void dispose() {
    _productosProvider.dispose();
    _categoriasProvider.dispose();
    _impuestosProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _productosProvider),
        ChangeNotifierProvider.value(value: _categoriasProvider),
        ChangeNotifierProvider.value(value: _impuestosProvider),
      ],
      child: Consumer3<ProductosProvider, CategoriasProvider, ImpuestosProvider>(
        builder: (context, productosProvider, categoriasProvider,
            impuestosProvider, _) {
          final authProvider = context.watch<AuthProvider>();
          final empresaId = authProvider.empresaId;
          final categorias = empresaId == null
              ? categoriasProvider.categorias
              : categoriasProvider.categorias
                  .where(
                    (categoria) =>
                        categoria.empresaId == null ||
                        categoria.empresaId == empresaId,
                  )
                  .toList();
          final categoriaIds = categorias
              .where((categoria) => categoria.id != null)
              .map((categoria) => categoria.id)
              .toSet();
          final impuestos = empresaId == null
              ? impuestosProvider.impuestos
              : impuestosProvider.impuestos
                  .where(
                    (impuesto) =>
                        impuesto.empresaId == null ||
                        impuesto.empresaId == empresaId,
                  )
                  .toList();
          var productosBase = productosProvider.productos;
          if (empresaId != null) {
            productosBase = productosBase.where((producto) {
              if (producto.empresaId != null) {
                return producto.empresaId == empresaId;
              }
              if (categoriaIds.isEmpty) {
                return true;
              }
              return categoriaIds.contains(producto.categoriaId);
            }).toList();
          }
          final productos = _filterProductos(productosBase);
          final isMobile = Responsive.isMobile(context);
          final errorMessage = productosProvider.errorMessage ??
              categoriasProvider.errorMessage ??
              impuestosProvider.errorMessage;
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(defaultPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeader(
                    title: 'Productos',
                    subtitle: 'Catalogo de productos y precios.',
                    searchHint: 'Buscar por codigo o descripcion',
                    onSearchChanged: (value) {
                      setState(() => _query = value.trim());
                    },
                    actions: [
                      IconButton(
                        tooltip: 'Refrescar',
                        onPressed: productosProvider.fetchProductos,
                        icon: const Icon(Icons.refresh),
                      ),
                      if (isMobile)
                        IconButton(
                          tooltip: 'Crear producto',
                          onPressed: () => _openProductoDialog(
                            context,
                            categorias: categorias,
                            impuestos: impuestos,
                          ),
                          icon: const Icon(Icons.add),
                        )
                      else
                        FilledButton.icon(
                          onPressed: () => _openProductoDialog(
                            context,
                            categorias: categorias,
                            impuestos: impuestos,
                          ),
                          icon: const Icon(Icons.add),
                          label: const Text('Crear producto'),
                        ),
                    ],
                  ),
                  if (productosProvider.isLoading ||
                      categoriasProvider.isLoading ||
                      impuestosProvider.isLoading)
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
                  _ProductosList(
                    productos: productos,
                    categorias: categorias,
                    impuestos: impuestos,
                    onEdit: (producto) => _openProductoDialog(
                      context,
                      producto: producto,
                      categorias: categorias,
                      impuestos: impuestos,
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

  List<Producto> _filterProductos(List<Producto> productos) {
    if (_query.isEmpty) {
      return productos;
    }
    final lower = _query.toLowerCase();
    return productos
        .where(
          (producto) =>
              producto.codigo.toLowerCase().contains(lower) ||
              producto.descripcion.toLowerCase().contains(lower) ||
              (producto.codigoBarras ?? '').toLowerCase().contains(lower),
        )
        .toList();
  }

  Future<void> _openProductoDialog(
    BuildContext providerContext, {
    Producto? producto,
    required List<Categoria> categorias,
    required List<Impuesto> impuestos,
  }) async {
    final isEditing = producto != null;
    final formKey = GlobalKey<FormState>();
    final codigoController =
        TextEditingController(text: producto?.codigo ?? '');
    final codigoBarrasController =
        TextEditingController(text: producto?.codigoBarras ?? '');
    final descripcionController =
        TextEditingController(text: producto?.descripcion ?? '');
    final precioController = TextEditingController(
      text: producto != null ? producto.precioUnitario.toStringAsFixed(2) : '',
    );
    int? categoriaId = producto?.categoriaId;
    int? impuestoId = producto?.impuestoId;

    await showDialog<void>(
      context: providerContext,
      builder: (context) {
        return AlertDialog(
          title: Text(isEditing ? 'Editar producto' : 'Crear producto'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return SizedBox(
                width: 480,
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
                        controller: codigoBarrasController,
                        decoration:
                            const InputDecoration(labelText: 'Codigo de barras'),
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
                        controller: precioController,
                        keyboardType: TextInputType.number,
                        decoration:
                            const InputDecoration(labelText: 'Precio unitario'),
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
                      DropdownButtonFormField<int>(
                        value: categoriaId,
                        items: categorias
                            .map(
                              (categoria) => DropdownMenuItem(
                                value: categoria.id,
                                child: Text(categoria.nombre),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() => categoriaId = value);
                        },
                        decoration:
                            const InputDecoration(labelText: 'Categoria'),
                        validator: (value) {
                          if (value == null) {
                            return 'Seleccione categoria';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: defaultPadding / 2),
                      DropdownButtonFormField<int>(
                        value: impuestoId,
                        items: impuestos
                            .map(
                              (impuesto) => DropdownMenuItem(
                                value: impuesto.id,
                                child: Text(
                                  '${impuesto.descripcion} (${impuesto.tarifa.toStringAsFixed(2)}%)',
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() => impuestoId = value);
                        },
                        decoration:
                            const InputDecoration(labelText: 'Impuesto'),
                        validator: (value) {
                          if (value == null) {
                            return 'Seleccione impuesto';
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
                final provider =
                    providerContext.read<ProductosProvider>();
                final payload = Producto(
                  id: producto?.id,
                  codigo: codigoController.text.trim(),
                  codigoBarras: codigoBarrasController.text.trim(),
                  descripcion: descripcionController.text.trim(),
                  precioUnitario:
                      double.tryParse(precioController.text.trim()) ?? 0,
                  categoriaId: categoriaId!,
                  impuestoId: impuestoId!,
                );
                final ok = isEditing
                    ? await provider.updateProducto(payload)
                    : await provider.createProducto(payload);
                if (!ok) {
                  showAppToast(
                    providerContext,
                    provider.errorMessage ??
                        'No se pudo guardar el producto.',
                    isError: true,
                  );
                  return;
                }
                if (context.mounted) {
                  Navigator.of(context).pop();
                  showAppToast(
                    providerContext,
                    isEditing
                        ? 'Producto actualizado.'
                        : 'Producto creado.',
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
    codigoBarrasController.dispose();
    descripcionController.dispose();
    precioController.dispose();
  }
}

class _ProductosList extends StatelessWidget {
  const _ProductosList({
    required this.productos,
    required this.categorias,
    required this.impuestos,
    required this.onEdit,
  });

  final List<Producto> productos;
  final List<Categoria> categorias;
  final List<Impuesto> impuestos;
  final void Function(Producto producto) onEdit;

  String _categoriaNombre(int categoriaId) {
    return categorias
        .firstWhere(
          (categoria) => categoria.id == categoriaId,
          orElse: () => Categoria(id: 0, nombre: '-', descripcion: ''),
        )
        .nombre;
  }

  String _impuestoNombre(int impuestoId) {
    final impuesto = impuestos.firstWhere(
      (item) => item.id == impuestoId,
      orElse: () => Impuesto(
        id: 0,
        codigo: '-',
        codigoPorcentaje: '-',
        tarifa: 0,
        descripcion: '-',
        activo: true,
      ),
    );
    return '${impuesto.descripcion} (${impuesto.tarifa.toStringAsFixed(2)}%)';
  }

  @override
  Widget build(BuildContext context) {
    if (productos.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(defaultPadding),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.all(Radius.circular(10)),
        ),
        child: const Text('Sin productos registrados.'),
      );
    }

    if (Responsive.isMobile(context)) {
      return Column(
        children: productos
            .map(
              (producto) => Card(
                child: ListTile(
                  title: Text('${producto.codigo} - ${producto.descripcion}'),
                  subtitle: Text(
                    'Precio: ${producto.precioUnitario.toStringAsFixed(2)} | ${_categoriaNombre(producto.categoriaId)}${producto.codigoBarras == null || producto.codigoBarras!.isEmpty ? '' : ' | Barra: ${producto.codigoBarras}'}',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    tooltip: 'Editar',
                    onPressed: () => onEdit(producto),
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
                    DataColumn(label: Text('Codigo barras')),
                    DataColumn(label: Text('Descripcion')),
                    DataColumn(label: Text('Precio')),
                    DataColumn(label: Text('Categoria')),
                    DataColumn(label: Text('Impuesto')),
                    DataColumn(label: Text('Acciones')),
                  ],
                  rows: productos
                      .map(
                        (producto) => DataRow(
                          cells: [
                            DataCell(Text(producto.codigo)),
                            DataCell(Text(producto.codigoBarras ?? '-')),
                            DataCell(Text(producto.descripcion)),
                            DataCell(
                              Text(producto.precioUnitario.toStringAsFixed(2)),
                            ),
                            DataCell(
                              Text(_categoriaNombre(producto.categoriaId)),
                            ),
                            DataCell(
                              Text(_impuestoNombre(producto.impuestoId)),
                            ),
                            DataCell(
                              IconButton(
                                tooltip: 'Editar',
                                onPressed: () => onEdit(producto),
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
