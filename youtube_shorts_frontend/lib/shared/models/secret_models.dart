import 'package:equatable/equatable.dart';

// Secret validation response model
class SecretValidationResponse extends Equatable {
  final bool valid;
  final String? projectId;
  final String? clientIdPreview;
  final List<String> errors;
  final List<String> warnings;

  const SecretValidationResponse({
    required this.valid,
    this.projectId,
    this.clientIdPreview,
    this.errors = const [],
    this.warnings = const [],
  });

  factory SecretValidationResponse.fromJson(Map<String, dynamic> json) {
    return SecretValidationResponse(
      valid: json['valid'] ?? false,
      projectId: json['project_id'],
      clientIdPreview: json['client_id_preview'],
      errors: List<String>.from(json['errors'] ?? []),
      warnings: List<String>.from(json['warnings'] ?? []),
    );
  }

  @override
  List<Object?> get props => [valid, projectId, clientIdPreview, errors, warnings];
}

// Secret upload response model
class SecretUploadResponse extends Equatable {
  final String id;
  final String message;
  final SecretResponse secret;

  const SecretUploadResponse({
    required this.id,
    required this.message,
    required this.secret,
  });

  factory SecretUploadResponse.fromJson(Map<String, dynamic> json) {
    return SecretUploadResponse(
      id: json['id'],
      message: json['message'],
      secret: SecretResponse.fromJson(json['secret']),
    );
  }

  @override
  List<Object> get props => [id, message, secret];
}

// Secret response model
class SecretResponse extends Equatable {
  final String id;
  final String userId;
  final String projectId;
  final bool isActive;
  final bool isVerified;
  final String originalFilename;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastUsedAt;
  final String authUri;
  final String tokenUri;
  final String authProviderX509CertUrl;
  final List<String>? redirectUris;

  const SecretResponse({
    required this.id,
    required this.userId,
    required this.projectId,
    required this.isActive,
    required this.isVerified,
    required this.originalFilename,
    required this.createdAt,
    required this.updatedAt,
    this.lastUsedAt,
    required this.authUri,
    required this.tokenUri,
    required this.authProviderX509CertUrl,
    this.redirectUris,
  });

  factory SecretResponse.fromJson(Map<String, dynamic> json) {
    return SecretResponse(
      id: json['id'],
      userId: json['user_id'],
      projectId: json['project_id'],
      isActive: json['is_active'] ?? false,
      isVerified: json['is_verified'] ?? false,
      originalFilename: json['original_filename'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      lastUsedAt: json['last_used_at'] != null 
          ? DateTime.parse(json['last_used_at']) 
          : null,
      authUri: json['auth_uri'],
      tokenUri: json['token_uri'],
      authProviderX509CertUrl: json['auth_provider_x509_cert_url'],
      redirectUris: json['redirect_uris'] != null 
          ? List<String>.from(json['redirect_uris']) 
          : null,
    );
  }

  @override
  List<Object?> get props => [
    id, userId, projectId, isActive, isVerified, originalFilename,
    createdAt, updatedAt, lastUsedAt, authUri, tokenUri,
    authProviderX509CertUrl, redirectUris
  ];
}

// Secret status response model
class SecretStatusResponse extends Equatable {
  final bool hasSecrets;
  final int secretCount;
  final int activeSecrets;
  final DateTime? latestUpload;

  const SecretStatusResponse({
    required this.hasSecrets,
    required this.secretCount,
    required this.activeSecrets,
    this.latestUpload,
  });

  factory SecretStatusResponse.fromJson(Map<String, dynamic> json) {
    return SecretStatusResponse(
      hasSecrets: json['has_secrets'] ?? false,
      secretCount: json['secret_count'] ?? 0,
      activeSecrets: json['active_secrets'] ?? 0,
      latestUpload: json['latest_upload'] != null 
          ? DateTime.parse(json['latest_upload']) 
          : null,
    );
  }

  @override
  List<Object?> get props => [hasSecrets, secretCount, activeSecrets, latestUpload];
} 