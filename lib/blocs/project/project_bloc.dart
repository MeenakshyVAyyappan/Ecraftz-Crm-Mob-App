import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../models/project_model.dart';
import '../../services/supabase_service.dart';
import '../branch/branch_cubit.dart';

abstract class ProjectEvent extends Equatable {
  const ProjectEvent();
  @override
  List<Object?> get props => [];
}

class LoadProjectsEvent extends ProjectEvent {
  final BranchState? branchState;
  const LoadProjectsEvent({this.branchState});
  @override
  List<Object?> get props => [branchState];
}

class AddProjectEvent extends ProjectEvent {
  final Project project;
  const AddProjectEvent(this.project);
  @override
  List<Object?> get props => [project];
}

class AddProjectsBulkEvent extends ProjectEvent {
  final List<Project> projects;
  const AddProjectsBulkEvent(this.projects);
  @override
  List<Object?> get props => [projects];
}

class UpdateProjectEvent extends ProjectEvent {
  final Project project;
  const UpdateProjectEvent(this.project);
  @override
  List<Object?> get props => [project];
}

class DeleteProjectEvent extends ProjectEvent {
  final String id;
  const DeleteProjectEvent(this.id);
  @override
  List<Object?> get props => [id];
}

class ProjectState extends Equatable {
  final List<Project> projects;
  const ProjectState({this.projects = const []});

  @override
  List<Object?> get props => [projects];

  ProjectState copyWith({List<Project>? projects}) {
    return ProjectState(projects: projects ?? this.projects);
  }
}

class ProjectBloc extends Bloc<ProjectEvent, ProjectState> {
  final _client = SupabaseService.client;

  ProjectBloc() : super(const ProjectState()) {
    on<LoadProjectsEvent>((event, emit) async {
      try {
        var filterQuery = _client
            .from('projects')
            .select('*, clients(name)')
            .isFilter('deleted_at', null);

        final branchState = event.branchState;
        if (branchState != null &&
            branchState.selectedBranch != BranchFilter.allBranches) {
          final branchId = branchState.activeBranchId;
          if (branchId != null && branchId.isNotEmpty) {
            filterQuery = filterQuery.eq('branch_id', branchId);
          }
        }

        final projectsRes = await filterQuery.order('created_at', ascending: false);
            
        final tasksRes = await _client
            .from('tasks')
            .select('id, project_id, status')
            .isFilter('deleted_at', null);

        final projectsList = (projectsRes as List).map((pJson) {
          final project = Project.fromJson(pJson);
          final pTasks = (tasksRes as List).where((t) => t['project_id'] == project.id).toList();
          final completed = pTasks.where((t) => t['status']?.toString().toLowerCase() == 'done').length;
          final total = pTasks.length;
          final progress = total > 0 ? (completed / total) : 0.0;
          
          return Project(
            id: project.id,
            name: project.name,
            clientName: project.clientName,
            status: project.status,
            deadline: project.deadline,
            totalTasks: total,
            completedTasks: completed,
            progress: progress,
            teamLead: project.teamLead,
            isArchived: project.isArchived,
          );
        }).toList();

        emit(ProjectState(projects: projectsList));
      } catch (e) {
        emit(state.copyWith());
      }
    });

    on<AddProjectEvent>((event, emit) async {
      try {
        String? clientId;
        if (event.project.clientName.isNotEmpty) {
          final clientsRes = await _client
              .from('clients')
              .select('id')
              .eq('name', event.project.clientName)
              .isFilter('deleted_at', null)
              .limit(1);
          if ((clientsRes as List).isNotEmpty) {
            clientId = clientsRes.first['id']?.toString();
          }
        }
        
        final Map<String, dynamic> data = event.project.toJson();
        data.remove('id');
        data['client_id'] = clientId;
        data['start_date'] = DateTime.now().toIso8601String().split('T')[0];
        
        await _client.from('projects').insert(data);
        add(LoadProjectsEvent());
      } catch (e) {
        // handle error
      }
    });

    on<AddProjectsBulkEvent>((event, emit) async {
      try {
        final clientsRes = await _client
            .from('clients')
            .select('id, name')
            .isFilter('deleted_at', null);
        final clients = clientsRes as List;
        
        final List<Map<String, dynamic>> dataList = [];
        for (final p in event.projects) {
          final clientRow = clients.firstWhere(
            (c) => c['name']?.toString().toLowerCase() == p.clientName.toLowerCase(),
            orElse: () => null,
          );
          final clientId = clientRow != null ? clientRow['id']?.toString() : null;
          
          final data = p.toJson();
          data.remove('id');
          data['client_id'] = clientId;
          data['start_date'] = DateTime.now().toIso8601String().split('T')[0];
          dataList.add(data);
        }
        
        await _client.from('projects').insert(dataList);
        add(LoadProjectsEvent());
      } catch (e) {
        // handle error
      }
    });

    on<UpdateProjectEvent>((event, emit) async {
      try {
        String? clientId;
        if (event.project.clientName.isNotEmpty) {
          final clientsRes = await _client
              .from('clients')
              .select('id')
              .eq('name', event.project.clientName)
              .isFilter('deleted_at', null)
              .limit(1);
          if ((clientsRes as List).isNotEmpty) {
            clientId = clientsRes.first['id']?.toString();
          }
        }

        final Map<String, dynamic> data = event.project.toJson();
        data['client_id'] = clientId;
        
        await _client
            .from('projects')
            .update(data)
            .eq('id', event.project.id);
        add(LoadProjectsEvent());
      } catch (e) {
        // handle error
      }
    });

    on<DeleteProjectEvent>((event, emit) async {
      try {
        await _client.from('projects').update({
          'deleted_at': DateTime.now().toUtc().toIso8601String(),
        }).eq('id', event.id);
        add(LoadProjectsEvent());
      } catch (e) {
        // handle error
      }
    });
  }
}
