import '../repositories/product_repository.dart';
import '../repositories/invoice_repository.dart';

class PosController {
  final ProductRepository _productRepository = ProductRepository();
  final InvoiceRepository _invoiceRepository = InvoiceRepository();

  Future<List<Map<String, dynamic>>> loadStoreProducts(int storeId) async {
    return await _productRepository.getInventoryList(storeId);
  }

  Future<bool> handleCheckout({
    required int storeId,
    required int employeeId,
    required Map<int, int> cart,
    required List<Map<String, dynamic>> products,
    required double discountPercent,
    required double totalAmount,
  }) async {
    final List<Map<String, dynamic>> items = [];
    cart.forEach((productId, qty) {
      final prod = products.firstWhere((p) => p['ProductID'] == productId);
      final price = prod['SalePrice'] as double;
      final discount = price * qty * (discountPercent / 100);
      items.add({
        'ProductID': productId,
        'Quantity': qty,
        'UnitPrice': price,
        'PromotionID': discountPercent > 0 ? 2 : 1,
        'DiscountAmount': discount,
      });
    });

    return await _invoiceRepository.createInvoice(
      storeId: storeId,
      employeeId: employeeId,
      items: items,
      totalAmount: totalAmount,
    );
  }
}
