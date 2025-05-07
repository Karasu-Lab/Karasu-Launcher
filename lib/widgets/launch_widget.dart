import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:karasu_launcher/providers/minecraft_state_provider.dart';
import 'package:karasu_launcher/providers/profiles_provider.dart';
import 'package:karasu_launcher/services/minecraft_service.dart';
import 'package:karasu_launcher/providers/authentication_provider.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

class LaunchWidget extends ConsumerStatefulWidget {
  const LaunchWidget({
    super.key,
    this.child,
    this.onPressed,
    this.width,
    this.height = 50,
    this.onDuplicateWarning,
    this.profileId,
    this.buttonColor,
    this.progressColor,
    this.buttonStyle,
    this.textStyle,
    this.borderRadius,
    this.customButtonBuilder,
    this.containerBackgroundColor,
    this.activeButtonColor,
    this.inactiveButtonColor,
    this.buttonElevation,
    this.allowRelaunching = true,
    this.runningWidget,
    this.mouseCursor,
  });

  final Widget? child;
  final VoidCallback? onPressed;
  final double? width;
  final double height;
  final Future<bool?> Function()? onDuplicateWarning;
  final String? profileId;
  final Color? buttonColor;
  final Color? progressColor;
  final ButtonStyle? buttonStyle;
  final TextStyle? textStyle;
  final BorderRadius? borderRadius;
  final Color? containerBackgroundColor;
  final Color? activeButtonColor;
  final Color? inactiveButtonColor;
  final double? buttonElevation;
  final bool allowRelaunching;
  final Widget? runningWidget;
  final MouseCursor? mouseCursor;

  final Widget Function(
    BuildContext context,
    bool isEnabled,
    VoidCallback? onPressed,
    Widget child,
  )?
  customButtonBuilder;

  @override
  ConsumerState<LaunchWidget> createState() => _LaunchWidgetState();
}

