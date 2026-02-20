import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/models/usuario_empresa.dart';
import '../../resource/theme/dimens.dart';
import '../../routing/app_sections.dart';
import '../../services/api_client.dart';
import '../../services/dashboard_service.dart';
import '../../services/empresas_service.dart';
import '../../services/usuarios_service.dart';
import '../../states/auth_provider.dart';
import '../../states/menu_app_controller.dart';
import '../../utils/responsive.dart';
import 'components/header.dart';
import '../../domain/models/dashboard_resumen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _loadingEmpresas = false;
  bool _loadingResumen = false;
  String? _resumenError;
  DashboardResumen? _resumen;
  late final DashboardService _dashboardService;
  List<UsuarioEmpresa> _empresas = [];
  int? _selectedEmpresaId;

  @override
  void initState() {
    super.initState();
    _dashboardService = DashboardService(ApiClient());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadEmpresas();
    });
  }

  Future<void> _loadEmpresas() async {
    final auth = context.read<AuthProvider>();
    final userId = auth.usuarioId;
    if (userId == null && !auth.isAdmin) {
      return;
    }
    if (!mounted) {
      return;
    }
    setState(() => _loadingEmpresas = true);
    try {
      if (auth.isAdmin) {
        final service = EmpresasService(ApiClient());
        final empresas = await service.fetchEmpresas();
        _empresas = empresas
            .where((empresa) => empresa.id != null)
            .map(
              (empresa) => UsuarioEmpresa(
                empresaId: empresa.id!,
                principal: empresa.id == auth.empresaId,
                empresa: empresa,
              ),
            )
            .toList();
      } else {
        final service = UsuariosService(ApiClient());
        _empresas = await service.fetchUsuarioEmpresas(userId!);
      }
      if (!mounted) {
        return;
      }
      _selectedEmpresaId = _resolvePrincipalEmpresaId(_empresas);
    } catch (_) {
      if (!mounted) {
        return;
      }
      _empresas = [];
    } finally {
      if (mounted) {
        setState(() => _loadingEmpresas = false);
        _loadResumen(empresaId: _selectedEmpresaId);
      }
    }
  }

  Future<void> _loadResumen({int? empresaId}) async {
    if (!mounted) {
      return;
    }
    setState(() {
      _loadingResumen = true;
      _resumenError = null;
    });
    try {
      final resumen = await _dashboardService.fetchResumen(
        empresaId: empresaId,
      );
      if (!mounted) {
        return;
      }
      setState(() => _resumen = resumen);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _resumen = null;
        _resumenError = _resolveError(error);
      });
    } finally {
      if (mounted) {
        setState(() => _loadingResumen = false);
      }
    }
  }

  int? _resolvePrincipalEmpresaId(List<UsuarioEmpresa> empresas) {
    for (final item in empresas) {
      if (item.principal) {
        return item.empresaId;
      }
    }
    return empresas.isNotEmpty ? empresas.first.empresaId : null;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        primary: false,
        padding: const EdgeInsets.all(defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Header(),
            const SizedBox(height: defaultPadding),
            _EmpresaSelector(
              empresas: _empresas,
              selectedEmpresaId: _selectedEmpresaId,
              isLoading: _loadingEmpresas,
              onChanged: (value) {
                setState(() => _selectedEmpresaId = value);
                _loadResumen(empresaId: value);
              },
            ),
            const SizedBox(height: defaultPadding * 1.5),
            if (_loadingResumen)
              const Padding(
                padding: EdgeInsets.only(bottom: defaultPadding),
                child: LinearProgressIndicator(),
              ),
            if (_resumenError != null)
              Padding(
                padding: const EdgeInsets.only(bottom: defaultPadding),
                child: Text(
                  _resumenError!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
            _StatsGrid(resumen: _resumen),
            const SizedBox(height: defaultPadding * 1.5),
            const _SectionTitle(title: 'Accesos rapidos'),
            const SizedBox(height: defaultPadding),
            _CashflowCard(resumen: _resumen),
            const SizedBox(height: defaultPadding * 1.5),
            const _SectionTitle(title: 'Acciones rapidas'),
            const SizedBox(height: defaultPadding),
            Responsive(
              mobile: _MobileSummary(resumen: _resumen),
              tablet: _TabletSummary(resumen: _resumen),
              desktop: _DesktopSummary(resumen: _resumen),
            ),
          ],
        ),
      ),
    );
  }

  String _resolveError(Object error) {
    if (error is ApiException) {
      return error.message;
    }
    return error.toString();
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.resumen});

  final DashboardResumen? resumen;

  @override
  Widget build(BuildContext context) {
    final stats = _DashboardStatData.fromResumen(resumen);
    final size = MediaQuery.of(context).size;
    final crossAxisCount = size.width < 650
        ? 1
        : Responsive.isMobile(context)
            ? 2
            : 4;
    final ratio = Responsive.isDesktop(context) ? 2.6 : 2.2;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: stats.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: defaultPadding,
        mainAxisSpacing: defaultPadding,
        childAspectRatio: ratio,
      ),
      itemBuilder: (context, index) {
        return _StatCard(data: stats[index]);
      },
    );
  }
}

