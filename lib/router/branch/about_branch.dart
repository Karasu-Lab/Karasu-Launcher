part of '../routes.dart';

class AboutShellBranch extends StatefulShellBranchData {
  const AboutShellBranch();
}

const aboutStatefulShellBranch = TypedStatefulShellBranch<AboutShellBranch>(
  routes: <TypedRoute<RouteData>>[
    TypedGoRoute<AboutBaseRoute>(
      path: '/about',
      routes: [
        TypedGoRoute<AboutLicenseRoute>(path: 'license'),
      ],
    ),
  ],
);

class AboutBaseRoute extends GoRouteData {
  const AboutBaseRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const AboutHomePage();
  }
}

class AboutLicenseRoute extends GoRouteData {
  const AboutLicenseRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const AboutLicensePage();
  }
}