class _LaunchWidgetState extends ConsumerState<LaunchWidget> {
  @override
  Widget build(BuildContext context) {
    final minecraftState = ref.watch(minecraftStateProvider);
    final minecraftStateNotifier = ref.watch(minecraftStateProvider.notifier);
    final minecraftService = ref.read(minecraftServiceProvider);

    final profilesData = ref.watch(profilesProvider);
    final selectedProfileId =
        widget.profileId ?? ref.watch(selectedProfileProvider);
    final activeAccount = ref.watch(activeAccountProvider);

    if (widget.child != null) {
      return MouseRegion(
        cursor: widget.mouseCursor ?? SystemMouseCursors.click,
        child: GestureDetector(onTap: widget.onPressed, child: widget.child!),
      );
    }

    final String? profileId =
        selectedProfileId != null && profilesData != null
            ? (profilesData.profiles[selectedProfileId]?.id ??
                profilesData.profiles[selectedProfileId]?.gameDir ??
                'unknown')
            : null;
    final String userId = activeAccount?.id ?? 'offline-user';
    final bool isProfileRunning =
        profileId != null &&
        minecraftStateNotifier.isUserLaunchingProfile(userId, profileId);

    if (isProfileRunning &&
        !widget.allowRelaunching &&
        widget.runningWidget != null) {
      return widget.runningWidget!;
    }

    final bool isEnabled =
        !minecraftState.isLaunching &&
        selectedProfileId != null &&
        profilesData != null &&
        (widget.allowRelaunching || !isProfileRunning);

    final profile =
        selectedProfileId != null && profilesData != null
            ? profilesData.profiles[selectedProfileId]
            : null;

    Future<void> handleLaunch() async {
      if (profile != null) {
        final profileId = profile.id ?? profile.gameDir ?? 'unknown';
        final userId = activeAccount?.id ?? 'offline-user';

        if (minecraftStateNotifier.isUserLaunchingProfile(userId, profileId)) {
          final shouldLaunch = await _showDuplicateProfileWarningDialog();
          if (shouldLaunch != true) return;
        }

        await ref
            .read(profilesProvider.notifier)
            .updateProfileLastUsed(selectedProfileId!);

        minecraftStateNotifier.setUserLaunchingProfile(
          userId,
          profileId,
          isOfflineUser: activeAccount == null,
        );

        await minecraftService.launchMinecraftAsService(profile);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              FlutterI18n.translate(context, 'homePage.error.profileNotFound'),
            ),
          ),
        );
      }
    }

    String getButtonText() {
      if (selectedProfileId == null || profilesData == null) {
        return FlutterI18n.translate(context, 'homePage.button.selectProfile');
      } else if (minecraftState.isLaunching &&
          minecraftState.isGlobalLaunching) {
        return minecraftState.progressText;
      } else if (isProfileRunning && !widget.allowRelaunching) {
        return FlutterI18n.translate(
          context,
          'homePage.button.alreadyRunning',
          translationParams: {"name": profile?.name ?? 'Unknown'},
        );
      } else {
        return FlutterI18n.translate(
          context,
          'homePage.button.launch',
          translationParams: {"name": profile?.name ?? 'Unknown'},
        );
      }
    }

    final defaultTextStyle = TextStyle(
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
    );

    final Color baseBackgroundColor =
        widget.containerBackgroundColor ?? Colors.grey[300] ?? Colors.grey;
    final Color activeColor =
        widget.activeButtonColor ?? widget.buttonColor ?? Colors.green;
    final Color inactiveColor = widget.inactiveButtonColor ?? Colors.grey;
    final Color currentButtonColor = isEnabled ? activeColor : inactiveColor;
    final Color progressBarColor =
        widget.progressColor ?? const Color(0xFF2E7D32);

    final buttonChild = Stack(
      children: [
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              color: baseBackgroundColor,
              borderRadius: widget.borderRadius ?? BorderRadius.circular(8.0),
            ),
          ),
        ),

        if (minecraftState.isLaunching)
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width:
                (widget.width ?? MediaQuery.of(context).size.width * 0.4) *
                minecraftState.progressValue.clamp(0.0, 1.0),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              decoration: BoxDecoration(
                color: progressBarColor,
                borderRadius: BorderRadius.horizontal(
                  left:
                      (widget.borderRadius?.topLeft ??
                          const Radius.circular(8.0)),
                  right:
                      minecraftState.progressValue >= 0.99
                          ? (widget.borderRadius?.topRight ??
                              const Radius.circular(8.0))
                          : Radius.zero,
                ),
              ),
            ),
          ),

        if (!minecraftState.isLaunching)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: currentButtonColor,
                borderRadius: widget.borderRadius ?? BorderRadius.circular(8.0),
              ),
            ),
          ),

        Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  getButtonText(),
                  style: widget.textStyle ?? defaultTextStyle,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    if (widget.customButtonBuilder != null) {
      return SizedBox(
        width: widget.width ?? MediaQuery.of(context).size.width * 0.4,
        height: widget.height,
        child: MouseRegion(
          cursor:
              widget.mouseCursor ??
              (isEnabled
                  ? SystemMouseCursors.click
                  : SystemMouseCursors.forbidden),
          child: widget.customButtonBuilder!(
            context,
            isEnabled,
            isEnabled ? handleLaunch : null,
            buttonChild,
          ),
        ),
      );
    }

    return SizedBox(
      width: widget.width ?? MediaQuery.of(context).size.width * 0.4,
      height: widget.height,
      child: ElevatedButton.icon(
        onPressed: isEnabled ? handleLaunch : null,
        style:
            widget.buttonStyle ??
            ElevatedButton.styleFrom(
              padding: EdgeInsets.zero,
              foregroundColor: Colors.white,
              backgroundColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: widget.borderRadius ?? BorderRadius.circular(8.0),
              ),
              elevation: widget.buttonElevation ?? 3.0,
            ).copyWith(
              mouseCursor: WidgetStateProperty.resolveWith<MouseCursor>(
                (states) =>
                    widget.mouseCursor ??
                    (isEnabled
                        ? SystemMouseCursors.click
                        : SystemMouseCursors.forbidden),
              ),
            ),
        icon: null,
        label: buttonChild,
      ),
    );
  }

  Future<bool?> _showDuplicateProfileWarningDialog() {
    if (widget.onDuplicateWarning != null) {
      return widget.onDuplicateWarning!();
    }

    return showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              FlutterI18n.translate(context, 'homePage.warning.title'),
            ),
            content: Text(
              FlutterI18n.translate(
                context,
                'homePage.warning.duplicateProfile',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  FlutterI18n.translate(context, 'homePage.actions.cancel'),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(
                  FlutterI18n.translate(context, 'homePage.actions.launch'),
                ),
              ),
            ],
          ),
    );
  }
}
