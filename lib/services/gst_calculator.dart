class GSTBreakdown {
  final double taxableAmount;
  final double cgstAmount;
  final double sgstAmount;
  final double igstAmount;
  final double totalTax;
  final double grandTotal;
  final bool isInterState;

  GSTBreakdown({
    required this.taxableAmount,
    required this.cgstAmount,
    required this.sgstAmount,
    required this.igstAmount,
    required this.totalTax,
    required this.grandTotal,
    required this.isInterState,
  });
}

class GSTCalculator {
  static GSTBreakdown calculate({
    required List<Map<String, dynamic>> items,
    required String sellerStateCode,
    required String buyerStateCode,
  }) {
    final bool isInterState = (sellerStateCode != buyerStateCode) ||
        sellerStateCode.isEmpty ||
        buyerStateCode.isEmpty;
    double taxable = 0.0;
    double cgst = 0.0;
    double sgst = 0.0;
    double igst = 0.0;

    for (var item in items) {
      double qty = (item['quantity'] ?? 1).toDouble();
      double price = (item['unit_price'] ?? 0).toDouble();
      double discount = (item['discount_amount'] ?? 0).toDouble();
      double rate = (item['gst_rate'] ?? 0).toDouble();

      double lineTaxable = (qty * price) - discount;
      taxable += lineTaxable;

      if (isInterState) {
        igst += (lineTaxable * rate) / 100.0;
      } else {
        cgst += (lineTaxable * (rate / 2.0)) / 100.0;
        sgst += (lineTaxable * (rate / 2.0)) / 100.0;
      }
    }

    double totalTax = cgst + sgst + igst;
    return GSTBreakdown(
      taxableAmount: taxable,
      cgstAmount: cgst,
      sgstAmount: sgst,
      igstAmount: igst,
      totalTax: totalTax,
      grandTotal: taxable + totalTax,
      isInterState: isInterState,
    );
  }
}
