import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'config/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/profile_provider.dart';
import 'providers/booking_provider.dart';
import 'providers/settlement_provider.dart';
import 'providers/wallet_provider.dart';
import 'services/api_client.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/forgot_password_screen.dart';
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
import 'screens/support_chat_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const AirveatWorkerApp());
}

class AirveatWorkerApp extends StatefulWidget {
  const AirveatWorkerApp({super.key});

  @override
  State<AirveatWorkerApp> createState() => _AirveatWorkerAppState();
}

class _AirveatWorkerAppState extends State<AirveatWorkerApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // The OS can suspend/kill the socket connection while the app is
    // backgrounded; plain Socket.IO reconnection can't recover from that
    // since it relies on the process actively running. Force a fresh
    // connect when the app comes back to the foreground so chat/support
    // messages sent during the gap don't require a manual app relaunch.
    if (state == AppLifecycleState.resumed) {
      _reconnectSocketIfLoggedIn();
    }
  }

  Future<void> _reconnectSocketIfLoggedIn() async {
    final userData = await ApiClient.getUserData();
    final userId = (userData?['id'] ?? userData?['_id'])?.toString();
    if (userId == null || userId.isEmpty || !mounted) return;
    context.read<BookingProvider>().connectSocket(userId);
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => BookingProvider()),
        ChangeNotifierProvider(create: (_) => SettlementProvider()),
        ChangeNotifierProvider(create: (_) => WalletProvider()),
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
          '/forgot-password': (context) => const ForgotPasswordScreen(),
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
          '/support-chat': (context) => const SupportChatScreen(),
        },
      ),
    );
  }
}
