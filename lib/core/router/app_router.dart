import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/onboarding/screens/splash_screen.dart';
import '../../features/onboarding/screens/onboarding_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/home/screens/home_shell.dart';
import '../../features/home/screens/main_feed_screen.dart';
import '../../features/venues/screens/venues_screen.dart';
import '../../features/chat/screens/chat_list_screen.dart';
import '../../features/wallet/screens/wallet_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/feed/screens/post_detail_screen.dart';
import '../../features/venues/screens/venue_detail_screen.dart';
import '../../features/chat/screens/chat_room_screen.dart';
import '../../features/notifications/screens/notifications_screen.dart';
import '../../features/merchant/screens/merchant_screen.dart';
import '../../features/advertiser/screens/advertiser_screen.dart';
import '../../features/dj/screens/dj_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    routes: [
      GoRoute(path: '/splash',       builder: (c, s) => const SplashScreen()),
      GoRoute(path: '/onboarding',   builder: (c, s) => const OnboardingScreen()),
      GoRoute(path: '/login',        builder: (c, s) => const LoginScreen()),
      GoRoute(path: '/register',     builder: (c, s) => const RegisterScreen()),
      GoRoute(path: '/post/:id',     builder: (c, s) => PostDetailScreen(postId: s.pathParameters['id']!)),
      GoRoute(path: '/venue/:id',    builder: (c, s) => VenueDetailScreen(venueId: s.pathParameters['id']!)),
      GoRoute(path: '/chat/:id',     builder: (c, s) => ChatRoomScreen(roomId: s.pathParameters['id']!)),
      GoRoute(path: '/notifications', builder: (c, s) => const NotificationsScreen()),
      GoRoute(path: '/merchant',     builder: (c, s) => const MerchantScreen()),
      GoRoute(path: '/advertiser',   builder: (c, s) => const AdvertiserScreen()),
      GoRoute(path: '/dj-studio',    builder: (c, s) => const DJScreen()),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => HomeShell(child: child),
        routes: [
          GoRoute(path: '/',         builder: (c, s) => const MainFeedScreen()),
          GoRoute(path: '/venues',   builder: (c, s) => const VenuesScreen()),
          GoRoute(path: '/chat',     builder: (c, s) => const ChatListScreen()),
          GoRoute(path: '/wallet',   builder: (c, s) => const WalletScreen()),
          GoRoute(path: '/profile',  builder: (c, s) => const ProfileScreen()),
        ],
      ),
    ],
  );
});
