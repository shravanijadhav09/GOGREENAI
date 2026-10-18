import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/app_provider.dart';
import 'core/theme/app_theme.dart';
import 'features/home/home_screen.dart';
import 'features/plants/plants_screen.dart';
import 'features/nurseries/nurseries_screen.dart';
import 'features/ai/ai_assistant_screen.dart';
import 'features/auth/screens/auth_gate.dart';
import 'providers/auth_provider.dart';

import 'providers/cart_provider.dart';
import 'providers/location_provider.dart';
import 'providers/owner_provider.dart';
import 'providers/reminder_provider.dart';
import 'providers/wishlist_provider.dart';
import 'providers/language_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const GoGreenApp());
}

class GoGreenApp extends StatelessWidget {
  const GoGreenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider()..tryRestoreSession(),
        ),
        ChangeNotifierProvider(
          create: (_) => AppProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => OwnerProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => CartProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => LocationProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => ReminderProvider()..loadReminders(),
        ),
        ChangeNotifierProvider(
          create: (_) => WishlistProvider()..loadWishlist(),
        ),
        ChangeNotifierProvider(
          create: (_) => LanguageProvider()..loadLanguage(),
        ),
      ],
      child: MaterialApp(
        title: 'GoGreen-AI',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const AuthGate(),
      ),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    PlantsScreen(),
    NurseriesScreen(),
    AiAssistantScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: lang.tr('nav_home'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.local_florist_outlined),
            selectedIcon: const Icon(Icons.local_florist),
            label: lang.tr('nav_plants'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.store_outlined),
            selectedIcon: const Icon(Icons.store),
            label: lang.tr('nav_nurseries'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.smart_toy_outlined),
            selectedIcon: const Icon(Icons.smart_toy),
            label: lang.tr('nav_ai'),
          ),
        ],
      ),
    );
  }
}
