import 'package:equatable/equatable.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

abstract class UploadEvent extends Equatable {
  const UploadEvent();

  @override
  List<Object?> get props => [];
}

class UploadVideoEvent extends UploadEvent {
  final File? videoFile;
  final PlatformFile? platformFile;
  final String title;
  final String? description;
  final bool isTemp;

  const UploadVideoEvent({
    this.videoFile,
    this.platformFile,
    required this.title,
    this.description,
    this.isTemp = true,
  });

  @override
  List<Object?> get props => [videoFile, platformFile, title, description, isTemp];
}

class UploadTranscriptTextEvent extends UploadEvent {
  final String transcriptText;
  final String title;

  const UploadTranscriptTextEvent({
    required this.transcriptText,
    required this.title,
  });

  @override
  List<Object?> get props => [transcriptText, title];
}

class UploadTranscriptFileEvent extends UploadEvent {
  final File? transcriptFile;
  final PlatformFile? platformFile;
  final String title;

  const UploadTranscriptFileEvent({
    this.transcriptFile,
    this.platformFile,
    required this.title,
  });

  @override
  List<Object?> get props => [transcriptFile, platformFile, title];
}

class ResetUploadEvent extends UploadEvent {} 