import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../domain/models/cliente.dart';
import '../domain/models/cobro_cliente.dart';
import '../domain/models/cuenta_por_cobrar.dart';
import '../domain/models/documento_cliente.dart';
import '../domain/models/cxc_aging_report.dart';
import '../resource/theme/dimens.dart';
import '../services/api_client.dart';
import '../services/clientes_service.dart';
import '../services/cobros_cliente_service.dart';
import '../services/cuentas_por_cobrar_service.dart';
import '../services/documentos_cliente_service.dart';
import '../services/cxc_reportes_service.dart';
import '../states/auth_provider.dart';
import '../states/clientes_provider.dart';
import '../states/cobros_cliente_provider.dart';
import '../states/cxc_aging_provider.dart';
import '../states/cxc_provider.dart';
import '../states/documentos_cliente_provider.dart';
import '../ui/facturacion/factura_notifications.dart';
import '../ui/shared/feedback.dart';
import '../ui/shared/section_header.dart';
import '../utils/responsive.dart';

class CxcScreen extends StatefulWidget {
  const CxcScreen({super.key});

  @override
  State<CxcScreen> createState() => _CxcScreenState();
}

class _CxcScreenState extends State<CxcScreen> {
  int _tabIndex = 0;
  int? _selectedClienteId;
  String _documentoQuery = '';

  late final ApiClient _client;
  late final ClientesProvider _clientesProvider;
  late final DocumentosClienteProvider _documentosProvider;
  late final CxcProvider _cxcProvider;
  late final CobrosClienteProvider _cobrosProvider;
  late final CxcAgingProvider _agingProvider;

  @override
  void initState() {
    super.initState();
    _client = ApiClient();
    _clientesProvider = ClientesProvider(ClientesService(_client));
    _documentosProvider =
        DocumentosClienteProvider(DocumentosClienteService(_client));
    _cxcProvider = CxcProvider(CuentasPorCobrarService(_client));
    _cobrosProvider = CobrosClienteProvider(CobrosClienteService(_client));
    _agingProvider = CxcAgingProvider(CxcReportesService(_client));

    _clientesProvider.fetchClientes();
    _documentosProvider.fetchDocumentos();
    _cxcProvider.fetchCuentas();
    _cobrosProvider.fetchCobros();
    _agingProvider.fetchReport();
  }

