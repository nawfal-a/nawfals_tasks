part of '../task/manager.dart';

class TaskHandler extends StatefulWidget {
  /// Create Task manager instance.
  final TaskManager Function() initialize;

  final Widget child;

  /// Create task handler widget that will carry the [TaskManager] instance with the [BuildContext].
  const TaskHandler({super.key, required this.initialize, required this.child});

  @override
  State<TaskHandler> createState() => _TaskHandlerState();
}

class _TaskHandlerState extends State<TaskHandler> {
  late TaskManager taskManager;

  @override
  void initState() {
    taskManager = widget.initialize();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return _TaskHandler(manager: taskManager, child: widget.child);
  }

  @override
  void dispose() {
    taskManager.dispose();
    super.dispose();
  }
}

class _TaskHandler extends InheritedWidget {
  final TaskManager manager;

  const _TaskHandler({required super.child, required this.manager});

  @override
  bool updateShouldNotify(covariant _TaskHandler oldWidget) {
    return false;
  }
}
