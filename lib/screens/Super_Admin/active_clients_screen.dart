import 'package:ecraftz_crm/widgets/app_snackbar.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/supabase_service.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/app_refresh_button.dart';
import '../../widgets/branch_switcher.dart';
import '../../models/client_model.dart';
import '../../blocs/billing/billing_bloc.dart';
import '../../models/billing_model.dart';
import '../../services/invoice_pdf_generator.dart';
import 'create_invoices_screen.dart';
import '../../blocs/client/client_bloc.dart';
import '../../blocs/branch/branch_cubit.dart';
import '../../theme/app_theme.dart';
import '../../blocs/theme/theme_bloc.dart';
import 'client_statement_screen.dart';
import 'package:intl/intl.dart';
import '../../services/financials_service.dart';
import '../../models/income_entry_model.dart';

String _formatDate(DateTime dt) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
}

// ─── SERVICE COLORS ───────────────────────────────────────────────────────────

Color _serviceColor(String service) {
  final s = service.toLowerCase();
  if (s.contains('digital') || s.contains('marketing')) return const Color(0xFFF59E0B);
  if (s.contains('web') || s.contains('development')) return const Color(0xFF3B82F6);
  if (s.contains('seo')) return const Color(0xFF10B981);
  if (s.contains('design')) return const Color(0xFF8B5CF6);
  if (s.contains('content')) return const Color(0xFFEC4899);
  if (s.contains('social')) return const Color(0xFFF97316);
  if (s.contains('branding')) return const Color(0xFFEF4444);
  return const Color(0xFF6B7280);
}

// ─── MAIN PAGE ────────────────────────────────────────────────────────────────

class ActiveClientsPage extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;
  final bool showAppBar;

  const ActiveClientsPage({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    this.showAppBar = true,
  });

  @override
  State<ActiveClientsPage> createState() => _ActiveClientsPageState();
}

class _ActiveClientsPageState extends State<ActiveClientsPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String _sortBy = 'default';
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  Color get _bg => Theme.of(context).scaffoldBackgroundColor;
  Color get _border => AppTheme.borderOf(context);
  Color get _textPrimary => AppTheme.textPrimaryOf(context);
  Color get _textSecondary => AppTheme.textSecondaryOf(context);

  @override
  void initState() {
    super.initState();
    final branchState = context.read<BranchCubit>().state;
    context.read<ClientBloc>().add(LoadClientsEvent(branchState: branchState));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<ActiveClient> _filtered(List<ActiveClient> clients) {
    // 1. Filter by search query
    List<ActiveClient> result = clients;
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result.where((c) =>
          c.name.toLowerCase().contains(q) ||
          c.email.toLowerCase().contains(q) ||
          c.services.any((s) => s.toLowerCase().contains(q))).toList();
    }

    // 2. Sort
    switch (_sortBy) {
      case 'name_az':
        result.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'name_za':
        result.sort((a, b) => b.name.compareTo(a.name));
        break;
      case 'value_low_high':
        result.sort((a, b) => a.contractValue.compareTo(b.contractValue));
        break;
      case 'value_high_low':
        result.sort((a, b) => b.contractValue.compareTo(a.contractValue));
        break;
      case 'date_earliest':
        result.sort((a, b) => a.onboardedAt.compareTo(b.onboardedAt));
        break;
      case 'date_latest':
        result.sort((a, b) => b.onboardedAt.compareTo(a.onboardedAt));
        break;
      default:
        break;
    }
    return result;
  }

  void _showBulkImport() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => _ImportDataDialog(
        title: 'Import Data to Active Clients',
        subtitle: 'Bulk migration wizard for production-grade data ingestion.',
        onFilePicked: (file) async {
          // Parse and import clients from the picked file
          try {
            String content;
            if (file.bytes != null) {
              content = String.fromCharCodes(file.bytes!);
            } else if (file.path != null) {
              content = await File(file.path!).readAsString();
            } else {
              return;
            }
            final lines = content
                .split(RegExp(r'\r?\n'))
                .where((l) => l.trim().isNotEmpty)
                .toList();
            final clients = <ActiveClient>[];
            for (int i = 0; i < lines.length; i++) {
              final cols = lines[i].split(',').map((s) => s.trim()).toList();
              if (cols.length < 3) continue;
              clients.add(ActiveClient(
                id: DateTime.now().millisecondsSinceEpoch.toString() + i.toString(),
                name: cols[0],
                email: cols[1],
                services: cols[2].split(';').map((s) => s.trim()).toList(),
                contractValue: cols.length > 3 ? double.tryParse(cols[3]) ?? 0 : 0,
                onboardedAt: DateTime.now(),
                templateUsed: 'Bulk Import',
              ));
            }
            if (clients.isNotEmpty && mounted) {
              context.read<ClientBloc>().add(AddClientsBulkEvent(clients));
              AppSnackBar.showCustom(context, 
                SnackBar(
                  content: Text('\${clients.length} client(s) imported successfully'),
                  backgroundColor: const Color(0xFF10B981),
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              AppSnackBar.showCustom(context, 
                SnackBar(content: Text('Import failed: \$e')),
              );
            }
          }
        },
      ),
    );
  }

  void _showClientDetail(ActiveClient client) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ClientDetailSheet(client: client),
    );
  }

  void _showInvoice(ActiveClient client) {
    final profile = context.read<BillingBloc>().state.gstProfile;
    final branchState = context.read<BranchCubit>().state;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => InvoiceFormModal(
        prefilledClient: client,
        gstProfile: profile,
        onSave: (inv) {
          context.read<BillingBloc>().add(AddInvoiceEvent(inv, branchState: branchState));
          InvoicePdfGenerator.printInvoice(inv, profile);
        },
      ),
    );
  }

  void _showPayRenewal(ActiveClient client) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: _ProcessClientRenewalSheet(
          client: client,
          onSaved: () {
            context.read<ClientBloc>().add(LoadClientsEvent(
              branchState: context.read<BranchCubit>().state,
            ));
          },
        ),
      ),
    );
  }

  void _deleteClient(ActiveClient client) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove Client'),
        content: Text('Remove "${client.name}" from active clients?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              context.read<ClientBloc>().add(DeleteClientEvent(client.id));
              Navigator.pop(context);
              AppSnackBar.showCustom(context, 
                const SnackBar(content: Text('Client removed'), backgroundColor: Colors.red),
              );
            },
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleAutoRenew(ActiveClient client) async {
    final currentStatus = client.renewalStatus ?? 'active';
    final newStatus = (currentStatus == 'auto-renew' || currentStatus == 'active') ? 'manual' : 'auto-renew';
    try {
      await SupabaseService.client
          .from('clients')
          .update({'renewal_status': newStatus})
          .eq('id', client.id);
      
      if (mounted) {
        context.read<ClientBloc>().add(LoadClientsEvent(
          branchState: context.read<BranchCubit>().state,
        ));
        AppSnackBar.showCustom(
          context,
          SnackBar(
            content: Text(newStatus == 'auto-renew'
                ? 'Auto-Renewal enabled for ${client.name}'
                : 'Auto-Renewal disabled for ${client.name}'),
            backgroundColor: const Color(0xFFD97706),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showCustom(context, SnackBar(content: Text('Failed to update renewal status: $e')));
      }
    }
  }

  void _showEditClient(ActiveClient client) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditClientSheet(
        client: client,
        onSaved: () {
          context.read<ClientBloc>().add(LoadClientsEvent(
            branchState: context.read<BranchCubit>().state,
          ));
        },
      ),
    );
  }

  void _showCreateProposal(ActiveClient client) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CreateProposalSheet(
        clientName: client.name,
        clientId: client.id,
        defaultAmount: client.contractValue,
      ),
    );
  }

  void _showClientHistory(ActiveClient client) {
    final historyEvents = [
      {'date': _formatDate(client.onboardedAt), 'title': 'Client Onboarded', 'desc': 'Onboarded using template "${client.templateUsed}"'},
      {'date': _formatDate(client.onboardedAt), 'title': 'Contract Created', 'desc': 'Contract initialized at ₹${client.contractValue.toStringAsFixed(0)}'},
      {'date': 'Active Status', 'title': 'Renewal Config', 'desc': 'Auto-renewal: ${client.renewalStatus ?? "active"}'},
    ];

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.history_rounded, color: Color(0xFF00BCD4)),
              const SizedBox(width: 8),
              Expanded(child: Text('History: ${client.name}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: historyEvents.length,
              separatorBuilder: (_, __) => const Divider(height: 12),
              itemBuilder: (_, i) {
                final ev = historyEvents[i];
                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(radius: 14, backgroundColor: Color(0xFFE0F7FA), child: Icon(Icons.check, size: 14, color: Color(0xFF00BCD4))),
                  title: Text(ev['title']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  subtitle: Text('${ev['desc']}\n${ev['date']}', style: const TextStyle(fontSize: 11)),
                );
              },
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
          ],
        );
      },
    );
  }

  void _showClientStatement(ActiveClient client) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ClientStatementsScreen(
          selectedIndex: widget.selectedIndex,
          onItemSelected: widget.onItemSelected,
          initialClientName: client.name,
          initialClientId: client.id,
          autoShowTemplate: true,
        ),
      ),
    );
  }

  void _showClientProposals(ActiveClient client) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.article_outlined, color: Color(0xFF00BCD4)),
              const SizedBox(width: 8),
              Expanded(child: Text('Proposals for ${client.name}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.article, color: Color(0xFF00BCD4)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Proposal #${client.id.length > 6 ? client.id.substring(0, 6).toUpperCase() : client.id}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          Text('Value: ₹${client.contractValue.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: const Color(0xFF10B981).withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
                      child: const Text('ACTIVE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00BCD4), foregroundColor: Colors.white),
              onPressed: () {
                Navigator.pop(ctx);
                _showCreateProposal(client);
              },
              child: const Text('Create Proposal'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 600;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: _bg,
      drawer: widget.showAppBar ? AppDrawer(
        selectedIndex: widget.selectedIndex,
        onItemSelected: (i) {
          widget.onItemSelected(i);
          Navigator.pop(context);
        },
      ) : null,
      appBar: widget.showAppBar ? AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        leading: isWide
            ? null
            : IconButton(
                icon: Icon(Icons.menu_rounded, color: isDark ? Colors.white : const Color(0xFF374151)),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Active Clients',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _textPrimary)),
            Text('Manage your active customer relationships and contracts.',
                style: TextStyle(fontSize: 11, color: _textSecondary)),
          ],
        ),
        actions: [
          AppRefreshButton(
            onRefresh: () async {
              context.read<ClientBloc>().add(
                LoadClientsEvent(
                  branchState: context.read<BranchCubit>().state,
                ),
              );
              await Future.delayed(const Duration(milliseconds: 600));
            },
          ),
          const SizedBox(width: 4),
          // Branch switcher — always visible in the AppBar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: BranchSwitcher(compact: true),
          ),
          BlocBuilder<ThemeBloc, ThemeState>(
            builder: (context, themeState) {
              final isDarkTheme = themeState.themeMode == ThemeMode.dark;
              return IconButton(
                icon: Icon(
                  isDarkTheme ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                  color: isDarkTheme ? Colors.white : const Color(0xFF374151),
                ),
                onPressed: () {
                  context.read<ThemeBloc>().add(ToggleThemeEvent());
                },
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: OutlinedButton.icon(
              onPressed: _showBulkImport,
              icon: Icon(Icons.upload_file_outlined, size: 15, color: _textPrimary),
              label: Text(
                isWide ? 'Bulk Import' : 'Import',
                style: TextStyle(fontSize: 12, color: _textPrimary),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: _border),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _border),
        ),
      ) : null,
      body: BlocListener<BranchCubit, BranchState>(
        listener: (context, branchState) {
          // Reload clients whenever branch selection changes
          context.read<ClientBloc>().add(LoadClientsEvent(branchState: branchState));
        },
        child: BlocBuilder<ClientBloc, ClientState>(
          builder: (context, state) {
            final allClients = state.clients;
            final clients = _filtered(allClients);
            return Column(
              children: [
                // Stats strip
                _buildStatsStrip(allClients),
                // Search bar + Sort By
                _buildSearchAndSort(isDark, isWide),
                // Table
                Expanded(
                  child: clients.isEmpty
                      ? _buildEmpty()
                      : _buildTable(clients, isWide),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Builds the search bar + Sort By dropdown row.
  /// On wide screens (>600px): search and dropdown sit side-by-side.
  /// On mobile: search fills the full width; dropdown is on a second row.
  Widget _buildSearchAndSort(bool isDark, bool isWide) {
    final sortDropdown = Container(
      height: 42,
      decoration: BoxDecoration(
        color: isDark ? AppTheme.bgBaseDark : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _sortBy,
          isDense: true,
          icon: Icon(Icons.keyboard_arrow_down_rounded,
              color: AppTheme.textMutedOf(context), size: 18),
          style: TextStyle(color: _textPrimary, fontSize: 12),
          dropdownColor: isDark ? AppTheme.bgCardDark : Colors.white,
          items: const [
            DropdownMenuItem(
              value: 'default',
              child: Text('Sort by...', style: TextStyle(fontSize: 12)),
            ),
            DropdownMenuItem(
              value: 'name_az',
              child: Text('Name: A → Z ↑', style: TextStyle(fontSize: 12, color: Color(0xFF00BCD4))),
            ),
            DropdownMenuItem(
              value: 'name_za',
              child: Text('Name: Z → A ↓', style: TextStyle(fontSize: 12, color: Color(0xFF00BCD4))),
            ),
            DropdownMenuItem(
              value: 'value_low_high',
              child: Text('Value: Low → High ↑', style: TextStyle(fontSize: 12, color: Color(0xFF00BCD4))),
            ),
            DropdownMenuItem(
              value: 'value_high_low',
              child: Text('Value: High → Low ↓', style: TextStyle(fontSize: 12, color: Color(0xFF00BCD4))),
            ),
            DropdownMenuItem(
              value: 'date_earliest',
              child: Text('Date: Earliest First ↑', style: TextStyle(fontSize: 12, color: Color(0xFF00BCD4))),
            ),
            DropdownMenuItem(
              value: 'date_latest',
              child: Text('Date: Latest First ↓', style: TextStyle(fontSize: 12, color: Color(0xFF00BCD4))),
            ),
          ],
          onChanged: (v) {
            if (v != null) setState(() => _sortBy = v);
          },
        ),
      ),
    );

    final searchField = TextField(
      controller: _searchCtrl,
      onChanged: (v) => setState(() => _searchQuery = v),
      style: TextStyle(color: _textPrimary, fontSize: 13),
      decoration: InputDecoration(
        hintText: 'Search active clients...',
        hintStyle: TextStyle(color: AppTheme.textMutedOf(context), fontSize: 13),
        prefixIcon:
            Icon(Icons.search, color: AppTheme.textMutedOf(context), size: 18),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                icon: Icon(Icons.close, size: 16, color: _textSecondary),
                onPressed: () {
                  _searchCtrl.clear();
                  setState(() => _searchQuery = '');
                })
            : null,
        filled: true,
        fillColor: isDark ? AppTheme.bgBaseDark : const Color(0xFFF9FAFB),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: _border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: _border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF00BCD4), width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(vertical: 10),
      ),
    );

    return Container(
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: isWide
          // ── Wide screen: search + sort side by side ──
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: searchField),
                const SizedBox(width: 10),
                SizedBox(width: 190, child: sortDropdown),
              ],
            )
          // ── Mobile: search first, sort below ──
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                searchField,
                const SizedBox(height: 8),
                sortDropdown,
              ],
            ),
    );
  }

  Widget _buildStatsStrip(List<ActiveClient> allClients) {
    final total = allClients.length;
    final totalValue = allClients.fold<double>(0, (s, c) => s + c.contractValue);
    final services = allClients.expand((c) => c.services).toSet().length;

    return Container(
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      width: double.infinity,
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _statChip('Total Clients', '$total', const Color(0xFF00BCD4)),
          _statChip('Contract Value', '₹${_formatValue(totalValue)}', const Color(0xFF10B981)),
          _statChip('Services', '$services active', const Color(0xFF8B5CF6)),
        ],
      ),
    );
  }

  Widget _statChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: TextStyle(
                  color: color, fontSize: 13, fontWeight: FontWeight.w700)),
          Text(label,
              style: TextStyle(color: AppTheme.textMutedOf(context), fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.people_outline, size: 48, color: AppTheme.textMutedOf(context)),
          const SizedBox(height: 12),
          Text('No active clients found',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textPrimaryOf(context))),
          const SizedBox(height: 6),
          Text('Clients appear here after submitting onboarding forms\nor via bulk import.',
              style: TextStyle(color: AppTheme.textSecondaryOf(context), fontSize: 13),
              textAlign: TextAlign.center),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _showBulkImport,
            icon: const Icon(Icons.upload_file_outlined, size: 16),
            label: const Text('Bulk Import'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00BCD4),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTable(List<ActiveClient> clients, bool isWide) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (!isWide) {
      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: clients.length,
        itemBuilder: (_, i) => _ClientRow(
          client: clients[i],
          isLast: i == clients.length - 1,
          isWide: isWide,
          onPayRenewal: () => _showPayRenewal(clients[i]),
          onDetails: () => _showClientDetail(clients[i]),
          onInvoice: () => _showInvoice(clients[i]),
          onAutoRenew: () => _toggleAutoRenew(clients[i]),
          onEdit: () => _showEditClient(clients[i]),
          onCreateProposal: () => _showCreateProposal(clients[i]),
          onViewHistory: () => _showClientHistory(clients[i]),
          onViewStatement: () => _showClientStatement(clients[i]),
          onViewProposals: () => _showClientProposals(clients[i]),
          onDelete: () => _deleteClient(clients[i]),
        ),
      );
    }
    return Column(
      children: [
        // Table header
        Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.bgCardDark : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            border: Border.all(color: AppTheme.borderOf(context)),
          ),
          child: Row(
            children: [
              const Expanded(flex: 3, child: _TableHeader('Client Name')),
              const Expanded(flex: 3, child: _TableHeader('Service')),
              const Expanded(flex: 2, child: _TableHeader('Contract Value')),
              Expanded(flex: isWide ? 3 : 2, child: const _TableHeader('Actions')),
            ],
          ),
        ),
        // Rows
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            itemCount: clients.length,
            itemBuilder: (_, i) => _ClientRow(
              client: clients[i],
              isLast: i == clients.length - 1,
              isWide: isWide,
              onPayRenewal: () => _showPayRenewal(clients[i]),
              onDetails: () => _showClientDetail(clients[i]),
              onInvoice: () => _showInvoice(clients[i]),
              onAutoRenew: () => _toggleAutoRenew(clients[i]),
              onEdit: () => _showEditClient(clients[i]),
              onCreateProposal: () => _showCreateProposal(clients[i]),
              onViewHistory: () => _showClientHistory(clients[i]),
              onViewStatement: () => _showClientStatement(clients[i]),
              onViewProposals: () => _showClientProposals(clients[i]),
              onDelete: () => _deleteClient(clients[i]),
            ),
          ),
        ),
      ],
    );
  }

  String _formatValue(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}K';
    return v.toStringAsFixed(0);
  }
}

