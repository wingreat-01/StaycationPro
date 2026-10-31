import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models.dart';
import '../../repository.dart';
import '../../theme.dart';
import '../../widgets.dart';

final _pesoCompact = NumberFormat.compactCurrency(symbol: '₱');

class BookingRequestsScreen extends StatefulWidget {
  const BookingRequestsScreen({super.key});

  @override
  State<BookingRequestsScreen> createState() => _BookingRequestsScreenState();
}

class _BookingRequestsScreenState extends State<BookingRequestsScreen> {
  late Future<List<Booking>> _bookings = fetchOwnerBookings();
  late final RealtimeChannel _channel;
  final Set<String> _busyIds = {};

  @override
  void initState() {
    super.initState();
    // Refresh whenever a booking for one of this owner's listings changes.
    _channel = supabase
        .channel('owner-bookings')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'bookings',
          callback: (_) {
            if (mounted) _reload();
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    supabase.removeChannel(_channel);
    super.dispose();
  }

  Future<void> _reload() async {
    final future = fetchOwnerBookings();
    setState(() => _bookings = future);
    await future.catchError((_) => <Booking>[]);
  }

  Future<void> _respond(Booking b, {required bool accept}) async {
    if (!accept) {
      final ok = await confirmDialog(
        context,
        'Decline request?',
        '${b.guestName ?? 'The guest'} will be notified that their request was declined.',
        confirm: 'Decline',
      );
      if (!ok || !mounted) return;
    }
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busyIds.add(b.id));
    try {
      await respondToBooking(b.id, accept: accept);
      messenger.showSnackBar(
        SnackBar(
          content: Text(accept ? 'Booking confirmed.' : 'Request declined.'),
        ),
      );
      await _reload();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(errorMessage(e))));
    } finally {
      if (mounted) setState(() => _busyIds.remove(b.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 16),
                child: PageHeader(
                  subtitle: 'Host dashboard',
                  title: 'Bookings',
                ),
              ),
              Expanded(
                child: FutureBuilder<List<Booking>>(
                  future: _bookings,
                  builder: (context, snap) {
                    if (snap.hasError) {
                      return RefreshIndicator(
                        onRefresh: _reload,
                        child: EmptyState(
                          icon: Icons.cloud_off_rounded,
                          title: "Couldn't load bookings",
                          message: errorMessage(snap.error!),
                        ),
                      );
                    }
                    if (!snap.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    return _buildDashboard(snap.data!);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboard(List<Booking> all) {
    final now = DateTime.now();
    final pending = all
        .where((b) => b.status == BookingStatus.pending && b.isUpcoming)
        .toList();
    final upcoming = all
        .where((b) => b.status == BookingStatus.accepted && b.isUpcoming)
        .toList();
    final history = all
        .where((b) => !pending.contains(b) && !upcoming.contains(b))
        .toList()
        .reversed
        .toList();
    final monthEarnings = all
        .where(
          (b) =>
              b.status == BookingStatus.accepted &&
              b.checkIn.year == now.year &&
              b.checkIn.month == now.month,
        )
        .fold<double>(0, (sum, b) => sum + b.totalPrice);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(
                child: _StatTile(
                  icon: Icons.notifications_active_outlined,
                  color: const Color(0xFFF59E0B),
                  value: '${pending.length}',
                  label: 'New requests',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatTile(
                  icon: Icons.event_available_outlined,
                  color: AppColors.brand,
                  value: '${upcoming.length}',
                  label: 'Upcoming',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatTile(
                  icon: Icons.account_balance_wallet_outlined,
                  color: AppColors.accent,
                  value: _pesoCompact.format(monthEarnings),
                  label: 'This month',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: softShadow,
          ),
          child: TabBar(
            indicator: BoxDecoration(
              color: AppColors.brand,
              borderRadius: BorderRadius.circular(12),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            labelColor: Colors.white,
            unselectedLabelColor: AppColors.muted,
            labelStyle: const TextStyle(fontWeight: FontWeight.w700),
            splashBorderRadius: BorderRadius.circular(12),
            tabs: [
              Tab(
                height: 40,
                text: pending.isEmpty
                    ? 'Requests'
                    : 'Requests (${pending.length})',
              ),
              const Tab(height: 40, text: 'Upcoming'),
              const Tab(height: 40, text: 'History'),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: TabBarView(
            children: [
              _list(
                pending,
                Icons.inbox_rounded,
                'No new requests',
                'New booking requests from guests will appear here.',
                withActions: true,
              ),
              _list(
                upcoming,
                Icons.event_available_rounded,
                'No upcoming stays',
                'Accepted bookings will show up here.',
              ),
              _list(
                history,
                Icons.history_rounded,
                'No history yet',
                'Past, declined and cancelled bookings live here.',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _list(
    List<Booking> bookings,
    IconData emptyIcon,
    String emptyTitle,
    String emptyMessage, {
    bool withActions = false,
  }) {
    return RefreshIndicator(
      onRefresh: _reload,
      child: bookings.isEmpty
          ? EmptyState(
              icon: emptyIcon,
              title: emptyTitle,
              message: emptyMessage,
            )
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                  itemCount: bookings.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 16),
                  itemBuilder: (context, i) {
                    final b = bookings[i];
                    final busy = _busyIds.contains(b.id);
                    return BookingCard(
                      booking: b,
                      showGuest: true,
                      actions: withActions
                          ? [
                              OutlinedButton(
                                onPressed: busy
                                    ? null
                                    : () => _respond(b, accept: false),
                                child: const Text('Decline'),
                              ),
                              FilledButton(
                                onPressed: busy
                                    ? null
                                    : () => _respond(b, accept: true),
                                child: const Text('Accept'),
                              ),
                            ]
                          : const [],
                    );
                  },
                ),
              ),
            ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;

  const _StatTile({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
