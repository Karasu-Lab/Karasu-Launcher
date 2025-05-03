part of '../routes.dart';

class TaskManagerShellBranch extends StatefulShellBranchData {
  const TaskManagerShellBranch();
}

const taskManagerStatefulShellBranch = TypedStatefulShellBranch<TaskManagerShellBranch>(
  routes: <TypedRoute<RouteData>>[
    TypedGoRoute<TaskManagerPageRoute>(
      path: '/taskmanager',
    ),
  ],
);

class TaskManagerPageRoute extends GoRouteData {
  const TaskManagerPageRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const TaskManagerPage();
  }
}
