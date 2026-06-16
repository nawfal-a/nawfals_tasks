class TaskOperation {
  /// Operation name.
  ///
  /// Operations with identical names are considered the same even they are of different instances.
  final String name;

  /// Whether this operation will lead to change in data, such as database or files.
  final bool mutating;

  /// Defines [Task] operation.
  ///
  /// For example: Loading, Updating, Starting, etc.
  const TaskOperation({required this.name, required this.mutating});

  @override
  int get hashCode => Object.hash(name, mutating);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TaskOperation &&
          runtimeType == other.runtimeType &&
          hashCode == other.hashCode);

  @override
  String toString() {
    return "[$runtimeType $name]";
  }

  /// Convert to [Map].
  Map toMap() {
    return {"name": name, "mutating": mutating};
  }

  /// Create [TaskOperation] from [Map].
  static TaskOperation fromMap(Map map) {
    return TaskOperation(name: map["name"], mutating: map["mutating"]);
  }
}

class TaskOperations {
  /// Load operation.
  static const TaskOperation load = TaskOperation(
    name: "Load",
    mutating: false,
  );

  /// Reload operation.
  static const TaskOperation reload = TaskOperation(
    name: "Reload",
    mutating: false,
  );

  /// Search operation.
  static const TaskOperation search = TaskOperation(
    name: "Search",
    mutating: false,
  );

  /// Load more operation.
  static const TaskOperation loadMore = TaskOperation(
    name: "Load more",
    mutating: false,
  );

  /// Open operation.
  static const TaskOperation open = TaskOperation(
    name: "Open",
    mutating: false,
  );

  /// Reopen operation.
  static const TaskOperation reopen = TaskOperation(
    name: "Reopen",
    mutating: false,
  );

  /// Close operation.
  static const TaskOperation close = TaskOperation(
    name: "Close",
    mutating: false,
  );

  /// Create operation.
  static const TaskOperation create = TaskOperation(
    name: "Create",
    mutating: true,
  );

  /// Add operation.
  static const TaskOperation add = TaskOperation(name: "Add", mutating: true);

  /// Update operation.
  static const TaskOperation update = TaskOperation(
    name: "Update",
    mutating: true,
  );

  /// Edit operation.
  static const TaskOperation edit = TaskOperation(name: "Edit", mutating: true);

  /// Delete operation.
  static const TaskOperation delete = TaskOperation(
    name: "Delete",
    mutating: true,
  );

  /// Restore operation.
  static const TaskOperation restore = TaskOperation(
    name: "Restore",
    mutating: true,
  );

  /// Erase operation.
  static const TaskOperation erase = TaskOperation(
    name: "Erase",
    mutating: true,
  );

  /// Start operation.
  static const TaskOperation start = TaskOperation(
    name: "Start",
    mutating: false,
  );

  /// Stop operation.
  static const TaskOperation stop = TaskOperation(
    name: "Stop",
    mutating: false,
  );

  /// Get operation.
  static const TaskOperation get = TaskOperation(name: "Get", mutating: false);

  /// Read operation.
  static const TaskOperation read = TaskOperation(
    name: "Read",
    mutating: false,
  );

  /// Check operation.
  static const TaskOperation check = TaskOperation(
    name: "Check",
    mutating: false,
  );

  /// Login operation.
  static const TaskOperation login = TaskOperation(
    name: "Login",
    mutating: false,
  );

  /// Logout operation.
  static const TaskOperation logout = TaskOperation(
    name: "Logout",
    mutating: false,
  );

  /// Initialize operation.
  static const TaskOperation initialize = TaskOperation(
    name: "Initialize",
    mutating: false,
  );

  /// Get the default cancelling operations ignores targets for each operation.
  static bool getDefaultCancellingOperationsIgnoresTargets(
    TaskOperation operation,
  ) {
    switch (operation) {
      case TaskOperations.update:
        return true;
      case TaskOperations.edit:
        return true;
      case TaskOperations.delete:
        return true;
      default:
        return false;
    }
  }

  /// Get the default cancelling operations for each operation.
  static List<TaskOperation> getDefaultCancellingOperations(
    TaskOperation operation,
  ) {
    switch (operation) {
      case TaskOperations.load:
        return [
          TaskOperations.reload,
          TaskOperations.search,
          TaskOperations.reopen,
        ];
      case TaskOperations.reload:
        return [
          TaskOperations.load,
          TaskOperations.search,
          TaskOperations.open,
        ];
      case TaskOperations.open:
        return [TaskOperations.reload, TaskOperations.reopen];
      case TaskOperations.reopen:
        return [TaskOperations.load, TaskOperations.open];
      case TaskOperations.update:
        return [TaskOperations.delete, TaskOperations.erase];
      case TaskOperations.edit:
        return [TaskOperations.delete, TaskOperations.erase];
      case TaskOperations.delete:
        return [TaskOperations.erase];
      case TaskOperations.open:
        return [
          TaskOperations.delete,
          TaskOperations.erase,
          TaskOperations.close,
        ];
      case TaskOperations.close:
        return [TaskOperations.open];
      case TaskOperations.start:
        return [TaskOperations.stop];
      case TaskOperations.stop:
        return [TaskOperations.start];
      default:
        return [];
    }
  }
}
