import 'package:equatable/equatable.dart';
import '../../../shared/models/upload_models.dart';

abstract class UploadState extends Equatable {
  const UploadState();

  @override
  List<Object?> get props => [];
}

class UploadInitial extends UploadState {}

class UploadLoading extends UploadState {}

class UploadProgress extends UploadState {
  final double progress;
  final String? message;

  const UploadProgress({
    required this.progress,
    this.message,
  });

  @override
  List<Object?> get props => [progress, message];
}

class VideoUploadSuccess extends UploadState {
  final UploadResponse uploadResponse;

  const VideoUploadSuccess(this.uploadResponse);

  @override
  List<Object> get props => [uploadResponse];
}

class TranscriptUploadSuccess extends UploadState {
  final UploadResponse uploadResponse;

  const TranscriptUploadSuccess(this.uploadResponse);

  @override
  List<Object> get props => [uploadResponse];
}

class UploadError extends UploadState {
  final String message;
  final String? errorCode;

  const UploadError({
    required this.message,
    this.errorCode,
  });

  @override
  List<Object?> get props => [message, errorCode];
} 