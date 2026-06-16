import 'package:flutter/widgets.dart';

import '../task/manager.dart';
import '../task/operation.dart';

class TaskListener<K, V> {
  /// Creates [TaskListener] that listens to the [Task] that satisfies the parameters, unless it is hidden.
  ///
  /// If [cancelTasksOnDispose] is null, default value will be used.
  static Widget parameters<K, V>(
    BuildContext context, {
    required TaskListenerParameters parameters,
    bool enabled = true,
    bool? cancelTasksOnDispose,
    required Widget Function(Task<K, V>? task) builder,
  }) {
    return _TaskListener<K, V>(
      enabled: enabled,
      cancelTasksOnDispose:
          cancelTasksOnDispose ??
          _TaskListener._getDefaultCancelTasksOnDispose(parameters.operation),
      filter: (taskManager) {
        return List<Task<K, V>>.from(
          taskManager.currentTasks.where((e) => parameters._complied(e)),
        );
      },
      builder: (tasks) {
        return builder(tasks.firstOrNull);
      },
    );
  }

  /// Creates [TaskListener] that listens to the all the tasks that satisfies any of the parameters.
  /// Hidden tasks will be ignored.
  static Widget multiParameters<K, V>(
    BuildContext context, {
    required List<TaskListenerParameters> parameters,
    bool enabled = true,
    required bool cancelTasksOnDispose,
    required Widget Function(List<Task<K, V>> tasks) builder,
  }) {
    return _TaskListener<K, V>(
      enabled: enabled,
      cancelTasksOnDispose: cancelTasksOnDispose,
      filter: (taskManager) {
        return List<Task<K, V>>.from(
          taskManager.currentTasks.where(
            (e) => parameters.any((p) => p._complied(e)),
          ),
        );
      },
      builder: builder,
    );
  }

  /// Creates [TaskListener] that listens to all current tasks except hidden and private ones.
  static Widget current(
    BuildContext context, {
    bool enabled = true,
    bool hidePrivate = true,
    required Widget Function(List<Task> tasks) builder,
  }) {
    return _TaskListener(
      enabled: enabled,
      cancelTasksOnDispose: false,
      filter: (taskManager) {
        return taskManager.currentTasks
            .where((e) => !e.config.private || !hidePrivate)
            .toList();
      },
      builder: builder,
    );
  }

  /// Creates [TaskListener] that listens to all active tasks except hidden and private ones.
  static Widget active(
    BuildContext context, {
    bool enabled = true,
    bool hidePrivate = true,
    required Widget Function(List<Task> tasks) builder,
  }) {
    return _TaskListener(
      enabled: enabled,
      cancelTasksOnDispose: false,
      filter: (taskManager) {
        return taskManager.activeTasks
            .where((e) => !e.config.private || !hidePrivate)
            .toList();
      },
      builder: builder,
    );
  }
}

class TaskListenerParameters {
  /// [Task] operation to listen to.
  final TaskOperation operation;

  /// [Task] data type to listen to.
  final Type dataType;

  /// [Task] data unique identifiers to listen to.
  /// If null, it will be ignored.
  final ListenerValuesConfig? dataUniqueIdentifiersConfig;

  /// [Task] targets to listen to.
  /// If null, will listen to all targets.
  final ListenerValuesConfig? targetsConfig;

  /// [Task] tags to listen to.
  /// If null, will listen to all tags.
  final ListenerValuesConfig? tagsConfig;

  TaskListenerParameters({
    required this.operation,
    required this.dataType,
    required this.dataUniqueIdentifiersConfig,
    this.targetsConfig,
    this.tagsConfig,
  });

  bool _complied(Task task) {
    if (operation != task.descriptor.operation) {
      return false;
    }

    if (dataType != task.descriptor.dataType) {
      return false;
    }

    if (dataUniqueIdentifiersConfig != null) {
      if (task.descriptor.dataUniqueIdentifiers != null &&
          !dataUniqueIdentifiersConfig!.allow(
            task.descriptor.dataUniqueIdentifiers!,
          )) {
        return false;
      }
    }

    if (targetsConfig != null) {
      if (!targetsConfig!.allow(task.descriptor.targets)) {
        return false;
      }
    }

    if (tagsConfig != null) {
      if (!tagsConfig!.allow(task.tags)) {
        return false;
      }
    }
    return true;
  }
}

class ListenerValuesConfig {
  /// Values must include all [requiredAll] or more
  /// to match this parameters.
  final List<String> requiredAll;

  /// Values include at least one of [requiredAny]
  /// or more to match this parameters.
  final List<String> requiredAny;

  /// Value must be present in [allowed] and no more
  /// to match this parameters.
  /// If null, all values will be allowed.
  final List<String>? allowed;

  ListenerValuesConfig({
    required this.requiredAll,
    required this.requiredAny,
    required this.allowed,
  });

  bool allow(List<String> attributes) {
    if (!attributes.toSet().containsAll(requiredAll)) {
      return false;
    }

    if (requiredAny.isNotEmpty) {
      if (!attributes.any((e) => requiredAny.contains(e))) {
        return false;
      }
    }

    if (allowed != null) {
      if (!allowed!.toSet().containsAll(attributes)) {
        return false;
      }
    }
    return true;
  }
}

class _TaskListener<K, V> extends StatefulWidget {
  final bool enabled;
  final List<Task<K, V>> Function(TaskManager taskManager) filter;
  final bool cancelTasksOnDispose;
  final Widget Function(List<Task<K, V>> tasks) builder;
  const _TaskListener({
    required this.enabled,
    required this.filter,
    required this.builder,
    required this.cancelTasksOnDispose,
  });

  @override
  State<_TaskListener<K, V>> createState() => __TaskListenerState<K, V>();

  /// Get the default [cancelTasksOnDispose] for each operation
  static bool _getDefaultCancelTasksOnDispose(TaskOperation operation) {
    return !operation.mutating;
  }
}

class __TaskListenerState<K, V> extends State<_TaskListener<K, V>> {
  late TaskManager taskManager;

  List<Task<K, V>> _tasks = [];

  late VoidCallback _listener;

  void enable() {
    taskManager.addListener(_listener);
  }

  void disable() {
    taskManager.removeListener(_listener);
  }

  @override
  void initState() {
    taskManager = TaskManager.of(context);
    _listener = () {
      int length = _tasks.length;
      _tasks = widget.filter(taskManager);
      if (_tasks.isNotEmpty || length > _tasks.length) {
        if (mounted) {
          setState(() {});
        }
      }
    };
    if (widget.enabled) {
      enable();
    }

    super.initState();
  }

  @override
  void didUpdateWidget(covariant _TaskListener<K, V> oldWidget) {
    if (widget.enabled) {
      enable();
    } else {
      disable();
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(_tasks);
  }

  @override
  void dispose() {
    if (widget.cancelTasksOnDispose) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        List<Task> tasks = widget.filter(taskManager);

        taskManager.cancelTasks(tasks);
      });
    }
    disable();
    super.dispose();
  }
}
