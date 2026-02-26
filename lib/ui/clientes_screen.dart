import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../domain/models/cliente.dart';
import '../resource/theme/dimens.dart';
import '../services/api_client.dart';
import '../services/clientes_service.dart';
import '../states/auth_provider.dart';
import '../states/clientes_provider.dart';
import '../ui/shared/feedback.dart';
import '../ui/shared/section_header.dart';
import '../utils/responsive.dart';

class ClientesScreen extends StatefulWidget {
  const ClientesScreen({super.key});

  @override
  State<ClientesScreen> createState() => _ClientesScreenState();
}

class _ClientesScreenState extends State<ClientesScreen> {
  late final ClientesProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = ClientesProvider(ClientesService(ApiClient()));
    _provider.fetchClientes();
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
      child: Consumer<ClientesProvider>(
        builder: (context, provider, _) {
          final authProvider = context.watch<AuthProvider>();
          final empresaId = authProvider.empresaId;
          final clientes = empresaId == null
              ? provider.clientes
              : provider.clientes
                  .where(
                    (cliente) =>
                        cliente.empresaId == null ||
                        cliente.empresaId == empresaId,
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
                    title: 'Clientes',
                    subtitle: 'Registro y validacion de clientes.',
                    actions: [
                      IconButton(
                        tooltip: 'Refrescar',
                        onPressed: provider.fetchClientes,
                        icon: const Icon(Icons.refresh),
                      ),
                      if (isMobile)
                        IconButton(
                          tooltip: 'Crear cliente',
                          onPressed: () => _openClienteDialog(context),
                          icon: const Icon(Icons.add),
                        )
                      else
                        FilledButton.icon(
                          onPressed: () => _openClienteDialog(context),
                          icon: const Icon(Icons.add),
                          label: const Text('Crear cliente'),
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
                  _ClientesList(
                    clientes: clientes,
                    onEdit: (cliente) =>
                        _openClienteDialog(context, cliente: cliente),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _openClienteDialog(
    BuildContext providerContext, {
    Cliente? cliente,
  }) async {
    final isEditing = cliente != null;
    final formKey = GlobalKey<FormState>();
    final identificacionController =
        TextEditingController(text: cliente?.identificacion ?? '');
    final razonSocialController =
        TextEditingController(text: cliente?.razonSocial ?? '');
    final emailController = TextEditingController(text: cliente?.email ?? '');
    final direccionController =
        TextEditingController(text: cliente?.direccion ?? '');
    final creditoDiasController = TextEditingController(
      text: cliente?.creditoDias?.toString() ?? '',
    );
    var tipoIdentificacion = cliente?.tipoIdentificacion ?? '05';

    await showDialog<void>(
      context: providerContext,
      builder: (context) {
        return AlertDialog(
          title: Text(isEditing ? 'Editar cliente' : 'Crear cliente'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return SizedBox(
                width: 420,
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        value: tipoIdentificacion,
                        items: const [
                          DropdownMenuItem(value: '05', child: Text('Cedula')),
                          DropdownMenuItem(value: '04', child: Text('RUC')),
                          DropdownMenuItem(
                              value: '06', child: Text('Pasaporte')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => tipoIdentificacion = value);
                          }
                        },
                        decoration: const InputDecoration(labelText: 'Tipo'),
                      ),
                      const SizedBox(height: defaultPadding / 2),
                      TextFormField(
                        controller: identificacionController,
                        decoration:
                            const InputDecoration(labelText: 'Identificacion'),
                        keyboardType: TextInputType.number,
                        validator: (value) =>
                            _validateIdentificacion(value, tipoIdentificacion),
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
                        controller: emailController,
                        decoration: const InputDecoration(labelText: 'Email'),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Campo requerido';
                          }
                          if (!value.contains('@')) {
                            return 'Email no valido';
                          }
                          return null;
                        },
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
                      TextFormField(
                        controller: creditoDiasController,
                        decoration: const InputDecoration(
                          labelText: 'Credito (dias)',
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
                final creditoDiasValue =
                    int.tryParse(creditoDiasController.text.trim());
                final provider = providerContext.read<ClientesProvider>();
                final payload = Cliente(
                  id: cliente?.id,
                  tipoIdentificacion: tipoIdentificacion,
                  identificacion: identificacionController.text.trim(),
                  razonSocial: razonSocialController.text.trim(),
                  email: emailController.text.trim(),
                  direccion: direccionController.text.trim(),
                  creditoDias: creditoDiasValue,
                );
                final ok = isEditing
                    ? await provider.updateCliente(payload)
                    : await provider.createCliente(payload);
                if (!ok) {
                  showAppToast(
                    providerContext,
                    provider.errorMessage ?? 'No se pudo guardar el cliente.',
                    isError: true,
                  );
                  return;
                }
                if (context.mounted) {
                  Navigator.of(context).pop();
                  showAppToast(
                    providerContext,
                    isEditing ? 'Cliente actualizado.' : 'Cliente registrado.',
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
    emailController.dispose();
    direccionController.dispose();
    creditoDiasController.dispose();
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
}

class _ClientesList extends StatelessWidget {
  const _ClientesList({
    required this.clientes,
    required this.onEdit,
  });

  final List<Cliente> clientes;
  final void Function(Cliente cliente) onEdit;

  @override
  Widget build(BuildContext context) {
    if (clientes.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(defaultPadding),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.all(Radius.circular(10)),
        ),
        child: const Text('Sin clientes registrados.'),
      );
    }

    if (Responsive.isMobile(context)) {
      return Column(
        children: clientes
            .map(
              (cliente) => Card(
                child: ListTile(
                  title: Text(cliente.razonSocial),
                  subtitle: Text(
                    '${cliente.identificacion} • Credito ${cliente.creditoDias?.toString() ?? '-'} dias',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    tooltip: 'Editar',
                    onPressed: () => onEdit(cliente),
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
                    DataColumn(label: Text('Tipo')),
                    DataColumn(label: Text('Identificacion')),
                    DataColumn(label: Text('Razon social')),
                    DataColumn(label: Text('Email')),
                    DataColumn(label: Text('Direccion')),
                    DataColumn(label: Text('Credito (dias)')),
                    DataColumn(label: Text('Acciones')),
                  ],
                  rows: clientes
                      .map(
                        (cliente) => DataRow(
                          cells: [
                            DataCell(Text(cliente.tipoIdentificacion)),
                            DataCell(Text(cliente.identificacion)),
                            DataCell(Text(cliente.razonSocial)),
                            DataCell(Text(cliente.email)),
                            DataCell(Text(cliente.direccion)),
                            DataCell(
                              Text(cliente.creditoDias?.toString() ?? '-'),
                            ),
                            DataCell(
                              IconButton(
                                tooltip: 'Editar',
                                onPressed: () => onEdit(cliente),
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
