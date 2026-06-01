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

  const Authenticated({required this.user, required this.role});

  @override
  List<Object?> get props => [user, role];
}

class Unauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc() : super(AuthInitial()) {
    on<AuthCheckEvent>((event, emit) {
      final user = SupabaseService.currentUser;
      if (user != null) {
        final role = user.userMetadata?['role']?.toString().toLowerCase() ?? '';
        emit(Authenticated(user: user, role: role));
      } else {
        emit(Unauthenticated());
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
          var role = user.userMetadata?['role']?.toString().toLowerCase() ?? '';
          if (role.isEmpty && event.email == 'employee@ecraftz.com') {
            role = 'employee';
          }
          emit(Authenticated(user: user, role: role));
        } else {
          emit(const AuthError('Login failed: user is null'));
        }
      } catch (e) {
        emit(AuthError(e is AuthException ? e.message : e.toString()));
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
          final role = user.userMetadata?['role']?.toString().toLowerCase() ?? '';
          emit(Authenticated(user: user, role: role));
        } else {
          emit(const AuthError('Registration failed: user is null'));
        }
      } catch (e) {
        emit(AuthError(e is AuthException ? e.message : e.toString()));
      }
    });

    on<AuthLogoutEvent>((event, emit) async {
      emit(AuthLoading());
      try {
        await SupabaseService.signOut();
        emit(Unauthenticated());
      } catch (e) {
        emit(AuthError(e.toString()));
      }
    });
  }
}
