import 'package:equatable/equatable.dart';
import '../../../shared/models/user_models.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  
  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {}

class AuthRegisterRequested extends AuthEvent {
  final UserRegisterRequest request;
  
  const AuthRegisterRequested(this.request);
  
  @override
  List<Object> get props => [request];
}

class AuthLoginRequested extends AuthEvent {
  final UserLoginRequest request;
  
  const AuthLoginRequested(this.request);
  
  @override
  List<Object> get props => [request];
}

class AuthLogoutRequested extends AuthEvent {}

class AuthTokenRefreshRequested extends AuthEvent {}

class AuthProfileUpdateRequested extends AuthEvent {
  final UpdateProfileRequest request;
  
  const AuthProfileUpdateRequested(this.request);
  
  @override
  List<Object> get props => [request];
}

class AuthPasswordChangeRequested extends AuthEvent {
  final ChangePasswordRequest request;
  
  const AuthPasswordChangeRequested(this.request);
  
  @override
  List<Object> get props => [request];
}

class AuthUserProfileRequested extends AuthEvent {} 