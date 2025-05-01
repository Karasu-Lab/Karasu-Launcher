part of '../routes.dart';

class ModShellBranch extends StatefulShellBranchData {
  const ModShellBranch();
}

class ModRoute extends GoRouteData {
  const ModRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const ModPage();
  }
}

class ModrinthRoute extends GoRouteData {
  const ModrinthRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const ModrinthPage();
  }
}

class CurseforgeRoute extends GoRouteData {
  const CurseforgeRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const CurseforgeePage();
  }
}

const modStatefulShellBranch = TypedStatefulShellBranch<ModShellBranch>(
  routes: <TypedRoute<RouteData>>[
    TypedGoRoute<ModRoute>(
      path: '/mod',
      routes: [
        TypedGoRoute<ModrinthRoute>(path: 'modrinth'),
        TypedGoRoute<CurseforgeRoute>(path: 'curseforge'),
      ],
    ),
  ],
);