class _EmpresaSelector extends StatelessWidget {
  const _EmpresaSelector({
    required this.empresas,
    required this.selectedEmpresaId,
    required this.isLoading,
    required this.onChanged,
  });

  final List<UsuarioEmpresa> empresas;
  final int? selectedEmpresaId;
  final bool isLoading;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const LinearProgressIndicator();
    }
    if (empresas.isEmpty) {
      return const SizedBox.shrink();
    }
    if (empresas.length == 1) {
      final label = _empresaLabel(empresas.first);
      final theme = Theme.of(context);
      return Row(
        children: [
          Text(
            'Empresa',
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: theme.colorScheme.outline.withAlpha(153),
                ),
              ),
              child: Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      );
    }
    final items = empresas
        .map(
          (item) => DropdownMenuItem<int>(
            value: item.empresaId,
            child: Text(_empresaLabel(item)),
          ),
        )
        .toList();
    return Row(
      children: [
        Text(
          'Empresa',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: DropdownButtonFormField<int>(
            value: selectedEmpresaId ?? empresas.first.empresaId,
            items: items,
            onChanged: onChanged,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
        ),
      ],
    );
  }
}

String _empresaLabel(UsuarioEmpresa item) {
  final empresa = item.empresa;
  if (empresa != null) {
    if (empresa.nombreComercial.isNotEmpty) {
      return empresa.nombreComercial;
    }
    if (empresa.razonSocial.isNotEmpty) {
      return empresa.razonSocial;
    }
  }
  return item.empresaId.toString();
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.data});

  final _DashboardStatData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surface = theme.colorScheme.surface;
    final gradient = LinearGradient(
      colors: [
        surface,
        Color.alphaBlend(data.color.withAlpha(28), surface),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Container(
      padding: const EdgeInsets.all(defaultPadding),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: data.color.withAlpha(140)),
        boxShadow: [
          BoxShadow(
            color: data.color.withAlpha(22),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: data.color.withAlpha(30),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(data.icon, color: data.color),
          ),
          const SizedBox(width: defaultPadding),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  data.title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withAlpha(160),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  data.value,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  data.caption,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: data.isPositive
                        ? Colors.greenAccent.shade400
                        : theme.colorScheme.error,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CashflowCard extends StatelessWidget {
  const _CashflowCard({required this.resumen});

  final DashboardResumen? resumen;

  @override
  Widget build(BuildContext context) {
    return _DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Flujo de Caja Ultimos 30 Dias',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: defaultPadding),
          SizedBox(
            height: 160,
            child: _MiniLineChart(
              values: _resolveCashflowValues(resumen),
            ),
          ),
          const SizedBox(height: defaultPadding),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: const [
              _QuickActionButton(
                label: 'Nueva Factura',
                icon: Icons.add_circle_outline,
                color: Color(0xFF2697FF),
                section: AppSection.facturacion,
              ),
              _QuickActionButton(
                label: 'Registrar Cliente',
                icon: Icons.person_add_alt_1,
                color: Color(0xFF29C98A),
                section: AppSection.clientes,
              ),
              _QuickActionButton(
                label: 'Entrada Stock',
                icon: Icons.inventory_2_outlined,
                color: Color(0xFFF5A524),
                section: AppSection.inventarios,
              ),
              _QuickActionButton(
                label: 'Subir Factura',
                icon: Icons.cloud_upload_outlined,
                color: Color(0xFF7B61FF),
                section: AppSection.facturacion,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.section,
  });

  final String label;
  final IconData icon;
  final Color color;
  final AppSection section;

  @override
  Widget build(BuildContext context) {
    final controller = context.read<MenuAppController>();
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () => controller.setSection(section),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: color.withAlpha(30),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withAlpha(120)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MobileSummary extends StatelessWidget {
  const _MobileSummary({required this.resumen});

  final DashboardResumen? resumen;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _RecentInvoicesCard(resumen: resumen),
        const SizedBox(height: defaultPadding),
        _TopProductsCard(resumen: resumen),
        const SizedBox(height: defaultPadding),
        _LowStockCard(resumen: resumen),
      ],
    );
  }
}

class _TabletSummary extends StatelessWidget {
  const _TabletSummary({required this.resumen});

  final DashboardResumen? resumen;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _RecentInvoicesCard(resumen: resumen),
        const SizedBox(height: defaultPadding),
        _TopProductsCard(resumen: resumen),
        const SizedBox(height: defaultPadding),
        _LowStockCard(resumen: resumen),
      ],
    );
  }
}

