import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../domain/models/categoria.dart';
import '../domain/models/cuenta_por_pagar.dart';
import '../domain/models/documento_proveedor.dart';
import '../domain/models/impuesto.dart';
import '../domain/models/pago_proveedor.dart';
import '../domain/models/producto.dart';
import '../domain/models/proveedor.dart';
import '../domain/models/bodega.dart';
import '../resource/theme/dimens.dart';
import '../services/api_client.dart';
import '../services/bodegas_service.dart';
import '../services/categorias_service.dart';
import '../services/cuentas_por_pagar_service.dart';
import '../services/documentos_proveedor_service.dart';
import '../services/impuestos_service.dart';
import '../services/pagos_proveedor_service.dart';
import '../services/productos_service.dart';
import '../services/proveedores_service.dart';
import '../states/auth_provider.dart';
import '../states/bodegas_provider.dart';
import '../states/categorias_provider.dart';
import '../states/cxp_provider.dart';
import '../states/documentos_proveedor_provider.dart';
import '../states/impuestos_provider.dart';
import '../states/pagos_proveedor_provider.dart';
import '../states/productos_provider.dart';
import '../states/proveedores_provider.dart';
import '../ui/facturacion/factura_notifications.dart';
import '../ui/shared/feedback.dart';
import '../ui/shared/section_header.dart';
import '../utils/responsive.dart';

class ProveedoresScreen extends StatefulWidget {
  const ProveedoresScreen({super.key});

  @override
  State<ProveedoresScreen> createState() => _ProveedoresScreenState();
}

class _ProveedoresScreenState extends State<ProveedoresScreen> {
  int _tabIndex = 0;
  String _proveedorQuery = '';
  String _documentoQuery = '';
  int? _selectedProveedorId;

  late final ApiClient _client;
  late final ProveedoresProvider _proveedoresProvider;
  late final DocumentosProveedorProvider _documentosProvider;
  late final CxpProvider _cxpProvider;
  late final PagosProveedorProvider _pagosProvider;
  late final ProductosProvider _productosProvider;
  late final BodegasProvider _bodegasProvider;
  late final CategoriasProvider _categoriasProvider;
  late final ImpuestosProvider _impuestosProvider;

  @override
  void initState() {
    super.initState();
    _client = ApiClient();
    _proveedoresProvider = ProveedoresProvider(ProveedoresService(_client));
    _documentosProvider =
        DocumentosProveedorProvider(DocumentosProveedorService(_client));
    _cxpProvider = CxpProvider(CuentasPorPagarService(_client));
    _pagosProvider = PagosProveedorProvider(PagosProveedorService(_client));
    _productosProvider = ProductosProvider(ProductosService(_client));
    _bodegasProvider = BodegasProvider(BodegasService(_client));
    _categoriasProvider = CategoriasProvider(CategoriasService(_client));
    _impuestosProvider = ImpuestosProvider(ImpuestosService(_client));

    _proveedoresProvider.fetchProveedores();
    _documentosProvider.fetchDocumentos();
    _cxpProvider.fetchCuentas();
    _pagosProvider.fetchPagos();
    _productosProvider.fetchProductos();
    _bodegasProvider.fetchBodegas();
    _categoriasProvider.fetchCategorias();
    _impuestosProvider.fetchImpuestos();
  }

