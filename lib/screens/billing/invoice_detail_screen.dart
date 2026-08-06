import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../models/invoice_model.dart';
import '../../services/billing_service.dart';

class InvoiceDetailScreen extends StatefulWidget {
  final InvoiceModel invoice;
  final VoidCallback? onInvoiceUpdated;

  const InvoiceDetailScreen({
    super.key,
    required this.invoice,
    this.onInvoiceUpdated,
  });

  @override
  State<InvoiceDetailScreen> createState() => _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends State<InvoiceDetailScreen> {
  late InvoiceModel _invoice;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _invoice = widget.invoice;
  }

  Future<void> _refreshInvoice() async {
    if (_invoice.id == null) return;
    setState(() => _isLoading = true);
    final fresh = await BillingService.getInvoiceById(_invoice.id!);
    if (fresh != null && mounted) {
      setState(() {
        _invoice = fresh;
        _isLoading = false;
      });
      widget.onInvoiceUpdated?.call();
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Show E-Signature Modal ────────────────────────────────────────────────
  void _showSignatureDialog() {
    final nameCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Digital E-Signature Stamp'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Authorized Signer Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              height: 100,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.teal.shade300),
                borderRadius: BorderRadius.circular(8),
                color: Colors.teal.shade50,
              ),
              child: const Center(
                child: Text('✦ Digital Signature Stamp Approved ✦',
                    style: TextStyle(fontStyle: FontStyle.italic, color: Colors.teal, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              final signatureMock = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==";
              final ok = await BillingService.updateSignature(
                invoiceId: _invoice.id!,
                signatureData: signatureMock,
                signerName: nameCtrl.text.trim(),
              );
              if (ok) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('E-Signature Applied Successfully!')));
                _refreshInvoice();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
            child: const Text('Apply Signature'),
          ),
        ],
      ),
    );
  }

  // ── Show Process Payment Modal (RPC Workflow) ─────────────────────────────
  void _showPaymentDialog() {
    final amountCtrl = TextEditingController(text: _invoice.amountDue.toString());
    final refCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    String method = 'Bank Transfer';
    bool isProcessing = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: const Text('Record Invoice Payment'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Invoice #: ${_invoice.invoiceNumber}', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('Outstanding Balance: ₹${_invoice.amountDue.toStringAsFixed(2)}', style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 12),
                TextField(
                  controller: amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Payment Amount (₹)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: method,
                  decoration: const InputDecoration(labelText: 'Payment Method', border: OutlineInputBorder()),
                  items: ['Bank Transfer', 'UPI', 'Razorpay', 'E-Signature', 'manual']
                      .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                      .toList(),
                  onChanged: (val) => setModalState(() => method = val!),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: refCtrl,
                  decoration: const InputDecoration(labelText: 'Txn / Reference Number', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesCtrl,
                  decoration: const InputDecoration(labelText: 'Payment Notes', border: OutlineInputBorder()),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: isProcessing
                  ? null
                  : () async {
                      final payAmount = double.tryParse(amountCtrl.text) ?? 0.0;
                      if (payAmount <= 0) return;

                      setModalState(() => isProcessing = true);
                      final res = await BillingService.processInvoicePayment(
                        invoiceId: _invoice.id!,
                        orgId: _invoice.organizationId ?? '',
                        amount: payAmount,
                        method: method,
                        transactionId: refCtrl.text.trim(),
                        notes: notesCtrl.text.trim(),
                      );
                      Navigator.pop(ctx);
                      if (res['success'] == true) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Payment processed! New Status: ${res['new_status']}')),
                        );
                        _refreshInvoice();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Payment failed: ${res['error']}'), backgroundColor: Colors.red),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
              child: isProcessing ? const CircularProgressIndicator(color: Colors.white) : const Text('Process Payment'),
            ),
          ],
        ),
      ),
    );
  }

  // ── PDF Document Generation ───────────────────────────────────────────────
  Future<void> _exportPdf() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context ctx) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(20),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('ECRAFTZ CRM', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.teal)),
                    pw.Text(_invoice.documentType.toUpperCase(), style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
                pw.Divider(thickness: 2),
                pw.SizedBox(height: 10),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Billed To:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.Text(_invoice.clientName ?? 'Client'),
                        pw.Text('Place of Supply: State ${_invoice.placeOfSupply ?? "32"}'),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('Invoice #: ${_invoice.invoiceNumber}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.Text('Issued: ${DateFormat('dd MMM yyyy').format(_invoice.issuedAt)}'),
                        pw.Text('Due Date: ${DateFormat('dd MMM yyyy').format(_invoice.dueDate)}'),
                        pw.Text('Status: ${_invoice.status.toUpperCase()}'),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 20),
                pw.TableHelper.fromTextArray(
                  headers: ['Item Description', 'HSN/SAC', 'Qty', 'Unit Price', 'Total'],
                  data: _invoice.items.map((item) {
                    return [
                      item.itemName,
                      item.hsnSac ?? '998314',
                      item.quantity.toString(),
                      'INR ${item.unitPrice.toStringAsFixed(2)}',
                      'INR ${item.totalAmount.toStringAsFixed(2)}',
                    ];
                  }).toList(),
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                  headerDecoration: const pw.BoxDecoration(color: PdfColors.teal),
                ),
                pw.SizedBox(height: 15),
                pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Subtotal: INR ${_invoice.amount.toStringAsFixed(2)}'),
                      pw.Text('GST Tax: INR ${_invoice.taxAmount.toStringAsFixed(2)}'),
                      pw.Text('Grand Total: INR ${_invoice.grandTotal.toStringAsFixed(2)}',
                          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                      pw.Text('Amount Paid: INR ${_invoice.amountPaid.toStringAsFixed(2)}'),
                      pw.Text('Amount Due: INR ${_invoice.amountDue.toStringAsFixed(2)}',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.red)),
                    ],
                  ),
                ),
                if (_invoice.signerName != null) ...[
                  pw.SizedBox(height: 30),
                  pw.Text('Authorized Signature: ${_invoice.signerName}', style: pw.TextStyle(fontStyle: pw.FontStyle.italic)),
                  pw.Text('Signed At: ${DateFormat('dd MMM yyyy HH:mm').format(_invoice.signedAt ?? DateTime.now())}'),
                ]
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: '${_invoice.invoiceNumber}.pdf',
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return Colors.green;
      case 'partially_paid':
        return Colors.orange;
      case 'overdue':
        return Colors.red;
      case 'sent':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_invoice.invoiceNumber, style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.print_outlined),
            onPressed: _exportPdf,
            tooltip: 'Export & Print PDF',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshInvoice,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status Banner
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _getStatusColor(_invoice.status).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _getStatusColor(_invoice.status)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.receipt_long, color: _getStatusColor(_invoice.status)),
                              const SizedBox(width: 8),
                              Text(
                                '${_invoice.documentType} • ${_invoice.status.toUpperCase()}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _getStatusColor(_invoice.status),
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            'Due: ${DateFormat('dd MMM yyyy').format(_invoice.dueDate)}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Client & Invoice Metadata Card
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Invoice Metadata', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            const Divider(height: 20),
                            _buildMetaRow('Client Name:', _invoice.clientName ?? 'Unknown Client'),
                            _buildMetaRow('Issued Date:', DateFormat('dd MMM yyyy').format(_invoice.issuedAt)),
                            _buildMetaRow('Place of Supply Code:', _invoice.placeOfSupply ?? '32'),
                            _buildMetaRow('Terms:', _invoice.terms),
                            if (_invoice.notes != null && _invoice.notes!.isNotEmpty)
                              _buildMetaRow('Notes:', _invoice.notes!),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Line Items Section
                    const Text('Deliverable Items', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),

                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          children: _invoice.items.isEmpty
                              ? [const Padding(padding: EdgeInsets.all(16), child: Text('No itemized deliverables found.'))]
                              : _invoice.items.map((item) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    decoration: const BoxDecoration(
                                      border: Border(bottom: BorderSide(color: Colors.black12)),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(item.itemName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                              if (item.description != null)
                                                Text(item.description!, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                              Text('HSN/SAC: ${item.hsnSac ?? "998314"} | Qty: ${item.quantity}',
                                                  style: const TextStyle(fontSize: 12)),
                                            ],
                                          ),
                                        ),
                                        Text('₹${item.totalAmount.toStringAsFixed(2)}',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                      ],
                                    ),
                                  );
                                }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Financial Summary Card
                    Card(
                      elevation: 2,
                      color: Colors.teal.shade50,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            _buildSummaryRow('Subtotal (Taxable):', '₹${_invoice.amount.toStringAsFixed(2)}'),
                            _buildSummaryRow('GST Tax Amount:', '₹${_invoice.taxAmount.toStringAsFixed(2)}'),
                            if (_invoice.roundOff != 0)
                              _buildSummaryRow('Round Off:', '₹${_invoice.roundOff.toStringAsFixed(2)}'),
                            const Divider(height: 20),
                            _buildSummaryRow('Grand Total:', '₹${_invoice.grandTotal.toStringAsFixed(2)}', isBold: true),
                            _buildSummaryRow('Amount Paid:', '₹${_invoice.amountPaid.toStringAsFixed(2)}', color: Colors.green),
                            _buildSummaryRow('Amount Due:', '₹${_invoice.amountDue.toStringAsFixed(2)}', isBold: true, color: Colors.red),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // E-Signature Stamp Card
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('E-Signature Verification', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                ElevatedButton.icon(
                                  onPressed: _showSignatureDialog,
                                  icon: const Icon(Icons.draw, size: 18),
                                  label: const Text('Sign Screen'),
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (_invoice.signerName != null) ...[
                              Text('Signed by: ${_invoice.signerName}', style: const TextStyle(fontWeight: FontWeight.bold)),
                              Text('Date: ${DateFormat('dd MMM yyyy HH:mm').format(_invoice.signedAt ?? DateTime.now())}',
                                  style: const TextStyle(color: Colors.grey)),
                            ] else
                              const Text('Pending digital signature stamp from client / admin.',
                                  style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Action Buttons (Record Payment)
                    if (_invoice.status != 'paid')
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: _showPaymentDialog,
                          icon: const Icon(Icons.payment),
                          label: const Text('Record Payment (RPC Flow)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal.shade700,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildMetaRow(String label, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 140, child: Text(label, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500))),
          Expanded(child: Text(val, style: const TextStyle(fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String val, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: isBold ? 16 : 14)),
          Text(val, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.w600, fontSize: isBold ? 16 : 14, color: color)),
        ],
      ),
    );
  }
}
