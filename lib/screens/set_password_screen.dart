import 'package:flutter/material.dart';
import 'package:share_lib/share_lib_auth.dart';
import '../app_auth_provider.dart';
import '../theme/app_theme.dart';

/// 소셜 로그인 계정에 이메일/비밀번호를 연결하거나, 기존 비밀번호를 변경합니다.
class SetPasswordScreen extends StatefulWidget {
  const SetPasswordScreen({super.key});

  @override
  State<SetPasswordScreen> createState() => _SetPasswordScreenState();
}

class _SetPasswordScreenState extends State<SetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isSubmitting = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  bool get _isChange => AppAuthProvider.shared.hasPasswordProvider;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      await AppAuthProvider.shared.setOrUpdatePassword(
        _passwordController.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isChange ? '비밀번호가 변경되었습니다.' : '비밀번호가 등록되었습니다. 이제 이메일로도 로그인할 수 있습니다.',
          ),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      final message = _errorMessage(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String _errorMessage(Object error) {
    if (error is LocalizedException) {
      switch (error.localizationKey) {
        case 'weakPassword':
          return '비밀번호가 너무 약합니다. 6자 이상 입력해 주세요.';
        case 'requiresRecentLogin':
          return '보안을 위해 다시 로그인한 뒤 비밀번호를 변경해 주세요.';
        case 'emailRequiredForPassword':
          return '이 계정에는 이메일이 없어 비밀번호를 설정할 수 없습니다.';
        case 'emailAlreadyInUseSignUp':
          return '이미 다른 방식으로 연결된 이메일입니다.';
        case 'passwordSetFailed':
          return '비밀번호 설정에 실패했습니다: ${error.parameters?['message'] ?? ''}';
        default:
          return error.localizationKey;
      }
    }
    return error.toString();
  }

  @override
  Widget build(BuildContext context) {
    final email = AppAuthProvider.shared.currentEmail ?? '';
    final title = _isChange ? '비밀번호 변경' : '비밀번호 설정';

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.translucent,
      child: Scaffold(
        appBar: AppBar(
        title: Text(title),
        backgroundColor: AppTheme.backgroundColor,
        foregroundColor: AppTheme.textPrimaryColor,
        elevation: 0,
        ),
        backgroundColor: AppTheme.backgroundColor,
        body: Form(
          key: _formKey,
          child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              _isChange
                  ? '이메일 로그인에 사용할 비밀번호를 변경합니다.'
                  : '소셜 로그인 계정에 비밀번호를 등록하면, 같은 이메일로도 로그인할 수 있습니다.',
              style: TextStyle(
                fontSize: 15,
                height: 1.45,
                color: AppTheme.textSecondaryColor,
              ),
            ),
            if (email.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(
                '이메일',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                email,
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
            ],
            const SizedBox(height: 24),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: '비밀번호',
                hintText: '6자 이상',
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  onPressed: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.length < 6) {
                  return '비밀번호는 6자 이상이어야 합니다.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _confirmController,
              obscureText: _obscureConfirm,
              decoration: InputDecoration(
                labelText: '비밀번호 확인',
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirm
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  onPressed: () {
                    setState(() => _obscureConfirm = !_obscureConfirm);
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value != _passwordController.text) {
                  return '비밀번호가 일치하지 않습니다.';
                }
                return null;
              },
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(_isChange ? '비밀번호 변경' : '비밀번호 등록'),
              ),
            ),
          ],
          ),
        ),
      ),
    );
  }
}
