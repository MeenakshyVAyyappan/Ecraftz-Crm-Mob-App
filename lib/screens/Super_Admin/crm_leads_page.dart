import 'package:ecraftz_crm/widgets/app_snackbar.dart';
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/app_refresh_button.dart';
import '../../widgets/branch_switcher.dart';
import '../../models/lead_model.dart';
import '../../blocs/lead/lead_bloc.dart';
import '../../blocs/branch/branch_cubit.dart';
import '../../theme/app_theme.dart';
import '../../blocs/theme/theme_bloc.dart';
import '../../services/lead_import_service.dart';

Future<void> _launchUrl(Uri uri, BuildContext context, {String failureMessage = 'Could not open link'}) async {
  try {
    await launchUrl(uri, mode: LaunchMode.externalNonBrowserApplication);
  } catch (_) {
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      AppSnackBar.showCustom(context, 
        SnackBar(content: Text(failureMessage), backgroundColor: Colors.red),
      );
    }
  }
}

String _normalizePhone(String phone) {
  return phone.replaceAll(RegExp(r'[^0-9+]'), '');
}

Future<void> _callPhone(String phone, BuildContext context) async {
  final normalized = _normalizePhone(phone);
  if (normalized.isEmpty) {
    AppSnackBar.showCustom(context, 
      const SnackBar(content: Text('Phone number not available'), backgroundColor: Colors.red),
    );
    return;
  }
  final uri = Uri(scheme: 'tel', path: normalized);
  await _launchUrl(uri, context, failureMessage: 'Could not place the call.');
}

Future<void> _sendSms(String phone, BuildContext context) async {
  final normalized = _normalizePhone(phone);
  if (normalized.isEmpty) {
    AppSnackBar.showCustom(context, 
      const SnackBar(content: Text('Phone number not available'), backgroundColor: Colors.red),
    );
    return;
  }
  final body = Uri.encodeComponent('Hi, I wanted to follow up regarding your lead status.');
  final uri = Uri.parse('sms:$normalized?body=$body');
  await _launchUrl(uri, context, failureMessage: 'Could not send SMS.');
}

Future<void> _sendWhatsApp(String phone, BuildContext context) async {
  final normalized = _normalizePhone(phone).replaceAll('+', '');
  if (normalized.isEmpty) {
    AppSnackBar.showCustom(context, 
      const SnackBar(content: Text('Phone number not available'), backgroundColor: Colors.red),
    );
    return;
  }
  final text = Uri.encodeComponent('Hello, I wanted to follow up regarding your lead status.');
  final uri = Uri.parse('https://wa.me/$normalized?text=$text');
  await _launchUrl(uri, context, failureMessage: 'Could not launch WhatsApp.');
}

Future<void> _sendEmail(String email, BuildContext context) async {
  if (email.isEmpty) {
    AppSnackBar.showCustom(context, 
      const SnackBar(content: Text('Email address not available'), backgroundColor: Colors.red),
    );
    return;
  }
  final subject = Uri.encodeComponent('Follow-up from Ecraftz CRM');
  final body = Uri.encodeComponent('Hello,\n\nI am reaching out regarding your lead. Please let me know when you are available to discuss.\n\nRegards,\nEcraftz Team');
  final uri = Uri.parse('mailto:$email?subject=$subject&body=$body');
  await _launchUrl(uri, context, failureMessage: 'Could not launch the email client.');
}

// ─── MAIN PAGE ────────────────────────────────────────────────────────────────

class CRMLeadsPage extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;
  final bool showAppBar;

  const CRMLeadsPage({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    this.showAppBar = true,
  });

  @override
  State<CRMLeadsPage> createState() => _CRMLeadsPageState();
}

