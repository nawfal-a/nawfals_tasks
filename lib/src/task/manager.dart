import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'operation.dart';

part 'task.dart';
part 'config.dart';
part 'descriptor.dart';
part '../widgets/handler.dart';

class TaskManager with ChangeNotifier {
  /// Waiting duration for the task to stay active after completion before stopping.
  final Duration afterCompletionDelay;

  /// Delay to debounce tasks callback.
  final Duration? debounceDelay;

  /// Waiting duration for the task to before retry.
  final Duration autoRetryDelay;

  /// Defines the [Task] auto retries count.
  ///
  /// -1 for infinity, caution that infinity auto retries may lead to performance issues.
  final int maxAutoRetries;

  /// Maximum number of tasks that can run in parallel.
  ///
  /// -1 for unlimited, caution that unlimited parallel tasks may lead to performance issues.
  final int maxParallel;

  /// Creates task manager to handle background tasks.
  TaskManager({
    this.afterCompletionDelay = const Duration(seconds: 2),
    this.debounceDelay = const Duration(milliseconds: 500),
    this.autoRetryDelay = const Duration(seconds: 5),
    this.maxAutoRetries = 5,
    this.maxParallel = 5,
  }) {
    assert(maxParallel != 0);
  }

  /// Find [TaskManager] instance within the [BuildContext]
  static TaskManager of(BuildContext context) {
    final provider = context.findAncestorWidgetOfExactType<_TaskHandler>();
    if (provider == null) {
      throw FlutterError(
        'TaskManager.of() called with a context that does not contain '
        'a TaskManager.\n'
        'No TaskHandler ancestor could be found starting from the '
        'context that was passed to TaskManager.of().\n\n'
        'This usually happens when:\n'
        '- You forget to wrap your app with TaskHandler.\n'
        '- You use a BuildContext that is above TaskHandler.\n\n'
        'Make sure TaskHandler is an ancestor of this widget.',
      );
    }
    return provider.manager;
  }

  /// Get all tasks except hidden.
  List<Task> get tasks => _tasks.where((e) => !e.config.hidden).toList();

  /// Get all current tasks.
  List<Task> get currentTasks => tasks.where((e) => !e.state.stopped).toList();

  /// Get all tasks that are in the active state.
  List<Task> get activeTasks => tasks.where((e) => e.state.active).toList();

  /// Add and execute a [Task]
  ///
  /// The [Task] will wait if [maxParallel] is exceeded
  void addTask(Task task) {
    _addTask(task, false, null);
  }

  /// Retry a [Task]
  ///
  /// The [Task] will wait if [maxParallel] is exceeded
  void retryTask(Task task) {
    _addTask(task, true, null);
  }

  /// Cancel a [Task]
  void cancelTask(Task task) {
    _runningTasks.remove(task._id);
    task._setCanceled();
    if (!task.config.hidden) {
      notifyListeners();
    }
  }

  /// Cancel a list of [Task]
  void cancelTasks(List<Task> tasks) {
    for (Task task in tasks) {
      _runningTasks.remove(task._id);
      task._setCanceled();
    }
    notifyListeners();
  }

  @override
  void dispose() async {
    for (Task task in _tasks) {
      task._setCanceled();
    }
    _tasks.clear();
    _listeners.clear();
    _queue.clear();
    _runningTasks.clear();
    super.dispose();
  }

  /// Set on task complete listener per [BuildContext]
  void setOnTaskCompleteListener(
    BuildContext context,
    void Function(Task task) callback,
  ) {
    _listeners[context.hashCode] = callback;
  }

  /// Remove on complete listener for the [BuildContext]
  void removeOnCompleteListener(BuildContext context) {
    _listeners.remove(context.hashCode);
  }

  final List<Task> _tasks = [];
  final Set<String> _runningTasks = {};

  final Queue<Task> _queue = Queue<Task>();

  final Map<int, void Function(Task task)> _listeners = {};

  void _addTask(Task task, bool retry, int? retries) async {
    if (retry) {
      task = task._copyWith(retries);
    }

    for (Task oldTask in _tasks) {
      if (task._shouldCancel(oldTask)) {
        _runningTasks.remove(oldTask._id);
        oldTask._setCanceled();
      }
    }

    _tasks.removeWhere((e) => e.state.stopped);

    _tasks.add(task);

    if (!task.config.hidden) {
      notifyListeners();
    }

    _queue.add(task);

    _tryStartNextTask();
  }

  void _tryStartNextTask() async {
    if (_runningTasks.length >= maxParallel) {
      return;
    }

    if (_queue.isEmpty) {
      return;
    }

    Task task = _queue.removeFirst();
    _runningTasks.add(task._id);
    await _runTask(task);
    _runningTasks.remove(task._id);
    if (task.state.success) {
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        task._cleanUp();
      });
    }
    _tryStartNextTask();

    await Future.delayed(
      task.config.afterCompletionDelay ?? afterCompletionDelay,
    );

    if (task.state.canceled) {
      return;
    }
    task._setStopped();
    if (!task.config.hidden) {
      notifyListeners();
    }
  }

  Future<void> _runTask(Task task) async {
    if (task.state.canceled) {
      return;
    }
    task._setStarted();
    if (!task.config.hidden) {
      notifyListeners();
    }

    if ((task.config.debounceDelay ?? debounceDelay) != null) {
      await Future.delayed((task.config.debounceDelay ?? debounceDelay)!);
      if (task.state.canceled) {
        return;
      }
    }

    Object? exception;
    try {
      await task._call(notifyListeners);
    } catch (e, s) {
      task._result = null;
      exception = e;

      if (kDebugMode) {
        print(e);
        print(s);
      }
    }

    if (task.state.canceled) {
      return;
    }

    if (task.config.retryConfig.auto && exception != null) {
      int max = (task.config.retryConfig.maxAutoRetries ?? maxAutoRetries);
      if (task.retries < max || max == -1) {
        task._setWaiting(exception);
        if (!task.config.hidden) {
          notifyListeners();
        }
        await Future.delayed(
          task.config.retryConfig.autoRetryDelay ?? autoRetryDelay,
        );
        if (task.state.canceled) {
          return;
        }

        _addTask(task, true, task.retries + 1);
        return;
      }
    }

    task._setCompleted(exception);
    if (!task.config.hidden) {
      notifyListeners();

      task._callListeners();

      for (var callback in List<void Function(Task)>.from(_listeners.values)) {
        callback(task);
      }
    }
  }
}
