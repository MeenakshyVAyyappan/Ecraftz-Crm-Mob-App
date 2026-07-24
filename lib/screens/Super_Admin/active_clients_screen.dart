import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import '../../widgets/app_drawer.dart';
import '../../models/client_model.dart';
import '../../blocs/client/client_bloc.dart';
import '../../theme/app_theme.dart';
import '../../blocs/theme/theme_bloc.dart';

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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  Color get _bg => Theme.of(context).scaffoldBackgroundColor;
  Color get _border => AppTheme.borderOf(context);
  Color get _textPrimary => AppTheme.textPrimaryOf(context);
  Color get _textSecondary => AppTheme.textSecondaryOf(context);

  @override
  void initState() {
    super.initState();
    context.read<ClientBloc>().add(LoadClientsEvent());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<ActiveClient> _filtered(List<ActiveClient> clients) {
    if (_searchQuery.isEmpty) return clients;
    final q = _searchQuery.toLowerCase();
    return clients.where((c) =>
        c.name.toLowerCase().contains(q) ||
        c.email.toLowerCase().contains(q) ||
        c.services.any((s) => s.toLowerCase().contains(q))).toList();
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
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('\${clients.length} client(s) imported successfully'),
                  backgroundColor: const Color(0xFF10B981),
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _InvoiceSheet(client: client),
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
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Client removed'), backgroundColor: Colors.red),
              );
            },
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
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
      body: BlocBuilder<ClientBloc, ClientState>(
        builder: (context, state) {
          final allClients = state.clients;
          final clients = _filtered(allClients);
          return Column(
            children: [
              // Stats strip
              _buildStatsStrip(allClients),
              // Search bar
              Container(
                color: Theme.of(context).colorScheme.surface,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _searchQuery = v),
                  style: TextStyle(color: _textPrimary, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Search active clients...',
                    hintStyle: TextStyle(color: AppTheme.textMutedOf(context), fontSize: 13),
                    prefixIcon: Icon(Icons.search, color: AppTheme.textMutedOf(context), size: 18),
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
                ),
              ),
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
          _statChip('Contract Value', '\$${_formatValue(totalValue)}', const Color(0xFF10B981)),
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
          onDetails: () => _showClientDetail(clients[i]),
          onInvoice: () => _showInvoice(clients[i]),
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
              onDetails: () => _showClientDetail(clients[i]),
              onInvoice: () => _showInvoice(clients[i]),
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

class _ClientRow extends StatelessWidget {
  final ActiveClient client;
  final bool isLast;
  final bool isWide;
  final VoidCallback onDetails;
  final VoidCallback onInvoice;
  final VoidCallback onDelete;

  const _ClientRow({
    required this.client,
    required this.isLast,
    required this.isWide,
    required this.onDetails,
    required this.onInvoice,
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
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Remove Client', style: TextStyle(color: Colors.red, fontSize: 13)),
                    ),
                  ],
                  onSelected: (v) {
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
                          ? '\$${client.contractValue.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}'
                          : '\$0',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: client.contractValue > 0 ? textPrimary : textMuted,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    _ActionBtn(
                      icon: Icons.info_outline_rounded,
                      label: 'Details',
                      onTap: onDetails,
                      color: const Color(0xFF00BCD4),
                    ),
                    const SizedBox(width: 8),
                    _ActionBtn(
                      icon: Icons.receipt_long_outlined,
                      label: 'Invoice',
                      onTap: onInvoice,
                      color: const Color(0xFF00BCD4),
                    ),
                  ],
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
                  ? '\$${client.contractValue.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}'
                  : '\$0',
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
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                        value: 'delete',
                        child: Text('Remove Client',
                            style: TextStyle(color: Colors.red, fontSize: 13))),
                  ],
                  onSelected: (v) {
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

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
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
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle, size: 8, color: Color(0xFF10B981)),
                        SizedBox(width: 5),
                        Text('Active',
                            style: TextStyle(
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
                  _DetailSection(
                    title: 'Services',
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
                  _DetailSection(
                    title: 'Contract Details',
                    icon: Icons.attach_money_rounded,
                    child: Column(
                      children: [
                        _DetailRow(
                            'Contract Value',
                            client.contractValue > 0
                                ? '\$${client.contractValue.toStringAsFixed(0)}'
                                : 'Not set'),
                        _DetailRow('Onboarded',
                            _formatDate(client.onboardedAt)),
                        _DetailRow('Template Used', client.templateUsed),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _DetailSection(
                    title: 'Contact Information',
                    icon: Icons.person_outline_rounded,
                    child: Column(
                      children: [
                        _DetailRow('Email', client.email),
                        _DetailRow('Client Name', client.name),
                      ],
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
                                        '\$${perService.toStringAsFixed(0)}',
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
                                  '\$${client.contractValue.toStringAsFixed(0)}',
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
