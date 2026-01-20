import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_lib/share_lib_auth.dart';
import '../models/user.dart';
import '../theme/app_theme.dart';
import '../config/auth_config.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider<User>>(
      builder: (context, authProvider, child) {
        if (!authProvider.isInitialized && !authProvider.isInitializing) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!context.mounted) return;
            context.read<AuthProvider<User>>().initialize();
          });
        }

        // 로그인 안 되어 있으면 안내 메시지
        if (!authProvider.isAuthenticated) {
          return LoginRequiredScreen(
            config: authConfig,
            authScreenBuilder: (context) =>
                AuthScreen<User>(config: authConfig),
          );
        }

        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryColor.withOpacity(0.1),
                      AppTheme.primaryColor.withOpacity(0.05),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.forum_rounded,
                  size: 64,
                  color: AppTheme.primaryColor.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                '채팅 목록이 없습니다',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '승인된 모임의 채팅방이 여기에 표시됩니다',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textTertiaryColor,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }
}
