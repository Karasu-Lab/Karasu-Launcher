import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:karasu_launcher/pages/about/about_home_page.dart';
import 'package:karasu_launcher/pages/mod/curseforge_page.dart';
import 'package:karasu_launcher/pages/mod/mod_page.dart';
import 'package:karasu_launcher/pages/mod/modrinth_page.dart';
import 'package:karasu_launcher/pages/server_page.dart';
import 'package:karasu_launcher/widgets/window_buttons.dart';
import 'package:karasu_launcher/widgets/animated_side_menu.dart';
import 'package:karasu_launcher/widgets/side_menu_toggle_button.dart';

import '../pages/home_page.dart';
import '../pages/setting_page.dart';
import '../pages/loading_page.dart';
import '../pages/account/account_home_page.dart';
import '../pages/account/account_sign_in_page.dart';
import '../pages/account/account_profile_page.dart';
import '../pages/taskmanager_page.dart';

part 'routes.g.dart';
part 'branch/home_branch.dart';
part 'branch/setting_branch.dart';
part 'branch/mod_branch.dart';
part 'branch/server_branch.dart';
part 'branch/about_branch.dart';
part 'branch/account_branch.dart';
part 'branch/taskmanager_branch.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _sideMenuNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    navigatorKey: _rootNavigatorKey,
    debugLogDiagnostics: kDebugMode,
    routes: [
      GoRoute(path: '/', builder: (context, state) => const LoadingPage()),
      ...$appRoutes,
    ],
  );
});

@TypedStatefulShellRoute<MainShellRouteData>(
  branches: <TypedStatefulShellBranch<StatefulShellBranchData>>[
    homeStatefulShellBranch,
    settingStatefulShellBranch,
    modStatefulShellBranch,
    serverStatefulShellBranch,
    aboutStatefulShellBranch,
    accountStatefulShellBranch,
    taskManagerStatefulShellBranch,
  ],
)
class MainShellRouteData extends StatefulShellRouteData {
  const MainShellRouteData();

  @override
  Widget builder(
    BuildContext context,
    GoRouterState state,
    StatefulNavigationShell navigationShell,
  ) {
    return AppNavigationBar(navigationShell: navigationShell);
  }
}

class AppNavigationBar extends ConsumerWidget {
  const AppNavigationBar({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static final GlobalKey<NavigatorState> $parentNavigatorKey =
      _rootNavigatorKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: WindowBorder(
        color: Colors.transparent,
        width: 0,
        child: Column(
          children: [
            WindowTitleBarBox(
              child: Row(
                children: [
                  const SideMenuToggleButton(),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.only(left: 16),
                      child: MoveWindow(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Text(
                              "Karasu Launcher",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const WindowButtons(),
                ],
              ),
            ),
            Expanded(
              child: Row(
                children: [
                  const AnimatedSideMenu(),
                  Expanded(child: navigationShell),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
