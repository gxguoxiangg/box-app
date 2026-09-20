/// Wiki 登录页面。
///
/// 当前页面完成用户名密码登录和临时失败锁定，登录成功后进入投稿页。
/// 忘记密码功能按需求暂不实现。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../home/data/tool_registry.dart';
import '../models/auth_session.dart';
import '../viewmodel/auth_viewmodel.dart';

/// Wiki 登录页面。
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AuthState authState = ref.watch(authControllerProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('登录'),
        leading: IconButton(
          tooltip: '返回',
          icon: const Icon(Icons.close_rounded),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.articleList);
            }
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 40),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const _WikiLogo(),
                const SizedBox(height: 16),
                Text(
                  'Wiki',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 12),
                Text(
                  '登录您的账号',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _usernameController,
                  enabled: !authState.isLoading && !authState.isLocked,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: '用户名',
                    hintText: '输入用户名',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                    border: OutlineInputBorder(),
                  ),
                  validator: (String? value) =>
                      value == null || value.trim().isEmpty ? '请输入用户名' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  enabled: !authState.isLoading && !authState.isLocked,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                  decoration: InputDecoration(
                    labelText: '密码',
                    hintText: '输入密码',
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    suffixIcon: IconButton(
                      tooltip: _obscurePassword ? '显示密码' : '隐藏密码',
                      icon: Icon(_obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                      onPressed: () => setState(
                        () => _obscurePassword = !_obscurePassword,
                      ),
                    ),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (String? value) =>
                      value == null || value.isEmpty ? '请输入密码' : null,
                ),
                if (authState.errorMessage != null) ...<Widget>[
                  const SizedBox(height: 8),
                  Text(
                    authState.errorMessage ?? '',
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 13,
                    ),
                  ),
                ],
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: null,
                    child: const Text('忘记密码？（功能暂不实现）'),
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: authState.isLoading || authState.isLocked
                      ? null
                      : _submit,
                  child: authState.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('下一步'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final AuthSession? session = await ref
        .read(authControllerProvider.notifier)
        .login(
          username: _usernameController.text.trim(),
          password: _passwordController.text,
        );
    if (!mounted || session == null) return;
    ref.read(authSessionProvider.notifier).setSession(session);
    context.go(AppRoutes.articleCreate);
  }
}

/// Wiki 登录页图标。
class _WikiLogo extends StatelessWidget {
  const _WikiLogo();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: const Color(0xFFE8EEFF),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(
          Icons.menu_book_rounded,
          size: 42,
          color: Color(0xFF3B6CF6),
        ),
      ),
    );
  }
}

/// 后期扩展：可接入安全存储和 Refresh Token；当前按需求只保留内存会话。
