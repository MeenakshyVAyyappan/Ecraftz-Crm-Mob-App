import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/invoice_model.dart';
import '../../services/billing_service.dart';

class RecurringSubscriptionsScreen extends StatefulWidget {
  const RecurringSubscriptionsScreen({super.key});

  @override
  State<RecurringSubscriptionsScreen> createState() => _RecurringSubscriptionsScreenState();
}

class _RecurringSubscriptionsScreenState extends State<RecurringSubscriptionsScreen> {
  List<InvoiceModel> _recurringInvoices = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSubscriptions();
  }

  Future<void> _loadSubscriptions() async {
    setState(() => _isLoading = true);
    final all = await BillingService.getInvoices();
    if (mounted) {
      setState(() {
        _recurringInvoices = all.where((inv) => inv.isRecurring || inv.frequency != null).toList();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadSubscriptions,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Recurring Retainers & Subscriptions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                const Text('Auto-tracks retainer services (Monthly SEO, SaaS maintenance) and billing alerts.',
                    style: TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 16),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _recurringInvoices.isEmpty
                          ? const Center(child: Text('No recurring retainer subscriptions scheduled.'))
                          : ListView.builder(
                              itemCount: _recurringInvoices.length,
                              itemBuilder: (context, index) {
                                final item = _recurringInvoices[index];
                                final nextBillingDate = item.dueDate.add(const Duration(days: 30));

                                return Card(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: ListTile(
                                    leading: const CircleAvatar(
                                      backgroundColor: Colors.teal,
                                      child: Icon(Icons.autorenew, color: Colors.white),
                                    ),
                                    title: Text('${item.clientName ?? "Client"} • ${item.invoiceNumber}',
                                        style: const TextStyle(fontWeight: FontWeight.bold)),
                                    subtitle: Text(
                                        'Frequency: ${(item.frequency ?? "monthly").toUpperCase()} • Next Date: ${DateFormat("dd MMM yyyy").format(nextBillingDate)}'),
                                    trailing: Text('₹${item.grandTotal.toStringAsFixed(2)}',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.teal)),
                                  ),
                                );
                              },
                            ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
