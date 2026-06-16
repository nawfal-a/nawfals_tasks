part of 'manager.dart';

class Task<K, V> {
  /// Task descriptor.
  final TaskDescriptor descriptor;

  /// Task configration.
  final TaskConfig config;

  /// Task initial message.
  late String initialMessage;

  /// Task initial sub-message.
  String? initialSubMessage;

  /// Task auxiliary  message.
  final String? auxiliaryMessage;

  /// Task data payloads list.
  ///
  /// Can be used to deliver data with the task.
  List<K>? data;

  /// [Task] tags for listeners.
  ///
  /// Can help in managing listeners for multiple scenarios.
  final List<String> tags;

  /// [Task] modifiers.
  ///
  /// This value does not affect [Task] canceling or listening.
  /// Used to modify task signature that can help
  /// to manage different tasks that has matching descriptors.
  final List<String>? modifiers;

  /// Extra object to deliver with the task.
  final dynamic extra;

  /// Task main callback.
  ///
  /// This function is called when the task is running.
  ///
  /// [task]
  /// Current task.
  ///
  /// [setProgress]
  /// Used to set task progress within the callback.
  ///
  /// [setMessage]
  /// Used to set task messages within the callback.
  final Future<V> Function(
    Task<K, V> task,
    void Function(double progress) setProgress,
    void Function(String message, String? subMessage) setMessage,
  )
  callback;

  /// Creates background task that can be listened to its state changes using [TaskListener].
  ///
  /// K is the type of the data.
  /// V is the return type of the task.
  Task({
    required this.descriptor,
    required this.config,
    required this.initialMessage,
    this.initialSubMessage,
    this.auxiliaryMessage,
    required this.data,
    this.tags = const [],
    this.modifiers,
    this.extra,
    required this.callback,
  }) {
    _tagsHashCode = Object.hashAll(List<String>.from(tags)..sort());

    _id =
        "${descriptor.hashCode}-$_tagsHashCode-${DateTime.now().microsecondsSinceEpoch}";

    _signature = "${descriptor.hashCode}";

    if (modifiers != null) {
      _signature = "$_signature-${modifiers!}";
    }
    _message = initialMessage;
    _subMessage = initialSubMessage;
  }

  @override
  String toString() {
    return "[$runtimeType ${_toMap().toString()}]";
  }

  /// Set on complete listener per [BuildContext]
  void setOnCompleteListener(
    BuildContext context,
    void Function(Task<K, V> task) callback,
  ) {
    _listeners[context.hashCode] = callback;
  }

  /// Remove on complete listener for the [BuildContext]
  void removeOnCompleteListener(BuildContext context) {
    _listeners.remove(context.hashCode);
  }

  /// Get task id.
  String get id => _id;

  /// Get task signature.
  String get signature => _signature;

  /// Get task callback result.
  V? get result => _result;

  /// Get task callback progress.
  double? get progress => _progress;

  /// Get task callback exception, if occured.
  Object? get exception => _exception;

  /// Get task current message.
  String get message => _message;

  /// Get task current sub-message.
  String? get subMessage => _subMessage;

  /// Get task auto retries.
  int get retries => _retries;

  /// Get task state.
  TaskState get state => TaskState(
    pending: _pending && !_active,
    active: _active,
    interactive:
        _pending ||
        _running ||
        (exception != null && config.retryConfig.manual),
    running: _running,
    success: !_running && !_pending && exception == null && !_canceled,
    failed: !_running && !_pending && exception != null,
    completed: !_running && !_pending && !_waiting,
    canceled: _canceled,
    waiting: _waiting,
    stopped:
        !_pending &&
        !_active &&
        (exception == null || !(config.retryConfig.manual)),
  );

  @override
  int get hashCode {
    return _id.hashCode;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is Task<K, V> &&
        other.runtimeType != runtimeType &&
        hashCode == other.hashCode;
  }

  late final String _id;

  late final String _signature;

  late int _tagsHashCode;

  V? _result;
  double? _progress;

  Object? _exception;

  late String _message;
  late String? _subMessage;

  int _retries = 0;

