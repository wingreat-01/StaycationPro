import 'package:flutter/material.dart';

import '../../models.dart';
import '../../repository.dart';
import '../../widgets.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  late Future<List<Booking>> _bookings = fetchGuestBookings();

  Future<void> _reload() async {
    final future = fetchGuestBookings();
    setState(() => _bookings = future);
    await future.catchError((_) => <Booking>[]);
  }

  Future<void> _cancel(Booking b) async {
    final ok = await confirmDialog(
      context,
      'Cancel booking?',
      'Your booking for ${b.listingTitle ?? 'this place'} will be cancelled.',
      confirm: 'Cancel booking',
    );
    if (!ok || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await cancelBooking(b.id);
      await _reload();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(errorMessage(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final today = DateUtils.dateOnly(DateTime.now());
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: PageHeader(subtitle: 'Your bookings', title: 'My trips'),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _reload,
                child: FutureBuilder<List<Booking>>(
                  future: _bookings,
                  builder: (context, snap) {
                    if (snap.hasError) {
                      return EmptyState(
                        icon: Icons.cloud_off_rounded,
                        title: "Couldn't load trips",
                        message: errorMessage(snap.error!),
                      );
                    }
                    if (!snap.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final bookings = snap.data!;
                    if (bookings.isEmpty) {
                      return const EmptyState(
                        icon: Icons.luggage_rounded,
                        title: 'No trips yet',
                        message:
                            'When you request a stay, it will show up here.',
                      );
                    }
                    return Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 720),
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                          itemCount: bookings.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 16),
                          itemBuilder: (context, i) {
                            final b = bookings[i];
                            final cancellable =
                                (b.status == BookingStatus.pending ||
                                    b.status == BookingStatus.accepted) &&
                                b.checkIn.isAfter(today);
                            return BookingCard(
                              booking: b,
                              actions: [
                                if (cancellable)
                                  OutlinedButton(
                                    onPressed: () => _cancel(b),
                                    child: const Text('Cancel booking'),
                                  ),
                              ],
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
