part of '../routes.dart';

class SocialShellBranch extends StatefulShellBranchData {
  const SocialShellBranch();
}

const socialStatefulShellBranch = TypedStatefulShellBranch<SocialShellBranch>(
  routes: <TypedRoute<RouteData>>[
    TypedGoRoute<SocialBaseRoute>(
      path: '/social',
      routes: [
        TypedGoRoute<TwitterPageRoute>(path: 'twitter'),
        TypedGoRoute<GitHubPageRoute>(path: 'github'),
      ],
    ),
  ],
);

// ソーシャルのベースルート
class SocialBaseRoute extends GoRouteData {
  const SocialBaseRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    // デフォルトでTwitterに遷移するか、ソーシャルのホームページを表示することができます
    return const SocialHomePage();
  }
}

class TwitterPageRoute extends GoRouteData {
  const TwitterPageRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const TwitterPage();
  }
}

class GitHubPageRoute extends GoRouteData {
  const GitHubPageRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const GitHubPage();
  }
}
