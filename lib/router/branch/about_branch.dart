part of '../routes.dart';

class AboutShellBranch extends StatefulShellBranchData {
  const AboutShellBranch();
}

const aboutStatefulShellBranch = TypedStatefulShellBranch<AboutShellBranch>(
  routes: <TypedRoute<RouteData>>[TypedGoRoute<AboutBaseRoute>(path: '/about')],
);

class AboutBaseRoute extends GoRouteData {
  const AboutBaseRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const AboutHomePage();
  }
}
