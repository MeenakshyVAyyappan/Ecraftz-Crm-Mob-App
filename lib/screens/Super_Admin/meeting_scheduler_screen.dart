import 'package:ecraftz_crm/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../blocs/meeting/meeting_bloc.dart';
import '../../blocs/client/client_bloc.dart';
import '../../blocs/theme/theme_bloc.dart';
import '../../models/meeting_model.dart';
import '../../models/client_model.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_drawer.dart';

// ─── STATUS / TYPE HELPERS ────────────────────────────────────────────────────

Color _statusColor(String status) {
  switch (status.toLowerCase()) {
    case 'scheduled':   return const Color(0xFF3B82F6);
    case 'completed':   return const Color(0xFF10B981);
    case 'cancelled':   return const Color(0xFFEF4444);
    case 'rescheduled': return const Color(0xFFF59E0B);
    default:            return const Color(0xFF8892B0);
  }
}

IconData _statusIcon(String status) {
  switch (status.toLowerCase()) {
    case 'scheduled':   return Icons.schedule_rounded;
    case 'completed':   return Icons.check_circle_rounded;
    case 'cancelled':   return Icons.cancel_rounded;
    case 'rescheduled': return Icons.update_rounded;
    default:            return Icons.circle_outlined;
  }
}

IconData _modeIcon(String mode) =>
    mode == 'in_person' ? Icons.location_on_rounded : Icons.videocam_rounded;

Color _typeColor(String? type) {
  switch ((type ?? '').toLowerCase()) {
    case 'client demo':    return const Color(0xFF8B5CF6);
    case 'discovery call': return const Color(0xFF06B6D4);
    case 'follow up':      return const Color(0xFFF59E0B);
    case 'onboarding':     return const Color(0xFF10B981);
    case 'review':         return const Color(0xFF3B82F6);
    case 'internal':       return const Color(0xFF6366F1);
    default:               return const Color(0xFF6B7A99);
  }
}

const _meetingTypes    = ['Client Demo', 'Discovery Call', 'Follow Up', 'Onboarding', 'Review', 'Internal', 'General'];
const _meetingModes    = ['online', 'in_person'];
const _meetingStatuses = ['scheduled', 'completed', 'cancelled', 'rescheduled'];
const _durations       = [15, 30, 45, 60, 90, 120];

String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

// ─── MAIN SCREEN ─────────────────────────────────────────────────────────────

class MeetingSchedulerScreen extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;
  final bool showAppBar;

  const MeetingSchedulerScreen({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    this.showAppBar = true,
  });

  @override
  State<MeetingSchedulerScreen> createState() => _MeetingSchedulerScreenState();
}

