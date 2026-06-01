import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../models/department_model.dart';
import '../../services/supabase_service.dart';

abstract class DepartmentEvent extends Equatable {
  const DepartmentEvent();
  @override
  List<Object?> get props => [];
}

class LoadDepartmentsEvent extends DepartmentEvent {}

class AddDepartmentEvent extends DepartmentEvent {
  final String name;
  final String description;
  const AddDepartmentEvent({required this.name, required this.description});
  @override
  List<Object?> get props => [name, description];
}

class UpdateDepartmentEvent extends DepartmentEvent {
  final Department department;
  const UpdateDepartmentEvent(this.department);
  @override
  List<Object?> get props => [department];
}

class DeleteDepartmentEvent extends DepartmentEvent {
  final String id;
  const DeleteDepartmentEvent(this.id);
  @override
  List<Object?> get props => [id];
}

class DepartmentState extends Equatable {
  final List<Department> departments;
  final bool isLoading;
  final String? error;

  const DepartmentState({
    this.departments = const [],
    this.isLoading = false,
    this.error,
  });

  @override
  List<Object?> get props => [departments, isLoading, error];

  DepartmentState copyWith({
    List<Department>? departments,
    bool? isLoading,
    String? error,
  }) {
    return DepartmentState(
      departments: departments ?? this.departments,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class DepartmentBloc extends Bloc<DepartmentEvent, DepartmentState> {
  final _client = SupabaseService.client;

  DepartmentBloc() : super(const DepartmentState()) {
    on<LoadDepartmentsEvent>((event, emit) async {
      emit(state.copyWith(isLoading: true));
      try {
        final res = await _client
            .from('departments')
            .select()
            .isFilter('deleted_at', null)
            .order('name');
        final list = (res as List).map((x) => Department.fromJson(x)).toList();
        emit(state.copyWith(departments: list, isLoading: false));
      } catch (e) {
        emit(state.copyWith(isLoading: false, error: e.toString()));
      }
    });

    on<AddDepartmentEvent>((event, emit) async {
      emit(state.copyWith(isLoading: true));
      try {
        final slug = event.name.toLowerCase().replaceAll(RegExp(r'\s+'), '_');
        await _client.from('departments').insert({
          'name': event.name,
          'description': event.description,
          'slug': slug,
          'status': 'active',
          'organization_id': '00000000-0000-0000-0000-000000000000',
        });
        add(LoadDepartmentsEvent());
      } catch (e) {
        emit(state.copyWith(isLoading: false, error: e.toString()));
      }
    });

    on<UpdateDepartmentEvent>((event, emit) async {
      emit(state.copyWith(isLoading: true));
      try {
        await _client.from('departments').update({
          'name': event.department.name,
          'description': event.department.description,
          'slug': event.department.slug,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        }).eq('id', event.department.id);
        add(LoadDepartmentsEvent());
      } catch (e) {
        emit(state.copyWith(isLoading: false, error: e.toString()));
      }
    });

    on<DeleteDepartmentEvent>((event, emit) async {
      emit(state.copyWith(isLoading: true));
      try {
        await _client.from('departments').update({
          'deleted_at': DateTime.now().toUtc().toIso8601String(),
        }).eq('id', event.id);
        add(LoadDepartmentsEvent());
      } catch (e) {
        emit(state.copyWith(isLoading: false, error: e.toString()));
      }
    });
  }
}
