import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../models/task_model.dart';
import '../../services/supabase_service.dart';

abstract class TaskEvent extends Equatable {
  const TaskEvent();
  @override
  List<Object?> get props => [];
}

class LoadTasksEvent extends TaskEvent {}

class AddTaskEvent extends TaskEvent {
  final TaskItem task;
  const AddTaskEvent(this.task);
  @override
  List<Object?> get props => [task];
}

class UpdateTaskEvent extends TaskEvent {
  final TaskItem task;
  const UpdateTaskEvent(this.task);
  @override
  List<Object?> get props => [task];
}

class UpdateTaskStatusEvent extends TaskEvent {
  final String id;
  final TaskStatus status;
  const UpdateTaskStatusEvent(this.id, this.status);
  @override
  List<Object?> get props => [id, status];
}

class ReallocateTaskEvent extends TaskEvent {
  final String taskId;
  final String? newOwner;
  const ReallocateTaskEvent(this.taskId, this.newOwner);
  @override
  List<Object?> get props => [taskId, newOwner];
}

class DeleteTaskEvent extends TaskEvent {
  final String id;
  const DeleteTaskEvent(this.id);
  @override
  List<Object?> get props => [id];
}

class TaskState extends Equatable {
  final List<TaskItem> tasks;
  final List<TeamMember> members;

  const TaskState({this.tasks = const [], this.members = const []});

  @override
  List<Object?> get props => [tasks, members];

  TaskState copyWith({List<TaskItem>? tasks, List<TeamMember>? members}) {
    return TaskState(
      tasks: tasks ?? this.tasks,
      members: members ?? this.members,
    );
  }
}

class TaskBloc extends Bloc<TaskEvent, TaskState> {
  final _client = SupabaseService.client;

  TaskBloc() : super(const TaskState()) {
    on<LoadTasksEvent>((event, emit) async {
      try {
        final res = await _client
            .from('tasks')
            .select()
            .order('created_at', ascending: false);
        final list = (res as List).map((x) => TaskItem.fromJson(x)).toList();
        emit(TaskState(
          tasks: list,
          members: _recomputeMembers(list),
        ));
      } catch (e, stackTrace) {
        print('Error loading tasks: $e\n$stackTrace');
        emit(state.copyWith());
      }
    });

    on<AddTaskEvent>((event, emit) async {
      try {
        String? projectId;
        if (event.task.parentProject != null && event.task.parentProject!.isNotEmpty) {
          final parts = event.task.parentProject!.split(' - ');
          final pName = parts.last.trim();
          final projectsRes = await _client
              .from('projects')
              .select('id')
              .eq('name', pName)
              .isFilter('deleted_at', null)
              .limit(1);
          if ((projectsRes as List).isNotEmpty) {
            projectId = projectsRes.first['id']?.toString();
          } else {
            projectId = event.task.parentProject;
          }
        }

        final Map<String, dynamic> data = event.task.toJson();
        data.remove('id');
        data['project_id'] = projectId;
        data['created_at'] = DateTime.now().toUtc().toIso8601String();
        
        await _client.from('tasks').insert(data);
        add(LoadTasksEvent());
      } catch (e) {
        // handle error
      }
    });

    on<UpdateTaskEvent>((event, emit) async {
      try {
        String? projectId;
        if (event.task.parentProject != null && event.task.parentProject!.isNotEmpty) {
          final parts = event.task.parentProject!.split(' - ');
          final pName = parts.last.trim();
          final projectsRes = await _client
              .from('projects')
              .select('id')
              .eq('name', pName)
              .isFilter('deleted_at', null)
              .limit(1);
          if ((projectsRes as List).isNotEmpty) {
            projectId = projectsRes.first['id']?.toString();
          } else {
            projectId = event.task.parentProject;
          }
        }

        final Map<String, dynamic> data = event.task.toJson();
        data['project_id'] = projectId;
        
        await _client
            .from('tasks')
            .update(data)
            .eq('id', event.task.id);
        add(LoadTasksEvent());
      } catch (e) {
        // handle error
      }
    });

    on<UpdateTaskStatusEvent>((event, emit) async {
      try {
        await _client.from('tasks').update({
          'status': _taskStatusToString(event.status),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        }).eq('id', event.id);
        add(LoadTasksEvent());
      } catch (e) {
        // handle error
      }
    });

    on<ReallocateTaskEvent>((event, emit) async {
      try {
        final taskRes = await _client.from('tasks').select().eq('id', event.taskId).limit(1);
        if ((taskRes as List).isNotEmpty) {
          final taskData = taskRes.first;
          String desc = taskData['description']?.toString() ?? '';
          
          final fallbackRegex = RegExp(r'\[METADATA_FALLBACK:\s*(\{.*\})\]');
          desc = desc.replaceAll(fallbackRegex, '').trim();
          
          if (event.newOwner != null && event.newOwner!.isNotEmpty) {
            desc += '\n\n[METADATA_FALLBACK: {"owner": "${event.newOwner}"}]';
          }
          
          await _client.from('tasks').update({
            'description': desc,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          }).eq('id', event.taskId);
        }
        add(LoadTasksEvent());
      } catch (e) {
        // handle error
      }
    });

    on<DeleteTaskEvent>((event, emit) async {
      try {
        await _client.from('tasks').update({
          'deleted_at': DateTime.now().toUtc().toIso8601String(),
        }).eq('id', event.id);
        add(LoadTasksEvent());
      } catch (e) {
        // handle error
      }
    });
  }

  static List<TeamMember> _recomputeMembers(List<TaskItem> tasks) {
    return [
      TeamMember(
        id: '1',
        name: 'Chimbu',
        role: 'TEAM LEAD',
        department: 'WEB DEVELOPING',
        weeklyLoad: 0,
        weeklyLimit: 40,
        tasks: tasks.where((t) => t.owner == 'Chimbu').toList(),
      ),
      TeamMember(
        id: '2',
        name: 'Tony Stark',
        role: 'SALES',
        department: 'BDE',
        weeklyLoad: 0,
        weeklyLimit: 40,
        tasks: tasks.where((t) => t.owner == 'Tony Stark').toList(),
      ),
    ];
  }
}

String _taskStatusToString(TaskStatus s) {
  switch (s) {
    case TaskStatus.toDo: return 'todo';
    case TaskStatus.inProgress: return 'in_progress';
    case TaskStatus.review: return 'review';
    case TaskStatus.done: return 'done';
  }
}
