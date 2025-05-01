part of '../routes.dart';

class SettingShellBranch extends StatefulShellBranchData {
  const SettingShellBranch();
}

const settingStatefulShellBranch = TypedStatefulShellBranch<SettingShellBranch>(
  routes: <TypedRoute<RouteData>>[
    TypedGoRoute<SettingPageRoute>(
      path: '/settings',
    ),
  ],
);

class SettingPageRoute extends GoRouteData {
  const SettingPageRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const SettingPage();
  }
}
