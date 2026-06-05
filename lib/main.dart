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
      ],
      child: const EcraftzCRMApp(),
    ),
  );
}

/// AuthWrapper uses BlocBuilder to switch screens inside the provider tree,
/// avoiding Navigator.pushReplacement which can lose provider context.
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthInitial || state is AuthLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (state is Authenticated) {
          if (state.role == 'employee') {
            return const EmployeeDashboardScreen();
          }
          return const MainShell();
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
