import '../entities/invoice_page.dart';

abstract class InvoicesRepository {
  Future<InvoicePage> fetchInvoices({
    required String token,
    int page = 1,
    int limit = 10,
    String search = '',
    int? paymentStatus,
  });
}