  @override
  void dispose() {
    _clientesProvider.dispose();
    _documentosProvider.dispose();
    _cxcProvider.dispose();
    _cobrosProvider.dispose();
    _agingProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _clientesProvider),
        ChangeNotifierProvider.value(value: _documentosProvider),
        ChangeNotifierProvider.value(value: _cxcProvider),
        ChangeNotifierProvider.value(value: _cobrosProvider),
        ChangeNotifierProvider.value(value: _agingProvider),
      ],
      child: Consumer5<ClientesProvider, DocumentosClienteProvider, CxcProvider,
          CobrosClienteProvider, CxcAgingProvider>(
        builder: (context, clientesProvider, documentosProvider, cxcProvider,
            cobrosProvider, agingProvider, _) {
          final authProvider = context.watch<AuthProvider>();
          final empresaId = authProvider.empresaId;
          var clientes = clientesProvider.clientes;
          if (empresaId != null) {
            clientes = clientes
                .where(
                  (cliente) =>
                      cliente.empresaId == null ||
                      cliente.empresaId == empresaId,
                )
                .toList();
          }

          var documentos = documentosProvider.documentos;
          if (_selectedClienteId != null) {
            documentos = documentos
                .where((doc) => doc.clienteId == _selectedClienteId)
                .toList();
          }
          documentos = _filterDocumentos(documentos);

          var cuentas = cxcProvider.cuentas;
          if (_selectedClienteId != null) {
            cuentas = cuentas
                .where((cuenta) => cuenta.clienteId == _selectedClienteId)
                .toList();
          }
          cuentas = _filterCuentas(cuentas);

          var cobros = cobrosProvider.cobros;
          if (_selectedClienteId != null) {
            cobros = cobros
                .where((cobro) => cobro.clienteId == _selectedClienteId)
                .toList();
          }

          final isMobile = Responsive.isMobile(context);
          final isLoading = _resolveLoading(
            documentosProvider: documentosProvider,
            cxcProvider: cxcProvider,
            cobrosProvider: cobrosProvider,
            agingProvider: agingProvider,
          );
          final errorMessage = _resolveErrorMessage(
            documentosProvider: documentosProvider,
            cxcProvider: cxcProvider,
            cobrosProvider: cobrosProvider,
            agingProvider: agingProvider,
          );
          final actions = _buildActions(
            context,
            isMobile: isMobile,
            clientes: clientes,
            cuentas: cuentas,
          );

          _syncClienteSeleccion(clientes);

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(defaultPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeader(
                    title: 'Cuentas por cobrar',
                    subtitle:
                        'Documentos, CxC, cobros y reporte de vencimientos.',
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
                    clientes: clientes,
                    documentos: documentos,
                    cuentas: cuentas,
                    cobros: cobros,
                    report: agingProvider.report,
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
      return 'Buscar documento por numero o autorizacion';
    }
    if (_tabIndex == 1) {
      return 'Buscar cuenta por numero de factura';
    }
    return null;
  }

  ValueChanged<String>? _resolveSearchHandler() {
    if (_tabIndex == 0 || _tabIndex == 1) {
      return (value) => setState(() => _documentoQuery = value.trim());
    }
    return null;
  }

  bool _resolveLoading({
    required DocumentosClienteProvider documentosProvider,
    required CxcProvider cxcProvider,
    required CobrosClienteProvider cobrosProvider,
    required CxcAgingProvider agingProvider,
  }) {
    switch (_tabIndex) {
      case 0:
        return documentosProvider.isLoading;
      case 1:
        return cxcProvider.isLoading;
      case 2:
        return cobrosProvider.isLoading;
      case 3:
        return agingProvider.isLoading;
      default:
        return false;
    }
  }

  String? _resolveErrorMessage({
    required DocumentosClienteProvider documentosProvider,
    required CxcProvider cxcProvider,
    required CobrosClienteProvider cobrosProvider,
    required CxcAgingProvider agingProvider,
  }) {
    switch (_tabIndex) {
      case 0:
        return documentosProvider.errorMessage;
      case 1:
        return cxcProvider.errorMessage;
      case 2:
        return cobrosProvider.errorMessage;
      case 3:
        return agingProvider.errorMessage;
      default:
        return null;
    }
  }

  void _syncClienteSeleccion(List<Cliente> clientes) {
    if (_selectedClienteId == null) {
      return;
    }
    final clienteIds =
        clientes.map((cliente) => cliente.id).whereType<int>().toSet();
    if (!clienteIds.contains(_selectedClienteId)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _onClienteFilterChanged(null);
        }
      });
    }
  }

  List<Widget> _buildActions(
    BuildContext context, {
    required bool isMobile,
    required List<Cliente> clientes,
    required List<CuentaPorCobrar> cuentas,
  }) {
    switch (_tabIndex) {
      case 0:
        return [
          IconButton(
            tooltip: 'Refrescar',
            onPressed: () => _documentosProvider.fetchDocumentos(
              clienteId: _selectedClienteId,
            ),
            icon: const Icon(Icons.refresh),
          ),
        ];
      case 1:
        return [
          IconButton(
            tooltip: 'Refrescar',
            onPressed: () => _cxcProvider.fetchCuentas(
              clienteId: _selectedClienteId,
            ),
            icon: const Icon(Icons.refresh),
          ),
        ];
      case 2:
        return [
          IconButton(
            tooltip: 'Refrescar',
            onPressed: () => _cobrosProvider.fetchCobros(
              clienteId: _selectedClienteId,
            ),
            icon: const Icon(Icons.refresh),
          ),
          if (isMobile)
            IconButton(
              tooltip: 'Registrar cobro',
              onPressed: () => _openCobroDialog(
                context,
                clientes: clientes,
                cuentas: cuentas,
              ),
              icon: const Icon(Icons.add),
            )
          else
            FilledButton.icon(
              onPressed: () => _openCobroDialog(
                context,
                clientes: clientes,
                cuentas: cuentas,
              ),
              icon: const Icon(Icons.add),
              label: const Text('Registrar cobro'),
            ),
        ];
      case 3:
        return [
          IconButton(
            tooltip: 'Refrescar',
            onPressed: () => _agingProvider.fetchReport(
              clienteId: _selectedClienteId,
            ),
            icon: const Icon(Icons.refresh),
          ),
        ];
      default:
        return const [];
    }
  }

  Widget _resolveTabBody(
    BuildContext context, {
    required List<Cliente> clientes,
    required List<DocumentoCliente> documentos,
    required List<CuentaPorCobrar> cuentas,
    required List<CobroCliente> cobros,
    required CxcAgingReport? report,
  }) {
    switch (_tabIndex) {
      case 0:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ClienteFilter(
              clientes: clientes,
              value: _selectedClienteId,
              onChanged: _onClienteFilterChanged,
            ),
            const SizedBox(height: defaultPadding),
            _DocumentosList(
              documentos: documentos,
              onAnular: (documento) =>
                  _confirmAnularDocumento(context, documento),
            ),
          ],
        );
      case 1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ClienteFilter(
              clientes: clientes,
              value: _selectedClienteId,
              onChanged: _onClienteFilterChanged,
            ),
            const SizedBox(height: defaultPadding),
            _CxcList(cuentas: cuentas),
          ],
        );
      case 2:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ClienteFilter(
              clientes: clientes,
              value: _selectedClienteId,
              onChanged: _onClienteFilterChanged,
            ),
            const SizedBox(height: defaultPadding),
            _CobrosList(cobros: cobros),
          ],
        );
      case 3:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ClienteFilter(
              clientes: clientes,
              value: _selectedClienteId,
              onChanged: _onClienteFilterChanged,
            ),
            const SizedBox(height: defaultPadding),
            _AgingPanel(report: report),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  List<DocumentoCliente> _filterDocumentos(
    List<DocumentoCliente> documentos,
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

  List<CuentaPorCobrar> _filterCuentas(List<CuentaPorCobrar> cuentas) {
    if (_documentoQuery.isEmpty) {
      return cuentas;
    }
    final lower = _documentoQuery.toLowerCase();
    return cuentas
        .where(
          (cuenta) =>
              (cuenta.documentoNumero ?? cuenta.numeroDocumento ?? '')
                  .toLowerCase()
                  .contains(lower),
        )
        .toList();
  }

  void _onClienteFilterChanged(int? clienteId) {
    setState(() => _selectedClienteId = clienteId);
    _documentosProvider.fetchDocumentos(clienteId: clienteId);
    _cxcProvider.fetchCuentas(clienteId: clienteId);
    _cobrosProvider.fetchCobros(clienteId: clienteId);
    _agingProvider.fetchReport(clienteId: clienteId);
  }

  Future<void> _confirmAnularDocumento(
    BuildContext providerContext,
    DocumentoCliente documento,
  ) async {
    final documentoId = documento.id;
    if (documentoId == null) {
      showAppToast(
        providerContext,
        'Documento sin ID.',
        isError: true,
      );
      return;
    }
    if ((documento.estado ?? '').toUpperCase() == 'ANULADA') {
      showAppToast(
        providerContext,
        'El documento ya esta anulado.',
        isError: true,
      );
      return;
    }

    final motivoController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: providerContext,
      builder: (context) {
        return AlertDialog(
          title: const Text('Anular documento'),
          content: TextFormField(
            controller: motivoController,
            decoration: const InputDecoration(
              labelText: 'Motivo',
            ),
            maxLines: 2,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Anular'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      motivoController.dispose();
      return;
    }

    showFacturaProcessingDialog(
      context: providerContext,
      title: 'Procesando anulacion...',
      message:
          'Estamos actualizando el documento. Por favor, no cierres la ventana.',
    );
    final provider = providerContext.read<DocumentosClienteProvider>();
    final ok = await provider.actualizarEstado(
      documentoId: documentoId,
      estado: 'ANULADA',
      motivo: motivoController.text.trim(),
      clienteId: _selectedClienteId,
    );
    if (providerContext.mounted) {
      Navigator.of(providerContext).pop();
    }
    motivoController.dispose();
    if (!ok) {
      showAppToast(
        providerContext,
        provider.errorMessage ?? 'No se pudo anular el documento.',
        isError: true,
      );
      return;
    }
    await providerContext
        .read<CxcProvider>()
        .fetchCuentas(clienteId: _selectedClienteId);
    await providerContext
        .read<CxcAgingProvider>()
        .fetchReport(clienteId: _selectedClienteId);
    showAppToast(providerContext, 'Documento anulado.');
  }

  Future<void> _openCobroDialog(
    BuildContext providerContext, {
    required List<Cliente> clientes,
    required List<CuentaPorCobrar> cuentas,
  }) async {
    if (clientes.isEmpty) {
      showAppToast(
        providerContext,
        'Registra clientes antes de crear cobros.',
        isError: true,
      );
      return;
    }
    int? clienteId = _selectedClienteId;
    if (clienteId == null) {
      clienteId = _resolveFirstClienteId(clientes);
    }
    DateTime fechaCobro = DateTime.now();
    final fechaController =
        TextEditingController(text: _formatDate(fechaCobro));
    final formaPagoController = TextEditingController();
    final referenciaController = TextEditingController();
    final observacionController = TextEditingController();
    final detalles = <_CobroDetalleDraft>[
      _CobroDetalleDraft(
        valor: 0,
        valorController: TextEditingController(text: '0.00'),
      ),
    ];

    await showDialog<void>(
      context: providerContext,
      builder: (context) {
        return AlertDialog(
          title: const Text('Registrar cobro cliente'),
          content: StatefulBuilder(
            builder: (context, setState) {
              final cxcProvider = providerContext.read<CxcProvider>();
              final cuentasBase =
                  cxcProvider.cuentas.isNotEmpty ? cxcProvider.cuentas : cuentas;
              final cuentasPendientes = cuentasBase
                  .where((cuenta) =>
                      (clienteId == null || cuenta.clienteId == clienteId) &&
                      (cuenta.saldo ?? 0) > 0 &&
                      (cuenta.estado ?? '').toUpperCase() != 'ANULADA')
                  .toList();

              Future<CuentaPorCobrar?> pickDocumento() async {
                final searchController = TextEditingController();
                CuentaPorCobrar? selected;
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
                                            cuenta.documentoNumero ??
                                                cuenta.numeroDocumento ??
                                                '-',
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
                        value: clienteId,
                        items: clientes
                            .where((cliente) => cliente.id != null)
                            .map(
                              (cliente) => DropdownMenuItem(
                                value: cliente.id!,
                                child: buildClienteLabel(context, cliente),
                              ),
                            )
                            .toList(),
                        onChanged: (value) async {
                          setState(() => clienteId = value);
                          if (value != null) {
                            await providerContext
                                .read<CxcProvider>()
                                .fetchCuentas(clienteId: value);
                            if (context.mounted) {
                              setState(() {});
                            }
                          }
                        },
                        decoration:
                            const InputDecoration(labelText: 'Cliente'),
                      ),
                      const SizedBox(height: defaultPadding / 2),
                      TextFormField(
                        controller: fechaController,
                        readOnly: true,
                        decoration:
                            const InputDecoration(labelText: 'Fecha cobro'),
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: fechaCobro,
                            firstDate: DateTime(fechaCobro.year - 1),
                            lastDate: DateTime(fechaCobro.year + 1),
                          );
                          if (date != null) {
                            setState(() {
                              fechaCobro = date;
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
                      _CobroDetallesTable(
                        detalles: detalles,
                        onPickDocumento: pickDocumento,
                        onAdd: () {
                          setState(
                            () => detalles.add(
                              _CobroDetalleDraft(
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
                      _CobroTotalPanel(detalles: detalles),
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
                if (clienteId == null) {
                  showAppToast(
                    providerContext,
                    'Selecciona cliente.',
                    isError: true,
                  );
                  return;
                }
                if (detalles.any(
                  (detalle) =>
                      detalle.cuentaPorCobrarId == null || detalle.valor <= 0,
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
                  title: 'Procesando cobro...',
                  message:
                      'Estamos registrando el cobro. Por favor, no cierres la ventana.',
                );
                final total = detalles.fold<double>(
                  0,
                  (sum, detalle) => sum + detalle.valor,
                );
                final cobro = CobroCliente(
                  clienteId: clienteId!,
                  fechaCobro: fechaCobro,
                  montoTotal: total,
                  formaPago: formaPagoController.text.trim(),
                  referencia: referenciaController.text.trim(),
                  observacion: observacionController.text.trim(),
                  detalles: detalles
                      .map(
                        (detalle) => CobroClienteDetalle(
                          cuentaPorCobrarId: detalle.cuentaPorCobrarId,
                          montoAplicado: detalle.valor,
                        ),
                      )
                      .toList(),
                );
                final provider =
                    providerContext.read<CobrosClienteProvider>();
                final ok = await provider.createCobro(cobro);
                if (providerContext.mounted) {
                  Navigator.of(providerContext).pop();
                }
                if (!ok) {
                  showAppToast(
                    providerContext,
                    provider.errorMessage ?? 'No se pudo registrar el cobro.',
                    isError: true,
                  );
                  return;
                }
                await providerContext
                    .read<CxcProvider>()
                    .fetchCuentas(clienteId: clienteId);
                await providerContext
                    .read<DocumentosClienteProvider>()
                    .fetchDocumentos(clienteId: clienteId);
                await providerContext
                    .read<CxcAgingProvider>()
                    .fetchReport(clienteId: clienteId);
                if (context.mounted) {
                  Navigator.of(context).pop();
                  showAppToast(providerContext, 'Cobro registrado.');
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

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  int? _resolveFirstClienteId(List<Cliente> clientes) {
    for (final cliente in clientes) {
      if (cliente.id != null) {
        return cliente.id;
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
    final labels = const ['Documentos', 'CxC', 'Cobros', 'Aging'];
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

class _ClienteFilter extends StatelessWidget {
  const _ClienteFilter({
    required this.clientes,
    required this.value,
    required this.onChanged,
  });

  final List<Cliente> clientes;
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
            child: Text('Todos los clientes'),
          ),
          ...clientes
              .where((cliente) => cliente.id != null)
              .map(
            (cliente) => DropdownMenuItem<int?>(
              value: cliente.id,
              child: buildClienteLabel(context, cliente),
            ),
          ),
        ],
        onChanged: onChanged,
        decoration: const InputDecoration(labelText: 'Cliente'),
      ),
    );
  }
}

class _DocumentosList extends StatelessWidget {
  const _DocumentosList({
    required this.documentos,
    required this.onAnular,
  });

  final List<DocumentoCliente> documentos;
  final void Function(DocumentoCliente documento) onAnular;

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
              (documento) {
                final isAnulada =
                    (documento.estado ?? '').toUpperCase() == 'ANULADA';
                return Card(
                  child: ListTile(
                    title: Text(
                      documento.numeroDocumento ?? '-',
                    ),
                    subtitle: Text(
                      '${documento.estado ?? '-'} | ${_formatDateValue(documento.fechaEmision) ?? 'Fecha sin definir'}',
                    ),
                    trailing: PopupMenuButton<String>(
                      enabled: !isAnulada,
                      onSelected: (value) {
                        if (value == 'anular') {
                          onAnular(documento);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'anular',
                          child: Text('Anular'),
                        ),
                      ],
                    ),
                  ),
                );
              },
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
                    DataColumn(label: Text('Numero')),
                    DataColumn(label: Text('Fecha')),
                    DataColumn(label: Text('Vencimiento')),
                    DataColumn(label: Text('Total')),
                    DataColumn(label: Text('Saldo')),
                    DataColumn(label: Text('Estado')),
                    DataColumn(label: Text('Dias para vencer')),
                    DataColumn(label: Text('Vencida')),
                    DataColumn(label: Text('Acciones')),
                  ],
                  rows: documentos
                      .map(
                        (documento) {
                          final isAnulada =
                              (documento.estado ?? '').toUpperCase() ==
                                  'ANULADA';
                          return DataRow(
                            cells: [
                              DataCell(Text(documento.numeroDocumento ?? '-')),
                              DataCell(
                                Text(
                                  _formatDateValue(documento.fechaEmision) ??
                                      '-',
                                ),
                              ),
                              DataCell(
                                Text(
                                  _formatDateValue(
                                        documento.fechaVencimiento,
                                      ) ??
                                      '-',
                                ),
                              ),
                              DataCell(
                                Text(
                                  (documento.total ?? 0).toStringAsFixed(2),
                                ),
                              ),
                              DataCell(
                                Text((documento.saldo ?? 0).toStringAsFixed(2)),
                              ),
                              DataCell(Text(documento.estado ?? '-')),
                              DataCell(
                                Text(
                                  documento.diasParaVencer?.toString() ?? '-',
                                ),
                              ),
                              DataCell(
                                Text(documento.vencida == null
                                    ? '-'
                                    : documento.vencida!
                                        ? 'Si'
                                        : 'No'),
                              ),
                              DataCell(
                                IconButton(
                                  tooltip: 'Anular',
                                  onPressed:
                                      isAnulada ? null : () => onAnular(documento),
                                  icon: const Icon(Icons.block_outlined),
                                ),
                              ),
                            ],
                          );
                        },
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

class _CxcList extends StatelessWidget {
  const _CxcList({required this.cuentas});

  final List<CuentaPorCobrar> cuentas;

  @override
  Widget build(BuildContext context) {
    if (cuentas.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(defaultPadding),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.all(Radius.circular(10)),
        ),
        child: const Text('Sin cuentas por cobrar.'),
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
                    '${cuenta.estado ?? '-'} | ${_formatDateValue(cuenta.fechaEmision) ?? 'Fecha sin definir'}',
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
                    DataColumn(label: Text('Fecha')),
                    DataColumn(label: Text('Vencimiento')),
                    DataColumn(label: Text('Credito')),
                    DataColumn(label: Text('Saldo')),
                    DataColumn(label: Text('Estado')),
                    DataColumn(label: Text('Bucket credito')),
                    DataColumn(label: Text('Bucket vencimiento')),
                    DataColumn(label: Text('Dias para vencer')),
                    DataColumn(label: Text('Vencida')),
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
                              Text(cuenta.creditoDias?.toString() ?? '-'),
                            ),
                            DataCell(
                              Text((cuenta.saldo ?? 0).toStringAsFixed(2)),
                            ),
                            DataCell(Text(cuenta.estado ?? '-')),
                            DataCell(Text(cuenta.creditoBucket ?? '-')),
                            DataCell(Text(cuenta.bucketVencimiento ?? '-')),
                            DataCell(
                              Text(cuenta.diasParaVencer?.toString() ?? '-'),
                            ),
                            DataCell(
                              Text(cuenta.vencida == null
                                  ? '-'
                                  : cuenta.vencida!
                                      ? 'Si'
                                      : 'No'),
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

class _CobrosList extends StatelessWidget {
  const _CobrosList({required this.cobros});

  final List<CobroCliente> cobros;

  @override
  Widget build(BuildContext context) {
    if (cobros.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(defaultPadding),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.all(Radius.circular(10)),
        ),
        child: const Text('Sin cobros registrados.'),
      );
    }

    if (Responsive.isMobile(context)) {
      return Column(
        children: cobros
            .map(
              (cobro) => Card(
                child: ListTile(
                  title: Text(
                    'Cobro ${(cobro.montoTotal).toStringAsFixed(2)}',
                  ),
                  subtitle: Text(
                    _formatDateValue(cobro.fechaCobro) ?? 'Cobro sin fecha',
                  ),
                  trailing: Text(cobro.formaPago ?? '-'),
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
                    DataColumn(label: Text('Observacion')),
                  ],
                  rows: cobros
                      .map(
                        (cobro) => DataRow(
                          cells: [
                            DataCell(
                              Text(
                                _formatDateValue(cobro.fechaCobro) ?? '-',
                              ),
                            ),
                            DataCell(
                              Text(cobro.montoTotal.toStringAsFixed(2)),
                            ),
                            DataCell(Text(cobro.formaPago ?? '-')),
                            DataCell(Text(cobro.referencia ?? '-')),
                            DataCell(Text(cobro.observacion ?? '-')),
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

class _AgingPanel extends StatelessWidget {
  const _AgingPanel({required this.report});

  final CxcAgingReport? report;

  @override
  Widget build(BuildContext context) {
    if (report == null) {
      return Container(
        padding: const EdgeInsets.all(defaultPadding),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.all(Radius.circular(10)),
        ),
        child: const Text('Sin datos para mostrar.'),
      );
    }

    final items = [
      _AgingItem(label: 'Vencidas', value: report!.vencidas),
      _AgingItem(label: 'Por vencer 7', value: report!.porVencer7),
      _AgingItem(label: 'Por vencer 15', value: report!.porVencer15),
      _AgingItem(label: 'Por vencer 30', value: report!.porVencer30),
      _AgingItem(label: 'Futuras', value: report!.futuras),
      _AgingItem(label: 'Total', value: report!.total, emphasize: true),
    ];

    return Container(
      padding: const EdgeInsets.all(defaultPadding),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.all(Radius.circular(10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Resumen aging', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: defaultPadding / 2),
          Wrap(
            spacing: defaultPadding,
            runSpacing: defaultPadding / 2,
            children: items
                .map(
                  (item) => _AgingCard(item: item),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _AgingItem {
  const _AgingItem({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final double value;
  final bool emphasize;
}

class _AgingCard extends StatelessWidget {
  const _AgingCard({required this.item});

  final _AgingItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.titleSmall?.copyWith(
      fontWeight: item.emphasize ? FontWeight.w700 : FontWeight.w600,
    );
    return Container(
      width: 180,
      padding: const EdgeInsets.all(defaultPadding),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withAlpha(240),
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        border: Border.all(
          color: theme.colorScheme.outline.withAlpha(90),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.label, style: theme.textTheme.bodySmall),
          const SizedBox(height: 8),
          Text(item.value.toStringAsFixed(2), style: style),
        ],
      ),
    );
  }
}

class _CobroDetallesTable extends StatefulWidget {
  const _CobroDetallesTable({
    required this.detalles,
    required this.onPickDocumento,
    required this.onAdd,
    required this.onRemove,
    this.onChanged,
  });

  final List<_CobroDetalleDraft> detalles;
  final Future<CuentaPorCobrar?> Function() onPickDocumento;
  final VoidCallback onAdd;
  final void Function(int index) onRemove;
  final VoidCallback? onChanged;

  @override
  State<_CobroDetallesTable> createState() => _CobroDetallesTableState();
}

class _CobroDetallesTableState extends State<_CobroDetallesTable> {
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
                              cuenta.documentoClienteId ?? cuenta.documentoId;
                          detalle.documentoNumero = cuenta.documentoNumero ??
                              cuenta.numeroDocumento ??
                              '-';
                          detalle.cuentaPorCobrarId = cuenta.id;
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

class _CobroTotalPanel extends StatelessWidget {
  const _CobroTotalPanel({required this.detalles});

  final List<_CobroDetalleDraft> detalles;

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

class _CobroDetalleDraft {
  _CobroDetalleDraft({
    this.documentoId,
    this.documentoNumero,
    this.cuentaPorCobrarId,
    required this.valor,
    this.valorController,
  });

  int? documentoId;
  String? documentoNumero;
  double valor;
  TextEditingController? valorController;
  int? cuentaPorCobrarId;
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

Widget buildClienteLabel(BuildContext context, Cliente cliente) {
  final isMobile = Responsive.isMobile(context);
  final maxChars = isMobile ? 18 : 28;
  final maxWidth = isMobile ? 200.0 : 280.0;
  final razon = _truncateText(cliente.razonSocial, maxChars);
  final label = '${cliente.identificacion} - $razon';
  return ConstrainedBox(
    constraints: BoxConstraints(maxWidth: maxWidth),
    child: Text(
      label,
      overflow: TextOverflow.ellipsis,
    ),
  );
}
