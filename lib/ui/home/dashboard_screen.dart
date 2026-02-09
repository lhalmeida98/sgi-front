import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../resource/theme/dimens.dart';
import '../../routing/app_sections.dart';
import '../../states/menu_app_controller.dart';
import '../../utils/responsive.dart';
import 'components/header.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

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
            const SizedBox(height: defaultPadding * 1.5),
            const _StatsGrid(),
            const SizedBox(height: defaultPadding * 1.5),
            const _SectionTitle(title: 'Accesos rapidos'),
            const SizedBox(height: defaultPadding),
            const _CashflowCard(),
            const SizedBox(height: defaultPadding * 1.5),
            const _SectionTitle(title: 'Acciones rapidas'),
            const SizedBox(height: defaultPadding),
            Responsive(
              mobile: const _MobileSummary(),
              tablet: const _TabletSummary(),
              desktop: const _DesktopSummary(),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid();

  @override
  Widget build(BuildContext context) {
    final stats = _DashboardStatData.samples;
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
  const _CashflowCard();

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
          const SizedBox(
            height: 160,
            child: _MiniLineChart(),
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
  const _MobileSummary();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        _RecentInvoicesCard(),
        SizedBox(height: defaultPadding),
        _TopProductsCard(),
      ],
    );
  }
}

class _TabletSummary extends StatelessWidget {
  const _TabletSummary();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        _RecentInvoicesCard(),
        SizedBox(height: defaultPadding),
        _TopProductsCard(),
      ],
    );
  }
}

class _DesktopSummary extends StatelessWidget {
  const _DesktopSummary();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Expanded(flex: 3, child: _RecentInvoicesCard()),
        SizedBox(width: defaultPadding),
        Expanded(flex: 2, child: _TopProductsCard()),
      ],
    );
  }
}

class _RecentInvoicesCard extends StatelessWidget {
  const _RecentInvoicesCard();

  @override
  Widget build(BuildContext context) {
    final rows = _InvoiceRowData.samples;
    return _DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(
            title: 'Ultimas Facturas',
            actionLabel: 'Ver todo',
          ),
          const SizedBox(height: defaultPadding),
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

  TableRow _buildInvoiceRow(BuildContext context, _InvoiceRowData row) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Text(
            row.numero,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Text(row.monto),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Align(
            alignment: Alignment.centerLeft,
            child: _StatusChip(
              label: row.estado,
              color: row.color,
            ),
          ),
        ),
      ],
    );
  }
}

class _TopProductsCard extends StatelessWidget {
  const _TopProductsCard();

  @override
  Widget build(BuildContext context) {
    final rows = _ProductRowData.samples;
    return _DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(
            title: 'Productos mas vendidos',
            actionLabel: 'Detalle',
          ),
          const SizedBox(height: defaultPadding),
          for (final row in rows) _ProductRow(row: row),
        ],
      ),
    );
  }
}

class _ProductRow extends StatelessWidget {
  const _ProductRow({required this.row});

  final _ProductRowData row;

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
              row.producto,
              style: theme.textTheme.bodySmall,
            ),
          ),
          Expanded(
            child: Text(
              row.cantidad,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withAlpha(150),
              ),
            ),
          ),
          Expanded(
            child: Text(
              row.total,
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
  const _MiniLineChart();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CustomPaint(
      painter: _LineChartPainter(
        values: const [
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
        ],
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

  static const List<_DashboardStatData> samples = [
    _DashboardStatData(
      title: 'Ventas del Mes',
      value: '\$12,450.00',
      caption: '+12% vs. mes anterior',
      icon: Icons.trending_up,
      color: Color(0xFF2ECC71),
      isPositive: true,
    ),
    _DashboardStatData(
      title: 'Cuentas por Cobrar',
      value: '\$3,120.50',
      caption: '8 pendientes hoy',
      icon: Icons.account_balance_wallet_outlined,
      color: Color(0xFFF5A524),
      isPositive: true,
    ),
    _DashboardStatData(
      title: 'Stock Critico',
      value: '15',
      caption: 'Necesitan reposicion',
      icon: Icons.warning_amber_rounded,
      color: Color(0xFFFF5A5F),
      isPositive: false,
    ),
    _DashboardStatData(
      title: 'Proveedores por Pagar',
      value: '\$1,890.75',
      caption: '3 vencen esta semana',
      icon: Icons.inventory_2_outlined,
      color: Color(0xFF7B61FF),
      isPositive: true,
    ),
  ];
}

class _InvoiceRowData {
  const _InvoiceRowData({
    required this.numero,
    required this.monto,
    required this.estado,
    required this.color,
  });

  final String numero;
  final String monto;
  final String estado;
  final Color color;

  static const List<_InvoiceRowData> samples = [
    _InvoiceRowData(
      numero: '001-001-000000843',
      monto: '\$260.00',
      estado: 'SRI Autorizado',
      color: Color(0xFF2ECC71),
    ),
    _InvoiceRowData(
      numero: '001-001-000000842',
      monto: '\$180.30',
      estado: 'Pendiente',
      color: Color(0xFFF5A524),
    ),
    _InvoiceRowData(
      numero: '001-001-000000841',
      monto: '\$150.00',
      estado: 'Rechazada',
      color: Color(0xFFFF5A5F),
    ),
  ];
}

class _ProductRowData {
  const _ProductRowData({
    required this.producto,
    required this.cantidad,
    required this.total,
  });

  final String producto;
  final String cantidad;
  final String total;

  static const List<_ProductRowData> samples = [
    _ProductRowData(
      producto: 'Registro Office',
      cantidad: '10.6k',
      total: '\$2,950.00',
    ),
    _ProductRowData(
      producto: 'Candener Pago',
      cantidad: '9.3k',
      total: '\$2,180.00',
    ),
    _ProductRowData(
      producto: 'Helados Ventos',
      cantidad: '5.1k',
      total: '\$1,950.00',
    ),
  ];
}