class _MeetingSchedulerScreenState extends State<MeetingSchedulerScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery  = '';
  String _statusFilter = 'All';
  String _typeFilter   = 'All';
  late TabController _tabController;

  bool  get _isDark        => Theme.of(context).brightness == Brightness.dark;
  Color get _bg            => Theme.of(context).scaffoldBackgroundColor;
  Color get _cardBg        => Theme.of(context).colorScheme.surface;
  Color get _border        => AppTheme.borderOf(context);
  Color get _textPrimary   => AppTheme.textPrimaryOf(context);
  Color get _textSecondary => AppTheme.textSecondaryOf(context);
  Color get _textMuted     => AppTheme.textMutedOf(context);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {});
      }
    });
    context.read<MeetingBloc>().add(LoadMeetingsEvent());
    context.read<ClientBloc>().add(LoadClientsEvent());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _tabController.dispose();
    super.dispose();
  }

  List<Meeting> _filtered(List<Meeting> all) {
    final q = _searchQuery.toLowerCase();
    return all.where((m) {
      final matchSearch = q.isEmpty ||
          m.title.toLowerCase().contains(q) ||
          (m.clientName ?? '').toLowerCase().contains(q) ||
          (m.projectName ?? '').toLowerCase().contains(q) ||
          (m.meetingType ?? '').toLowerCase().contains(q);
      final matchStatus = _statusFilter == 'All' || m.status == _statusFilter;
      final matchType   = _typeFilter == 'All'   || m.meetingType == _typeFilter;
      return matchSearch && matchStatus && matchType;
    }).toList();
  }

  List<Meeting> _byTab(List<Meeting> filtered) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);

    switch (_tabController.index) {
      case 0: // All
        return filtered;
      case 1: // Today
        return filtered.where((m) =>
          m.scheduledAt.isAfter(todayStart.subtract(const Duration(milliseconds: 1))) &&
          m.scheduledAt.isBefore(todayEnd.add(const Duration(milliseconds: 1)))
        ).toList();
      case 2: // Upcoming
        return filtered.where((m) =>
          m.scheduledAt.isAfter(now) &&
          m.status != 'completed' &&
          m.status != 'cancelled'
        ).toList();
      case 3: // Overdue
        return filtered.where((m) =>
          m.scheduledAt.isBefore(now) &&
          (m.status == 'scheduled' || m.status == 'rescheduled')
        ).toList();
      default:
        return filtered;
    }
  }

  void _openForm({Meeting? edit}) {
    final clients = context.read<ClientBloc>().state.clients;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _MeetingFormDialog(
        edit: edit,
        clients: clients,
        onSave: (data) {
          if (edit == null) {
            context.read<MeetingBloc>().add(CreateMeetingEvent(
              title:           data['title'] as String,
              description:     data['description'] as String?,
              meetingType:     data['meetingType'] as String,
              meetingMode:     data['meetingMode'] as String,
              location:        data['location'] as String?,
              scheduledAt:     data['scheduledAt'] as DateTime,
              durationMinutes: data['durationMinutes'] as int,
              meetingLink:     data['meetingLink'] as String?,
              clientId:        data['clientId'] as String?,
              status:          data['status'] as String,
            ));
          } else {
            context.read<MeetingBloc>().add(UpdateMeetingEvent(
              id:              edit.id,
              title:           data['title'] as String,
              description:     data['description'] as String?,
              meetingType:     data['meetingType'] as String,
              meetingMode:     data['meetingMode'] as String,
              location:        data['location'] as String?,
              scheduledAt:     data['scheduledAt'] as DateTime,
              durationMinutes: data['durationMinutes'] as int,
              meetingLink:     data['meetingLink'] as String?,
              status:          data['status'] as String,
              outcomeNotes:    data['outcomeNotes'] as String?,
            ));
          }
        },
      ),
    );
  }

  void _confirmDelete(Meeting m) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete Meeting',
            style: TextStyle(color: _textPrimary, fontWeight: FontWeight.w700)),
        content: Text(
          'Delete "${m.title}"? This cannot be undone.',
          style: TextStyle(color: _textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: _textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(context);
              context.read<MeetingBloc>().add(DeleteMeetingEvent(m.id));
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showDetail(Meeting m) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DetailSheet(
        meeting: m,
        isDark: _isDark,
        cardBg: _cardBg,
        border: _border,
        textPrimary: _textPrimary,
        textSecondary: _textSecondary,
        textMuted: _textMuted,
        onEdit: () {
          Navigator.pop(context);
          _openForm(edit: m);
        },
        onDelete: () {
          Navigator.pop(context);
          _confirmDelete(m);
        },
        onStatusChange: (s) {
          Navigator.pop(context);
          context.read<MeetingBloc>().add(UpdateMeetingEvent(id: m.id, status: s));
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 600;
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: _bg,
      drawer: widget.showAppBar
          ? AppDrawer(
              selectedIndex: widget.selectedIndex,
              onItemSelected: (i) {
                widget.onItemSelected(i);
                Navigator.pop(context);
              },
            )
          : null,
      appBar: widget.showAppBar
          ? AppBar(
              backgroundColor: _cardBg,
              elevation: 0,
              leading: isWide
                  ? null
                  : IconButton(
                      icon: Icon(Icons.menu_rounded,
                          color: _isDark ? Colors.white : const Color(0xFF374151)),
                      onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                    ),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Meeting Scheduler',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: _textPrimary),
                  ),
                  Text(
                    'Schedule and manage all client and team meetings',
                    style: TextStyle(fontSize: 11, color: _textSecondary),
                  ),
                ],
              ),
              actions: [
                BlocBuilder<ThemeBloc, ThemeState>(
                  builder: (context, s) => IconButton(
                    icon: Icon(
                      s.themeMode == ThemeMode.dark
                          ? Icons.light_mode_rounded
                          : Icons.dark_mode_rounded,
                      color: _isDark ? Colors.white : const Color(0xFF374151),
                    ),
                    onPressed: () =>
                        context.read<ThemeBloc>().add(ToggleThemeEvent()),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(1),
                child: Container(height: 1, color: _border),
              ),
            )
          : null,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        backgroundColor: const Color(0xFF3B82F6),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Schedule Meeting',
            style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchFilters(),
            _buildTabs(),
            Expanded(
              child: BlocConsumer<MeetingBloc, MeetingState>(
                listener: (context, state) {
                  if (state.errorMessage != null && state.errorMessage!.isNotEmpty) {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    AppSnackBar.showCustom(context, SnackBar(
                      content: Text('Error: ${state.errorMessage}'),
                      backgroundColor: AppTheme.error,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ));
                  } else if (state.successMessage != null && state.successMessage!.isNotEmpty) {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    AppSnackBar.showCustom(context, SnackBar(
                      content: Text(state.successMessage!),
                      backgroundColor: const Color(0xFF10B981),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ));
                  }
                },
                builder: (context, state) {
                  if (state.status == MeetingStatusState.loading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final displayed = _byTab(_filtered(state.meetings));
                  if (displayed.isEmpty) return _buildEmpty();
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    itemCount: displayed.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _MeetingCard(
                      meeting: displayed[i],
                      isDark: _isDark,
                      cardBg: _cardBg,
                      border: _border,
                      textPrimary: _textPrimary,
                      textSecondary: _textSecondary,
                      textMuted: _textMuted,
                      onTap: () => _showDetail(displayed[i]),
                      onEdit: () => _openForm(edit: displayed[i]),
                      onDelete: () => _confirmDelete(displayed[i]),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchFilters() {
    return Container(
      color: _cardBg,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        children: [
          Container(
            height: 42,
            decoration: BoxDecoration(
              color: _isDark
                  ? const Color(0xFF1E2E42)
                  : const Color(0xFFF5F7FA),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _border),
            ),
            child: TextField(
              controller: _searchCtrl,
              style: TextStyle(color: _textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search meetings, clients, types…',
                hintStyle: TextStyle(color: _textMuted, fontSize: 14),
                prefixIcon:
                    Icon(Icons.search_rounded, color: _textMuted, size: 18),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear_rounded,
                            color: _textMuted, size: 16),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 11),
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _chip('All', _statusFilter == 'All',
                    () => setState(() => _statusFilter = 'All')),
                ..._meetingStatuses.map((s) => _chip(
                      _cap(s),
                      _statusFilter == s,
                      () => setState(() => _statusFilter =
                          _statusFilter == s ? 'All' : s),
                      color: _statusColor(s),
                    )),
                Container(
                    width: 1,
                    height: 18,
                    color: _border,
                    margin: const EdgeInsets.symmetric(horizontal: 10)),
                _chip('All Types', _typeFilter == 'All',
                    () => setState(() => _typeFilter = 'All')),
                ..._meetingTypes.map((t) => _chip(
                      t,
                      _typeFilter == t,
                      () => setState(
                          () => _typeFilter = _typeFilter == t ? 'All' : t),
                      color: _typeColor(t),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap,
      {Color? color}) {
    final c = color ?? const Color(0xFF3B82F6);
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: selected
                ? c.withValues(alpha: 0.14)
                : (_isDark
                    ? const Color(0xFF1E2E42)
                    : const Color(0xFFF1F5F9)),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? c.withValues(alpha: 0.5) : _border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? c : _textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      color: _cardBg,
      child: Column(
        children: [
          Divider(height: 1, color: _border),
          TabBar(
            controller: _tabController,
            onTap: (_) => setState(() {}),
            labelColor: const Color(0xFF3B82F6),
            unselectedLabelColor: _textSecondary,
            indicatorColor: const Color(0xFF3B82F6),
            indicatorWeight: 2,
            tabs: const [
              Tab(text: 'All'),
              Tab(text: 'Today'),
              Tab(text: 'Upcoming'),
              Tab(text: 'Overdue'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    String tabLabel = 'meetings';
    switch (_tabController.index) {
      case 1: tabLabel = 'today\'s meetings'; break;
      case 2: tabLabel = 'upcoming meetings'; break;
      case 3: tabLabel = 'overdue meetings'; break;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.event_rounded,
                size: 36, color: Color(0xFF3B82F6)),
          ),
          const SizedBox(height: 16),
          Text('No $tabLabel found',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _textPrimary)),
          const SizedBox(height: 6),
          Text(
            _searchQuery.isNotEmpty ||
                    _statusFilter != 'All' ||
                    _typeFilter != 'All'
                ? 'Try adjusting your search or filters'
                : 'Schedule a meeting to get started',
            style: TextStyle(fontSize: 13, color: _textSecondary),
          ),
        ],
      ),
    );
  }
}

// ─── MEETING CARD ─────────────────────────────────────────────────────────────

class _MeetingCard extends StatelessWidget {
  final Meeting meeting;
  final bool isDark;
  final Color cardBg, border, textPrimary, textSecondary, textMuted;
  final VoidCallback onTap, onEdit, onDelete;

  const _MeetingCard({
    required this.meeting,
    required this.isDark,
    required this.cardBg,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  bool get _isToday {
    final now = DateTime.now();
    return meeting.scheduledAt.year == now.year &&
        meeting.scheduledAt.month == now.month &&
        meeting.scheduledAt.day == now.day;
  }

  bool get _isOverdue =>
      meeting.scheduledAt.isBefore(DateTime.now()) &&
      meeting.status == 'scheduled';

  @override
  Widget build(BuildContext context) {
    final sc = _statusColor(meeting.status);
    final tc = _typeColor(meeting.meetingType);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _isToday
                ? const Color(0xFF3B82F6).withValues(alpha: 0.4)
                : border,
            width: _isToday ? 1.5 : 1,
          ),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2))
                ],
        ),
        child: Column(
          children: [
            Container(
              height: 4,
              decoration: BoxDecoration(
                color: sc,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(14)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _typeBadge(meeting.meetingType ?? 'General', tc),
                      const SizedBox(width: 6),
                      _modeBadge(),
                      const Spacer(),
                      _statusBadge(sc),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Text(meeting.title,
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: textPrimary)),
                      ),
                      PopupMenuButton<String>(
                        icon: Icon(Icons.more_vert_rounded,
                            color: textMuted, size: 18),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        color: cardBg,
                        onSelected: (v) {
                          if (v == 'edit') onEdit();
                          if (v == 'delete') onDelete();
                        },
                        itemBuilder: (_) => [
                          PopupMenuItem(
                              value: 'edit',
                              child: Row(children: [
                                Icon(Icons.edit_rounded,
                                    size: 16, color: textSecondary),
                                const SizedBox(width: 8),
                                Text('Edit',
                                    style: TextStyle(
                                        color: textPrimary, fontSize: 13)),
                              ])),
                          const PopupMenuItem(
                              value: 'delete',
                              child: Row(children: [
                                Icon(Icons.delete_outline_rounded,
                                    size: 16, color: Color(0xFFEF4444)),
                                SizedBox(width: 8),
                                Text('Delete',
                                    style: TextStyle(
                                        color: Color(0xFFEF4444),
                                        fontSize: 13)),
                              ])),
                        ],
                      ),
                    ],
                  ),
                  if (meeting.description != null &&
                      meeting.description!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(meeting.description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 12,
                            color: textSecondary,
                            height: 1.4)),
                  ],
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 14,
                    runSpacing: 6,
                    children: [
                      _info(
                        Icons.calendar_today_rounded,
                        _isToday
                            ? 'Today  ${DateFormat("h:mm a").format(meeting.scheduledAt)}'
                            : DateFormat('EEE, d MMM • h:mm a')
                                .format(meeting.scheduledAt),
                        _isToday
                            ? const Color(0xFF3B82F6)
                            : textSecondary,
                      ),
                      _info(Icons.timer_outlined,
                          '${meeting.durationMinutes} min', textSecondary),
                      if (meeting.clientName != null)
                        _info(Icons.person_outline_rounded,
                            meeting.clientName!, textSecondary),
                    ],
                  ),
                  if (_isOverdue) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 7),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: const Color(0xFFF59E0B)
                                .withValues(alpha: 0.25)),
                      ),
                      child: const Row(children: [
                        Icon(Icons.warning_amber_rounded,
                            size: 13, color: Color(0xFFF59E0B)),
                        SizedBox(width: 6),
                        Text('Overdue — please update status',
                            style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFFF59E0B),
                                fontWeight: FontWeight.w500)),
                      ]),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _typeBadge(String label, Color c) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
            color: c.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(6)),
        child: Text(label,
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: c,
                letterSpacing: 0.3)),
      );

  Widget _modeBadge() => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF1E2E42)
              : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(_modeIcon(meeting.meetingMode),
              size: 10, color: textSecondary),
          const SizedBox(width: 3),
          Text(
              meeting.meetingMode == 'in_person'
                  ? 'In Person'
                  : 'Online',
              style: TextStyle(
                  fontSize: 10,
                  color: textSecondary,
                  fontWeight: FontWeight.w600)),
        ]),
      );

  Widget _statusBadge(Color c) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: c.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: c.withValues(alpha: 0.3)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(_statusIcon(meeting.status), size: 10, color: c),
          const SizedBox(width: 4),
          Text(_cap(meeting.status),
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w700, color: c)),
        ]),
      );

  Widget _info(IconData icon, String label, Color c) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: c),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  color: c,
                  fontWeight: FontWeight.w500)),
        ],
      );
}

