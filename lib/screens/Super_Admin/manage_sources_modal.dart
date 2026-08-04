import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/lead_model.dart';
import '../../services/supabase_service.dart';
import '../../blocs/lead/lead_bloc.dart';
import '../../blocs/branch/branch_cubit.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_snackbar.dart';

class ManageSourcesModal extends StatefulWidget {
  final List<Lead> allLeads;
  final String? activeFilter;
  final Function(String?) onFilterChanged;

  const ManageSourcesModal({
    super.key,
    required this.allLeads,
    this.activeFilter,
    required this.onFilterChanged,
  });

  static const String spKey = 'crm_acquisition_sources';
  static const List<String> defaultSources = [
    'Website',
    'LinkedIn',
    'Instagram',
    'Facebook / Meta Ads',
    'Google Ads / Search',
    'Cold Call',
    'Referral',
    'JustDial',
    'Trade Show / Event',
    'Email Campaign',
    'Agent / Partner',
    'WhatsApp Direct',
    'Other'
  ];

  static Future<List<String>> getSavedSources() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(spKey);
    if (saved == null || saved.isEmpty) {
      await prefs.setStringList(spKey, defaultSources);
      return defaultSources;
    }
    return saved;
  }

  @override
  State<ManageSourcesModal> createState() => _ManageSourcesModalState();
}

