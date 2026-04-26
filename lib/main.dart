import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';

import 'core/session_manager.dart';
import 'core/app_colors.dart';
import 'features/dashboard/data/dashboard_repository_impl.dart';
import 'features/dashboard/domain/repositories/dashboard_repository.dart';
import 'features/dashboard/presentation/pages/dashboard_page.dart';
import 'features/invoices/data/invoices_repository_impl.dart';
import 'features/invoices/domain/repositories/invoices_repository.dart';
import 'features/orders/data/orders_repository_impl.dart';
import 'features/orders/domain/repositories/orders_repository.dart';
import 'login/data/login_repository.dart';
import 'login/models/login_response.dart';
import 'login/view/login_page.dart';
import 'signup/data/sign_up_repository.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );
  runApp(const DelybellApp());
}

class DelybellApp extends StatelessWidget {
  const DelybellApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(create: (_) => LoginRepository()),
        RepositoryProvider(create: (_) => SignUpRepository()),
        RepositoryProvider<DashboardRepository>(
          create: (_) => DashboardRepositoryImpl(),
        ),
        RepositoryProvider<OrdersRepository>(
          create: (_) => OrdersRepositoryImpl(),
        ),
        RepositoryProvider<InvoicesRepository>(
          create: (_) => InvoicesRepositoryImpl(),
        ),
      ],
      child: MaterialApp(
        title: 'Delybell',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF66258E),
            brightness: Brightness.light,
            primary: const Color(0xFF66258E),
            surfaceContainer: Colors.white,
          ),
          extensions: const [
            AppColors(
              primary: Color(0xFF66258E),
              primarySoft: Color(0xFFEDE9FE),
              border: Color(0xFFE5E7EB),
              surface: Colors.white,
              mutedText: Color(0xFF6B7280),
              danger: Color(0xFFE11D48),
              success: Color(0xFF16A34A),
            ),
          ],
          appBarTheme: AppBarTheme(backgroundColor: Colors.white),
          primaryColor: const Color(0xFF66258E),
          scaffoldBackgroundColor: const Color(0xFFF0F2F8),
          chipTheme: ChipThemeData(
            backgroundColor: Colors.white,
            selectedColor: const Color(0xFF66258E),
            labelStyle: const TextStyle(
              color: Color(0xFF66258E),
              fontWeight: FontWeight.w600,
            ),
          ),
          inputDecorationTheme: const InputDecorationTheme(
            border: UnderlineInputBorder(),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF0A26D8), width: 2),
            ),
          ),
        ),
        home: const SplashGate(),
      ),
    );
  }
}

class SplashGate extends StatefulWidget {
  const SplashGate({super.key});

  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate> {
  bool _showLogin = false;

  @override
  void initState() {
    super.initState();
    _attemptAutoLogin();
  }

  Future<void> _attemptAutoLogin() async {
    final savedSession = await SessionManager().loadLogin();
    print(savedSession?.user.toJson());
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;
    if (savedSession != null) {
      _navigateToDashboard(savedSession);
    } else {
      setState(() => _showLogin = true);
    }
  }

  void _navigateToDashboard(LoginResponse response) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => DashboardPage(
          loginResponse: response,
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

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 600),
      child: _showLogin ? const LoginPage() : const _SplashScreen(),
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Shimmer.fromColors(
              baseColor: const Color(0xFF66258E),
              highlightColor: const Color(0xFFB794F6),
              period: const Duration(seconds: 2),
              child: SizedBox(
                width: 200,
                child: Image.asset(
                  'assets/icons/delybell.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 24),
          
            const Text(
              'Delivery at your fingertips',
              style: TextStyle(
                color: Color(0xFF4B5563),
                fontSize: 14,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
