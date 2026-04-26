import 'invoice.dart';

class InvoicePage {
  const InvoicePage({
    required this.invoices,
    required this.currentPage,
    required this.lastPage,
  });

  final List<Invoice> invoices;
  final int currentPage;
  final int lastPage;
}
