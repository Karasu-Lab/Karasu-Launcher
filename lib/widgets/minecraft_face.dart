import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:async';

/// Minecraftのスキンから顔部分のみを表示するウィジェット
class MinecraftFace extends StatelessWidget {
  final ImageProvider imageProvider;
  final double size;
  final bool showOverlay;
  
  // 画像キャッシュの実装
  static final Map<String, ui.Image> _imageCache = {};
  
  /// コンストラクタ
  ///
  /// [imageProvider] スキン画像のプロバイダー（ネットワーク、アセット、メモリ等）
  /// [size] 表示サイズ
  /// [showOverlay] 顔の前面レイヤーを表示するかどうか
  const MinecraftFace({
    super.key,
    required this.imageProvider,
    this.size = 64.0,
    this.showOverlay = true,
  });

  /// ネットワーク画像からMinecraftの顔を表示
  factory MinecraftFace.network(
    String url, {
    Key? key,
    double size = 64.0,
    bool showOverlay = true,
    Map<String, String>? headers,
  }) {
    return MinecraftFace(
      key: key,
      imageProvider: NetworkImage(url, headers: headers),
      size: size,
      showOverlay: showOverlay,
    );
  }

  /// アセット画像からMinecraftの顔を表示
  factory MinecraftFace.asset(
    String assetName, {
    Key? key,
    double size = 64.0,
    bool showOverlay = true,
    AssetBundle? bundle,
    String? package,
  }) {
    return MinecraftFace(
      key: key,
      imageProvider: AssetImage(assetName, bundle: bundle, package: package),
      size: size,
      showOverlay: showOverlay,
    );
  }

  /// メモリ内の画像データからMinecraftの顔を表示
  factory MinecraftFace.memory(
    Uint8List bytes, {
    Key? key,
    double size = 64.0,
    bool showOverlay = true,
    double scale = 1.0,
  }) {
    return MinecraftFace(
      key: key,
      imageProvider: MemoryImage(bytes, scale: scale),
      size: size,
      showOverlay: showOverlay,
    );
  }

  /// 画像プロバイダーからキャッシュキーを生成
  String _getCacheKey(ImageProvider provider) {
    if (provider is NetworkImage) {
      return 'network_${provider.url}';
    } else if (provider is AssetImage) {
      return 'asset_${provider.assetName}';
    } else if (provider is MemoryImage) {
      // メモリイメージの場合はバイト配列のハッシュコードを使用
      return 'memory_${provider.bytes.hashCode}';
    }
    // その他のプロバイダーの場合はオブジェクトのハッシュコード
    return 'other_${provider.hashCode}';
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: FutureBuilder<ui.Image>(
        future: _loadImage(imageProvider),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done &&
              snapshot.hasData) {
            return CustomPaint(
              painter: _MinecraftFacePainter(
                image: snapshot.data!,
                showOverlay: showOverlay,
              ),
              size: Size(size, size),
            );
          } else {
            // 画像読み込み中または失敗時のプレースホルダー
            return _buildPlaceholder();
          }
        },
      ),
    );
  }

  /// プレースホルダーウィジェットを構築
  Widget _buildPlaceholder() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.3),
        border: Border.all(color: Colors.grey),
      ),
    );
  }

  /// 画像を非同期で読み込む（キャッシュ対応）
  Future<ui.Image> _loadImage(ImageProvider provider) async {
    final String cacheKey = _getCacheKey(provider);
    
    // キャッシュにある場合はそれを返す
    if (_imageCache.containsKey(cacheKey)) {
      return _imageCache[cacheKey]!;
    }
    
    final Completer<ui.Image> completer = Completer<ui.Image>();
    final ImageStream stream = provider.resolve(ImageConfiguration.empty);

    final ImageStreamListener listener = ImageStreamListener(
      (ImageInfo info, bool _) {
        // 画像をキャッシュに保存
        _imageCache[cacheKey] = info.image;
        completer.complete(info.image);
      },
      onError: (dynamic exception, StackTrace? stackTrace) {
        completer.completeError(exception, stackTrace);
      },
    );

    stream.addListener(listener);
    return completer.future;
  }
  
  /// キャッシュをクリア
  static void clearCache() {
    _imageCache.clear();
  }
}

/// Minecraftの顔を描画するカスタムペインター
class _MinecraftFacePainter extends CustomPainter {
  final ui.Image image;
  final bool showOverlay;

  _MinecraftFacePainter({required this.image, required this.showOverlay});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint =
        Paint()..filterQuality = FilterQuality.none; // ピクセルアートをきれいに表示

    // 描画先のサイズに合わせてスケール
    final double scale = size.width / 8;
    canvas.scale(scale, scale);

    // レイヤー1（顔の背景部分）を描画 - 座標(8,9)から(16,16)
    final Rect faceRect = Rect.fromLTRB(8, 9, 16, 16);
    final Rect destRect = Rect.fromLTRB(0, 0, 8, 8);
    canvas.drawImageRect(image, faceRect, destRect, paint);

    // レイヤー2（顔の前面部分）を描画 - 座標(40,8)から(48,16)
    if (showOverlay) {
      final Rect overlayRect = Rect.fromLTRB(40, 8, 48, 16);
      canvas.drawImageRect(image, overlayRect, destRect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _MinecraftFacePainter oldDelegate) {
    return oldDelegate.image != image || oldDelegate.showOverlay != showOverlay;
  }
}