class _CRMLeadsPageState extends State<CRMLeadsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isKanban = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ScrollController _kanbanScrollController = ScrollController();
  Offset? _lastDragOffset;
  Timer? _scrollTimer;

  void _handleDragMove(DragTargetDetails<Lead> details) {
    _lastDragOffset = details.offset;
    _startScrollTimerIfNecessary();
  }

  void _startScrollTimerIfNecessary() {
    if (_scrollTimer != null) return;
    _scrollTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (_lastDragOffset == null) {
        _cancelScrollTimer();
        return;
      }
      final dx = _lastDragOffset!.dx;
      final screenWidth = MediaQuery.of(context).size.width;
      const threshold = 60.0;
      const scrollStep = 15.0;

      if (dx < threshold) {
        if (_kanbanScrollController.hasClients) {
          final newOffset = (_kanbanScrollController.offset - scrollStep)
              .clamp(0.0, _kanbanScrollController.position.maxScrollExtent);
          _kanbanScrollController.jumpTo(newOffset);
        }
      } else if (dx > screenWidth - threshold) {
        if (_kanbanScrollController.hasClients) {
          final newOffset = (_kanbanScrollController.offset + scrollStep)
              .clamp(0.0, _kanbanScrollController.position.maxScrollExtent);
          _kanbanScrollController.jumpTo(newOffset);
        }
      } else {
        _cancelScrollTimer();
      }
    });
  }

  void _cancelScrollTimer() {
    _scrollTimer?.cancel();
    _scrollTimer = null;
  }

  void _handleDragEnd() {
    _cancelScrollTimer();
    _lastDragOffset = null;
  }

  List<Lead> _filteredLeads(List<Lead> leads) {
    if (_searchQuery.isEmpty) return leads;
    final q = _searchQuery.toLowerCase();
    return leads.where((l) =>
      l.fullName.toLowerCase().contains(q) ||
      l.email.toLowerCase().contains(q) ||
      l.companyName.toLowerCase().contains(q)).toList();
  }

  Map<LeadStatus, List<Lead>> _leadsByStatus(List<Lead> filteredLeads) {
    final map = <LeadStatus, List<Lead>>{};
    for (final s in LeadStatus.values) {
      map[s] = filteredLeads.where((l) => l.status == s).toList();
    }
    return map;
  }

  Color get _bg => Theme.of(context).scaffoldBackgroundColor;
  Color get _border => AppTheme.borderOf(context);
  Color get _textPrimary => AppTheme.textPrimaryOf(context);
  Color get _textSecondary => AppTheme.textSecondaryOf(context);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: LeadStatus.values.length, vsync: this);
    context.read<LeadBloc>().add(
          LoadLeadsEvent(branchState: context.read<BranchCubit>().state),
        );
  }

  @override
  void dispose() {
    _cancelScrollTimer();
    _kanbanScrollController.dispose();
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _showAddLeadDialog({Lead? existing}) {
    showDialog(
      context: context,
      builder: (_) => _AddLeadDialog(
        existing: existing,
        onSave: (lead) {
          if (existing != null) {
            context.read<LeadBloc>().add(UpdateLeadEvent(lead));
          } else {
            context.read<LeadBloc>().add(AddLeadEvent(lead));
          }
        },
      ),
    );
  }

  void _deleteLead(Lead lead) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Lead'),
        content: Text('Remove ${lead.fullName} from CRM?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              context.read<LeadBloc>().add(DeleteLeadEvent(lead.id));
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _changeStatus(Lead lead, LeadStatus newStatus) {
    context.read<LeadBloc>().add(ChangeLeadStatusEvent(lead.id, newStatus));
  }

  bool _isSelectionMode = false;
  final Set<String> _selectedLeadIds = {};

  void _toggleSelection(String leadId) {
    setState(() {
      if (_selectedLeadIds.contains(leadId)) {
        _selectedLeadIds.remove(leadId);
        if (_selectedLeadIds.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedLeadIds.add(leadId);
        _isSelectionMode = true;
      }
    });
  }

  void _selectAll(List<Lead> filteredLeads) {
    setState(() {
      _isSelectionMode = true;
      _selectedLeadIds.clear();
      for (var l in filteredLeads) {
        _selectedLeadIds.add(l.id);
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _isSelectionMode = false;
      _selectedLeadIds.clear();
    });
  }

  void _confirmBulkDelete() {
    if (_selectedLeadIds.isEmpty) return;
    final count = _selectedLeadIds.length;

    showDialog(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Delete Selected Leads'),
        content: Text(
          'Are you sure you want to delete the $count selected lead(s)? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dlgCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(dlgCtx);
              context.read<LeadBloc>().add(
                    BulkDeleteLeadsEvent(
                      _selectedLeadIds.toList(),
                      branchState: context.read<BranchCubit>().state,
                    ),
                  );
              setState(() {
                _selectedLeadIds.clear();
                _isSelectionMode = false;
              });
              AppSnackBar.showSuccess(
                context,
                '$count lead(s) deleted successfully.',
              );
            },
            child: Text('Delete ($count)'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleExcelImport() async {
    final service = LeadImportService();
    final fileResult = await service.pickExcelFile();
    if (fileResult == null || fileResult.files.isEmpty) return;

    final file = fileResult.files.first;
    Uint8List? bytes = file.bytes;
    if (bytes == null && file.path != null) {
      bytes = await File(file.path!).readAsBytes();
    }
    if (bytes == null) {
      if (mounted) AppSnackBar.showError(context, 'Unable to read selected file.');
      return;
    }

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(color: Color(0xFF00BCD4)),
            SizedBox(width: 16),
            Expanded(child: Text('Importing leads from Excel...')),
          ],
        ),
      ),
    );

    final activeBranchId = context.read<BranchCubit>().state.activeBranchId;
    final result = await service.importLeadsFromExcel(
      bytes: bytes,
      branchId: activeBranchId,
    );

    if (mounted) {
      Navigator.pop(context); // Close progress dialog
      _showImportResultDialog(context, result);
      context.read<LeadBloc>().add(
            LoadLeadsEvent(branchState: context.read<BranchCubit>().state),
          );
    }
  }

  void _showImportResultDialog(BuildContext context, ImportResult result) {
    showDialog(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.file_upload_outlined, color: Color(0xFF10B981)),
            SizedBox(width: 8),
            Text('Import Results',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _resultBadge('Imported', '${result.successCount}', const Color(0xFF10B981)),
                  _resultBadge('Duplicates', '${result.duplicateCount}', const Color(0xFFF59E0B)),
                  _resultBadge('Failed', '${result.failedCount}', Colors.redAccent),
                ],
              ),
              const SizedBox(height: 16),
              if (result.errorDetails.isNotEmpty) ...[
                const Text('Validation & Warning Logs:',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Container(
                  constraints: const BoxConstraints(maxHeight: 180),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.withOpacity(0.3)),
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: result.errorDetails.length,
                    itemBuilder: (_, i) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      child: Text(
                        '• ${result.errorDetails[i]}',
                        style: const TextStyle(fontSize: 11, color: Colors.redAccent),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00BCD4),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dlgCtx),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Widget _resultBadge(String label, String count, Color color) {
    return Column(
      children: [
        Text(count, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: TextStyle(fontSize: 11, color: color)),
      ],
    );
  }

  Widget _buildSelectionBottomBar(List<Lead> filteredLeads) {
    final count = _selectedLeadIds.length;
    final allSelected = count > 0 && count == filteredLeads.length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(top: BorderSide(color: _border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _clearSelection,
              tooltip: 'Cancel Selection',
            ),
            const SizedBox(width: 4),
            Text(
              '$count Selected',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: _textPrimary,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () {
                if (allSelected) {
                  _clearSelection();
                } else {
                  _selectAll(filteredLeads);
                }
              },
              icon: Icon(
                allSelected ? Icons.deselect_rounded : Icons.select_all_rounded,
                size: 16,
                color: const Color(0xFF00BCD4),
              ),
              label: Text(
                allSelected ? 'Deselect All' : 'Select All',
                style: const TextStyle(
                  color: Color(0xFF00BCD4),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              onPressed: count > 0 ? _confirmBulkDelete : null,
              icon: const Icon(Icons.delete_forever_rounded, size: 16),
              label: Text('Delete ($count)', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
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
      bottomNavigationBar: _isSelectionMode
          ? BlocBuilder<LeadBloc, LeadState>(
              builder: (context, state) =>
                  _buildSelectionBottomBar(_filteredLeads(state.leads)),
            )
          : null,
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
        leading: _isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: _clearSelection,
              )
            : (isWide
                ? null
                : IconButton(
                    icon: Icon(Icons.menu_rounded, color: isDark ? Colors.white : const Color(0xFF374151)),
                    onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                  )),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                _isSelectionMode
                    ? '${_selectedLeadIds.length} Selected'
                    : 'Lead Management',
                style: TextStyle(
                    color: _textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700)),
            if (!isWide && !_isSelectionMode)
              Text('Manage your pipeline',
                  style: TextStyle(color: _textSecondary, fontSize: 11)),
          ],
        ),
        actions: _isSelectionMode
            ? [
                BlocBuilder<LeadBloc, LeadState>(
                  builder: (context, state) {
                    final filtered = _filteredLeads(state.leads);
                    final allSelected = _selectedLeadIds.isNotEmpty &&
                        _selectedLeadIds.length == filtered.length;
                    return TextButton.icon(
                      onPressed: () {
                        if (allSelected) {
                          _clearSelection();
                        } else {
                          _selectAll(filtered);
                        }
                      },
                      icon: Icon(
                        allSelected
                            ? Icons.deselect_rounded
                            : Icons.select_all_rounded,
                        size: 16,
                        color: const Color(0xFF00BCD4),
                      ),
                      label: Text(
                        allSelected ? 'Deselect All' : 'Select All',
                        style: const TextStyle(
                            color: Color(0xFF00BCD4),
                            fontWeight: FontWeight.w600,
                            fontSize: 12),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete_forever_rounded,
                      color: Colors.redAccent),
                  onPressed: _confirmBulkDelete,
                  tooltip: 'Delete Selected',
                ),
              ]
            : [
                // Branch switcher
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: BranchSwitcher(compact: true),
                ),
                IconButton(
                  icon: const Icon(Icons.file_upload_outlined,
                      color: Color(0xFF10B981)),
                  onPressed: _handleExcelImport,
                  tooltip: 'Import Leads from Excel',
                ),
                AppRefreshButton(
                  onRefresh: () async {
                    context.read<LeadBloc>().add(
                          LoadLeadsEvent(
                              branchState: context.read<BranchCubit>().state),
                        );
                    await Future.delayed(const Duration(milliseconds: 600));
                  },
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: Icon(
                    _isKanban ? Icons.view_list_rounded : Icons.view_kanban_rounded,
                    color: const Color(0xFF00BCD4),
                  ),
                  onPressed: () => setState(() => _isKanban = !_isKanban),
                  tooltip: _isKanban ? 'List View' : 'Kanban View',
                ),
                BlocBuilder<ThemeBloc, ThemeState>(
                  builder: (context, themeState) {
                    final isDarkTheme = themeState.themeMode == ThemeMode.dark;
                    return IconButton(
                      icon: Icon(
                        isDarkTheme
                            ? Icons.light_mode_rounded
                            : Icons.dark_mode_rounded,
                        color:
                            isDarkTheme ? Colors.white : const Color(0xFF374151),
                      ),
                      onPressed: () {
                        context.read<ThemeBloc>().add(ToggleThemeEvent());
                      },
                    );
                  },
                ),
                if (isWide)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ElevatedButton.icon(
                      onPressed: () => _showAddLeadDialog(),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add Lead'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00BCD4),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                      ),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: IconButton(
                      icon: const Icon(Icons.add_circle,
                          color: Color(0xFF00BCD4), size: 28),
                      onPressed: () => _showAddLeadDialog(),
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
          context.read<LeadBloc>().add(
                LoadLeadsEvent(branchState: branchState),
              );
        },
        child: BlocBuilder<LeadBloc, LeadState>(
        builder: (context, state) {
          final leads = state.leads;
          final filtered = _filteredLeads(leads);
          return Column(
            children: [
              if (!widget.showAppBar)
                Container(
                  color: Theme.of(context).colorScheme.surface,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              _isKanban ? Icons.view_list_rounded : Icons.view_kanban_rounded,
                              color: const Color(0xFF00BCD4),
                              size: 20,
                            ),
                            onPressed: () => setState(() => _isKanban = !_isKanban),
                            tooltip: _isKanban ? 'List View' : 'Kanban View',
                          ),
                          Text(
                            _isKanban ? 'Kanban View' : 'List View',
                            style: TextStyle(color: _textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _showAddLeadDialog(),
                        icon: const Icon(Icons.add, size: 14, color: Colors.white),
                        label: const Text('Add Lead', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00BCD4),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        ),
                      ),
                    ],
                  ),
                ),
              // Search bar
              Container(
                color: Theme.of(context).colorScheme.surface,
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _searchQuery = v),
                  style: TextStyle(color: _textPrimary, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Search leads by name, email or company…',
                    hintStyle: TextStyle(color: AppTheme.textMutedOf(context), fontSize: 13),
                    prefixIcon: Icon(Icons.search, color: AppTheme.textMutedOf(context), size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.close, size: 18, color: _textSecondary),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            })
                        : null,
                    filled: true,
                    fillColor: isDark ? AppTheme.bgBaseDark : const Color(0xFFF9FAFB),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: _border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: _border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFF00BCD4), width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              // Stats strip
              _buildStatsStrip(filtered),
              // Content
              Expanded(
                child: _isKanban ? _buildKanban(filtered) : _buildList(filtered),
              ),
            ],
          );
        },
      ),
    ),
  );
}

  Widget _buildStatsStrip(List<Lead> filteredLeads) {
    final total = filteredLeads.length;
    final totalValue = filteredLeads.fold<double>(0, (s, l) => s + l.value);
    final converted = filteredLeads.where((l) => l.status == LeadStatus.convertedClient).length;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: [
          _statChip('Total Leads', '$total', isDark ? Colors.white70 : const Color(0xFF6B7280)),
          const SizedBox(width: 12),
          _statChip('Pipeline Value', '₹${totalValue.toStringAsFixed(0)}', const Color(0xFF00BCD4)),
          const SizedBox(width: 12),
          _statChip('Converted', '$converted', const Color(0xFF10B981)),
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
                  color: color, fontSize: 14, fontWeight: FontWeight.w700)),
          Text(label,
              style: TextStyle(color: AppTheme.textMutedOf(context), fontSize: 10)),
        ],
      ),
    );
  }

  // ── KANBAN ──────────────────────────────────────────────────────────────────

  Widget _buildKanban(List<Lead> filteredLeads) {
    final byStatus = _leadsByStatus(filteredLeads);
    return ListView.builder(
      controller: _kanbanScrollController,
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(16),
      itemCount: LeadStatus.values.length,
      itemBuilder: (_, i) {
        final status = LeadStatus.values[i];
        final leads = byStatus[status] ?? [];
        return _KanbanColumn(
          status: status,
          leads: leads,
          onAddLead: () => _showAddLeadDialog(),
          onTap: (l) => _showLeadDetail(l),
          onDelete: _deleteLead,
          onStatusChange: _changeStatus,
          onDragStarted: () {},
          onDragEnd: _handleDragEnd,
          onDragMove: _handleDragMove,
        );
      },
    );
  }

  // ── LIST ────────────────────────────────────────────────────────────────────

  Widget _buildList(List<Lead> leads) {
    if (leads.isEmpty) {
      return Center(
        child: Text('No leads found', style: TextStyle(color: AppTheme.textMutedOf(context))),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: leads.length + 1,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        if (i == leads.length) {
          return Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Showing 1–${leads.length} of ${leads.length} leads',
              style: TextStyle(color: AppTheme.textMutedOf(context), fontSize: 12),
              textAlign: TextAlign.center,
            ),
          );
        }
        final lead = leads[i];
        final isSelected = _selectedLeadIds.contains(lead.id);
        return _LeadListTile(
          lead: lead,
          isSelectionMode: _isSelectionMode,
          isSelected: isSelected,
          onTap: () {
            if (_isSelectionMode) {
              _toggleSelection(lead.id);
            } else {
              _showLeadDetail(lead);
            }
          },
          onLongPress: () => _toggleSelection(lead.id),
          onDelete: () => _deleteLead(lead),
          onEdit: () => _showAddLeadDialog(existing: lead),
          onStatusChange: (s) => _changeStatus(lead, s),
        );
      },
    );
  }

  // ── LEAD DETAIL ─────────────────────────────────────────────────────────────

  void _showLeadDetail(Lead lead) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LeadDetailSheet(
        lead: lead,
        onEdit: () {
          Navigator.pop(context);
          _showAddLeadDialog(existing: lead);
        },
        onDelete: () {
          Navigator.pop(context);
          _deleteLead(lead);
        },
        onStatusChange: (s) {
          context.read<LeadBloc>().add(ChangeLeadStatusEvent(lead.id, s));
          Navigator.pop(context);
        },
      ),
    );
  }
}

