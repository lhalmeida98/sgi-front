import 'factura.dart';

class FacturaPage {
  FacturaPage({
    required this.items,
    required this.page,
    required this.size,
    required this.totalItems,
    required this.totalPages,
  });

  final List<Factura> items;
  final int page;
  final int size;
  final int totalItems;
  final int totalPages;
}
