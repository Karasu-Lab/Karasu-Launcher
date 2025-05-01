import 'package:flutter/material.dart';
import 'package:karasu_launcher/models/auth/minecraft_profile.dart';
import 'package:karasu_launcher/models/auth/account.dart';

/// ユーザーのMinecraftアイコンを表示するウィジェット
class UserIcon extends StatelessWidget {
  /// 表示するアカウント情報
  final Account? account;

  /// アイコンのサイズ
  final double size;

  /// アイコンの枠線の半径
  final double borderRadius;

  /// タップ時の処理
  final VoidCallback? onTap;

  const UserIcon({
    super.key,
    this.account,
    this.size = 32,
    this.borderRadius = 16,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // アカウント情報に基づいたアバターウィジェットを構築
    Widget avatarWidget = _buildDefaultIcon(context);

    // アクティブアカウントが存在する場合の表示処理
    if (account != null) {
      // Minecraft認証がされているかチェック
      if (account!.hasValidMinecraftToken) {
        // Minecraft認証済みで、スキンURLが存在する場合はそのアバターを表示
        final profile = account!.profile;
        if (profile?.skinUrl != null) {
          avatarWidget = _buildProfileAvatar(context, profile!);
        } else {
          // スキンURLがない場合はデフォルトのMinecraftアイコンを表示
          avatarWidget = _buildMinecraftIcon(context);
        }
      } else {
        // Minecraft認証がされていない場合はXboxアイコンを表示
        avatarWidget = _buildXboxIcon(context);
      }
    }

    // タップ可能かどうかに応じてウィジェットを構築
    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: Padding(padding: const EdgeInsets.all(4.0), child: avatarWidget),
      );
    } else {
      return avatarWidget;
    }
  }

  /// スキンURLが存在する場合のアバターを作成
  Widget _buildProfileAvatar(BuildContext context, MinecraftProfile profile) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Image.network(
        profile.skinUrl!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder:
            (context, error, stackTrace) => _buildDefaultIcon(context),
      ),
    );
  }

  /// デフォルトのアイコンを作成
  Widget _buildDefaultIcon(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Icon(
        Icons.account_circle,
        color: Colors.white70,
        size: size,
      ),
    );
  }

  /// Minecraft用アイコンを作成
  Widget _buildMinecraftIcon(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Icon(Icons.account_box, color: Colors.white70, size: size * 0.75),
    );
  }

  /// Xbox用アイコンを作成
  Widget _buildXboxIcon(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Icon(
        Icons.sports_esports,
        color: Colors.white70,
        size: size
      ),
    );
  }
}
