import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'theme/app_theme.dart';
import 'screens/signin.dart';
import 'screens/main_shell.dart';
import 'screens/Employee/employee_dashboard.dart';
import 'services/supabase_service.dart';
import 'blocs/theme/theme_bloc.dart';
import 'blocs/auth/auth_bloc.dart';
import 'blocs/lead/lead_bloc.dart';
import 'blocs/client/client_bloc.dart';
import 'blocs/project/project_bloc.dart';
import 'blocs/task/task_bloc.dart';
import 'blocs/billing/billing_bloc.dart';
import 'blocs/dashboard/dashboard_bloc.dart';
import 'blocs/department/department_bloc.dart';
import 'blocs/onboarding/onboarding_bloc.dart';
import 'blocs/client_feedback/client_feedback_bloc.dart';
import 'blocs/meeting/meeting_bloc.dart';
import 'blocs/document_vault/document_vault_bloc.dart';
import 'blocs/crm_reports/crm_reports_bloc.dart';
import 'blocs/team_timesheet/team_timesheet_bloc.dart';
import 'blocs/attendance_device/attendance_device_bloc.dart';
import 'blocs/branch/branch_cubit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.initialize();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: AppTheme.bgCard,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => ThemeBloc()),
        BlocProvider(create: (_) => AuthBloc()..add(AuthCheckEvent())),
        BlocProvider<LeadBloc>(create: (_) => LeadBloc()),
        BlocProvider<ClientBloc>(create: (_) => ClientBloc()),
        BlocProvider<ProjectBloc>(create: (_) => ProjectBloc()),
        BlocProvider<TaskBloc>(create: (_) => TaskBloc()),
        BlocProvider<BillingBloc>(create: (_) => BillingBloc()),
        BlocProvider<DashboardBloc>(create: (_) => DashboardBloc()),
        BlocProvider<DepartmentBloc>(create: (_) => DepartmentBloc()),
        BlocProvider<OnboardingBloc>(create: (_) => OnboardingBloc()..add(LoadOnboardingDataEvent())),
        BlocProvider<ClientFeedbackBloc>(create: (_) => ClientFeedbackBloc()),
        BlocProvider<MeetingBloc>(create: (_) => MeetingBloc()),
        BlocProvider<DocumentVaultBloc>(create: (_) => DocumentVaultBloc()),
        BlocProvider<CrmReportsBloc>(create: (_) => CrmReportsBloc()),
        BlocProvider<TeamTimesheetBloc>(create: (_) => TeamTimesheetBloc()),
        BlocProvider<AttendanceDeviceBloc>(create: (_) => AttendanceDeviceBloc()),
        BlocProvider<BranchCubit>(create: (_) => BranchCubit()),
      ],
      child: const EcraftzCRMApp(),
    ),
  );
}

/// AuthWrapper is a StatefulWidget that tracks a login session counter.
/// Every time the user logs in (isLoginEvent = true), _loginSessionCount increments.
/// This counter is embedded in the key of EmployeeDashboardScreen and MainShell,
/// ensuring Flutter completely destroys and recreates the widget tree on each login —
/// even for the same user — so the latest department and profile data are always loaded.
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  // Incremented on every login. Changing this value changes the key on the
  // dashboard widget, forcing Flutter to tear down the old state completely
  // and build a fresh one that fetches the latest profile/department from Supabase.
  int _loginSessionCount = 0;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listenWhen: (previous, current) {
        // Rebuild listener only on meaningful state changes
        return current is Authenticated || current is Unauthenticated;
      },
      listener: (context, state) {
        if (state is Authenticated && state.isLoginEvent) {
          // Increment counter to force widget recreation with a new key
          setState(() {
            _loginSessionCount++;
          });
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Login successful.'),
              backgroundColor: AppTheme.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Future.delayed(const Duration(milliseconds: 1500), () {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Profile loaded successfully.'),
                  backgroundColor: AppTheme.success,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          });
        } else if (state is Unauthenticated) {
          if (state.loggedOut) {
            ScaffoldMessenger.of(context).clearSnackBars();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Logout successful.'),
                backgroundColor: AppTheme.success,
                behavior: SnackBarBehavior.floating,
              ),
            );
          } else if (state.sessionExpired) {
            ScaffoldMessenger.of(context).clearSnackBars();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Session expired. Please login again.'),
                backgroundColor: AppTheme.warning,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      },
      builder: (context, state) {
        if (state is AuthInitial || state is AuthLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (state is Authenticated) {
          if (state.role == 'employee') {
            // Key includes loginSessionCount so the widget is fully recreated
            // on every login, even if the same user logs in again after logout.
            return EmployeeDashboardScreen(
              key: ValueKey('emp_${state.user.id}_$_loginSessionCount'),
            );
          }
          return MainShell(
            key: ValueKey('admin_${state.user.id}_$_loginSessionCount'),
          );
        }
        // Unauthenticated or AuthError — show login
        return const LoginPage();
      },
    );
  }
}

class EcraftzCRMApp extends StatelessWidget {
  const EcraftzCRMApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, themeState) {
        final currentMode = themeState.themeMode;
        final isDark = currentMode == ThemeMode.dark;
        SystemChrome.setSystemUIOverlayStyle(
          SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
            systemNavigationBarColor: isDark ? AppTheme.bgCardDark : AppTheme.bgCard,
            systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
          ),
        );
        return MaterialApp(
          title: 'Ecraftz CRM',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: currentMode,
          home: const AuthWrapper(),
        );
      },
    );
  }
}
