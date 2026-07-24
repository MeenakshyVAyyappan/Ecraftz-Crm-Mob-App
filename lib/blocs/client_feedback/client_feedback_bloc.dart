import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/client_feedback_model.dart';
import '../../services/client_feedback_service.dart';

abstract class ClientFeedbackEvent {}

class LoadClientFeedbackEvent extends ClientFeedbackEvent {}

class AddClientFeedbackEvent extends ClientFeedbackEvent {
  final String clientId;
  final String? projectId;
  final double rating;
  final Map<String, double>? categoryRatings;
  final String feedbackType;
  final String comments;
  final String status;
  final String? actionNotes;
  final File? audioFile;

  AddClientFeedbackEvent({
    required this.clientId,
    this.projectId,
    required this.rating,
    this.categoryRatings,
    required this.feedbackType,
    required this.comments,
    this.status = 'pending',
    this.actionNotes,
    this.audioFile,
  });
}

class UpdateClientFeedbackEvent extends ClientFeedbackEvent {
  final String id;
  final String? clientId;
  final double? rating;
  final Map<String, double>? categoryRatings;
  final String? feedbackType;
  final String? comments;
  final String? status;
  final String? actionNotes;
  final String? internalResponse;
  final String? clientResponse;
  final String? assignedEmployeeId;
  final DateTime? followUpDate;
  final File? audioFile;

  UpdateClientFeedbackEvent({
    required this.id,
    this.clientId,
    this.rating,
    this.categoryRatings,
    this.feedbackType,
    this.comments,
    this.status,
    this.actionNotes,
    this.internalResponse,
    this.clientResponse,
    this.assignedEmployeeId,
    this.followUpDate,
    this.audioFile,
  });
}

class DeleteClientFeedbackEvent extends ClientFeedbackEvent {
  final String id;
  DeleteClientFeedbackEvent(this.id);
}

// Category Management Events
class AddCategoryEvent extends ClientFeedbackEvent {
  final String name;
  AddCategoryEvent(this.name);
}

class UpdateCategoryEvent extends ClientFeedbackEvent {
  final String id;
  final String? name;
  final bool? isEnabled;
  UpdateCategoryEvent(this.id, {this.name, this.isEnabled});
}

class DeleteCategoryEvent extends ClientFeedbackEvent {
  final String id;
  DeleteCategoryEvent(this.id);
}

// Share Link Event
class GenerateSharedLinkEvent extends ClientFeedbackEvent {
  final String clientId;
  final String? projectId;
  GenerateSharedLinkEvent({required this.clientId, this.projectId});
}

// Clears the previously generated link when the bottom sheet is reopened
class ClearGeneratedLinkEvent extends ClientFeedbackEvent {}

enum ClientFeedbackStatus { initial, loading, loaded, error }

class ClientFeedbackState {
  final ClientFeedbackStatus status;
  final List<ClientFeedback> feedbacks;
  final List<FeedbackCategory> categories;
  final FeedbackDashboardMetrics metrics;
  final String? generatedShareLink;
  final String? errorMessage;

  ClientFeedbackState({
    this.status = ClientFeedbackStatus.initial,
    this.feedbacks = const [],
    this.categories = const [],
    FeedbackDashboardMetrics? metrics,
    this.generatedShareLink,
    this.errorMessage,
  }) : metrics = metrics ?? FeedbackDashboardMetrics.fromFeedbackList(const []);