// ─── KANBAN COLUMN ────────────────────────────────────────────────────────────

class _KanbanColumn extends StatefulWidget {
  final LeadStatus status;
  final List<Lead> leads;
  final VoidCallback onAddLead;
  final Function(Lead) onTap;
  final Function(Lead) onDelete;
  final Function(Lead, LeadStatus) onStatusChange;
  final VoidCallback onDragStarted;
  final VoidCallback onDragEnd;
  final Function(DragTargetDetails<Lead>) onDragMove;

  const _KanbanColumn({
    required this.status,
    required this.leads,
    required this.onAddLead,
    required this.onTap,
    required this.onDelete,
    required this.onStatusChange,
    required this.onDragStarted,
    required this.onDragEnd,
    required this.onDragMove,
  });

  @override
  State<_KanbanColumn> createState() => _KanbanColumnState();
}

class _KanbanColumnState extends State<_KanbanColumn> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DragTarget<Lead>(
      onWillAccept: (lead) {
        return lead != null && lead.status != widget.status;
      },
      onAccept: (lead) {
        widget.onStatusChange(lead, widget.status);
        setState(() {
          _isHovered = false;
        });
      },
      onMove: (details) {
        widget.onDragMove(details);
        if (!_isHovered) {
          setState(() {
            _isHovered = true;
          });
        }
      },
      onLeave: (lead) {
        setState(() {
          _isHovered = false;
        });
      },
      builder: (context, candidateData, rejectedData) {
        return Container(
          width: 240,
          margin: const EdgeInsets.only(right: 12),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: _isHovered 
                ? widget.status.color.withOpacity(0.08) 
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isHovered 
                  ? widget.status.color.withOpacity(0.3) 
                  : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Column header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.bgCardDark : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.borderOf(context)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: widget.status.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(widget.status.label,
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimaryOf(context),
                              letterSpacing: 0.3)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: widget.status.bgColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text('${widget.leads.length}',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: widget.status.color)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Cards
              Expanded(
                child: widget.leads.isEmpty
                    ? Container(
                        decoration: BoxDecoration(
                          color: (isDark ? AppTheme.bgCardDark : Colors.white).withOpacity(0.5),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: AppTheme.borderOf(context), style: BorderStyle.solid),
                        ),
                        child: Center(
                          child: Text('No leads',
                              style: TextStyle(
                                  color: AppTheme.textMutedOf(context), fontSize: 12)),
                        ),
                      )
                    : ListView.separated(
                        itemCount: widget.leads.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) => _KanbanCard(
                          lead: widget.leads[i],
                          onTap: () => widget.onTap(widget.leads[i]),
                          onDelete: () => widget.onDelete(widget.leads[i]),
                          onStatusChange: (s) => widget.onStatusChange(widget.leads[i], s),
                          onDragStarted: widget.onDragStarted,
                          onDragEnd: widget.onDragEnd,
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── KANBAN CARD ──────────────────────────────────────────────────────────────

class _KanbanCard extends StatelessWidget {
  final Lead lead;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final Function(LeadStatus) onStatusChange;
  final VoidCallback onDragStarted;
  final VoidCallback onDragEnd;

  const _KanbanCard({
    required this.lead,
    required this.onTap,
    required this.onDelete,
    required this.onStatusChange,
    required this.onDragStarted,
    required this.onDragEnd,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardContent = Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.bgCardDark : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderOf(context)),
        boxShadow: isDark ? [] : [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Avatar(name: lead.initials, color: lead.status.color),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(lead.fullName,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimaryOf(context)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    if (lead.companyName.isNotEmpty)
                      Text('@ ${lead.companyName.toLowerCase()}',
                          style: TextStyle(
                              fontSize: 11, color: AppTheme.textSecondaryOf(context)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_horiz,
                    size: 16, color: Color(0xFF9CA3AF)),
                padding: EdgeInsets.zero,
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red, fontSize: 13))),
                ],
                onSelected: (v) {
                  if (v == 'delete') onDelete();
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.bgBaseDark : const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text('GENERAL',
                    style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondaryOf(context),
                        letterSpacing: 0.5)),
              ),
              const SizedBox(width: 6),
              if (lead.value > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF064E3B) : const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text('₹${lead.value.toStringAsFixed(0)}',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isDark ? const Color(0xFFA7F3D0) : const Color(0xFF059669))),
                ),
            ],
          ),
        ],
      ),
    );

    return LongPressDraggable<Lead>(
      data: lead,
      feedback: Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(10),
        color: Colors.transparent,
        child: SizedBox(
          width: 220,
          child: cardContent,
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: cardContent,
      ),
      onDragStarted: onDragStarted,
      onDragEnd: (_) => onDragEnd(),
      child: GestureDetector(
        onTap: onTap,
        child: cardContent,
      ),
    );
  }
}

