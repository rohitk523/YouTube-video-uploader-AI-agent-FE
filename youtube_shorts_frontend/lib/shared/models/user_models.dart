import 'package:equatable/equatable.dart';

// User registration request model
class UserRegisterRequest extends Equatable {
  final String email;
  final String password;
  final String username;
  final String firstName;
  final String lastName;

  const UserRegisterRequest({
    required this.email,
    required this.password,
    required this.username,
    required this.firstName,
    required this.lastName,
  });

  Map<String, dynamic> toJson() => {
    'email': email,
    'password': password,
    'username': username,
    'first_name': firstName,
    'last_name': lastName,
  };

  @override
  List<Object> get props => [email, password, username, firstName, lastName];
}

// User login request model
class UserLoginRequest extends Equatable {
  final String email;
  final String password;
  final String scope;

  const UserLoginRequest({
    required this.email,
    required this.password,
    this.scope = 'read write upload youtube',
  });

  Map<String, dynamic> toFormData() => {
    'grant_type': 'password',
    'username': email,
    'password': password,
    'scope': scope,
  };

  @override
  List<Object> get props => [email, password, scope];
}

// Authentication response model
class AuthResponse extends Equatable {
  final String accessToken;
  final String tokenType;
  final int expiresIn;
  final String? refreshToken;
  final String? scope;
  final UserProfile? user;

  const AuthResponse({
    required this.accessToken,
    required this.tokenType,
    required this.expiresIn,
    this.refreshToken,
    this.scope,
    this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) => AuthResponse(
    accessToken: json['access_token'] as String,
    tokenType: json['token_type'] as String,
    expiresIn: json['expires_in'] as int,
    refreshToken: json['refresh_token'] as String?,
    scope: json['scope'] as String?,
    user: json['user'] != null ? UserProfile.fromJson(json['user']) : null,
  );

  Map<String, dynamic> toJson() => {
    'access_token': accessToken,
    'token_type': tokenType,
    'expires_in': expiresIn,
    if (refreshToken != null) 'refresh_token': refreshToken,
    if (scope != null) 'scope': scope,
    if (user != null) 'user': user!.toJson(),
  };

  @override
  List<Object?> get props => [accessToken, tokenType, expiresIn, refreshToken, scope, user];
}

// User profile model
class UserProfile extends Equatable {
  final String id;
  final String email;
  final String? username;
  final String? firstName;
  final String? lastName;
  final bool isActive;
  final bool isVerified;
  final String? profilePictureUrl;
  final String? provider;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastLoginAt;

  const UserProfile({
    required this.id,
    required this.email,
    this.username,
    this.firstName,
    this.lastName,
    required this.isActive,
    required this.isVerified,
    this.profilePictureUrl,
    this.provider,
    required this.createdAt,
    required this.updatedAt,
    this.lastLoginAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    id: json['id'] as String,
    email: json['email'] as String,
    username: json['username'] as String?,
    firstName: json['first_name'] as String?,
    lastName: json['last_name'] as String?,
    isActive: json['is_active'] as bool,
    isVerified: json['is_verified'] as bool,
    profilePictureUrl: json['profile_picture_url'] as String?,
    provider: json['provider'] as String?,
    createdAt: DateTime.parse(json['created_at'] as String),
    updatedAt: DateTime.parse(json['updated_at'] as String),
    lastLoginAt: json['last_login_at'] != null 
      ? DateTime.parse(json['last_login_at'] as String) 
      : null,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    if (username != null) 'username': username,
    if (firstName != null) 'first_name': firstName,
    if (lastName != null) 'last_name': lastName,
    'is_active': isActive,
    'is_verified': isVerified,
    if (profilePictureUrl != null) 'profile_picture_url': profilePictureUrl,
    if (provider != null) 'provider': provider,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    if (lastLoginAt != null) 'last_login_at': lastLoginAt!.toIso8601String(),
  };

  String get displayName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    }
    return username ?? email.split('@').first;
  }

  UserProfile copyWith({
    String? id,
    String? email,
    String? username,
    String? firstName,
    String? lastName,
    bool? isActive,
    bool? isVerified,
    String? profilePictureUrl,
    String? provider,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastLoginAt,
  }) => UserProfile(
    id: id ?? this.id,
    email: email ?? this.email,
    username: username ?? this.username,
    firstName: firstName ?? this.firstName,
    lastName: lastName ?? this.lastName,
    isActive: isActive ?? this.isActive,
    isVerified: isVerified ?? this.isVerified,
    profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
    provider: provider ?? this.provider,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    lastLoginAt: lastLoginAt ?? this.lastLoginAt,
  );

  @override
  List<Object?> get props => [
    id, email, username, firstName, lastName, isActive, isVerified,
    profilePictureUrl, provider, createdAt, updatedAt, lastLoginAt,
  ];
}

// Update profile request model
class UpdateProfileRequest extends Equatable {
  final String? username;
  final String? firstName;
  final String? lastName;
  final String? profilePictureUrl;

  const UpdateProfileRequest({
    this.username,
    this.firstName,
    this.lastName,
    this.profilePictureUrl,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (username != null) data['username'] = username;
    if (firstName != null) data['first_name'] = firstName;
    if (lastName != null) data['last_name'] = lastName;
    if (profilePictureUrl != null) data['profile_picture_url'] = profilePictureUrl;
    return data;
  }

  @override
  List<Object?> get props => [username, firstName, lastName, profilePictureUrl];
}

// Change password request model
class ChangePasswordRequest extends Equatable {
  final String currentPassword;
  final String newPassword;

  const ChangePasswordRequest({
    required this.currentPassword,
    required this.newPassword,
  });

  Map<String, dynamic> toJson() => {
    'current_password': currentPassword,
    'new_password': newPassword,
  };

  @override
  List<Object> get props => [currentPassword, newPassword];
}

// Refresh token request model
class RefreshTokenRequest extends Equatable {
  final String refreshToken;

  const RefreshTokenRequest({required this.refreshToken});

  Map<String, dynamic> toJson() => {
    'refresh_token': refreshToken,
  };

  @override
  List<Object> get props => [refreshToken];
} 