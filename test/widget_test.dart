import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:staycation_pro/models.dart';
import 'package:staycation_pro/screens/owner/calendar_screen.dart';

Booking _booking({
  required String id,
  required DateTime checkIn,
  required DateTime checkOut,
  required BookingStatus status,
  required String guest,
}) => Booking(
  id: id,
  listingId: 'l1',
  guestId: 'g-$id',
  checkIn: checkIn,
  checkOut: checkOut,
  guests: 2,
  totalPrice: 5000,
  status: status,
  note: null,
  createdAt: DateTime(2026, 1, 1),
  listingTitle: 'Taal View Condo',
  guestName: guest,
);

void main() {
  test('Booking.coversNight includes check-in, excludes check-out day', () {
    final b = _booking(
      id: 'b',
      checkIn: DateTime(2026, 12, 1),
      checkOut: DateTime(2026, 12, 3),
      status: BookingStatus.accepted,
      guest: 'Ana',
    );
    expect(b.coversNight(DateTime(2026, 11, 30)), isFalse);
    expect(b.coversNight(DateTime(2026, 12, 1)), isTrue);
    expect(b.coversNight(DateTime(2026, 12, 2)), isTrue);
    expect(b.coversNight(DateTime(2026, 12, 3)), isFalse);
  });

  testWidgets('Calendar shows the guest staying on a tapped reserved night', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final now = DateTime.now();
    DateTime day(int d) => DateTime(now.year, now.month, d);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AvailabilityCalendar(
            listings: const [
              Listing(
                id: 'l1',
                ownerId: 'o',
                title: 'Taal View Condo',
                description: '',
                location: 'Tagaytay',
                pricePerNight: 2500,
                maxGuests: 4,
              ),
            ],
            bookings: [
              _booking(
                id: 'a',
                checkIn: day(10),
                checkOut: day(13),
                status: BookingStatus.accepted,
                guest: 'Juan Dela Cruz',
              ),
              _booking(
                id: 'p',
                checkIn: day(20),
                checkOut: day(22),
                status: BookingStatus.pending,
                guest: 'Maria Santos',
              ),
            ],
            onRefresh: () async {},
          ),
        ),
      ),
    );

    // 3 reserved nights, 2 pending, and occupancy is reserved / days.
    final days = DateUtils.getDaysInMonth(now.year, now.month);
    expect(find.text('${(3 / days * 100).round()}%'), findsOneWidget);

    await tester.tap(find.text('11'));
    await tester.pump();
    expect(find.text('Juan Dela Cruz'), findsOneWidget);
    expect(find.text('Maria Santos'), findsNothing);

    await tester.tap(find.text('21'));
    await tester.pump();
    expect(find.text('Maria Santos'), findsOneWidget);
  });

  test('DateSpan treats check-out day as free for the next check-in', () {
    final span = DateSpan(DateTime(2026, 12, 1), DateTime(2026, 12, 3));
    expect(
      span.overlaps(DateTime(2026, 12, 3), DateTime(2026, 12, 5)),
      isFalse,
    );
    expect(
      span.overlaps(DateTime(2026, 11, 29), DateTime(2026, 12, 1)),
      isFalse,
    );
    expect(span.overlaps(DateTime(2026, 12, 2), DateTime(2026, 12, 4)), isTrue);
  });

  test('Booking parses joined rows', () {
    final b = Booking.fromMap({
      'id': 'b1',
      'listing_id': 'l1',
      'guest_id': 'g1',
      'check_in': '2026-12-01',
      'check_out': '2026-12-04',
      'guests': 2,
      'total_price': 7500,
      'status': 'pending',
      'note': null,
      'created_at': '2026-10-30T08:00:00Z',
      'listings': {'title': 'Taal View Condo', 'location': 'Tagaytay'},
      'guest': {'full_name': 'Juan Dela Cruz', 'phone': '09171234567'},
    });
    expect(b.nights, 3);
    expect(b.status, BookingStatus.pending);
    expect(b.listingTitle, 'Taal View Condo');
    expect(b.guestName, 'Juan Dela Cruz');
  });
}
