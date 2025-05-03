// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'routes.dart';

// **************************************************************************
// GoRouterGenerator
// **************************************************************************

List<RouteBase> get $appRoutes => [$mainShellRouteData, $accountHomeRoute];

RouteBase get $mainShellRouteData => StatefulShellRouteData.$route(
  factory: $MainShellRouteDataExtension._fromState,
  branches: [
    StatefulShellBranchData.$branch(
      routes: [
        GoRouteData.$route(
          path: '/minecraft',

          factory: $HomePageRouteExtension._fromState,
        ),
      ],
    ),
    StatefulShellBranchData.$branch(
      routes: [
        GoRouteData.$route(
          path: '/settings',

          factory: $SettingPageRouteExtension._fromState,
        ),
      ],
    ),
    StatefulShellBranchData.$branch(
      routes: [
        GoRouteData.$route(
          path: '/profile',

          factory: $ProfilePageRouteExtension._fromState,
        ),
      ],
    ),
    StatefulShellBranchData.$branch(
      routes: [
        GoRouteData.$route(
          path: '/mod',

          factory: $ModRouteExtension._fromState,
          routes: [
            GoRouteData.$route(
              path: 'modrinth',

              factory: $ModrinthRouteExtension._fromState,
            ),
            GoRouteData.$route(
              path: 'curseforge',

              factory: $CurseforgeRouteExtension._fromState,
            ),
          ],
        ),
      ],
    ),
    StatefulShellBranchData.$branch(
      routes: [
        GoRouteData.$route(
          path: '/server',

          factory: $ServerPageRouteExtension._fromState,
        ),
      ],
    ),
    StatefulShellBranchData.$branch(
      routes: [
        GoRouteData.$route(
          path: '/social',

          factory: $SocialBaseRouteExtension._fromState,
          routes: [
            GoRouteData.$route(
              path: 'twitter',

              factory: $TwitterPageRouteExtension._fromState,
            ),
            GoRouteData.$route(
              path: 'github',

              factory: $GitHubPageRouteExtension._fromState,
            ),
          ],
        ),
      ],
    ),
    StatefulShellBranchData.$branch(
      navigatorKey: AccountBranchData.$navigatorKey,

      routes: [
        GoRouteData.$route(
          path: '/accounts',

          factory: $AccountHomeRouteExtension._fromState,
          routes: [
            GoRouteData.$route(
              path: 'sign-in',

              factory: $AccountSignInRouteExtension._fromState,
            ),
            GoRouteData.$route(
              path: 'profiles/:id',

              factory: $AccountProfileRouteExtension._fromState,
            ),
          ],
        ),
      ],
    ),
  ],
);

extension $MainShellRouteDataExtension on MainShellRouteData {
  static MainShellRouteData _fromState(GoRouterState state) =>
      const MainShellRouteData();
}

extension $HomePageRouteExtension on HomePageRoute {
  static HomePageRoute _fromState(GoRouterState state) => const HomePageRoute();

  String get location => GoRouteData.$location('/minecraft');

  void go(BuildContext context) => context.go(location);

  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  void replace(BuildContext context) => context.replace(location);
}

extension $SettingPageRouteExtension on SettingPageRoute {
  static SettingPageRoute _fromState(GoRouterState state) =>
      const SettingPageRoute();

  String get location => GoRouteData.$location('/settings');

  void go(BuildContext context) => context.go(location);

  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  void replace(BuildContext context) => context.replace(location);
}

extension $ProfilePageRouteExtension on ProfilePageRoute {
  static ProfilePageRoute _fromState(GoRouterState state) =>
      const ProfilePageRoute();

  String get location => GoRouteData.$location('/profile');

  void go(BuildContext context) => context.go(location);

  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  void replace(BuildContext context) => context.replace(location);
}

extension $ModRouteExtension on ModRoute {
  static ModRoute _fromState(GoRouterState state) => const ModRoute();

  String get location => GoRouteData.$location('/mod');

  void go(BuildContext context) => context.go(location);

  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  void replace(BuildContext context) => context.replace(location);
}

extension $ModrinthRouteExtension on ModrinthRoute {
  static ModrinthRoute _fromState(GoRouterState state) => const ModrinthRoute();

  String get location => GoRouteData.$location('/mod/modrinth');

  void go(BuildContext context) => context.go(location);

  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  void replace(BuildContext context) => context.replace(location);
}

extension $CurseforgeRouteExtension on CurseforgeRoute {
  static CurseforgeRoute _fromState(GoRouterState state) =>
      const CurseforgeRoute();

  String get location => GoRouteData.$location('/mod/curseforge');

  void go(BuildContext context) => context.go(location);

  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  void replace(BuildContext context) => context.replace(location);
}

extension $ServerPageRouteExtension on ServerPageRoute {
  static ServerPageRoute _fromState(GoRouterState state) =>
      const ServerPageRoute();

  String get location => GoRouteData.$location('/server');

  void go(BuildContext context) => context.go(location);

  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  void replace(BuildContext context) => context.replace(location);
}

extension $SocialBaseRouteExtension on SocialBaseRoute {
  static SocialBaseRoute _fromState(GoRouterState state) =>
      const SocialBaseRoute();

  String get location => GoRouteData.$location('/social');

  void go(BuildContext context) => context.go(location);

  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  void replace(BuildContext context) => context.replace(location);
}

extension $TwitterPageRouteExtension on TwitterPageRoute {
  static TwitterPageRoute _fromState(GoRouterState state) =>
      const TwitterPageRoute();

  String get location => GoRouteData.$location('/social/twitter');

  void go(BuildContext context) => context.go(location);

  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  void replace(BuildContext context) => context.replace(location);
}

extension $GitHubPageRouteExtension on GitHubPageRoute {
  static GitHubPageRoute _fromState(GoRouterState state) =>
      const GitHubPageRoute();

  String get location => GoRouteData.$location('/social/github');

  void go(BuildContext context) => context.go(location);

  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  void replace(BuildContext context) => context.replace(location);
}

extension $AccountHomeRouteExtension on AccountHomeRoute {
  static AccountHomeRoute _fromState(GoRouterState state) =>
      const AccountHomeRoute();

  String get location => GoRouteData.$location('/accounts');

  void go(BuildContext context) => context.go(location);

  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  void replace(BuildContext context) => context.replace(location);
}

extension $AccountSignInRouteExtension on AccountSignInRoute {
  static AccountSignInRoute _fromState(GoRouterState state) =>
      const AccountSignInRoute();

  String get location => GoRouteData.$location('/accounts/sign-in');

  void go(BuildContext context) => context.go(location);

  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  void replace(BuildContext context) => context.replace(location);
}

extension $AccountProfileRouteExtension on AccountProfileRoute {
  static AccountProfileRoute _fromState(GoRouterState state) =>
      AccountProfileRoute(id: state.pathParameters['id']!);

  String get location =>
      GoRouteData.$location('/accounts/profiles/${Uri.encodeComponent(id)}');

  void go(BuildContext context) => context.go(location);

  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $accountHomeRoute => GoRouteData.$route(
  path: '/accounts',

  factory: $AccountHomeRouteExtension._fromState,
  routes: [
    GoRouteData.$route(
      path: 'sign-in',

      factory: $AccountSignInRouteExtension._fromState,
    ),
    GoRouteData.$route(
      path: 'profiles/:id',

      factory: $AccountProfileRouteExtension._fromState,
    ),
  ],
);