// ─── DETAIL BOTTOM SHEET ──────────────────────────────────────────────────────

class _DetailSheet extends StatelessWidget {
  final Meeting meeting;
  final bool isDark;
  final Color cardBg, border, textPrimary, textSecondary, textMuted;
  final VoidCallback onEdit, onDelete;
  final void Function(String) onStatusChange;

  const _DetailSheet({
    required this.meeting,
    required this.isDark,
    required this.cardBg,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.onEdit,
    required this.onDelete,
    required this.onStatusChange,
  });

  @override
  Widget build(BuildContext context) {
    final sc = _statusColor(meeting.status);
    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (_, ctrl) => Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                    color: border,
                    borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: sc.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(_statusIcon(meeting.status),
                        color: sc, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(meeting.title,
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: textPrimary)),
                        Text(meeting.meetingType ?? 'General',
                            style: TextStyle(
                                fontSize: 12,
                                color: _typeColor(meeting.meetingType),
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  IconButton(
                      onPressed: onEdit,
                      icon: Icon(Icons.edit_rounded,
                          color: textSecondary, size: 20)),
                  IconButton(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline_rounded,
                          color: Color(0xFFEF4444), size: 20)),
                ],
              ),
            ),
            Divider(height: 24, color: border),
            Expanded(
              child: ListView(
                controller: ctrl,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  Text('STATUS',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: textMuted,
                          letterSpacing: 1.2)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _meetingStatuses.map((s) {
                      final active = meeting.status == s;
                      final c = _statusColor(s);
                      return GestureDetector(
                        onTap: active ? null : () => onStatusChange(s),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: active
                                ? c.withValues(alpha: 0.14)
                                : (isDark
                                    ? const Color(0xFF1E2E42)
                                    : const Color(0xFFF1F5F9)),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: active
                                    ? c.withValues(alpha: 0.5)
                                    : border,
                                width: active ? 1.5 : 1),
                          ),
                          child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(_statusIcon(s),
                                    size: 12,
                                    color: active ? c : textMuted),
                                const SizedBox(width: 5),
                                Text(_cap(s),
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color:
                                            active ? c : textSecondary)),
                              ]),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  Text('DETAILS',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: textMuted,
                          letterSpacing: 1.2)),
                  const SizedBox(height: 10),
                  _row(
                      Icons.calendar_today_rounded,
                      'Date & Time',
                      '${DateFormat("EEEE, d MMMM yyyy").format(meeting.scheduledAt)} at ${DateFormat("h:mm a").format(meeting.scheduledAt)}'),
                  _row(Icons.timer_outlined, 'Duration',
                      '${meeting.durationMinutes} minutes'),
                  _row(_modeIcon(meeting.meetingMode), 'Mode',
                      meeting.meetingMode == 'in_person'
                          ? 'In Person'
                          : 'Online'),
                  if (meeting.location != null &&
                      meeting.location!.isNotEmpty)
                    _row(Icons.location_on_outlined, 'Location',
                        meeting.location!),
                  if (meeting.meetingLink != null &&
                      meeting.meetingLink!.isNotEmpty)
                    _row(Icons.link_rounded, 'Meeting Link',
                        meeting.meetingLink!),
                  if (meeting.clientName != null)
                    _row(Icons.person_outline_rounded, 'Client',
                        meeting.clientName!),
                  if (meeting.projectName != null)
                    _row(Icons.folder_outlined, 'Project',
                        meeting.projectName!),
                  if (meeting.description != null &&
                      meeting.description!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text('DESCRIPTION',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: textMuted,
                            letterSpacing: 1.2)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1E2E42)
                            : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: border),
                      ),
                      child: Text(meeting.description!,
                          style: TextStyle(
                              fontSize: 13,
                              color: textPrimary,
                              height: 1.5)),
                    ),
                  ],
                  if (meeting.outcomeNotes != null &&
                      meeting.outcomeNotes!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text('OUTCOME NOTES',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: textMuted,
                            letterSpacing: 1.2)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981)
                            .withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: const Color(0xFF10B981)
                                .withValues(alpha: 0.2)),
                      ),
                      child: Text(meeting.outcomeNotes!,
                          style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF10B981),
                              height: 1.5)),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Text(
                      'Created ${DateFormat("d MMM yyyy").format(meeting.createdAt)}',
                      style: TextStyle(fontSize: 11, color: textMuted)),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(IconData icon, String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 16, color: textMuted),
              const SizedBox(width: 10),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(label,
                        style: TextStyle(
                            fontSize: 11,
                            color: textMuted,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(value,
                        style: TextStyle(
                            fontSize: 13,
                            color: textPrimary,
                            fontWeight: FontWeight.w500)),
                  ])),
            ]),
      );
}

