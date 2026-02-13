import 'dart:typed_data';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../domain/models/cliente.dart';
import '../domain/models/bodega.dart';
import '../domain/models/empresa.dart';
import '../domain/models/factura.dart';
import '../domain/models/impuesto.dart';
import '../domain/models/inventario_producto_disponible.dart';
import '../domain/models/preorden.dart';
import '../domain/models/producto.dart';
import '../resource/theme/dimens.dart';
import '../services/api_client.dart';
import '../services/bodegas_service.dart';
import '../services/clientes_service.dart';
import '../services/empresas_service.dart';
import '../services/facturas_service.dart';
import '../services/impuestos_service.dart';
import '../services/inventarios_service.dart';
import '../services/preordenes_service.dart';
import '../services/productos_service.dart';
import '../states/auth_provider.dart';
import '../states/bodegas_provider.dart';
import '../states/clientes_provider.dart';
import '../states/empresas_provider.dart';
import '../states/facturas_provider.dart';
import '../states/impuestos_provider.dart';
import '../states/inventarios_provider.dart';
import '../states/preordenes_provider.dart';
import '../states/productos_provider.dart';
import 'facturacion/factura_notifications.dart';
import '../ui/shared/feedback.dart';
import '../ui/shared/section_header.dart';
import '../utils/pdf_utils.dart';
import '../utils/responsive.dart';

enum FacturacionSection { facturar, seguimiento }

class FacturacionScreen extends StatefulWidget {
  const FacturacionScreen({super.key});

  @override
  State<FacturacionScreen> createState() => _FacturacionScreenState();
}

class _FacturacionScreenState extends State<FacturacionScreen> {
  final _dirEstablecimientoController = TextEditingController();
  final _codigoNumericoController = TextEditingController();
  final _observacionesController = TextEditingController();
  final _preordenIdController = TextEditingController();
  final _clienteEmailController = TextEditingController();
  final _clienteDireccionController = TextEditingController();
  final _facturaIdController = TextEditingController();

  FacturacionSection _section = FacturacionSection.facturar;
  int? _empresaId;
  int? _clienteId;
  int? _bodegaId;
  String _moneda = 'USD';
  DateTime? _fechaEmision;
  int? _empresaIdProceso;

  final List<_FacturaItemDraft> _items = [
    _FacturaItemDraft(cantidad: 1, descuento: 0),
  ];
  final List<_PagoDraft> _pagos = [
    _PagoDraft(formaPago: 'EFECTIVO', monto: 0),
  ];

  late final ApiClient _client;
  late final EmpresasProvider _empresasProvider;
  late final ClientesProvider _clientesProvider;
  late final ProductosProvider _productosProvider;
  late final ImpuestosProvider _impuestosProvider;
  late final FacturasProvider _facturasProvider;
  late final BodegasProvider _bodegasProvider;
  late final InventariosProvider _inventariosProvider;
  late final PreordenesProvider _preordenesProvider;
  bool _empresaPrefillDone = false;
  bool _bodegaPrefillDone = false;
  int _codigoNumericoSecuencia = 0;

  @override
  void initState() {
    super.initState();
    _client = ApiClient();
    _empresasProvider = EmpresasProvider(EmpresasService(_client));
    _clientesProvider = ClientesProvider(ClientesService(_client));
    _productosProvider = ProductosProvider(ProductosService(_client));
    _impuestosProvider = ImpuestosProvider(ImpuestosService(_client));
    _facturasProvider = FacturasProvider(FacturasService(_client));
    _bodegasProvider = BodegasProvider(BodegasService(_client));
    _inventariosProvider = InventariosProvider(InventariosService(_client));
    _preordenesProvider = PreordenesProvider(PreordenesService(_client));

    _empresasProvider.fetchEmpresas();
    _clientesProvider.fetchClientes();
    _productosProvider.fetchProductos();
    _impuestosProvider.fetchImpuestos();
    _bodegasProvider.fetchBodegas();
    _inventariosProvider.clearProductosDisponibles();
    _setNextCodigoNumerico();
  }

