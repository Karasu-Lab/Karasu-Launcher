part of '../routes.dart';

class SettingShellBranch extends StatefulShellBranchData {
  const SettingShellBranch();
}

const settingStatefulShellBranch = TypedStatefulShellBranch<SettingShellBranch>(
  routes: <TypedRoute<RouteData>>[
    TypedGoRoute<SettingPageRoute>(
      path: '/settings',
      routes: <TypedRoute<RouteData>>[
        TypedGoRoute<GeneralSettingsRoute>(
          path: 'general',
        ),
        TypedGoRoute<JavaSettingsRoute>(
          path: 'java',
        ),
        TypedGoRoute<DataManagementRoute>(
          path: 'data',
        ),
      ],
    ),
  ],
);

class SettingPageRoute extends GoRouteData {
  const SettingPageRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    // デフォルトでGeneralSettingsPageにリダイレクト
    return const SettingsPage(section: 'general');
  }
}

class GeneralSettingsRoute extends GoRouteData {
  const GeneralSettingsRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const SettingsPage(section: 'general');
  }
}

class JavaSettingsRoute extends GoRouteData {
  const JavaSettingsRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const SettingsPage(section: 'java');
  }
}

class DataManagementRoute extends GoRouteData {
  const DataManagementRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const SettingsPage(section: 'data');
  }
}