// ─── FORM DIALOG ─────────────────────────────────────────────────────────────

class _MeetingFormDialog extends StatefulWidget {
  final Meeting? edit;
  final List<ActiveClient> clients;
  final void Function(Map<String, dynamic>) onSave;

  const _MeetingFormDialog({
    this.edit,
    required this.clients,
    required this.onSave,
  });

  @override
  State<_MeetingFormDialog> createState() => _MeetingFormDialogState();
}

class _MeetingFormDialogState extends State<_MeetingFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _locationCtrl;
  late TextEditingController _linkCtrl;
  late TextEditingController _notesCtrl;

  String   _meetingType = 'Client Demo';
  String   _meetingMode = 'online';
  String   _status      = 'scheduled';
  int      _duration    = 30;
  DateTime _scheduledAt = DateTime.now().add(const Duration(hours: 1));
  String?  _clientId;

  bool  get _isDark        => Theme.of(context).brightness == Brightness.dark;
  Color get _cardBg        => Theme.of(context).colorScheme.surface;
  Color get _border        => AppTheme.borderOf(context);
  Color get _textPrimary   => AppTheme.textPrimaryOf(context);
  Color get _textSecondary => AppTheme.textSecondaryOf(context);

  @override
  void initState() {
    super.initState();
    final e = widget.edit;
    _titleCtrl    = TextEditingController(text: e?.title ?? '');
    _descCtrl     = TextEditingController(text: e?.description ?? '');
    _locationCtrl = TextEditingController(text: e?.location ?? '');
    _linkCtrl     = TextEditingController(text: e?.meetingLink ?? '');
    _notesCtrl    = TextEditingController(text: e?.outcomeNotes ?? '');
    if (e != null) {
      _meetingType = e.meetingType ?? 'Client Demo';
      _meetingMode = e.meetingMode;
      _status      = e.status;
      _duration    = e.durationMinutes;
      _scheduledAt = e.scheduledAt;
      _clientId    = e.clientId;
    }
  }

  @override
  void dispose() {
    for (final c in [
      _titleCtrl, _descCtrl, _locationCtrl, _linkCtrl, _notesCtrl
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _scheduledAt,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_scheduledAt));
    if (time == null || !mounted) return;
    setState(() => _scheduledAt = DateTime(
        date.year, date.month, date.day, time.hour, time.minute));
  }

  bool _isSubmitting = false;

  void _save() {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    widget.onSave({
      'title':           _titleCtrl.text.trim(),
      'description':
          _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      'meetingType':     _meetingType,
      'meetingMode':     _meetingMode,
      'location':
          _locationCtrl.text.trim().isEmpty ? null : _locationCtrl.text.trim(),
      'scheduledAt':     _scheduledAt,
      'durationMinutes': _duration,
      'meetingLink':
          _linkCtrl.text.trim().isEmpty ? null : _linkCtrl.text.trim(),
      'clientId':        _clientId,
      'status':          _status,
      'outcomeNotes':
          _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    });
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.edit != null;
    return Dialog(
      backgroundColor: _cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ──
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 16, 16),
              decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: _border))),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.event_rounded,
                        color: Color(0xFF3B82F6), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isEdit ? 'Edit Meeting' : 'Schedule Meeting',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: _textPrimary),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close_rounded, color: _textSecondary),
                  ),
                ],
              ),
            ),
            // ── Body ──
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _lbl('Meeting Title *'),
                      _field(_titleCtrl, 'e.g. Client Demo — Project X',
                          validator: (v) =>
                              (v == null || v.trim().isEmpty)
                                  ? 'Title is required'
                                  : null),
                      const SizedBox(height: 16),
                      Row(children: [
                        Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _lbl('Meeting Type'),
                                _drop<String>(
                                    value: _meetingType,
                                    items: _meetingTypes,
                                    onChanged: (v) => setState(
                                        () => _meetingType = v!)),
                              ]),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _lbl('Mode'),
                                _drop<String>(
                                    value: _meetingMode,
                                    items: _meetingModes,
                                    display: (v) => v == 'in_person'
                                        ? 'In Person'
                                        : 'Online',
                                    onChanged: (v) => setState(
                                        () => _meetingMode = v!)),
                              ]),
                        ),
                      ]),
                      const SizedBox(height: 16),
                      _lbl('Date & Time *'),
                      GestureDetector(
                        onTap: _pickDateTime,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 13),
                          decoration: BoxDecoration(
                            color: _isDark
                                ? const Color(0xFF1E2E42)
                                : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: _border),
                          ),
                          child: Row(children: [
                            const Icon(Icons.calendar_today_rounded,
                                size: 16, color: Color(0xFF3B82F6)),
                            const SizedBox(width: 8),
                            Text(
                              DateFormat('EEE, d MMM yyyy · h:mm a')
                                  .format(_scheduledAt),
                              style: TextStyle(
                                  fontSize: 14,
                                  color: _textPrimary,
                                  fontWeight: FontWeight.w500),
                            ),
                            const Spacer(),
                            Icon(Icons.edit_rounded,
                                size: 14, color: _textSecondary),
                          ]),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(children: [
                        Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _lbl('Duration'),
                                _drop<int>(
                                    value: _duration,
                                    items: _durations,
                                    display: (v) => '$v min',
                                    onChanged: (v) =>
                                        setState(() => _duration = v!)),
                              ]),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _lbl('Status'),
                                _drop<String>(
                                    value: _status,
                                    items: _meetingStatuses,
                                    display: _cap,
                                    onChanged: (v) =>
                                        setState(() => _status = v!)),
                              ]),
                        ),
                      ]),
                      const SizedBox(height: 16),
                      _lbl('Client (optional)'),
                      _clientDrop(),
                      const SizedBox(height: 16),
                      if (_meetingMode == 'in_person') ...[
                        _lbl('Location'),
                        _field(_locationCtrl, 'Office address or room'),
                        const SizedBox(height: 16),
                      ] else ...[
                        _lbl('Meeting Link (optional)'),
                        _field(_linkCtrl, 'https://meet.google.com/...'),
                        const SizedBox(height: 16),
                      ],
                      _lbl('Description (optional)'),
                      _field(_descCtrl, 'Agenda, goals, or notes…',
                          maxLines: 3),
                      if (isEdit) ...[
                        const SizedBox(height: 16),
                        _lbl('Outcome Notes (optional)'),
                        _field(_notesCtrl,
                            'Summary of what was discussed…',
                            maxLines: 3),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            // ── Footer ──
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: _border))),
              child: Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _textSecondary,
                      side: BorderSide(color: _border),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding:
                          const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding:
                          const EdgeInsets.symmetric(vertical: 14),
                    ),
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : Icon(
                              isEdit
                                  ? Icons.save_rounded
                                  : Icons.event_rounded,
                              size: 18),
                      label: Text(
                        isEdit ? 'Save Changes' : 'Schedule Meeting',
                        style:
                            const TextStyle(fontWeight: FontWeight.w700),
                      ),
                  ),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _lbl(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: _textSecondary)),
      );

  Widget _field(TextEditingController ctrl, String hint,
      {int maxLines = 1, String? Function(String?)? validator}) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      style: TextStyle(color: _textPrimary, fontSize: 14),
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
            color: AppTheme.textMutedOf(context), fontSize: 13),
        filled: true,
        fillColor: _isDark
            ? const Color(0xFF1E2E42)
            : const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: _border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: _border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(
                color: Color(0xFF3B82F6), width: 1.5)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                const BorderSide(color: Color(0xFFEF4444))),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }

  Widget _drop<T>({
    required T value,
    required List<T> items,
    String Function(T)? display,
    required void Function(T?) onChanged,
  }) {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: _isDark
            ? const Color(0xFF1E2E42)
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          dropdownColor: _cardBg,
          style: TextStyle(color: _textPrimary, fontSize: 14),
          items: items
              .map((i) => DropdownMenuItem(
                    value: i,
                    child: Text(
                        display != null ? display(i) : i.toString(),
                        style: TextStyle(
                            color: _textPrimary, fontSize: 14)),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _clientDrop() {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: _isDark
            ? const Color(0xFF1E2E42)
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: _clientId,
          isExpanded: true,
          dropdownColor: _cardBg,
          hint: Text('No client selected',
              style: TextStyle(
                  color: AppTheme.textMutedOf(context),
                  fontSize: 14)),
          items: [
            DropdownMenuItem<String?>(
              value: null,
              child: Text('No client',
                  style: TextStyle(
                      color: _textSecondary, fontSize: 14)),
            ),
            ...widget.clients.map((c) => DropdownMenuItem<String?>(
                  value: c.id,
                  child: Text(c.name,
                      style: TextStyle(
                          color: _textPrimary, fontSize: 14)),
                )),
          ],
          onChanged: (v) => setState(() => _clientId = v),
        ),
      ),
    );
  }
}
