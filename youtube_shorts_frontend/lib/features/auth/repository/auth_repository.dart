import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/errors/app_exceptions.dart';
import '../../../shared/models/user_models.dart';

abstract class AuthRepository {
  Future<AuthResponse> register(UserRegisterRequest request);
  Future<AuthResponse> login(UserLoginRequest request);
  Future<AuthResponse> refreshToken();
  Future<UserProfile> getUserProfile();
  Future<UserProfile> updateProfile(UpdateProfileRequest request);
  Future<void> changePassword(ChangePasswordRequest request);
  Future<void> logout();
  Future<bool> isLoggedIn();
  Future<String?> getStoredToken();
  Future<UserProfile?> getStoredUser();
}

class AuthRepositoryImpl implements AuthRepository {
  final ApiClient _apiClient;
  
  AuthRepositoryImpl(this._apiClient);
  
  @override
  Future<AuthResponse> register(UserRegisterRequest request) async {
    try {
      final response = await _apiClient.post(
        ApiConstants.register,
        data: json.encode(request.toJson()),
      );
      
      final authResponse = AuthResponse.fromJson(response.data);
      
      // Store tokens and user data
      await _storeTokens(authResponse.accessToken, authResponse.refreshToken);
      if (authResponse.user != null) {
        await _storeUser(authResponse.user!);
      }
      
      return authResponse;
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  @override
  Future<AuthResponse> login(UserLoginRequest request) async {
    try {
      final response = await _apiClient.postForm(
        ApiConstants.token,
        request.toFormData(),
      );
      
      final authResponse = AuthResponse.fromJson(response.data);
      
      // Store tokens
      await _storeTokens(authResponse.accessToken, authResponse.refreshToken);
      
      // Get and store user profile
      final userProfile = await getUserProfile();
      await _storeUser(userProfile);
      
      return authResponse;
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  @override
  Future<AuthResponse> refreshToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final refreshTokenString = prefs.getString(ApiConstants.refreshTokenKey);
      
      if (refreshTokenString == null) {
        throw UnauthorizedException('No refresh token available');
      }
      
      final request = RefreshTokenRequest(refreshToken: refreshTokenString);
      final response = await _apiClient.post(
        ApiConstants.refreshToken,
        data: json.encode(request.toJson()),
      );
      
      final authResponse = AuthResponse.fromJson(response.data);
      
      // Update stored tokens
      await _storeTokens(authResponse.accessToken, authResponse.refreshToken);
      
      return authResponse;
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  @override
  Future<UserProfile> getUserProfile() async {
    try {
      final response = await _apiClient.get(ApiConstants.userInfo);
      return UserProfile.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  @override
  Future<UserProfile> updateProfile(UpdateProfileRequest request) async {
    try {
      final response = await _apiClient.put(
        ApiConstants.updateProfile,
        data: json.encode(request.toJson()),
      );
      
      final updatedProfile = UserProfile.fromJson(response.data);
      
      // Update stored user data
      await _storeUser(updatedProfile);
      
      return updatedProfile;
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  @override
  Future<void> changePassword(ChangePasswordRequest request) async {
    try {
      await _apiClient.post(
        ApiConstants.changePassword,
        data: json.encode(request.toJson()),
      );
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  @override
  Future<void> logout() async {
    try {
      // Call logout endpoint
      await _apiClient.post(ApiConstants.logout);
    } catch (e) {
      // Even if the API call fails, we should clear local storage
      print('Logout API call failed: $e');
    } finally {
      // Clear all stored data
      await _clearStoredData();
    }
  }
  
  @override
  Future<bool> isLoggedIn() async {
    try {
      final token = await getStoredToken();
      if (token == null) return false;
      
      // Check if token is expired
      if (_isTokenExpired(token)) {
        // Try to refresh token
        try {
          await refreshToken();
          return true;
        } catch (e) {
          await _clearStoredData();
          return false;
        }
      }
      
      return true;
    } catch (e) {
      return false;
    }
  }
  
  @override
  Future<String?> getStoredToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(ApiConstants.accessTokenKey);
  }
  
  @override
  Future<UserProfile?> getStoredUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString(ApiConstants.userDataKey);
      
      if (userDataString == null) return null;
      
      final userData = json.decode(userDataString);
      return UserProfile.fromJson(userData);
    } catch (e) {
      return null;
    }
  }
  
  // Private helper methods
  Future<void> _storeTokens(String accessToken, String? refreshToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(ApiConstants.accessTokenKey, accessToken);
    if (refreshToken != null) {
      await prefs.setString(ApiConstants.refreshTokenKey, refreshToken);
    }
  }
  
  Future<void> _storeUser(UserProfile user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(ApiConstants.userDataKey, json.encode(user.toJson()));
  }
  
  Future<void> _clearStoredData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(ApiConstants.accessTokenKey);
    await prefs.remove(ApiConstants.refreshTokenKey);
    await prefs.remove(ApiConstants.userDataKey);
  }
  
  bool _isTokenExpired(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;
      
      final payload = json.decode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );
      
      final exp = payload['exp'] as int?;
      if (exp == null) return true;
      
      final expiryDate = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      return DateTime.now().isAfter(expiryDate);
    } catch (e) {
      return true; // Assume expired if we can't parse
    }
  }
  
  AppException _handleError(dynamic error) {
    if (error is AppException) return error;
    return GenericException('Authentication error: ${error.toString()}');
  }
} 