  ClientFeedbackState copyWith({
    ClientFeedbackStatus? status,
    List<ClientFeedback>? feedbacks,
    List<FeedbackCategory>? categories,
    FeedbackDashboardMetrics? metrics,
    Object? generatedShareLink = _sentinel,
    String? errorMessage,
  }) {
    return ClientFeedbackState(
      status: status ?? this.status,
      feedbacks: feedbacks ?? this.feedbacks,
      categories: categories ?? this.categories,
      metrics: metrics ?? this.metrics,
      generatedShareLink: generatedShareLink == _sentinel
          ? this.generatedShareLink
          : generatedShareLink as String?,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

// Sentinel used to distinguish "not provided" from explicit null in copyWith
const Object _sentinel = Object();

class ClientFeedbackBloc extends Bloc<ClientFeedbackEvent, ClientFeedbackState> {
  ClientFeedbackBloc() : super(ClientFeedbackState()) {
    on<LoadClientFeedbackEvent>(_onLoad);
    on<AddClientFeedbackEvent>(_onAdd);
    on<UpdateClientFeedbackEvent>(_onUpdate);
    on<DeleteClientFeedbackEvent>(_onDelete);
    on<AddCategoryEvent>(_onAddCategory);
    on<UpdateCategoryEvent>(_onUpdateCategory);
    on<DeleteCategoryEvent>(_onDeleteCategory);
    on<GenerateSharedLinkEvent>(_onGenerateShareLink);
    on<ClearGeneratedLinkEvent>(_onClearGeneratedLink);
  }

  Future<void> _onLoad(LoadClientFeedbackEvent event, Emitter<ClientFeedbackState> emit) async {
    emit(state.copyWith(status: ClientFeedbackStatus.loading));
    try {
      final list = await ClientFeedbackService.instance.fetchAllFeedback();
      final cats = await ClientFeedbackService.instance.fetchCategories();
      final metrics = FeedbackDashboardMetrics.fromFeedbackList(list);

      emit(state.copyWith(
        status: ClientFeedbackStatus.loaded,
        feedbacks: list,
        categories: cats,
        metrics: metrics,
      ));
    } catch (e) {
      emit(state.copyWith(status: ClientFeedbackStatus.error, errorMessage: e.toString()));
    }
  }

  Future<void> _onAdd(AddClientFeedbackEvent event, Emitter<ClientFeedbackState> emit) async {
    try {
      await ClientFeedbackService.instance.addFeedback(
        clientId: event.clientId,
        projectId: event.projectId,
        rating: event.rating,
        categoryRatings: event.categoryRatings,
        feedbackType: event.feedbackType,
        comments: event.comments,
        status: event.status,
        actionNotes: event.actionNotes,
        audioFile: event.audioFile,
      );
      add(LoadClientFeedbackEvent());
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  Future<void> _onUpdate(UpdateClientFeedbackEvent event, Emitter<ClientFeedbackState> emit) async {
    try {
      await ClientFeedbackService.instance.updateFeedback(
        id: event.id,
        clientId: event.clientId,
        rating: event.rating,
        categoryRatings: event.categoryRatings,
        feedbackType: event.feedbackType,
        comments: event.comments,
        status: event.status,
        actionNotes: event.actionNotes,
        internalResponse: event.internalResponse,
        clientResponse: event.clientResponse,
        assignedEmployeeId: event.assignedEmployeeId,
        followUpDate: event.followUpDate,
        audioFile: event.audioFile,
      );
      add(LoadClientFeedbackEvent());
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  Future<void> _onDelete(DeleteClientFeedbackEvent event, Emitter<ClientFeedbackState> emit) async {
    try {
      await ClientFeedbackService.instance.deleteFeedback(event.id);
      add(LoadClientFeedbackEvent());
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  Future<void> _onAddCategory(AddCategoryEvent event, Emitter<ClientFeedbackState> emit) async {
    try {
      await ClientFeedbackService.instance.createCategory(event.name);
      add(LoadClientFeedbackEvent());
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  Future<void> _onUpdateCategory(UpdateCategoryEvent event, Emitter<ClientFeedbackState> emit) async {
    try {
      await ClientFeedbackService.instance.updateCategory(
        event.id,
        name: event.name,
        isEnabled: event.isEnabled,
      );
      add(LoadClientFeedbackEvent());
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  Future<void> _onDeleteCategory(DeleteCategoryEvent event, Emitter<ClientFeedbackState> emit) async {
    try {
      await ClientFeedbackService.instance.deleteCategory(event.id);
      add(LoadClientFeedbackEvent());
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  void _onGenerateShareLink(GenerateSharedLinkEvent event, Emitter<ClientFeedbackState> emit) {
    final link = ClientFeedbackService.instance.generateSharedFeedbackLink(
      clientId: event.clientId,
      projectId: event.projectId,
    );
    emit(state.copyWith(generatedShareLink: link));
  }

  void _onClearGeneratedLink(ClearGeneratedLinkEvent event, Emitter<ClientFeedbackState> emit) {
    // Explicitly clear the link so the sheet always starts fresh
    emit(state.copyWith(generatedShareLink: null));
  }
}