// ─── TABLE HEADER ─────────────────────────────────────────────────────────────

class _TableHeader extends StatelessWidget {
  final String text;
  const _TableHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondaryOf(context)));
  }
}

// ─── CLIENT ROW ───────────────────────────────────────────────────────────────

List<PopupMenuEntry<String>> _buildClientPopupMenuItems(ActiveClient client, BuildContext context) {
  final isAutoRenew = client.renewalStatus == 'auto-renew' || client.renewalStatus == 'active';

  return [
    PopupMenuItem<String>(
      value: 'pay_renewal',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.credit_card_rounded, size: 18, color: Color(0xFF10B981)),
          const SizedBox(width: 10),
          const Text(
            'Pay Renewal',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF10B981),
            ),
          ),
        ],
      ),
    ),
    PopupMenuItem<String>(
      value: 'auto_renew',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isAutoRenew ? Icons.autorenew_rounded : Icons.description_outlined,
            size: 18,
            color: const Color(0xFFD97706),
          ),
          const SizedBox(width: 10),
          Text(
            isAutoRenew ? 'Disable Auto-Renewal' : 'Enable Auto-Renewal',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFFD97706),
            ),
          ),
        ],
      ),
    ),
    PopupMenuItem<String>(
      value: 'edit',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.edit_outlined, size: 18, color: AppTheme.textPrimaryOf(context)),
          const SizedBox(width: 10),
          Text(
            'Edit Details',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimaryOf(context),
            ),
          ),
        ],
      ),
    ),
    PopupMenuItem<String>(
      value: 'create_proposal',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.article_outlined, size: 18, color: AppTheme.textPrimaryOf(context)),
          const SizedBox(width: 10),
          Text(
            'Create Proposal',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimaryOf(context),
            ),
          ),
        ],
      ),
    ),
    PopupMenuItem<String>(
      value: 'history',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.visibility_outlined, size: 18, color: AppTheme.textPrimaryOf(context)),
          const SizedBox(width: 10),
          Text(
            'View History',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimaryOf(context),
            ),
          ),
        ],
      ),
    ),
    PopupMenuItem<String>(
      value: 'statement',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.article_outlined, size: 18, color: Color(0xFF0284C7)),
          const SizedBox(width: 10),
          const Text(
            'View Statement',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0284C7),
            ),
          ),
        ],
      ),
    ),
    PopupMenuItem<String>(
      value: 'view_proposals',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.visibility_outlined, size: 18, color: AppTheme.textPrimaryOf(context)),
          const SizedBox(width: 10),
          Text(
            'View Proposals',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimaryOf(context),
            ),
          ),
        ],
      ),
    ),
    const PopupMenuDivider(height: 6),
    const PopupMenuItem<String>(
      value: 'delete',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.delete_outline, size: 18, color: Color(0xFFEF4444)),
          SizedBox(width: 10),
          Text(
            'Remove Client',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFFEF4444),
            ),
          ),
        ],
      ),
    ),
  ];
}

class _ClientRow extends StatelessWidget {
  final ActiveClient client;
  final bool isLast;
  final bool isWide;
  final VoidCallback onPayRenewal;
  final VoidCallback onDetails;
  final VoidCallback onInvoice;
  final VoidCallback onAutoRenew;
  final VoidCallback onEdit;
  final VoidCallback onCreateProposal;
  final VoidCallback onViewHistory;
  final VoidCallback onViewStatement;
  final VoidCallback onViewProposals;
  final VoidCallback onDelete;