  @override
  void dispose() {
    _empresasProvider.dispose();
    _clientesProvider.dispose();
    _productosProvider.dispose();
    _impuestosProvider.dispose();
    _facturasProvider.dispose();
    _bodegasProvider.dispose();
    _inventariosProvider.dispose();
    _preordenesProvider.dispose();
    _dirEstablecimientoController.dispose();
    _codigoNumericoController.dispose();
    _observacionesController.dispose();
    _preordenIdController.dispose();
    _clienteEmailController.dispose();
    _clienteDireccionController.dispose();
    _facturaIdController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final authProvider = context.read<AuthProvider>();
    if (!_empresaPrefillDone && authProvider.empresaId != null) {
      _empresaId = authProvider.empresaId;
      _empresaIdProceso = authProvider.empresaId;
      _empresaPrefillDone = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _empresasProvider),
        ChangeNotifierProvider.value(value: _clientesProvider),
        ChangeNotifierProvider.value(value: _productosProvider),
        ChangeNotifierProvider.value(value: _impuestosProvider),
        ChangeNotifierProvider.value(value: _facturasProvider),
        ChangeNotifierProvider.value(value: _bodegasProvider),
        ChangeNotifierProvider.value(value: _inventariosProvider),
      ],
      child: Consumer5<EmpresasProvider, ClientesProvider, ProductosProvider,
          ImpuestosProvider, FacturasProvider>(
        builder: (context, empresasProvider, clientesProvider,
            productosProvider, impuestosProvider, facturasProvider, _) {
          final authProvider = context.watch<AuthProvider>();
          final bodegasProvider = context.watch<BodegasProvider>();
          final inventariosProvider = context.watch<InventariosProvider>();
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
          final impuestos = empresaId == null
              ? impuestosProvider.impuestos
              : impuestosProvider.impuestos
                  .where(
                    (impuesto) =>
                        impuesto.empresaId == null ||
                        impuesto.empresaId == empresaId,
                  )
                  .toList();
          final bodegas = empresaId == null
              ? bodegasProvider.bodegas
              : bodegasProvider.bodegas
                  .where(
                    (bodega) =>
                        bodega.empresaId == null || bodega.empresaId == empresaId,
                  )
                  .toList();
          final productosDisponibles =
              inventariosProvider.productosDisponibles;
          final disponiblesBodegaId =
              inventariosProvider.productosDisponiblesBodegaId;
          final isLoading = empresasProvider.isLoading ||
              clientesProvider.isLoading ||
              productosProvider.isLoading ||
              impuestosProvider.isLoading ||
              facturasProvider.isLoading ||
              bodegasProvider.isLoading ||
              inventariosProvider.isLoading;
          final errorMessage = empresasProvider.errorMessage ??
              clientesProvider.errorMessage ??
              productosProvider.errorMessage ??
              impuestosProvider.errorMessage ??
              facturasProvider.errorMessage ??
              bodegasProvider.errorMessage ??
              inventariosProvider.errorMessage;

          if (!_bodegaPrefillDone) {
            final firstBodegaId = bodegas
                .firstWhere(
                  (bodega) => bodega.id != null,
                  orElse: () => Bodega(
                    id: null,
                    nombre: '',
                    descripcion: '',
                    direccion: '',
                    activa: true,
                  ),
                )
                .id;
            if (firstBodegaId != null) {
              _bodegaPrefillDone = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) {
                  return;
                }
                setState(() {
                  _bodegaId = firstBodegaId;
                  for (final item in _items) {
                    item.bodegaId ??= firstBodegaId;
                  }
                });
                _inventariosProvider.fetchProductosDisponibles(firstBodegaId);
              });
            }
          }

          if (_empresaId != null &&
              _dirEstablecimientoController.text.isEmpty) {
            final empresa = empresas.firstWhere(
              (item) => item.id == _empresaId,
              orElse: () => Empresa(
                id: 0,
                ambiente: '',
                tipoEmision: '',
                razonSocial: '',
                nombreComercial: '',
                ruc: '',
                dirMatriz: '',
                estab: '',
                ptoEmi: '',
                secuencial: '',
              ),
            );
            if (empresa.dirMatriz.isNotEmpty) {
              _dirEstablecimientoController.text = empresa.dirMatriz;
            }
          }

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(defaultPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeader(
                    title: 'Facturacion',
                    subtitle: 'Emision y seguimiento de facturas.',
                    actions: [
                      SegmentedButton<FacturacionSection>(
                        segments: const [
                          ButtonSegment(
                            value: FacturacionSection.facturar,
                            label: Text('Facturar'),
                            icon: Icon(Icons.receipt_long),
                          ),
                          ButtonSegment(
                            value: FacturacionSection.seguimiento,
                            label: Text('Seguimiento'),
                            icon: Icon(Icons.pending_actions),
                          ),
                        ],
                        selected: {_section},
                        onSelectionChanged: (value) {
                          setState(() => _section = value.first);
                        },
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
                  if (_section == FacturacionSection.facturar)
                    _FacturarView(
                      empresas: empresas,
                      clientes: clientes,
                      productos: productos,
                      impuestos: impuestos,
                      bodegas: bodegas,
                      disponibles: productosDisponibles,
                      disponiblesBodegaId: disponiblesBodegaId,
                      canSelectEmpresa: authProvider.isAdmin,
                      empresaId: _empresaId,
                      clienteId: _clienteId,
                      bodegaId: _bodegaId,
                      moneda: _moneda,
                      fechaEmision: _fechaEmision,
                      dirEstablecimientoController: _dirEstablecimientoController,
                      codigoNumericoController: _codigoNumericoController,
                      observacionesController: _observacionesController,
                      preordenIdController: _preordenIdController,
                      clienteEmailController: _clienteEmailController,
                      clienteDireccionController: _clienteDireccionController,
                      items: _items,
                      pagos: _pagos,
                      onEmpresaChanged: (value) {
                        setState(() {
                          _empresaId = value;
                          _bodegaId = null;
                          _bodegaPrefillDone = false;
                          for (final item in _items) {
                            item.bodegaId = null;
                          }
                          final empresa = empresas.firstWhere(
                            (item) => item.id == value,
                            orElse: () => Empresa(
                              id: 0,
                              ambiente: '',
                              tipoEmision: '',
                              razonSocial: '',
                              nombreComercial: '',
                              ruc: '',
                              dirMatriz: '',
                              estab: '',
                              ptoEmi: '',
                              secuencial: '',
                            ),
                          );
                          _dirEstablecimientoController.text = empresa.dirMatriz;
                        });
                        _inventariosProvider.clearProductosDisponibles();
                      },
                      onBodegaChanged: (value) {
                        setState(() {
                          _bodegaId = value;
                          for (final item in _items) {
                            item.bodegaId = value;
                          }
                        });
                        if (value == null) {
                          _inventariosProvider.clearProductosDisponibles();
                        } else {
                          _inventariosProvider.fetchProductosDisponibles(value);
                        }
                      },
                      onClienteChanged: (value) {
                        setState(() {
                          _clienteId = value;
                          final cliente = clientes.firstWhere(
                            (item) => item.id == value,
                            orElse: () => Cliente(
                              id: 0,
                              tipoIdentificacion: '',
                              identificacion: '',
                              razonSocial: '',
                              email: '',
                              direccion: '',
                            ),
                          );
                          _clienteEmailController.text = cliente.email;
                          _clienteDireccionController.text = cliente.direccion;
                        });
                      },
                      onMonedaChanged: (value) {
                        setState(() => _moneda = value);
                      },
                      onFechaChanged: () => _pickFecha(context),
                      onItemsChanged: () => setState(() {}),
                      onPagosChanged: () => setState(() {}),
                      onSubmit: () => _submitFactura(context),
                    )
                  else
                    _SeguimientoView(
                      empresas: empresas,
                      canSelectEmpresa: authProvider.isAdmin,
                      empresaId: _empresaIdProceso,
                      facturas: facturasProvider.facturasSeguimiento,
                      totalItems: facturasProvider.totalItems,
                      onEmpresaChanged: (value) {
                        setState(() => _empresaIdProceso = value);
                      },
                      onFetch: (range, page, size) async {
                        if (_empresaIdProceso == null) {
                          return;
                        }
                        await facturasProvider.fetchSeguimiento(
                          _empresaIdProceso!,
                          fechaDesde: range?.start,
                          fechaHasta: range?.end,
                          page: page,
                          size: size,
                        );
                      },
                      onReenviar: () => _reenviarFacturas(context),
                      onReenviarFactura: (facturaId) =>
                          _reenviarFactura(context, facturaId),
                      onVerPdf: (facturaId) => _verFacturaPdf(
                        context,
                        facturaId,
                      ),
                      onDescargarPdf: (facturaId) => _descargarFacturaPdf(
                        context,
                        facturaId,
                      ),
                      onVerXml: (facturaId) => _verFacturaXml(
                        context,
                        facturaId,
                      ),
                      onDescargarXml: (facturaId) => _descargarFacturaXml(
                        context,
                        facturaId,
                      ),
                      onConsultarEstado: () => _showEstadoDialog(context),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _pickFecha(BuildContext context) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _fechaEmision ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 1),
    );
    if (date != null) {
      setState(() => _fechaEmision = date);
    }
  }

  Future<void> _submitFactura(BuildContext providerContext) async {
    if (_empresaId == null || _clienteId == null) {
      showAppToast(
        providerContext,
        'Selecciona empresa y cliente.',
        isError: true,
      );
      return;
    }
    if (_dirEstablecimientoController.text.trim().isEmpty ||
        _codigoNumericoController.text.trim().isEmpty) {
      showAppToast(
        providerContext,
        'Completa los datos de la factura.',
        isError: true,
      );
      return;
    }
    if (_items.any((item) => item.productoId == null || item.cantidad <= 0)) {
      showAppToast(
        providerContext,
        'Completa los items con producto y cantidad.',
        isError: true,
      );
      return;
    }
    final bodegas = _empresaId == null
        ? _bodegasProvider.bodegas
        : _bodegasProvider.bodegas
            .where(
              (bodega) =>
                  bodega.empresaId == null || bodega.empresaId == _empresaId,
            )
            .toList();
    if (bodegas.where((bodega) => bodega.id != null).isEmpty) {
      showAppToast(
        providerContext,
        'Registra bodegas para facturar.',
        isError: true,
      );
      return;
    }
    if (_items.any((item) => (item.bodegaId ?? _bodegaId) == null)) {
      showAppToast(
        providerContext,
        'Asigna bodega a todos los items.',
        isError: true,
      );
      return;
    }
    final requiredByKey = <String, double>{};
    for (final item in _items) {
      final productoId = item.productoId;
      final bodegaId = item.bodegaId ?? _bodegaId;
      if (productoId == null || bodegaId == null) {
        continue;
      }
      final key = '$productoId@$bodegaId';
      requiredByKey[key] = (requiredByKey[key] ?? 0) + item.cantidad;
    }
    for (final entry in requiredByKey.entries) {
      final parts = entry.key.split('@');
      final productoId = int.tryParse(parts.first);
      final bodegaId = int.tryParse(parts.last);
      if (productoId == null || bodegaId == null) {
        continue;
      }
      var disponible = _inventariosProvider.getDisponible(
        productoId,
        bodegaId,
      );
      disponible ??= await _inventariosProvider.fetchProductoDisponibleDetalle(
        bodegaId: bodegaId,
        productoId: productoId,
      );
      final stockDisponible = disponible?.stockDisponible ?? 0;
      if (stockDisponible < entry.value) {
        showAppToast(
          providerContext,
          'Stock insuficiente para uno o mas items.',
          isError: true,
        );
        return;
      }
    }
    if (_pagos.any((pago) => pago.monto <= 0)) {
      showAppToast(
        providerContext,
        'Completa los montos de pago.',
        isError: true,
      );
      return;
    }

    final cliente = _clientesProvider.clientes.firstWhere(
      (item) => item.id == _clienteId,
      orElse: () => Cliente(
        id: _clienteId,
        tipoIdentificacion: '',
        identificacion: '',
        razonSocial: '',
        email: '',
        direccion: '',
      ),
    );

    if (_clienteEmailController.text.trim() != cliente.email ||
        _clienteDireccionController.text.trim() != cliente.direccion) {
      final updated = Cliente(
        id: cliente.id,
        tipoIdentificacion: cliente.tipoIdentificacion,
        identificacion: cliente.identificacion,
        razonSocial: cliente.razonSocial,
        email: _clienteEmailController.text.trim(),
        direccion: _clienteDireccionController.text.trim(),
      );
      final ok = await _clientesProvider.updateCliente(updated);
      if (!ok) {
        showAppToast(
          providerContext,
          _clientesProvider.errorMessage ??
              'No se pudo actualizar el cliente.',
          isError: true,
        );
        return;
      }
    }

    final preordenId = int.tryParse(_preordenIdController.text.trim());

    final productos = _empresaId == null
        ? _productosProvider.productos
        : _productosProvider.productos
            .where(
              (producto) =>
                  producto.empresaId == null || producto.empresaId == _empresaId,
            )
            .toList();
    final impuestos = _empresaId == null
        ? _impuestosProvider.impuestos
        : _impuestosProvider.impuestos
            .where(
              (impuesto) =>
                  impuesto.empresaId == null || impuesto.empresaId == _empresaId,
            )
            .toList();
    final totals = _FacturacionTotals.fromData(_items, productos, impuestos);

    final payload = <String, dynamic>{
      'empresaId': _empresaId,
      'clienteId': _clienteId,
      if (preordenId != null) 'preordenId': preordenId,
      'dirEstablecimiento': _dirEstablecimientoController.text.trim(),
      'fechaEmision': _formatDate(_fechaEmision ?? DateTime.now()),
      'moneda': _moneda,
      'codigoNumerico': _codigoNumericoController.text.trim(),
      'items': _items
          .map(
            (item) => {
              'productoId': item.productoId,
              'bodegaId': item.bodegaId ?? _bodegaId,
              'cantidad': item.cantidad,
              'descuento': item.descuento,
            },
          )
          .toList(),
      'pagos': _buildPagosPayload(totals.total),
    };

    await _procesarFactura(providerContext, payload);
  }

  Future<void> _procesarFactura(
    BuildContext providerContext,
    Map<String, dynamic> payload,
  ) async {
    final provider = providerContext.read<FacturasProvider>();
    showFacturaProcessingDialog(
      context: providerContext,
      title: 'Procesando documento...',
      message:
          'Estamos generando la factura y validando datos. Por favor, no cierres la ventana.',
    );
    final factura = await provider.createFactura(payload);
    if (!providerContext.mounted) {
      return;
    }
    if (factura == null || factura.id == null) {
      Navigator.of(providerContext).pop();
      await _showFacturaErrorDialog(
        providerContext,
        provider.errorMessage ?? 'No se pudo generar la factura.',
        payload,
      );
      return;
    }

    final estado = _normalizeEstado(factura.estado);
    if (_isEnProceso(estado)) {
      final actual =
          await _facturasProvider.fetchEnProcesoFactura(factura.id!);
      if (!providerContext.mounted) {
        return;
      }
      Navigator.of(providerContext).pop();
      if (actual != null) {
        await _showFacturaEstadoDialog(providerContext, actual);
      } else {
        await showFacturaNoticeDialog(
          context: providerContext,
          variant: FacturaNoticeVariant.info,
          title: 'Documento en proceso',
          message:
              'La factura #${factura.id} sigue en validacion. Puedes revisarla en Seguimiento.',
        );
      }
    } else {
      Navigator.of(providerContext).pop();
      await _showFacturaEstadoDialog(providerContext, factura);
    }

    if (!providerContext.mounted) {
      return;
    }
    _resetFacturaForm();
  }

  Future<void> _guardarPreordenDesdeFactura(BuildContext providerContext) async {
    if (_empresaId == null || _clienteId == null) {
      showAppToast(
        providerContext,
        'Selecciona empresa y cliente.',
        isError: true,
      );
      return;
    }
    if (_items.any((item) => (item.bodegaId ?? _bodegaId) == null)) {
      showAppToast(
        providerContext,
        'Asigna bodega a todos los items.',
        isError: true,
      );
      return;
    }
    if (_items.any((item) => item.productoId == null || item.cantidad <= 0)) {
      showAppToast(
        providerContext,
        'Completa los items con producto y cantidad.',
        isError: true,
      );
      return;
    }
    final baseObs = _observacionesController.text.trim();
    final observaciones = baseObs.isEmpty
        ? 'Generado desde factura no autorizada'
        : '$baseObs\nGenerado desde factura no autorizada';
    final payload = Preorden(
      empresaId: _empresaId!,
      clienteId: _clienteId!,
      dirEstablecimiento: _dirEstablecimientoController.text.trim(),
      moneda: _moneda,
      observaciones: observaciones,
      reservaInventario: true,
      items: _items
          .where((item) => item.productoId != null)
          .map(
            (item) => PreordenItem(
              bodegaId: item.bodegaId ?? _bodegaId,
              productoId: item.productoId!,
              cantidad: item.cantidad.toDouble(),
              descuento: item.descuento,
            ),
          )
          .toList(),
    );
    showFacturaProcessingDialog(
      context: providerContext,
      title: 'Guardando preorden...',
      message: 'Estamos registrando la preorden. Por favor, espera.',
    );
    final ok = await _preordenesProvider.createPreorden(payload);
    if (!providerContext.mounted) {
      return;
    }
    Navigator.of(providerContext).pop();
    if (!ok) {
      showAppToast(
        providerContext,
        _preordenesProvider.errorMessage ??
            'No se pudo guardar la preorden.',
        isError: true,
      );
      return;
    }
    showAppToast(providerContext, 'Preorden guardada.');
  }

  void _resetFacturaForm() {
    _dirEstablecimientoController.clear();
    _setNextCodigoNumerico();
    _observacionesController.clear();
    _preordenIdController.clear();
    _clienteEmailController.clear();
    _clienteDireccionController.clear();
    setState(() {
      _empresaId = null;
      _clienteId = null;
      _bodegaId = null;
      _bodegaPrefillDone = false;
      _moneda = 'USD';
      _fechaEmision = null;
      _items
        ..clear()
        ..add(_FacturaItemDraft(cantidad: 1, descuento: 0));
      _pagos
        ..clear()
        ..add(_PagoDraft(formaPago: 'EFECTIVO', monto: 0));
    });
    _inventariosProvider.clearProductosDisponibles();
  }

  String _normalizeEstado(String? estado) {
    final value = estado?.trim().isNotEmpty == true ? estado! : 'EN_PROCESO';
    return value.toUpperCase().replaceAll(' ', '_');
  }

  String _estadoLabel(String estado) {
    switch (estado) {
      case 'EN_PROCESO':
        return 'En proceso';
      case 'AUTORIZADA':
      case 'AUTORIZADO':
        return 'Autorizada';
      case 'ERROR':
        return 'Error';
      case 'ENVIADA':
        return 'Enviada';
      case 'PAGADA':
        return 'Pagada';
      case 'PENDIENTE':
        return 'Pendiente';
      case 'CANCELADA':
        return 'Cancelada';
      case 'ANULADA':
        return 'Anulada';
      default:
        final label = estado.replaceAll('_', ' ').toLowerCase();
        return label.isEmpty
            ? estado
            : '${label[0].toUpperCase()}${label.substring(1)}';
    }
  }

  bool _isEnProceso(String? estado) {
    final normalized = _normalizeEstado(estado);
    return normalized.contains('PROCESO');
  }

  String _facturaNumero(Factura factura) {
    final numero = factura.numero?.trim();
    if (numero != null && numero.isNotEmpty) {
      return numero;
    }
    if (factura.id != null) {
      return factura.id.toString();
    }
    return '-';
  }

  Color _statusColor(ThemeData theme, String estado) {
    switch (estado.toUpperCase()) {
      case 'AUTORIZADA':
      case 'AUTORIZADO':
        return Colors.green;
      case 'NO_AUTORIZADA':
        return Colors.amber.shade700;
      case 'ENVIADA':
      case 'RECIBIDA':
      case 'RECIBIDO':
        return Colors.blue;
      case 'ERROR':
      case 'RECHAZADA':
      case 'RECHAZADO':
      case 'DEVUELTA':
      case 'DEVUELTO':
      case 'CANCELADA':
      case 'ANULADA':
        return theme.colorScheme.error;
      case 'EN_PROCESO':
      default:
        return Colors.orange;
    }
  }

  void _setNextCodigoNumerico() {
    _codigoNumericoController.text = _nextCodigoNumerico();
  }

  String _nextCodigoNumerico() {
    if (_codigoNumericoSecuencia == 0) {
      _codigoNumericoSecuencia =
          DateTime.now().millisecondsSinceEpoch % 100000000;
      if (_codigoNumericoSecuencia == 0) {
        _codigoNumericoSecuencia = Random().nextInt(99999999) + 1;
      }
    } else {
      _codigoNumericoSecuencia =
          (_codigoNumericoSecuencia + 1) % 100000000;
      if (_codigoNumericoSecuencia == 0) {
        _codigoNumericoSecuencia = 1;
      }
    }
    return _codigoNumericoSecuencia.toString().padLeft(8, '0');
  }

  Future<void> _showFacturaErrorDialog(
    BuildContext context,
    String errorMessage,
    Map<String, dynamic> payload,
  ) async {
    await showFacturaNoticeDialog(
      context: context,
      variant: FacturaNoticeVariant.error,
      title: 'No pudimos crear esta factura',
      message: 'Hubo un problema al generar el comprobante.',
      detail: errorMessage,
      actions: [
        FacturaNoticeAction(
          label: 'Reintentar',
          isPrimary: true,
          isDestructive: true,
          onPressed: () {
            Navigator.of(context).pop();
            if (!context.mounted) {
              return;
            }
            _procesarFactura(context, payload);
          },
        ),
        FacturaNoticeAction(
          label: 'Cancelar',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  Future<void> _showFacturaEstadoDialog(
    BuildContext context,
    Factura factura,
  ) async {
    final theme = Theme.of(context);
    final numero = _facturaNumero(factura);
    final estado = _normalizeEstado(factura.estado);
    String? statusLabel;
    Color? statusColor;

    final messageDetail = factura.mensaje?.trim();
    final sriConsulta = factura.sriEstadoConsulta?.trim();
    final sriAutorizacion = factura.sriEstadoAutorizacion?.trim();
    final sriMensaje = factura.sriMensaje?.trim();
    FacturaNoticeVariant variant = FacturaNoticeVariant.info;
    String title = 'Factura generada';
    String message = 'El comprobante #$numero fue registrado en el sistema.';
    String? detail = messageDetail;

    switch (estado) {
      case 'AUTORIZADA':
      case 'AUTORIZADO':
        variant = FacturaNoticeVariant.success;
        title = '¡Factura generada con exito!';
        message = 'El comprobante #$numero fue registrado en el sistema.';
        break;
      case 'ENVIADA':
      case 'RECIBIDA':
      case 'RECIBIDO':
        variant = FacturaNoticeVariant.info;
        title = 'Enviada al SRI';
        message =
            'El documento fue enviado exitosamente. Espera la validacion.';
        statusLabel = 'Estado: Recibido';
        statusColor = Colors.green;
        break;
      case 'ERROR':
      case 'RECHAZADA':
      case 'RECHAZADO':
      case 'DEVUELTA':
      case 'DEVUELTO':
      case 'CANCELADA':
      case 'ANULADA':
        variant = FacturaNoticeVariant.error;
        title = 'No pudimos autorizar la factura';
        message = 'El comprobante #$numero presento un inconveniente.';
        break;
      case 'NO_AUTORIZADA':
        variant = FacturaNoticeVariant.warning;
        title = 'Factura no autorizada';
        message = 'El comprobante #$numero no fue autorizado.';
        statusLabel = 'Estado: NO_AUTORIZADA';
        statusColor = Colors.amber.shade700;
        break;
      case 'EN_PROCESO':
        variant = FacturaNoticeVariant.info;
        title = 'Documento en proceso';
        message = 'La factura #$numero sigue en validacion.';
        break;
      default:
        break;
    }

    final actions = <FacturaNoticeAction>[];
    if (variant == FacturaNoticeVariant.success) {
      if (factura.id != null) {
        actions.add(
          FacturaNoticeAction(
            label: 'Ver PDF',
            isPrimary: true,
            icon: Icons.picture_as_pdf_outlined,
            onPressed: () {
              Navigator.of(context).pop();
              _verFacturaPdf(context, factura.id!);
            },
          ),
        );
      }
      actions.add(
        FacturaNoticeAction(
          label: 'Cerrar',
          onPressed: () => Navigator.of(context).pop(),
        ),
      );
    } else if (variant == FacturaNoticeVariant.error) {
      if (factura.id != null) {
        actions.add(
          FacturaNoticeAction(
            label: 'Reintentar',
            isPrimary: true,
            isDestructive: true,
            onPressed: () {
              Navigator.of(context).pop();
              _reenviarFactura(context, factura.id!);
            },
          ),
        );
      }
      actions.add(
        FacturaNoticeAction(
          label: 'Cancelar',
          onPressed: () => Navigator.of(context).pop(),
        ),
      );
    } else if (variant == FacturaNoticeVariant.warning &&
        estado == 'NO_AUTORIZADA') {
      final detailLines = <String>[
        'Estado: $estado',
        if (sriConsulta != null && sriConsulta.isNotEmpty)
          'Estado SRI: $sriConsulta',
        if (sriAutorizacion != null && sriAutorizacion.isNotEmpty)
          'Autorizacion SRI: $sriAutorizacion',
        if (sriMensaje != null && sriMensaje.isNotEmpty)
          'Mensaje SRI: $sriMensaje',
        if (messageDetail != null &&
            messageDetail.isNotEmpty &&
            messageDetail != sriMensaje)
          messageDetail,
      ];
      detail = detailLines.join('\n');
      actions.add(
        FacturaNoticeAction(
          label: 'Guardar como preorden',
          isPrimary: true,
          onPressed: () {
            Navigator.of(context).pop();
            _guardarPreordenDesdeFactura(context);
          },
        ),
      );
      actions.add(
        FacturaNoticeAction(
          label: 'Cerrar',
          onPressed: () => Navigator.of(context).pop(),
        ),
      );
    } else {
      actions.add(
        FacturaNoticeAction(
          label: 'Entendido',
          isPrimary: true,
          onPressed: () => Navigator.of(context).pop(),
        ),
      );
    }

    await showFacturaNoticeDialog(
      context: context,
      variant: variant,
      title: title,
      message: message,
      detail: detail,
      statusLabel: statusLabel,
      statusColor: statusColor,
      actions: actions,
    );
  }

  void _consultarEstado(BuildContext providerContext) {
    final numero = _facturaIdController.text.trim();
    if (numero.isEmpty) {
      showAppToast(
        providerContext,
        'Numero de factura no valido.',
        isError: true,
      );
      return;
    }
    providerContext.read<FacturasProvider>().fetchEstado(numero);
  }

  Future<void> _showEstadoDialog(BuildContext providerContext) async {
    final facturasProvider = providerContext.read<FacturasProvider>();
    await showDialog<void>(
      context: providerContext,
      builder: (context) {
        return ChangeNotifierProvider.value(
          value: facturasProvider,
          child: AlertDialog(
            title: const Text('Estado de factura'),
            content: Consumer<FacturasProvider>(
              builder: (context, provider, _) {
                final estadoFactura = provider.estadoFactura;
                return SizedBox(
                  width: 420,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _facturaIdController,
                              decoration: const InputDecoration(
                                labelText: 'Numero de factura',
                                hintText: 'Ej: 001-001-000000015 o 15',
                              ),
                              keyboardType: TextInputType.text,
                            ),
                          ),
                          const SizedBox(width: defaultPadding / 2),
                          FilledButton.icon(
                            onPressed: () => _consultarEstado(context),
                            icon: const Icon(Icons.search),
                            label: const Text('Consultar'),
                          ),
                        ],
                      ),
                      const SizedBox(height: defaultPadding),
                      if (estadoFactura != null)
                        Container(
                          padding: const EdgeInsets.all(defaultPadding),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .surface
                                .withAlpha(204),
                            borderRadius:
                                const BorderRadius.all(Radius.circular(10)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Estado: ${estadoFactura.estado ?? '-'}'),
                              if (estadoFactura.mensaje != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    'Detalle: ${estadoFactura.mensaje}',
                                  ),
                                ),
                              if (estadoFactura.claveAcceso != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    'Clave acceso: ${estadoFactura.claveAcceso}',
                                  ),
                                ),
                            ],
                          ),
                        )
                      else
                        const Text('Consulta el estado de una factura.'),
                    ],
                  ),
                );
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cerrar'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _reenviarFacturas(BuildContext providerContext) async {
    if (_empresaIdProceso == null) {
      showAppToast(providerContext, 'Selecciona una empresa.', isError: true);
      return;
    }
    final ok = await providerContext
        .read<FacturasProvider>()
        .reenviarEnProceso(_empresaIdProceso!);
    if (ok && providerContext.mounted) {
      showAppToast(providerContext, 'Reenvio en proceso.');
      if (_empresaIdProceso != null) {
        await providerContext
            .read<FacturasProvider>()
            .fetchSeguimiento(_empresaIdProceso!);
      }
    } else if (providerContext.mounted) {
      showAppToast(
        providerContext,
        _facturasProvider.errorMessage ?? 'No se pudo reenviar.',
        isError: true,
      );
    }
  }

  Future<void> _reenviarFactura(
    BuildContext providerContext,
    int facturaId,
  ) async {
    final ok = await providerContext
        .read<FacturasProvider>()
        .reenviarFactura(facturaId);
    if (ok && providerContext.mounted) {
      showAppToast(
        providerContext,
        'Factura #$facturaId reenviada.',
      );
      if (_empresaIdProceso != null) {
        await providerContext
            .read<FacturasProvider>()
            .fetchSeguimiento(_empresaIdProceso!);
      }
    } else if (providerContext.mounted) {
      showAppToast(
        providerContext,
        _facturasProvider.errorMessage ?? 'No se pudo reenviar la factura.',
        isError: true,
      );
    }
  }

  Future<void> _verFacturaPdf(
    BuildContext providerContext,
    int facturaId,
  ) async {
    final bytes =
        await providerContext.read<FacturasProvider>().fetchPdf(facturaId);
    if (bytes == null) {
      if (providerContext.mounted) {
        showAppToast(
          providerContext,
          _facturasProvider.errorMessage ?? 'No se pudo obtener el PDF.',
          isError: true,
        );
      }
      return;
    }
    try {
      await openPdfBytes(
        Uint8List.fromList(bytes),
        fileName: 'factura_$facturaId.pdf',
      );
      if (providerContext.mounted) {
        showAppToast(providerContext, 'PDF abierto.');
      }
    } catch (error) {
      if (providerContext.mounted) {
        showAppToast(
          providerContext,
          'No se pudo abrir el PDF.',
          isError: true,
        );
      }
    }
  }

  Future<void> _descargarFacturaPdf(
    BuildContext providerContext,
    int facturaId,
  ) async {
    final bytes =
        await providerContext.read<FacturasProvider>().fetchPdf(facturaId);
    if (bytes == null) {
      if (providerContext.mounted) {
        showAppToast(
          providerContext,
          _facturasProvider.errorMessage ?? 'No se pudo obtener el PDF.',
          isError: true,
        );
      }
      return;
    }
    try {
      final saved = await savePdfBytes(
        Uint8List.fromList(bytes),
        fileName: 'factura_$facturaId.pdf',
      );
      if (providerContext.mounted) {
        showAppToast(
          providerContext,
          saved ? 'PDF descargado.' : 'Descarga cancelada.',
          isError: !saved,
        );
      }
    } catch (error) {
      if (providerContext.mounted) {
        showAppToast(
          providerContext,
          'No se pudo descargar el PDF.',
          isError: true,
        );
      }
    }
  }

  Future<void> _verFacturaXml(
    BuildContext providerContext,
    int facturaId,
  ) async {
    final bytes =
        await providerContext.read<FacturasProvider>().fetchXml(facturaId);
    if (bytes == null) {
      if (providerContext.mounted) {
        showAppToast(
          providerContext,
          _facturasProvider.errorMessage ?? 'No se pudo obtener el XML.',
          isError: true,
        );
      }
      return;
    }
    try {
      await openXmlBytes(
        Uint8List.fromList(bytes),
        fileName: 'factura-$facturaId.xml',
      );
      if (providerContext.mounted) {
        showAppToast(providerContext, 'XML abierto.');
      }
    } catch (error) {
      if (providerContext.mounted) {
        showAppToast(
          providerContext,
          'No se pudo abrir el XML.',
          isError: true,
        );
      }
    }
  }

  Future<void> _descargarFacturaXml(
    BuildContext providerContext,
    int facturaId,
  ) async {
    final bytes =
        await providerContext.read<FacturasProvider>().fetchXml(facturaId);
    if (bytes == null) {
      if (providerContext.mounted) {
        showAppToast(
          providerContext,
          _facturasProvider.errorMessage ?? 'No se pudo obtener el XML.',
          isError: true,
        );
      }
      return;
    }
    try {
      final saved = await saveXmlBytes(
        Uint8List.fromList(bytes),
        fileName: 'factura-$facturaId.xml',
      );
      if (providerContext.mounted) {
        showAppToast(
          providerContext,
          saved ? 'XML descargado.' : 'Descarga cancelada.',
          isError: !saved,
        );
      }
    } catch (error) {
      if (providerContext.mounted) {
        showAppToast(
          providerContext,
          'No se pudo descargar el XML.',
          isError: true,
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  List<Map<String, dynamic>> _buildPagosPayload(double totalFactura) {
    var remaining = totalFactura;
    final payload = <Map<String, dynamic>>[];

    for (final pago in _pagos.where((p) => p.formaPago != 'EFECTIVO')) {
      if (remaining <= 0) {
        break;
      }
      final aplicado = pago.monto <= remaining ? pago.monto : remaining;
      if (aplicado > 0) {
        final rounded = _roundMoney(aplicado);
        payload.add({'formaPago': pago.formaPago, 'monto': rounded});
        remaining -= rounded;
      }
    }

    for (final pago in _pagos.where((p) => p.formaPago == 'EFECTIVO')) {
      if (remaining <= 0) {
        break;
      }
      final aplicado = pago.monto <= remaining ? pago.monto : remaining;
      if (aplicado > 0) {
        final rounded = _roundMoney(aplicado);
        payload.add({'formaPago': pago.formaPago, 'monto': rounded});
        remaining -= rounded;
      }
    }

    return payload;
  }

  double _roundMoney(double value) {
    return double.parse(value.toStringAsFixed(2));
  }
}

class _FacturarView extends StatelessWidget {
  const _FacturarView({
    required this.empresas,
    required this.clientes,
    required this.productos,
    required this.impuestos,
    required this.bodegas,
    required this.disponibles,
    required this.disponiblesBodegaId,
    required this.canSelectEmpresa,
    required this.empresaId,
    required this.clienteId,
    required this.bodegaId,
    required this.moneda,
    required this.fechaEmision,
    required this.dirEstablecimientoController,
    required this.codigoNumericoController,
    required this.observacionesController,
    required this.preordenIdController,
    required this.clienteEmailController,
    required this.clienteDireccionController,
    required this.items,
    required this.pagos,
    required this.onEmpresaChanged,
    required this.onBodegaChanged,
    required this.onClienteChanged,
    required this.onMonedaChanged,
    required this.onFechaChanged,
    required this.onItemsChanged,
    required this.onPagosChanged,
    required this.onSubmit,
  });

  final List<Empresa> empresas;
  final List<Cliente> clientes;
  final List<Producto> productos;
  final List<Impuesto> impuestos;
  final List<Bodega> bodegas;
  final List<InventarioProductoDisponible> disponibles;
  final int? disponiblesBodegaId;
  final bool canSelectEmpresa;
  final int? empresaId;
  final int? clienteId;
  final int? bodegaId;
  final String moneda;
  final DateTime? fechaEmision;
  final TextEditingController dirEstablecimientoController;
  final TextEditingController codigoNumericoController;
  final TextEditingController observacionesController;
  final TextEditingController preordenIdController;
  final TextEditingController clienteEmailController;
  final TextEditingController clienteDireccionController;
  final List<_FacturaItemDraft> items;
  final List<_PagoDraft> pagos;
  final ValueChanged<int?> onEmpresaChanged;
  final ValueChanged<int?> onBodegaChanged;
  final ValueChanged<int?> onClienteChanged;
  final ValueChanged<String> onMonedaChanged;
  final VoidCallback onFechaChanged;
  final VoidCallback onItemsChanged;
  final VoidCallback onPagosChanged;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final selectedCliente = clientes
        .firstWhere(
          (cliente) => cliente.id == clienteId,
          orElse: () => Cliente(
            id: 0,
            tipoIdentificacion: '- ',
            identificacion: '-',
            razonSocial: 'Selecciona cliente',
            email: '-',
            direccion: '-',
          ),
        );
    final totals = _FacturacionTotals.fromData(items, productos, impuestos);

    return Column(
      children: [
        Responsive(
          mobile: Column(
            children: [
              _FacturaDatosCard(
                empresas: empresas,
                clientes: clientes,
                empresaId: empresaId,
                clienteId: clienteId,
                selectedCliente: selectedCliente,
                canSelectEmpresa: canSelectEmpresa,
                bodegas: bodegas,
                bodegaId: bodegaId,
                moneda: moneda,
                fechaEmision: fechaEmision,
                dirEstablecimientoController: dirEstablecimientoController,
                codigoNumericoController: codigoNumericoController,
                observacionesController: observacionesController,
                preordenIdController: preordenIdController,
                clienteEmailController: clienteEmailController,
                clienteDireccionController: clienteDireccionController,
                onEmpresaChanged: onEmpresaChanged,
                onBodegaChanged: onBodegaChanged,
                onClienteChanged: onClienteChanged,
                onMonedaChanged: onMonedaChanged,
                onFechaChanged: onFechaChanged,
              ),
              const SizedBox(height: defaultPadding),
              _PagoResumenCard(
                totals: totals,
                pagos: pagos,
                onChanged: onPagosChanged,
              ),
            ],
          ),
          tablet: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: _FacturaDatosCard(
                  empresas: empresas,
                  clientes: clientes,
                  empresaId: empresaId,
                  clienteId: clienteId,
                  selectedCliente: selectedCliente,
                  canSelectEmpresa: canSelectEmpresa,
                  bodegas: bodegas,
                  bodegaId: bodegaId,
                  moneda: moneda,
                  fechaEmision: fechaEmision,
                  dirEstablecimientoController: dirEstablecimientoController,
                  codigoNumericoController: codigoNumericoController,
                  observacionesController: observacionesController,
                  preordenIdController: preordenIdController,
                  clienteEmailController: clienteEmailController,
                  clienteDireccionController: clienteDireccionController,
                  onEmpresaChanged: onEmpresaChanged,
                  onBodegaChanged: onBodegaChanged,
                  onClienteChanged: onClienteChanged,
                  onMonedaChanged: onMonedaChanged,
                  onFechaChanged: onFechaChanged,
                ),
              ),
              const SizedBox(width: defaultPadding),
              Expanded(
                flex: 2,
                child: _PagoResumenCard(
                  totals: totals,
                  pagos: pagos,
                  onChanged: onPagosChanged,
                ),
              ),
            ],
          ),
          desktop: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: _FacturaDatosCard(
                  empresas: empresas,
                  clientes: clientes,
                  empresaId: empresaId,
                  clienteId: clienteId,
                  selectedCliente: selectedCliente,
                  canSelectEmpresa: canSelectEmpresa,
                  bodegas: bodegas,
                  bodegaId: bodegaId,
                  moneda: moneda,
                  fechaEmision: fechaEmision,
                  dirEstablecimientoController: dirEstablecimientoController,
                  codigoNumericoController: codigoNumericoController,
                  observacionesController: observacionesController,
                  preordenIdController: preordenIdController,
                  clienteEmailController: clienteEmailController,
                  clienteDireccionController: clienteDireccionController,
                  onEmpresaChanged: onEmpresaChanged,
                  onBodegaChanged: onBodegaChanged,
                  onClienteChanged: onClienteChanged,
                  onMonedaChanged: onMonedaChanged,
                  onFechaChanged: onFechaChanged,
                ),
              ),
              const SizedBox(width: defaultPadding),
              Expanded(
                flex: 2,
                child: _PagoResumenCard(
                  totals: totals,
                  pagos: pagos,
                  onChanged: onPagosChanged,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: defaultPadding),
        _FacturaItemsCard(
          items: items,
          productos: productos,
          impuestos: impuestos,
          bodegas: bodegas,
          disponibles: disponibles,
          disponiblesBodegaId: disponiblesBodegaId,
          defaultBodegaId: bodegaId,
          onChanged: onItemsChanged,
        ),
        const SizedBox(height: defaultPadding),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: onSubmit,
            icon: const Icon(Icons.check_circle),
            label: const Text('Confirmar factura'),
          ),
        ),
      ],
    );
  }
}

class _FacturaDatosCard extends StatelessWidget {
  const _FacturaDatosCard({
    required this.empresas,
    required this.clientes,
    required this.empresaId,
    required this.clienteId,
    required this.selectedCliente,
    required this.canSelectEmpresa,
    required this.bodegas,
    required this.bodegaId,
    required this.moneda,
    required this.fechaEmision,
    required this.dirEstablecimientoController,
    required this.codigoNumericoController,
    required this.observacionesController,
    required this.preordenIdController,
    required this.clienteEmailController,
    required this.clienteDireccionController,
    required this.onEmpresaChanged,
    required this.onBodegaChanged,
    required this.onClienteChanged,
    required this.onMonedaChanged,
    required this.onFechaChanged,
  });

  final List<Empresa> empresas;
  final List<Cliente> clientes;
  final int? empresaId;
  final int? clienteId;
  final Cliente selectedCliente;
  final bool canSelectEmpresa;
  final List<Bodega> bodegas;
  final int? bodegaId;
  final String moneda;
  final DateTime? fechaEmision;
  final TextEditingController dirEstablecimientoController;
  final TextEditingController codigoNumericoController;
  final TextEditingController observacionesController;
  final TextEditingController preordenIdController;
  final TextEditingController clienteEmailController;
  final TextEditingController clienteDireccionController;
  final ValueChanged<int?> onEmpresaChanged;
  final ValueChanged<int?> onBodegaChanged;
  final ValueChanged<int?> onClienteChanged;
  final ValueChanged<String> onMonedaChanged;
  final VoidCallback onFechaChanged;

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
                  Text('Datos de factura',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: defaultPadding),
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
                    value: clienteId,
                    items: clientes
                        .map(
                          (cliente) => DropdownMenuItem(
                            value: cliente.id,
                            child: Text(cliente.razonSocial),
                          ),
                        )
                        .toList(),
                    onChanged: onClienteChanged,
                    decoration: const InputDecoration(labelText: 'Cliente'),
                  ),
                  const SizedBox(height: defaultPadding / 2),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          initialValue: selectedCliente.identificacion,
                          readOnly: true,
                          decoration: const InputDecoration(
                            labelText: 'Identificacion',
                          ),
                        ),
                      ),
                      const SizedBox(width: defaultPadding / 2),
                      Expanded(
                        child: TextFormField(
                          controller: clienteEmailController,
                          decoration: const InputDecoration(labelText: 'Email'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: defaultPadding / 2),
                  TextFormField(
                    controller: clienteDireccionController,
                    decoration: const InputDecoration(labelText: 'Direccion'),
                  ),
                  const SizedBox(height: defaultPadding / 2),
                  TextFormField(
                    controller: dirEstablecimientoController,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Direccion establecimiento',
                    ),
                  ),
                  const SizedBox(height: defaultPadding / 2),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: codigoNumericoController,
                          readOnly: true,
                          decoration:
                              const InputDecoration(labelText: 'Codigo numerico'),
                        ),
                      ),
                      const SizedBox(width: defaultPadding / 2),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: moneda,
                          items: const [
                            DropdownMenuItem(value: 'USD', child: Text('USD')),
                            DropdownMenuItem(value: 'EUR', child: Text('EUR')),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              onMonedaChanged(value);
                            }
                          },
                          decoration: const InputDecoration(labelText: 'Moneda'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: defaultPadding / 2),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onFechaChanged,
                          icon: const Icon(Icons.event),
                          label: Text(
                            fechaEmision == null
                                ? 'Fecha de emision'
                                : _formatDate(fechaEmision!),
                          ),
                        ),
                      ),
                      const SizedBox(width: defaultPadding / 2),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: selectedBodegaId,
                          items: availableBodegas
                              .map(
                                (bodega) => DropdownMenuItem(
                                  value: bodega.id,
                                  child: Text(bodega.nombre),
                                ),
                              )
                              .toList(),
                          onChanged: availableBodegas.isEmpty
                              ? null
                              : onBodegaChanged,
                          decoration:
                              const InputDecoration(labelText: 'Bodega'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: defaultPadding / 2),
                  TextFormField(
                    controller: preordenIdController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Preorden ID (opcional)',
                    ),
                  ),
                  const SizedBox(height: defaultPadding / 2),
                  TextFormField(
                    controller: observacionesController,
                    maxLines: 2,
                    decoration:
                        const InputDecoration(labelText: 'Observaciones'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}

class _PagoResumenCard extends StatelessWidget {
  const _PagoResumenCard({
    required this.totals,
    required this.pagos,
    required this.onChanged,
  });

  final _FacturacionTotals totals;
  final List<_PagoDraft> pagos;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final total = totals.total;
    final totalPagos = pagos.fold<double>(
      0,
      (sum, item) => sum + item.monto,
    );
    final cambio = totalPagos - total;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final cardWidth = maxWidth > 520 ? 520.0 : maxWidth;
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
                  Text('Detalle de venta',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: defaultPadding / 2),
                  _TotalLine(label: 'Subtotal', value: totals.subtotal),
                  _TotalLine(label: 'Descuento', value: totals.descuento),
                  _TotalLine(label: 'Impuestos', value: totals.impuestos),
                  const Divider(),
                  _TotalLine(
                    label: 'Total',
                    value: totals.total,
                    isEmphasis: true,
                  ),
                  const SizedBox(height: defaultPadding),
                  Row(
                    children: [
                      Text(
                        'Pagos',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () {
                          pagos.add(
                            _PagoDraft(formaPago: 'EFECTIVO', monto: 0),
                          );
                          onChanged();
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Agregar'),
                      ),
                    ],
                  ),
                  const SizedBox(height: defaultPadding / 2),
                  Column(
                    children: List.generate(pagos.length, (index) {
                      final pago = pagos[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: defaultPadding / 2),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: DropdownButtonFormField<String>(
                                value: pago.formaPago,
                                items: const [
                                  DropdownMenuItem(
                                    value: 'EFECTIVO',
                                    child: Text('Efectivo'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'TARJETA',
                                    child: Text('Tarjeta'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'TRANSFERENCIA',
                                    child: Text('Transferencia'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'OTRO',
                                    child: Text('Otro'),
                                  ),
                                ],
                                onChanged: (value) {
                                  if (value != null) {
                                    pago.formaPago = value;
                                    onChanged();
                                  }
                                },
                                decoration: const InputDecoration(
                                  labelText: 'Forma de pago',
                                ),
                              ),
                            ),
                            const SizedBox(width: defaultPadding / 2),
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                initialValue: pago.monto.toStringAsFixed(2),
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: pago.formaPago == 'EFECTIVO'
                                      ? 'Recibido'
                                      : 'Monto',
                                ),
                                onChanged: (value) {
                                  pago.monto = double.tryParse(value) ?? 0;
                                  onChanged();
                                },
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                if (pagos.length == 1) {
                                  return;
                                }
                                pagos.removeAt(index);
                                onChanged();
                              },
                              icon: const Icon(Icons.delete_outline),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: defaultPadding / 2),
                  _TotalLine(
                    label: 'Total pagos',
                    value: totalPagos,
                  ),
                  _TotalLine(
                    label: 'Cambio',
                    value: cambio > 0 ? cambio : 0,
                    valueColor: Colors.green,
                  ),
                  _TotalLine(
                    label: 'Saldo',
                    value: cambio < 0 ? cambio.abs() : 0,
                    valueColor: Colors.redAccent,
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

class _FacturaItemsCard extends StatefulWidget {
  const _FacturaItemsCard({
    required this.items,
    required this.productos,
    required this.impuestos,
    required this.bodegas,
    required this.disponibles,
    required this.disponiblesBodegaId,
    required this.defaultBodegaId,
    required this.onChanged,
  });

  final List<_FacturaItemDraft> items;
  final List<Producto> productos;
  final List<Impuesto> impuestos;
  final List<Bodega> bodegas;
  final List<InventarioProductoDisponible> disponibles;
  final int? disponiblesBodegaId;
  final int? defaultBodegaId;
  final VoidCallback onChanged;

  @override
  State<_FacturaItemsCard> createState() => _FacturaItemsCardState();
}

class _FacturaItemsCardState extends State<_FacturaItemsCard> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _codigoController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  final FocusNode _codigoFocus = FocusNode();
  final Map<String, InventarioProductoDisponible> _detalleDisponibles = {};
  final Set<String> _sinStockKeys = {};
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    _codigoController.dispose();
    _searchFocus.dispose();
    _codigoFocus.dispose();
    super.dispose();
  }

  void _addItemForProducto(Producto producto) {
    widget.items.add(
      _FacturaItemDraft(
        cantidad: 1,
        descuento: 0,
        productoId: producto.id,
        bodegaId: widget.defaultBodegaId,
      ),
    );
    widget.onChanged();
  }

  void _addItemForDisponible(InventarioProductoDisponible disponible) {
    final producto = Producto(
      id: disponible.productoId,
      codigo: disponible.codigo,
      codigoBarras: disponible.codigoBarras,
      descripcion: disponible.descripcion,
      precioUnitario: disponible.precioUnitario,
      categoriaId: disponible.categoriaId,
      impuestoId: disponible.impuestoId,
    );
    context.read<ProductosProvider>().upsertProductoLocal(producto);
    widget.items.add(
      _FacturaItemDraft(
        cantidad: 1,
        descuento: 0,
        productoId: disponible.productoId,
        bodegaId: disponible.bodegaId,
      ),
    );
    _cacheDisponible(disponible);
    widget.onChanged();
  }

  String _keyFor(int productoId, int bodegaId) => '$productoId@$bodegaId';

  void _cacheDisponible(InventarioProductoDisponible disponible) {
    final key = _keyFor(disponible.productoId, disponible.bodegaId);
    _detalleDisponibles[key] = disponible;
    _sinStockKeys.remove(key);
  }

  InventarioProductoDisponible? _lookupDisponible(
    int? productoId,
    int? bodegaId,
  ) {
    if (productoId == null || bodegaId == null) {
      return null;
    }
    final key = _keyFor(productoId, bodegaId);
    final cached = _detalleDisponibles[key];
    if (cached != null) {
      return cached;
    }
    for (final disponible in widget.disponibles) {
      if (disponible.productoId == productoId &&
          disponible.bodegaId == bodegaId) {
        return disponible;
      }
    }
    return null;
  }

  Future<void> _ensureDisponibleDetalle({
    required int productoId,
    required int bodegaId,
  }) async {
    final key = _keyFor(productoId, bodegaId);
    if (_detalleDisponibles.containsKey(key)) {
      return;
    }
    final inventariosProvider = context.read<InventariosProvider>();
    final disponible = await inventariosProvider.fetchProductoDisponibleDetalle(
      bodegaId: bodegaId,
      productoId: productoId,
    );
    if (!mounted) {
      return;
    }
    if (disponible == null) {
      _detalleDisponibles.remove(key);
      _sinStockKeys.add(key);
    } else {
      _cacheDisponible(disponible);
    }
    setState(() {});
  }

  void _handleCodigoSubmit(String value) async {
    final codigo = value.trim();
    if (codigo.isEmpty) {
      return;
    }
    final bodegaId = widget.defaultBodegaId;
    if (bodegaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona una bodega primero.')),
      );
      return;
    }
    final inventariosProvider = context.read<InventariosProvider>();
    final disponible = await inventariosProvider.fetchProductoDisponibleByCodigo(
      bodegaId: bodegaId,
      codigo: codigo,
    );
    if (!mounted) {
      return;
    }
    if (disponible == null) {
      final message = inventariosProvider.errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message != null && message.isNotEmpty
                ? message
                : 'Producto no encontrado.',
          ),
        ),
      );
    } else {
      _addItemForDisponible(disponible);
    }
    _codigoController.clear();
    _codigoFocus.requestFocus();
  }

  List<Producto> _filterProductos(List<Producto> productos, String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) {
      return productos;
    }
    return productos.where((producto) {
      final codigo = producto.codigo.toLowerCase();
      final barras = (producto.codigoBarras ?? '').toLowerCase();
      final descripcion = producto.descripcion.toLowerCase();
      return codigo.contains(normalized) ||
          barras.contains(normalized) ||
          descripcion.contains(normalized);
    }).toList();
  }

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
    final selected = widget.productos
        .cast<Producto?>()
        .firstWhere((producto) => producto?.id == selectedId, orElse: () => null);
    if (selected == null) {
      return productos;
    }
    return [selected, ...productos];
  }

  Iterable<InventarioProductoDisponible> _filterDisponibles(
    List<InventarioProductoDisponible> disponibles,
    String query,
  ) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) {
      return const Iterable<InventarioProductoDisponible>.empty();
    }
    return disponibles.where((item) {
      final codigo = item.codigo.toLowerCase();
      final barras = (item.codigoBarras ?? '').toLowerCase();
      final descripcion = item.descripcion.toLowerCase();
      return codigo.contains(normalized) ||
          barras.contains(normalized) ||
          descripcion.contains(normalized);
    });
  }

  String _formatStock(double value) {
    final rounded = double.parse(value.toStringAsFixed(2));
    if (rounded == rounded.roundToDouble()) {
      return rounded.toStringAsFixed(0);
    }
    return rounded.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.items;
    final productos = widget.productos;
    final impuestos = widget.impuestos;
    final theme = Theme.of(context);
    final availableBodegas =
        widget.bodegas.where((bodega) => bodega.id != null).toList();
    final loadedForDefault = widget.defaultBodegaId != null &&
        widget.disponiblesBodegaId == widget.defaultBodegaId;
    final filteredProductos = _filterProductos(productos, _searchQuery);
    final requiredByKey = <String, double>{};
    for (final item in items) {
      final productoId = item.productoId;
      final bodegaId = item.bodegaId ?? widget.defaultBodegaId;
      if (productoId == null || bodegaId == null) {
        continue;
      }
      final key = _keyFor(productoId, bodegaId);
      requiredByKey[key] = (requiredByKey[key] ?? 0) + item.cantidad;
    }
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
                      Text('Items',
                          style: Theme.of(context).textTheme.titleMedium),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () {
                          items.add(
                            _FacturaItemDraft(
                              cantidad: 1,
                              descuento: 0,
                              bodegaId: widget.defaultBodegaId,
                            ),
                          );
                          widget.onChanged();
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Agregar'),
                      ),
                    ],
                  ),
                  const SizedBox(height: defaultPadding / 2),
                  Wrap(
                    spacing: defaultPadding / 2,
                    runSpacing: defaultPadding / 2,
                    children: [
                      SizedBox(
                        width: 320,
                        child: RawAutocomplete<InventarioProductoDisponible>(
                          textEditingController: _searchController,
                          focusNode: _searchFocus,
                          displayStringForOption: (disponible) =>
                              '${disponible.codigo} - ${disponible.descripcion}',
                          optionsBuilder: (value) {
                            final query = value.text;
                            return _filterDisponibles(
                              widget.disponibles,
                              query,
                            ).take(8);
                          },
                          onSelected: (disponible) {
                            _addItemForDisponible(disponible);
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                          fieldViewBuilder:
                              (context, controller, focusNode, onSubmit) {
                            return TextField(
                              controller: controller,
                              focusNode: focusNode,
                              decoration: _itemDecoration(
                                context,
                                'Buscar producto',
                              ).copyWith(
                                prefixIcon: const Icon(Icons.search),
                              ),
                              textInputAction: TextInputAction.search,
                              onChanged: (value) {
                                setState(() {
                                  _searchQuery = value;
                                });
                              },
                              onSubmitted: (_) => onSubmit(),
                            );
                          },
                          optionsViewBuilder:
                              (context, onSelected, options) {
                            final theme = Theme.of(context);
                            return Align(
                              alignment: Alignment.topLeft,
                              child: SizedBox(
                                width: 320,
                                child: Material(
                                  elevation: 6,
                                  color: theme.colorScheme.surface,
                                  borderRadius:
                                      const BorderRadius.all(Radius.circular(10)),
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      maxHeight: 260,
                                    ),
                                    child: ListView.separated(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8,
                                      ),
                                      shrinkWrap: true,
                                      itemCount: options.length,
                                      separatorBuilder: (_, __) => Divider(
                                        height: 1,
                                        color: theme.dividerColor.withAlpha(90),
                                      ),
                                      itemBuilder: (context, index) {
                                        final disponible = options.elementAt(index);
                                        return InkWell(
                                          onTap: () => onSelected(disponible),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 10,
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '${disponible.codigo} - ${disponible.descripcion}',
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: theme
                                                      .textTheme.bodyMedium,
                                                ),
                                                Text(
                                                  'Disponible: ${_formatStock(disponible.stockDisponible)}',
                                                  style: theme
                                                      .textTheme.labelSmall
                                                      ?.copyWith(
                                                    color: theme
                                                        .colorScheme.onSurface
                                                        .withAlpha(150),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      SizedBox(
                        width: 260,
                        child: TextField(
                          controller: _codigoController,
                          focusNode: _codigoFocus,
                          textInputAction: TextInputAction.done,
                          decoration: _itemDecoration(
                            context,
                            'Codigo o barras',
                          ).copyWith(
                            prefixIcon: const Icon(Icons.qr_code_2),
                            suffixIcon: IconButton(
                              onPressed: () =>
                                  _handleCodigoSubmit(_codigoController.text),
                              icon: const Icon(Icons.add),
                              tooltip: 'Agregar',
                            ),
                          ),
                          onSubmitted: _handleCodigoSubmit,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: defaultPadding / 2),
                  Column(
                    children: List.generate(items.length, (index) {
                      final item = items[index];
                      final dropdownProductos =
                          _withSelectedProducto(filteredProductos, item.productoId);
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
                      final impuesto = impuestos.firstWhere(
                        (impuesto) => impuesto.id == producto.impuestoId,
                        orElse: () => Impuesto(
                          id: 0,
                          codigo: '-',
                          codigoPorcentaje: '-',
                          tarifa: 0,
                          descripcion: '-',
                          activo: true,
                        ),
                      );
                      final effectiveBodegaId =
                          item.bodegaId ?? widget.defaultBodegaId;
                      final dropdownBodegaId = availableBodegas.any(
                        (bodega) => bodega.id == effectiveBodegaId,
                      )
                          ? effectiveBodegaId
                          : null;
                      final bodegaMissing =
                          item.productoId != null && dropdownBodegaId == null;
                      final disponible = _lookupDisponible(
                        item.productoId,
                        dropdownBodegaId,
                      );
                      final key = (item.productoId != null &&
                              dropdownBodegaId != null)
                          ? _keyFor(item.productoId!, dropdownBodegaId!)
                          : null;
                      final requiredQty =
                          key == null ? 0 : (requiredByKey[key] ?? 0);
                      final remaining = disponible == null
                          ? null
                          : disponible.stockDisponible - requiredQty;
                      final missingInDefault = key != null &&
                          loadedForDefault &&
                          dropdownBodegaId == widget.defaultBodegaId &&
                          disponible == null;
                      final sinStock = (key != null &&
                              _sinStockKeys.contains(key)) ||
                          missingInDefault;
                      final stockInsuficiente = item.productoId != null &&
                          !bodegaMissing &&
                          (sinStock || (remaining != null && remaining < 0));
                      final stockLabel = bodegaMissing
                          ? 'Sin bodega'
                          : sinStock
                              ? 'Sin stock'
                              : remaining == null
                                  ? '-'
                                  : _formatStock(remaining);
                      final stockColor = (bodegaMissing || stockInsuficiente)
                          ? theme.colorScheme.error
                          : theme.colorScheme.onSurface.withAlpha(200);
                      final base = producto.precioUnitario * item.cantidad;
                      final ivaMonto =
                          (base - item.descuento) * (impuesto.tarifa / 100);
                      final totalLinea = (base - item.descuento) + ivaMonto;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: defaultPadding / 2),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            decoration: BoxDecoration(
                              color: (stockInsuficiente || bodegaMissing)
                                  ? theme.colorScheme.error.withAlpha(18)
                                  : Colors.transparent,
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(8)),
                            ),
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
                                              producto.descripcion,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (value) {
                                    item.productoId = value;
                                    widget.onChanged();
                                    final bodegaId =
                                        item.bodegaId ?? widget.defaultBodegaId;
                                    if (value != null && bodegaId != null) {
                                      _ensureDisponibleDetalle(
                                        productoId: value,
                                        bodegaId: bodegaId,
                                      );
                                    }
                                  },
                                  decoration: _itemDecoration(
                                    context,
                                    'Producto',
                                  ),
                                ),
                              ),
                              const SizedBox(width: defaultPadding / 2),
                              SizedBox(
                                width: 200,
                                child: DropdownButtonFormField<int>(
                                  value: dropdownBodegaId,
                                  items: availableBodegas
                                      .map(
                                        (bodega) => DropdownMenuItem(
                                          value: bodega.id,
                                          child: Text(bodega.nombre),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: availableBodegas.isEmpty
                                      ? null
                                      : (value) {
                                          item.bodegaId = value;
                                          widget.onChanged();
                                          final productoId = item.productoId;
                                          if (value != null &&
                                              productoId != null) {
                                            _ensureDisponibleDetalle(
                                              productoId: productoId,
                                              bodegaId: value,
                                            );
                                          }
                                        },
                                  decoration: _itemDecoration(
                                    context,
                                    'Bodega',
                                  ),
                                ),
                              ),
                              const SizedBox(width: defaultPadding / 2),
                              SizedBox(
                                width: 110,
                                child: TextFormField(
                                  initialValue: item.cantidad.toString(),
                                  decoration:
                                      _itemDecoration(context, 'Cantidad'),
                                  keyboardType: TextInputType.number,
                                  onChanged: (value) {
                                    item.cantidad = int.tryParse(value) ?? 0;
                                    widget.onChanged();
                                  },
                                ),
                              ),
                              const SizedBox(width: defaultPadding / 2),
                              SizedBox(
                                width: 110,
                                child: InputDecorator(
                                  decoration:
                                      _itemDecoration(context, 'Existencia'),
                                  child: Text(
                                    stockLabel,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: stockColor,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: defaultPadding / 2),
                              SizedBox(
                                width: 130,
                                child: TextFormField(
                                  initialValue:
                                      item.descuento.toStringAsFixed(2),
                                  decoration:
                                      _itemDecoration(context, 'Descuento'),
                                  keyboardType: TextInputType.number,
                                  onChanged: (value) {
                                    item.descuento =
                                        double.tryParse(value) ?? 0;
                                    widget.onChanged();
                                  },
                                ),
                              ),
                              const SizedBox(width: defaultPadding / 2),
                              SizedBox(
                                width: 130,
                                child: TextFormField(
                                  key: ValueKey(
                                    'precio-${item.productoId}-${producto.precioUnitario}',
                                  ),
                                  initialValue:
                                      producto.precioUnitario.toStringAsFixed(2),
                                  readOnly: true,
                                  decoration: _itemDecoration(context, 'Costo'),
                                ),
                              ),
                              const SizedBox(width: defaultPadding / 2),
                              SizedBox(
                                width: 130,
                                child: TextFormField(
                                  key: ValueKey(
                                    'iva-${item.productoId}-${item.cantidad}-${item.descuento}',
                                  ),
                                  initialValue: ivaMonto.toStringAsFixed(2),
                                  readOnly: true,
                                  decoration: _itemDecoration(context, 'IVA'),
                                ),
                              ),
                              const SizedBox(width: defaultPadding / 2),
                              SizedBox(
                                width: 140,
                                child: TextFormField(
                                  key: ValueKey(
                                    'total-${item.productoId}-${item.cantidad}-${item.descuento}',
                                  ),
                                  initialValue: totalLinea.toStringAsFixed(2),
                                  readOnly: true,
                                  decoration: _itemDecoration(context, 'Total'),
                                ),
                              ),
                              const SizedBox(width: defaultPadding / 2),
                              IconButton(
                                onPressed: () {
                                  if (items.length == 1) {
                                    return;
                                  }
                                  items.removeAt(index);
                                  widget.onChanged();
                                },
                                icon: const Icon(Icons.delete_outline),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                    }),
                  ),
                ],
              ),
            ),
          ),
        );
      },
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

class _SeguimientoView extends StatelessWidget {
  const _SeguimientoView({
    required this.empresas,
    required this.canSelectEmpresa,
    required this.empresaId,
    required this.facturas,
    required this.totalItems,
    required this.onEmpresaChanged,
    required this.onFetch,
    required this.onReenviar,
    required this.onReenviarFactura,
    required this.onVerPdf,
    required this.onDescargarPdf,
    required this.onVerXml,
    required this.onDescargarXml,
    required this.onConsultarEstado,
  });

  final List<Empresa> empresas;
  final bool canSelectEmpresa;
  final int? empresaId;
  final List<Factura> facturas;
  final int totalItems;
  final ValueChanged<int?> onEmpresaChanged;
  final Future<void> Function(DateTimeRange? range, int page, int size) onFetch;
  final VoidCallback onReenviar;
  final ValueChanged<int> onReenviarFactura;
  final ValueChanged<int> onVerPdf;
  final ValueChanged<int> onDescargarPdf;
  final ValueChanged<int> onVerXml;
  final ValueChanged<int> onDescargarXml;
  final VoidCallback onConsultarEstado;

  @override
  Widget build(BuildContext context) {
    return _FacturasSeguimiento(
      empresas: empresas,
      canSelectEmpresa: canSelectEmpresa,
      empresaId: empresaId,
      facturas: facturas,
      totalItems: totalItems,
      onEmpresaChanged: onEmpresaChanged,
      onFetch: onFetch,
      onReenviar: onReenviar,
      onReenviarFactura: onReenviarFactura,
      onVerPdf: onVerPdf,
      onDescargarPdf: onDescargarPdf,
      onVerXml: onVerXml,
      onDescargarXml: onDescargarXml,
      onConsultarEstado: onConsultarEstado,
    );
  }
}

class _FacturasSeguimiento extends StatefulWidget {
  const _FacturasSeguimiento({
    required this.empresas,
    required this.canSelectEmpresa,
    required this.empresaId,
    required this.facturas,
    required this.totalItems,
    required this.onEmpresaChanged,
    required this.onFetch,
    required this.onReenviar,
    required this.onReenviarFactura,
    required this.onVerPdf,
    required this.onDescargarPdf,
    required this.onVerXml,
    required this.onDescargarXml,
    required this.onConsultarEstado,
  });

  final List<Empresa> empresas;
  final bool canSelectEmpresa;
  final int? empresaId;
  final List<Factura> facturas;
  final int totalItems;
  final ValueChanged<int?> onEmpresaChanged;
  final Future<void> Function(DateTimeRange? range, int page, int size) onFetch;
  final VoidCallback onReenviar;
  final ValueChanged<int> onReenviarFactura;
  final ValueChanged<int> onVerPdf;
  final ValueChanged<int> onDescargarPdf;
  final ValueChanged<int> onVerXml;
  final ValueChanged<int> onDescargarXml;
  final VoidCallback onConsultarEstado;

  @override
  State<_FacturasSeguimiento> createState() => _FacturasSeguimientoState();
}

class _FacturasSeguimientoState extends State<_FacturasSeguimiento> {
  static const _todasKey = 'TODAS';
  String _estadoFiltro = _todasKey;
  DateTimeRange? _dateRange;
  int _page = 0;
  static const int _pageSize = 20;
  bool _autoFetchDone = false;

  @override
  void didUpdateWidget(covariant _FacturasSeguimiento oldWidget) {
    super.didUpdateWidget(oldWidget);
    final estados = _estadoOptions();
    if (!estados.contains(_estadoFiltro)) {
      _estadoFiltro = _todasKey;
    }
    if (widget.empresaId != null &&
        widget.empresaId != oldWidget.empresaId) {
      _page = 0;
      _request();
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_autoFetchDone && widget.empresaId != null) {
        _autoFetchDone = true;
        _request();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filteredFacturas = _filteredFacturas();
    final estados = _estadoOptions();
    final totalCount =
        widget.totalItems > 0 ? widget.totalItems : widget.facturas.length;
    final pagadasCount = _countEstados({'PAGADA', 'AUTORIZADA'});
    final pendientesCount =
        _countEstados({'PENDIENTE', 'EN_PROCESO', 'ENVIADA'});
    final canceladasCount = _countEstados({'CANCELADA', 'ANULADA'});
    final isDark = theme.brightness == Brightness.dark;
    final totalTint = const Color(0xFF2F5BEA);
    final pagadasTint = const Color(0xFFF57C00);
    final pendientesTint = const Color(0xFF2E7D32);
    final canceladasTint = const Color(0xFFD32F2F);
    Color statBg(Color tint) {
      if (!isDark) {
        return tint.withOpacity(0.12);
      }
      return Color.alphaBlend(
        tint.withOpacity(0.22),
        theme.colorScheme.surface,
      );
    }
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
                color: theme.colorScheme.surface,
                borderRadius: const BorderRadius.all(Radius.circular(10)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Gestion de facturas',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: defaultPadding),
                  Wrap(
                    spacing: defaultPadding / 2,
                    runSpacing: defaultPadding / 2,
                    children: [
                      _StatCard(
                        title: 'Total facturas',
                        value: totalCount.toString(),
                        color: statBg(totalTint),
                        valueColor: totalTint,
                      ),
                      _StatCard(
                        title: 'Pagadas',
                        value: pagadasCount.toString(),
                        color: statBg(pagadasTint),
                        valueColor: pagadasTint,
                      ),
                      _StatCard(
                        title: 'Pendientes',
                        value: pendientesCount.toString(),
                        color: statBg(pendientesTint),
                        valueColor: pendientesTint,
                      ),
                      _StatCard(
                        title: 'Canceladas',
                        value: canceladasCount.toString(),
                        color: statBg(canceladasTint),
                        valueColor: canceladasTint,
                      ),
                    ],
                  ),
                  const SizedBox(height: defaultPadding),
                  widget.canSelectEmpresa
                      ? DropdownButtonFormField<int>(
                          value: widget.empresaId,
                          items: widget.empresas
                              .map(
                                (empresa) => DropdownMenuItem(
                                  value: empresa.id,
                                  child: Text(empresa.razonSocial),
                                ),
                              )
                              .toList(),
                          onChanged: widget.onEmpresaChanged,
                          decoration:
                              const InputDecoration(labelText: 'Empresa'),
                        )
                      : TextFormField(
                          readOnly: true,
                          initialValue: widget.empresas
                              .firstWhere(
                                (empresa) => empresa.id == widget.empresaId,
                                orElse: () => widget.empresas.isNotEmpty
                                    ? widget.empresas.first
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
                  Wrap(
                    spacing: defaultPadding / 2,
                    runSpacing: defaultPadding / 2,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      FilledButton.icon(
                        onPressed: _request,
                        icon: const Icon(Icons.search),
                        label: const Text('Consultar'),
                      ),
                      OutlinedButton.icon(
                        onPressed: widget.onReenviar,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reenviar en proceso'),
                      ),
                      OutlinedButton.icon(
                        onPressed: widget.onConsultarEstado,
                        icon: const Icon(Icons.pending_actions),
                        label: const Text('Estado factura'),
                      ),
                      DropdownButton<String>(
                        value: _estadoFiltro,
                        items: estados
                            .map(
                              (estado) => DropdownMenuItem(
                                value: estado,
                                child: Text(_estadoLabel(estado)),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }
                          setState(() => _estadoFiltro = value);
                        },
                      ),
                      _DateRangeField(
                        label: 'Fecha',
                        value: _dateRangeLabel(),
                        onTap: () => _pickDateRange(context),
                      ),
                      if (_dateRange != null)
                        TextButton(
                          onPressed: () {
                            setState(() => _dateRange = null);
                            _page = 0;
                            _request();
                          },
                          child: const Text('Limpiar fecha'),
                        ),
                    ],
                  ),
                  const SizedBox(height: defaultPadding),
                  filteredFacturas.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(defaultPadding),
                          child: Center(
                            child: Text('Sin facturas para mostrar.'),
                          ),
                        )
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            final maxWidth = constraints.maxWidth;
                            final cardWidth = Responsive.isDesktop(context)
                                ? (maxWidth > 1120 ? 1120.0 : maxWidth)
                                : maxWidth;
                            final useMenuActions =
                                !Responsive.isDesktop(context);
                            final actionsWidth =
                                useMenuActions ? 200.0 : 360.0;
                            return Align(
                              alignment: Alignment.topCenter,
                              child: SizedBox(
                                width: cardWidth,
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: DataTable(
                                    columns: [
                                      const DataColumn(label: Text('Factura')),
                                      const DataColumn(label: Text('Cliente')),
                                      const DataColumn(label: Text('Fecha')),
                                      const DataColumn(label: Text('Monto')),
                                      const DataColumn(label: Text('Estado')),
                                      DataColumn(
                                        label: SizedBox(
                                          width: actionsWidth,
                                          child: const Text('Acciones'),
                                        ),
                                      ),
                                    ],
                                    rows: filteredFacturas.map((factura) {
                                      final facturaId = factura.id;
                                      final estado =
                                          _normalizeEstado(factura.estado);
                                      final statusColor =
                                          _statusColor(theme, estado);
                                      final canReenviar =
                                          facturaId != null &&
                                              _isEnProceso(estado);
                                      return DataRow(
                                        cells: [
                                          DataCell(
                                            Text(_facturaNumero(factura)),
                                          ),
                                          DataCell(
                                            Text(factura.cliente ?? '-'),
                                          ),
                                          DataCell(
                                            Text(
                                              _formatFecha(
                                                factura.fechaEmision,
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            Text(_formatMonto(factura.total)),
                                          ),
                                          DataCell(
                                            Chip(
                                              label: Text(_estadoLabel(estado)),
                                              backgroundColor:
                                                  statusColor.withAlpha(40),
                                              labelStyle: TextStyle(
                                                color: statusColor,
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            SizedBox(
                                              width: actionsWidth,
                                              child: useMenuActions
                                                  ? Align(
                                                      alignment:
                                                          Alignment.centerLeft,
                                                      child: PopupMenuButton<
                                                          _FacturaAction>(
                                                        icon: const Icon(
                                                          Icons.more_vert,
                                                        ),
                                                        onSelected: (action) {
                                                          switch (action) {
                                                            case _FacturaAction
                                                                .ver:
                                                              _showFacturaDetalle(
                                                                context,
                                                                factura,
                                                              );
                                                              break;
                                                            case _FacturaAction
                                                                .reenviar:
                                                              if (canReenviar) {
                                                                widget
                                                                    .onReenviarFactura(
                                                                  facturaId!,
                                                                );
                                                              }
                                                              break;
                                                            case _FacturaAction
                                                                .pdf:
                                                              if (facturaId !=
                                                                  null) {
                                                                widget
                                                                    .onDescargarPdf(
                                                                  facturaId,
                                                                );
                                                              }
                                                              break;
                                                            case _FacturaAction
                                                                .xml:
                                                              if (facturaId !=
                                                                  null) {
                                                                widget
                                                                    .onDescargarXml(
                                                                  facturaId,
                                                                );
                                                              }
                                                              break;
                                                          }
                                                        },
                                                        itemBuilder:
                                                            (context) => [
                                                          const PopupMenuItem(
                                                            value: _FacturaAction
                                                                .ver,
                                                            child: Text('Ver'),
                                                          ),
                                                          PopupMenuItem(
                                                            value: _FacturaAction
                                                                .reenviar,
                                                            enabled:
                                                                canReenviar,
                                                            child: const Text(
                                                              'Reenviar',
                                                            ),
                                                          ),
                                                          const PopupMenuItem(
                                                            value: _FacturaAction
                                                                .pdf,
                                                            child: Text('PDF'),
                                                          ),
                                                          const PopupMenuItem(
                                                            value: _FacturaAction
                                                                .xml,
                                                            child: Text('XML'),
                                                          ),
                                                        ],
                                                      ),
                                                    )
                                                  : Wrap(
                                                      spacing: 6,
                                                      runSpacing: 6,
                                                      children: [
                                                        OutlinedButton.icon(
                                                          onPressed: () =>
                                                              _showFacturaDetalle(
                                                            context,
                                                            factura,
                                                          ),
                                                          icon: const Icon(
                                                            Icons
                                                                .visibility_outlined,
                                                          ),
                                                          label: const Text(
                                                            'Ver',
                                                          ),
                                                        ),
                                                        OutlinedButton.icon(
                                                          onPressed: canReenviar
                                                              ? () => widget
                                                                  .onReenviarFactura(
                                                                facturaId!,
                                                              )
                                                              : null,
                                                          icon: const Icon(
                                                            Icons.refresh,
                                                          ),
                                                          label: const Text(
                                                            'Reenviar',
                                                          ),
                                                        ),
                                                        OutlinedButton.icon(
                                                          onPressed: facturaId ==
                                                                  null
                                                              ? null
                                                              : () => widget
                                                                  .onDescargarPdf(
                                                                facturaId,
                                                              ),
                                                          icon: const Icon(
                                                            Icons
                                                                .picture_as_pdf_outlined,
                                                          ),
                                                          label: const Text(
                                                            'PDF',
                                                          ),
                                                        ),
                                                        OutlinedButton.icon(
                                                          onPressed: facturaId ==
                                                                  null
                                                              ? null
                                                              : () => widget
                                                                  .onDescargarXml(
                                                                facturaId,
                                                              ),
                                                          icon: const Icon(
                                                            Icons.code_outlined,
                                                          ),
                                                          label: const Text(
                                                            'XML',
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                            ),
                                          ),
                                        ],
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  List<Factura> _filteredFacturas() {
    Iterable<Factura> data = widget.facturas;
    if (_estadoFiltro != _todasKey) {
      data = data.where(
        (factura) => _normalizeEstado(factura.estado) == _estadoFiltro,
      );
    }
    if (_dateRange != null) {
      data = data.where((factura) {
        final fecha = factura.fechaEmision;
        if (fecha == null) {
          return false;
        }
        final start = DateTime(
          _dateRange!.start.year,
          _dateRange!.start.month,
          _dateRange!.start.day,
        );
        final end = DateTime(
          _dateRange!.end.year,
          _dateRange!.end.month,
          _dateRange!.end.day,
          23,
          59,
          59,
        );
        return !fecha.isBefore(start) && !fecha.isAfter(end);
      });
    }
    return data.toList();
  }

  List<String> _estadoOptions() {
    final estados = widget.facturas
        .map((factura) => _normalizeEstado(factura.estado))
        .toSet()
        .toList()
      ..sort();
    return [_todasKey, ...estados];
  }

  String _normalizeEstado(String? estado) {
    final value = estado?.trim().isNotEmpty == true ? estado! : 'EN_PROCESO';
    return value.toUpperCase().replaceAll(' ', '_');
  }

  String _estadoLabel(String estado) {
    if (estado == _todasKey) {
      return 'Todas';
    }
    switch (estado) {
      case 'EN_PROCESO':
        return 'En proceso';
      case 'AUTORIZADA':
        return 'Autorizada';
      case 'ERROR':
        return 'Error';
      case 'ENVIADA':
        return 'Enviada';
      case 'PAGADA':
        return 'Pagada';
      case 'PENDIENTE':
        return 'Pendiente';
      case 'CANCELADA':
        return 'Cancelada';
      case 'ANULADA':
        return 'Anulada';
      default:
        final label = estado.replaceAll('_', ' ').toLowerCase();
        return label.isEmpty
            ? estado
            : '${label[0].toUpperCase()}${label.substring(1)}';
    }
  }

  bool _isEnProceso(String? estado) {
    final normalized = _normalizeEstado(estado);
    return normalized.contains('PROCESO');
  }

  int _countEstados(Set<String> estados) {
    return widget.facturas.where((factura) {
      final normalized = _normalizeEstado(factura.estado);
      return estados.contains(normalized);
    }).length;
  }

  String _facturaNumero(Factura factura) {
    final numero = factura.numero?.trim();
    if (numero != null && numero.isNotEmpty) {
      return numero;
    }
    if (factura.id != null) {
      return factura.id.toString();
    }
    return '-';
  }

  String _formatFecha(DateTime? date) {
    if (date == null) {
      return '-';
    }
    return DateFormat('dd/MM/yyyy', 'es_EC').format(date);
  }

  String _formatMonto(double? total) {
    if (total == null) {
      return '-';
    }
    return '\$${total.toStringAsFixed(2)}';
  }

  String _dateRangeLabel() {
    final range = _dateRange ?? _defaultRange();
    return '${_formatFecha(range.start)} - ${_formatFecha(range.end)}';
  }

  Future<void> _pickDateRange(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 1),
      initialDateRange: _dateRange,
      locale: const Locale('es', 'EC'),
    );
    if (picked != null) {
      setState(() => _dateRange = picked);
      _page = 0;
      _request();
    }
  }

  Future<void> _request() async {
    if (widget.empresaId == null) {
      return;
    }
    final range = _dateRange ?? _defaultRange();
    await widget.onFetch(range, _page, _pageSize);
  }

  DateTimeRange _defaultRange() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 0);
    return DateTimeRange(start: start, end: end);
  }

  Future<void> _showFacturaDetalle(
    BuildContext context,
    Factura factura,
  ) async {
    final numero = _facturaNumero(factura);
    final cliente = factura.cliente ?? 'Sin cliente';
    final estado = _normalizeEstado(factura.estado);
    final statusColor = _statusColor(Theme.of(context), estado);
    final facturaId = factura.id;
    final canReenviar = facturaId != null && _isEnProceso(estado);

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Factura $numero - $cliente'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DetailRow(label: 'Fecha', value: _formatFecha(factura.fechaEmision)),
                _DetailRow(label: 'Monto', value: _formatMonto(factura.total)),
                Row(
                  children: [
                    Text(
                      'Estado',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    const SizedBox(width: 8),
                    Chip(
                      label: Text(_estadoLabel(estado)),
                      backgroundColor: statusColor.withAlpha(40),
                      labelStyle: TextStyle(color: statusColor),
                    ),
                  ],
                ),
                if (factura.claveAcceso != null)
                  _DetailRow(
                    label: 'Clave acceso',
                    value: factura.claveAcceso!,
                  ),
                const SizedBox(height: defaultPadding),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      onPressed: facturaId == null
                          ? null
                          : () => widget.onVerPdf(facturaId),
                      icon: const Icon(Icons.picture_as_pdf_outlined),
                      label: const Text('Ver PDF'),
                    ),
                    OutlinedButton.icon(
                      onPressed: facturaId == null
                          ? null
                          : () => widget.onDescargarPdf(facturaId),
                      icon: const Icon(Icons.download),
                      label: const Text('Descargar PDF'),
                    ),
                    FilledButton.icon(
                      onPressed: facturaId == null
                          ? null
                          : () => widget.onVerXml(facturaId),
                      icon: const Icon(Icons.code_outlined),
                      label: const Text('Ver XML'),
                    ),
                    OutlinedButton.icon(
                      onPressed: facturaId == null
                          ? null
                          : () => widget.onDescargarXml(facturaId),
                      icon: const Icon(Icons.download),
                      label: const Text('Descargar XML'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            if (canReenviar)
              FilledButton(
                onPressed: () => widget.onReenviarFactura(facturaId!),
                child: const Text('Reenviar factura'),
              ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  Color _statusColor(ThemeData theme, String estado) {
    switch (estado.toUpperCase()) {
      case 'AUTORIZADA':
        return Colors.green;
      case 'NO_AUTORIZADA':
        return Colors.amber.shade700;
      case 'ENVIADA':
        return Colors.blue;
      case 'ERROR':
        return theme.colorScheme.error;
      case 'CANCELADA':
      case 'ANULADA':
        return Colors.red;
      case 'EN_PROCESO':
      default:
        return Colors.orange;
    }
  }
}

enum _FacturaAction { ver, reenviar, pdf, xml }

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.color,
    required this.valueColor,
  });

  final String title;
  final String value;
  final Color color;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 200,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.colorScheme.outline.withAlpha(40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.labelMedium),
          const SizedBox(height: 6),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: valueColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: Theme.of(context).textTheme.labelMedium,
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _DateRangeField extends StatelessWidget {
  const _DateRangeField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outline.withAlpha(120)),
          borderRadius: BorderRadius.circular(10),
          color: theme.colorScheme.surface,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.date_range, size: 18),
            const SizedBox(width: 6),
            Text(
              '$label: ',
              style: theme.textTheme.labelMedium,
            ),
            Text(value),
          ],
        ),
      ),
    );
  }
}

class _TotalLine extends StatelessWidget {
  const _TotalLine({
    required this.label,
    required this.value,
    this.isEmphasis = false,
    this.valueColor,
  });

  final String label;
  final double value;
  final bool isEmphasis;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: isEmphasis ? FontWeight.w600 : FontWeight.normal,
          color: valueColor,
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

class _FacturacionTotals {
  _FacturacionTotals(this.subtotal, this.descuento, this.impuestos, this.total);

  final double subtotal;
  final double descuento;
  final double impuestos;
  final double total;

  factory _FacturacionTotals.fromData(
    List<_FacturaItemDraft> items,
    List<Producto> productos,
    List<Impuesto> impuestos,
  ) {
    double subtotal = 0;
    double descuento = 0;
    double impuestoTotal = 0;

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
      final base = producto.precioUnitario * item.cantidad;
      subtotal += base;
      descuento += item.descuento;
      final impuesto = impuestos.firstWhere(
        (imp) => imp.id == producto.impuestoId,
        orElse: () => Impuesto(
          id: 0,
          codigo: '-',
          codigoPorcentaje: '-',
          tarifa: 0,
          descripcion: '-',
          activo: true,
        ),
      );
      impuestoTotal += (base - item.descuento) * (impuesto.tarifa / 100);
    }

    final total = subtotal - descuento + impuestoTotal;
    return _FacturacionTotals(subtotal, descuento, impuestoTotal, total);
  }
}

class _FacturaItemDraft {
  _FacturaItemDraft({
    required this.cantidad,
    required this.descuento,
    this.productoId,
    this.bodegaId,
  });

  int? productoId;
  int? bodegaId;
  int cantidad;
  double descuento;
}

class _PagoDraft {
  _PagoDraft({required this.formaPago, required this.monto});

  String formaPago;
  double monto;
}
