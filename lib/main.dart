import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config.dart';
import 'models.dart';
import 'repository.dart';
import 'screens/account_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/guest/browse_screen.dart';
import 'screens/guest/my_bookings_screen.dart';
import 'screens/owner/booking_requests_screen.dart';
import 'screens/owner/my_listings_screen.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (supabaseUrl.isEmpty || supabasePublishableKey.isEmpty) {
    runApp(const _MissingConfigApp());
    return;
  }
  await Supabase.initialize(
    url: supabaseUrl,
    publishableKey: supabasePublishableKey,
  );
  runApp(const StaycationApp());
}

class StaycationApp extends StatelessWidget {
  const StaycationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StaycationPro',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: const AuthGate(),
    );
  }
}

/// Shows the sign-in screen or the guest/owner home based on auth state.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: supabase.auth.onAuthStateChange,
      builder: (context, _) {
        final user = supabase.auth.currentUser;
        if (user == null) return const AuthScreen();
        return _ProfileLoader(key: ValueKey(user.id));
      },
    );
  }
}

class _ProfileLoader extends StatefulWidget {
  const _ProfileLoader({super.key});

  @override
  State<_ProfileLoader> createState() => _ProfileLoaderState();
}

class _ProfileLoaderState extends State<_ProfileLoader> {
  late Future<Profile> _profile = fetchProfile();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Profile>(
      future: _profile,
      builder: (context, snap) {
        if (snap.hasError) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(errorMessage(snap.error!)),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => setState(() => _profile = fetchProfile()),
                    child: const Text('Retry'),
                  ),
                  TextButton(
                    onPressed: () => supabase.auth.signOut(),
                    child: const Text('Sign out'),
                  ),
                ],
              ),
            ),
          );
        }
        if (!snap.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return HomeShell(profile: snap.data!);
      },
    );
  }
}

class HomeShell extends StatefulWidget {
  final Profile profile;

  const HomeShell({super.key, required this.profile});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final isOwner = widget.profile.isOwner;
    final pages = isOwner
        ? const [BookingRequestsScreen(), MyListingsScreen()]
        : const [BrowseScreen(), MyBookingsScreen()];
    final destinations = isOwner
        ? const [
            NavigationDestination(
              icon: Icon(Icons.space_dashboard_outlined),
              selectedIcon: Icon(Icons.space_dashboard_rounded),
              label: 'Dashboard',
            ),
            NavigationDestination(
              icon: Icon(Icons.home_work_outlined),
              selectedIcon: Icon(Icons.home_work_rounded),
              label: 'My Places',
            ),
          ]
        : const [
            NavigationDestination(
              icon: Icon(Icons.explore_outlined),
              selectedIcon: Icon(Icons.explore_rounded),
              label: 'Explore',
            ),
            NavigationDestination(
              icon: Icon(Icons.luggage_outlined),
              selectedIcon: Icon(Icons.luggage_rounded),
              label: 'My Trips',
            ),
          ];

    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          ...pages,
          AccountScreen(profile: widget.profile),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.line)),
        ),
        child: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: [
            ...destinations,
            const NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Account',
            ),
          ],
        ),
      ),
    );
  }
}

class _MissingConfigApp extends StatelessWidget {
  const _MissingConfigApp();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: Padding(
          padding: EdgeInsets.all(24),
          child: Center(
            child: Text(
              'Supabase is not configured.\n\n'
              'Copy env.example.json to env.json, fill in your project URL '
              'and publishable key, then run:\n\n'
              'flutter run --dart-define-from-file=env.json',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
