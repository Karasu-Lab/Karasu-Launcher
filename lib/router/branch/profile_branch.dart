part of '../routes.dart';

class ProfileShellBranch extends StatefulShellBranchData {
  const ProfileShellBranch();
}

const profileStatefulShellBranch = TypedStatefulShellBranch<ProfileShellBranch>(
  routes: <TypedRoute<RouteData>>[
    TypedGoRoute<ProfilePageRoute>(
      path: '/profile',
    ),
  ],
);

class ProfilePageRoute extends GoRouteData {
  const ProfilePageRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const ProfilePage();
  }
}
