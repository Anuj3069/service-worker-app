import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'config/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/profile_provider.dart';
import 'providers/booking_provider.dart';
import 'providers/settlement_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/create_profile_screen.dart';
import 'screens/kyc_upload_screen.dart';
import 'screens/kyc_pending_screen.dart';
import 'screens/kyc_rejected_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/settlement_screen.dart';
import 'screens/settlement_detail_screen.dart';
import 'screens/bank_details_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const AirveatWorkerApp());
}

class AirveatWorkerApp extends StatelessWidget {
  const AirveatWorkerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => BookingProvider()),
        ChangeNotifierProvider(create: (_) => SettlementProvider()),
      ],
      child: MaterialApp(
        title: 'Airveat Worker',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        navigatorKey: navigatorKey,
        initialRoute: '/',
        routes: {
          '/': (context) => const SplashScreen(),
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/create-profile': (context) => const CreateProfileScreen(),
          '/kyc-upload': (context) => const KycUploadScreen(),
          '/kyc-pending': (context) => const KycPendingScreen(),
          '/kyc-rejected': (context) => const KycRejectedScreen(),
          '/dashboard': (context) => const DashboardScreen(),
          '/chat': (context) => const ChatScreen(),
          '/settlements': (context) => const SettlementScreen(),
          '/settlement-detail': (context) => const SettlementDetailScreen(),
          '/bank-details': (context) => const BankDetailsScreen(),
        },
      ),
    );
  }
}