class _DesktopSummary extends StatelessWidget {
  const _DesktopSummary({required this.resumen});

  final DashboardResumen? resumen;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 3, child: _RecentInvoicesCard(resumen: resumen)),
        const SizedBox(width: defaultPadding),
        Expanded(
          flex: 2,
          child: Column(
            children: [
              _TopProductsCard(resumen: resumen),
              const SizedBox(height: defaultPadding),
              _LowStockCard(resumen: resumen),
            ],
          ),
        ),
      ],
    );
  }
}

class _RecentInvoicesCard extends StatelessWidget {
  const _RecentInvoicesCard({required this.resumen});

  final DashboardResumen? resumen;

  @override
  Widget build(BuildContext context) {
    final rows = resumen?.ultimasFacturas ?? const <DashboardFacturaItem>[];
    return _DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(
            title: 'Ultimas Facturas',
            actionLabel: 'Ver todo',
          ),
          const SizedBox(height: defaultPadding),
          if (rows.isEmpty)
            Text(
              'Sin facturas recientes.',
              style: Theme.of(context).textTheme.bodySmall,
            )
          else
            Table(
              columnWidths: const {
                0: FlexColumnWidth(2.2),
                1: FlexColumnWidth(1.2),
                2: FlexColumnWidth(1.2),
              },
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              children: [
                _buildTableHeader(context, ['Numero', 'Monto', 'Estado']),
                for (final row in rows) _buildInvoiceRow(context, row),
              ],
            ),
        ],
      ),
    );
  }

  TableRow _buildTableHeader(BuildContext context, List<String> titles) {
    final style = Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurface.withAlpha(140),
          fontWeight: FontWeight.w600,
        );
    return TableRow(
      children: titles
          .map(
            (title) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(title, style: style),
            ),
          )
          .toList(),
    );
  }

  TableRow _buildInvoiceRow(BuildContext context, DashboardFacturaItem row) {
    final statusColor = _resolveStatusColor(row.estado);
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Text(
            row.numero ?? '-',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Text(_formatMoney(row.total)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Align(
            alignment: Alignment.centerLeft,
            child: _StatusChip(
              label: row.estado ?? '-',
              color: statusColor,
            ),
          ),
        ),
      ],
    );
  }
}

class _TopProductsCard extends StatelessWidget {
  const _TopProductsCard({required this.resumen});

  final DashboardResumen? resumen;

  @override
  Widget build(BuildContext context) {
    final rows = resumen?.productosMasVendidos ??
        const <DashboardProductoVentaItem>[];
    return _DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(
            title: 'Productos mas vendidos',
            actionLabel: 'Detalle',
          ),
          const SizedBox(height: defaultPadding),
          if (rows.isEmpty)
            Text(
              'Sin datos de ventas.',
              style: Theme.of(context).textTheme.bodySmall,
            )
          else
            for (final row in rows) _ProductRow(row: row),
        ],
      ),
    );
  }
}

