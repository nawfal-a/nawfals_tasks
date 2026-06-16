part of 'manager.dart';

class TaskConfig {
  /// Sets the [Task] as hidden.
  ///
  /// Hidden tasks does not notify listeners and can not be listened to.
  final bool hidden;

  /// Sets the [Task] as private.
  ///
  /// Private tasks are not shown is general listeners like [TaskListener.current] or [TaskListener.active].
  final bool private;

  /// Waiting duration for the task to stay active after completion before stopping.
  ///
  /// If null, the value set in [TaskManager] will be used.
  final Duration? afterCompletionDelay;

  /// Delay to debounce  task callback.
  final Duration? debounceDelay;

  /// Sets the [Task] retry configration.
  late final TaskRetryConfig retryConfig;

  /// Defines [Task] configrations.
  ///
  /// [retryConfig] sets the [Task] retry configration.
  /// If null, the default is [cancelable], [manual] with [auto] disabled.
  TaskConfig({
    this.hidden = false,
    this.private = false,
    this.afterCompletionDelay,
    this.debounceDelay,
    TaskRetryConfig? retryConfig,
  }) {
    this.retryConfig = retryConfig ?? TaskRetryConfig();
  }

  @override
  String toString() {
    return "[$runtimeType ${_toMap().toString()}]";
  }

  /// Convert to [Map].
  Map _toMap() {
    return {
      "hidden": hidden,
      "private": private,
      "afterCompletionDelay": afterCompletionDelay?.inMilliseconds,
      "debounceDelay": debounceDelay?.inMilliseconds,
      "retryConfig": retryConfig._toMap(),
    };
  }
}

class TaskRetryConfig {
  /// Defines if the [Task] supports manual retry.
  ///
  /// Can be used to show retry button if the [Task] failed.
  final bool manual;

  /// Defines if the [Task] supports auto retry.
  final bool auto;

  /// Defines the [Task] auto retries count.
  ///
  /// -1 for infinity, caution that infinity auto retries may lead to performance issues.
  ///
  /// If null, the value set in [TaskManager] will be used.
  final int? maxAutoRetries;

  /// Defines the [Task] delay before auto retry.
  ///
  /// If null, the value set in [TaskManager] will be used.
  final Duration? autoRetryDelay;

  /// Defines [Task] retry configration.
  ///
  /// [cancelable] sets the [Task] as cancelable when it is failed.
  TaskRetryConfig({
    this.manual = true,
    this.auto = false,
    bool cancelable = true,
    this.maxAutoRetries,
    this.autoRetryDelay,
  }) {
    if (manual || auto) {
      _cancelable = cancelable;
    } else {
      _cancelable = false;
    }
  }

  /// [Task] retry cancelability.
  ///
  /// Can be used to show cancel button if the [Task] failed.
  /// If both [manual] and [auto] retry is set to [false], [cancelable] is set to [false] automatically because it makes no sense if retry is disabled.
  bool get cancelable => _cancelable;

  @override
  String toString() {
    return "[$runtimeType ${_toMap().toString()}]";
  }

  late final bool _cancelable;

  Map _toMap() {
    return {
      "manual": manual,
      "auto": auto,
      "cancelable": cancelable,
      "maxAutoRetries": maxAutoRetries,
      "autoRetryDelay": autoRetryDelay,
    };
  }
}
