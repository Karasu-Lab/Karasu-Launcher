import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:karasu_launcher/providers/minecraft_state_provider.dart';
import 'package:karasu_launcher/providers/profiles_provider.dart';
import 'package:karasu_launcher/services/minecraft_service.dart';
import 'package:karasu_launcher/widgets/tab.dart';
import 'package:karasu_launcher/pages/home/play_tab.dart';
import 'package:karasu_launcher/pages/home/launch_config_tab.dart';
import 'package:karasu_launcher/pages/home/patch_notes_tab.dart';
import 'package:karasu_launcher/pages/home/log_tab.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  int _currentTabIndex = 0;

  final List<TabItem> _tabs = const [
    TabItem(title: 'プレイ', content: PlayTab()),
    TabItem(title: '起動構成', content: LaunchConfigTab()),
    TabItem(title: '公式パッチノート', content: PatchNotesTab()),
    TabItem(title: 'ログ', content: LogTab()),
  ];
  @override
  void initState() {
    super.initState();

    // postFrameCallbackを使用すると安全にプロバイダーの状態を更新できます
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(profilesProvider.notifier).reloadProfiles();

      final profilesData = ref.read(profilesProvider);
      if (profilesData != null && ref.read(selectedProfileProvider) == null) {
        _findAndSelectLastUsedProfile();
      }
    });
  }

  void _selectLastUsedProfile(bool forceReload) async {
    if (forceReload) {
      await ref.read(profilesProvider.notifier).reloadProfiles();
    }
    _findAndSelectLastUsedProfile();
  }

  void _findAndSelectLastUsedProfile() {
    final updatedProfilesData = ref.read(profilesProvider);
    if (updatedProfilesData == null || updatedProfilesData.profiles.isEmpty) {
      return;
    }

    String? lastUsedProfileId;
    DateTime? lastUsedTime;

    updatedProfilesData.profiles.forEach((id, profile) {
      if (profile.lastUsed != null) {
        final lastUsed = DateTime.tryParse(profile.lastUsed!);
        if (lastUsed != null &&
            (lastUsedTime == null || lastUsed.isAfter(lastUsedTime!))) {
          lastUsedTime = lastUsed;
          lastUsedProfileId = id;
        }
      }
    });

    if (lastUsedProfileId != null) {
      ref.read(selectedProfileProvider.notifier).state = lastUsedProfileId;
    }
  }

  void _onTabChanged(int index) {
    setState(() {
      _currentTabIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final minecraftState = ref.watch(minecraftStateProvider);
    final minecraftService = ref.read(minecraftServiceProvider);

    final profilesData = ref.watch(profilesProvider);
    final selectedProfileId = ref.watch(selectedProfileProvider);

    return Scaffold(
      appBar: AppBar(title: Text(_tabs[_currentTabIndex].title)),
      body: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: const Color.fromRGBO(0, 0, 0, 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TabWidget(tabs: _tabs, onTabChanged: _onTabChanged),
            ),
          ),

          Container(
            height: 100,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: const Color.fromRGBO(0, 0, 0, 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Center(
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.4,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed:
                      minecraftState.isLaunching ||
                              selectedProfileId == null ||
                              profilesData == null
                          ? null
                          : () async {
                            final profile =
                                profilesData.profiles[selectedProfileId];
                            if (profile != null) {
                              await ref
                                  .read(profilesProvider.notifier)
                                  .updateProfileLastUsed(selectedProfileId);

                              await minecraftService.launchMinecraftAsService(
                                profile,
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('選択されたプロファイルが見つかりません'),
                                ),
                              );
                            }
                          },
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    elevation: 3.0,
                  ),
                  icon: null,
                  label: Stack(
                    children: [
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                      ),
                      if (minecraftState.isLaunching)
                        Positioned(
                          left: 0,
                          top: 0,
                          bottom: 0,
                          width:
                              MediaQuery.of(context).size.width *
                              0.4 *
                              minecraftState.progressValue,
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF2E7D32),
                              borderRadius: BorderRadius.horizontal(
                                left: const Radius.circular(8.0),
                                right:
                                    minecraftState.progressValue >= 0.99
                                        ? const Radius.circular(8.0)
                                        : Radius.zero,
                              ),
                            ),
                          ),
                        ),
                      if (!minecraftState.isLaunching)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color:
                                  selectedProfileId == null ||
                                          profilesData == null
                                      ? Colors.grey
                                      : Colors.green,
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                          ),
                        ),

                      Center(
                        child: Text(
                          selectedProfileId == null || profilesData == null
                              ? 'Please select a profile'
                              : minecraftState.isLaunching
                              ? minecraftState.progressText
                              : 'Launch ${profilesData.profiles[selectedProfileId]?.name ?? 'Unknown'}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: const [
                              Shadow(
                                color: Colors.black54,
                                offset: Offset(1.0, 1.0),
                                blurRadius: 3.0,
                              ),
                              Shadow(
                                color: Colors.black38,
                                offset: Offset(-1.0, -1.0),
                                blurRadius: 3.0,
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
