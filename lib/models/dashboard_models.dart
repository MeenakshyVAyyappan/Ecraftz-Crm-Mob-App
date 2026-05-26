class DashboardStats {
  final String label;
  final String value;
  final String subtitle;
  final String status;
  final String icon;
  final int colorIndex;

  const DashboardStats({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.status,
    required this.icon,
    required this.colorIndex,
  });
}

class ActivityItem {
  final String user;
  final String action;
  final String target;
  final String timeAgo;
  final int colorIndex;

  const ActivityItem({
    required this.user,
    required this.action,
    required this.target,
    required this.timeAgo,
    required this.colorIndex,
  });
}

class ProjectItem {
  final String name;
  final String client;
  final double progress;
  final int taskCount;
  final int totalTasks;
  final String status;

  const ProjectItem({
    required this.name,
    required this.client,
    required this.progress,
    required this.taskCount,
    required this.totalTasks,
    required this.status,
  });
}

class RecentTask {
  final String title;
  final String project;
  final String status;

  const RecentTask({
    required this.title,
    required this.project,
    required this.status,
  });
}

class RevenuePoint {
  final String month;
  final double pipeline;
  final double actual;

  const RevenuePoint({
    required this.month,
    required this.pipeline,
    required this.actual,
  });
}

// Sample Data
class DashboardData {
  static const List<DashboardStats> stats = [
    DashboardStats(
      label: 'TOTAL REVENUE',
      value: '₹2,500',
      subtitle: 'ALL TIME EARNINGS',
      status: 'STABLE',
      icon: 'currency_rupee',
      colorIndex: 0,
    ),
    DashboardStats(
      label: 'ACTIVE PROJECTS',
      value: '6',
      subtitle: 'ONGOING OPERATIONS',
      status: 'STABLE',
      icon: 'work_outline',
      colorIndex: 1,
    ),
    DashboardStats(
      label: 'OVERDUE TASKS',
      value: '0',
      subtitle: 'ALL CLEAR',
      status: 'STABLE',
      icon: 'warning_amber_rounded',
      colorIndex: 2,
    ),
    DashboardStats(
      label: 'RESOURCE LOAD',
      value: '0%',
      subtitle: '0H LOGGED / 7D',
      status: 'STABLE',
      icon: 'access_time',
      colorIndex: 3,
    ),
  ];

  static const List<ActivityItem> activities = [
    ActivityItem(
      user: 'Tony Stark',
      action: 'STATUS_CHANGE',
      target: 'Viswajith e',
      timeAgo: '2 DAYS AGO',
      colorIndex: 0,
    ),
    ActivityItem(
      user: 'Tony Stark',
      action: 'STATUS_CHANGE',
      target: 'viswajith null',
      timeAgo: '2 DAYS AGO',
      colorIndex: 1,
    ),
    ActivityItem(
      user: 'Tony Stark',
      action: 'STATUS_CHANGE',
      target: 'viswajith null',
      timeAgo: '2 DAYS AGO',
      colorIndex: 2,
    ),
    ActivityItem(
      user: 'Tony Stark',
      action: 'STATUS_CHANGE',
      target: 'shock stark',
      timeAgo: '2 DAYS AGO',
      colorIndex: 0,
    ),
    ActivityItem(
      user: 'Tony Stark',
      action: 'STATUS_CHANGE',
      target: 'shock stark',
      timeAgo: '2 DAYS AGO',
      colorIndex: 1,
    ),
  ];

  static const List<ProjectItem> projects = [
    ProjectItem(
      name: 'Digital Marketing Premium Intake v1',
      client: 'arsenal',
      progress: 1.0,
      taskCount: 1,
      totalTasks: 1,
      status: 'completed',
    ),
    ProjectItem(
      name: 'Web Development Dynamic Specification v1',
      client: 'janani',
      progress: 1.0,
      taskCount: 1,
      totalTasks: 1,
      status: 'completed',
    ),
    ProjectItem(
      name: 'ecocraft',
      client: 'ecocraft',
      progress: 0.0,
      taskCount: 0,
      totalTasks: 0,
      status: 'pending',
    ),
    ProjectItem(
      name: 'aliya',
      client: 'aliya',
      progress: 0.0,
      taskCount: 0,
      totalTasks: 0,
      status: 'pending',
    ),
    ProjectItem(
      name: 'flexora',
      client: 'flexora',
      progress: 0.0,
      taskCount: 0,
      totalTasks: 0,
      status: 'pending',
    ),
  ];

  static const List<RecentTask> tasks = [
    RecentTask(
      title: 'design dashboard',
      project: 'arsenal - Digital Marketing Premium Intake v1',
      status: 'DONE',
    ),
    RecentTask(
      title: 'develop this',
      project: 'janani - Web Development Dynamic Specification v1',
      status: 'DONE',
    ),
  ];

  static const List<RevenuePoint> revenueData = [
    RevenuePoint(month: 'Dec', pipeline: 0, actual: 0),
    RevenuePoint(month: 'Jan', pipeline: 200, actual: 100),
    RevenuePoint(month: 'Feb', pipeline: 400, actual: 300),
    RevenuePoint(month: 'Mar', pipeline: 600, actual: 500),
    RevenuePoint(month: 'Apr', pipeline: 2500, actual: 2500),
    RevenuePoint(month: 'May', pipeline: 2800, actual: 2500),
  ];
}