  @override
  void dispose() {
    _proveedoresProvider.dispose();
    _documentosProvider.dispose();
    _cxpProvider.dispose();
    _pagosProvider.dispose();
    _productosProvider.dispose();
    _bodegasProvider.dispose();
    _categoriasProvider.dispose();
    _impuestosProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _proveedoresProvider),
        ChangeNotifierProvider.value(value: _documentosProvider),
        ChangeNotifierProvider.value(value: _cxpProvider),
        ChangeNotifierProvider.value(value: _pagosProvider),
        ChangeNotifierProvider.value(value: _productosProvider),
        ChangeNotifierProvider.value(value: _bodegasProvider),
        ChangeNotifierProvider.value(value: _categoriasProvider),
        ChangeNotifierProvider.value(value: _impuestosProvider),
      ],
      child: Consumer6<ProveedoresProvider, DocumentosProveedorProvider,
          CxpProvider, PagosProveedorProvider, ProductosProvider, BodegasProvider>(
        builder: (context, proveedoresProvider, documentosProvider, cxpProvider,
            pagosProvider, productosProvider, bodegasProvider, _) {
          final categoriasProvider = context.watch<CategoriasProvider>();
          final impuestosProvider = context.watch<ImpuestosProvider>();
          final authProvider = context.watch<AuthProvider>();
          final empresaId = authProvider.empresaId;
          var proveedores = proveedoresProvider.proveedores;
          if (empresaId != null) {
            proveedores = proveedores
                .where(
                  (proveedor) =>
                      proveedor.empresaId == null ||
                      proveedor.empresaId == empresaId,
                )
                .toList();
          }
          proveedores = _filterProveedores(proveedores);
          var documentos = documentosProvider.documentos;
          if (_selectedProveedorId != null) {
            documentos = documentos
                .where((doc) => doc.proveedorId == _selectedProveedorId)
                .toList();
          }
          documentos = _filterDocumentos(documentos);
          var cuentas = cxpProvider.cuentas;
          if (_selectedProveedorId != null) {
            cuentas = cuentas
                .where((cxp) => cxp.proveedorId == _selectedProveedorId)
                .toList();
          }
          var pagos = pagosProvider.pagos;
          if (_selectedProveedorId != null) {
            pagos = pagos
                .where((pago) => pago.proveedorId == _selectedProveedorId)
                .toList();
          }
          var bodegas = bodegasProvider.bodegas;
          if (empresaId != null) {
            bodegas = bodegas
                .where(
                  (bodega) =>
                      bodega.empresaId == null || bodega.empresaId == empresaId,
                )
                .toList();
          }
          bodegas = bodegas.where((bodega) => bodega.activa).toList();
          final productos = empresaId == null
              ? productosProvider.productos
              : productosProvider.productos
                  .where(
                    (producto) =>
                        producto.empresaId == null ||
                        producto.empresaId == empresaId,
                  )
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
          final impuestos = empresaId == null
              ? impuestosProvider.impuestos
              : impuestosProvider.impuestos
                  .where(
                    (impuesto) =>
                        impuesto.empresaId == null ||
                        impuesto.empresaId == empresaId,
                  )
                  .toList();
          final isMobile = Responsive.isMobile(context);
          final isLoading = _resolveLoading(
            proveedoresProvider: proveedoresProvider,
            documentosProvider: documentosProvider,
            cxpProvider: cxpProvider,
            pagosProvider: pagosProvider,
            productosProvider: productosProvider,
            bodegasProvider: bodegasProvider,
            categoriasProvider: categoriasProvider,
            impuestosProvider: impuestosProvider,
          );
          final errorMessage = _resolveErrorMessage(
            proveedoresProvider: proveedoresProvider,
            documentosProvider: documentosProvider,
            cxpProvider: cxpProvider,
            pagosProvider: pagosProvider,
            productosProvider: productosProvider,
            bodegasProvider: bodegasProvider,
            categoriasProvider: categoriasProvider,
            impuestosProvider: impuestosProvider,
          );
          final actions = _buildActions(
            context,
            isMobile: isMobile,
            proveedores: proveedores,
            productos: productos,
            bodegas: bodegas,
            categorias: categorias,
            impuestos: impuestos,
            cuentas: cuentas,
          );

          _syncProveedorSeleccion(proveedores);

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(defaultPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeader(
                    title: 'Proveedores',
                    subtitle: 'Proveedores, documentos, CxP y pagos.',
                    searchHint: _resolveSearchHint(),
                    onSearchChanged: _resolveSearchHandler(),
                    actions: actions,
                  ),
                  const SizedBox(height: defaultPadding),
                  _TabSelector(
                    currentIndex: _tabIndex,
                    onChanged: (index) => setState(() => _tabIndex = index),
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
                  _resolveTabBody(
                    context,
                    proveedores: proveedores,
                    documentos: documentos,
                    cuentas: cuentas,
                    pagos: pagos,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String? _resolveSearchHint() {
    if (_tabIndex == 0) {
      return 'Buscar proveedor por RUC o razon social';
    }
    if (_tabIndex == 1) {
      return 'Buscar documento por numero o autorizacion';
    }
    return null;
  }

  ValueChanged<String>? _resolveSearchHandler() {
    if (_tabIndex == 0) {
      return (value) => setState(() => _proveedorQuery = value.trim());
    }
    if (_tabIndex == 1) {
      return (value) => setState(() => _documentoQuery = value.trim());
    }
    return null;
  }

  bool _resolveLoading({
    required ProveedoresProvider proveedoresProvider,
    required DocumentosProveedorProvider documentosProvider,
    required CxpProvider cxpProvider,
    required PagosProveedorProvider pagosProvider,
    required ProductosProvider productosProvider,
    required BodegasProvider bodegasProvider,
    required CategoriasProvider categoriasProvider,
    required ImpuestosProvider impuestosProvider,
  }) {
    switch (_tabIndex) {
      case 0:
        return proveedoresProvider.isLoading;
      case 1:
        return documentosProvider.isLoading ||
            productosProvider.isLoading ||
            bodegasProvider.isLoading ||
            categoriasProvider.isLoading ||
            impuestosProvider.isLoading;
      case 2:
        return cxpProvider.isLoading;
      case 3:
        return pagosProvider.isLoading;
      default:
        return false;
    }
  }

  String? _resolveErrorMessage({
    required ProveedoresProvider proveedoresProvider,
    required DocumentosProveedorProvider documentosProvider,
    required CxpProvider cxpProvider,
    required PagosProveedorProvider pagosProvider,
    required ProductosProvider productosProvider,
    required BodegasProvider bodegasProvider,
    required CategoriasProvider categoriasProvider,
    required ImpuestosProvider impuestosProvider,
  }) {
    switch (_tabIndex) {
      case 0:
        return proveedoresProvider.errorMessage;
      case 1:
        return documentosProvider.errorMessage ??
            productosProvider.errorMessage ??
            bodegasProvider.errorMessage ??
            categoriasProvider.errorMessage ??
            impuestosProvider.errorMessage;
      case 2:
        return cxpProvider.errorMessage;
      case 3:
        return pagosProvider.errorMessage;
      default:
        return null;
    }
  }

  void _syncProveedorSeleccion(List<Proveedor> proveedores) {
    if (_selectedProveedorId == null) {
      return;
    }
    final proveedorIds = proveedores
        .map((proveedor) => proveedor.id)
        .whereType<int>()
        .toSet();
    if (!proveedorIds.contains(_selectedProveedorId)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _onProveedorFilterChanged(null);
        }
      });
    }
  }

  List<Widget> _buildActions(
    BuildContext context, {
    required bool isMobile,
    required List<Proveedor> proveedores,
    required List<Producto> productos,
    required List<Bodega> bodegas,
    required List<Categoria> categorias,
    required List<Impuesto> impuestos,
    required List<CuentaPorPagar> cuentas,
  }) {
    switch (_tabIndex) {
      case 0:
        return [
          IconButton(
            tooltip: 'Refrescar',
            onPressed: _proveedoresProvider.fetchProveedores,
            icon: const Icon(Icons.refresh),
          ),
          if (isMobile)
            IconButton(
              tooltip: 'Crear proveedor',
              onPressed: () => _openProveedorDialog(context),
              icon: const Icon(Icons.add),
            )
          else
            FilledButton.icon(
              onPressed: () => _openProveedorDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Crear proveedor'),
            ),
        ];
      case 1:
        return [
          IconButton(
            tooltip: 'Refrescar',
            onPressed: () => _documentosProvider.fetchDocumentos(
              proveedorId: _selectedProveedorId,
            ),
            icon: const Icon(Icons.refresh),
          ),
          if (isMobile)
            IconButton(
              tooltip: 'Documento manual',
              onPressed: () => _openDocumentoManualDialog(
                context,
                proveedores: proveedores,
                productos: productos,
                bodegas: bodegas,
              ),
              icon: const Icon(Icons.note_add_outlined),
            )
          else
            FilledButton.icon(
              onPressed: () => _openDocumentoManualDialog(
                context,
                proveedores: proveedores,
                productos: productos,
                bodegas: bodegas,
              ),
              icon: const Icon(Icons.note_add_outlined),
              label: const Text('Documento manual'),
            ),
          if (isMobile)
            IconButton(
              tooltip: 'Subir XML',
              onPressed: () => _openDocumentoXmlDialog(
                context,
                proveedores: proveedores,
                bodegas: bodegas,
                productos: productos,
                categorias: categorias,
                impuestos: impuestos,
              ),
              icon: const Icon(Icons.cloud_upload_outlined),
            )
          else
            FilledButton.icon(
              onPressed: () => _openDocumentoXmlDialog(
                context,
                proveedores: proveedores,
                bodegas: bodegas,
                productos: productos,
                categorias: categorias,
                impuestos: impuestos,
              ),
              icon: const Icon(Icons.cloud_upload_outlined),
              label: const Text('Subir XML'),
            ),
          if (isMobile)
            IconButton(
              tooltip: 'Por autorizacion',
              onPressed: () => _openAutorizacionDialog(
                context,
                proveedores: proveedores,
                bodegas: bodegas,
                productos: productos,
                categorias: categorias,
                impuestos: impuestos,
              ),
              icon: const Icon(Icons.verified_outlined),
            )
          else
            FilledButton.icon(
              onPressed: () => _openAutorizacionDialog(
                context,
                proveedores: proveedores,
                bodegas: bodegas,
                productos: productos,
                categorias: categorias,
                impuestos: impuestos,
              ),
              icon: const Icon(Icons.verified_outlined),
              label: const Text('Por autorizacion'),
            ),
        ];
      case 2:
        return [
          IconButton(
            tooltip: 'Refrescar',
            onPressed: () => _cxpProvider.fetchCuentas(
              proveedorId: _selectedProveedorId,
            ),
            icon: const Icon(Icons.refresh),
          ),
        ];
      case 3:
        return [
          IconButton(
            tooltip: 'Refrescar',
            onPressed: () => _pagosProvider.fetchPagos(
              proveedorId: _selectedProveedorId,
            ),
            icon: const Icon(Icons.refresh),
          ),
          if (isMobile)
            IconButton(
              tooltip: 'Registrar pago',
              onPressed: () => _openPagoDialog(
                context,
                proveedores: proveedores,
                cuentas: cuentas,
              ),
              icon: const Icon(Icons.add),
            )
          else
            FilledButton.icon(
              onPressed: () => _openPagoDialog(
                context,
                proveedores: proveedores,
                cuentas: cuentas,
              ),
              icon: const Icon(Icons.add),
              label: const Text('Registrar pago'),
            ),
        ];
      default:
        return const [];
    }
  }

  Widget _resolveTabBody(
    BuildContext context, {
    required List<Proveedor> proveedores,
    required List<DocumentoProveedor> documentos,
    required List<CuentaPorPagar> cuentas,
    required List<PagoProveedor> pagos,
  }) {
    switch (_tabIndex) {
      case 0:
        return _ProveedoresList(
          proveedores: proveedores,
          onEdit: (proveedor) =>
              _openProveedorDialog(context, proveedor: proveedor),
          onInactivate: (proveedor) => _confirmInactivate(context, proveedor),
          onDelete: (proveedor) => _confirmDelete(context, proveedor),
        );
      case 1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ProveedorFilter(
              proveedores: proveedores,
              value: _selectedProveedorId,
              onChanged: _onProveedorFilterChanged,
            ),
            const SizedBox(height: defaultPadding),
            _DocumentosList(documentos: documentos),
          ],
        );
      case 2:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ProveedorFilter(
              proveedores: proveedores,
              value: _selectedProveedorId,
              onChanged: _onProveedorFilterChanged,
            ),
            const SizedBox(height: defaultPadding),
            _CxpList(cuentas: cuentas),
          ],
        );
      case 3:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ProveedorFilter(
              proveedores: proveedores,
              value: _selectedProveedorId,
              onChanged: _onProveedorFilterChanged,
            ),
            const SizedBox(height: defaultPadding),
            _PagosList(pagos: pagos),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  List<Proveedor> _filterProveedores(List<Proveedor> proveedores) {
    if (_proveedorQuery.isEmpty) {
      return proveedores;
    }
    final lower = _proveedorQuery.toLowerCase();
    return proveedores
        .where(
          (proveedor) =>
              proveedor.razonSocial.toLowerCase().contains(lower) ||
              proveedor.identificacion.toLowerCase().contains(lower) ||
              proveedor.email.toLowerCase().contains(lower) ||
              (proveedor.nombreComercial ?? '').toLowerCase().contains(lower),
        )
        .toList();
  }

  List<DocumentoProveedor> _filterDocumentos(
    List<DocumentoProveedor> documentos,
  ) {
    if (_documentoQuery.isEmpty) {
      return documentos;
    }
    final lower = _documentoQuery.toLowerCase();
    return documentos
        .where(
          (documento) =>
              (documento.numeroDocumento ?? '').toLowerCase().contains(lower) ||
              (documento.numeroAutorizacion ?? '')
                  .toLowerCase()
                  .contains(lower),
        )
        .toList();
  }

  void _onProveedorFilterChanged(int? proveedorId) {
    setState(() => _selectedProveedorId = proveedorId);
    _documentosProvider.fetchDocumentos(proveedorId: proveedorId);
    _cxpProvider.fetchCuentas(proveedorId: proveedorId);
    _pagosProvider.fetchPagos(proveedorId: proveedorId);
  }

  Future<void> _openProveedorDialog(
    BuildContext providerContext, {
    Proveedor? proveedor,
  }) async {
    final isEditing = proveedor != null;
    final formKey = GlobalKey<FormState>();
    final identificacionController =
        TextEditingController(text: proveedor?.identificacion ?? '');
    final razonSocialController =
        TextEditingController(text: proveedor?.razonSocial ?? '');
    final nombreComercialController =
        TextEditingController(text: proveedor?.nombreComercial ?? '');
    final emailController = TextEditingController(text: proveedor?.email ?? '');
    final telefonoController =
        TextEditingController(text: proveedor?.telefono ?? '');
    final direccionController =
        TextEditingController(text: proveedor?.direccion ?? '');
    final condicionesPagoController =
        TextEditingController(text: proveedor?.condicionesPago ?? 'CONTADO');
    var tipoIdentificacion = proveedor?.tipoIdentificacion ?? '04';
    var activo = proveedor?.activo ?? true;
    final identificacionFocus = FocusNode();
    var isConsultingSri = false;
    var lastSriConsulta = '';

    await showDialog<void>(
      context: providerContext,
      builder: (context) {
        return AlertDialog(
          title: Text(isEditing ? 'Editar proveedor' : 'Crear proveedor'),
          content: StatefulBuilder(
            builder: (context, setState) {
              Future<void> consultarSri() async {
                if (isEditing) {
                  return;
                }
                final identificacion = identificacionController.text.trim();
                if (identificacion.isEmpty) {
                  showAppToast(
                    providerContext,
                    'Ingresa la identificacion.',
                    isError: true,
                  );
                  return;
                }
                if (tipoIdentificacion != '04' && tipoIdentificacion != '05') {
                  showAppToast(
                    providerContext,
                    'Consulta SRI disponible solo para RUC o Cedula.',
                    isError: true,
                  );
                  return;
                }
                if (tipoIdentificacion == '04' && identificacion.length != 13) {
                  showAppToast(
                    providerContext,
                    'El RUC debe tener 13 digitos.',
                    isError: true,
                  );
                  return;
                }
                if (tipoIdentificacion == '05' && identificacion.length != 10) {
                  showAppToast(
                    providerContext,
                    'La cedula debe tener 10 digitos.',
                    isError: true,
                  );
                  return;
                }
                if (identificacion == lastSriConsulta) {
                  return;
                }
                setState(() => isConsultingSri = true);
                try {
                  final provider =
                      providerContext.read<ProveedoresProvider>();
                  final result = await provider.consultarSri(identificacion);
                  lastSriConsulta = identificacion;
                  if (result.encontrado && result.data != null) {
                    razonSocialController.text =
                        result.data!.razonSocial ?? '';
                    if (nombreComercialController.text.trim().isEmpty) {
                      nombreComercialController.text =
                          result.data!.razonSocial ?? '';
                    }
                    showAppToast(
                      providerContext,
                      'Datos cargados desde SRI.',
                    );
                  } else {
                    showAppToast(
                      providerContext,
                      result.mensaje ??
                          'No existe en SRI. Ingresa todos los datos.',
                      isError: true,
                    );
                  }
                } catch (_) {
                  showAppToast(
                    providerContext,
                    'No se pudo consultar SRI.',
                    isError: true,
                  );
                } finally {
                  if (context.mounted) {
                    setState(() => isConsultingSri = false);
                  }
                }
              }

              if (!identificacionFocus.hasListeners) {
                identificacionFocus.addListener(() {
                  if (!identificacionFocus.hasFocus) {
                    consultarSri();
                  }
                });
              }
              return SizedBox(
                width: 460,
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        value: tipoIdentificacion,
                        items: const [
                          DropdownMenuItem(value: '04', child: Text('RUC')),
                          DropdownMenuItem(value: '05', child: Text('Cedula')),
                          DropdownMenuItem(value: '06', child: Text('Pasaporte')),
                        ],
                        onChanged: isEditing
                            ? null
                            : (value) {
                                if (value != null) {
                                  setState(() => tipoIdentificacion = value);
                                }
                              },
                        decoration: const InputDecoration(labelText: 'Tipo'),
                      ),
                      const SizedBox(height: defaultPadding / 2),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: identificacionController,
                              focusNode: identificacionFocus,
                              decoration: const InputDecoration(
                                labelText: 'Identificacion',
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) => _validateIdentificacion(
                                value,
                                tipoIdentificacion,
                              ),
                              readOnly: isEditing,
                              onFieldSubmitted: (_) => consultarSri(),
                            ),
                          ),
                          const SizedBox(width: defaultPadding / 2),
                          SizedBox(
                            height: 48,
                            child: FilledButton(
                              onPressed:
                                  isConsultingSri ? null : consultarSri,
                              child: isConsultingSri
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text('Consultar'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: defaultPadding / 2),
                      TextFormField(
                        controller: razonSocialController,
                        decoration:
                            const InputDecoration(labelText: 'Razon social'),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Campo requerido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: defaultPadding / 2),
                      TextFormField(
                        controller: nombreComercialController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre comercial',
                        ),
                      ),
                      const SizedBox(height: defaultPadding / 2),
                      TextFormField(
                        controller: emailController,
                        decoration: const InputDecoration(labelText: 'Email'),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          final trimmed = value?.trim() ?? '';
                          if (trimmed.isEmpty) {
                            return null;
                          }
                          if (!trimmed.contains('@')) {
                            return 'Email no valido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: defaultPadding / 2),
                      TextFormField(
                        controller: telefonoController,
                        decoration: const InputDecoration(labelText: 'Telefono'),
                      ),
                      const SizedBox(height: defaultPadding / 2),
                      TextFormField(
                        controller: direccionController,
                        decoration:
                            const InputDecoration(labelText: 'Direccion'),
                      ),
                      const SizedBox(height: defaultPadding / 2),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: condicionesPagoController,
                              decoration: const InputDecoration(
                                labelText: 'Condiciones de pago',
                              ),
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
                              value: activo,
                              onChanged: (value) {
                                setState(() => activo = value);
                              },
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Activo'),
                            ),
                          ),
                        ],
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
                final provider = providerContext.read<ProveedoresProvider>();
                final payload = Proveedor(
                  id: proveedor?.id,
                  tipoIdentificacion: tipoIdentificacion,
                  identificacion: identificacionController.text.trim(),
                  razonSocial: razonSocialController.text.trim(),
                  nombreComercial: nombreComercialController.text.trim(),
                  email: emailController.text.trim(),
                  telefono: telefonoController.text.trim(),
                  direccion: direccionController.text.trim(),
                  condicionesPago: condicionesPagoController.text.trim(),
                  activo: activo,
                );
                final ok = isEditing
                    ? await provider.updateProveedor(payload)
                    : await provider.createProveedor(payload);
                if (!ok) {
                  showAppToast(
                    providerContext,
                    provider.errorMessage ?? 'No se pudo guardar el proveedor.',
                    isError: true,
                  );
                  return;
                }
                if (context.mounted) {
                  Navigator.of(context).pop();
                  showAppToast(
                    providerContext,
                    isEditing
                        ? 'Proveedor actualizado.'
                        : 'Proveedor registrado.',
                  );
                }
              },
              child: Text(isEditing ? 'Guardar' : 'Crear'),
            ),
          ],
        );
      },
    );

    identificacionController.dispose();
    razonSocialController.dispose();
    nombreComercialController.dispose();
    emailController.dispose();
    telefonoController.dispose();
    direccionController.dispose();
    condicionesPagoController.dispose();
    identificacionFocus.dispose();
  }

  Future<void> _confirmInactivate(
    BuildContext providerContext,
    Proveedor proveedor,
  ) async {
    if (proveedor.id == null) {
      showAppToast(
        providerContext,
        'Proveedor sin ID valido.',
        isError: true,
      );
      return;
    }
    final confirmed = await showDialog<bool>(
      context: providerContext,
      builder: (context) {
        return AlertDialog(
          title: const Text('Inactivar proveedor'),
          content: Text(
            'Deseas inactivar a ${proveedor.razonSocial}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Inactivar'),
            ),
          ],
        );
      },
    );
    if (confirmed != true) {
      return;
    }
    final provider = providerContext.read<ProveedoresProvider>();
    final ok = await provider.inactivateProveedor(proveedor.id!);
    if (!ok) {
      showAppToast(
        providerContext,
        provider.errorMessage ?? 'No se pudo inactivar el proveedor.',
        isError: true,
      );
      return;
    }
    showAppToast(providerContext, 'Proveedor inactivado.');
  }

  Future<void> _confirmDelete(
    BuildContext providerContext,
    Proveedor proveedor,
  ) async {
    if (proveedor.id == null) {
      showAppToast(
        providerContext,
        'Proveedor sin ID valido.',
        isError: true,
      );
      return;
    }
    final confirmed = await showDialog<bool>(
      context: providerContext,
      builder: (context) {
        return AlertDialog(
          title: const Text('Eliminar proveedor'),
          content: Text(
            'Deseas eliminar a ${proveedor.razonSocial}?',
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
    if (confirmed != true) {
      return;
    }
    final provider = providerContext.read<ProveedoresProvider>();
    final ok = await provider.inactivateProveedor(proveedor.id!);
    if (!ok) {
      showAppToast(
        providerContext,
        provider.errorMessage ?? 'No se pudo eliminar el proveedor.',
        isError: true,
      );
      return;
    }
    showAppToast(providerContext, 'Proveedor eliminado.');
  }

  Future<void> _openDocumentoManualDialog(
    BuildContext providerContext, {
    required List<Proveedor> proveedores,
    required List<Producto> productos,
    required List<Bodega> bodegas,
  }) async {
    if (proveedores.isEmpty) {
      showAppToast(
        providerContext,
        'Registra proveedores antes de crear documentos.',
        isError: true,
      );
      return;
    }
    if (bodegas.isEmpty) {
      showAppToast(
        providerContext,
        'Registra bodegas antes de crear documentos.',
        isError: true,
      );
      return;
    }
    final formKey = GlobalKey<FormState>();
    int? proveedorId = _selectedProveedorId;
    if (proveedorId == null) {
      proveedorId = _resolveFirstProveedorId(proveedores);
    }
    int? bodegaId = _resolveFirstBodegaId(bodegas);
    String tipoDocumento = 'FACTURA';
    DateTime fechaEmision = DateTime.now();
    final fechaController =
        TextEditingController(text: _formatDate(fechaEmision));
    final numeroController = TextEditingController();
    final autorizacionController = TextEditingController();
    DateTime? fechaVencimiento;
    final fechaVencimientoController = TextEditingController();
    final impuestosController = TextEditingController(text: '0.00');
    final monedaController = TextEditingController(text: 'USD');
    final margenController = TextEditingController();
    final items = <_DocumentoItemDraft>[
      _DocumentoItemDraft(cantidad: 1, costoUnitario: 0, precioVenta: 0),
    ];

    await showDialog<void>(
      context: providerContext,
      builder: (context) {
        return AlertDialog(
          title: const Text('Documento manual'),
          content: StatefulBuilder(
            builder: (context, setState) {
              void applyMargenGlobal() {
                final raw = margenController.text.trim().replaceAll(',', '.');
                final margen = double.tryParse(raw) ?? 0;
                if (margen <= 0) {
                  return;
                }
                setState(() {
                  for (final item in items) {
                    final precio =
                        item.costoUnitario * (1 + (margen / 100));
                    item.precioVenta = precio;
                    item.precioVentaController?.text =
                        precio.toStringAsFixed(2);
                  }
                });
              }

              return SizedBox(
                width: 720,
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DropdownButtonFormField<int>(
                          isExpanded: true,
                          value: proveedorId,
                          items: proveedores
                              .where((proveedor) => proveedor.id != null)
                              .map(
                                (proveedor) => DropdownMenuItem(
                                  value: proveedor.id!,
                                  child: buildProveedorLabel(context, proveedor),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            setState(() => proveedorId = value);
                          },
                          decoration:
                              const InputDecoration(labelText: 'Proveedor'),
                          validator: (value) {
                            if (value == null) {
                              return 'Seleccione proveedor';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: defaultPadding / 2),
                        DropdownButtonFormField<int>(
                          value: bodegaId,
                          items: bodegas
                              .where((bodega) => bodega.id != null)
                              .map(
                                (bodega) => DropdownMenuItem(
                                  value: bodega.id!,
                                  child: Text(bodega.nombre),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            setState(() => bodegaId = value);
                          },
                          decoration: const InputDecoration(labelText: 'Bodega'),
                          validator: (value) {
                            if (value == null) {
                              return 'Seleccione bodega';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: defaultPadding / 2),
                        DropdownButtonFormField<String>(
                          value: tipoDocumento,
                          items: const [
                            DropdownMenuItem(
                              value: 'FACTURA',
                              child: Text('Factura'),
                            ),
                            DropdownMenuItem(
                              value: 'ND',
                              child: Text('Nota de debito'),
                            ),
                            DropdownMenuItem(
                              value: 'NC',
                              child: Text('Nota de credito'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value == null) {
                              return;
                            }
                            setState(() => tipoDocumento = value);
                          },
                          decoration:
                              const InputDecoration(labelText: 'Tipo'),
                        ),
                        const SizedBox(height: defaultPadding / 2),
                        TextFormField(
                          controller: numeroController,
                          decoration: const InputDecoration(
                            labelText: 'Numero documento',
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Campo requerido';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: defaultPadding / 2),
                        TextFormField(
                          controller: fechaController,
                          readOnly: true,
                          decoration: const InputDecoration(
                            labelText: 'Fecha emision',
                          ),
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: fechaEmision,
                              firstDate: DateTime(fechaEmision.year - 1),
                              lastDate: DateTime(fechaEmision.year + 1),
                            );
                            if (date != null) {
                              setState(() {
                                fechaEmision = date;
                                fechaController.text = _formatDate(date);
                              });
                            }
                          },
                        ),
                        const SizedBox(height: defaultPadding / 2),
                        TextFormField(
                          controller: fechaVencimientoController,
                          readOnly: true,
                          decoration: const InputDecoration(
                            labelText: 'Fecha vencimiento',
                          ),
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: fechaVencimiento ?? fechaEmision,
                              firstDate: DateTime(fechaEmision.year - 1),
                              lastDate: DateTime(fechaEmision.year + 2),
                            );
                            if (date != null) {
                              setState(() {
                                fechaVencimiento = date;
                                fechaVencimientoController.text =
                                    _formatDate(date);
                              });
                            }
                          },
                        ),
                        const SizedBox(height: defaultPadding / 2),
                        TextFormField(
                          controller: autorizacionController,
                          decoration: const InputDecoration(
                            labelText: 'Autorizacion (opcional)',
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
                              child: TextFormField(
                                controller: impuestosController,
                                decoration: const InputDecoration(
                                  labelText: 'Impuestos',
                                ),
                                keyboardType: TextInputType.number,
                                onChanged: (_) => setState(() {}),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Campo requerido';
                                  }
                                  if (double.tryParse(value) == null) {
                                    return 'Valor invalido';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: defaultPadding),
                        Wrap(
                          spacing: defaultPadding,
                          runSpacing: defaultPadding / 2,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            SizedBox(
                              width: 180,
                              child: TextFormField(
                                controller: margenController,
                                decoration: const InputDecoration(
                                  labelText: 'Margen % (PVP)',
                                ),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            TextButton.icon(
                              onPressed: applyMargenGlobal,
                              icon: const Icon(Icons.auto_fix_high),
                              label: const Text('Aplicar a todos'),
                            ),
                          ],
                        ),
                        const SizedBox(height: defaultPadding / 2),
                        _DocumentoItemsTable(
                          items: items,
                          productos: productos,
                          onAddItem: () {
                            setState(() {
                              items.add(
                                _DocumentoItemDraft(
                                  cantidad: 1,
                                  costoUnitario: 0,
                                  precioVenta: 0,
                                ),
                              );
                            });
                          },
                          onRemoveItem: (index) {
                            if (items.length == 1) {
                              return;
                            }
                            setState(() {
                              items[index].precioVentaController?.dispose();
                              items.removeAt(index);
                            });
                          },
                          onChanged: () => setState(() {}),
                        ),
                        const SizedBox(height: defaultPadding),
                        _DocumentoTotalPanel(
                          items: items,
                          productos: productos,
                          impuestos: double.tryParse(
                                impuestosController.text.trim(),
                              ) ??
                              0,
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
                if (proveedorId == null) {
                  showAppToast(
                    providerContext,
                    'Seleccione proveedor.',
                    isError: true,
                  );
                  return;
                }
                if (bodegaId == null) {
                  showAppToast(
                    providerContext,
                    'Seleccione bodega.',
                    isError: true,
                  );
                  return;
                }
                if (tipoDocumento == 'FACTURA' &&
                    items.any(
                      (item) => item.productoId == null || item.cantidad <= 0,
                    )) {
                  showAppToast(
                    providerContext,
                    'Completa los items con producto y cantidad.',
                    isError: true,
                  );
                  return;
                }

                final documentoItems = items
                    .where((item) => item.productoId != null)
                    .map(
                      (item) {
                        final producto = productos.firstWhere(
                          (producto) => producto.id == item.productoId,
                          orElse: () => Producto(
                            id: 0,
                            codigo: '-',
                            descripcion: 'Producto',
                            precioUnitario: 0,
                            categoriaId: 0,
                            impuestoId: 0,
                          ),
                        );
                        final costoUnitario = item.costoUnitario > 0
                            ? item.costoUnitario
                            : producto.precioUnitario;
                        final subtotal = costoUnitario * item.cantidad;
                        return DocumentoProveedorItem(
                          bodegaId: bodegaId,
                          productoId: item.productoId,
                          codigoPrincipal: producto.codigo,
                          codigoBarras: producto.codigoBarras,
                          descripcion: producto.descripcion,
                          precioVenta:
                              item.precioVenta > 0 ? item.precioVenta : null,
                          cantidad: item.cantidad,
                          costoUnitario: costoUnitario,
                          subtotal: subtotal,
                        );
                      },
                    )
                    .toList();
                final subtotal = documentoItems.fold<double>(
                  0,
                  (sum, item) => sum + (item.subtotal ?? 0),
                );
                final impuestos = double.tryParse(
                      impuestosController.text.trim(),
                    ) ??
                    0;
                final total = subtotal + impuestos;
                final documento = DocumentoProveedor(
                  tipoDocumento: tipoDocumento,
                  numeroDocumento: numeroController.text.trim(),
                  numeroAutorizacion: autorizacionController.text.trim(),
                  fechaEmision: fechaEmision,
                  fechaVencimiento: fechaVencimiento,
                  subtotal: subtotal,
                  impuestos: impuestos,
                  total: total,
                  moneda: monedaController.text.trim(),
                  items: documentoItems,
                );
                final provider =
                    providerContext.read<DocumentosProveedorProvider>();
                final ok = await provider.createDocumentoManual(
                  proveedorId: proveedorId!,
                  documento: documento,
                );
                if (!ok) {
                  showAppToast(
                    providerContext,
                    provider.errorMessage ??
                        'No se pudo registrar el documento.',
                    isError: true,
                  );
                  return;
                }
                if (context.mounted) {
                  Navigator.of(context).pop();
                  showAppToast(providerContext, 'Documento registrado.');
                }
              },
              child: const Text('Registrar'),
            ),
          ],
        );
      },
    );

    fechaController.dispose();
    numeroController.dispose();
    autorizacionController.dispose();
    fechaVencimientoController.dispose();
    impuestosController.dispose();
    monedaController.dispose();
    margenController.dispose();
    for (final item in items) {
      item.precioVentaController?.dispose();
    }
  }

  Future<void> _openDocumentoXmlDialog(
    BuildContext providerContext, {
    required List<Proveedor> proveedores,
    required List<Bodega> bodegas,
    required List<Producto> productos,
    required List<Categoria> categorias,
    required List<Impuesto> impuestos,
  }) async {
    if (proveedores.isEmpty) {
      showAppToast(
        providerContext,
        'Registra proveedores antes de cargar XML.',
        isError: true,
      );
      return;
    }
    int? proveedorId = _selectedProveedorId;
    if (proveedorId == null) {
      proveedorId = _resolveFirstProveedorId(proveedores);
    }
    PlatformFile? selectedFile;

    await showDialog<void>(
      context: providerContext,
      builder: (context) {
        return AlertDialog(
          title: const Text('Subir XML de proveedor'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<int>(
                    isExpanded: true,
                    value: proveedorId,
                    items: proveedores
                        .where((proveedor) => proveedor.id != null)
                        .map(
                          (proveedor) => DropdownMenuItem(
                            value: proveedor.id!,
                            child: buildProveedorLabel(context, proveedor),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() => proveedorId = value);
                    },
                    decoration: const InputDecoration(labelText: 'Proveedor'),
                  ),
                  const SizedBox(height: defaultPadding),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final result = await FilePicker.platform.pickFiles(
                        type: FileType.custom,
                        allowedExtensions: const ['xml'],
                        withData: true,
                      );
                      if (result != null && result.files.isNotEmpty) {
                        setState(() {
                          selectedFile = result.files.first;
                        });
                      }
                    },
                    icon: const Icon(Icons.attach_file),
                    label: Text(
                      selectedFile == null
                          ? 'Seleccionar XML'
                          : selectedFile!.name,
                    ),
                  ),
                ],
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
                if (proveedorId == null) {
                  showAppToast(
                    providerContext,
                    'Selecciona un proveedor.',
                    isError: true,
                  );
                  return;
                }
                if (selectedFile == null || selectedFile!.bytes == null) {
                  showAppToast(
                    providerContext,
                    'Selecciona el archivo XML.',
                    isError: true,
                  );
                  return;
                }
                final provider =
                    providerContext.read<DocumentosProveedorProvider>();
                final preview = await provider.previewDocumentoXml(
                  proveedorId: proveedorId!,
                  bytes: selectedFile!.bytes!,
                  filename: selectedFile!.name,
                );
                if (preview == null) {
                  showAppToast(
                    providerContext,
                    provider.errorMessage ??
                        'No se pudo obtener el preview.',
                    isError: true,
                  );
                  return;
                }
                if (context.mounted) {
                  Navigator.of(context).pop();
                  _showDocumentoPreviewDialog(
                    providerContext,
                    proveedorId: proveedorId!,
                    preview: preview,
                    bodegas: bodegas,
                    productos: productos,
                    categorias: categorias,
                    impuestos: impuestos,
                  );
                }
              },
              child: const Text('Previsualizar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openAutorizacionDialog(
    BuildContext providerContext, {
    required List<Proveedor> proveedores,
    required List<Bodega> bodegas,
    required List<Producto> productos,
    required List<Categoria> categorias,
    required List<Impuesto> impuestos,
  }) async {
    if (proveedores.isEmpty) {
      showAppToast(
        providerContext,
        'Registra proveedores antes de consultar autorizaciones.',
        isError: true,
      );
      return;
    }
    int? proveedorId = _selectedProveedorId;
    if (proveedorId == null) {
      proveedorId = _resolveFirstProveedorId(proveedores);
    }
    final autorizacionController = TextEditingController();

    await showDialog<void>(
      context: providerContext,
      builder: (context) {
        return AlertDialog(
          title: const Text('Registrar por autorizacion'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<int>(
                      isExpanded: true,
                      value: proveedorId,
                      items: proveedores
                          .where((proveedor) => proveedor.id != null)
                          .map(
                            (proveedor) => DropdownMenuItem(
                              value: proveedor.id!,
                              child: buildProveedorLabel(context, proveedor),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() => proveedorId = value);
                      },
                      decoration: const InputDecoration(labelText: 'Proveedor'),
                    ),
                    const SizedBox(height: defaultPadding),
                    TextFormField(
                      controller: autorizacionController,
                      decoration: const InputDecoration(
                        labelText: 'Numero autorizacion SRI',
                      ),
                    ),
                  ],
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
                final autorizacion = autorizacionController.text.trim();
                if (proveedorId == null || autorizacion.isEmpty) {
                  showAppToast(
                    providerContext,
                    'Completa proveedor y autorizacion.',
                    isError: true,
                  );
                  return;
                }
                final provider =
                    providerContext.read<DocumentosProveedorProvider>();
                final preview = await provider.previewAutorizacion(
                  proveedorId: proveedorId!,
                  autorizacion: autorizacion,
                );
                if (preview == null) {
                  showAppToast(
                    providerContext,
                    provider.errorMessage ?? 'No se pudo obtener el preview.',
                    isError: true,
                  );
                  return;
                }
                if (context.mounted) {
                  Navigator.of(context).pop();
                  _showDocumentoPreviewDialog(
                    providerContext,
                    proveedorId: proveedorId!,
                    preview: preview,
                    bodegas: bodegas,
                    productos: productos,
                    categorias: categorias,
                    impuestos: impuestos,
                  );
                }
              },
              child: const Text('Previsualizar'),
            ),
          ],
        );
      },
    );

    autorizacionController.dispose();
  }

  Future<void> _openPagoDialog(
    BuildContext providerContext, {
    required List<Proveedor> proveedores,
    required List<CuentaPorPagar> cuentas,
  }) async {
    if (proveedores.isEmpty) {
      showAppToast(
        providerContext,
        'Registra proveedores antes de crear pagos.',
        isError: true,
      );
      return;
    }
    int? proveedorId = _selectedProveedorId;
    if (proveedorId == null) {
      proveedorId = _resolveFirstProveedorId(proveedores);
    }
    DateTime fechaPago = DateTime.now();
    final fechaController =
        TextEditingController(text: _formatDate(fechaPago));
    final formaPagoController = TextEditingController();
    final referenciaController = TextEditingController();
    final observacionController = TextEditingController();
    final detalles = <_PagoDetalleDraft>[
      _PagoDetalleDraft(
        valor: 0,
        valorController: TextEditingController(text: '0.00'),
      ),
    ];

    await showDialog<void>(
      context: providerContext,
      builder: (context) {
        return AlertDialog(
          title: const Text('Registrar pago proveedor'),
          content: StatefulBuilder(
            builder: (context, setState) {
              final cxpProvider = providerContext.read<CxpProvider>();
              final cuentasBase = cxpProvider.cuentas.isNotEmpty
                  ? cxpProvider.cuentas
                  : cuentas;
              final cuentasPendientes = cuentasBase
                  .where((cuenta) =>
                      (proveedorId == null ||
                          cuenta.proveedorId == proveedorId) &&
                      (cuenta.saldo ?? 0) > 0)
                  .toList();

              Future<CuentaPorPagar?> pickDocumento() async {
                final searchController = TextEditingController();
                CuentaPorPagar? selected;
                await showDialog<void>(
                  context: context,
                  builder: (context) {
                    return StatefulBuilder(
                      builder: (context, setInnerState) {
                        final query =
                            searchController.text.trim().toLowerCase();
                        final filtered = cuentasPendientes
                            .where((cuenta) => (cuenta.documentoNumero ??
                                    cuenta.numeroDocumento ??
                                    '')
                                .toLowerCase()
                                .contains(query))
                            .toList();
                        return AlertDialog(
                          title: const Text('Seleccionar documento'),
                          content: SizedBox(
                            width: 420,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextField(
                                  controller: searchController,
                                  decoration: const InputDecoration(
                                    labelText: 'Buscar por numero',
                                  ),
                                  onChanged: (_) =>
                                      setInnerState(() {}),
                                ),
                                const SizedBox(height: defaultPadding),
                                SizedBox(
                                  height: 260,
                                  child: ListView(
                                    children: [
                                      for (final cuenta in filtered)
                                        ListTile(
                                          title: Text(
                                            '${cuenta.documentoTipo ?? cuenta.tipoDocumento ?? ''} ${cuenta.documentoNumero ?? cuenta.numeroDocumento ?? '-'}'
                                                .trim(),
                                          ),
                                          subtitle: Text(
                                            'Saldo: ${(cuenta.saldo ?? 0).toStringAsFixed(2)}',
                                          ),
                                          onTap: () {
                                            selected = cuenta;
                                            Navigator.of(context).pop();
                                          },
                                        ),
                                    ],
                                  ),
                                ),
                              ],
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
                  },
                );
                searchController.dispose();
                return selected;
              }

              return SizedBox(
                width: 640,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButtonFormField<int>(
                        isExpanded: true,
                        value: proveedorId,
                        items: proveedores
                            .where((proveedor) => proveedor.id != null)
                            .map(
                              (proveedor) => DropdownMenuItem(
                                value: proveedor.id!,
                                child: buildProveedorLabel(context, proveedor),
                              ),
                            )
                            .toList(),
                        onChanged: (value) async {
                          setState(() => proveedorId = value);
                          if (value != null) {
                            await providerContext
                                .read<CxpProvider>()
                                .fetchCuentas(proveedorId: value);
                            if (context.mounted) {
                              setState(() {});
                            }
                          }
                        },
                        decoration:
                            const InputDecoration(labelText: 'Proveedor'),
                      ),
                      const SizedBox(height: defaultPadding / 2),
                      TextFormField(
                        controller: fechaController,
                        readOnly: true,
                        decoration:
                            const InputDecoration(labelText: 'Fecha pago'),
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: fechaPago,
                            firstDate: DateTime(fechaPago.year - 1),
                            lastDate: DateTime(fechaPago.year + 1),
                          );
                          if (date != null) {
                            setState(() {
                              fechaPago = date;
                              fechaController.text = _formatDate(date);
                            });
                          }
                        },
                      ),
                      const SizedBox(height: defaultPadding / 2),
                      TextFormField(
                        controller: formaPagoController,
                        decoration:
                            const InputDecoration(labelText: 'Forma de pago'),
                      ),
                      const SizedBox(height: defaultPadding / 2),
                      TextFormField(
                        controller: referenciaController,
                        decoration:
                            const InputDecoration(labelText: 'Referencia'),
                      ),
                      const SizedBox(height: defaultPadding / 2),
                      TextFormField(
                        controller: observacionController,
                        decoration:
                            const InputDecoration(labelText: 'Observacion'),
                        maxLines: 2,
                      ),
                      const SizedBox(height: defaultPadding),
                      _PagoDetallesTable(
                        detalles: detalles,
                        onPickDocumento: pickDocumento,
                        onAdd: () {
                          setState(
                            () => detalles.add(
                              _PagoDetalleDraft(
                                valor: 0,
                                valorController:
                                    TextEditingController(text: '0.00'),
                              ),
                            ),
                          );
                        },
                        onRemove: (index) {
                          if (detalles.length == 1) {
                            return;
                          }
                          setState(() {
                            detalles[index].valorController?.dispose();
                            detalles.removeAt(index);
                          });
                        },
                        onChanged: () => setState(() {}),
                      ),
                      const SizedBox(height: defaultPadding),
                      _PagoTotalPanel(detalles: detalles),
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
                if (proveedorId == null) {
                  showAppToast(
                    providerContext,
                    'Selecciona proveedor.',
                    isError: true,
                  );
                  return;
                }
                if (detalles.any(
                  (detalle) =>
                      detalle.cuentaPorPagarId == null || detalle.valor <= 0,
                )) {
                  showAppToast(
                    providerContext,
                    'Completa los documentos y valores.',
                    isError: true,
                  );
                  return;
                }
                showFacturaProcessingDialog(
                  context: providerContext,
                  title: 'Procesando pago...',
                  message:
                      'Estamos registrando el pago. Por favor, no cierres la ventana.',
                );
                final total = detalles.fold<double>(
                  0,
                  (sum, detalle) => sum + detalle.valor,
                );
                final pago = PagoProveedor(
                  proveedorId: proveedorId!,
                  fechaPago: fechaPago,
                  montoTotal: total,
                  formaPago: formaPagoController.text.trim(),
                  referencia: referenciaController.text.trim(),
                  observacion: observacionController.text.trim(),
                  detalles: detalles
                      .map(
                        (detalle) => PagoProveedorDetalle(
                          cuentaPorPagarId: detalle.cuentaPorPagarId,
                          montoAplicado: detalle.valor,
                        ),
                      )
                      .toList(),
                );
                final provider =
                    providerContext.read<PagosProveedorProvider>();
                final ok = await provider.createPago(pago);
                if (providerContext.mounted) {
                  Navigator.of(providerContext).pop();
                }
                if (!ok) {
                  showAppToast(
                    providerContext,
                    provider.errorMessage ?? 'No se pudo registrar el pago.',
                    isError: true,
                  );
                  return;
                }
                if (context.mounted) {
                  Navigator.of(context).pop();
                  showAppToast(providerContext, 'Pago registrado.');
                }
              },
              child: const Text('Registrar'),
            ),
          ],
        );
      },
    );

    fechaController.dispose();
    formaPagoController.dispose();
    referenciaController.dispose();
    observacionController.dispose();
    for (final detalle in detalles) {
      detalle.valorController?.dispose();
    }
  }

  Future<void> _showDocumentoPreviewDialog(
    BuildContext providerContext, {
    required int proveedorId,
    required DocumentoProveedor preview,
    required List<Bodega> bodegas,
    required List<Producto> productos,
    required List<Categoria> categorias,
    required List<Impuesto> impuestos,
  }) async {
    final availableCategorias = List<Categoria>.from(categorias);
    final availableImpuestos = List<Impuesto>.from(impuestos);
    final availableBodegas = List<Bodega>.from(bodegas);
    final items = preview.items
        .map(
          (item) => _DocumentoPreviewItemDraft(
            bodegaId: item.bodegaId,
            productoId: item.productoId,
            categoriaId: item.categoriaId,
            impuestoId: item.impuestoId,
            codigoPrincipal: item.codigoPrincipal ?? '',
            codigoBarras: item.codigoBarras ?? '',
            descripcion: item.descripcion ?? '',
            precioVenta:
                item.precioVenta ?? item.costoUnitario ?? 0,
            cantidad: item.cantidad ?? 0,
            costoUnitario: item.costoUnitario ?? 0,
            subtotal: item.subtotal ?? 0,
          ),
        )
        .toList();
    for (final item in items) {
      item.codigoBarrasController ??=
          TextEditingController(text: item.codigoBarras ?? '');
      item.precioVentaController ??=
          TextEditingController(text: item.precioVenta.toStringAsFixed(2));
    }
    final hasBodegas =
        availableBodegas.where((bodega) => bodega.id != null).isNotEmpty;
    int? bulkBodegaId = availableBodegas
        .firstWhere(
          (b) => b.id != null,
          orElse: () => Bodega(
            id: null,
            nombre: '',
            descripcion: '',
            direccion: '',
            activa: true,
          ),
        )
        .id;
    int? bulkCategoriaId;
    int? bulkImpuestoId;
    final margenController = TextEditingController();
    if (bulkBodegaId != null) {
      for (final item in items) {
        item.bodegaId ??= bulkBodegaId;
      }
    }
    var isSaving = false;

    await showDialog<void>(
      context: providerContext,
      builder: (context) {
        return AlertDialog(
          title: const Text('Preview documento proveedor'),
          content: StatefulBuilder(
            builder: (context, setState) {
              Future<void> applyBodegaToAll(int? bodegaId) async {
                setState(() {
                  bulkBodegaId = bodegaId;
                  for (final item in items) {
                    item.bodegaId = bodegaId;
                  }
                });
              }

              Future<void> applyCategoriaToAll(int? categoriaId) async {
                setState(() {
                  bulkCategoriaId = categoriaId;
                  for (final item in items) {
                    if (item.productoId == null) {
                      item.categoriaId = categoriaId;
                    }
                  }
                });
              }

              Future<void> applyImpuestoToAll(int? impuestoId) async {
                setState(() {
                  bulkImpuestoId = impuestoId;
                  for (final item in items) {
                    if (item.productoId == null) {
                      item.impuestoId = impuestoId;
                    }
                  }
                });
              }

              void applyMargenToAll() {
                final raw =
                    margenController.text.trim().replaceAll(',', '.');
                final margen = double.tryParse(raw) ?? 0;
                if (margen <= 0) {
                  return;
                }
                setState(() {
                  for (final item in items) {
                    final precio =
                        item.costoUnitario * (1 + (margen / 100));
                    item.precioVenta = precio;
                    item.precioVentaController?.text =
                        precio.toStringAsFixed(2);
                  }
                });
              }

              Future<Bodega?> pickBodega() async {
                final controller = TextEditingController();
                Bodega? selected;
                await showDialog<void>(
                  context: context,
                  builder: (context) {
                    return StatefulBuilder(
                      builder: (context, setInnerState) {
                        final query = controller.text.trim().toLowerCase();
                        final filtered = availableBodegas
                            .where((bodega) =>
                                bodega.nombre.toLowerCase().contains(query))
                            .toList();
                        return AlertDialog(
                          title: const Text('Seleccionar bodega'),
                          content: SizedBox(
                            width: 380,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextField(
                                  controller: controller,
                                  decoration: const InputDecoration(
                                    labelText: 'Buscar bodega',
                                  ),
                                  onChanged: (_) =>
                                      setInnerState(() {}),
                                ),
                                const SizedBox(height: defaultPadding),
                                SizedBox(
                                  height: 220,
                                  child: ListView(
                                    children: [
                                      for (final bodega in filtered)
                                        ListTile(
                                          title: Text(bodega.nombre),
                                          onTap: () {
                                            selected = bodega;
                                            Navigator.of(context).pop();
                                          },
                                        ),
                                    ],
                                  ),
                                ),
                              ],
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
                  },
                );
                controller.dispose();
                return selected;
              }

              Future<Impuesto?> pickImpuesto() async {
                final controller = TextEditingController();
                Impuesto? selected;
                await showDialog<void>(
                  context: context,
                  builder: (context) {
                    return StatefulBuilder(
                      builder: (context, setInnerState) {
                        final query = controller.text.trim().toLowerCase();
                        final filtered = availableImpuestos
                            .where((impuesto) =>
                                impuesto.descripcion
                                    .toLowerCase()
                                    .contains(query))
                            .toList();
                        return AlertDialog(
                          title: const Text('Seleccionar impuesto'),
                          content: SizedBox(
                            width: 420,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextField(
                                  controller: controller,
                                  decoration: const InputDecoration(
                                    labelText: 'Buscar impuesto',
                                  ),
                                  onChanged: (_) =>
                                      setInnerState(() {}),
                                ),
                                const SizedBox(height: defaultPadding),
                                SizedBox(
                                  height: 240,
                                  child: ListView(
                                    children: [
                                      for (final impuesto in filtered)
                                        ListTile(
                                          title: Text(
                                            '${impuesto.descripcion} (${impuesto.tarifa.toStringAsFixed(2)}%)',
                                          ),
                                          onTap: () {
                                            selected = impuesto;
                                            Navigator.of(context).pop();
                                          },
                                        ),
                                    ],
                                  ),
                                ),
                              ],
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
                  },
                );
                controller.dispose();
                return selected;
              }

              Future<Categoria?> pickCategoria() async {
                final controller = TextEditingController();
                Categoria? selected;
                await showDialog<void>(
                  context: context,
                  builder: (context) {
                    return StatefulBuilder(
                      builder: (context, setInnerState) {
                        final query = controller.text.trim().toLowerCase();
                        final filtered = availableCategorias
                            .where((categoria) =>
                                categoria.nombre.toLowerCase().contains(query))
                            .toList();
                        return AlertDialog(
                          title: const Text('Seleccionar categoria'),
                          content: SizedBox(
                            width: 380,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextField(
                                  controller: controller,
                                  decoration: const InputDecoration(
                                    labelText: 'Buscar o crear',
                                  ),
                                  onChanged: (_) =>
                                      setInnerState(() {}),
                                ),
                                const SizedBox(height: defaultPadding),
                                SizedBox(
                                  height: 220,
                                  child: ListView(
                                    children: [
                                      for (final categoria in filtered)
                                        ListTile(
                                          title: Text(categoria.nombre),
                                          onTap: () {
                                            selected = categoria;
                                            Navigator.of(context).pop();
                                          },
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Cancelar'),
                            ),
                            if (controller.text.trim().isNotEmpty)
                              FilledButton(
                                onPressed: () async {
                                  final nombre = controller.text.trim();
                                  final provider = providerContext
                                      .read<CategoriasProvider>();
                                  final ok = await provider.createCategoria(
                                    Categoria(
                                      nombre: nombre,
                                      descripcion: nombre,
                                    ),
                                  );
                                  if (!ok) {
                                    if (context.mounted) {
                                      showAppToast(
                                        providerContext,
                                        provider.errorMessage ??
                                            'No se pudo crear la categoria.',
                                        isError: true,
                                      );
                                    }
                                    return;
                                  }
                                  final created = provider.categorias
                                      .firstWhere(
                                        (item) =>
                                            item.nombre.toLowerCase() ==
                                            nombre.toLowerCase(),
                                        orElse: () => Categoria(
                                          id: null,
                                          nombre: nombre,
                                          descripcion: nombre,
                                        ),
                                      );
                                  if (created.id != null) {
                                    availableCategorias.add(created);
                                    selected = created;
                                  }
                                  if (context.mounted) {
                                    Navigator.of(context).pop();
                                  }
                                },
                                child: const Text('Crear'),
                              ),
                          ],
                        );
                      },
                    );
                  },
                );
                controller.dispose();
                return selected;
              }

              return SizedBox(
                width: 900,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _PreviewHeader(preview: preview),
                      const SizedBox(height: defaultPadding),
                      _PreviewBulkSelectors(
                        bodegas: availableBodegas,
                        categorias: availableCategorias,
                        impuestos: availableImpuestos,
                        bulkBodegaId: bulkBodegaId,
                        bulkCategoriaId: bulkCategoriaId,
                        bulkImpuestoId: bulkImpuestoId,
                        onBodegaPressed: () async {
                          final bodega = await pickBodega();
                          if (bodega != null) {
                            applyBodegaToAll(bodega.id);
                          }
                        },
                        onCategoriaPressed: () async {
                          final categoria = await pickCategoria();
                          if (categoria != null) {
                            applyCategoriaToAll(categoria.id);
                          }
                        },
                        onImpuestoPressed: () async {
                          final impuesto = await pickImpuesto();
                          if (impuesto != null) {
                            applyImpuestoToAll(impuesto.id);
                          }
                        },
                      ),
                      const SizedBox(height: defaultPadding / 2),
                      Wrap(
                        spacing: defaultPadding,
                        runSpacing: defaultPadding / 2,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          SizedBox(
                            width: 180,
                            child: TextFormField(
                              controller: margenController,
                              decoration: const InputDecoration(
                                labelText: 'Margen % (PVP)',
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: applyMargenToAll,
                            icon: const Icon(Icons.auto_fix_high),
                            label: const Text('Aplicar a todos'),
                          ),
                        ],
                      ),
                      const SizedBox(height: defaultPadding / 2),
                      if (!hasBodegas)
                        Text(
                          'No hay bodegas registradas. No se puede guardar.',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      if (isSaving)
                        Padding(
                          padding: const EdgeInsets.only(top: defaultPadding / 2),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const LinearProgressIndicator(),
                              const SizedBox(height: 6),
                              Text(
                                'Estamos guardando...',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: defaultPadding / 2),
                      _PreviewItemsTable(
                        items: items,
                        bodegas: availableBodegas,
                        productos: productos,
                        categorias: availableCategorias,
                        impuestos: availableImpuestos,
                        onChanged: () => setState(() {}),
                        onPickCategoria: pickCategoria,
                        onPickBodega: pickBodega,
                        onPickImpuesto: pickImpuesto,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
            FilledButton(
              onPressed: isSaving
                  ? null
                  : () async {
                if (!hasBodegas) {
                  showAppToast(
                    providerContext,
                    'Registra bodegas para guardar.',
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
                if (items.any((item) =>
                    item.productoId == null &&
                    (item.categoriaId == null || item.impuestoId == null))) {
                  showAppToast(
                    providerContext,
                    'Asigna categoria e impuesto para productos nuevos.',
                    isError: true,
                  );
                  return;
                }
                if (items.any(
                  (item) => item.productoId == null && item.precioVenta <= 0,
                )) {
                  showAppToast(
                    providerContext,
                    'Ingresa el precio de venta para productos nuevos.',
                    isError: true,
                  );
                  return;
                }
                final documento = DocumentoProveedor(
                  tipoDocumento: preview.tipoDocumento,
                  numeroDocumento: preview.numeroDocumento,
                  numeroAutorizacion: preview.numeroAutorizacion,
                  fechaEmision: preview.fechaEmision,
                  subtotal: preview.subtotal,
                  impuestos: preview.impuestos,
                  total: preview.total,
                  moneda: preview.moneda ?? 'USD',
                  items: items
                      .map(
                        (item) => DocumentoProveedorItem(
                          bodegaId: item.bodegaId,
                          productoId: item.productoId,
                          categoriaId: item.productoId == null
                              ? item.categoriaId
                              : null,
                          impuestoId: item.productoId == null
                              ? item.impuestoId
                              : null,
                          codigoPrincipal: item.codigoPrincipal,
                          codigoBarras: item.codigoBarras?.trim().isEmpty ?? true
                              ? null
                              : item.codigoBarras?.trim(),
                          descripcion: item.descripcion,
                          precioVenta:
                              item.precioVenta > 0 ? item.precioVenta : null,
                          cantidad: item.cantidad,
                          costoUnitario: item.costoUnitario,
                          subtotal: item.subtotal,
                        ),
                      )
                      .toList(),
                );
                final provider =
                    providerContext.read<DocumentosProveedorProvider>();
                setState(() => isSaving = true);
                showFacturaProcessingDialog(
                  context: providerContext,
                  title: 'Procesando documento...',
                  message:
                      'Estamos guardando el documento. Por favor, no cierres la ventana.',
                );
                final ok = await provider.createDocumentoManual(
                  proveedorId: proveedorId,
                  documento: documento,
                );
                if (providerContext.mounted) {
                  Navigator.of(providerContext).pop();
                }
                if (context.mounted) {
                  setState(() => isSaving = false);
                }
                if (!ok) {
                  showAppToast(
                    providerContext,
                    provider.errorMessage ??
                        'No se pudo registrar el documento.',
                    isError: true,
                  );
                  return;
                }
                if (context.mounted) {
                  Navigator.of(context).pop();
                  showAppToast(providerContext, 'Documento registrado.');
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
    for (final item in items) {
      item.codigoBarrasController?.dispose();
      item.precioVentaController?.dispose();
    }
    margenController.dispose();
  }

  String? _validateIdentificacion(String? value, String tipo) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return 'Campo requerido';
    }
    if (tipo == '05' && trimmed.length != 10) {
      return 'Debe tener 10 digitos';
    }
    if (tipo == '04' && trimmed.length != 13) {
      return 'Debe tener 13 digitos';
    }
    if (tipo == '06' && trimmed.length < 5) {
      return 'Minimo 5 caracteres';
    }
    return null;
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  int? _resolveFirstProveedorId(List<Proveedor> proveedores) {
    for (final proveedor in proveedores) {
      if (proveedor.id != null) {
        return proveedor.id;
      }
    }
    return null;
  }

  int? _resolveFirstBodegaId(List<Bodega> bodegas) {
    for (final bodega in bodegas) {
      if (bodega.id != null) {
        return bodega.id;
      }
    }
    return null;
  }
}

class _TabSelector extends StatelessWidget {
  const _TabSelector({
    required this.currentIndex,
    required this.onChanged,
  });

  final int currentIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final labels = const ['Proveedores', 'Documentos', 'CxP', 'Pagos'];
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: List.generate(labels.length, (index) {
        final selected = index == currentIndex;
        return ChoiceChip(
          label: Text(labels[index]),
          selected: selected,
          onSelected: (_) => onChanged(index),
        );
      }),
    );
  }
}

class _ProveedorFilter extends StatelessWidget {
  const _ProveedorFilter({
    required this.proveedores,
    required this.value,
    required this.onChanged,
  });

  final List<Proveedor> proveedores;
  final int? value;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 420,
      child: DropdownButtonFormField<int?>(
        value: value,
        isExpanded: true,
        items: [
          const DropdownMenuItem<int?>(
            value: null,
            child: Text('Todos los proveedores'),
          ),
          ...proveedores
              .where((proveedor) => proveedor.id != null)
              .map(
            (proveedor) => DropdownMenuItem<int?>(
              value: proveedor.id,
              child: buildProveedorLabel(context, proveedor),
            ),
              ),
        ],
        onChanged: onChanged,
        decoration: const InputDecoration(labelText: 'Proveedor'),
      ),
    );
  }
}

class _ProveedoresList extends StatelessWidget {
  const _ProveedoresList({
    required this.proveedores,
    required this.onEdit,
    required this.onInactivate,
    required this.onDelete,
  });

  final List<Proveedor> proveedores;
  final void Function(Proveedor proveedor) onEdit;
  final void Function(Proveedor proveedor) onInactivate;
  final void Function(Proveedor proveedor) onDelete;

  @override
  Widget build(BuildContext context) {
    if (proveedores.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(defaultPadding),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.all(Radius.circular(10)),
        ),
        child: const Text('Sin proveedores registrados.'),
      );
    }

    if (Responsive.isMobile(context)) {
      return Column(
        children: proveedores
            .map(
              (proveedor) => Card(
                child: ListTile(
                  title: Text(proveedor.razonSocial),
                  subtitle: Text(proveedor.identificacion),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        tooltip: 'Editar',
                        onPressed: () => onEdit(proveedor),
                      ),
                      IconButton(
                        icon: const Icon(Icons.block_outlined),
                        tooltip: 'Inactivar',
                        onPressed: () => onInactivate(proveedor),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        tooltip: 'Eliminar',
                        onPressed: () => onDelete(proveedor),
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
        final cardWidth = maxWidth > 1200 ? 1080.0 : maxWidth;
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
                    DataColumn(label: Text('Tipo')),
                    DataColumn(label: Text('Identificacion')),
                    DataColumn(label: Text('Razon social')),
                    DataColumn(label: Text('Nombre comercial')),
                    DataColumn(label: Text('Email')),
                    DataColumn(label: Text('Telefono')),
                    DataColumn(label: Text('Direccion')),
                    DataColumn(label: Text('Condiciones')),
                    DataColumn(label: Text('Estado')),
                    DataColumn(label: Text('Acciones')),
                  ],
                  rows: proveedores
                      .map(
                        (proveedor) => DataRow(
                          cells: [
                            DataCell(Text(proveedor.tipoIdentificacion)),
                            DataCell(Text(proveedor.identificacion)),
                            DataCell(Text(proveedor.razonSocial)),
                            DataCell(Text(proveedor.nombreComercial ?? '-')),
                            DataCell(Text(proveedor.email)),
                            DataCell(Text(proveedor.telefono)),
                            DataCell(Text(proveedor.direccion)),
                            DataCell(Text(proveedor.condicionesPago ?? '-')),
                            DataCell(Text(
                              proveedor.activo == null
                                  ? '-'
                                  : proveedor.activo!
                                      ? 'Activo'
                                      : 'Inactivo',
                            )),
                            DataCell(
                              Row(
                                children: [
                                  IconButton(
                                    tooltip: 'Editar',
                                    onPressed: () => onEdit(proveedor),
                                    icon: const Icon(Icons.edit_outlined),
                                  ),
                                  IconButton(
                                    tooltip: 'Inactivar',
                                    onPressed: () => onInactivate(proveedor),
                                    icon: const Icon(Icons.block_outlined),
                                  ),
                                  IconButton(
                                    tooltip: 'Eliminar',
                                    onPressed: () => onDelete(proveedor),
                                    icon: const Icon(Icons.delete_outline),
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

class _DocumentosList extends StatelessWidget {
  const _DocumentosList({required this.documentos});

  final List<DocumentoProveedor> documentos;

  @override
  Widget build(BuildContext context) {
    if (documentos.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(defaultPadding),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.all(Radius.circular(10)),
        ),
        child: const Text('Sin documentos registrados.'),
      );
    }

    if (Responsive.isMobile(context)) {
      return Column(
        children: documentos
            .map(
              (documento) => Card(
                child: ListTile(
                  title: Text(
                    '${documento.tipoDocumento ?? '-'} #${documento.numeroDocumento ?? '-'}',
                  ),
                  subtitle: Text(
                    _formatDateValue(documento.fechaEmision) ??
                        'Fecha sin definir',
                  ),
                  trailing: Text(
                    (documento.total ?? 0).toStringAsFixed(2),
                    style: const TextStyle(fontWeight: FontWeight.w600),
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
        final cardWidth = maxWidth > 1200 ? 1080.0 : maxWidth;
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
                    DataColumn(label: Text('Tipo')),
                    DataColumn(label: Text('Numero')),
                    DataColumn(label: Text('Fecha')),
                    DataColumn(label: Text('Total')),
                    DataColumn(label: Text('Estado')),
                    DataColumn(label: Text('Autorizacion')),
                  ],
                  rows: documentos
                      .map(
                        (documento) => DataRow(
                          cells: [
                            DataCell(Text(documento.tipoDocumento ?? '-')),
                            DataCell(Text(documento.numeroDocumento ?? '-')),
                            DataCell(
                              Text(
                                _formatDateValue(documento.fechaEmision) ??
                                    '-',
                              ),
                            ),
                            DataCell(
                              Text((documento.total ?? 0).toStringAsFixed(2)),
                            ),
                            DataCell(Text(documento.estado ?? '-')),
                            DataCell(Text(documento.numeroAutorizacion ?? '-')),
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

class _CxpList extends StatelessWidget {
  const _CxpList({required this.cuentas});

  final List<CuentaPorPagar> cuentas;

  @override
  Widget build(BuildContext context) {
    if (cuentas.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(defaultPadding),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.all(Radius.circular(10)),
        ),
        child: const Text('Sin cuentas por pagar.'),
      );
    }

    if (Responsive.isMobile(context)) {
      return Column(
        children: cuentas
            .map(
              (cuenta) => Card(
                child: ListTile(
                  title: Text(
                    cuenta.documentoNumero ??
                        cuenta.numeroDocumento ??
                        '-',
                  ),
                  subtitle: Text(
                    '${cuenta.documentoTipo ?? cuenta.tipoDocumento ?? '-'} | ${_formatDateValue(cuenta.fechaEmision) ?? 'Fecha sin definir'}',
                  ),
                  trailing: Text(
                    (cuenta.saldo ?? cuenta.total ?? 0).toStringAsFixed(2),
                    style: const TextStyle(fontWeight: FontWeight.w600),
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
        final cardWidth = maxWidth > 1200 ? 1080.0 : maxWidth;
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
                    DataColumn(label: Text('Documento')),
                    DataColumn(label: Text('Tipo')),
                    DataColumn(label: Text('Fecha')),
                    DataColumn(label: Text('Vencimiento')),
                    DataColumn(label: Text('Total')),
                    DataColumn(label: Text('Saldo')),
                    DataColumn(label: Text('Estado')),
                  ],
                  rows: cuentas
                      .map(
                        (cuenta) => DataRow(
                          cells: [
                            DataCell(
                              Text(
                                cuenta.documentoNumero ??
                                    cuenta.numeroDocumento ??
                                    '-',
                              ),
                            ),
                            DataCell(
                              Text(
                                cuenta.documentoTipo ??
                                    cuenta.tipoDocumento ??
                                    '-',
                              ),
                            ),
                            DataCell(
                              Text(
                                _formatDateValue(cuenta.fechaEmision) ?? '-',
                              ),
                            ),
                            DataCell(
                              Text(
                                _formatDateValue(cuenta.fechaVencimiento) ??
                                    '-',
                              ),
                            ),
                            DataCell(
                              Text((cuenta.total ?? 0).toStringAsFixed(2)),
                            ),
                            DataCell(
                              Text((cuenta.saldo ?? 0).toStringAsFixed(2)),
                            ),
                            DataCell(Text(cuenta.estado ?? '-')),
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

class _PagosList extends StatelessWidget {
  const _PagosList({required this.pagos});

  final List<PagoProveedor> pagos;

  @override
  Widget build(BuildContext context) {
    if (pagos.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(defaultPadding),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.all(Radius.circular(10)),
        ),
        child: const Text('Sin pagos registrados.'),
      );
    }

    if (Responsive.isMobile(context)) {
      return Column(
        children: pagos
            .map(
              (pago) => Card(
                child: ListTile(
                  title: Text(
                    _formatDateValue(pago.fechaPago) ?? 'Pago sin fecha',
                  ),
                  subtitle: Text(pago.formaPago ?? 'Forma sin definir'),
                  trailing: Text(
                    pago.montoTotal.toStringAsFixed(2),
                    style: const TextStyle(fontWeight: FontWeight.w600),
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
        final cardWidth = maxWidth > 1200 ? 1080.0 : maxWidth;
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
                    DataColumn(label: Text('Fecha')),
                    DataColumn(label: Text('Total')),
                    DataColumn(label: Text('Forma')),
                    DataColumn(label: Text('Referencia')),
                    DataColumn(label: Text('Detalles')),
                    DataColumn(label: Text('Estado')),
                  ],
                  rows: pagos
                      .map(
                        (pago) => DataRow(
                          cells: [
                            DataCell(
                              Text(_formatDateValue(pago.fechaPago) ?? '-'),
                            ),
                            DataCell(Text(pago.montoTotal.toStringAsFixed(2))),
                            DataCell(Text(pago.formaPago ?? '-')),
                            DataCell(Text(pago.referencia ?? '-')),
                            DataCell(Text('${pago.detalles.length}')),
                            DataCell(Text(pago.estado ?? '-')),
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

class _DocumentoItemsTable extends StatefulWidget {
  const _DocumentoItemsTable({
    required this.items,
    required this.productos,
    required this.onAddItem,
    required this.onRemoveItem,
    this.onChanged,
  });

  final List<_DocumentoItemDraft> items;
  final List<Producto> productos;
  final VoidCallback onAddItem;
  final void Function(int index) onRemoveItem;
  final VoidCallback? onChanged;

  @override
  State<_DocumentoItemsTable> createState() => _DocumentoItemsTableState();
}

class _DocumentoItemsTableState extends State<_DocumentoItemsTable> {
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
                    flex: 5,
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
                          if (value != null &&
                              (item.precioVenta <= 0 ||
                                  (item.precioVentaController?.text ?? '')
                                      .trim()
                                      .isEmpty)) {
                            final producto = widget.productos.firstWhere(
                              (producto) => producto.id == value,
                              orElse: () => Producto(
                                id: 0,
                                codigo: '-',
                                descripcion: '-',
                                precioUnitario: 0,
                                categoriaId: 0,
                                impuestoId: 0,
                              ),
                            );
                            item.precioVenta = producto.precioUnitario;
                            item.precioVentaController?.text =
                                producto.precioUnitario.toStringAsFixed(2);
                          }
                        });
                        widget.onChanged?.call();
                      },
                      decoration:
                          const InputDecoration(labelText: 'Producto'),
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
                    flex: 3,
                    child: TextFormField(
                      initialValue: item.costoUnitario.toStringAsFixed(2),
                      decoration: const InputDecoration(labelText: 'Costo'),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        setState(() {
                          item.costoUnitario = double.tryParse(value) ?? 0;
                        });
                        widget.onChanged?.call();
                      },
                    ),
                  ),
                  const SizedBox(width: defaultPadding / 2),
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: item.precioVentaController,
                      decoration:
                          const InputDecoration(labelText: 'PVP'),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        setState(() {
                          item.precioVenta = double.tryParse(value) ?? 0;
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

class _DocumentoTotalPanel extends StatelessWidget {
  const _DocumentoTotalPanel({
    required this.items,
    required this.productos,
    required this.impuestos,
  });

  final List<_DocumentoItemDraft> items;
  final List<Producto> productos;
  final double impuestos;

  @override
  Widget build(BuildContext context) {
    double subtotal = 0;
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
      final costo = item.costoUnitario > 0
          ? item.costoUnitario
          : producto.precioUnitario;
      subtotal += costo * item.cantidad;
    }
    final total = subtotal + impuestos;

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
          _TotalRow(label: 'Impuestos', value: impuestos),
          const Divider(),
          _TotalRow(label: 'Total', value: total, isEmphasis: true),
        ],
      ),
    );
  }
}

class _PreviewHeader extends StatelessWidget {
  const _PreviewHeader({required this.preview});

  final DocumentoProveedor preview;

  @override
  Widget build(BuildContext context) {
    final rows = <_PreviewRow>[
      _PreviewRow('Tipo', preview.tipoDocumento ?? '-'),
      _PreviewRow('Numero', preview.numeroDocumento ?? '-'),
      _PreviewRow('Autorizacion', preview.numeroAutorizacion ?? '-'),
      _PreviewRow(
        'Emisor',
        preview.razonSocialEmisor ??
            preview.identificacionEmisor ??
            '-',
      ),
      _PreviewRow(
        'Identificacion',
        preview.identificacionEmisor ?? '-',
      ),
      _PreviewRow(
        'Fecha',
        _formatDateValue(preview.fechaEmision) ?? '-',
      ),
      _PreviewRow(
        'Subtotal',
        (preview.subtotal ?? 0).toStringAsFixed(2),
      ),
      _PreviewRow(
        'Impuestos',
        (preview.impuestos ?? 0).toStringAsFixed(2),
      ),
      _PreviewRow(
        'Total',
        (preview.total ?? 0).toStringAsFixed(2),
      ),
      _PreviewRow('Moneda', preview.moneda ?? '-'),
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: rows
          .map(
            (row) => Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface.withAlpha(210),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withAlpha(80),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    row.label,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    row.value,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _PreviewBulkSelectors extends StatelessWidget {
  const _PreviewBulkSelectors({
    required this.bodegas,
    required this.categorias,
    required this.impuestos,
    required this.bulkBodegaId,
    required this.bulkCategoriaId,
    required this.bulkImpuestoId,
    required this.onBodegaPressed,
    required this.onCategoriaPressed,
    required this.onImpuestoPressed,
  });

  final List<Bodega> bodegas;
  final List<Categoria> categorias;
  final List<Impuesto> impuestos;
  final int? bulkBodegaId;
  final int? bulkCategoriaId;
  final int? bulkImpuestoId;
  final VoidCallback onBodegaPressed;
  final VoidCallback onCategoriaPressed;
  final VoidCallback onImpuestoPressed;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 220,
          child: InkWell(
            onTap: onBodegaPressed,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface.withAlpha(220),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withAlpha(120),
                ),
              ),
              child: Text(
                bulkBodegaId == null
                    ? 'Bodega para todos'
                    : 'Bodega: ${bodegas.firstWhere((b) => b.id == bulkBodegaId, orElse: () => Bodega(id: 0, nombre: '-', descripcion: '-', direccion: '-', activa: true)).nombre}',
              ),
            ),
          ),
        ),
        SizedBox(
          width: 220,
          child: InkWell(
            onTap: onCategoriaPressed,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface.withAlpha(220),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withAlpha(120),
                ),
              ),
              child: Text(
                bulkCategoriaId == null
                    ? 'Categoria para todos'
                    : 'Categoria: ${categorias.firstWhere((c) => c.id == bulkCategoriaId, orElse: () => Categoria(id: 0, nombre: '-', descripcion: '-')).nombre}',
              ),
            ),
          ),
        ),
        SizedBox(
          width: 220,
          child: InkWell(
            onTap: onImpuestoPressed,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface.withAlpha(220),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withAlpha(120),
                ),
              ),
              child: Text(
                bulkImpuestoId == null
                    ? 'Impuesto para todos'
                    : 'Impuesto: ${impuestos.firstWhere((i) => i.id == bulkImpuestoId, orElse: () => Impuesto(id: 0, codigo: '-', codigoPorcentaje: '-', tarifa: 0, descripcion: '-', activo: true)).descripcion}',
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PreviewRow {
  const _PreviewRow(this.label, this.value);

  final String label;
  final String value;
}

class _PreviewItemsTable extends StatefulWidget {
  const _PreviewItemsTable({
    required this.items,
    required this.bodegas,
    required this.productos,
    required this.categorias,
    required this.impuestos,
    required this.onChanged,
    required this.onPickCategoria,
    required this.onPickBodega,
    required this.onPickImpuesto,
  });

  final List<_DocumentoPreviewItemDraft> items;
  final List<Bodega> bodegas;
  final List<Producto> productos;
  final List<Categoria> categorias;
  final List<Impuesto> impuestos;
  final VoidCallback onChanged;
  final Future<Categoria?> Function() onPickCategoria;
  final Future<Bodega?> Function() onPickBodega;
  final Future<Impuesto?> Function() onPickImpuesto;

  @override
  State<_PreviewItemsTable> createState() => _PreviewItemsTableState();
}

class _PreviewItemsTableState extends State<_PreviewItemsTable> {
  String _categoriaNombre(int? categoriaId) {
    final categoria = widget.categorias.firstWhere(
      (item) => item.id == categoriaId,
      orElse: () => Categoria(
        id: 0,
        nombre: '-',
        descripcion: '-',
      ),
    );
    return categoria.nombre;
  }

  String _impuestoNombre(int? impuestoId) {
    final impuesto = widget.impuestos.firstWhere(
      (item) => item.id == impuestoId,
      orElse: () => Impuesto(
        id: 0,
        codigo: '-',
        codigoPorcentaje: '-',
        descripcion: '-',
        tarifa: 0,
        activo: true,
      ),
    );
    return '${impuesto.descripcion} (${impuesto.tarifa.toStringAsFixed(2)}%)';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return const Text('Sin items en el documento.');
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Codigo')),
          DataColumn(label: Text('Codigo barras')),
          DataColumn(label: Text('Descripcion')),
          DataColumn(label: Text('Cantidad')),
          DataColumn(label: Text('Costo')),
          DataColumn(label: Text('PVP')),
          DataColumn(label: Text('Subtotal')),
          DataColumn(label: Text('Bodega')),
          DataColumn(label: Text('Producto')),
          DataColumn(label: Text('Categoria')),
          DataColumn(label: Text('Impuesto')),
        ],
        rows: widget.items.map((item) {
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
          return DataRow(
            cells: [
              DataCell(Text(item.codigoPrincipal)),
              DataCell(
                SizedBox(
                  width: 220,
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: item.codigoBarrasController,
                          decoration: const InputDecoration(
                            hintText: 'Opcional',
                          ),
                          onChanged: (value) {
                            setState(() => item.codigoBarras = value);
                            widget.onChanged();
                          },
                        ),
                      ),
                      const SizedBox(width: 6),
                      if (item.codigoPrincipal.trim().isNotEmpty)
                        IconButton(
                          tooltip: 'Copiar codigo',
                          icon: const Icon(Icons.content_copy, size: 18),
                          onPressed: () {
                            final value = item.codigoPrincipal.trim();
                            item.codigoBarrasController?.text = value;
                            setState(() => item.codigoBarras = value);
                            widget.onChanged();
                            showAppToast(
                              context,
                              'Codigo copiado al campo de barras.',
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
              DataCell(Text(item.descripcion)),
              DataCell(Text('${item.cantidad}')),
              DataCell(Text(item.costoUnitario.toStringAsFixed(2))),
              DataCell(
                SizedBox(
                  width: 120,
                  child: TextFormField(
                    controller: item.precioVentaController,
                    decoration: const InputDecoration(
                      hintText: 'Precio',
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      setState(() {
                        item.precioVenta = double.tryParse(value) ?? 0;
                      });
                      widget.onChanged();
                    },
                  ),
                ),
              ),
              DataCell(Text(item.subtotal.toStringAsFixed(2))),
              DataCell(
                InkWell(
                  onTap: () async {
                    final bodega = await widget.onPickBodega();
                    if (bodega != null) {
                      setState(() => item.bodegaId = bodega.id);
                      widget.onChanged();
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .surface
                          .withAlpha(220),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(context)
                            .colorScheme
                            .outline
                            .withAlpha(120),
                      ),
                    ),
                    child: Text(
                      item.bodegaId == null
                          ? 'Seleccionar'
                          : widget.bodegas
                              .firstWhere(
                                (bodega) => bodega.id == item.bodegaId,
                                orElse: () => Bodega(
                                  id: 0,
                                  nombre: '-',
                                  descripcion: '-',
                                  direccion: '-',
                                  activa: true,
                                ),
                              )
                              .nombre,
                    ),
                  ),
                ),
              ),
              DataCell(
                DropdownButton<int>(
                  value: item.productoId,
                  hint: const Text('Nuevo'),
                  items: widget.productos
                      .where((producto) => producto.id != null)
                      .map(
                        (producto) => DropdownMenuItem(
                          value: producto.id!,
                          child: Text(
                            '${producto.codigo} - ${producto.descripcion}',
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      item.productoId = value;
                      if (value != null &&
                          (item.precioVenta <= 0 ||
                              (item.precioVentaController?.text ?? '')
                                  .trim()
                                  .isEmpty)) {
                        final producto = widget.productos.firstWhere(
                          (producto) => producto.id == value,
                          orElse: () => Producto(
                            id: 0,
                            codigo: '-',
                            descripcion: '-',
                            precioUnitario: 0,
                            categoriaId: 0,
                            impuestoId: 0,
                          ),
                        );
                        item.precioVenta = producto.precioUnitario;
                        item.precioVentaController?.text =
                            producto.precioUnitario.toStringAsFixed(2);
                      }
                    });
                    widget.onChanged();
                  },
                ),
              ),
              DataCell(
                item.productoId != null
                    ? Text(_categoriaNombre(producto.categoriaId))
                    : InkWell(
                        onTap: () async {
                          final categoria = await widget.onPickCategoria();
                          if (categoria != null) {
                            setState(() => item.categoriaId = categoria.id);
                            widget.onChanged();
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .surface
                                .withAlpha(220),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Theme.of(context)
                                  .colorScheme
                                  .outline
                                  .withAlpha(120),
                            ),
                          ),
                          child: Text(
                            item.categoriaId == null
                                ? 'Seleccionar'
                                : _categoriaNombre(item.categoriaId),
                          ),
                        ),
                      ),
              ),
              DataCell(
                item.productoId != null
                    ? Text(_impuestoNombre(producto.impuestoId))
                    : InkWell(
                        onTap: () async {
                          final impuesto = await widget.onPickImpuesto();
                          if (impuesto != null) {
                            setState(() => item.impuestoId = impuesto.id);
                            widget.onChanged();
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .surface
                                .withAlpha(220),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Theme.of(context)
                                  .colorScheme
                                  .outline
                                  .withAlpha(120),
                            ),
                          ),
                          child: Text(
                            item.impuestoId == null
                                ? 'Seleccionar'
                                : _impuestoNombre(item.impuestoId),
                          ),
                        ),
                      ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _PagoDetallesTable extends StatefulWidget {
  const _PagoDetallesTable({
    required this.detalles,
    required this.onPickDocumento,
    required this.onAdd,
    required this.onRemove,
    this.onChanged,
  });

  final List<_PagoDetalleDraft> detalles;
  final Future<CuentaPorPagar?> Function() onPickDocumento;
  final VoidCallback onAdd;
  final void Function(int index) onRemove;
  final VoidCallback? onChanged;

  @override
  State<_PagoDetallesTable> createState() => _PagoDetallesTableState();
}

class _PagoDetallesTableState extends State<_PagoDetallesTable> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Detalles', style: Theme.of(context).textTheme.titleSmall),
            const Spacer(),
            TextButton.icon(
              onPressed: widget.onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Agregar'),
            ),
          ],
        ),
        const SizedBox(height: defaultPadding / 2),
        Column(
          children: List.generate(widget.detalles.length, (index) {
            final detalle = widget.detalles[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: defaultPadding / 2),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: InkWell(
                      onTap: () async {
                        final cuenta = await widget.onPickDocumento();
                        if (cuenta == null) {
                          return;
                        }
                        setState(() {
                          detalle.documentoId =
                              cuenta.documentoProveedorId ?? cuenta.documentoId;
                          final numero =
                              cuenta.documentoNumero ?? cuenta.numeroDocumento;
                          final tipo =
                              cuenta.documentoTipo ?? cuenta.tipoDocumento;
                          detalle.documentoNumero =
                              tipo == null || tipo.trim().isEmpty
                                  ? numero
                                  : '$tipo ${numero ?? ''}'.trim();
                          detalle.cuentaPorPagarId = cuenta.id;
                          final saldo = cuenta.saldo ?? 0;
                          detalle.valor = saldo;
                          detalle.valorController?.text =
                              saldo.toStringAsFixed(2);
                        });
                        widget.onChanged?.call();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surface
                              .withAlpha(220),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Theme.of(context)
                                .colorScheme
                                .outline
                                .withAlpha(120),
                          ),
                        ),
                        child: Text(
                          detalle.documentoNumero ?? 'Seleccionar documento',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: defaultPadding / 2),
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: detalle.valorController,
                      decoration: const InputDecoration(labelText: 'Valor'),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        setState(() {
                          detalle.valor = double.tryParse(value) ?? 0;
                        });
                        widget.onChanged?.call();
                      },
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      widget.onRemove(index);
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

class _PagoTotalPanel extends StatelessWidget {
  const _PagoTotalPanel({required this.detalles});

  final List<_PagoDetalleDraft> detalles;

  @override
  Widget build(BuildContext context) {
    final total = detalles.fold<double>(
      0,
      (sum, detalle) => sum + detalle.valor,
    );
    return Container(
      padding: const EdgeInsets.all(defaultPadding),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withAlpha(204),
        borderRadius: const BorderRadius.all(Radius.circular(10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Total', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: defaultPadding / 2),
          _TotalRow(label: 'Monto', value: total, isEmphasis: true),
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

class _DocumentoItemDraft {
  _DocumentoItemDraft({
    this.productoId,
    required this.cantidad,
    required this.costoUnitario,
    double? precioVenta,
  }) : precioVenta = precioVenta ?? 0 {
    precioVentaController =
        TextEditingController(text: this.precioVenta.toStringAsFixed(2));
  }

  int? productoId;
  int cantidad;
  double costoUnitario;
  double precioVenta;
  TextEditingController? precioVentaController;
}

class _DocumentoPreviewItemDraft {
  _DocumentoPreviewItemDraft({
    this.bodegaId,
    this.productoId,
    this.categoriaId,
    this.impuestoId,
    required this.codigoPrincipal,
    this.codigoBarras,
    required this.descripcion,
    required this.precioVenta,
    required this.cantidad,
    required this.costoUnitario,
    required this.subtotal,
  });

  int? bodegaId;
  int? productoId;
  int? categoriaId;
  int? impuestoId;
  String codigoPrincipal;
  String? codigoBarras;
  TextEditingController? codigoBarrasController;
  String descripcion;
  double precioVenta;
  TextEditingController? precioVentaController;
  int cantidad;
  double costoUnitario;
  double subtotal;
}

class _PagoDetalleDraft {
  _PagoDetalleDraft({
    this.documentoId,
    this.documentoNumero,
    this.cuentaPorPagarId,
    required this.valor,
    this.valorController,
  });

  int? documentoId;
  String? documentoNumero;
  double valor;
  TextEditingController? valorController;
  int? cuentaPorPagarId;
}

String? _formatDateValue(DateTime? date) {
  if (date == null) {
    return null;
  }
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}

String _truncateText(String text, int maxChars) {
  final trimmed = text.trim();
  if (trimmed.length <= maxChars) {
    return trimmed;
  }
  if (maxChars <= 3) {
    return trimmed.substring(0, maxChars);
  }
  return '${trimmed.substring(0, maxChars - 3)}...';
}

Widget buildProveedorLabel(BuildContext context, Proveedor proveedor) {
  final isMobile = Responsive.isMobile(context);
  final maxChars = isMobile ? 18 : 28;
  final maxWidth = isMobile ? 200.0 : 280.0;
  final razon = _truncateText(proveedor.razonSocial, maxChars);
  final label = '${proveedor.identificacion} - $razon';
  return ConstrainedBox(
    constraints: BoxConstraints(maxWidth: maxWidth),
    child: Text(
      label,
      overflow: TextOverflow.ellipsis,
    ),
  );
}
