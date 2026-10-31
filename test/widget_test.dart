import 'package:flutter_test/flutter_test.dart';
import 'package:staycation_pro/models.dart';

void main() {
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
