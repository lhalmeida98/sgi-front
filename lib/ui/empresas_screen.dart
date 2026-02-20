import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../domain/models/empresa.dart';
import '../domain/models/usuario_empresa.dart';
import '../resource/theme/dimens.dart';
import '../services/api_client.dart';
import '../services/empresas_service.dart';
import '../services/usuarios_service.dart';
import '../states/auth_provider.dart';
import '../states/empresas_provider.dart';
import '../ui/shared/feedback.dart';
import '../ui/shared/section_header.dart';
import '../utils/responsive.dart';

class EmpresasScreen extends StatefulWidget {
  const EmpresasScreen({super.key});

  @override
  State<EmpresasScreen> createState() => _EmpresasScreenState();
}

class _EmpresasScreenState extends State<EmpresasScreen> {
  late final EmpresasProvider _provider;
  List<UsuarioEmpresa> _usuarioEmpresas = [];
  bool _isLoadingUsuarioEmpresas = false;
  String? _usuarioEmpresasError;

  @override
  void initState() {
    super.initState();
    _provider = EmpresasProvider(EmpresasService(ApiClient()));
    _provider.fetchEmpresas();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchUsuarioEmpresas();
    });
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
      child: Consumer<EmpresasProvider>(
        builder: (context, provider, _) {
          final authProvider = context.watch<AuthProvider>();
          final isMobile = Responsive.isMobile(context);
          final userEmpresas = _usuarioEmpresas
              .map((item) => item.empresa)
              .whereType<Empresa>()
              .toList();
          final empresas = userEmpresas.isNotEmpty
              ? userEmpresas
              : provider.empresas;
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(defaultPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeader(
                    title: 'Empresas',
                    subtitle: 'Alta de empresas, firma digital y logo.',
                    actions: [
                      IconButton(
                        tooltip: 'Refrescar',
                        onPressed: () {
                          provider.fetchEmpresas();
                          _fetchUsuarioEmpresas();
                        },
                        icon: const Icon(Icons.refresh),
                      ),
                      if (authProvider.isAdmin)
                        if (isMobile)
                          IconButton(
                            tooltip: 'Crear empresa',
                            onPressed: () => _openEmpresaDialog(context),
                            icon: const Icon(Icons.add),
                          )
                        else
                          FilledButton.icon(
                            onPressed: () => _openEmpresaDialog(context),
                            icon: const Icon(Icons.add),
                            label: const Text('Crear empresa'),
                          ),
                    ],
                  ),
                  if (provider.isLoading)
                    const Padding(
                      padding: EdgeInsets.only(top: defaultPadding / 2),
                      child: LinearProgressIndicator(),
                    ),
                  if (_isLoadingUsuarioEmpresas)
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
                  if (_usuarioEmpresasError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: defaultPadding / 2),
                      child: Text(
                        _usuarioEmpresasError!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  const SizedBox(height: defaultPadding),
                  _EmpresasList(
                    empresas: empresas,
                    onUploadFirma: (empresa) => _showFirmaDialog(
                      context,
                      empresa,
                    ),
                    onUploadLogo: (empresa) => _showLogoDialog(
                      context,
                      empresa,
                    ),
                    onEditEmpresa: (empresa) => _openEmpresaDialog(
                      context,
                      empresa: empresa,
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

  Future<void> _fetchUsuarioEmpresas() async {
    final authProvider = context.read<AuthProvider>();
    final usuarioId = authProvider.usuarioId;
    if (usuarioId == null) {
      return;
    }
    setState(() {
      _isLoadingUsuarioEmpresas = true;
      _usuarioEmpresasError = null;
    });
    try {
      final service = UsuariosService(ApiClient());
      final items = await service.fetchUsuarioEmpresas(usuarioId);
      if (!mounted) {
        return;
      }
      setState(() {
        _usuarioEmpresas = items;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _usuarioEmpresasError =
            'No se pudo cargar empresas del usuario.';
        _usuarioEmpresas = [];
      });
    } finally {
      if (mounted) {
        setState(() => _isLoadingUsuarioEmpresas = false);
      }
    }
  }

  Future<void> _openEmpresaDialog(
    BuildContext providerContext, {
    Empresa? empresa,
  }) async {
    final isEditing = empresa != null;
    final formKey = GlobalKey<FormState>();
    final razonSocialController =
        TextEditingController(text: empresa?.razonSocial ?? '');
    final nombreComercialController =
        TextEditingController(text: empresa?.nombreComercial ?? '');
    final rucController = TextEditingController(text: empresa?.ruc ?? '');
    final dirMatrizController =
        TextEditingController(text: empresa?.dirMatriz ?? '');
    final estabController = TextEditingController(text: empresa?.estab ?? '');
    final ptoEmiController = TextEditingController(text: empresa?.ptoEmi ?? '');
    final secuencialController =
        TextEditingController(text: empresa?.secuencial ?? '');
    final creditoDiasController = TextEditingController(
      text: empresa?.creditoDiasDefault?.toString() ?? '',
    );

    var ambiente = empresa?.ambiente ?? 'PRUEBAS';
    var tipoEmision = empresa?.tipoEmision ?? 'NORMAL';
    PlatformFile? selectedFile;
    final claveController = TextEditingController();

    await showDialog<void>(
      context: providerContext,
      builder: (context) {
        return AlertDialog(
          title: Text(isEditing ? 'Editar empresa' : 'Crear empresa'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return SizedBox(
                width: 520,
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DropdownButtonFormField<String>(
                          value: ambiente,
                          items: const [
                            DropdownMenuItem(
                              value: 'PRUEBAS',
                              child: Text('PRUEBAS'),
                            ),
                            DropdownMenuItem(
                              value: 'PRODUCCION',
                              child: Text('PRODUCCION'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => ambiente = value);
                            }
                          },
                          decoration: const InputDecoration(labelText: 'Ambiente'),
                        ),
                        const SizedBox(height: defaultPadding / 2),
                        DropdownButtonFormField<String>(
                          value: tipoEmision,
                          items: const [
                            DropdownMenuItem(
                              value: 'NORMAL',
                              child: Text('NORMAL'),
                            ),
                            DropdownMenuItem(
                              value: 'CONTINGENCIA',
                              child: Text('CONTINGENCIA'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => tipoEmision = value);
                            }
                          },
                          decoration:
                              const InputDecoration(labelText: 'Tipo emision'),
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
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Campo requerido';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: defaultPadding / 2),
                        TextFormField(
                          controller: rucController,
                          enabled: !isEditing,
                          decoration: const InputDecoration(labelText: 'RUC'),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Campo requerido';
                            }
                            if (value.trim().length != 13) {
                              return 'Debe tener 13 digitos';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: defaultPadding / 2),
                        TextFormField(
                          controller: dirMatrizController,
                          decoration: const InputDecoration(
                            labelText: 'Direccion matriz',
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
                                controller: estabController,
                                decoration:
                                    const InputDecoration(labelText: 'Estab'),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Requerido';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: defaultPadding / 2),
                            Expanded(
                              child: TextFormField(
                                controller: ptoEmiController,
                                decoration: const InputDecoration(
                                  labelText: 'Pto Emi',
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Requerido';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: defaultPadding / 2),
                        TextFormField(
                          controller: secuencialController,
                          decoration:
                              const InputDecoration(labelText: 'Secuencial'),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Campo requerido';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: defaultPadding / 2),
                        TextFormField(
                          controller: creditoDiasController,
                          decoration: const InputDecoration(
                            labelText: 'Credito default (dias)',
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            final trimmed = value?.trim() ?? '';
                            if (trimmed.isEmpty) {
                              return null;
                            }
                            final parsed = int.tryParse(trimmed);
                            if (parsed == null || parsed < 0) {
                              return 'Debe ser un numero valido';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: defaultPadding),
                        Container(
                          padding: const EdgeInsets.all(defaultPadding),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Theme.of(context)
                                  .colorScheme
                                  .outline
                                  .withAlpha(120),
                            ),
                            borderRadius:
                                const BorderRadius.all(Radius.circular(10)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Firma digital (opcional)',
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              const SizedBox(height: defaultPadding / 2),
                              OutlinedButton.icon(
                                onPressed: () async {
                                  final result =
                                      await FilePicker.platform.pickFiles(
                                    type: FileType.custom,
                                    allowedExtensions: const ['p12'],
                                    withData: true,
                                  );
                                  if (result != null &&
                                      result.files.isNotEmpty) {
                                    setState(() {
                                      selectedFile = result.files.first;
                                    });
                                  }
                                },
                                icon: const Icon(Icons.attach_file),
                                label: Text(
                                  selectedFile == null
                                      ? 'Seleccionar archivo .p12'
                                      : selectedFile!.name,
                                ),
                              ),
                              const SizedBox(height: defaultPadding / 2),
                              TextFormField(
                                controller: claveController,
                                obscureText: true,
                                decoration: const InputDecoration(
                                  labelText: 'Clave',
                                ),
                              ),
                            ],
                          ),
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
                final clave = claveController.text.trim();
                if (selectedFile != null || clave.isNotEmpty) {
                  if (selectedFile == null || clave.isEmpty) {
                    showAppToast(
                      providerContext,
                      'Selecciona el archivo y la clave.',
                      isError: true,
                    );
                    return;
                  }
                }
                if (!mounted) {
                  return;
                }
                final provider =
                    providerContext.read<EmpresasProvider>();
                final creditoDiasValue =
                    int.tryParse(creditoDiasController.text.trim());
                final payload = Empresa(
                  id: empresa?.id,
                  ambiente: ambiente,
                  tipoEmision: tipoEmision,
                  razonSocial: razonSocialController.text.trim(),
                  nombreComercial: nombreComercialController.text.trim(),
                  ruc: rucController.text.trim(),
                  dirMatriz: dirMatrizController.text.trim(),
                  estab: estabController.text.trim(),
                  ptoEmi: ptoEmiController.text.trim(),
                  secuencial: secuencialController.text.trim(),
                  creditoDiasDefault: creditoDiasValue,
                );

                if (isEditing) {
                  final ok = await provider.updateEmpresa(payload);
                  if (!ok) {
                    showAppToast(
                      providerContext,
                      provider.errorMessage ??
                          'No se pudo actualizar la empresa.',
                      isError: true,
                    );
                    return;
                  }
                } else {
                  final created = await provider.createEmpresa(payload);
                  if (created == null) {
                    showAppToast(
                      providerContext,
                      provider.errorMessage ??
                          'No se pudo registrar la empresa.',
                      isError: true,
                    );
                    return;
                  }
                }

                if (selectedFile != null && selectedFile!.bytes != null) {
                  final empresaId = empresa?.id ??
                      provider.empresas
                          .firstWhere(
                            (item) => item.ruc == payload.ruc,
                            orElse: () => payload,
                          )
                          .id;
                  if (empresaId == null) {
                    showAppToast(
                      providerContext,
                      'No se pudo obtener el ID para la firma.',
                      isError: true,
                    );
                    return;
                  }
                  final ok = await provider.uploadFirma(
                    empresaId: empresaId,
                    bytes: selectedFile!.bytes!,
                    filename: selectedFile!.name,
                    clave: clave,
                  );
                  if (!ok) {
                    showAppToast(
                      providerContext,
                      provider.errorMessage ??
                          'No se pudo cargar la firma.',
                      isError: true,
                    );
                    return;
                  }
                }

                if (context.mounted) {
                  Navigator.of(context).pop();
                  showAppToast(
                    providerContext,
                    isEditing
                        ? 'Empresa actualizada.'
                        : 'Empresa registrada.',
                  );
                }
              },
              child: Text(isEditing ? 'Guardar' : 'Crear'),
            ),
          ],
        );
      },
    );

    razonSocialController.dispose();
    nombreComercialController.dispose();
    rucController.dispose();
    dirMatrizController.dispose();
    estabController.dispose();
    ptoEmiController.dispose();
    secuencialController.dispose();
    creditoDiasController.dispose();
    claveController.dispose();
  }

  Future<void> _showFirmaDialog(
    BuildContext providerContext,
    Empresa empresa,
  ) async {
    if (empresa.id == null) {
      showAppToast(
        providerContext,
        'Empresa sin ID valido.',
        isError: true,
      );
      return;
    }
    PlatformFile? selectedFile;
    final claveController = TextEditingController();
    await showDialog<void>(
      context: providerContext,
      builder: (context) {
        return AlertDialog(
          title: const Text('Cargar firma digital'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    empresa.razonSocial,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: defaultPadding),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final result = await FilePicker.platform.pickFiles(
                        type: FileType.custom,
                        allowedExtensions: const ['p12'],
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
                          ? 'Seleccionar archivo .p12'
                          : selectedFile!.name,
                    ),
                  ),
                  const SizedBox(height: defaultPadding),
                  TextFormField(
                    controller: claveController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Clave',
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
                if (selectedFile == null ||
                    selectedFile!.bytes == null ||
                    claveController.text.trim().isEmpty) {
                  showAppToast(
                    providerContext,
                    'Selecciona el archivo y la clave.',
                    isError: true,
                  );
                  return;
                }
                final provider =
                    providerContext.read<EmpresasProvider>();
                final ok = await provider.uploadFirma(
                  empresaId: empresa.id!,
                  bytes: selectedFile!.bytes!,
                  filename: selectedFile!.name,
                  clave: claveController.text.trim(),
                );
                if (ok && context.mounted) {
                  Navigator.of(context).pop();
                  showAppToast(providerContext, 'Firma cargada.');
                } else if (context.mounted) {
                  showAppToast(
                    providerContext,
                    provider.errorMessage ??
                        'No se pudo cargar la firma.',
                    isError: true,
                  );
                }
              },
              child: const Text('Subir'),
            ),
          ],
        );
      },
    );
    claveController.dispose();
  }

  Future<void> _showLogoDialog(
    BuildContext providerContext,
    Empresa empresa,
  ) async {
    if (empresa.id == null) {
      showAppToast(
        providerContext,
        'Empresa sin ID valido.',
        isError: true,
      );
      return;
    }
    PlatformFile? selectedFile;
    await showDialog<void>(
      context: providerContext,
      builder: (context) {
        return AlertDialog(
          title: const Text('Subir logo de empresa'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    empresa.razonSocial,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: defaultPadding),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final result = await FilePicker.platform.pickFiles(
                        type: FileType.image,
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
                          ? 'Seleccionar imagen'
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
                if (selectedFile == null || selectedFile!.bytes == null) {
                  showAppToast(
                    providerContext,
                    'Selecciona una imagen.',
                    isError: true,
                  );
                  return;
                }
                final provider =
                    providerContext.read<EmpresasProvider>();
                final ok = await provider.uploadLogo(
                  empresaId: empresa.id!,
                  bytes: selectedFile!.bytes!,
                  filename: selectedFile!.name,
                );
                if (ok && context.mounted) {
                  Navigator.of(context).pop();
                  showAppToast(providerContext, 'Logo cargado.');
                } else if (context.mounted) {
                  showAppToast(
                    providerContext,
                    provider.errorMessage ??
                        'No se pudo cargar el logo.',
                    isError: true,
                  );
                }
              },
              child: const Text('Subir'),
            ),
          ],
        );
      },
    );
  }
}

class _EmpresasList extends StatelessWidget {
  const _EmpresasList({
    required this.empresas,
    required this.onUploadFirma,
    required this.onUploadLogo,
    required this.onEditEmpresa,
  });

  final List<Empresa> empresas;
  final void Function(Empresa empresa) onUploadFirma;
  final void Function(Empresa empresa) onUploadLogo;
  final void Function(Empresa empresa) onEditEmpresa;

  @override
  Widget build(BuildContext context) {
    final items = empresas;

    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(defaultPadding),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.all(Radius.circular(10)),
        ),
        child: const Text('Sin empresas registradas.'),
      );
    }

    final ambienteCounts = <String, int>{};
    for (final empresa in items) {
      ambienteCounts.update(empresa.ambiente, (value) => value + 1,
          ifAbsent: () => 1);
    }

    if (Responsive.isMobile(context)) {
      return Column(
        children: items
            .map(
              (empresa) => Card(
                child: ListTile(
                  title: Text(empresa.razonSocial),
                  subtitle: Text(
                    'RUC: ${empresa.ruc} • Credito ${empresa.creditoDiasDefault?.toString() ?? '-'} dias',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        tooltip: 'Editar',
                        onPressed: () => onEditEmpresa(empresa),
                      ),
                      IconButton(
                        icon: const Icon(Icons.key),
                        tooltip: 'Cargar firma',
                        onPressed: () => onUploadFirma(empresa),
                      ),
                      IconButton(
                        icon: const Icon(Icons.image_outlined),
                        tooltip: 'Subir logo',
                        onPressed: () => onUploadLogo(empresa),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Listado de empresas',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withAlpha(18),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${items.length} registradas',
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: defaultPadding / 2),
                  Wrap(
                    spacing: defaultPadding / 2,
                    runSpacing: defaultPadding / 2,
                    children: ambienteCounts.entries
                        .map(
                          (entry) => Chip(
                            label: Text('${entry.key}: ${entry.value}'),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: defaultPadding),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('RUC')),
                        DataColumn(label: Text('Razon social')),
                        DataColumn(label: Text('Ambiente')),
                        DataColumn(label: Text('Estab/PtoEmi')),
                        DataColumn(label: Text('Credito default')),
                        DataColumn(label: Text('Acciones')),
                      ],
                      rows: items
                          .map(
                            (empresa) => DataRow(
                              cells: [
                                DataCell(Text(empresa.ruc)),
                                DataCell(Text(empresa.razonSocial)),
                                DataCell(
                                  _AmbienteBadge(ambiente: empresa.ambiente),
                                ),
                                DataCell(Text('${empresa.estab}-${empresa.ptoEmi}')),
                                DataCell(
                                  Text(
                                    empresa.creditoDiasDefault?.toString() ??
                                        '-',
                                  ),
                                ),
                                DataCell(
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        tooltip: 'Editar',
                                        onPressed: () =>
                                            onEditEmpresa(empresa),
                                        icon:
                                            const Icon(Icons.edit_outlined),
                                      ),
                                      IconButton(
                                        tooltip: 'Subir firma',
                                        onPressed: () =>
                                            onUploadFirma(empresa),
                                        icon: const Icon(Icons.key),
                                      ),
                                      IconButton(
                                        tooltip: 'Subir logo',
                                        onPressed: () =>
                                            onUploadLogo(empresa),
                                        icon: const Icon(Icons.image_outlined),
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
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AmbienteBadge extends StatelessWidget {
  const _AmbienteBadge({required this.ambiente});

  final String ambiente;

  @override
  Widget build(BuildContext context) {
    final isProduccion = ambiente.toUpperCase() == 'PRODUCCION';
    final color = isProduccion ? Colors.green : Colors.orange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        ambiente,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
