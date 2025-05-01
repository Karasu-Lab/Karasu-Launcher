part of '../routes.dart';

class ServerShellBranch extends StatefulShellBranchData {
  const ServerShellBranch();
}

const serverStatefulShellBranch = TypedStatefulShellBranch<ServerShellBranch>(
  routes: <TypedRoute<RouteData>>[
    TypedGoRoute<ServerPageRoute>(path: '/server'),
  ],
);

class ServerPageRoute extends GoRouteData {
  const ServerPageRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const ServerPage();
  }
}
