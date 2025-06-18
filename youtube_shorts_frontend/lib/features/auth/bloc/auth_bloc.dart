import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/errors/app_exceptions.dart';
import '../repository/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;
  
  AuthBloc(this._authRepository) : super(AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthRegisterRequested>(_onAuthRegisterRequested);
    on<AuthLoginRequested>(_onAuthLoginRequested);
    on<AuthLogoutRequested>(_onAuthLogoutRequested);
    on<AuthTokenRefreshRequested>(_onAuthTokenRefreshRequested);
    on<AuthProfileUpdateRequested>(_onAuthProfileUpdateRequested);
    on<AuthPasswordChangeRequested>(_onAuthPasswordChangeRequested);
    on<AuthUserProfileRequested>(_onAuthUserProfileRequested);
  }
  
  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    
    try {
      final isLoggedIn = await _authRepository.isLoggedIn();
      
      if (isLoggedIn) {
        final user = await _authRepository.getStoredUser();
        final token = await _authRepository.getStoredToken();
        
        if (user != null && token != null) {
          emit(AuthAuthenticated(user: user, token: token));
        } else {
          // Try to get fresh user profile
          try {
            final freshUser = await _authRepository.getUserProfile();
            final freshToken = await _authRepository.getStoredToken();
            if (freshToken != null) {
              emit(AuthAuthenticated(user: freshUser, token: freshToken));
            } else {
              emit(AuthUnauthenticated());
            }
          } catch (e) {
            emit(AuthUnauthenticated());
          }
        }
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      emit(AuthUnauthenticated());
    }
  }
  
  Future<void> _onAuthRegisterRequested(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(RegisterLoading());
    
    try {
      final authResponse = await _authRepository.register(event.request);
      emit(RegisterSuccess(authResponse));
      
      // After successful registration, update main auth state
      if (authResponse.user != null) {
        final token = await _authRepository.getStoredToken();
        if (token != null) {
          emit(AuthAuthenticated(user: authResponse.user!, token: token));
        }
      }
    } catch (e) {
      final message = e is AppException ? e.message : 'Registration failed';
      emit(RegisterError(message));
    }
  }
  
  Future<void> _onAuthLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(LoginLoading());
    
    try {
      final authResponse = await _authRepository.login(event.request);
      emit(LoginSuccess(authResponse));
      
      // After successful login, get user profile and update main auth state
      final user = await _authRepository.getStoredUser();
      final token = await _authRepository.getStoredToken();
      
      if (user != null && token != null) {
        emit(AuthAuthenticated(user: user, token: token));
      }
    } catch (e) {
      final message = e is AppException ? e.message : 'Login failed';
      emit(LoginError(message));
    }
  }
  
  Future<void> _onAuthLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    
    try {
      await _authRepository.logout();
      emit(AuthUnauthenticated());
    } catch (e) {
      // Even if logout API call fails, clear local state
      emit(AuthUnauthenticated());
    }
  }
  
  Future<void> _onAuthTokenRefreshRequested(
    AuthTokenRefreshRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      await _authRepository.refreshToken();
      
      // Update auth state with fresh token
      final user = await _authRepository.getStoredUser();
      final token = await _authRepository.getStoredToken();
      
      if (user != null && token != null) {
        emit(AuthAuthenticated(user: user, token: token));
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      emit(AuthUnauthenticated());
    }
  }
  
  Future<void> _onAuthProfileUpdateRequested(
    AuthProfileUpdateRequested event,
    Emitter<AuthState> emit,
  ) async {
    if (state is! AuthAuthenticated) return;
    
    final currentState = state as AuthAuthenticated;
    emit(ProfileUpdateLoading());
    
    try {
      final updatedProfile = await _authRepository.updateProfile(event.request);
      emit(ProfileUpdateSuccess(updatedProfile));
      
      // Update main auth state with new profile
      emit(AuthAuthenticated(user: updatedProfile, token: currentState.token));
    } catch (e) {
      final message = e is AppException ? e.message : 'Profile update failed';
      emit(ProfileUpdateError(message));
      
      // Restore previous auth state
      emit(currentState);
    }
  }
  
  Future<void> _onAuthPasswordChangeRequested(
    AuthPasswordChangeRequested event,
    Emitter<AuthState> emit,
  ) async {
    if (state is! AuthAuthenticated) return;
    
    final currentState = state as AuthAuthenticated;
    emit(PasswordChangeLoading());
    
    try {
      await _authRepository.changePassword(event.request);
      emit(PasswordChangeSuccess());
      
      // Restore auth state
      emit(currentState);
    } catch (e) {
      final message = e is AppException ? e.message : 'Password change failed';
      emit(PasswordChangeError(message));
      
      // Restore previous auth state
      emit(currentState);
    }
  }
  
  Future<void> _onAuthUserProfileRequested(
    AuthUserProfileRequested event,
    Emitter<AuthState> emit,
  ) async {
    if (state is! AuthAuthenticated) return;
    
    final currentState = state as AuthAuthenticated;
    
    try {
      final freshProfile = await _authRepository.getUserProfile();
      final token = await _authRepository.getStoredToken();
      
      if (token != null) {
        emit(AuthAuthenticated(user: freshProfile, token: token));
      }
    } catch (e) {
      // Keep current state if profile fetch fails
      emit(currentState);
    }
  }
} 