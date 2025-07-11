import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import '../providers/side_menu_provider.dart';
import '../providers/authentication_provider.dart';
import './account/user_icon.dart';
import 'package:twemoji/twemoji.dart';
import './animations/side_menu_animation.dart';

class AnimatedSideMenu extends ConsumerStatefulWidget {
  const AnimatedSideMenu({super.key});

  @override
  ConsumerState<AnimatedSideMenu> createState() => _AnimatedSideMenuState();
}

class _AnimatedSideMenuState extends ConsumerState<AnimatedSideMenu>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late SideMenuAnimation _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _animation = SideMenuAnimation(controller: _animationController);

    final isMenuOpen = ref.read(sideMenuOpenProvider);
    if (isMenuOpen) {
      _animationController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(sideMenuOpenProvider, (previous, next) {
      _animation.setMenuState(next);
    });
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final menuWidth = _animation.calculateMenuWidth();

        return SizedBox(
          width: menuWidth,
          height: MediaQuery.of(context).size.height,
          child: Container(
            color: Colors.transparent,
            height: MediaQuery.of(context).size.height,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        _buildMenuItem(
                          IonIcons.cube,
                          'Minecraft',
                          path: '/minecraft',
                        ),
                        _buildMenuItem(
                          BoxIcons.bx_server,
                          'Minecraft Server',
                          path: '/server',
                        ),
                        _buildMenuItem(
                          RichText(
                            text: TwemojiTextSpan(
                              text: '🦵',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ),
                          'Modrinth',
                          path: '/mod/modrinth',
                        ),
                        _buildMenuItem(
                          SvgPicture.asset(
                            "assets/anvil.svg",
                            colorFilter: ColorFilter.mode(
                              Theme.of(context).iconTheme.color!,
                              BlendMode.srcIn,
                            ),
                          ),
                          'CurseForge',
                          path: '/mod/curseforge',
                        ),
                      ],
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMenuItem(
                      Icons.monitor,
                      FlutterI18n.translate(context, "sideMenu.taskManager"),
                      path: '/taskmanager',
                    ),
                    Consumer(
                      builder: (context, ref, child) {
                        final authState = ref.watch(authenticationProvider);
                        return _buildMenuItem(
                          UserIcon(
                            account: authState.activeAccount,
                            size: 21,
                            borderRadius: 4,
                          ),
                          FlutterI18n.translate(context, "sideMenu.accounts"),
                          path: '/accounts',
                        );
                      },
                    ),
                    _buildMenuItem(
                      Icons.settings,
                      FlutterI18n.translate(context, "sideMenu.settings"),
                      path: '/settings',
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMenuItem(dynamic iconData, String title, {String? path}) {
    final showText = _animation.isMenuOpen;
    final currentLocation = GoRouterState.of(context).matchedLocation;
    final isActive = path != null && currentLocation == path;

    Widget leadingWidget;
    if (iconData is Widget) {
      if (iconData is SvgPicture) {
        leadingWidget = SizedBox(width: 18, height: 18, child: iconData);
      } else if (iconData is RichText) {
        leadingWidget = SizedBox(
          width: 21,
          height: 21,
          child: FittedBox(fit: BoxFit.contain, child: iconData),
        );
      } else {
        leadingWidget = SizedBox(width: 18, height: 18, child: iconData);
      }
    } else if (iconData is IconData) {
      leadingWidget = Icon(
        iconData,
        color: isActive ? Colors.white : Colors.white70,
        size: 18,
      );
    } else if (iconData is String &&
        (iconData.startsWith('http://') || iconData.startsWith('https://'))) {
      leadingWidget = ClipRRect(
        borderRadius: BorderRadius.circular(4.0),
        child: Image.network(
          iconData,
          width: 18,
          height: 18,
          fit: BoxFit.cover,
          errorBuilder:
              (context, error, stackTrace) => const Icon(
                Icons.broken_image,
                color: Colors.white70,
                size: 18,
              ),
        ),
      );
    } else {
      leadingWidget = const Icon(Icons.error, color: Colors.white70, size: 18);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        Widget menuItem = Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 2.0),
          child: SizedBox(
            width: constraints.maxWidth,
            child: ListTile(
              contentPadding: EdgeInsets.symmetric(
                horizontal: 9.0,
                vertical: 0,
              ),
              minLeadingWidth: 20,
              horizontalTitleGap: 8,
              dense: true,
              visualDensity: VisualDensity.compact,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              onTap: () {
                if (path != null) {
                  context.go(path);
                }
              },
              leading: leadingWidget,
              tileColor: isActive ? Colors.white.withAlpha(51) : null,
              title:
                  showText
                      ? AnimatedOpacity(
                        duration: const Duration(milliseconds: 150),
                        opacity: _animation.getTextOpacity(),
                        child: Text(
                          title,
                          style: TextStyle(
                            color: isActive ? Colors.white : Colors.white,
                            fontSize: 14,
                            fontWeight:
                                isActive ? FontWeight.bold : FontWeight.normal,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      )
                      : null,
            ),
          ),
        );
        if (!showText) {
          menuItem = Tooltip(
            message: title,
            waitDuration: const Duration(milliseconds: 800),
            preferBelow: false,
            verticalOffset: 0,
            margin: const EdgeInsets.only(left: 12),
            textStyle: const TextStyle(fontSize: 14, color: Colors.white),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(4),
            ),
            child: menuItem,
          );
        }

        return menuItem;
      },
    );
  }
}
