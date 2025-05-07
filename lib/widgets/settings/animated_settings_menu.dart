import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:karasu_launcher/pages/settings/settings_page.dart';
import 'package:karasu_launcher/widgets/animations/side_menu_animation.dart';

class AnimatedSettingsMenu extends StatefulWidget {
  final SettingsSection currentSection;
  final Function(SettingsSection) onSectionChanged;

  const AnimatedSettingsMenu({
    super.key,
    required this.currentSection,
    required this.onSectionChanged,
  });

  @override
  State<AnimatedSettingsMenu> createState() => _AnimatedSettingsMenuState();
}

class _AnimatedSettingsMenuState extends State<AnimatedSettingsMenu>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late SideMenuAnimation _animation;
  bool _isMenuOpen = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _animation = SideMenuAnimation(controller: _animationController);

    _animationController.value = 1.0;
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleMenu() {
    setState(() {
      _isMenuOpen = !_isMenuOpen;
      _animation.setMenuState(_isMenuOpen);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final menuWidth = _animation.calculateMenuWidth();

        return SizedBox(
          width: menuWidth,
          height: MediaQuery.of(context).size.height,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                onPressed: _toggleMenu,
                icon: Icon(
                  _isMenuOpen ? Icons.chevron_left : Icons.chevron_right,
                ),
                tooltip:
                    _isMenuOpen
                        ? FlutterI18n.translate(context, 'sideMenu.closeMenu')
                        : FlutterI18n.translate(context, 'sideMenu.openMenu'),
              ),
              Expanded(
                child: ListView(
                  children: [
                    _buildMenuItem(
                      context,
                      icon: Icons.settings,
                      title: FlutterI18n.translate(
                        context,
                        'settingsPage.general',
                      ),
                      section: SettingsSection.general,
                    ),
                    _buildMenuItem(
                      context,
                      icon: Icons.coffee,
                      title: FlutterI18n.translate(
                        context,
                        'settingsPage.java',
                      ),
                      section: SettingsSection.java,
                    ),
                    _buildMenuItem(
                      context,
                      icon: Icons.storage,
                      title: FlutterI18n.translate(
                        context,
                        'settingsPage.dataManagement',
                      ),
                      section: SettingsSection.data,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required SettingsSection section,
  }) {
    final isActive = widget.currentSection == section;
    final showText = _animation.isMenuOpen;

    return LayoutBuilder(
      builder: (context, constraints) {
        Widget menuItem = Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 2.0),
          child: SizedBox(
            width: constraints.maxWidth,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
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
              onTap: () => widget.onSectionChanged(section),
              leading: Icon(
                icon,
                color: isActive ? Colors.white : Colors.white70,
                size: 18,
              ),
              tileColor: isActive ? Colors.white.withAlpha(51) : null,
              title:
                  showText
                      ? AnimatedOpacity(
                        duration: const Duration(milliseconds: 150),
                        opacity: _animation.getTextOpacity(),
                        child: Text(
                          title,
                          style: TextStyle(
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
