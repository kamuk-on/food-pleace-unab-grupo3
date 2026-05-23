import 'package:flutter/material.dart';

/// Imagen remota con placeholder de carga y fallback ante error.
///
/// Si [imageUrl] es nulo o vacio, muestra directamente el fallback.
class RemoteImage extends StatelessWidget {
  const RemoteImage({
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.fallbackIcon = Icons.image_not_supported_outlined,
    super.key,
  });

  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final IconData fallbackIcon;

  @override
  Widget build(BuildContext context) {
    final Widget image = _buildImage(context);
    if (borderRadius == null) {
      return image;
    }
    return ClipRRect(borderRadius: borderRadius!, child: image);
  }

  Widget _buildImage(BuildContext context) {
    final String? url = imageUrl?.trim();
    if (url == null || url.isEmpty) {
      return _Fallback(width: width, height: height, icon: fallbackIcon);
    }

    return Image.network(
      url,
      width: width,
      height: height,
      fit: fit,
      loadingBuilder: (context, child, progress) {
        if (progress == null) {
          return child;
        }
        return _Placeholder(width: width, height: height);
      },
      errorBuilder: (context, error, stackTrace) {
        return _Fallback(width: width, height: height, icon: fallbackIcon);
      },
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({this.width, this.height});

  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }
}

class _Fallback extends StatelessWidget {
  const _Fallback({required this.icon, this.width, this.height});

  final IconData icon;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Container(
      width: width,
      height: height,
      color: colors.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Icon(icon, size: 32, color: colors.onSurfaceVariant),
    );
  }
}
