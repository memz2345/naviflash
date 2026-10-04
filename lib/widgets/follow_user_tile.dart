                                    
  
                                       
                    
                                        
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:naviflash/services/bilibili_user_space_service.dart';
import 'package:naviflash/services/cached_image_provider.dart';
import 'package:naviflash/services/network_settings_service.dart';

               
class FollowUserTile extends StatelessWidget {
  final BiliRelationUser user;

                          
  final bool showRemoveFan;

                           
  final bool removing;
  final VoidCallback? onRemoveFan;

                        
  final bool showGroup;
  final VoidCallback? onManageGroup;

                                          
  final VoidCallback? onOpenSpace;

  const FollowUserTile({
    super.key,
    required this.user,
    this.showRemoveFan = false,
    this.removing = false,
    this.onRemoveFan,
    this.showGroup = false,
    this.onManageGroup,
    this.onOpenSpace,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final headers = NetworkSettingsService.instance.apiHeaders.isEmpty
        ? null
        : NetworkSettingsService.instance.apiHeaders;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: ClipOval(
        child: SizedBox(
          width: 44,
          height: 44,
          child: user.face.isNotEmpty
              ? Image(
                  image: CachedImageProvider(
                    BilibiliUserSpaceService.avatarUrl(user.face),
                    headers: headers,
                  ),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _placeholder(cs),
                )
              : _placeholder(cs),
        ),
      ),
      title: Text(
        user.uname.isEmpty ? '用户${user.mid}' : user.uname,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 14.5,
          fontWeight: FontWeight.w600,
          color: cs.onSurface,
        ),
      ),
      subtitle: user.sign.isNotEmpty
          ? Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                user.sign,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
              ),
            )
          : null,
      trailing: _trailing(cs),
      onTap: user.mid > 0
          ? () {
              HapticFeedback.lightImpact();
              onOpenSpace?.call();
            }
          : null,
    );
  }

  Widget? _trailing(ColorScheme cs) {
    final buttons = <Widget>[];
    if (showGroup && onManageGroup != null) {
      buttons.add(
        IconButton(
          tooltip: '分组',
          icon: Icon(
            Icons.folder_open_outlined,
            size: 20,
            color: cs.onSurfaceVariant,
          ),
          onPressed: onManageGroup,
        ),
      );
    }
    if (showRemoveFan) {
      buttons.add(
        IconButton(
          tooltip: '移除粉丝',
          icon: removing
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(
                  Icons.remove_circle_outline_outlined,
                  size: 20,
                  color: cs.onSurfaceVariant,
                ),
          onPressed: removing ? null : onRemoveFan,
        ),
      );
    }
    if (buttons.isEmpty) return null;
    return Row(mainAxisSize: MainAxisSize.min, children: buttons);
  }

  Widget _placeholder(ColorScheme cs) => Container(
    color: cs.surfaceContainerHighest,
    child: Icon(Icons.person_outline, size: 22, color: cs.onSurfaceVariant),
  );
}