  bool _pending = true;
  bool _active = false;
  bool _running = false;
  bool _canceled = false;
  bool _waiting = false;

  Map<int, void Function(Task<K, V> task)> _listeners = {};

  void _setStarted() {
    _active = true;
    _running = true;
    _pending = false;
    _exception = null;
  }

  void _setCompleted(Object? exception) {
    _running = false;
    _exception = exception;
  }

  void _setStopped() {
    _running = false;
    _active = false;
  }

  void _setCanceled() {
    _canceled = true;
    _pending = false;
    _running = false;
    _active = false;
    _exception = null;
    _result = null;
    _cleanUp();
  }

  void _setRetry(int retries) {
    _waiting = false;
    _retries = retries;
  }

  void _setWaiting(Object? exception) {
    _waiting = true;
    _running = false;
    _exception = exception;
  }

  bool _shouldCancel(Task other) {
    if (_id == other._id) {
      return false;
    }
    if (descriptor._sameData(other.descriptor) &&
        other.descriptor.cancelingOperations.contains(descriptor.operation) &&
        (other.descriptor.cancelingOperationsIgnoresTargets ||
            descriptor.targets.toSet().containsAll(other.descriptor.targets))) {
      return true;
    }
    if (descriptor._shouldCancel(other.descriptor)) {
      return true;
    }
    return false;
  }

  void _callListeners() {
    for (var callback in List<void Function(Task<K, V>)>.from(
      _listeners.values,
    )) {
      callback(this);
    }
  }

  void _cleanUp() {
    _listeners.clear();
    data = null;
    _result = null;
  }

  Future<void> _call(VoidCallback notifyListeners) async {
    _result = await callback(
      this,
      (progress) {
        _progress = progress;
        if (!config.hidden) {
          notifyListeners();
        }
      },
      (message, subMessage) {
        _message = message;
        _subMessage = subMessage;
        if (!config.hidden) {
          notifyListeners();
        }
      },
    );
  }

  Task<K, V> _copyWith(int? retries) {
    Task<K, V> newTask = Task<K, V>(
      descriptor: descriptor,
      config: config,
      initialMessage: initialMessage,
      initialSubMessage: initialSubMessage,
      auxiliaryMessage: auxiliaryMessage,
      data: data,
      modifiers: modifiers,
      tags: tags,
      callback: callback,
    );
    newTask._listeners = Map.from(_listeners);
    if (retries != null) {
      newTask._setRetry(retries);
    }
    return newTask;
  }

  Map _toMap() {
    return {
      "id": _id,
      "descriptor": descriptor._toMap(),
      "config": config._toMap(),
      "tags": tags,
      "modifiers": modifiers,
      "state": state._toMap(),
    };
  }
}

/// Describes task state
class TaskState {
  /// Task is still pending.
  final bool pending;

  /// Task is in active state.
  final bool active;

  /// Task is in the interactive state.
  ///
  /// Interactive state means either the [Task] is pending, running or it is completed with exception and the [TaskRetryConfig] manual value is set to false
  final bool interactive;

  /// Task is in running.
  final bool running;

  /// Task has been succeded.
  final bool success;

  /// Task has been failed.
  final bool failed;

  /// Task has been completed regardless if succeded or failed.
  final bool completed;

  /// Task has been canceled.
  final bool canceled;

  /// Task is in waiting state before auto retry.
  final bool waiting;

  /// Task has been stopped.
  ///
  /// the [Task] is not active and has no exception or it has exception but the [TaskRetryConfig] manual value is set to false
  final bool stopped;

  TaskState({
    required this.pending,
    required this.active,
    required this.interactive,
    required this.running,
    required this.success,
    required this.failed,
    required this.completed,
    required this.canceled,
    required this.waiting,
    required this.stopped,
  });

  @override
  String toString() {
    return "[$runtimeType ${_toMap().toString()}]";
  }

  Map _toMap() {
    return {
      "pending": pending,
      "active": active,
      "interacive": interactive,
      "running": running,
      "success": success,
      "failed": failed,
      "completed": completed,
      "canceled": canceled,
      "waiting": waiting,
      "stopped": stopped,
    };
  }
}