  const _ClientRow({
    required this.client,
    required this.isLast,
    required this.isWide,
    required this.onPayRenewal,
    required this.onDetails,
    required this.onInvoice,
    required this.onAutoRenew,
    required this.onEdit,
    required this.onCreateProposal,
    required this.onViewHistory,
    required this.onViewStatement,
    required this.onViewProposals,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = AppTheme.textPrimaryOf(context);
    final textSecondary = AppTheme.textSecondaryOf(context);
    final textMuted = AppTheme.textMutedOf(context);
    final border = AppTheme.borderOf(context);

    if (!isWide) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.bgCardDark : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border),
          boxShadow: isDark ? [] : [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Avatar + Info + Popup Menu
            Row(
              children: [
                _Avatar(initials: client.initials),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        client.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        client.email,
                        style: TextStyle(
                          fontSize: 11,
                          color: textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, size: 18, color: textMuted),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  color: isDark ? AppTheme.bgCardDark : Colors.white,
                  itemBuilder: (ctx) => _buildClientPopupMenuItems(client, ctx),
                  onSelected: (v) {
                    if (v == 'pay_renewal') onPayRenewal();
                    if (v == 'auto_renew') onAutoRenew();
                    if (v == 'edit') onEdit();
                    if (v == 'create_proposal') onCreateProposal();
                    if (v == 'history') onViewHistory();
                    if (v == 'statement') onViewStatement();
                    if (v == 'view_proposals') onViewProposals();
                    if (v == 'delete') onDelete();
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Services
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: client.services.map((s) => _ServiceBadge(service: s)).toList(),
            ),
            const SizedBox(height: 12),
            Divider(height: 1, color: border),
            const SizedBox(height: 12),
            // Value + Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CONTRACT VALUE',
                      style: TextStyle(fontSize: 9, color: textMuted, fontWeight: FontWeight.w600, letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      client.contractValue > 0
                          ? '₹${client.contractValue.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}'
                          : '₹0',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: client.contractValue > 0 ? textPrimary : textMuted,
                      ),
                    ),
                  ],
                ),
                Flexible(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _ActionBtn(
                          icon: Icons.credit_card_rounded,
                          label: 'Pay Renewal',
                          onTap: onPayRenewal,
                          color: const Color(0xFF10B981),
                        ),
                        const SizedBox(width: 4),
                        _ActionBtn(
                          icon: Icons.info_outline_rounded,
                          label: 'Details',
                          onTap: onDetails,
                          color: const Color(0xFF00BCD4),
                        ),
                        const SizedBox(width: 4),
                        _ActionBtn(
                          icon: Icons.receipt_long_outlined,
                          label: 'Invoice',
                          onTap: onInvoice,
                          color: const Color(0xFF00BCD4),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.bgCardDark : Colors.white,
        border: Border(
          left: BorderSide(color: border),
          right: BorderSide(color: border),
          bottom: BorderSide(
              color: isLast ? Colors.transparent : border),
        ),
        borderRadius: isLast
            ? const BorderRadius.vertical(bottom: Radius.circular(12))
            : BorderRadius.zero,
      ),
      child: Row(
        children: [
          // Client name + email
          Expanded(
            flex: 3,
            child: Row(
              children: [
                _Avatar(initials: client.initials),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(client.name,
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: textPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      Text(client.email,
                          style: TextStyle(
                              fontSize: 11, color: textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Services
          Expanded(
            flex: 3,
            child: Wrap(
              spacing: 4,
              runSpacing: 4,
              children: client.services.map((s) => _ServiceBadge(service: s)).toList(),
            ),
          ),
          // Contract value
          Expanded(
            flex: 2,
            child: Text(
              client.contractValue > 0
                  ? '₹${client.contractValue.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}'
                  : '₹0',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: client.contractValue > 0
                      ? textPrimary
                      : textMuted),
            ),
          ),
          // Actions
          Expanded(
            flex: isWide ? 3 : 2,
            child: Row(
              children: [
                _ActionBtn(
                  icon: Icons.credit_card_rounded,
                  label: 'Pay Renewal',
                  onTap: onPayRenewal,
                  color: const Color(0xFF10B981),
                ),
                const SizedBox(width: 6),
                _ActionBtn(
                  icon: Icons.info_outline_rounded,
                  label: 'Details',
                  onTap: onDetails,
                  color: const Color(0xFF00BCD4),
                ),
                const SizedBox(width: 6),
                _ActionBtn(
                  icon: Icons.receipt_long_outlined,
                  label: 'Invoice',
                  onTap: onInvoice,
                  color: const Color(0xFF00BCD4),
                ),
                const SizedBox(width: 2),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_horiz,
                      size: 18, color: textMuted),
                  padding: EdgeInsets.zero,
                  color: isDark ? AppTheme.bgCardDark : Colors.white,
                  itemBuilder: (ctx) => _buildClientPopupMenuItems(client, ctx),
                  onSelected: (v) {
                    if (v == 'pay_renewal') onPayRenewal();
                    if (v == 'auto_renew') onAutoRenew();
                    if (v == 'edit') onEdit();
                    if (v == 'create_proposal') onCreateProposal();
                    if (v == 'history') onViewHistory();
                    if (v == 'statement') onViewStatement();
                    if (v == 'view_proposals') onViewProposals();
                    if (v == 'delete') onDelete();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── CLIENT DETAIL SHEET ──────────────────────────────────────────────────────

class _ClientDetailSheet extends StatelessWidget {
  final ActiveClient client;
  const _ClientDetailSheet({required this.client});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppTheme.bgCardDark : Colors.white;
    final textPrimary = AppTheme.textPrimaryOf(context);
    final textSecondary = AppTheme.textSecondaryOf(context);
    final border = AppTheme.borderOf(context);

    String fmtCur(double? val) {
      if (val == null || val == 0) return '₹0';
      return '₹${val.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder: (_, ctrl) => Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                  color: border,
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: [
                  _Avatar(initials: client.initials, size: 48),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(client.name,
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: textPrimary)),
                        if (client.email.isNotEmpty)
                          Text(client.email,
                              style: TextStyle(
                                  fontSize: 12, color: textSecondary)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.circle, size: 8, color: Color(0xFF10B981)),
                        const SizedBox(width: 5),
                        Text(client.renewalStatus?.toUpperCase() ?? 'ACTIVE',
                            style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF10B981))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 24, color: border),
            Expanded(
              child: ListView(
                controller: ctrl,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  // Services Section
                  if (client.services.isNotEmpty) ...[
                    _DetailSection(
                      title: 'Services Provided',
                      icon: Icons.work_outline_rounded,
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: client.services
                            .map((s) => _ServiceBadge(service: s, large: true))
                            .toList(),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // Contract & Pricing Overview
                  _DetailSection(
                    title: 'Contract & Financial Details',
                    icon: Icons.attach_money_rounded,
                    child: Column(
                      children: [
                        _DetailRow('Contract Value', fmtCur(client.contractValue)),
                        _DetailRow('Amount (₹)', fmtCur(client.amount ?? client.contractValue)),
                        _DetailRow('Client Category', client.clientCategory ?? client.templateUsed),
                        _DetailRow('CPR (Cost Per Result ₹)', client.cpr != null ? '₹${client.cpr!.toStringAsFixed(2)}' : 'Not set'),
                        _DetailRow('CPA (Cost Per Acquisition ₹)', client.cpa != null ? '₹${client.cpa!.toStringAsFixed(2)}' : 'Not set'),
                        _DetailRow('Total Count', client.totalCount != null ? '${client.totalCount}' : '0'),
                        _DetailRow('Shoot Count', client.shootCount != null ? '${client.shootCount}' : '0'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Renewal Details
                  _DetailSection(
                    title: 'Renewal Information',
                    icon: Icons.autorenew_rounded,
                    child: Column(
                      children: [
                        _DetailRow('Renewal Date', (client.renewalDate != null && client.renewalDate!.isNotEmpty) ? client.renewalDate! : 'Not set'),
                        _DetailRow('Pending / Renewed Status', client.renewalStatus ?? 'ACTIVE'),
                        _DetailRow('Onboarded Date', _formatDate(client.onboardedAt)),
                        _DetailRow('Template Used', client.templateUsed),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Team & Department Allocations
                  _DetailSection(
                    title: 'Assigned Team & Department',
                    icon: Icons.groups_outlined,
                    child: Column(
                      children: [
                        _DetailRow('Assigned Department', (client.department != null && client.department!.isNotEmpty) ? client.department! : 'Not set'),
                        _DetailRow('Assigned Team Lead', (client.teamLead != null && client.teamLead!.isNotEmpty) ? client.teamLead! : 'Not set'),
                        _DetailRow('DM Team', (client.dmTeam != null && client.dmTeam!.isNotEmpty) ? client.dmTeam! : 'Not set'),
                        _DetailRow('Designers', (client.designers != null && client.designers!.isNotEmpty) ? client.designers! : 'Not set'),
                        _DetailRow('Editors', (client.editors != null && client.editors!.isNotEmpty) ? client.editors! : 'Not set'),
                        _DetailRow('Content Writers', (client.contentWriters != null && client.contentWriters!.isNotEmpty) ? client.contentWriters! : 'Not set'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Contact & Business Information
                  _DetailSection(
                    title: 'Contact Information',
                    icon: Icons.person_outline_rounded,
                    child: Column(
                      children: [
                        _DetailRow('Client Name', client.name),
                        _DetailRow('Email', client.email.isNotEmpty ? client.email : 'Not set'),
                        _DetailRow('Phone Number', (client.phone != null && client.phone!.isNotEmpty) ? client.phone! : 'Not set'),
                        _DetailRow('Business Address', (client.address != null && client.address!.isNotEmpty) ? client.address! : 'Not set'),
                        _DetailRow('GSTIN / Tax Registration', (client.gstin != null && client.gstin!.isNotEmpty) ? client.gstin! : 'Not set'),
                        _DetailRow('Website', (client.website != null && client.website!.isNotEmpty) ? client.website! : 'Not set'),
                      ],
                    ),
                  ),

                  // Remarks Section
                  if (client.remarks != null && client.remarks!.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    _DetailSection(
                      title: 'Remarks & Notes',
                      icon: Icons.note_alt_outlined,
                      child: Text(
                        client.remarks!,
                        style: TextStyle(fontSize: 13, color: textPrimary),
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }
}

// ─── INVOICE SHEET ────────────────────────────────────────────────────────────

class _InvoiceSheet extends StatelessWidget {
  final ActiveClient client;
  const _InvoiceSheet({required this.client});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppTheme.bgCardDark : Colors.white;
    final textPrimary = AppTheme.textPrimaryOf(context);
    final textSecondary = AppTheme.textSecondaryOf(context);
    final textMuted = AppTheme.textMutedOf(context);
    final border = AppTheme.borderOf(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.92,
      minChildSize: 0.4,
      builder: (_, ctrl) => Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                  color: border,
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: Row(
                children: [
                  Text('Invoice',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: textPrimary)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF164E63) : const Color(0xFFF0FDFE),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFF00BCD4).withOpacity(0.3)),
                    ),
                    child: const Text('DRAFT',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF00BCD4),
                            letterSpacing: 0.5)),
                  ),
                ],
              ),
            ),
            Divider(height: 24, color: border),
            Expanded(
              child: ListView(
                controller: ctrl,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  // Client info
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Bill To',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: textMuted,
                                    letterSpacing: 0.5)),
                            const SizedBox(height: 4),
                            Text(client.name,
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: textPrimary)),
                            Text(client.email,
                                style: TextStyle(
                                    fontSize: 12, color: textSecondary)),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('Invoice Date',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: textMuted,
                                    letterSpacing: 0.5)),
                            const SizedBox(height: 4),
                            Text(
                              '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                              style: TextStyle(
                                  fontSize: 12, color: textPrimary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Services table
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: border),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        // Header
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: isDark ? AppTheme.bgBaseDark : const Color(0xFFF9FAFB),
                            borderRadius:
                                const BorderRadius.vertical(top: Radius.circular(10)),
                          ),
                          child: Row(
                            children: [
                              Expanded(flex: 4, child: Text('Service', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: textMuted))),
                              Expanded(flex: 1, child: Text('Qty', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: textMuted))),
                              Expanded(flex: 2, child: Text('Amount', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: textMuted), textAlign: TextAlign.end)),
                            ],
                          ),
                        ),
                        Divider(height: 1, color: border),
                        ...client.services.asMap().entries.map((e) {
                          final perService = client.services.isEmpty
                              ? 0.0
                              : client.contractValue / client.services.length;
                          return Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 12),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 4,
                                      child: Text(e.value,
                                          style: TextStyle(
                                              fontSize: 13,
                                              color: textPrimary)),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: Text('1',
                                          style: TextStyle(
                                              fontSize: 13,
                                              color: textSecondary)),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        '₹${perService.toStringAsFixed(0)}',
                                        style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: textPrimary),
                                        textAlign: TextAlign.end,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (e.key < client.services.length - 1)
                                Divider(height: 1, color: border),
                            ],
                          );
                        }).toList(),
                        Divider(height: 1, color: border),
                        // Total
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          child: Row(
                            children: [
                              Expanded(
                                  flex: 4,
                                  child: Text('Total',
                                      style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: textPrimary))),
                              const Expanded(flex: 1, child: SizedBox()),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  '₹${client.contractValue.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF00BCD4)),
                                  textAlign: TextAlign.end,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(Icons.download_outlined, size: 16, color: textPrimary),
                          label: Text('Download PDF', style: TextStyle(color: textPrimary, fontSize: 13)),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: border),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.send_outlined, size: 16),
                          label: const Text('Send Invoice', style: TextStyle(fontSize: 13)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00BCD4),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── IMPORT DATA DIALOG ───────────────────────────────────────────────────────

class _ImportDataDialog extends StatefulWidget {
  final String title;
  final String subtitle;
  final Future<void> Function(PlatformFile file) onFilePicked;

  const _ImportDataDialog({
    required this.title,
    required this.subtitle,
    required this.onFilePicked,
  });

  @override
  State<_ImportDataDialog> createState() => _ImportDataDialogState();
}

class _ImportDataDialogState extends State<_ImportDataDialog> {
  PlatformFile? _selectedFile;
  bool _isImporting = false;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'xlsx', 'xls'],
      allowMultiple: false,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() => _selectedFile = result.files.first);
    }
  }

  Future<void> _doImport() async {
    if (_selectedFile == null) return;
    setState(() => _isImporting = true);
    try {
      await widget.onFilePicked(_selectedFile!);
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppTheme.bgCardDark : Colors.white;
    final textPrimary = AppTheme.textPrimaryOf(context);
    final textSecondary = AppTheme.textSecondaryOf(context);
    final textMuted = AppTheme.textMutedOf(context);
    final border = AppTheme.borderOf(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00BCD4).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: const Color(0xFF00BCD4).withOpacity(0.25)),
                    ),
                    child: const Icon(
                      Icons.upload_file_rounded,
                      color: Color(0xFF00BCD4),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: textPrimary,
                          ),
                        ),
                        Text(
                          widget.subtitle,
                          style: TextStyle(fontSize: 10.5, color: textSecondary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, size: 18, color: textMuted),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            Divider(height: 20, color: border),
            // Upload area
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              child: GestureDetector(
                onTap: _pickFile,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.bgBaseDark : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _selectedFile != null
                          ? const Color(0xFF00BCD4)
                          : border,
                      width: _selectedFile != null ? 1.5 : 1,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.upload_rounded,
                        size: 40,
                        color: _selectedFile != null
                            ? const Color(0xFF00BCD4)
                            : textMuted,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _selectedFile != null
                            ? _selectedFile!.name
                            : 'Upload Excel or CSV File',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: _selectedFile != null
                              ? const Color(0xFF00BCD4)
                              : textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (_selectedFile == null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Drop your migration file here or click to browse.',
                          style: TextStyle(fontSize: 12, color: textSecondary),
                          textAlign: TextAlign.center,
                        ),
                      ],
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: _pickFile,
                        icon: Icon(Icons.folder_open_outlined,
                            size: 16, color: textPrimary),
                        label: Text(
                          _selectedFile != null ? 'Change File' : 'Choose File',
                          style:
                              TextStyle(fontSize: 13, color: textPrimary),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: border),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Divider(height: 24, color: border),
            // Footer actions
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancel',
                        style: TextStyle(
                            fontSize: 14,
                            color: textSecondary,
                            fontWeight: FontWeight.w600)),
                  ),
                  const Spacer(),
                  if (_selectedFile != null)
                    ElevatedButton.icon(
                      onPressed: _isImporting ? null : _doImport,
                      icon: _isImporting
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.upload_rounded, size: 16),
                      label: Text(
                          _isImporting ? 'Importing...' : 'Import',
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00BCD4),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        elevation: 0,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// ─── REUSABLE WIDGETS ─────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  final String initials;
  final double size;

  const _Avatar({required this.initials, this.size = 36});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF00BCD4).withOpacity(0.15),
        shape: BoxShape.circle,
        border: Border.all(
            color: const Color(0xFF00BCD4).withOpacity(0.3), width: 1.5),
      ),
      child: Center(
        child: Text(initials,
            style: TextStyle(
                fontSize: size * 0.33,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF00BCD4))),
      ),
    );
  }
}

