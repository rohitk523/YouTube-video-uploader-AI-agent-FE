import 'package:flutter_bloc/flutter_bloc.dart';
import '../repository/upload_repository.dart';
import 'upload_event.dart';
import 'upload_state.dart';

class UploadBloc extends Bloc<UploadEvent, UploadState> {
  final UploadRepository uploadRepository;

  UploadBloc(this.uploadRepository) : super(UploadInitial()) {
    on<UploadVideoEvent>(_onUploadVideo);
    on<UploadTranscriptTextEvent>(_onUploadTranscriptText);
    on<UploadTranscriptFileEvent>(_onUploadTranscriptFile);
    on<ResetUploadEvent>(_onResetUpload);
  }

  Future<void> _onUploadVideo(
    UploadVideoEvent event,
    Emitter<UploadState> emit,
  ) async {
    emit(UploadLoading());
    
    try {
      emit(const UploadProgress(progress: 0.1, message: 'Starting video upload...'));
      
      final response = await uploadRepository.uploadVideo(
        event.videoFile,
        title: event.title,
        description: event.description ?? '',
        platformFile: event.platformFile,
        isTemp: event.isTemp,
        onProgress: (progress) {
          emit(UploadProgress(
            progress: progress,
            message: 'Uploading video... ${(progress * 100).toInt()}%',
          ));
        },
      );
      
      emit(VideoUploadSuccess(response));
    } catch (e) {
      emit(UploadError(message: e.toString()));
    }
  }

  Future<void> _onUploadTranscriptText(
    UploadTranscriptTextEvent event,
    Emitter<UploadState> emit,
  ) async {
    emit(UploadLoading());
    
    try {
      emit(const UploadProgress(progress: 0.1, message: 'Uploading transcript...'));
      
      final response = await uploadRepository.uploadTranscriptText(
        event.transcriptText,
        title: event.title,
      );
      
      emit(TranscriptUploadSuccess(response));
    } catch (e) {
      emit(UploadError(message: e.toString()));
    }
  }

  Future<void> _onUploadTranscriptFile(
    UploadTranscriptFileEvent event,
    Emitter<UploadState> emit,
  ) async {
    emit(UploadLoading());
    
    try {
      emit(const UploadProgress(progress: 0.1, message: 'Uploading transcript file...'));
      
      final response = await uploadRepository.uploadTranscriptFile(
        event.transcriptFile,
        title: event.title,
        platformFile: event.platformFile,
        onProgress: (progress) {
          emit(UploadProgress(
            progress: progress,
            message: 'Uploading transcript... ${(progress * 100).toInt()}%',
          ));
        },
      );
      
      emit(TranscriptUploadSuccess(response));
    } catch (e) {
      emit(UploadError(message: e.toString()));
    }
  }

  void _onResetUpload(
    ResetUploadEvent event,
    Emitter<UploadState> emit,
  ) {
    emit(UploadInitial());
  }
} 