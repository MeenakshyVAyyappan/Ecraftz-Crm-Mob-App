import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/billing_model.dart';

class InvoicePdfGenerator {
  static Future<Uint8List> buildInvoicePdfBytes(Invoice inv, GstProfile profile) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Company Header
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  width: 45,
                  height: 45,
                  decoration: pw.BoxDecoration(
                    color: PdfColors.blueGrey900,
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Center(
                    child: pw.Text(
                      'E',
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                pw.SizedBox(width: 14),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        profile.legalName.isNotEmpty
                            ? profile.legalName
                            : 'Ecraftz Info Solutions LLP',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blueGrey900,
                        ),
                      ),
                      pw.Text(
                        profile.address.isNotEmpty
                            ? profile.address
                            : 'Ecraftz, A9, First floor, NV Tower, M20/265, Kallai, Kozhikode, Kerala 673003',
                        style: const pw.TextStyle(
                            fontSize: 9, color: PdfColors.grey700),
                      ),
                    ],
                  ),
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('UK | UAE | INDIA',
                        style: const pw.TextStyle(
                            fontSize: 9, color: PdfColors.grey800)),
                    pw.Text(profile.website.isNotEmpty ? profile.website : 'www.vbecraftz.com',
                        style: const pw.TextStyle(
                            fontSize: 9, color: PdfColors.grey700)),
                    pw.Text(profile.email.isNotEmpty ? profile.email : 'mail@ecraftz.in',
                        style: const pw.TextStyle(
                            fontSize: 9, color: PdfColors.grey700)),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 14),
            pw.Divider(color: PdfColors.grey300),
            pw.SizedBox(height: 10),

            // Meta bar
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Invoice #: ${inv.invoiceNumber}',
                    style: pw.TextStyle(
                        fontSize: 11, fontWeight: pw.FontWeight.bold)),
                pw.Text('Place Of Supply: ${inv.placeOfSupply ?? "32"}',
                    style: pw.TextStyle(
                        fontSize: 11, fontWeight: pw.FontWeight.bold)),
              ],
            ),
            pw.Text(
                'Invoice Date: ${DateFormat("dd-MM-yyyy").format(inv.issuedDate)}',
                style: const pw.TextStyle(fontSize: 10)),
            pw.SizedBox(height: 14),

            // Billed By / To Box
            pw.Container(
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Column(
                children: [
                  pw.Container(
                    color: PdfColors.grey200,
                    padding: const pw.EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    child: pw.Row(
                      children: [
                        pw.Expanded(
                            child: pw.Text('BILLED BY',
                                style: pw.TextStyle(
                                    fontSize: 9,
                                    fontWeight: pw.FontWeight.bold))),
                        pw.Expanded(
                            child: pw.Text('BILLED TO',
                                style: pw.TextStyle(
                                    fontSize: 9,
                                    fontWeight: pw.FontWeight.bold))),
                      ],
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(12),
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('Ecraftz Info Solutions LLP',
                                  style: pw.TextStyle(
                                      fontSize: 10,
                                      fontWeight: pw.FontWeight.bold)),
                              pw.Text(
                                  profile.address.isNotEmpty
                                      ? profile.address
                                      : 'Ecraftz, A9, First floor, NV Tower, Kallai, Kozhikode 673003',
                                  style: const pw.TextStyle(
                                      fontSize: 8, color: PdfColors.grey700),
                                ),
                              pw.Text(
                                'GSTIN: ${profile.gstin.isNotEmpty ? profile.gstin : "32AAYFE1819K1Z4"}',
                                style: pw.TextStyle(
                                    fontSize: 8,
                                    fontWeight: pw.FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        pw.SizedBox(width: 12),
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                inv.clientName.isNotEmpty
                                    ? inv.clientName
                                    : 'CLIENT NAME',
                                style: pw.TextStyle(
                                    fontSize: 10,
                                    fontWeight: pw.FontWeight.bold),
                              ),
                              pw.Text(
                                inv.clientAddress?.isNotEmpty == true
                                    ? inv.clientAddress!
                                    : 'INDIA',
                                style: const pw.TextStyle(
                                    fontSize: 8, color: PdfColors.grey700),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 14),

            // Itemized Table
            pw.TableHelper.fromTextArray(
              border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
              headerStyle: pw.TextStyle(
                  fontSize: 8, fontWeight: pw.FontWeight.bold),
              cellStyle: const pw.TextStyle(fontSize: 8),
              headerDecoration:
                  const pw.BoxDecoration(color: PdfColors.grey200),
              headers: [
                'S.No',
                'Description',
                'HSN/SAC',
                'Unit',
                'Rate',
                'Disc',
                'SGST %',
                'SGST Amt',
                'CGST %',
                'CGST Amt',
                'Net Amt'
              ],
              data: inv.items.asMap().entries.map((e) {
                final idx = e.key + 1;
                final item = e.value;
                return [
                  '$idx',
                  item.description,
                  item.hsnSac ?? '-',
                  item.category ?? 'Nos',
                  item.unitPrice.toStringAsFixed(2),
                  item.discountAmount > 0
                      ? item.discountAmount.toStringAsFixed(0)
                      : '0.0%',
                  '${item.sgstRate.toStringAsFixed(1)}%',
                  item.sgstAmount.toStringAsFixed(2),
                  '${item.cgstRate.toStringAsFixed(1)}%',
                  item.cgstAmount.toStringAsFixed(2),
                  item.total.toStringAsFixed(2),
                ];
              }).toList(),
            ),

            pw.SizedBox(height: 16),

            // Totals and Bank Details
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  flex: 6,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('TOTAL IN WORDS:',
                          style: pw.TextStyle(
                              fontSize: 8, fontWeight: pw.FontWeight.bold)),
                      pw.Text(_numberToWordsIndian(inv.grossAmount),
                          style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                              fontStyle: pw.FontStyle.italic)),
                      pw.SizedBox(height: 14),
                      pw.Text('BANK ACCOUNT DETAILS:',
                          style: pw.TextStyle(
                              fontSize: 8, fontWeight: pw.FontWeight.bold)),
                      pw.Text('Company: ECRAFTZ TECHNOLOGIES PVT LTD',
                          style: const pw.TextStyle(fontSize: 8)),
                      pw.Text('Account No: 751405500282',
                          style: const pw.TextStyle(fontSize: 8)),
                      pw.Text('IFSC Code: ICIC0007514',
                          style: const pw.TextStyle(fontSize: 8)),
                      pw.Text('Bank: ICICI Bank (ICIC1)',
                          style: const pw.TextStyle(fontSize: 8)),
                      pw.Text('Branch: Calicut, Medical College',
                          style: const pw.TextStyle(fontSize: 8)),
                    ],
                  ),
                ),
                pw.SizedBox(width: 16),
                pw.Expanded(
                  flex: 4,
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey300),
                    ),
                    child: pw.Column(
                      children: [
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Sub Total',
                                style: const pw.TextStyle(fontSize: 8)),
                            pw.Text(inv.subtotal.toStringAsFixed(2),
                                style: const pw.TextStyle(fontSize: 8)),
                          ],
                        ),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(
                                'CGST (${(inv.items.firstOrNull?.cgstRate ?? 0.0).toStringAsFixed(1)}%)',
                                style: const pw.TextStyle(fontSize: 8)),
                            pw.Text(inv.totalCgst.toStringAsFixed(2),
                                style: const pw.TextStyle(fontSize: 8)),
                          ],
                        ),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(
                                'SGST (${(inv.items.firstOrNull?.sgstRate ?? 0.0).toStringAsFixed(1)}%)',
                                style: const pw.TextStyle(fontSize: 8)),
                            pw.Text(inv.totalSgst.toStringAsFixed(2),
                                style: const pw.TextStyle(fontSize: 8)),
                          ],
                        ),
                        pw.Divider(color: PdfColors.grey400),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Total',
                                style: pw.TextStyle(
                                    fontSize: 10,
                                    fontWeight: pw.FontWeight.bold)),
                            pw.Text('₹${inv.grossAmount.toStringAsFixed(2)}',
                                style: pw.TextStyle(
                                    fontSize: 10,
                                    fontWeight: pw.FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            pw.Spacer(),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Column(
                children: [
                  pw.Container(width: 120, height: 0.5, color: PdfColors.grey700),
                  pw.SizedBox(height: 2),
                  pw.Text('Authorized Signature',
                      style: pw.TextStyle(
                          fontSize: 8, fontWeight: pw.FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    return pdf.save();
  }

  static String _numberToWordsIndian(double amount) {
    final int val = amount.round();
    if (val <= 0) return 'Rupees Zero Only';

    final units = [
      '', 'One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven', 'Eight', 'Nine',
      'Ten', 'Eleven', 'Twelve', 'Thirteen', 'Fourteen', 'Fifteen', 'Sixteen',
      'Seventeen', 'Eighteen', 'Nineteen'
    ];
    final tens = [
      '', '', 'Twenty', 'Thirty', 'Forty', 'Fifty', 'Sixty', 'Seventy', 'Eighty', 'Ninety'
    ];

    String convertBelowThousand(int n) {
      if (n == 0) return '';
      if (n < 20) return units[n];
      if (n < 100) {
        final t = tens[n ~/ 10];
        final u = units[n % 10];
        return u.isEmpty ? t : '$t $u';
      }
      final h = units[n ~/ 100];
      final rem = convertBelowThousand(n % 100);
      return rem.isEmpty ? '$h Hundred' : '$h Hundred $rem';
    }

    int temp = val;
    int crore = temp ~/ 10000000;
    temp %= 10000000;
    int lakh = temp ~/ 100000;
    temp %= 100000;
    int thousand = temp ~/ 1000;
    temp %= 1000;
    int remainder = temp;

    List<String> parts = [];
    if (crore > 0) parts.add('${convertBelowThousand(crore)} Crore');
    if (lakh > 0) parts.add('${convertBelowThousand(lakh)} Lakh');
    if (thousand > 0) parts.add('${convertBelowThousand(thousand)} Thousand');
    if (remainder > 0) parts.add(convertBelowThousand(remainder));

    return 'Rupees ${parts.join(' ')} Only';
  }

  static Future<void> printInvoice(Invoice inv, GstProfile profile) async {
    try {
      final pdfBytes = await buildInvoicePdfBytes(inv, profile);
      await Printing.layoutPdf(
        onLayout: (_) async => pdfBytes,
        name: 'Invoice_${inv.invoiceNumber}',
      );
    } catch (e) {
      debugPrint('Error printing/saving invoice: $e');
    }
  }
}
