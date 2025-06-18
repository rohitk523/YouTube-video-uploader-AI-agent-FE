import 'package:equatable/equatable.dart';
import '../../../shared/models/user_models.dart';

abstract class AuthState extends Equatable {
  const AuthState();
  
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final UserProfile user;
  final String token;
  
  const AuthAuthenticated({
    required this.user,
    required this.token,
  });
  
  @override
  List<Object> get props => [user, token];
}

class AuthUnauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;
  
  const AuthError(this.message);
  
  @override
  List<Object> get props => [message];
}

// Registration specific states
class RegisterLoading extends AuthState {}

class RegisterSuccess extends AuthState {
  final AuthResponse authResponse;
  
  const RegisterSuccess(this.authResponse);
  
  @override
  List<Object> get props => [authResponse];
}

class RegisterError extends AuthState {
  final String message;
  
  const RegisterError(this.message);
  
  @override
  List<Object> get props => [message];
}

// Login specific states
class LoginLoading extends AuthState {}

class LoginSuccess extends AuthState {
  final AuthResponse authResponse;
  
  const LoginSuccess(this.authResponse);
  
  @override
  List<Object> get props => [authResponse];
}

class LoginError extends AuthState {
  final String message;
  
  const LoginError(this.message);
  
  @override
  List<Object> get props => [message];
}

// Profile update states
class ProfileUpdateLoading extends AuthState {}

class ProfileUpdateSuccess extends AuthState {
  final UserProfile updatedProfile;
  
  const ProfileUpdateSuccess(this.updatedProfile);
  
  @override
  List<Object> get props => [updatedProfile];
}

class ProfileUpdateError extends AuthState {
  final String message;
  
  const ProfileUpdateError(this.message);
  
  @override
  List<Object> get props => [message];
}

// Password change states
class PasswordChangeLoading extends AuthState {}

class PasswordChangeSuccess extends AuthState {}

class PasswordChangeError extends AuthState {
  final String message;
  
  const PasswordChangeError(this.message);
  
  @override
  List<Object> get props => [message];
} 