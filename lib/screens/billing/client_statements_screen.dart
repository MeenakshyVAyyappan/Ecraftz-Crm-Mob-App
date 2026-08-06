import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../models/invoice_model.dart';
import '../../services/billing_service.dart';
import '../../services/supabase_service.dart';

class ClientStatementsScreen extends StatefulWidget {
  final int? selectedIndex;
  final Function(int)? onItemSelected;

  const ClientStatementsScreen({
    super.key,
    this.selectedIndex,
    this.onItemSelected,
  });

  @override
  State<ClientStatementsScreen> createState() => _ClientStatementsScreenState();
}

class _ClientStatementsScreenState extends State<ClientStatementsScreen> {
  List<InvoiceModel> _invoices = [];
  List<Map<String, dynamic>> _clients = [];
  String? _selectedClientId;
  DateTime? _fromDate;
  DateTime? _toDate;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final invoices = await BillingService.getInvoices();
      final clientsData = await SupabaseService.client
          .from('clients')
          .select('id, name')
          .isFilter('deleted_at', null)
          .order('name');

      if (mounted) {
        setState(() {
          _invoices = invoices;
          _clients = (clientsData as List).map((e) => Map<String, dynamic>.from(e)).toList();
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<InvoiceModel> get _filteredInvoices {
    return _invoices.where((inv) {
      final matchClient = _selectedClientId == null || inv.clientId == _selectedClientId;
      final matchFrom = _fromDate == null || !inv.issuedAt.isBefore(_fromDate!);
      final matchTo = _toDate == null || !inv.issuedAt.isAfter(_toDate!);
      return matchClient && matchFrom && matchTo;
    }).toList();
  }

  // Summary Metrics (Page 8 Specification)
  double get _totalInvoiced => _filteredInvoices
      .where((i) => i.status.toLowerCase() != 'draft' && i.status.toLowerCase() != 'cancelled')
      .fold(0.0, (sum, i) => sum + i.effectiveGrandTotal);

  double get _totalCollected => _filteredInvoices
      .where((i) => i.status.toLowerCase() != 'cancelled')
      .fold(0.0, (sum, i) => sum + i.effectiveAmountPaid);

  double get _balanceOutstanding => _totalInvoiced - _totalCollected;
  double get _overdueAmount => _filteredInvoices
      .where((i) => i.status == 'overdue' || i.dueDate.isBefore(DateTime.now()))
      .fold(0.0, (sum, i) => sum + i.amountDue);

  Future<void> _exportLedgerPdf() async {
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
                pw.Text('CLIENT ACCOUNT LEDGER STATEMENT', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.teal)),
                pw.SizedBox(height: 10),
                pw.Text('Generated: ${DateFormat("dd MMM yyyy HH:mm").format(DateTime.now())}'),
                pw.Divider(),
                pw.SizedBox(height: 10),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Total Invoiced: INR ${_totalInvoiced.toStringAsFixed(2)}'),
                    pw.Text('Total Collected: INR ${_totalCollected.toStringAsFixed(2)}'),
                  ],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Outstanding Balance: INR ${_balanceOutstanding.toStringAsFixed(2)}'),
                    pw.Text('Overdue Amount: INR ${_overdueAmount.toStringAsFixed(2)}'),
                  ],
                ),
                pw.SizedBox(height: 20),
                pw.TableHelper.fromTextArray(
                  headers: ['Invoice #', 'Date', 'Client', 'Status', 'Grand Total', 'Paid', 'Balance'],
                  data: _filteredInvoices.map((inv) {
                    return [
                      inv.invoiceNumber,
                      DateFormat('dd/MM/yyyy').format(inv.issuedAt),
                      inv.clientName ?? 'Client',
                      inv.status.toUpperCase(),
                      'INR ${inv.grandTotal.toStringAsFixed(2)}',
                      'INR ${inv.amountPaid.toStringAsFixed(2)}',
                      'INR ${inv.amountDue.toStringAsFixed(2)}',
                    ];
                  }).toList(),
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                  headerDecoration: const pw.BoxDecoration(color: PdfColors.teal),
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'Client_Ledger_Statement.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Client Account Ledger', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _exportLedgerPdf,
            tooltip: 'Export Statement PDF',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: RefreshIndicator(
                onRefresh: _loadData,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Filter Options Card
                      Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Filter Ledger Options', style: TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String?>(
                                value: _selectedClientId,
                                decoration: const InputDecoration(labelText: 'Filter by Client', border: OutlineInputBorder(), isDense: true),
                                items: [
                                  const DropdownMenuItem<String?>(value: null, child: Text('All Clients')),
                                  ..._clients.map((c) => DropdownMenuItem<String?>(value: c['id'].toString(), child: Text(c['name'].toString()))),
                                ],
                                onChanged: (val) => setState(() => _selectedClientId = val),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 4 Summary Metric Cards (Specification Page 8)
                      LayoutBuilder(builder: (context, constraints) {
                        bool isWide = constraints.maxWidth > 500;
                        return isWide
                            ? Row(
                                children: [
                                  Expanded(child: _buildMetricCard('Total Invoiced', '₹${_totalInvoiced.toStringAsFixed(2)}', Colors.blue)),
                                  const SizedBox(width: 8),
                                  Expanded(child: _buildMetricCard('Total Collected', '₹${_totalCollected.toStringAsFixed(2)}', Colors.green)),
                                  const SizedBox(width: 8),
                                  Expanded(child: _buildMetricCard('Outstanding', '₹${_balanceOutstanding.toStringAsFixed(2)}', Colors.orange)),
                                  const SizedBox(width: 8),
                                  Expanded(child: _buildMetricCard('Overdue Amount', '₹${_overdueAmount.toStringAsFixed(2)}', Colors.red)),
                                ],
                              )
                            : Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(child: _buildMetricCard('Total Invoiced', '₹${_totalInvoiced.toStringAsFixed(2)}', Colors.blue)),
                                      const SizedBox(width: 8),
                                      Expanded(child: _buildMetricCard('Total Collected', '₹${_totalCollected.toStringAsFixed(2)}', Colors.green)),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(child: _buildMetricCard('Outstanding', '₹${_balanceOutstanding.toStringAsFixed(2)}', Colors.orange)),
                                      const SizedBox(width: 8),
                                      Expanded(child: _buildMetricCard('Overdue Amount', '₹${_overdueAmount.toStringAsFixed(2)}', Colors.red)),
                                    ],
                                  ),
                                ],
                              );
                      }),
                      const SizedBox(height: 16),

                      // Invoices Table / List
                      const Text('Ledger Transactions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),

                      _filteredInvoices.isEmpty
                          ? const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('No ledger records match filters.')))
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _filteredInvoices.length,
                              itemBuilder: (context, index) {
                                final inv = _filteredInvoices[index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    title: Text('${inv.invoiceNumber} - ${inv.clientName ?? "Client"}',
                                        style: const TextStyle(fontWeight: FontWeight.bold)),
                                    subtitle: Text('Issued: ${DateFormat("dd MMM yyyy").format(inv.issuedAt)} | Due: ${DateFormat("dd MMM yyyy").format(inv.dueDate)}'),
                                    trailing: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text('₹${inv.grandTotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                        Text('Due: ₹${inv.amountDue.toStringAsFixed(2)}',
                                            style: TextStyle(color: inv.amountDue > 0 ? Colors.red : Colors.green, fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildMetricCard(String title, String value, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey), overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
            ),
          ],
        ),
      ),
    );
  }
}
