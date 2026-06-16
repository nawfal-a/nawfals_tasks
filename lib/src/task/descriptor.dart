part of 'manager.dart';

class TaskDescriptor {
  /// [Task] operation.
  final TaskOperation operation;

  /// [Task] data type.
  final Type dataType;

  /// [Task] list of data unique identifiers.
  final List<String>? dataUniqueIdentifiers;

  /// [Task] targets.
  ///
  /// If you have multiple tasks with the same [dataType] and [dataUniqueIdentifiers]
  /// this can help in separating between them.
  final List<String> targets;

  /// Defines [Task] descriptor.
  ///
  /// Used to distinguish task by [TaskOperation], assosiated [dataType],
  /// [dataUniqueIdentifiers] and [targets].
  /// New [Task] will cancel previous tasks that have the same [TaskOperation]
  /// [dataType], [dataUniqueIdentifiers] and contains all targets of previous task.
  ///
  /// [cancelingOperations]
  /// New [Task] with this operations will cancel this [Task] if other parameters are
  /// matching, except for targets.
  /// If null, default operations will be used.
  TaskDescriptor({
    required this.operation,
    required this.dataType,
    required this.dataUniqueIdentifiers,
    this.targets = const [],
    List<TaskOperation>? cancelingOperations,
  }) {
    _hashCode = Object.hashAll([
      operation,
      dataType,
      if (dataUniqueIdentifiers != null)
        ...List<String>.from(dataUniqueIdentifiers!)..sort(),
      ...List<String>.from(targets)..sort(),
    ]);

    this.cancelingOperations =
        cancelingOperations ??
        TaskOperations.getDefaultCancellingOperations(operation);
  }

  late List<TaskOperation> cancelingOperations;

  static TaskDescriptor single({
    required TaskOperation operation,
    required Type dataType,
    required String dataUniqueIdentifier,
    List<String> targets = const [],
    List<TaskOperation>? cancelingOperations,
  }) {
    return TaskDescriptor(
      operation: operation,
      dataType: dataType,
      dataUniqueIdentifiers: [dataUniqueIdentifier],
      targets: targets,
      cancelingOperations: cancelingOperations,
    );
  }

  bool _sameData(TaskDescriptor other) {
    if (dataType != other.dataType) {
      return false;
    }

    if (dataUniqueIdentifiers != null &&
        other.dataUniqueIdentifiers != null &&
        !listEquals(dataUniqueIdentifiers, other.dataUniqueIdentifiers)) {
      return false;
    }

    return true;
  }

  bool _shouldCancel(TaskDescriptor other) {
    if (this == other) {
      return true;
    }

    if (operation != other.operation) {
      return false;
    }

    if (!_sameData(other)) {
      return false;
    }

    if (!targets.toSet().containsAll(other.targets)) {
      return false;
    }

    return true;
  }

  late int _hashCode;

  @override
  int get hashCode {
    return _hashCode;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TaskDescriptor &&
          runtimeType == other.runtimeType &&
          operation == other.operation &&
          hashCode == other.hashCode);

  @override
  String toString() {
    return "[$runtimeType ${_toMap().toString()}]";
  }

  /// Convert to [Map].
  Map _toMap() {
    return {
      "operation": operation.name,
      "dataType": dataType,
      "dataUniqueIdentifiers": dataUniqueIdentifiers,
      "targets": targets,
      "cancelingOperations": [
        for (TaskOperation operation in cancelingOperations) operation.name,
      ],
    };
  }
}
