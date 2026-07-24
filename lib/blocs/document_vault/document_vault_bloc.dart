import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/document_model.dart';
import '../../services/document_vault_service.dart';

abstract class DocumentVaultEvent {}
class LoadDocumentsEvent extends DocumentVaultEvent {}
class UploadDocumentEvent extends DocumentVaultEvent {
  final String title;
  final File file;
  final String category;
  final String? clientId;
  final String? projectId;
  final String version;
  final String? description;

  UploadDocumentEvent({
    required this.title,
    required this.file,
    required this.category,
    this.clientId,
    this.projectId,
    this.version = '1.0',
    this.description,
  });
}
class DeleteDocumentEvent extends DocumentVaultEvent {
  final String id;
  DeleteDocumentEvent(this.id);
}

enum DocumentVaultStatus { initial, loading, loaded, error }

class DocumentVaultState {
  final DocumentVaultStatus status;
  final List<CrmDocument> documents;
  final String? errorMessage;

  DocumentVaultState({
    this.status = DocumentVaultStatus.initial,
    this.documents = const [],
    this.errorMessage,
  });

  DocumentVaultState copyWith({
    DocumentVaultStatus? status,
    List<CrmDocument>? documents,
    String? errorMessage,
  }) {
    return DocumentVaultState(
      status: status ?? this.status,
      documents: documents ?? this.documents,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class DocumentVaultBloc extends Bloc<DocumentVaultEvent, DocumentVaultState> {
  DocumentVaultBloc() : super(DocumentVaultState()) {
    on<LoadDocumentsEvent>(_onLoad);
    on<UploadDocumentEvent>(_onUpload);
    on<DeleteDocumentEvent>(_onDelete);
  }

  Future<void> _onLoad(LoadDocumentsEvent event, Emitter<DocumentVaultState> emit) async {
    emit(state.copyWith(status: DocumentVaultStatus.loading));
    try {
      final list = await DocumentVaultService.instance.fetchDocuments();
      emit(state.copyWith(status: DocumentVaultStatus.loaded, documents: list));
    } catch (e) {
      emit(state.copyWith(status: DocumentVaultStatus.error, errorMessage: e.toString()));
    }
  }

  Future<void> _onUpload(UploadDocumentEvent event, Emitter<DocumentVaultState> emit) async {
    try {
      await DocumentVaultService.instance.uploadDocument(
        title: event.title,
        file: event.file,
        category: event.category,
        clientId: event.clientId,
        projectId: event.projectId,
        version: event.version,
        description: event.description,
      );
      add(LoadDocumentsEvent());
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  Future<void> _onDelete(DeleteDocumentEvent event, Emitter<DocumentVaultState> emit) async {
    try {
      await DocumentVaultService.instance.deleteDocument(event.id);
      add(LoadDocumentsEvent());
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }
}