class _ProductRow extends StatelessWidget {
  const _ProductRow({required this.row});

  final DashboardProductoVentaItem row;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              row.descripcion ?? '-',
              style: theme.textTheme.bodySmall,
            ),
          ),
          Expanded(
            child: Text(
              _formatQuantity(row.cantidad),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withAlpha(150),
              ),
            ),
          ),
          Expanded(
            child: Text(
              _formatMoney(row.total),
              textAlign: TextAlign.right,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LowStockCard extends StatelessWidget {
  const _LowStockCard({required this.resumen});

  final DashboardResumen? resumen;

  @override
  Widget build(BuildContext context) {
    final rows =
        resumen?.productosMenosStock ?? const <DashboardProductoStockItem>[];
    return _DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(
            title: 'Productos con menos stock',
            actionLabel: 'Detalle',
          ),
          const SizedBox(height: defaultPadding),
          _LowStockHeader(),
          const SizedBox(height: 6),
          if (rows.isEmpty)
            Text(
              'Sin productos en lista.',
              style: Theme.of(context).textTheme.bodySmall,
            )
          else
            for (final row in rows) _LowStockRow(row: row),
        ],
      ),
    );
  }
}

class _LowStockRow extends StatelessWidget {
  const _LowStockRow({required this.row});

  final DashboardProductoStockItem row;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final actual = row.stockActual;
    final minimo = row.stockMinimo;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              row.descripcion ?? '-',
              style: theme.textTheme.bodySmall,
            ),
          ),
          Expanded(
            child: Text(
              _formatQuantity(actual),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withAlpha(150),
              ),
            ),
          ),
          Expanded(
            child: Text(
              _formatQuantity(minimo),
              textAlign: TextAlign.right,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LowStockHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurface.withAlpha(140),
          fontWeight: FontWeight.w600,
        );
    return Row(
      children: [
        Expanded(flex: 3, child: Text('Producto', style: style)),
        Expanded(child: Text('Actual', style: style)),
        Expanded(
          child: Text('Minimo', style: style, textAlign: TextAlign.right),
        ),
      ],
    );
  }
}

class _CardHeader extends StatelessWidget {
  const _CardHeader({required this.title, required this.actionLabel});