class _ServiceBadge extends StatelessWidget {
  final String service;
  final bool large;

  const _ServiceBadge({required this.service, this.large = false});

  @override
  Widget build(BuildContext context) {
    final color = _serviceColor(service);
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: large ? 10 : 7, vertical: large ? 5 : 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Text(service,
          style: TextStyle(
              fontSize: large ? 12 : 10,
              fontWeight: FontWeight.w600,
              color: color)),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          border: Border.all(color: color.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(7),
          color: color.withOpacity(0.05),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w600, color: color)),
          ],
        ),
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _DetailSection(
      {required this.title, required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.bgBaseDark : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderOf(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: const Color(0xFF00BCD4)),
              const SizedBox(width: 6),
              Text(title,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimaryOf(context))),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text('$label: ',
              style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondaryOf(context),
                  fontWeight: FontWeight.w500)),
          Expanded(
            child: Text(value,
                style: TextStyle(
                    fontSize: 12, color: AppTheme.textPrimaryOf(context)),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}

// ─── COUNTRY CODE MODEL & DATASET ─────────────────────────────────────────────

class CountryCode {
  final String name;
  final String code;
  final String dialCode;
  final String flag;

  const CountryCode({
    required this.name,
    required this.code,
    required this.dialCode,
    required this.flag,
  });
}

const List<CountryCode> kAllCountries = [
  CountryCode(name: 'India', code: 'IN', dialCode: '+91', flag: '🇮🇳'),
  CountryCode(name: 'United Arab Emirates', code: 'AE', dialCode: '+971', flag: '🇦🇪'),
  CountryCode(name: 'United States', code: 'US', dialCode: '+1', flag: '🇺🇸'),
  CountryCode(name: 'United Kingdom', code: 'GB', dialCode: '+44', flag: '🇬🇧'),
  CountryCode(name: 'Saudi Arabia', code: 'SA', dialCode: '+966', flag: '🇸🇦'),
  CountryCode(name: 'Qatar', code: 'QA', dialCode: '+974', flag: '🇶🇦'),
  CountryCode(name: 'Oman', code: 'OM', dialCode: '+968', flag: '🇴🇲'),
  CountryCode(name: 'Kuwait', code: 'KW', dialCode: '+965', flag: '🇰🇼'),
  CountryCode(name: 'Bahrain', code: 'BH', dialCode: '+973', flag: '🇧🇭'),
  CountryCode(name: 'Singapore', code: 'SG', dialCode: '+65', flag: '🇸🇬'),
  CountryCode(name: 'Malaysia', code: 'MY', dialCode: '+60', flag: '🇲🇾'),
  CountryCode(name: 'Australia', code: 'AU', dialCode: '+61', flag: '🇦🇺'),
  CountryCode(name: 'Canada', code: 'CA', dialCode: '+1', flag: '🇨🇦'),
  CountryCode(name: 'Germany', code: 'DE', dialCode: '+49', flag: '🇩🇪'),
  CountryCode(name: 'France', code: 'FR', dialCode: '+33', flag: '🇫🇷'),
  CountryCode(name: 'Italy', code: 'IT', dialCode: '+39', flag: '🇮🇹'),
  CountryCode(name: 'Spain', code: 'ES', dialCode: '+34', flag: '🇪🇸'),
  CountryCode(name: 'Netherlands', code: 'NL', dialCode: '+31', flag: '🇳🇱'),
  CountryCode(name: 'Switzerland', code: 'CH', dialCode: '+41', flag: '🇨🇭'),
  CountryCode(name: 'Sweden', code: 'SE', dialCode: '+46', flag: '🇸🇪'),
  CountryCode(name: 'Norway', code: 'NO', dialCode: '+47', flag: '🇳🇴'),
  CountryCode(name: 'Denmark', code: 'DK', dialCode: '+45', flag: '🇩🇰'),
  CountryCode(name: 'Finland', code: 'FI', dialCode: '+358', flag: '🇫🇮'),
  CountryCode(name: 'Ireland', code: 'IE', dialCode: '+353', flag: '🇮🇪'),
  CountryCode(name: 'New Zealand', code: 'NZ', dialCode: '+64', flag: '🇳🇿'),
  CountryCode(name: 'Japan', code: 'JP', dialCode: '+81', flag: '🇯🇵'),
  CountryCode(name: 'South Korea', code: 'KR', dialCode: '+82', flag: '🇰🇷'),
  CountryCode(name: 'China', code: 'CN', dialCode: '+86', flag: '🇨🇳'),
  CountryCode(name: 'Hong Kong', code: 'HK', dialCode: '+852', flag: '🇭🇰'),
  CountryCode(name: 'Taiwan', code: 'TW', dialCode: '+886', flag: '🇹🇼'),
  CountryCode(name: 'Thailand', code: 'TH', dialCode: '+66', flag: '🇹🇭'),
  CountryCode(name: 'Indonesia', code: 'ID', dialCode: '+62', flag: '🇮🇩'),
  CountryCode(name: 'Philippines', code: 'PH', dialCode: '+63', flag: '🇵🇭'),
  CountryCode(name: 'Vietnam', code: 'VN', dialCode: '+84', flag: '🇻🇳'),
  CountryCode(name: 'Pakistan', code: 'PK', dialCode: '+92', flag: '🇵🇰'),
  CountryCode(name: 'Bangladesh', code: 'BD', dialCode: '+880', flag: '🇧🇩'),
  CountryCode(name: 'Sri Lanka', code: 'LK', dialCode: '+94', flag: '🇱🇱'),
  CountryCode(name: 'Nepal', code: 'NP', dialCode: '+977', flag: '🇳🇵'),
  CountryCode(name: 'South Africa', code: 'ZA', dialCode: '+27', flag: '🇿🇦'),
  CountryCode(name: 'Nigeria', code: 'NG', dialCode: '+234', flag: '🇳🇬'),
  CountryCode(name: 'Egypt', code: 'EG', dialCode: '+20', flag: '🇪🇬'),
  CountryCode(name: 'Kenya', code: 'KE', dialCode: '+254', flag: '🇰🇪'),
  CountryCode(name: 'Brazil', code: 'BR', dialCode: '+55', flag: '🇧🇷'),
  CountryCode(name: 'Mexico', code: 'MX', dialCode: '+52', flag: '🇲🇽'),
  CountryCode(name: 'Argentina', code: 'AR', dialCode: '+54', flag: '🇦🇷'),
  CountryCode(name: 'Chile', code: 'CL', dialCode: '+56', flag: '🇨🇱'),
  CountryCode(name: 'Colombia', code: 'CO', dialCode: '+57', flag: '🇨🇴'),
  CountryCode(name: 'Russia', code: 'RU', dialCode: '+7', flag: '🇷🇺'),
  CountryCode(name: 'Turkey', code: 'TR', dialCode: '+90', flag: '🇹🇷'),
];

// ─── COMPREHENSIVE EDIT CLIENT SHEET (MATCHING WEB APP) ───────────────────────

class _EditClientSheet extends StatefulWidget {
  final ActiveClient client;
  final VoidCallback onSaved;

  const _EditClientSheet({
    required this.client,
    required this.onSaved,
  });

  @override
  State<_EditClientSheet> createState() => _EditClientSheetState();
}

class _EditClientSheetState extends State<_EditClientSheet> {
  late TextEditingController _nameCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _contractValueCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _gstinCtrl;
  late TextEditingController _deptCtrl;
  late TextEditingController _teamLeadCtrl;
  late TextEditingController _categoryCtrl;
  late TextEditingController _totalCountCtrl;
  late TextEditingController _shootCountCtrl;
  late TextEditingController _amountCtrl;
  late TextEditingController _cprCtrl;
  late TextEditingController _cpaCtrl;
  late TextEditingController _renewalDateCtrl;
  late TextEditingController _renewalStatusCtrl;
  late TextEditingController _dmTeamCtrl;
  late TextEditingController _designersCtrl;
  late TextEditingController _editorsCtrl;
  late TextEditingController _contentWritersCtrl;
  late TextEditingController _remarksCtrl;
  late TextEditingController _customServiceCtrl;

  late List<String> _services;
  String? _selectedBranchId;
  String _selectedStandardService = 'Add a standard service...';
  bool _isSaving = false;
  CountryCode _selectedCountry = kAllCountries.first; // Default India (+91)

  final List<String> _ecraftzDepartments = [
    'Select Department...',
    'Digital Marketing',
    'Graphic Designing',
    'Video Editing',
    'Videography',
    'Content Writer',
    'Web Development',
    'BDE',
    'CRM',
    'SEO',
    'Branding & Strategy',
    'Sales & Account Management',
  ];

  final List<String> _standardServicesOptions = [
    'Add a standard service...',
    'Web Development',
    'Digital Marketing',
    'SEO Optimization',
    'Branding & Identity',
    'Graphic Design',
    'Video Editing',
    'Content Writing',
    'Social Media Management',
  ];

  Future<void> _loadDepartments() async {
    try {
      final res = await SupabaseService.client.from('departments').select('name');
      final list = res as List;
      for (final item in list) {
        final name = item['name']?.toString();
        if (name != null && name.isNotEmpty && !_ecraftzDepartments.contains(name)) {
          if (mounted) {
            setState(() {
              _ecraftzDepartments.add(name);
            });
          }
        }
      }
    } catch (_) {}
  }

  Widget _buildDepartmentDropdown() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = AppTheme.borderOf(context);
    final textPrimary = AppTheme.textPrimaryOf(context);
    final textMuted = AppTheme.textMutedOf(context);

    // If current text in _deptCtrl is not in options, append it so it's selectable
    if (_deptCtrl.text.isNotEmpty && !_ecraftzDepartments.contains(_deptCtrl.text)) {
      _ecraftzDepartments.add(_deptCtrl.text);
    }

    final selectedVal = _ecraftzDepartments.contains(_deptCtrl.text)
        ? _deptCtrl.text
        : 'Select Department...';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(10),
        color: isDark ? AppTheme.bgBaseDark : const Color(0xFFF9FAFB),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedVal,
          isExpanded: true,
          dropdownColor: isDark ? AppTheme.bgCardDark : Colors.white,
          style: TextStyle(fontSize: 13, color: textPrimary),
          hint: Text('Select Department...', style: TextStyle(fontSize: 13, color: textMuted)),
          items: _ecraftzDepartments.map((dept) {
            final isPlaceholder = dept == 'Select Department...';
            return DropdownMenuItem<String>(
              value: dept,
              child: Text(
                dept,
                style: TextStyle(
                  fontSize: 13,
                  color: isPlaceholder ? textMuted : textPrimary,
                  fontWeight: isPlaceholder ? FontWeight.normal : FontWeight.w500,
                ),
              ),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() {
                _deptCtrl.text = (val == 'Select Department...') ? '' : val;
              });
            }
          },
        ),
      ),
    );
  }

  final List<String> _teamLeadsList = [
    'Select Team Lead...',
    'Super Admin',
    'Meenakshy',
    'Operations Lead',
    'Digital Marketing Lead',
    'Design Lead',
    'Development Lead',
    'Video Lead',
  ];

  Future<void> _loadTeamLeads() async {
    try {
      final res = await SupabaseService.client.from('profiles').select('full_name, role');
      final list = res as List;
      for (final item in list) {
        final name = item['full_name']?.toString();
        if (name != null && name.isNotEmpty && !_teamLeadsList.contains(name)) {
          if (mounted) {
            setState(() {
              _teamLeadsList.add(name);
            });
          }
        }
      }
    } catch (_) {}
  }

  Widget _buildTeamLeadDropdown() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = AppTheme.borderOf(context);
    final textPrimary = AppTheme.textPrimaryOf(context);
    final textMuted = AppTheme.textMutedOf(context);

    if (_teamLeadCtrl.text.isNotEmpty && !_teamLeadsList.contains(_teamLeadCtrl.text)) {
      _teamLeadsList.add(_teamLeadCtrl.text);
    }

    final selectedVal = _teamLeadsList.contains(_teamLeadCtrl.text)
        ? _teamLeadCtrl.text
        : 'Select Team Lead...';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(10),
        color: isDark ? AppTheme.bgBaseDark : const Color(0xFFF9FAFB),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedVal,
          isExpanded: true,
          dropdownColor: isDark ? AppTheme.bgCardDark : Colors.white,
          style: TextStyle(fontSize: 13, color: textPrimary),
          hint: Text('Select Team Lead...', style: TextStyle(fontSize: 13, color: textMuted)),
          items: _teamLeadsList.map((lead) {
            final isPlaceholder = lead == 'Select Team Lead...';
            return DropdownMenuItem<String>(
              value: lead,
              child: Text(
                lead,
                style: TextStyle(
                  fontSize: 13,
                  color: isPlaceholder ? textMuted : textPrimary,
                  fontWeight: isPlaceholder ? FontWeight.normal : FontWeight.w500,
                ),
              ),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() {
                _teamLeadCtrl.text = (val == 'Select Team Lead...') ? '' : val;
              });
            }
          },
        ),
      ),
    );
  }

  Future<void> _selectRenewalDate() async {
    DateTime initial = DateTime.now();
    if (_renewalDateCtrl.text.isNotEmpty) {
      try {
        final parts = _renewalDateCtrl.text.split('-');
        if (parts.length == 3) {
          if (parts[0].length == 4) {
            initial = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
          } else {
            initial = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
          }
        }
      } catch (_) {}
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? const ColorScheme.dark(primary: Color(0xFF00BCD4), onPrimary: Colors.white, surface: Color(0xFF1E293B))
                : const ColorScheme.light(primary: Color(0xFF00BCD4), onPrimary: Colors.white),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final day = picked.day.toString().padLeft(2, '0');
      final month = picked.month.toString().padLeft(2, '0');
      final year = picked.year.toString();
      setState(() {
        _renewalDateCtrl.text = '$day-$month-$year';
      });
    }
  }

  Widget _buildRenewalDatePicker() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: _selectRenewalDate,
      borderRadius: BorderRadius.circular(10),
      child: IgnorePointer(
        child: TextField(
          controller: _renewalDateCtrl,
          style: TextStyle(fontSize: 13, color: AppTheme.textPrimaryOf(context)),
          decoration: InputDecoration(
            hintText: 'Select date (dd-mm-yyyy)',
            hintStyle: TextStyle(color: AppTheme.textMutedOf(context), fontSize: 12),
            suffixIcon: const Icon(Icons.calendar_today_rounded, size: 18, color: Color(0xFF00BCD4)),
            filled: true,
            fillColor: isDark ? AppTheme.bgBaseDark : const Color(0xFFF9FAFB),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppTheme.borderOf(context)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppTheme.borderOf(context)),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    final c = widget.client;
    _nameCtrl = TextEditingController(text: c.name);
    _emailCtrl = TextEditingController(text: c.email);

    // Extract country dial code if present in phone number
    String rawPhone = c.phone?.trim() ?? '';
    CountryCode matchedCountry = kAllCountries.first;
    for (final country in kAllCountries) {
      if (rawPhone.startsWith(country.dialCode)) {
        matchedCountry = country;
        rawPhone = rawPhone.substring(country.dialCode.length).trim();
        break;
      }
    }
    _selectedCountry = matchedCountry;
    _phoneCtrl = TextEditingController(text: rawPhone);

    _contractValueCtrl = TextEditingController(text: c.contractValue > 0 ? c.contractValue.toStringAsFixed(0) : '0');
    _addressCtrl = TextEditingController(text: c.address ?? '');
    _gstinCtrl = TextEditingController(text: c.gstin ?? '');
    _deptCtrl = TextEditingController(text: c.department ?? '');
    _teamLeadCtrl = TextEditingController(text: c.teamLead ?? '');
    _categoryCtrl = TextEditingController(text: c.clientCategory ?? c.templateUsed);
    _totalCountCtrl = TextEditingController(text: c.totalCount?.toString() ?? '');
    _shootCountCtrl = TextEditingController(text: c.shootCount?.toString() ?? '');
    _amountCtrl = TextEditingController(text: c.amount != null ? c.amount!.toStringAsFixed(0) : (c.contractValue > 0 ? c.contractValue.toStringAsFixed(0) : '0'));
    _cprCtrl = TextEditingController(text: c.cpr?.toString() ?? '');
    _cpaCtrl = TextEditingController(text: c.cpa?.toString() ?? '');
    _renewalDateCtrl = TextEditingController(text: c.renewalDate ?? '');
    _renewalStatusCtrl = TextEditingController(text: c.renewalStatus ?? 'ACTIVE');
    _dmTeamCtrl = TextEditingController(text: c.dmTeam ?? '');
    _designersCtrl = TextEditingController(text: c.designers ?? '');
    _editorsCtrl = TextEditingController(text: c.editors ?? '');
    _contentWritersCtrl = TextEditingController(text: c.contentWriters ?? '');
    _remarksCtrl = TextEditingController(text: c.remarks ?? '');
    _customServiceCtrl = TextEditingController();

    _services = List<String>.from(c.services);
    _selectedBranchId = c.branchId;
    _loadDepartments();
    _loadTeamLeads();
    _fetchLatestClientDetails();
  }

  Future<void> _fetchLatestClientDetails() async {
    try {
      final res = await SupabaseService.client
          .from('clients')
          .select('*')
          .eq('id', widget.client.id)
          .maybeSingle();

      if (res != null && mounted) {
        final updated = ActiveClient.fromJson(res);
        setState(() {
          if (_nameCtrl.text.isEmpty || _nameCtrl.text == widget.client.name) _nameCtrl.text = updated.name;
          if (_emailCtrl.text.isEmpty || _emailCtrl.text == widget.client.email) _emailCtrl.text = updated.email;

          String rawPhone = updated.phone?.trim() ?? '';
          CountryCode matchedCountry = kAllCountries.first;
          for (final country in kAllCountries) {
            if (rawPhone.startsWith(country.dialCode)) {
              matchedCountry = country;
              rawPhone = rawPhone.substring(country.dialCode.length).trim();
              break;
            }
          }
          _selectedCountry = matchedCountry;
          _phoneCtrl.text = rawPhone;

          _contractValueCtrl.text = updated.contractValue > 0 ? updated.contractValue.toStringAsFixed(0) : '0';
          _addressCtrl.text = updated.address ?? '';
          _gstinCtrl.text = updated.gstin ?? '';
          _deptCtrl.text = updated.department ?? '';
          _teamLeadCtrl.text = updated.teamLead ?? '';
          _categoryCtrl.text = updated.clientCategory ?? updated.templateUsed;
          _totalCountCtrl.text = updated.totalCount?.toString() ?? '';
          _shootCountCtrl.text = updated.shootCount?.toString() ?? '';
          _amountCtrl.text = updated.amount != null ? updated.amount!.toStringAsFixed(0) : (updated.contractValue > 0 ? updated.contractValue.toStringAsFixed(0) : '0');
          _cprCtrl.text = updated.cpr?.toString() ?? '';
          _cpaCtrl.text = updated.cpa?.toString() ?? '';
          _renewalDateCtrl.text = updated.renewalDate ?? '';
          _renewalStatusCtrl.text = updated.renewalStatus ?? 'ACTIVE';
          _dmTeamCtrl.text = updated.dmTeam ?? '';
          _designersCtrl.text = updated.designers ?? '';
          _editorsCtrl.text = updated.editors ?? '';
          _contentWritersCtrl.text = updated.contentWriters ?? '';
          _remarksCtrl.text = updated.remarks ?? '';
          if (updated.services.isNotEmpty) {
            _services = List<String>.from(updated.services);
          }
          if (updated.branchId != null) {
            _selectedBranchId = updated.branchId;
          }
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _contractValueCtrl.dispose();
    _addressCtrl.dispose();
    _gstinCtrl.dispose();
    _deptCtrl.dispose();
    _teamLeadCtrl.dispose();
    _categoryCtrl.dispose();
    _totalCountCtrl.dispose();
    _shootCountCtrl.dispose();
    _amountCtrl.dispose();
    _cprCtrl.dispose();
    _cpaCtrl.dispose();
    _renewalDateCtrl.dispose();
    _renewalStatusCtrl.dispose();
    _dmTeamCtrl.dispose();
    _designersCtrl.dispose();
    _editorsCtrl.dispose();
    _contentWritersCtrl.dispose();
    _remarksCtrl.dispose();
    _customServiceCtrl.dispose();
    super.dispose();
  }

  void _addService(String s) {
    final trimmed = s.trim();
    if (trimmed.isNotEmpty && !_services.contains(trimmed)) {
      setState(() => _services.add(trimmed));
    }
  }

  void _removeService(String s) {
    setState(() => _services.remove(s));
  }

  Future<void> _saveClient() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      AppSnackBar.showCustom(context, const SnackBar(content: Text('Client Name is required'), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isSaving = true);

    try {
      final contractVal = double.tryParse(_contractValueCtrl.text.trim()) ?? widget.client.contractValue;
      final amtVal = double.tryParse(_amountCtrl.text.trim()) ?? contractVal;
      final rawPhone = _phoneCtrl.text.trim();
      final fullPhone = rawPhone.isNotEmpty ? '${_selectedCountry.dialCode} $rawPhone' : '';

      final updateMap = <String, dynamic>{
        'name': name,
        'email': _emailCtrl.text.trim(),
        'phone': fullPhone,
        'service': _services.join(','),
        'contract_value': contractVal,
        'amount': amtVal,
        'address': _addressCtrl.text.trim(),
        'billing_address': _addressCtrl.text.trim(),
        'gstin': _gstinCtrl.text.trim(),
        'client_category': _categoryCtrl.text.trim(),
        'department': _deptCtrl.text.trim(),
        'team_lead': _teamLeadCtrl.text.trim(),
        'total_count': int.tryParse(_totalCountCtrl.text.trim()),
        'shoot_count': int.tryParse(_shootCountCtrl.text.trim()),
        'cpr': double.tryParse(_cprCtrl.text.trim()),
        'cpa': double.tryParse(_cpaCtrl.text.trim()),
        'renewal_date': _renewalDateCtrl.text.trim(),
        'renewal_status': _renewalStatusCtrl.text.trim(),
        'dm_team': _dmTeamCtrl.text.trim(),
        'designers': _designersCtrl.text.trim(),
        'editors': _editorsCtrl.text.trim(),
        'content_writers': _contentWritersCtrl.text.trim(),
        'remarks': _remarksCtrl.text.trim(),
      };

      if (_selectedBranchId != null && _selectedBranchId!.isNotEmpty) {
        updateMap['branch_id'] = _selectedBranchId;
      }

      await SupabaseService.client.from('clients').update(updateMap).eq('id', widget.client.id);

      if (mounted) {
        widget.onSaved();
        Navigator.pop(context);
        AppSnackBar.showCustom(
          context,
          SnackBar(
            content: Text('Client "$name" updated successfully!'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        AppSnackBar.showCustom(
          context,
          SnackBar(content: Text('Failed to update client: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgCard = isDark ? AppTheme.bgCardDark : Colors.white;
    final textPrimary = AppTheme.textPrimaryOf(context);
    final textSecondary = AppTheme.textSecondaryOf(context);
    final textMuted = AppTheme.textMutedOf(context);
    final border = AppTheme.borderOf(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: bgCard,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Header handle + Title bar
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(color: border, borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Edit Client', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary)),
                        const SizedBox(height: 2),
                        Text('Update the information for this active client.', style: TextStyle(fontSize: 12, color: textSecondary)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: textMuted),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: border),
            // Form body
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                children: [
                  // Client Name / Company
                  _buildLabel('Client Name / Company', isRequired: true),
                  const SizedBox(height: 6),
                  _buildInput(_nameCtrl, hint: 'Company Name'),
                  const SizedBox(height: 14),

                  // Email & Phone
                  LayoutBuilder(builder: (_, c) {
                    final isWide = c.maxWidth > 500;
                    return isWide
                        ? Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildLabel('Email'),
                                    const SizedBox(height: 6),
                                    _buildInput(_emailCtrl, hint: 'billing@acme.com', keyboardType: TextInputType.emailAddress),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildLabel('Phone'),
                                    const SizedBox(height: 6),
                                    _buildPhoneInput(_phoneCtrl),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('Email'),
                              const SizedBox(height: 6),
                              _buildInput(_emailCtrl, hint: 'billing@acme.com', keyboardType: TextInputType.emailAddress),
                              const SizedBox(height: 14),
                              _buildLabel('Phone'),
                              const SizedBox(height: 6),
                              _buildPhoneInput(_phoneCtrl),
                            ],
                          );
                  }),
                  const SizedBox(height: 14),

                  // SERVICES PROVIDED
                  _buildLabel('SERVICES PROVIDED', uppercase: true),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: border),
                            borderRadius: BorderRadius.circular(10),
                            color: isDark ? AppTheme.bgBaseDark : const Color(0xFFF9FAFB),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedStandardService,
                              isExpanded: true,
                              dropdownColor: isDark ? AppTheme.bgCardDark : Colors.white,
                              style: TextStyle(fontSize: 13, color: textPrimary),
                              items: _standardServicesOptions.map((opt) {
                                return DropdownMenuItem(value: opt, child: Text(opt));
                              }).toList(),
                              onChanged: (val) {
                                if (val != null && val != 'Add a standard service...') {
                                  _addService(val);
                                  setState(() => _selectedStandardService = 'Add a standard service...');
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildInput(_customServiceCtrl, hint: 'Or type custom service...'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00BCD4),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                        onPressed: () {
                          if (_customServiceCtrl.text.trim().isNotEmpty) {
                            _addService(_customServiceCtrl.text);
                            _customServiceCtrl.clear();
                          }
                        },
                        child: const Text('+ Add', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('Select from dropdown or type custom service and press Add.', style: TextStyle(fontSize: 10, color: textMuted)),
                  if (_services.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _services.map((s) => Chip(
                        label: Text(s, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        backgroundColor: const Color(0xFF00BCD4).withOpacity(0.15),
                        labelStyle: const TextStyle(color: Color(0xFF00BCD4)),
                        deleteIcon: const Icon(Icons.close, size: 14, color: Color(0xFF00BCD4)),
                        onDeleted: () => _removeService(s),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                      )).toList(),
                    ),
                  ],
                  const SizedBox(height: 14),

                  // Contract Value (₹)
                  _buildLabel('Contract Value (₹)'),
                  const SizedBox(height: 6),
                  _buildInput(_contractValueCtrl, hint: '0', keyboardType: TextInputType.number),
                  const SizedBox(height: 14),

                  // Business Address & GSTIN
                  LayoutBuilder(builder: (_, c) {
                    final isWide = c.maxWidth > 500;
                    return isWide
                        ? Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildLabel('Business Address'),
                                    const SizedBox(height: 6),
                                    _buildInput(_addressCtrl, hint: '123 Business Way, Kozhikode'),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        _buildLabel('GSTIN / Tax Registration'),
                                        Text('15-digit GSTIN', style: TextStyle(fontSize: 9, color: textMuted)),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    _buildInput(_gstinCtrl, hint: 'E.G. 32AAAAA0000A1Z5'),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('Business Address'),
                              const SizedBox(height: 6),
                              _buildInput(_addressCtrl, hint: '123 Business Way, Kozhikode'),
                              const SizedBox(height: 14),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildLabel('GSTIN / Tax Registration'),
                                  Text('15-digit GSTIN', style: TextStyle(fontSize: 9, color: textMuted)),
                                ],
                              ),
                              const SizedBox(height: 6),
                              _buildInput(_gstinCtrl, hint: 'E.G. 32AAAAA0000A1Z5'),
                            ],
                          );
                  }),
                  const SizedBox(height: 14),

                  // Assigned Branch
                  _buildLabel('Assigned Branch'),
                  const SizedBox(height: 6),
                  BlocBuilder<BranchCubit, BranchState>(
                    builder: (context, branchState) {
                      final branchOptions = [
                        if (branchState.calicutBranchId != null) {'id': branchState.calicutBranchId!, 'name': 'Head Office (Calicut)'},
                        if (branchState.dubaiBranchId != null) {'id': branchState.dubaiBranchId!, 'name': 'Dubai Branch'},
                      ];
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: border),
                          borderRadius: BorderRadius.circular(10),
                          color: isDark ? AppTheme.bgBaseDark : const Color(0xFFF9FAFB),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String?>(
                            value: branchOptions.any((b) => b['id'] == _selectedBranchId) ? _selectedBranchId : null,
                            isExpanded: true,
                            hint: Text('Select Branch...', style: TextStyle(fontSize: 13, color: textMuted)),
                            dropdownColor: isDark ? AppTheme.bgCardDark : Colors.white,
                            style: TextStyle(fontSize: 13, color: textPrimary),
                            items: [
                              DropdownMenuItem<String?>(value: null, child: Text('Default Branch', style: TextStyle(color: textMuted))),
                              ...branchOptions.map((b) => DropdownMenuItem<String?>(value: b['id'], child: Text(b['name']!))),
                            ],
                            onChanged: (val) => setState(() => _selectedBranchId = val),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('Assigned Department'),
                            const SizedBox(height: 6),
                            _buildDepartmentDropdown(),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('Assigned Team Lead'),
                            const SizedBox(height: 6),
                            _buildTeamLeadDropdown(),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Category, Total Count, Shoot Count, Amount
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('Client Category'),
                            const SizedBox(height: 6),
                            _buildInput(_categoryCtrl, hint: 'VIP / General'),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('Total Count'),
                            const SizedBox(height: 6),
                            _buildInput(_totalCountCtrl, hint: '0', keyboardType: TextInputType.number),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('Shoot Count'),
                            const SizedBox(height: 6),
                            _buildInput(_shootCountCtrl, hint: '0', keyboardType: TextInputType.number),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('Amount (₹)'),
                            const SizedBox(height: 6),
                            _buildInput(_amountCtrl, hint: '0', keyboardType: TextInputType.number),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // CPR, CPA, Renewal Date, Renewal Status
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('CPR (Cost Per Result ₹)'),
                            const SizedBox(height: 6),
                            _buildInput(_cprCtrl, hint: 'e.g. 45.00', keyboardType: TextInputType.number),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('CPA (Cost Per Acquisition ₹)'),
                            const SizedBox(height: 6),
                            _buildInput(_cpaCtrl, hint: 'e.g. 180.00', keyboardType: TextInputType.number),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('Renewal Date'),
                            const SizedBox(height: 6),
                            _buildRenewalDatePicker(),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('Renewal Status'),
                            const SizedBox(height: 6),
                            _buildInput(_renewalStatusCtrl, hint: 'PENDING / ACTIVE'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // DM Team, Designers, Editors, Content Writers
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('DM Team'),
                            const SizedBox(height: 6),
                            _buildInput(_dmTeamCtrl, hint: 'Team name'),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('Designers'),
                            const SizedBox(height: 6),
                            _buildInput(_designersCtrl, hint: 'Designer name'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('Editors'),
                            const SizedBox(height: 6),
                            _buildInput(_editorsCtrl, hint: 'Editor name'),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('Content Writers'),
                            const SizedBox(height: 6),
                            _buildInput(_contentWritersCtrl, hint: 'Writer name'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Remarks
                  _buildLabel('Remarks'),
                  const SizedBox(height: 6),
                  _buildInput(_remarksCtrl, hint: 'Additional client notes or comments...', maxLines: 3),
                  const SizedBox(height: 24),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00BCD4),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      onPressed: _isSaving ? null : _saveClient,
                      child: _isSaving
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Update Client', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text, {bool isRequired = false, bool uppercase = false}) {
    return Text(
      uppercase ? text.toUpperCase() : text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: AppTheme.textPrimaryOf(context),
      ),
    );
  }

  Widget _buildInput(TextEditingController ctrl, {String? hint, TextInputType keyboardType = TextInputType.text, int maxLines = 1}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: TextStyle(fontSize: 13, color: AppTheme.textPrimaryOf(context)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: AppTheme.textMutedOf(context), fontSize: 12),
        filled: true,
        fillColor: isDark ? AppTheme.bgBaseDark : const Color(0xFFF9FAFB),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppTheme.borderOf(context)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppTheme.borderOf(context)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF00BCD4), width: 1.5),
        ),
      ),
    );
  }

  Future<void> _showCountryPicker() async {
    final result = await showDialog<CountryCode>(
      context: context,
      builder: (_) => _CountryCodePickerDialog(selectedCountry: _selectedCountry),
    );
    if (result != null) {
      setState(() => _selectedCountry = result);
    }
  }

  Widget _buildPhoneInput(TextEditingController ctrl) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.borderOf(context)),
        borderRadius: BorderRadius.circular(10),
        color: isDark ? AppTheme.bgBaseDark : const Color(0xFFF9FAFB),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: _showCountryPicker,
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(10)),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              decoration: BoxDecoration(
                border: Border(right: BorderSide(color: AppTheme.borderOf(context))),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_selectedCountry.flag, style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 4),
                  Text(_selectedCountry.dialCode, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 2),
                  Icon(Icons.arrow_drop_down, size: 16, color: AppTheme.textMutedOf(context)),
                ],
              ),
            ),
          ),
          Expanded(
            child: TextField(
              controller: ctrl,
              keyboardType: TextInputType.phone,
              style: TextStyle(fontSize: 13, color: AppTheme.textPrimaryOf(context)),
              decoration: const InputDecoration(
                hintText: 'Phone number',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── SEARCHABLE COUNTRY CODE PICKER DIALOG ────────────────────────────────────

class _CountryCodePickerDialog extends StatefulWidget {
  final CountryCode selectedCountry;

  const _CountryCodePickerDialog({required this.selectedCountry});

  @override
  State<_CountryCodePickerDialog> createState() => _CountryCodePickerDialogState();
}

class _CountryCodePickerDialogState extends State<_CountryCodePickerDialog> {
  late TextEditingController _searchCtrl;
  late List<CountryCode> _filteredCountries;

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController();
    _filteredCountries = List.from(kAllCountries);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _filter(String query) {
    final q = query.toLowerCase().trim();
    setState(() {
      if (q.isEmpty) {
        _filteredCountries = List.from(kAllCountries);
      } else {
        _filteredCountries = kAllCountries.where((c) {
          return c.name.toLowerCase().contains(q) ||
                 c.dialCode.contains(q) ||
                 c.code.toLowerCase().contains(q);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgCard = isDark ? AppTheme.bgCardDark : Colors.white;
    final textPrimary = AppTheme.textPrimaryOf(context);
    final textMuted = AppTheme.textMutedOf(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: bgCard,
      child: Container(
        padding: const EdgeInsets.all(16),
        constraints: const BoxConstraints(maxHeight: 520, maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.public_rounded, color: Color(0xFF00BCD4)),
                const SizedBox(width: 8),
                Text(
                  'Select Country Code',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _searchCtrl,
              onChanged: _filter,
              style: TextStyle(fontSize: 13, color: textPrimary),
              decoration: InputDecoration(
                hintText: 'Search country or code (+91, UAE...)',
                hintStyle: TextStyle(color: textMuted, fontSize: 12),
                prefixIcon: Icon(Icons.search, size: 18, color: textMuted),
                filled: true,
                fillColor: isDark ? AppTheme.bgBaseDark : const Color(0xFFF9FAFB),
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppTheme.borderOf(context)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppTheme.borderOf(context)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF00BCD4)),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _filteredCountries.isEmpty
                  ? Center(
                      child: Text('No countries found', style: TextStyle(color: textMuted, fontSize: 13)),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: _filteredCountries.length,
                      separatorBuilder: (_, __) => Divider(height: 1, color: AppTheme.borderOf(context)),
                      itemBuilder: (ctx, i) {
                        final country = _filteredCountries[i];
                        final isSelected = country.code == widget.selectedCountry.code;

                        return ListTile(
                          dense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          leading: Text(country.flag, style: const TextStyle(fontSize: 22)),
                          title: Text(
                            country.name,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected ? const Color(0xFF00BCD4) : textPrimary,
                            ),
                          ),
                          trailing: Text(
                            country.dialCode,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? const Color(0xFF00BCD4) : textMuted,
                            ),
                          ),
                          onTap: () => Navigator.pop(context, country),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── COMPREHENSIVE CREATE PROJECT PROPOSAL SHEET ──────────────────────────────

class PricingItem {
  TextEditingController nameCtrl;
  TextEditingController descCtrl;
  TextEditingController amountCtrl;

  PricingItem({
    String name = '',
    String desc = '',
    String amount = '0',
  })  : nameCtrl = TextEditingController(text: name),
        descCtrl = TextEditingController(text: desc),
        amountCtrl = TextEditingController(text: amount);

  void dispose() {
    nameCtrl.dispose();
    descCtrl.dispose();
    amountCtrl.dispose();
  }
}

class TermItem {
  TextEditingController termCtrl;

  TermItem({String term = ''}) : termCtrl = TextEditingController(text: term);

  void dispose() {
    termCtrl.dispose();
  }
}

class CreateProposalSheet extends StatefulWidget {
  final String clientName;
  final String clientId;
  final double defaultAmount;

  const CreateProposalSheet({
    super.key,
    required this.clientName,
    required this.clientId,
    this.defaultAmount = 0.0,
  });

  @override
  State<CreateProposalSheet> createState() => _CreateProposalSheetState();
}

class _CreateProposalSheetState extends State<CreateProposalSheet> {
  late TextEditingController _proposalTitleCtrl;
  late TextEditingController _serviceNameCtrl;
  late TextEditingController _projectDescCtrl;
  late TextEditingController _gstPercentCtrl;
  late TextEditingController _validUntilCtrl;

  String _selectedServiceType = 'Web Development';
  final List<String> _serviceTypeOptions = [
    'Web Development',
    'Digital Marketing',
    'SEO Optimization',
    'Branding & Identity',
    'Graphic Design',
    'Video Editing',
    'Content Writing',
    'Social Media Management',
  ];

  late List<PricingItem> _pricingItems;
  late List<TermItem> _termItems;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _proposalTitleCtrl = TextEditingController(text: 'Proposal for ${widget.clientName}');
    _serviceNameCtrl = TextEditingController(text: 'Web Development & Digital Strategy');
    _projectDescCtrl = TextEditingController(text: 'Describe the scope of work, deliverables, and objectives...');
    _gstPercentCtrl = TextEditingController(text: '18');

    final futureDate = DateTime.now().add(const Duration(days: 15));
    final day = futureDate.day.toString().padLeft(2, '0');
    final month = futureDate.month.toString().padLeft(2, '0');
    final year = futureDate.year.toString();
    _validUntilCtrl = TextEditingController(text: '$day-$month-$year');

    _pricingItems = [
      PricingItem(
        name: 'Core Services',
        desc: 'Initial setup & project execution',
        amount: widget.defaultAmount > 0 ? widget.defaultAmount.toStringAsFixed(0) : '25000',
      ),
    ];

    _termItems = [
      TermItem(term: 'Payment should be made within 7 days of invoice generation.'),
      TermItem(term: '50% advance payment required to start the project.'),
    ];
  }

  @override
  void dispose() {
    _proposalTitleCtrl.dispose();
    _serviceNameCtrl.dispose();
    _projectDescCtrl.dispose();
    _gstPercentCtrl.dispose();
    _validUntilCtrl.dispose();
    for (var item in _pricingItems) {
      item.dispose();
    }
    for (var term in _termItems) {
      term.dispose();
    }
    super.dispose();
  }

  void _addPricingItem() {
    setState(() {
      _pricingItems.add(PricingItem(name: '', desc: '', amount: '0'));
    });
  }

  void _removePricingItem(int index) {
    if (_pricingItems.length > 1) {
      setState(() {
        _pricingItems[index].dispose();
        _pricingItems.removeAt(index);
      });
    }
  }

  void _addTermItem() {
    setState(() {
      _termItems.add(TermItem(term: ''));
    });
  }

  void _removeTermItem(int index) {
    if (_termItems.length > 1) {
      setState(() {
        _termItems[index].dispose();
        _termItems.removeAt(index);
      });
    }
  }

  Future<void> _selectValidDate() async {
    DateTime initial = DateTime.now().add(const Duration(days: 15));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now(),
      lastDate: DateTime(2035),
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? const ColorScheme.dark(primary: Color(0xFF00BCD4), onPrimary: Colors.white, surface: Color(0xFF1E293B))
                : const ColorScheme.light(primary: Color(0xFF00BCD4), onPrimary: Colors.white),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final day = picked.day.toString().padLeft(2, '0');
      final month = picked.month.toString().padLeft(2, '0');
      final year = picked.year.toString();
      setState(() {
        _validUntilCtrl.text = '$day-$month-$year';
      });
    }
  }

  Future<void> _generateProposal() async {
    if (_proposalTitleCtrl.text.trim().isEmpty) {
      AppSnackBar.showCustom(context, const SnackBar(content: Text('Proposal Title is required'), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isGenerating = true);

    try {
      double subtotal = 0;
      for (var item in _pricingItems) {
        subtotal += double.tryParse(item.amountCtrl.text.trim()) ?? 0;
      }
      final gst = double.tryParse(_gstPercentCtrl.text.trim()) ?? 18;
      final grandTotal = subtotal + (subtotal * gst / 100);

      try {
        await SupabaseService.client.from('proposals').insert({
          'client_id': widget.clientId,
          'title': _proposalTitleCtrl.text.trim(),
          'service_name': _serviceNameCtrl.text.trim(),
          'service_type': _selectedServiceType,
          'description': _projectDescCtrl.text.trim(),
          'subtotal': subtotal,
          'gst_percent': gst,
          'total_amount': grandTotal,
          'valid_until': _validUntilCtrl.text.trim(),
          'terms': _termItems.map((t) => t.termCtrl.text.trim()).toList(),
          'status': 'SENT',
          'created_at': DateTime.now().toIso8601String(),
        });
      } catch (_) {}

      if (mounted) {
        Navigator.pop(context);
        AppSnackBar.showCustom(
          context,
          SnackBar(
            content: Text('Proposal "${_proposalTitleCtrl.text}" generated successfully! Total: ₹${grandTotal.toStringAsFixed(0)}'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isGenerating = false);
        AppSnackBar.showCustom(context, SnackBar(content: Text('Error generating proposal: $e'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgCard = isDark ? AppTheme.bgCardDark : Colors.white;
    final textPrimary = AppTheme.textPrimaryOf(context);
    final textSecondary = AppTheme.textSecondaryOf(context);
    final textMuted = AppTheme.textMutedOf(context);
    final border = AppTheme.borderOf(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: bgCard,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar + Title
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(color: border, borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Create Project Proposal', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary)),
                        const SizedBox(height: 2),
                        Text('Draft a professional proposal for ${widget.clientName}. The template will be generated automatically.', style: TextStyle(fontSize: 11, color: textSecondary)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: textMuted),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: border),
            // Form body
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                children: [
                  // SECTION 1: PROPOSAL DETAILS
                  _buildSectionHeader('PROPOSAL DETAILS'),
                  const SizedBox(height: 8),
                  _buildInputLabel('Proposal Title', isRequired: true),
                  const SizedBox(height: 6),
                  _buildInput(_proposalTitleCtrl, hint: 'Proposal for ${widget.clientName}'),
                  const SizedBox(height: 16),

                  // SECTION 2: SERVICE INFORMATION
                  _buildSectionHeader('SERVICE INFORMATION'),
                  const SizedBox(height: 8),
                  LayoutBuilder(builder: (_, c) {
                    final isWide = c.maxWidth > 500;
                    return isWide
                        ? Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildInputLabel('Service Name', isRequired: true),
                                    const SizedBox(height: 6),
                                    _buildInput(_serviceNameCtrl, hint: 'e.g. E-Commerce Website, Mobile App'),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildInputLabel('Service Type', isRequired: true),
                                    const SizedBox(height: 6),
                                    _buildServiceTypeDropdown(isDark, border, textPrimary),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildInputLabel('Service Name', isRequired: true),
                              const SizedBox(height: 6),
                              _buildInput(_serviceNameCtrl, hint: 'e.g. E-Commerce Website, Mobile App'),
                              const SizedBox(height: 12),
                              _buildInputLabel('Service Type', isRequired: true),
                              const SizedBox(height: 6),
                              _buildServiceTypeDropdown(isDark, border, textPrimary),
                            ],
                          );
                  }),
                  const SizedBox(height: 12),
                  _buildInputLabel('Project Description'),
                  const SizedBox(height: 6),
                  _buildInput(_projectDescCtrl, hint: 'Describe the scope of work, deliverables, and objectives...', maxLines: 3),
                  const SizedBox(height: 16),

                  // SECTION 3: PRICING ITEMS
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSectionHeader('PRICING ITEMS'),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF00BCD4),
                          side: const BorderSide(color: Color(0xFF00BCD4)),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: _addPricingItem,
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Add Item', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ..._pricingItems.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final item = entry.value;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: border),
                        borderRadius: BorderRadius.circular(10),
                        color: isDark ? AppTheme.bgBaseDark : const Color(0xFFF9FAFB),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _buildInput(item.nameCtrl, hint: 'Item Name'),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 90,
                                child: _buildInput(item.amountCtrl, hint: '₹ 0', keyboardType: TextInputType.number),
                              ),
                              if (_pricingItems.length > 1)
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                  onPressed: () => _removePricingItem(idx),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          _buildInput(item.descCtrl, hint: 'Description (optional)'),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 16),

                  // SECTION 4: GST & VALIDITY
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInputLabel('GST Percentage (%)'),
                            const SizedBox(height: 6),
                            _buildInput(_gstPercentCtrl, hint: '18', keyboardType: TextInputType.number),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInputLabel('Proposal Valid Until'),
                            const SizedBox(height: 6),
                            InkWell(
                              onTap: _selectValidDate,
                              borderRadius: BorderRadius.circular(10),
                              child: IgnorePointer(
                                child: _buildInput(_validUntilCtrl, hint: 'dd-mm-yyyy'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // SECTION 5: TERMS & CONDITIONS
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSectionHeader('TERMS & CONDITIONS'),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF00BCD4),
                          side: const BorderSide(color: Color(0xFF00BCD4)),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: _addTermItem,
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Add Term', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ..._termItems.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final term = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildInput(term.termCtrl, hint: 'Enter term or condition...'),
                          ),
                          if (_termItems.length > 1)
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                              onPressed: () => _removeTermItem(idx),
                            ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 24),

                  // GENERATE PROPOSAL BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00BCD4),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      onPressed: _isGenerating ? null : _generateProposal,
                      child: _isGenerating
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('GENERATE PROPOSAL PDF', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: Color(0xFF00BCD4),
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildInputLabel(String text, {bool isRequired = false}) {
    return Row(
      children: [
        Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryOf(context))),
        if (isRequired) const Text(' *', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildInput(TextEditingController ctrl, {String? hint, TextInputType keyboardType = TextInputType.text, int maxLines = 1}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: TextStyle(fontSize: 13, color: AppTheme.textPrimaryOf(context)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: AppTheme.textMutedOf(context), fontSize: 12),
        filled: true,
        fillColor: isDark ? AppTheme.bgBaseDark : const Color(0xFFF9FAFB),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppTheme.borderOf(context)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppTheme.borderOf(context)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF00BCD4), width: 1.5),
        ),
      ),
    );
  }

  Widget _buildServiceTypeDropdown(bool isDark, Color border, Color textPrimary) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(10),
        color: isDark ? AppTheme.bgBaseDark : const Color(0xFFF9FAFB),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedServiceType,
          isExpanded: true,
          dropdownColor: isDark ? AppTheme.bgCardDark : Colors.white,
          style: TextStyle(fontSize: 13, color: textPrimary),
          items: _serviceTypeOptions.map((opt) {
            return DropdownMenuItem(value: opt, child: Text(opt));
          }).toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() => _selectedServiceType = val);
            }
          },
        ),
      ),
    );
  }
}

// ─── PROCESS CLIENT RENEWAL PAYMENT SHEET ─────────────────────────────────────

class _ProcessClientRenewalSheet extends StatefulWidget {
  final ActiveClient client;
  final VoidCallback onSaved;

  const _ProcessClientRenewalSheet({
    required this.client,
    required this.onSaved,
  });

  @override
  State<_ProcessClientRenewalSheet> createState() => _ProcessClientRenewalSheetState();
}

class _ProcessClientRenewalSheetState extends State<_ProcessClientRenewalSheet> {
  late DateTime _renewedDate;
  late DateTime _nextRenewalDate;
  late TextEditingController _amountCtrl;
  late TextEditingController _notesCtrl;
  String _selectedCycle = 'Monthly (+1 Month)';
  bool _isSubmitting = false;

  final List<String> _cycleOptions = [
    'Monthly (+1 Month)',
    'Quarterly (+3 Months)',
    'Half-Yearly (+6 Months)',
    'Yearly (+1 Year)',
    'Custom',
  ];

  @override
  void initState() {
    super.initState();
    _renewedDate = DateTime.now();
    final initialAmt = widget.client.contractValue > 0
        ? widget.client.contractValue
        : (widget.client.amount ?? 0.0);
    _amountCtrl = TextEditingController(
      text: initialAmt > 0 ? initialAmt.toStringAsFixed(0) : '10000',
    );
    _notesCtrl = TextEditingController();
    _nextRenewalDate = DateTime.now();
    _calculateNextRenewalDate();
  }

  void _calculateNextRenewalDate() {
    setState(() {
      switch (_selectedCycle) {
        case 'Monthly (+1 Month)':
          _nextRenewalDate = DateTime(_renewedDate.year, _renewedDate.month + 1, _renewedDate.day);
          break;
        case 'Quarterly (+3 Months)':
          _nextRenewalDate = DateTime(_renewedDate.year, _renewedDate.month + 3, _renewedDate.day);
          break;
        case 'Half-Yearly (+6 Months)':
          _nextRenewalDate = DateTime(_renewedDate.year, _renewedDate.month + 6, _renewedDate.day);
          break;
        case 'Yearly (+1 Year)':
          _nextRenewalDate = DateTime(_renewedDate.year + 1, _renewedDate.month, _renewedDate.day);
          break;
        case 'Custom':
          break;
      }
    });
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitRenewal() async {
    final amount = double.tryParse(_amountCtrl.text.trim()) ?? 0.0;
    if (amount <= 0) {
      AppSnackBar.showCustom(
        context,
        const SnackBar(
          content: Text('Please enter a valid renewal amount.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final nextDateStr = DateFormat('yyyy-MM-dd').format(_nextRenewalDate);
      final notes = _notesCtrl.text.trim();

      // 1. Update client status & renewal date in Supabase
      await SupabaseService.client.from('clients').update({
        'renewal_status': 'RENEWED',
        'renewal_date': nextDateStr,
        'amount': amount,
        'contract_value': amount,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', widget.client.id);

      // 2. Add income entry so payment reflects in Income & Sales section
      final user = SupabaseService.currentUser;
      final orgId = widget.client.branchId ?? user?.id ?? '00000000-0000-0000-0000-000000000000';

      await FinancialsService.addIncomeEntry(
        IncomeEntryModel(
          organizationId: orgId,
          date: _renewedDate,
          categoryName: 'Retainers',
          name: 'Renewal Payment - ${widget.client.name}',
          clientId: widget.client.id,
          clientName: widget.client.name,
          amount: amount,
          paymentMethod: 'Bank Transfer',
          notes: notes.isNotEmpty
              ? notes
              : 'Client renewal payment received for ${widget.client.name}. Next due: $nextDateStr',
        ),
      );

      if (mounted) {
        widget.onSaved();
        Navigator.pop(context);
        AppSnackBar.showCustom(
          context,
          SnackBar(
            content: Text('Renewal payment recorded & added to Income for ${widget.client.name}!'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        AppSnackBar.showCustom(
          context,
          SnackBar(
            content: Text('Failed to process renewal payment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppTheme.bgCardDark : Colors.white;
    final textPrimary = AppTheme.textPrimaryOf(context);
    final textSecondary = AppTheme.textSecondaryOf(context);
    final border = AppTheme.borderOf(context);

    final formattedNextDueDate = DateFormat('EEEE, MMMM dd, yyyy').format(_nextRenewalDate);

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 580),
      child: AnimatedPadding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        duration: const Duration(milliseconds: 100),
        curve: Curves.decelerate,
        child: Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 16,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── 1. HEADER BAR ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 16, 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.credit_card_rounded, color: Color(0xFF10B981), size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'PROCESS CLIENT RENEWAL PAYMENT',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF10B981),
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(height: 2),
                            RichText(
                              text: TextSpan(
                                style: TextStyle(fontSize: 12, color: textSecondary),
                                children: [
                                  const TextSpan(text: 'Record renewal payment for '),
                                  TextSpan(
                                    text: widget.client.name,
                                    style: TextStyle(fontWeight: FontWeight.bold, color: textPrimary),
                                  ),
                                  const TextSpan(text: ' and calculate the next renewal date.'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close_rounded, color: textSecondary, size: 20),
                        onPressed: () => Navigator.pop(context),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1),

                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── 2. CLIENT INFO CARD ──
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.client.name,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Contact: ${widget.client.name}',
                                  style: TextStyle(fontSize: 12, color: textSecondary),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'CURRENT STATUS',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textMutedOf(context),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEF3C7),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    (widget.client.renewalStatus ?? 'PENDING').toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFFD97706),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ── 3. FORM FIELDS ──
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isWide = constraints.maxWidth > 420;

                          final renewedDateField = _buildFieldContainer(
                            label: 'RENEWED DATE *',
                            labelIcon: Icons.calendar_today_outlined,
                            labelColor: const Color(0xFF10B981),
                            helperText: 'Date payment was received',
                            bgColor: const Color(0xFFECFDF5),
                            borderColor: const Color(0xFF10B981),
                            child: InkWell(
                              onTap: () async {
                                final d = await showDatePicker(
                                  context: context,
                                  initialDate: _renewedDate,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2035),
                                );
                                if (d != null) {
                                  setState(() {
                                    _renewedDate = d;
                                    _calculateNextRenewalDate();
                                  });
                                }
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      DateFormat('dd-MM-yyyy').format(_renewedDate),
                                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textPrimary),
                                    ),
                                    const Icon(Icons.calendar_month, size: 18, color: Color(0xFF10B981)),
                                  ],
                                ),
                              ),
                            ),
                          );

                          final renewalCycleField = _buildFieldContainer(
                            label: 'RENEWAL CYCLE *',
                            labelIcon: Icons.autorenew,
                            labelColor: const Color(0xFF0284C7),
                            helperText: 'Billing frequency',
                            bgColor: const Color(0xFFF0F9FF),
                            borderColor: const Color(0xFF0284C7).withOpacity(0.4),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedCycle,
                                  isExpanded: true,
                                  icon: const Icon(Icons.keyboard_arrow_down, size: 20, color: Color(0xFF0284C7)),
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary),
                                  dropdownColor: bg,
                                  items: _cycleOptions
                                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                                      .toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() {
                                        _selectedCycle = val;
                                        _calculateNextRenewalDate();
                                      });
                                    }
                                  },
                                ),
                              ),
                            ),
                          );

                          final amountField = _buildFieldContainer(
                            label: 'RENEWAL AMOUNT (₹) *',
                            labelIcon: Icons.attach_money,
                            labelColor: const Color(0xFF10B981),
                            bgColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                            borderColor: border,
                            child: TextField(
                              controller: _amountCtrl,
                              keyboardType: TextInputType.number,
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textPrimary),
                              decoration: const InputDecoration(
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                border: InputBorder.none,
                              ),
                            ),
                          );

                          final nextRenewalDateField = _buildFieldContainer(
                            label: 'NEXT RENEWAL DATE *',
                            labelIcon: Icons.access_time,
                            labelColor: const Color(0xFF6366F1),
                            bgColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                            borderColor: border,
                            child: InkWell(
                              onTap: () async {
                                final d = await showDatePicker(
                                  context: context,
                                  initialDate: _nextRenewalDate,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2035),
                                );
                                if (d != null) {
                                  setState(() => _nextRenewalDate = d);
                                }
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      DateFormat('dd-MM-yyyy').format(_nextRenewalDate),
                                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textPrimary),
                                    ),
                                    const Icon(Icons.calendar_today_outlined, size: 18, color: Color(0xFF6366F1)),
                                  ],
                                ),
                              ),
                            ),
                          );

                          if (isWide) {
                            return Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(child: renewedDateField),
                                    const SizedBox(width: 12),
                                    Expanded(child: renewalCycleField),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                Row(
                                  children: [
                                    Expanded(child: amountField),
                                    const SizedBox(width: 12),
                                    Expanded(child: nextRenewalDateField),
                                  ],
                                ),
                              ],
                            );
                          } else {
                            return Column(
                              children: [
                                renewedDateField,
                                const SizedBox(height: 12),
                                renewalCycleField,
                                const SizedBox(height: 12),
                                amountField,
                                const SizedBox(height: 12),
                                nextRenewalDateField,
                              ],
                            );
                          }
                        },
                      ),

                      const SizedBox(height: 16),

                      // ── 4. INFO BANNER BOX ──
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFC7D2FE)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF6366F1), size: 22),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Next Due Date: $formattedNextDueDate',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF4338CA),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  RichText(
                                    text: const TextSpan(
                                      style: TextStyle(fontSize: 11, color: Color(0xFF6366F1)),
                                      children: [
                                        TextSpan(text: 'Status will be marked as '),
                                        TextSpan(
                                          text: 'RENEWED',
                                          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF059669)),
                                        ),
                                        TextSpan(text: '.'),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ── 5. PAYMENT NOTES FIELD ──
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'PAYMENT NOTES / TRANSACTION REF',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: textPrimary,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _notesCtrl,
                            maxLines: 3,
                            style: TextStyle(fontSize: 13, color: textPrimary),
                            decoration: InputDecoration(
                              hintText: 'e.g. Paid via UPI ref #940182, Invoice #INV-102',
                              hintStyle: TextStyle(color: AppTheme.textMutedOf(context), fontSize: 12),
                              filled: true,
                              fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                              contentPadding: const EdgeInsets.all(12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: border),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: border),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: Color(0xFF10B981)),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // ── 6. BUTTONS (100% Responsive for all device screen sizes) ──
                      LayoutBuilder(
                        builder: (context, btnConstraints) {
                          final isCompact = btnConstraints.maxWidth < 420;
                          if (isCompact) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: _isSubmitting ? null : _submitRenewal,
                                  icon: _isSubmitting
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                        )
                                      : const Icon(Icons.auto_awesome, size: 16, color: Colors.white),
                                  label: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      _isSubmitting ? 'CONFIRMING...' : 'CONFIRM RENEWAL PAYMENT',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF00A86B),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                                    elevation: 0,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                OutlinedButton(
                                  onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(color: border),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  ),
                                  child: Text(
                                    'Cancel',
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary),
                                  ),
                                ),
                              ],
                            );
                          } else {
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                OutlinedButton(
                                  onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(color: border),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  ),
                                  child: Text(
                                    'Cancel',
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Flexible(
                                  child: ElevatedButton.icon(
                                    onPressed: _isSubmitting ? null : _submitRenewal,
                                    icon: _isSubmitting
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                          )
                                        : const Icon(Icons.auto_awesome, size: 16, color: Colors.white),
                                    label: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        _isSubmitting ? 'CONFIRMING...' : 'CONFIRM RENEWAL PAYMENT',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF00A86B),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                      elevation: 0,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFieldContainer({
    required String label,
    required IconData labelIcon,
    required Color labelColor,
    required Widget child,
    String? helperText,
    Color? bgColor,
    Color? borderColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(labelIcon, size: 13, color: labelColor),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: labelColor,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: bgColor ?? Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor ?? Colors.grey.shade300),
          ),
          child: child,
        ),
        if (helperText != null) ...[
          const SizedBox(height: 3),
          Text(
            helperText,
            style: TextStyle(fontSize: 10, color: labelColor.withOpacity(0.8)),
          ),
        ],
      ],
    );
  }
}
