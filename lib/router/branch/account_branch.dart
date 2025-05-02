part of '../routes.dart';

@TypedGoRoute<AccountHomeRoute>(
  path: '/accounts',
  routes: [
    TypedGoRoute<AccountSignInRoute>(path: 'sign-in'),
    TypedGoRoute<AccountProfileRoute>(path: 'profile'),
    TypedGoRoute<AccountSignOutRoute>(path: 'sign-out'),
  ],
)
class AccountHomeRoute extends GoRouteData {
  const AccountHomeRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const AccountHomePage();
  }
}

class AccountSignInRoute extends GoRouteData {
  const AccountSignInRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const AccountSignInPage();
  }
}

class AccountProfileRoute extends GoRouteData {
  const AccountProfileRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const AccountProfilePage();
  }
}

class AccountSignOutRoute extends GoRouteData {
  const AccountSignOutRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const AccountSignOutPage();
  }
}

const accountStatefulShellBranch = TypedStatefulShellBranch<AccountBranchData>(
  routes: [
    TypedGoRoute<AccountHomeRoute>(
      path: '/accounts',
      routes: [
        TypedGoRoute<AccountSignInRoute>(path: 'sign-in'),
        TypedGoRoute<AccountProfileRoute>(path: 'profile'),
        TypedGoRoute<AccountSignOutRoute>(path: 'sign-out'),
      ],
    ),
  ],
);

class AccountBranchData extends StatefulShellBranchData {
  const AccountBranchData();

  static final GlobalKey<NavigatorState> $navigatorKey = _sideMenuNavigatorKey;
}
