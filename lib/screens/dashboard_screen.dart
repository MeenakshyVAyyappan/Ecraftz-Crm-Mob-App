import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/dashboard_models.dart';
import '../widgets/app_drawer.dart';
import '../widgets/stat_card.dart';
import '../widgets/revenue_chart.dart';
import '../widgets/donut_chart.dart';
import '../main.dart';

class DashboardScreen extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const DashboardScreen({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  int _selectedTab = 0;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: AppDrawer(
        selectedIndex: widget.selectedIndex,
        onItemSelected: (i) {
          widget.onItemSelected(i);
          Navigator.pop(context);
        },
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              _buildTopBar(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      _buildPageHeader(),
                      const SizedBox(height: 20),
                      _buildTabBar(),
                      if (_selectedTab == 0) ...[
                        const SizedBox(height: 20),
                        _buildDataVisibilityHeader(),
                        const SizedBox(height: 14),
                        _buildStatsGrid(),
                        const SizedBox(height: 24),
                        _buildActivitySection(),
                        const SizedBox(height: 24),
                        _buildDynamicWorkspaceHeader(),
                        const SizedBox(height: 16),
                        _buildRevenueCard(),
                        const SizedBox(height: 16),
                        _buildActiveProjectsCard(),
                        const SizedBox(height: 16),
                        _buildRecentTasksCard(),
                        const SizedBox(height: 16),
                        _buildBottomRow(),
                      ] else ...[
                        _buildDepartmentIntelligence(),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(bottom: BorderSide(color: AppTheme.borderOf(context))),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _scaffoldKey.currentState?.openDrawer(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDark ? AppTheme.bgBaseDark : AppTheme.bgBase,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.borderOf(context)),
              ),
              child: Icon(Icons.menu_rounded,
                  color: AppTheme.textSecondaryOf(context), size: 20),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: isDark ? AppTheme.bgBaseDark : AppTheme.bgBase,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.borderOf(context)),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  Icon(Icons.search_rounded,
                      color: AppTheme.textMutedOf(context), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Quick Search...',
                      style: TextStyle(
                          color: AppTheme.textMutedOf(context),
                          fontSize: 13.5,
                          fontWeight: FontWeight.w400),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          _buildThemeToggleButton(),
          const SizedBox(width: 8),
          Stack(
            clipBehavior: Clip.none,
            children: [
              _buildTopBarAction(Icons.notifications_none_rounded),
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                    color: AppTheme.error,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text('3',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          _buildAvatar(),
        ],
      ),
    );
  }

  Widget _buildThemeToggleButton() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () {
        themeNotifier.value = isDark ? ThemeMode.light : ThemeMode.dark;
      },
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: isDark ? AppTheme.bgBaseDark : AppTheme.bgBase,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.borderOf(context)),
        ),
        child: Icon(
          isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
          color: AppTheme.textSecondaryOf(context),
          size: 18,
        ),
      ),
    );
  }

  Widget _buildTopBarAction(IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: isDark ? AppTheme.bgBaseDark : AppTheme.bgBase,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderOf(context)),
      ),
      child: Icon(icon, color: AppTheme.textSecondaryOf(context), size: 18),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primary, Color(0xFF34AAFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: const Center(
        child: Text('SA',
            style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5)),
      ),
    );
  }

  Widget _buildPageHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dashboard',
              style: TextStyle(
                color: AppTheme.textPrimaryOf(context),
                fontSize: 26,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.8,
                height: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Operational command center',
              style: TextStyle(
                color: AppTheme.textSecondaryOf(context),
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.primary, Color(0xFF34AAFF)],
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Row(
            children: [
              Icon(Icons.add_rounded, color: Colors.white, size: 16),
              SizedBox(width: 4),
              Text('New',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderOf(context)),
      ),
      child: Row(
        children: [
          _buildTab(0, Icons.business_center_outlined, 'Enterprise Overview'),
          _buildTab(1, Icons.people_alt_outlined, 'Department Intelligence'),
        ],
      ),
    );
  }

  Widget _buildTab(int index, IconData icon, String label) {
    final isActive = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? AppTheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: AppTheme.primary.withOpacity(0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 15,
                  color: isActive
                      ? Colors.white
                      : AppTheme.textSecondaryOf(context)),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? Colors.white : AppTheme.textSecondaryOf(context),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDataVisibilityHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.filter_list_rounded,
                    size: 14, color: AppTheme.textSecondaryOf(context)),
                const SizedBox(width: 6),
                Text(
                  'DATA VISIBILITY',
                  style: TextStyle(
                    color: AppTheme.textPrimaryOf(context),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              'Analyze your metrics by timeframe',
              style: TextStyle(
                  color: AppTheme.textMutedOf(context),
                  fontSize: 10.5),
            ),
          ],
        ),
        Row(
          children: [
            _buildTimeButton('All Time', true),
            const SizedBox(width: 6),
            _buildTimeButton('Custom Range', false),
          ],
        ),
      ],
    );
  }

  Widget _buildTimeButton(String label, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isActive ? AppTheme.primary : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: isActive ? AppTheme.primary : AppTheme.borderOf(context)),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: AppTheme.primary.withOpacity(0.25),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                )
              ]
            : null,
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isActive ? Colors.white : AppTheme.textSecondaryOf(context),
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.1,
      ),
      itemCount: DashboardData.stats.length,
      itemBuilder: (context, i) =>
          StatCard(stat: DashboardData.stats[i], index: i),
    );
  }

  Widget _buildActivitySection() {
    return _SectionCard(
      title: 'RECENT OPERATIONAL ACTIVITY',
      subtitle: 'Real-time log of administrative and system events',
      trailing: _liveBadge(),
      child: Column(
        children: DashboardData.activities
            .map((a) => _buildActivityItem(a))
            .toList(),
      ),
    );
  }

  Widget _liveBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppTheme.success.withOpacity(0.15)
            : AppTheme.successLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.success.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
                color: AppTheme.success, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          const Text('LIVE',
              style: TextStyle(
                  color: AppTheme.success,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5)),
        ],
      ),
    );
  }

  Widget _buildActivityItem(ActivityItem a) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: [
                AppTheme.primary,
                AppTheme.success,
                AppTheme.warning
              ][a.colorIndex % 3],
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '${a.user} ',
                    style: TextStyle(
                      color: AppTheme.textPrimaryOf(context),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextSpan(
                    text: '${a.action} ',
                    style: TextStyle(
                      color: AppTheme.textSecondaryOf(context),
                      fontSize: 12.5,
                    ),
                  ),
                  TextSpan(
                    text: a.target,
                    style: const TextStyle(
                      color: AppTheme.primary,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            a.timeAgo,
            style: TextStyle(
                color: AppTheme.textMutedOf(context),
                fontSize: 10,
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildDynamicWorkspaceHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.add_circle_outline_rounded,
                    size: 14, color: AppTheme.textSecondaryOf(context)),
                const SizedBox(width: 6),
                Text('DYNAMIC WORKSPACE',
                    style: TextStyle(
                      color: AppTheme.textPrimaryOf(context),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                    )),
              ],
            ),
            const SizedBox(height: 2),
            Text('Personalize your command center layout',
                style: TextStyle(color: AppTheme.textMutedOf(context), fontSize: 10.5)),
          ],
        ),
        TextButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.refresh_rounded, size: 14),
          label: const Text('Reset Layout',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          style: TextButton.styleFrom(
              foregroundColor: AppTheme.primary,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6)),
        ),
      ],
    );
  }

  Widget _buildRevenueCard() {
    return _SectionCard(
      title: 'REVENUE VELOCITY',
      subtitle: '',
      headerIcon: Icons.trending_up_rounded,
      trailing: _operationalBadge(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹2,500',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimaryOf(context),
                  letterSpacing: -1.5,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppTheme.success.withOpacity(0.15)
                      : AppTheme.successLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.arrow_upward_rounded,
                        size: 12, color: AppTheme.success),
                    Text('+12.5%',
                        style: TextStyle(
                            color: AppTheme.success,
                            fontSize: 11,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const RevenueChart(),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildLegendItem('Pipeline', AppTheme.primary.withOpacity(0.5), isDashed: true),
              const SizedBox(width: 16),
              _buildLegendItem('Actual Revenue', AppTheme.primary),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, {bool isDashed = false}) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 2,
          color: color,
        ),
        const SizedBox(width: 6),
        Text(label,
            style: TextStyle(
                color: AppTheme.textSecondaryOf(context),
                fontSize: 11,
                fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _operationalBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppTheme.primary.withOpacity(0.15)
            : AppTheme.primaryLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
      ),
      child: const Text('OPERATIONAL',
          style: TextStyle(
              color: AppTheme.primary,
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5)),
    );
  }

  Widget _buildActiveProjectsCard() {
    return _SectionCard(
      title: 'Active Projects',
      subtitle: '',
      headerIcon: Icons.folder_outlined,
      child: Column(
        children: DashboardData.projects
            .map((p) => _buildProjectItem(p))
            .toList(),
      ),
    );
  }

  Widget _buildProjectItem(ProjectItem p) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '${p.client} - ${p.name}',
                  style: TextStyle(
                    color: AppTheme.textPrimaryOf(context),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${(p.progress * 100).toInt()}%',
                style: TextStyle(
                  color: p.progress == 1.0
                      ? AppTheme.success
                      : AppTheme.textSecondaryOf(context),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: p.progress,
              backgroundColor: AppTheme.borderOf(context),
              valueColor: AlwaysStoppedAnimation<Color>(
                p.progress == 1.0 ? AppTheme.primary : AppTheme.textMutedOf(context),
              ),
              minHeight: 5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${p.taskCount} / ${p.totalTasks} TASKS',
            style: TextStyle(
                color: AppTheme.textMutedOf(context),
                fontSize: 10,
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTasksCard() {
    return _SectionCard(
      title: 'Recent Tasks',
      subtitle: '',
      headerIcon: Icons.check_circle_outline_rounded,
      child: Column(
        children: DashboardData.tasks
            .map((t) => _buildTaskItem(t))
            .toList(),
      ),
    );
  }

  Widget _buildTaskItem(RecentTask t) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.title,
                  style: TextStyle(
                    color: AppTheme.textPrimaryOf(context),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  t.project,
                  style: TextStyle(
                      color: AppTheme.textMutedOf(context),
                      fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppTheme.success.withOpacity(0.15)
                  : AppTheme.successLight,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.success.withOpacity(0.2)),
            ),
            child: Text(
              t.status,
              style: const TextStyle(
                color: AppTheme.success,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomRow() {
    return Column(
      children: [
        _SectionCard(
          title: 'CRITICAL DEADLINES',
          subtitle: '',
          headerIcon: Icons.warning_amber_rounded,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Icon(Icons.check_circle_outline_rounded,
                      color: AppTheme.success, size: 40),
                  const SizedBox(height: 8),
                  Text('ALL RESOURCES ARE STABLE',
                      style: TextStyle(
                          color: AppTheme.textMutedOf(context),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildFinancialLiquidity(),
      ],
    );
  }

  Widget _buildFinancialLiquidity() {
    return _SectionCard(
      title: 'FINANCIAL LIQUIDITY',
      subtitle: '',
      headerIcon: Icons.account_balance_wallet_outlined,
      headerIconColor: AppTheme.success,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const DonutChart(
            percentage: 48,
            label: 'HEALTH',
            color: AppTheme.primary,
            size: 100,
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              children: [
                _buildLiquidityItem('LIQUID ASSETS', '₹2,500', AppTheme.primary, 0.48),
                const SizedBox(height: 16),
                _buildLiquidityItem('RECEIVABLES', '₹2,720', AppTheme.info, 0.52),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiquidityItem(
      String label, String value, Color color, double fraction) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                        color: color, shape: BoxShape.circle)),
                const SizedBox(width: 6),
                Text(label,
                    style: TextStyle(
                        color: AppTheme.textSecondaryOf(context),
                        fontSize: 11,
                        fontWeight: FontWeight.w500)),
              ],
            ),
            Text(value,
                style: TextStyle(
                    color: AppTheme.textPrimaryOf(context),
                    fontSize: 13,
                    fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: fraction,
            backgroundColor: AppTheme.borderOf(context),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 5,
          ),
        ),
      ],
    );
  }

  Widget _buildDepartmentIntelligence() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        _buildDeptWorkspaceHeader(),
        const SizedBox(height: 16),
        _buildDeptStatsGrid(),
        const SizedBox(height: 20),
        _buildProductivityChart(),
        const SizedBox(height: 20),
        _buildKpiAndAlerts(),
        const SizedBox(height: 20),
        _buildWorkforceAlignment(),
      ],
    );
  }

  Widget _buildDeptWorkspaceHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'DEPARTMENT OPERATIONS WORKSPACE',
          style: TextStyle(
            color: AppTheme.textPrimaryOf(context),
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'ADMIN CONTROL COCKPIT: DYNAMICALLY SWITCH AND AGGREGATE CORPORATE DEPARTMENTS.',
          style: TextStyle(color: AppTheme.textMutedOf(context), fontSize: 10),
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerLeft,
          child: _buildCockpitDropdown(),
        ),
      ],
    );
  }

  Widget _buildCockpitDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderOf(context)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'SELECT COCKPIT:',
            style: TextStyle(
              color: AppTheme.textSecondaryOf(context),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 6),
          Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: AppTheme.textSecondaryOf(context)),
        ],
      ),
    );
  }

  Widget _buildDeptStatCard(
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color color,
    Color bgColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderOf(context)),
        boxShadow: AppTheme.cardShadowOf(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  style: TextStyle(
                    color: AppTheme.textSecondaryOf(context),
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              color: AppTheme.textPrimaryOf(context),
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: AppTheme.textMutedOf(context),
              fontSize: 9,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeptStatsGrid() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.1,
      children: [
        _buildDeptStatCard(
          'Dept Capacity',
          '0 Staff',
          '40H CAPACITY WEEKLY',
          Icons.people_alt_outlined,
          AppTheme.primary,
          isDark ? AppTheme.primary.withOpacity(0.15) : AppTheme.primaryLight,
        ),
        _buildDeptStatCard(
          'Active Workload',
          '0 hrs',
          '0 TOTAL ACTIVE TASKS',
          Icons.access_time_rounded,
          AppTheme.info,
          isDark ? AppTheme.info.withOpacity(0.15) : AppTheme.infoLight,
        ),
        _buildDeptStatCard(
          'Capacity Allocation',
          '0%',
          'OPTIMAL WORK BALANCE',
          Icons.trending_up_rounded,
          AppTheme.textSecondaryOf(context),
          isDark ? AppTheme.bgBaseDark : AppTheme.bgBase,
        ),
        _buildDeptStatCard(
          'Time Desk Status',
          '0 Clocked',
          '0 ACTIVE/OFF SHIFT',
          Icons.insights_rounded,
          AppTheme.success,
          isDark ? AppTheme.success.withOpacity(0.15) : AppTheme.successLight,
        ),
      ],
    );
  }

  Widget _buildProductivityChart() {
    return _SectionCard(
      title: 'DEPARTMENT PRODUCTIVITY METRICS',
      subtitle: 'VISUAL REPORTING ENGINE AGGREGATED IN REAL TIME.',
      trailing: Row(
        children: [
          _buildExportButton(Icons.download_rounded, 'CSV'),
          const SizedBox(width: 6),
          _buildExportButton(Icons.picture_as_pdf_rounded, 'PDF'),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            height: 160,
            child: CustomPaint(
              painter: _DeptChartPainter(
                borderColor: AppTheme.borderOf(context),
                textColor: AppTheme.textMutedOf(context),
              ),
              child: const SizedBox(height: 160, width: double.infinity),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExportButton(IconData icon, String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.bgBaseDark : AppTheme.bgBase,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.borderOf(context)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 12, color: AppTheme.textSecondaryOf(context)),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: AppTheme.textSecondaryOf(context),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiAndAlerts() {
    return Column(
      children: [
        _SectionCard(
          title: 'DEPARTMENT KPI ENGINES',
          subtitle: 'ENTERPRISE METRIC SCOPES AGGREGATED DYNAMICALLY.',
          child: Column(
            children: [
              _buildKpiItem('Task Completion Rate', '0 / 0 tasks', 0.0),
              const SizedBox(height: 16),
              _buildKpiItem('Staff Utilization', '0 / 50 %', 0.0),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _SectionCard(
          title: 'OPERATIONAL ALERTS & ESCALATE',
          subtitle: 'URGENT DEPARTMENT INCIDENTS REQUIRING LEAD ACTION.',
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_outline_rounded,
                      color: AppTheme.success, size: 24),
                  const SizedBox(width: 8),
                  const Text(
                    'SLA HEALTH: OPTIMUM',
                    style: TextStyle(
                      color: AppTheme.success,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildKpiItem(String label, String value, double progress) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                color: AppTheme.textPrimaryOf(context),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                color: AppTheme.textSecondaryOf(context),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: AppTheme.borderOf(context),
            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  Widget _buildWorkforceAlignment() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _SectionCard(
      title: 'WORKFORCE ALIGNMENT & OPERATIONS',
      subtitle: 'OVERVIEW OF PERSONNEL MAPPED TO THE ACTIVE DEPARTMENT STRUCTURE.',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.bgBaseDark : AppTheme.bgBase,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.borderOf(context),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline_rounded,
                color: AppTheme.textMutedOf(context), size: 36),
            const SizedBox(height: 10),
            Text(
              'NO STAFF MAPPED TO THIS DEPARTMENT',
              style: TextStyle(
                color: AppTheme.textMutedOf(context),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeptChartPainter extends CustomPainter {
  final Color borderColor;
  final Color textColor;
  _DeptChartPainter({required this.borderColor, required this.textColor});

  @override
  void paint(Canvas canvas, Size size) {
    const double paddingLeft = 16;
    const double paddingRight = 16;
    const double paddingTop = 10;
    const double paddingBottom = 20;

    final double chartW = size.width - paddingLeft - paddingRight;
    final double chartH = size.height - paddingTop - paddingBottom;
    final double stepX = chartW / 4; // 5 days: Mon, Tue, Wed, Thu, Fri

    // Draw grid lines
    final gridPaint = Paint()
      ..color = borderColor.withOpacity(0.6)
      ..strokeWidth = 1;

    // Horizontal grid lines
    for (int i = 0; i <= 4; i++) {
      final y = paddingTop + (chartH / 4) * i;
      canvas.drawLine(Offset(paddingLeft, y), Offset(size.width - paddingRight, y), gridPaint);
    }

    // Vertical grid lines
    for (int i = 0; i < 5; i++) {
      final x = paddingLeft + i * stepX;
      canvas.drawLine(Offset(x, paddingTop), Offset(x, paddingTop + chartH), gridPaint);
    }

    // Draw labels
    final List<String> days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];
    final textStyle = TextStyle(
      color: textColor,
      fontSize: 9,
      fontWeight: FontWeight.w500,
    );

    for (int i = 0; i < 5; i++) {
      final x = paddingLeft + i * stepX;
      final tp = TextPainter(
        text: TextSpan(text: days[i], style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, size.height - paddingBottom + 4));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? trailing;
  final Widget child;
  final IconData? headerIcon;
  final Color? headerIconColor;

  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
    this.trailing,
    this.headerIcon,
    this.headerIconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderOf(context)),
        boxShadow: AppTheme.cardShadowOf(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    if (headerIcon != null) ...[
                      Icon(headerIcon!,
                          size: 15,
                          color:
                              headerIconColor ?? AppTheme.textSecondaryOf(context)),
                      const SizedBox(width: 7),
                    ],
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          color: AppTheme.textPrimaryOf(context),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                        softWrap: true,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 8),
                trailing!,
              ],
            ],
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(subtitle,
                style: TextStyle(
                    color: AppTheme.textMutedOf(context), fontSize: 10.5)),
          ],
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}
