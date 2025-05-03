import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';

class MinecraftFace extends StatefulWidget {
  final ImageProvider imageProvider;
  final double size;
  final bool showOverlay;

  static final Map<String, ui.Image> _imageCache = {};

  const MinecraftFace({
    super.key,
    required this.imageProvider,
    this.size = 64.0,
    this.showOverlay = true,
  });

  factory MinecraftFace.network(
    String url, {
    Key? key,
    double size = 64.0,
    bool showOverlay = true,
    Map<String, String>? headers,
  }) {
    return MinecraftFace(
      key: key,
      imageProvider: CachedNetworkImageProvider(url, headers: headers),
      size: size,
      showOverlay: showOverlay,
    );
  }

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

  static void clearCache() {
    _imageCache.clear();
  }

  @override
  State<MinecraftFace> createState() => _MinecraftFaceState();
}

class _MinecraftFaceState extends State<MinecraftFace>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  ui.Image? _loadedImage;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _loadImage(widget.imageProvider);
  }

  @override
  void didUpdateWidget(MinecraftFace oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.imageProvider != widget.imageProvider) {
      _loadedImage = null;
      _controller.reset();
      _loadImage(widget.imageProvider);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadImage(ImageProvider provider) async {
    try {
      final String cacheKey = _getCacheKey(provider);

      if (MinecraftFace._imageCache.containsKey(cacheKey)) {
        _loadedImage = MinecraftFace._imageCache[cacheKey];
        if (mounted) {
          setState(() {});
          _controller.forward();
        }
        return;
      }

      final Completer<ui.Image> completer = Completer<ui.Image>();
      final ImageStream stream = provider.resolve(ImageConfiguration.empty);

      final ImageStreamListener listener = ImageStreamListener(
        (ImageInfo info, bool _) {
          MinecraftFace._imageCache[cacheKey] = info.image;
          _loadedImage = info.image;

          if (mounted) {
            setState(() {});

            _controller.forward();
          }

          completer.complete(info.image);
        },
        onError: (dynamic exception, StackTrace? stackTrace) {
          completer.completeError(exception, stackTrace);
        },
      );

      stream.addListener(listener);
    } catch (e) {
      print('Error loading image: $e');
    }
  }

  String _getCacheKey(ImageProvider provider) {
    if (provider is NetworkImage) {
      return 'network_${provider.url}';
    } else if (provider is CachedNetworkImageProvider) {
      return 'cached_network_${provider.url}';
    } else if (provider is AssetImage) {
      return 'asset_${provider.assetName}';
    } else if (provider is MemoryImage) {
      return 'memory_${provider.bytes.hashCode}';
    }

    return 'other_${provider.hashCode}';
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        children: [
          _buildPlaceholder(),

          if (_loadedImage != null)
            AnimatedBuilder(
              animation: _opacityAnimation,
              builder: (context, child) {
                return Opacity(opacity: _opacityAnimation.value, child: child);
              },
              child: CustomPaint(
                painter: _MinecraftFacePainter(
                  image: _loadedImage!,
                  showOverlay: widget.showOverlay,
                ),
                size: Size(widget.size, widget.size),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.3),
        border: Border.all(color: Colors.grey),
      ),
    );
  }
}

class _MinecraftFacePainter extends CustomPainter {
  final ui.Image image;
  final bool showOverlay;

  _MinecraftFacePainter({required this.image, required this.showOverlay});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..filterQuality = FilterQuality.none;

    final double scale = size.width / 8;
    canvas.scale(scale, scale);

    final Rect faceRect = Rect.fromLTRB(8, 9, 16, 16);
    final Rect destRect = Rect.fromLTRB(0, 0, 8, 8);
    canvas.drawImageRect(image, faceRect, destRect, paint);

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
