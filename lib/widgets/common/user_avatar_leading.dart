import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth/auth_viewmodel.dart';

/// UserAvatarLeading
///
/// Một widget tái sử dụng cho phần leading của AppBar,
/// hiển thị avatar của user hiện tại và mở drawer khi tap.
class UserAvatarLeading extends StatelessWidget {
  const UserAvatarLeading({super.key});

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);

    return Consumer<AuthViewModel>(
      builder: (context, authViewModel, child) {
        final user = authViewModel.currentUser;
        final avatar = user?.avatar;
        final name = user?.name ?? 'User';

        return GestureDetector(
          onTap: () {
            Scaffold.of(context).openDrawer();
          },
          child: Padding(
            padding: const EdgeInsets.only(
              left: 16,
              top: 8,
              bottom: 8,
            ),
            child: CircleAvatar(
              backgroundColor: themeData.colorScheme.primary,
              backgroundImage:
                  avatar != null && avatar.isNotEmpty
                      ? NetworkImage(avatar)
                      : null,
              child:
                  avatar == null || avatar.isEmpty
                      ? Text(
                        name.isNotEmpty
                            ? name[0].toUpperCase()
                            : 'U',
                        style: TextStyle(
                          color: themeData.colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                      : null,
            ),
          ),
        );
      },
    );
  }
}
