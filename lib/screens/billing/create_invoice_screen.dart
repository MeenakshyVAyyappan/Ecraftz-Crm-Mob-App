import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/invoice_model.dart';
import '../../models/invoice_item_model.dart';
import '../../services/billing_service.dart';
import '../../services/gst_calculator.dart';
import '../../services/supabase_service.dart';

class CreateInvoiceScreen extends StatefulWidget {
  final VoidCallback? onInvoiceCreated;
  const CreateInvoiceScreen({super.key, this.onInvoiceCreated});

  @override
  State<CreateInvoiceScreen> createState() => _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends State<CreateInvoiceScreen> {
  final _formKey = GlobalKey<FormState>();

  String _documentType = 'Tax Invoice';
  String _invoiceNumber = '';
  String? _selectedClientId;
  String? _selectedClientName;
  String _sellerStateCode = '32'; // Default Kerala
  String _buyerStateCode = '32';  // Default Kerala
  DateTime _issuedAt = DateTime.now();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 15));
  String _notes = '';
  String _terms = 'Payment due within 15 days of invoice date.';
  double _roundOff = 0.0;
  bool _isRecurring = false;
  String _frequency = 'monthly';

  final List<Map<String, dynamic>> _lineItems = [
    {
      'item_name': 'Web Development Services',
      'description': 'Custom UI/UX & API Integration',
      'hsn_sac': '998314',
      'quantity': 1.0,
      'unit_price': 15000.0,
      'discount_amount': 0.0,
      'gst_rate': 18.0,
    }
  ];

  List<Map<String, dynamic>> _clients = [];
  bool _isLoadingClients = true;
  bool _isSubmitting = false;

  final List<String> _documentTypes = [
    'Tax Invoice',
    'GST Invoice',
    'Proforma Invoice',
    'Estimate',
    'Credit Note',
    'Normal Invoice',
  ];

  final List<String> _indianStates = [
    '32 - Kerala',
    '33 - Tamil Nadu',
    '29 - Karnataka',
    '27 - Maharashtra',
    '07 - Delhi',
    '09 - Uttar Pradesh',
    '19 - West Bengal',
    '36 - Telangana',
  ];

  @override
  void initState() {
    super.initState();
    _fetchClientsAndInvoiceNum();
  }

  Future<void> _fetchClientsAndInvoiceNum() async {
    try {
      final num = await BillingService.generateNextInvoiceNumber();
      final clientsData = await SupabaseService.client
          .from('clients')
          .select('id, name, email, place_of_supply, gstin')
          .isFilter('deleted_at', null)
          .order('name');

      if (mounted) {
        setState(() {
          _invoiceNumber = num;
          _clients = (clientsData as List).map((e) => Map<String, dynamic>.from(e)).toList();
          if (_clients.isNotEmpty) {
            _selectedClientId = _clients.first['id'].toString();
            _selectedClientName = _clients.first['name'].toString();
            final pos = _clients.first['place_of_supply']?.toString() ??
                _clients.first['gstin']?.toString().substring(0, 2);
            if (pos != null && pos.isNotEmpty) {
              _buyerStateCode = pos;
            }
          }
          _isLoadingClients = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingClients = false);
      }
    }
  }

  GSTBreakdown get _taxBreakdown {
    return GSTCalculator.calculate(
      items: _lineItems,
      sellerStateCode: _sellerStateCode.split(' ')[0],
      buyerStateCode: _buyerStateCode.split(' ')[0],
    );
  }

  void _addItem() {
    setState(() {
      _lineItems.add({
        'item_name': 'New Deliverable',
        'description': '',
        'hsn_sac': '998314',
        'quantity': 1.0,
        'unit_price': 1000.0,
        'discount_amount': 0.0,
        'gst_rate': 18.0,
      });
    });
  }

  void _removeItem(int index) {
    if (_lineItems.length > 1) {
      setState(() {
        _lineItems.removeAt(index);
      });
    }
  }

  Future<void> _submitInvoice() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedClientId == null || _selectedClientId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a client')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final breakdown = _taxBreakdown;
      final finalGrandTotal = (breakdown.grandTotal + _roundOff);

      final invoiceModel = InvoiceModel(
        clientId: _selectedClientId!,
        clientName: _selectedClientName,
        documentType: _documentType,
        invoiceNumber: _invoiceNumber,
        amount: breakdown.taxableAmount,
        taxRate: _lineItems.first['gst_rate'] ?? 18.0,
        taxAmount: breakdown.totalTax,
        roundOff: _roundOff,
        grandTotal: finalGrandTotal > 0 ? finalGrandTotal : 0.0,
        amountPaid: 0.0,
        amountDue: finalGrandTotal > 0 ? finalGrandTotal : 0.0,
        isRecurring: _isRecurring,
        frequency: _isRecurring ? _frequency : null,
        status: 'draft',
        placeOfSupply: _buyerStateCode.split(' ')[0],
        notes: _notes,
        terms: _terms,
        dueDate: _dueDate,
        issuedAt: _issuedAt,
      );

      final itemModels = _lineItems.map((item) {
        final qty = (item['quantity'] ?? 1.0).toDouble();
        final price = (item['unit_price'] ?? 0.0).toDouble();
        final discount = (item['discount_amount'] ?? 0.0).toDouble();
        final rate = (item['gst_rate'] ?? 18.0).toDouble();
        final lineTaxable = (qty * price) - discount;
        final isInter = breakdown.isInterState;

        final cgst = isInter ? 0.0 : (lineTaxable * (rate / 2.0)) / 100.0;
        final sgst = isInter ? 0.0 : (lineTaxable * (rate / 2.0)) / 100.0;
        final igst = isInter ? (lineTaxable * rate) / 100.0 : 0.0;
        final total = lineTaxable + cgst + sgst + igst;

        return InvoiceItemModel(
          itemName: item['item_name']?.toString() ?? 'Item',
          description: item['description']?.toString(),
          hsnSac: item['hsn_sac']?.toString(),
          quantity: qty,
          unitPrice: price,
          discountAmount: discount,
          gstRate: rate,
          cgstAmount: cgst,
          sgstAmount: sgst,
          igstAmount: igst,
          totalAmount: total,
        );
      }).toList();

      final result = await BillingService.createInvoice(
        invoice: invoiceModel,
        items: itemModels,
      );

      if (mounted) {
        setState(() => _isSubmitting = false);
        if (result != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Invoice ${_invoiceNumber} created successfully!')),
          );
          widget.onInvoiceCreated?.call();
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating invoice: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final breakdown = _taxBreakdown;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Invoice', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: _isLoadingClients
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Card
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Document & Client Header',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 12),

                              // Document Type & Number
                              LayoutBuilder(builder: (context, constraints) {
                                bool isWide = constraints.maxWidth > 500;
                                return isWide
                                    ? Row(
                                        children: [
                                          Expanded(child: _buildDocTypeDropdown()),
                                          const SizedBox(width: 12),
                                          Expanded(child: _buildInvoiceNumberField()),
                                        ],
                                      )
                                    : Column(
                                        children: [
                                          _buildDocTypeDropdown(),
                                          const SizedBox(height: 12),
                                          _buildInvoiceNumberField(),
                                        ],
                                      );
                              }),
                              const SizedBox(height: 12),

                              // Client Selector
                              DropdownButtonFormField<String>(
                                value: _selectedClientId,
                                decoration: const InputDecoration(
                                  labelText: 'Select Client *',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.business_outlined),
                                ),
                                items: _clients.map((c) {
                                  return DropdownMenuItem<String>(
                                    value: c['id'].toString(),
                                    child: Text(c['name'].toString(), overflow: TextOverflow.ellipsis),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  setState(() {
                                    _selectedClientId = val;
                                    final client = _clients.firstWhere((element) => element['id'].toString() == val);
                                    _selectedClientName = client['name']?.toString();
                                    final pos = client['place_of_supply']?.toString() ??
                                        client['gstin']?.toString().substring(0, 2);
                                    if (pos != null && pos.isNotEmpty) {
                                      _buyerStateCode = pos;
                                    }
                                  });
                                },
                              ),
                              const SizedBox(height: 12),

                              // State Codes for GST Resolution
                              LayoutBuilder(builder: (context, constraints) {
                                bool isWide = constraints.maxWidth > 500;
                                return isWide
                                    ? Row(
                                        children: [
                                          Expanded(child: _buildSellerStateDropdown()),
                                          const SizedBox(width: 12),
                                          Expanded(child: _buildBuyerStateDropdown()),
                                        ],
                                      )
                                    : Column(
                                        children: [
                                          _buildSellerStateDropdown(),
                                          const SizedBox(height: 12),
                                          _buildBuyerStateDropdown(),
                                        ],
                                      );
                              }),
                              const SizedBox(height: 12),

                              // Dates
                              LayoutBuilder(builder: (context, constraints) {
                                bool isWide = constraints.maxWidth > 500;
                                return isWide
                                    ? Row(
                                        children: [
                                          Expanded(child: _buildDatePickerTile('Issued Date', _issuedAt, (d) => setState(() => _issuedAt = d))),
                                          const SizedBox(width: 12),
                                          Expanded(child: _buildDatePickerTile('Due Date', _dueDate, (d) => setState(() => _dueDate = d))),
                                        ],
                                      )
                                    : Column(
                                        children: [
                                          _buildDatePickerTile('Issued Date', _issuedAt, (d) => setState(() => _issuedAt = d)),
                                          const SizedBox(height: 12),
                                          _buildDatePickerTile('Due Date', _dueDate, (d) => setState(() => _dueDate = d)),
                                        ],
                                      );
                              }),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Line Items Header & Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Itemized Deliverables', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          ElevatedButton.icon(
                            onPressed: _addItem,
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Add Item'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Line items list
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _lineItems.length,
                        itemBuilder: (context, index) => _buildLineItemCard(index),
                      ),
                      const SizedBox(height: 16),

                      // Tax & Total Summary Card
                      Card(
                        elevation: 2,
                        color: Colors.teal.shade50,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.calculate_outlined, color: Colors.teal),
                                  const SizedBox(width: 8),
                                  Text(
                                    breakdown.isInterState
                                        ? 'GST Calculation (Inter-State IGST)'
                                        : 'GST Calculation (Intra-State CGST + SGST)',
                                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.teal),
                                  ),
                                ],
                              ),
                              const Divider(height: 20),
                              _buildSummaryRow('Taxable Subtotal:', '₹${breakdown.taxableAmount.toStringAsFixed(2)}'),
                              if (!breakdown.isInterState) ...[
                                _buildSummaryRow('CGST Amount:', '₹${breakdown.cgstAmount.toStringAsFixed(2)}'),
                                _buildSummaryRow('SGST Amount:', '₹${breakdown.sgstAmount.toStringAsFixed(2)}'),
                              ] else ...[
                                _buildSummaryRow('IGST Amount:', '₹${breakdown.igstAmount.toStringAsFixed(2)}'),
                              ],
                              _buildSummaryRow('Total GST Tax:', '₹${breakdown.totalTax.toStringAsFixed(2)}'),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Round Off Adjustment:', style: TextStyle(fontSize: 14)),
                                  SizedBox(
                                    width: 90,
                                    child: TextFormField(
                                      initialValue: _roundOff.toString(),
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                                      decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
                                      onChanged: (val) => setState(() => _roundOff = double.tryParse(val) ?? 0.0),
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 20),
                              _buildSummaryRow(
                                'Grand Total:',
                                '₹${(breakdown.grandTotal + _roundOff).toStringAsFixed(2)}',
                                isBold: true,
                                fontSize: 18,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Notes & Terms
                      TextFormField(
                        initialValue: _terms,
                        decoration: const InputDecoration(labelText: 'Payment Terms', border: OutlineInputBorder()),
                        maxLines: 2,
                        onChanged: (val) => _terms = val,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        decoration: const InputDecoration(labelText: 'Additional Notes / Instructions', border: OutlineInputBorder()),
                        maxLines: 2,
                        onChanged: (val) => _notes = val,
                      ),
                      const SizedBox(height: 20),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _submitInvoice,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal.shade700,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: _isSubmitting
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text('Save & Create Invoice', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildDocTypeDropdown() {
    return DropdownButtonFormField<String>(
      value: _documentType,
      decoration: const InputDecoration(labelText: 'Document Type', border: OutlineInputBorder()),
      items: _documentTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
      onChanged: (val) => setState(() => _documentType = val!),
    );
  }

  Widget _buildInvoiceNumberField() {
    return TextFormField(
      initialValue: _invoiceNumber,
      decoration: const InputDecoration(labelText: 'Invoice Number', border: OutlineInputBorder()),
      onChanged: (val) => _invoiceNumber = val,
      validator: (val) => (val == null || val.isEmpty) ? 'Required' : null,
    );
  }

  Widget _buildSellerStateDropdown() {
    return DropdownButtonFormField<String>(
      value: _sellerStateCode,
      decoration: const InputDecoration(labelText: 'Seller State (Supply From)', border: OutlineInputBorder()),
      items: _indianStates.map((s) => DropdownMenuItem(value: s.split(' ')[0], child: Text(s))).toList(),
      onChanged: (val) => setState(() => _sellerStateCode = val!),
    );
  }

  Widget _buildBuyerStateDropdown() {
    return DropdownButtonFormField<String>(
      value: _buyerStateCode,
      decoration: const InputDecoration(labelText: 'Place of Supply (Buyer State)', border: OutlineInputBorder()),
      items: _indianStates.map((s) => DropdownMenuItem(value: s.split(' ')[0], child: Text(s))).toList(),
      onChanged: (val) => setState(() => _buyerStateCode = val!),
    );
  }

  Widget _buildDatePickerTile(String label, DateTime date, Function(DateTime) onPicked) {
    return InkWell(
      onTap: () async {
        final d = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
        );
        if (d != null) onPicked(d);
      },
      child: InputDecorator(
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        child: Text(DateFormat('dd MMM yyyy').format(date)),
      ),
    );
  }

  Widget _buildLineItemCard(int index) {
    final item = _lineItems[index];
    final qty = (item['quantity'] ?? 1.0).toDouble();
    final price = (item['unit_price'] ?? 0.0).toDouble();
    final discount = (item['discount_amount'] ?? 0.0).toDouble();
    final rate = (item['gst_rate'] ?? 18.0).toDouble();
    final lineTaxable = (qty * price) - discount;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: item['item_name'],
                    decoration: const InputDecoration(labelText: 'Item Name *', isDense: true),
                    onChanged: (val) => item['item_name'] = val,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _removeItem(index),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: item['description'],
              decoration: const InputDecoration(labelText: 'Description', isDense: true),
              onChanged: (val) => item['description'] = val,
            ),
            const SizedBox(height: 8),
            LayoutBuilder(builder: (context, constraints) {
              bool isWide = constraints.maxWidth > 500;
              return isWide
                  ? Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue: item['hsn_sac'],
                            decoration: const InputDecoration(labelText: 'HSN/SAC', isDense: true),
                            onChanged: (val) => item['hsn_sac'] = val,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            initialValue: qty.toString(),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: 'Qty', isDense: true),
                            onChanged: (val) => setState(() => item['quantity'] = double.tryParse(val) ?? 1.0),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            initialValue: price.toString(),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: 'Unit Price (₹)', isDense: true),
                            onChanged: (val) => setState(() => item['unit_price'] = double.tryParse(val) ?? 0.0),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        TextFormField(
                          initialValue: item['hsn_sac'],
                          decoration: const InputDecoration(labelText: 'HSN/SAC', isDense: true),
                          onChanged: (val) => item['hsn_sac'] = val,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                initialValue: qty.toString(),
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: const InputDecoration(labelText: 'Qty', isDense: true),
                                onChanged: (val) => setState(() => item['quantity'] = double.tryParse(val) ?? 1.0),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                initialValue: price.toString(),
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: const InputDecoration(labelText: 'Unit Price (₹)', isDense: true),
                                onChanged: (val) => setState(() => item['unit_price'] = double.tryParse(val) ?? 0.0),
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
            }),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: discount.toString(),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Discount (₹)', isDense: true),
                    onChanged: (val) => setState(() => item['discount_amount'] = double.tryParse(val) ?? 0.0),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<double>(
                    value: rate,
                    decoration: const InputDecoration(labelText: 'GST Rate (%)', isDense: true),
                    items: const [0, 5, 12, 18, 28]
                        .map((r) => DropdownMenuItem(value: r.toDouble(), child: Text('$r%')))
                        .toList(),
                    onChanged: (val) => setState(() => item['gst_rate'] = val ?? 18.0),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Line Subtotal: ₹${lineTaxable.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false, double fontSize = 14}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: fontSize, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(value, style: TextStyle(fontSize: fontSize, fontWeight: isBold ? FontWeight.bold : FontWeight.w600)),
        ],
      ),
    );
  }
}