  final String title;
  final String actionLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          actionLabel,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _DashboardCard extends StatelessWidget {
  const _DashboardCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surface = theme.colorScheme.surface;
    return Container(
      padding: const EdgeInsets.all(defaultPadding),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outline.withAlpha(110)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(120)),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _MiniLineChart extends StatelessWidget {
  const _MiniLineChart({required this.values});

  final List<double> values;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final points = values.isEmpty
        ? const [
            1.2,
            1.4,
            1.3,
            1.8,
            1.6,
            1.7,
            2.1,
            2.0,
            2.4,
            2.2,
            2.6,
            2.5,
          ]
        : values;
    return CustomPaint(
      painter: _LineChartPainter(
        values: points,
        lineColor: theme.colorScheme.primary,
        fillColor: theme.colorScheme.primary.withAlpha(45),
        gridColor: theme.colorScheme.onSurface.withAlpha(20),
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  _LineChartPainter({
    required this.values,
    required this.lineColor,
    required this.fillColor,
    required this.gridColor,
  });

  final List<double> values;
  final Color lineColor;
  final Color fillColor;
  final Color gridColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) {
      return;
    }

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    final gridStep = size.height / 3;
    for (var i = 1; i <= 2; i++) {
      final y = gridStep * i;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final minValue = values.reduce(min).toDouble();
    final maxValue = values.reduce(max).toDouble();
    final range =
        (maxValue - minValue).abs() < 0.001 ? 1.0 : maxValue - minValue;
    final stepX =
        values.length == 1 ? 0.0 : size.width / (values.length - 1);

    final linePath = Path();
    for (var i = 0; i < values.length; i++) {
      final x = stepX * i;
      final normalized = ((values[i] - minValue) / range).toDouble();
      final y = (size.height - (normalized * (size.height - 16)) - 8).toDouble();
      if (i == 0) {
        linePath.moveTo(x, y);
      } else {
        linePath.lineTo(x, y);
      }
    }

    final fillPath = Path.from(linePath)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(fillPath, fillPaint);

    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    canvas.drawPath(linePath, linePaint);
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.fillColor != fillColor ||
        oldDelegate.gridColor != gridColor;
  }
}

class _DashboardStatData {
  const _DashboardStatData({
    required this.title,
    required this.value,
    required this.caption,
    required this.icon,
    required this.color,
    required this.isPositive,
  });

  final String title;
  final String value;
  final String caption;
  final IconData icon;
  final Color color;
  final bool isPositive;

  static List<_DashboardStatData> fromResumen(DashboardResumen? resumen) {
    final ventasPct = resumen?.ventasVariacionPct;
    final ventasCaption = ventasPct == null
        ? 'Sin datos vs. mes anterior'
        : '${ventasPct >= 0 ? '+' : ''}${ventasPct.toStringAsFixed(1)}% vs. mes anterior';
    final pendientesHoy = resumen?.cuentasPorCobrarPendientesHoy;
    final pendientesCaption = pendientesHoy == null
        ? 'Sin datos hoy'
        : '$pendientesHoy pendientes hoy';
    final stockCritico = resumen?.stockCritico;
    final proveedoresSemana = resumen?.proveedoresPorPagarVencenSemana;
    final proveedoresCaption = proveedoresSemana == null
        ? 'Sin datos esta semana'
        : '$proveedoresSemana vencen esta semana';

    return [
      _DashboardStatData(
        title: 'Ventas del Mes',
        value: _formatMoney(resumen?.ventasMes),
        caption: ventasCaption,
        icon: Icons.trending_up,
        color: const Color(0xFF2ECC71),
        isPositive: (ventasPct ?? 0) >= 0,
      ),
      _DashboardStatData(
        title: 'Cuentas por Cobrar',
        value: _formatMoney(resumen?.cuentasPorCobrarTotal),
        caption: pendientesCaption,
        icon: Icons.account_balance_wallet_outlined,
        color: const Color(0xFFF5A524),
        isPositive: true,
      ),
      _DashboardStatData(
        title: 'Stock Critico',
        value: stockCritico?.toString() ?? '-',
        caption: 'Necesitan reposición',
        icon: Icons.warning_amber_rounded,
        color: const Color(0xFFFF5A5F),
        isPositive: (stockCritico ?? 0) == 0,
      ),
      _DashboardStatData(
        title: 'Proveedores por Pagar',
        value: _formatMoney(resumen?.proveedoresPorPagarTotal),
        caption: proveedoresCaption,
        icon: Icons.inventory_2_outlined,
        color: const Color(0xFF7B61FF),
        isPositive: true,
      ),
    ];
  }
}

List<double> _resolveCashflowValues(DashboardResumen? resumen) {
  final cashflow = resumen?.flujoCaja30Dias ?? const [];
  if (cashflow.isEmpty) {
    return const [];
  }
  return cashflow
      .map((item) => item.neto ?? item.ingresos ?? 0)
      .toList();
}

String _formatMoney(double? value) {
  if (value == null) {
    return '-';
  }
  return '\$${value.toStringAsFixed(2)}';
}

String _formatQuantity(double? value) {
  if (value == null) {
    return '-';
  }
  if (value % 1 == 0) {
    return value.toStringAsFixed(0);
  }
  return value.toStringAsFixed(2);
}

Color _resolveStatusColor(String? estado) {
  final normalized = estado?.toLowerCase() ?? '';
  if (normalized.contains('autoriz') ||
      normalized.contains('cobr') ||
      normalized.contains('emitida')) {
    return const Color(0xFF2ECC71);
  }
  if (normalized.contains('parcial') ||
      normalized.contains('pendiente') ||
      normalized.contains('proceso')) {
    return const Color(0xFFF5A524);
  }
  if (normalized.contains('rech') ||
      normalized.contains('error') ||
      normalized.contains('anulada')) {
    return const Color(0xFFFF5A5F);
  }
  return const Color(0xFF7B61FF);
}
