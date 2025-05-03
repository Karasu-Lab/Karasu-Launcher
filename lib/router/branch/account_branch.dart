part of '../routes.dart';

@TypedGoRoute<AccountHomeRoute>(
  path: '/accounts',
  routes: [
    TypedGoRoute<AccountSignInRoute>(path: 'sign-in'),
    TypedGoRoute<AccountProfileRoute>(path: 'profiles/:id'),
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
  const AccountProfileRoute({required this.id});

  final String id;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return AccountProfilePage(microsoftId: id);
  }
}

const accountStatefulShellBranch = TypedStatefulShellBranch<AccountBranchData>(
  routes: [
    TypedGoRoute<AccountHomeRoute>(
      path: '/accounts',
      routes: [
        TypedGoRoute<AccountSignInRoute>(path: 'sign-in'),
        TypedGoRoute<AccountProfileRoute>(path: 'profiles/:id'),
      ],
    ),
  ],
);

class AccountBranchData extends StatefulShellBranchData {
  const AccountBranchData();

  static final GlobalKey<NavigatorState> $navigatorKey = _sideMenuNavigatorKey;
}
