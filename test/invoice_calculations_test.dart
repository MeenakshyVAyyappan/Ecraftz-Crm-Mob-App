import 'package:flutter_test/flutter_test.dart';
import 'package:ecraftz_crm/models/billing_model.dart';

void main() {
  group('Invoice Financial Calculations', () {
    test('InvoiceItem calculations (CGST + SGST)', () {
      final item = InvoiceItem(
        description: 'SEO Optimization',
        quantity: 2,
        unitPrice: 10000,
        discountAmount: 1000,
        cgstAmount: 1710,
        sgstAmount: 1710,
      );

      expect(item.subtotal, 20000.0);
      expect(item.calculatedTaxable, 19000.0);
      expect(item.cgstRate, 9.0);
      expect(item.sgstRate, 9.0);
      expect(item.taxAmount, 3420.0);
      expect(item.total, 22420.0);
    });

    test('Invoice calculations with multiple items', () {
      final item1 = InvoiceItem(
        description: 'Web Design',
        quantity: 1,
        unitPrice: 15000,
        discountAmount: 0,
        cgstAmount: 1350,
        sgstAmount: 1350,
      );

      final item2 = InvoiceItem(
        description: 'Hosting',
        quantity: 1,
        unitPrice: 5000,
        discountAmount: 500,
        cgstAmount: 405,
        sgstAmount: 405,
      );

      final invoice = Invoice(
        id: 'inv-101',
        invoiceNumber: '26/27/121',
        clientName: 'MUBARAK CURTAINS',
        clientEntity: 'SEO ADVANCE',
        status: InvoiceStatus.paid,
        issuedDate: DateTime.parse('2026-07-25'),
        dueDate: DateTime.parse('2026-07-25'),
        items: [item1, item2],
      );

      expect(invoice.subtotal, 20000.0);
      expect(invoice.totalDiscount, 500.0);
      expect(invoice.taxableValue, 19500.0);
      expect(invoice.totalCgst, 1755.0);
      expect(invoice.totalSgst, 1755.0);
      expect(invoice.totalTax, 3510.0);
      expect(invoice.grossAmount, 23010.0);
      expect(invoice.amountPaid, 23010.0);
      expect(invoice.amountDue, 0.0);
    });

    test('Invoice status sent amount due calculation', () {
      final item = InvoiceItem(
        description: 'App Development',
        quantity: 1,
        unitPrice: 50000,
        discountAmount: 0,
        cgstAmount: 4500,
        sgstAmount: 4500,
      );

      final invoice = Invoice(
        id: 'inv-102',
        invoiceNumber: '26/27/122',
        clientName: 'Test Client',
        clientEntity: 'App Project',
        status: InvoiceStatus.sent,
        issuedDate: DateTime.parse('2026-07-25'),
        dueDate: DateTime.parse('2026-08-10'),
        items: [item],
      );

      expect(invoice.grossAmount, 59000.0);
      expect(invoice.amountPaid, 0.0);
      expect(invoice.amountDue, 59000.0);
    });
  });
}