// ─── LIST TILE ────────────────────────────────────────────────────────────────

class _LeadListTile extends StatelessWidget {
  final Lead lead;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final Function(LeadStatus) onStatusChange;

  const _LeadListTile({
    required this.lead,
    this.isSelectionMode = false,
    this.isSelected = false,
    required this.onTap,
    required this.onLongPress,
    required this.onDelete,
    required this.onEdit,
    required this.onStatusChange,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isSelected
        ? const Color(0xFF00BCD4).withOpacity(0.12)
        : (isDark ? AppTheme.bgCardDark : Colors.white);
    final borderColor = isSelected
        ? const Color(0xFF00BCD4).withOpacity(0.5)
        : AppTheme.borderOf(context);

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor, width: isSelected ? 1.5 : 1.0),
          boxShadow: isDark ? [] : [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 3,
              offset: const Offset(0, 1),
            )
          ],
        ),
        child: Row(
          children: [
            // Circular selection checkbox
            GestureDetector(
              onTap: onLongPress,
              child: Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Icon(
                  isSelected
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: isSelected
                      ? const Color(0xFF00BCD4)
                      : (isSelectionMode
                          ? AppTheme.textSecondaryOf(context)
                          : AppTheme.textMutedOf(context)),
                  size: 22,
                ),
              ),
            ),
            _Avatar(name: lead.initials, color: lead.status.color, size: 36),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(lead.fullName,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimaryOf(context))),
                  Text(lead.email,
                      style: TextStyle(
                          fontSize: 11, color: AppTheme.textSecondaryOf(context)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _StatusBadge(status: lead.status),
                if (lead.value > 0) ...[
                  const SizedBox(height: 4),
                  Text('₹${lead.value.toStringAsFixed(0)}',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimaryOf(context))),
                ],
              ],
            ),
            if (!isSelectionMode) ...[
              const SizedBox(width: 4),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert,
                    size: 18, color: Color(0xFF9CA3AF)),
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit', style: TextStyle(fontSize: 13))),
                  const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red, fontSize: 13))),
                ],
                onSelected: (v) {
                  if (v == 'edit') onEdit();
                  if (v == 'delete') onDelete();
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── LEAD DETAIL BOTTOM SHEET ─────────────────────────────────────────────────

class _LeadDetailSheet extends StatelessWidget {
  final Lead lead;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Function(LeadStatus) onStatusChange;

  const _LeadDetailSheet({
    required this.lead,
    required this.onEdit,
    required this.onDelete,
    required this.onStatusChange,
  });

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
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, controller) => Container(
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
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 4),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
              child: Row(
                children: [
                  _Avatar(name: lead.initials, color: lead.status.color, size: 44),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(lead.fullName,
                            style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: textPrimary)),
                        if (lead.jobTitle.isNotEmpty || lead.companyName.isNotEmpty)
                          Text(
                            [lead.jobTitle, lead.companyName]
                                .where((s) => s.isNotEmpty)
                                .join(' @ '),
                            style: TextStyle(
                                fontSize: 12, color: textSecondary),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined,
                        color: Color(0xFF00BCD4), size: 20),
                    onPressed: onEdit,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        color: Colors.red, size: 20),
                    onPressed: onDelete,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _ContactActionButton(
                    icon: Icons.phone_outlined,
                    label: 'Call',
                    color: const Color(0xFF2563EB),
                    onTap: lead.phone.isNotEmpty ? () => _callPhone(lead.phone, context) : null,
                  ),
                  _ContactActionButton(
                    icon: Icons.message_outlined,
                    label: 'SMS',
                    color: const Color(0xFF0EA5E9),
                    onTap: lead.phone.isNotEmpty ? () => _sendSms(lead.phone, context) : null,
                  ),
                  _ContactActionButton(
                    icon: Icons.chat_bubble_outline,
                    label: 'WhatsApp',
                    color: const Color(0xFF22C55E),
                    onTap: lead.phone.isNotEmpty ? () => _sendWhatsApp(lead.phone, context) : null,
                  ),
                  _ContactActionButton(
                    icon: Icons.email_outlined,
                    label: 'Email',
                    color: const Color(0xFFEF4444),
                    onTap: lead.email.isNotEmpty ? () => _sendEmail(lead.email, context) : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Divider(height: 24, color: border),
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _StatusBadge(status: lead.status, large: true),
                  const SizedBox(height: 16),
                  // Change status
                  Text('Move to Stage',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: textSecondary,
                          letterSpacing: 0.5)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: LeadStatus.values.map((s) {
                      final isActive = s == lead.status;
                      return GestureDetector(
                        onTap: () => onStatusChange(s),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: isActive ? s.color : s.bgColor,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: s.color.withOpacity(0.3)),
                          ),
                          child: Text(s.label,
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: isActive ? Colors.white : s.color,
                                  letterSpacing: 0.3)),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  // Contact info
                  _DetailSection(
                    title: 'Contact Information',
                    icon: Icons.person_outline,
                    children: [
                      _DetailRow(Icons.email_outlined, 'Email', lead.email),
                      if (lead.phone.isNotEmpty)
                        _DetailRow(Icons.phone_outlined, 'Phone', lead.phone),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (lead.companyName.isNotEmpty || lead.jobTitle.isNotEmpty)
                    _DetailSection(
                      title: 'Company Details',
                      icon: Icons.business_outlined,
                      children: [
                        if (lead.companyName.isNotEmpty)
                          _DetailRow(Icons.apartment_outlined, 'Company', lead.companyName),
                        if (lead.jobTitle.isNotEmpty)
                          _DetailRow(Icons.work_outline, 'Job Title', lead.jobTitle),
                      ],
                    ),
                  const SizedBox(height: 16),
                  _DetailSection(
                    title: 'Pipeline',
                    icon: Icons.bar_chart_outlined,
                    children: [
                      _DetailRow(Icons.source_outlined, 'Source', lead.source.label),
                      _DetailRow(Icons.currency_rupee, 'Value', lead.value > 0 ? '₹${lead.value.toStringAsFixed(0)}' : 'Not set'),
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

class _DetailSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _DetailSection({
    required this.title,
    required this.icon,
    required this.children,
  });

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
                      color: AppTheme.textPrimaryOf(context),
                      letterSpacing: 0.3)),
            ],
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppTheme.textMutedOf(context)),
          const SizedBox(width: 8),
          Text('$label: ',
              style: TextStyle(
                  fontSize: 12, color: AppTheme.textSecondaryOf(context), fontWeight: FontWeight.w500)),
          Expanded(
            child: Text(value,
                style: TextStyle(fontSize: 12, color: AppTheme.textPrimaryOf(context)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}

class _ContactActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _ContactActionButton({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = onTap == null;
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: isDisabled ? 0.5 : 1,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(label,
                  style: TextStyle(
                      color: color,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── ADD / EDIT LEAD DIALOG ───────────────────────────────────────────────────

class _AddLeadDialog extends StatefulWidget {
  final Lead? existing;
  final Function(Lead) onSave;

  const _AddLeadDialog({this.existing, required this.onSave});

  @override
  State<_AddLeadDialog> createState() => _AddLeadDialogState();
}

class _AddLeadDialogState extends State<_AddLeadDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstName, _lastName, _email,
      _company, _jobTitle, _phone, _value;
  late LeadStatus _status;
  late AcquisitionSource _source;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _firstName = TextEditingController(text: e?.firstName ?? '');
    _lastName = TextEditingController(text: e?.lastName ?? '');
    _email = TextEditingController(text: e?.email ?? '');
    _company = TextEditingController(text: e?.companyName ?? '');
    _jobTitle = TextEditingController(text: e?.jobTitle ?? '');
    _phone = TextEditingController(text: e?.phone ?? '');
    _value = TextEditingController(text: e?.value.toString() ?? '0');
    _status = e?.status ?? LeadStatus.newLead;
    _source = e?.source ?? AcquisitionSource.website;
  }

  @override
  void dispose() {
    for (final c in [_firstName, _lastName, _email, _company, _jobTitle, _phone, _value]) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final lead = Lead(
      id: widget.existing?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      firstName: _firstName.text.trim(),
      lastName: _lastName.text.trim(),
      email: _email.text.trim(),
      companyName: _company.text.trim(),
      jobTitle: _jobTitle.text.trim(),
      phone: _phone.text.trim(),
      status: _status,
      source: _source,
      value: double.tryParse(_value.text) ?? 0,
      createdAt: widget.existing?.createdAt ?? DateTime.now(),
    );
    widget.onSave(lead);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppTheme.bgCardDark : Colors.white;
    final textPrimary = AppTheme.textPrimaryOf(context);
    final textSecondary = AppTheme.textSecondaryOf(context);
    final border = AppTheme.borderOf(context);

    return Dialog(
      backgroundColor: bg,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title row
                Row(
                  children: [
                    Expanded(
                      child: Text(isEdit ? 'Edit Lead' : 'Add New Lead',
                          style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: textPrimary)),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, size: 20, color: textSecondary),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
                Text(
                  isEdit ? 'Update lead details.' : 'Fill in the details to add a new lead to your CRM.',
                  style: TextStyle(fontSize: 12, color: textSecondary),
                ),
                const SizedBox(height: 20),
                _sectionHeader(Icons.person_outline, 'CONTACT INFORMATION'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _field(_firstName, 'First Name', hint: 'John', required: true)),
                    const SizedBox(width: 12),
                    Expanded(child: _field(_lastName, 'Last Name', hint: 'Doe')),
                  ],
                ),
                const SizedBox(height: 12),
                _field(_email, 'Email Address',
                    hint: 'john@example.com',
                    keyboardType: TextInputType.emailAddress,
                    required: true,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Email required';
                      if (!v.contains('@')) return 'Invalid email';
                      return null;
                    }),
                const SizedBox(height: 20),
                _sectionHeader(Icons.business_outlined, 'COMPANY DETAILS'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _field(_company, 'Company Name', hint: 'Acme Inc')),
                    const SizedBox(width: 12),
                    Expanded(child: _field(_jobTitle, 'Job Title', hint: 'CEO')),
                  ],
                ),
                const SizedBox(height: 12),
                _field(_phone, 'Phone Number',
                    hint: '+1 (555) 000-0000',
                    keyboardType: TextInputType.phone),
                const SizedBox(height: 20),
                _sectionHeader(Icons.bar_chart_outlined, 'PIPELINE STRATEGY'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Lead Status',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: textPrimary)),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              border: Border.all(color: border),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<LeadStatus>(
                                value: _status,
                                isExpanded: true,
                                dropdownColor: bg,
                                style: TextStyle(
                                    fontSize: 13, color: textPrimary),
                                items: LeadStatus.values.map((s) {
                                  return DropdownMenuItem(
                                    value: s,
                                    child: Text(s.label,
                                        style: TextStyle(fontSize: 12, color: textPrimary)),
                                  );
                                }).toList(),
                                onChanged: (v) =>
                                    setState(() => _status = v!),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Acquisition Source',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: textPrimary)),
                          const SizedBox(height: 6),
                          Container(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              border: Border.all(color: border),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<AcquisitionSource>(
                                value: _source,
                                isExpanded: true,
                                dropdownColor: bg,
                                style: TextStyle(
                                    fontSize: 13, color: textPrimary),
                                items: AcquisitionSource.values.map((s) {
                                  return DropdownMenuItem(
                                    value: s,
                                    child: Text(s.label,
                                        style: TextStyle(fontSize: 12, color: textPrimary)),
                                  );
                                }).toList(),
                                onChanged: (v) => setState(() => _source = v!),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _field(_value, 'Lead Value (₹)',
                    hint: '0',
                    keyboardType: TextInputType.number),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00BCD4),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(
                      isEdit ? 'UPDATE LEAD' : 'CREATE LEAD',
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xFF00BCD4)),
        const SizedBox(width: 6),
        Text(text,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimaryOf(context),
                letterSpacing: 0.5)),
      ],
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    String hint = '',
    bool required = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    final textPrimary = AppTheme.textPrimaryOf(context);
    final border = AppTheme.borderOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: textPrimary)),
        const SizedBox(height: 5),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: TextStyle(fontSize: 13, color: textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: AppTheme.textMutedOf(context), fontSize: 13),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF00BCD4), width: 1.5),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          validator: validator ??
              (required
                  ? (v) => (v == null || v.isEmpty) ? '$label is required' : null
                  : null),
        ),
      ],
    );
  }
}

// ─── REUSABLE WIDGETS ─────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  final String name;
  final Color color;
  final double size;

  const _Avatar({required this.name, required this.color, this.size = 32});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        shape: BoxShape.circle,
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Center(
        child: Text(name,
            style: TextStyle(
                fontSize: size * 0.35,
                fontWeight: FontWeight.w700,
                color: color)),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final LeadStatus status;
  final bool large;

  const _StatusBadge({required this.status, this.large = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: large ? 12 : 8, vertical: large ? 6 : 3),
      decoration: BoxDecoration(
        color: status.bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: status.color.withOpacity(0.25)),
      ),
      child: Text(status.label,
          style: TextStyle(
              fontSize: large ? 12 : 9,
              fontWeight: FontWeight.w700,
              color: status.color,
              letterSpacing: 0.3)),
    );
  }
}
