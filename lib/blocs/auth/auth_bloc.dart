import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/supabase_service.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class AuthLoginEvent extends AuthEvent {
  final String email;
  final String password;

  const AuthLoginEvent({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

class AuthRegisterEvent extends AuthEvent {
  final String email;
  final String password;
  final String name;

  const AuthRegisterEvent({required this.email, required this.password, required this.name});

  @override
  List<Object?> get props => [email, password, name];
}

class AuthLogoutEvent extends AuthEvent {}

class AuthCheckEvent extends AuthEvent {}

abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class Authenticated extends AuthState {
  final User user;
  final String role;
  final bool isLoginEvent;

  const Authenticated({required this.user, required this.role, this.isLoginEvent = false});

  @override
  List<Object?> get props => [user, role, isLoginEvent];
}

class Unauthenticated extends AuthState {
  final bool loggedOut;
  final bool sessionExpired;

  const Unauthenticated({this.loggedOut = false, this.sessionExpired = false});

  @override
  List<Object?> get props => [loggedOut, sessionExpired];
}

class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}

class AuthRegistrationSuccess extends AuthState {}

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  bool _wasAuthenticated = false;

  AuthBloc() : super(AuthInitial()) {
    on<AuthCheckEvent>((event, emit) async {
      final user = SupabaseService.currentUser;
      if (user != null) {
        try {
          final profile = await SupabaseService.client
              .from('profiles')
              .select('role, status')
              .eq('id', user.id)
              .maybeSingle();

          if (profile != null) {
            final status = profile['status']?.toString().toLowerCase() ?? 'pending';
            if (status == 'active') {
              final role = profile['role']?.toString().toLowerCase() ?? 'employee';
              _wasAuthenticated = true;
              emit(Authenticated(user: user, role: role));
              return;
            }
          }
          await SupabaseService.signOut();
          final hadSession = _wasAuthenticated;
          _wasAuthenticated = false;
          emit(Unauthenticated(sessionExpired: hadSession));
        } catch (e) {
          final role = user.userMetadata?['role']?.toString().toLowerCase() ?? 'employee';
          _wasAuthenticated = true;
          emit(Authenticated(user: user, role: role));
        }
      } else {
        final hadSession = _wasAuthenticated;
        _wasAuthenticated = false;
        emit(Unauthenticated(sessionExpired: hadSession));
      }
    });

    on<AuthLoginEvent>((event, emit) async {
      emit(AuthLoading());
      try {
        final response = await SupabaseService.signInWithEmail(
          email: event.email,
          password: event.password,
        );
        final user = response.user;
        if (user != null) {
          final profile = await SupabaseService.client
              .from('profiles')
              .select('role, status')
              .eq('id', user.id)
              .maybeSingle();

          if (profile == null) {
            await SupabaseService.signOut();
            _wasAuthenticated = false;
            emit(const AuthError('User profile not found. Please contact an administrator.'));
            return;
          }

          final status = profile['status']?.toString().toLowerCase() ?? 'pending';
          if (status != 'active') {
            await SupabaseService.signOut();
            _wasAuthenticated = false;
            if (status == 'pending') {
              emit(const AuthError('Your account is pending admin approval.'));
            } else if (status == 'denied') {
              emit(const AuthError('Your account has been denied. Please contact the administrator.'));
            } else if (status == 'archived') {
              emit(const AuthError('Your account has been archived. Please contact the administrator.'));
            } else {
              emit(AuthError('Your account is $status. Please contact an administrator.'));
            }
            return;
          }

          final role = profile['role']?.toString().toLowerCase() ?? 'employee';
          _wasAuthenticated = true;
          emit(Authenticated(user: user, role: role, isLoginEvent: true));
        } else {
          _wasAuthenticated = false;
          emit(const AuthError('Unable to login. Please try again.'));
        }
      } catch (e) {
        print('AUTH_BLOC LOGIN ERROR: $e (Type: ${e.runtimeType})');
        _wasAuthenticated = false;
        final errStr = e.toString().toLowerCase();
        if (errStr.contains('invalid login credentials') || errStr.contains('invalid_credentials') || errStr.contains('invalid email or password')) {
          emit(const AuthError('Invalid email or password.'));
        } else if (errStr.contains('socketexception') || errStr.contains('failed host lookup') || errStr.contains('network') || errStr.contains('connection')) {
          emit(AuthError('Network error: $e. Please check your internet connection.'));
        } else {
          emit(AuthError('Unable to login: $e. Please try again.'));
        }
      }
    });

    on<AuthRegisterEvent>((event, emit) async {
      emit(AuthLoading());
      try {
        final response = await SupabaseService.signUpWithEmail(
          email: event.email,
          password: event.password,
          name: event.name,
        );
        final user = response.user;
        if (user != null) {
          try {
            await SupabaseService.client.from('profiles').upsert({
              'id': user.id,
              'full_name': event.name,
              'email': event.email,
              'role': 'employee',
              'status': 'pending',
              'organization_id': '00000000-0000-0000-0000-000000000000',
              'updated_at': DateTime.now().toUtc().toIso8601String(),
            });
          } catch (profileError) {
            print('Profile upsert exception (ignoring if trigger exists): $profileError');
          }
          await SupabaseService.signOut();
          emit(AuthRegistrationSuccess());
        } else {
          emit(const AuthError('Registration failed. Please try again.'));
        }
      } catch (e) {
        final errStr = e.toString().toLowerCase();
        if (errStr.contains('already registered') || errStr.contains('already exists') || errStr.contains('user_already_exists') || errStr.contains('email already in use')) {
          emit(const AuthError('This email is already registered.'));
        } else {
          emit(const AuthError('Registration failed. Please try again.'));
        }
      }
    });

    on<AuthLogoutEvent>((event, emit) async {
      emit(AuthLoading());
      try {
        await SupabaseService.signOut();
        _wasAuthenticated = false;
        emit(const Unauthenticated(loggedOut: true));
      } catch (e) {
        emit(AuthError(e.toString()));
      }
    });
  }
}
