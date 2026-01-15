import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ai_music/ui/component/navigation/fullscreen_image_page.dart';

class AvatarContent extends StatelessWidget {
  final String photoUrl;

  const AvatarContent({super.key, required this.photoUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(50),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: GestureDetector(
        onTap: () {
          Navigator.of(context, rootNavigator: true).push(
            PageRouteBuilder(
              opaque: false,
              barrierColor: Colors.black54,
              pageBuilder: (_, __, ___) => FullscreenImagePage(
                imageUrl: photoUrl,
                tag: "avatar_drawer",
              ),
            ),
          );
        },
        child: Hero(
          tag: "avatar_drawer",
          child: ClipOval(
            child: CachedNetworkImage(
              imageUrl: photoUrl,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => Icon(
                Icons.account_circle,
                size: 50,
                color:
                    Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
