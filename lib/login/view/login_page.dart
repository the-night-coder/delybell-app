import 'package:delybell/core/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/session_manager.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../signup/view/sign_up_page.dart';
import '../bloc/login_bloc.dart';
import '../data/login_repository.dart';
import '../models/login_type.dart';
import 'forgot_password_page.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => LoginBloc(context.read<LoginRepository>()),
      child: const _LoginView(),
    );
  }
}

class _LoginView extends StatelessWidget {
  const _LoginView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _LoginSegmentedControl(),
                  SizedBox(height: 32),
                  Text(
                    'Sign In',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Enter your credentials below to sign into your account.',
                    style: TextStyle(
                      color: Color(0xFF4B5563),
                      fontSize: 15,
                    ),
                  ),
                  SizedBox(height: 32),
                  _LoginForm(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginSegmentedControl extends StatelessWidget {
  const _LoginSegmentedControl();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LoginBloc, LoginState>(
      buildWhen: (previous, current) => previous.loginType != current.loginType,
      builder: (context, state) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFDDDEEA)),
          ),
          child: Row(
            children: LoginType.values.map((loginType) {
              final isActive = state.loginType == loginType;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    context.read<LoginBloc>().add(LoginTypeChanged(loginType));
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: isActive ? const Color(0xFF5B21B6) : Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: loginType == LoginType.user
                            ? const Radius.circular(16)
                            : Radius.zero,
                        bottomLeft: loginType == LoginType.user
                            ? const Radius.circular(16)
                            : Radius.zero,
                        topRight: loginType == LoginType.corporate
                            ? const Radius.circular(16)
                            : Radius.zero,
                        bottomRight: loginType == LoginType.corporate
                            ? const Radius.circular(16)
                            : Radius.zero,
                      ),
                    ),
                    child: Text(
                      loginType.title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isActive ? Colors.white : const Color(0xFF374151),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

class _LoginForm extends StatefulWidget {
  const _LoginForm();

  @override
  State<_LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<_LoginForm> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_handleEmailChanged);
    _passwordController.addListener(_handlePasswordChanged);
  }

  @override
  void dispose() {
    _emailController
      ..removeListener(_handleEmailChanged)
      ..dispose();
    _passwordController
      ..removeListener(_handlePasswordChanged)
      ..dispose();
    super.dispose();
  }

  void _handleEmailChanged() {
    context.read<LoginBloc>().add(LoginEmailChanged(_emailController.text));
  }

  void _handlePasswordChanged() {
    context
        .read<LoginBloc>()
        .add(LoginPasswordChanged(_passwordController.text));
  }

  void _handleSubmit() {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;
    context.read<LoginBloc>().add(const LoginSubmitted());
  }
  

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return BlocListener<LoginBloc, LoginState>(
      listener: (context, state) async {
        if (state.status == LoginStatus.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                state.loginResult?.message ?? 'Signed in successfully.',
              ),
            ),
          );
          final result = state.loginResult;
          if (result != null) {
            await SessionManager().saveLogin(result);
            if (!mounted) return;
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => DashboardPage(
                  loginResponse: result,
                  onLogout: (ctx) async {
                    await SessionManager().clearLogin();
                    Navigator.of(ctx).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginPage()),
                      (_) => false,
                    );
                  },
                ),
              ),
            );
          }
        } else if (state.status == LoginStatus.failure &&
            state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: Colors.red.shade600,
            ),
          );
        }
      },
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.person_outline),
                suffixText: '(required)',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Email is required';
                }
                if (!value.contains('@')) {
                  return 'Enter a valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            BlocBuilder<LoginBloc, LoginState>(
              buildWhen: (previous, current) =>
                  previous.isPasswordVisible != current.isPasswordVisible,
              builder: (context, state) {
                return TextFormField(
                  controller: _passwordController,
                  obscureText: !state.isPasswordVisible,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixText: '(required)',
                    suffixIcon: IconButton(
                      onPressed: () {
                        context
                            .read<LoginBloc>()
                            .add(const LoginPasswordVisibilityToggled());
                      },
                      icon: Icon(
                        state.isPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Password is required';
                    }
                    if (value.length < 6) {
                      return 'Enter at least 6 characters';
                    }
                    return null;
                  },
                );
              },
            ),
            const SizedBox(height: 28),
            BlocBuilder<LoginBloc, LoginState>(
              buildWhen: (previous, current) =>
                  previous.loginType != current.loginType ||
                  previous.status != current.status,
              builder: (context, state) {
                final bool isLoading = state.status == LoginStatus.loading;
                return SizedBox(
                  height: 50,
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: colors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(state.loginType.buttonLabel),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ForgotPasswordPage(),
                      ),
                    );
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF0F52BA),
                  ),
                  child: const Text('Forgot Password?'),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const SignUpPage(),
                      ),
                    );
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF0F52BA),
                  ),
                  child: const Text('Create Account'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