class _ManageSourcesModalState extends State<ManageSourcesModal> {
  List<String> _sources = [];
  final _addController = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadSources();
  }

  @override
  void dispose() {
    _addController.dispose();
    super.dispose();
  }

  Future<void> _loadSources() async {
    final list = await ManageSourcesModal.getSavedSources();
    if (mounted) {
      setState(() => _sources = list);
    }
  }

  Future<void> _saveSourcesList(List<String> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(ManageSourcesModal.spKey, list);
    setState(() => _sources = list);
  }

  Color _getSourceColor(String source) {
    final s = source.toLowerCase();
    if (s.contains('website')) return const Color(0xFF3B82F6); // Blue
    if (s.contains('linkedin')) return const Color(0xFF0077B5); // LinkedIn Blue
    if (s.contains('instagram')) return const Color(0xFFE1306C); // Instagram Pink
    if (s.contains('facebook') || s.contains('meta')) return const Color(0xFF1877F2); // Facebook Blue
    if (s.contains('google')) return const Color(0xFF10B981); // Google Green
    if (s.contains('cold')) return const Color(0xFFF59E0B); // Amber
    if (s.contains('referral')) return const Color(0xFF8B5CF6); // Purple
    if (s.contains('justdial')) return const Color(0xFFEF4444); // Red
    if (s.contains('trade') || s.contains('event')) return const Color(0xFFEC4899); // Pink
    if (s.contains('email')) return const Color(0xFF06B6D4); // Cyan
    if (s.contains('agent') || s.contains('partner')) return const Color(0xFF14B8A6); // Teal
    if (s.contains('whatsapp')) return const Color(0xFF22C55E); // WhatsApp Green
    return const Color(0xFF6B7280); // Grey (Other/Default)
  }

  Future<void> _addSource() async {
    final val = _addController.text.trim();
    if (val.isEmpty) return;

    if (_sources.any((s) => s.toLowerCase() == val.toLowerCase())) {
      AppSnackBar.showCustom(
        context,
        const SnackBar(
          content: Text('This acquisition source already exists.'),
          backgroundColor: Colors.amber,
        ),
      );
      return;
    }

    final newList = List<String>.from(_sources)..add(val);
    await _saveSourcesList(newList);
    _addController.clear();
    
    AppSnackBar.showCustom(
      context,
      SnackBar(
        content: Text('"$val" added successfully!'),
        backgroundColor: const Color(0xFF10B981),
      ),
    );
  }

  Future<void> _editSource(String oldName) async {
    if (oldName == 'Other') {
      AppSnackBar.showCustom(
        context,
        const SnackBar(
          content: Text('The "Other" source is reserved and cannot be modified.'),
          backgroundColor: Colors.amber,
        ),
      );
      return;
    }

    final editController = TextEditingController(text: oldName);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppTheme.bgCardDark : Colors.white,
        title: const Text('Edit Source Name'),
        content: TextField(
          controller: editController,
          style: TextStyle(color: AppTheme.textPrimaryOf(ctx)),
          decoration: const InputDecoration(
            hintText: 'Enter new name...',
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF00BCD4)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              final n = editController.text.trim();
              if (n.isNotEmpty && n != oldName) {
                Navigator.pop(ctx, n);
              } else {
                Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00BCD4)),
            child: const Text('SAVE', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (newName == null) return;

    if (_sources.any((s) => s.toLowerCase() == newName.toLowerCase() && s != oldName)) {
      AppSnackBar.showCustom(
        context,
        const SnackBar(
          content: Text('Another source already uses this name.'),
          backgroundColor: Colors.amber,
        ),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      // 1. Update database records
      await SupabaseService.client
          .from('leads')
          .update({'source': newName})
          .eq('source', oldName);

      // 2. Update local sources list
      final idx = _sources.indexOf(oldName);
      if (idx != -1) {
        final newList = List<String>.from(_sources);
        newList[idx] = newName;
        await _saveSourcesList(newList);
      }

      // 3. Reload lead list state
      if (mounted) {
        final branchState = context.read<BranchCubit>().state;
        context.read<LeadBloc>().add(LoadLeadsEvent(branchState: branchState));
      }

      AppSnackBar.showCustom(
        context,
        const SnackBar(
          content: Text('Acquisition source renamed successfully!'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    } catch (e) {
      AppSnackBar.showCustom(
        context,
        SnackBar(
          content: Text('Failed to update database: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _deleteSource(String sourceName) async {
    if (sourceName == 'Other') {
      AppSnackBar.showCustom(
        context,
        const SnackBar(
          content: Text('The "Other" source is reserved and cannot be deleted.'),
          backgroundColor: Colors.amber,
        ),
      );
      return;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppTheme.bgCardDark : Colors.white,
        title: const Text('Delete Source'),
        content: Text('Are you sure you want to delete "$sourceName"?\nAll active leads under this source will be moved to "Other".'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCEL', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('DELETE', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _loading = true);

    try {
      // 1. Move leads to 'Other' in database
      await SupabaseService.client
          .from('leads')
          .update({'source': 'Other'})
          .eq('source', sourceName);

      // 2. Remove source from local list
      final newList = List<String>.from(_sources)..remove(sourceName);
      await _saveSourcesList(newList);

      // 3. Reload lead list state
      if (mounted) {
        final branchState = context.read<BranchCubit>().state;
        context.read<LeadBloc>().add(LoadLeadsEvent(branchState: branchState));
      }

      AppSnackBar.showCustom(
        context,
        const SnackBar(
          content: Text('Acquisition source deleted successfully!'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    } catch (e) {
      AppSnackBar.showCustom(
        context,
        SnackBar(
          content: Text('Failed to delete: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = AppTheme.textPrimaryOf(context);
    final textSecondary = AppTheme.textSecondaryOf(context);
    final bg = isDark ? AppTheme.bgCardDark : Colors.white;
    final border = AppTheme.borderOf(context);
    
    final totalLeads = widget.allLeads.length;

    // Calculate lead counts per source
    final Map<String, int> distribution = {};
    for (final s in _sources) {
      distribution[s] = widget.allLeads.where((l) {
        final src = l.source.trim().toLowerCase();
        final name = s.trim().toLowerCase();
        return src == name;
      }).length;
    }

    return Dialog(
      backgroundColor: bg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: MediaQuery.of(context).size.width > 680 ? 650 : double.infinity,
        constraints: const BoxConstraints(maxHeight: 700),
        padding: const EdgeInsets.all(20),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00BCD4).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.track_changes_outlined,
                        color: Color(0xFF00BCD4),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'MANAGE ACQUISITION SOURCES ✨',
                            maxLines: 2,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: textPrimary,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Add, edit, delete, and analyze lead acquisition sources across your CRM',
                            style: TextStyle(fontSize: 11, color: textSecondary),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      color: textSecondary,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 16),

                // Add source row
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 450;
                    final textField = SizedBox(
                      height: 40,
                      child: TextField(
                        controller: _addController,
                        style: TextStyle(color: textPrimary, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Add new custom source (e.g. Newspaper, Radio)...',
                          hintStyle: TextStyle(color: AppTheme.textMutedOf(context), fontSize: 11),
                          prefixIcon: Icon(Icons.tag, color: AppTheme.textMutedOf(context), size: 18),
                          filled: true,
                          fillColor: isDark ? AppTheme.bgBaseDark : const Color(0xFFF9FAFB),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
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
                            borderSide: const BorderSide(color: Color(0xFF00BCD4)),
                          ),
                        ),
                      ),
                    );

                    final addButton = SizedBox(
                      height: 40,
                      child: ElevatedButton.icon(
                        onPressed: _loading ? null : _addSource,
                        icon: const Icon(Icons.add, size: 14, color: Colors.white),
                        label: const Text(
                          'ADD SOURCE',
                          style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00BCD4),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                        ),
                      ),
                    );

                    if (isNarrow) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          textField,
                          const SizedBox(height: 8),
                          addButton,
                        ],
                      );
                    }

                    return Row(
                      children: [
                        Expanded(child: textField),
                        const SizedBox(width: 8),
                        addButton,
                      ],
                    );
                  },
                ),
                const SizedBox(height: 18),

                // Active Sources Section title
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.pie_chart_outline, size: 16, color: Color(0xFF00BCD4)),
                        const SizedBox(width: 6),
                        Text(
                          'ACTIVE SOURCES & LEAD DISTRIBUTION',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Total Active Leads: $totalLeads',
                      style: TextStyle(fontSize: 11, color: textSecondary, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Grid list
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final cols = constraints.maxWidth > 400 ? 2 : 1;
                      final ratio = constraints.maxWidth > 400 ? 2.8 : 4.2;
                      return GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: cols,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: ratio,
                        ),
                        itemCount: _sources.length,
                        itemBuilder: (context, index) {
                          final source = _sources[index];
                          final count = distribution[source] ?? 0;
                          final pct = totalLeads > 0 ? (count / totalLeads) : 0.0;
                          final isSelected = widget.activeFilter?.toLowerCase() == source.toLowerCase();

                          final themeColor = _getSourceColor(source);

                          return GestureDetector(
                            onTap: () {
                              widget.onFilterChanged(source);
                              Navigator.pop(context);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected 
                                    ? themeColor.withOpacity(0.12)
                                    : (isDark ? AppTheme.bgBaseDark : const Color(0xFFF9FAFB)),
                                border: Border.all(
                                  color: isSelected ? themeColor : border,
                                  width: isSelected ? 1.5 : 1,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  // Top label + Edit/Delete action buttons
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Flexible(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: themeColor.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            source,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: themeColor,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                      if (source != 'Other')
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            GestureDetector(
                                              onTap: () => _editSource(source),
                                              child: Icon(Icons.edit_outlined, size: 14, color: textSecondary),
                                            ),
                                            const SizedBox(width: 6),
                                            GestureDetector(
                                              onTap: () => _deleteSource(source),
                                              child: Icon(Icons.delete_outline, size: 14, color: textSecondary),
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),

                                  // Progress count indicator
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(2),
                                              child: LinearProgressIndicator(
                                                value: pct,
                                                backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                                                valueColor: AlwaysStoppedAnimation<Color>(themeColor),
                                                minHeight: 4,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            '$count (${(pct * 100).toStringAsFixed(0)}%)',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: textPrimary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Bottom Panel
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00BCD4).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF00BCD4).withOpacity(0.15)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.filter_list, size: 16, color: Color(0xFF00BCD4)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Click any source card to filter lead table instantly',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          widget.onFilterChanged(null);
                          Navigator.pop(context);
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'Reset Source Filter',
                          style: TextStyle(
                            color: Color(0xFF00BCD4),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (_loading)
              Positioned.fill(
                child: Container(
                  color: bg.withOpacity(0.6),
                  child: const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00BCD4)),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
