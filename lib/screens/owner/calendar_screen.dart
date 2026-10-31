import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models.dart';
import '../../repository.dart';
import '../../theme.dart';
import '../../widgets.dart';

final _monthFormat = DateFormat('MMMM yyyy');
final _dayTitleFormat = DateFormat('EEEE, MMM d');
const _weekdays = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

const _pendingColor = Color(0xFFB45309);
const _pendingBackground = Color(0xFFFEF3C7);

enum _NightStatus { available, pending, reserved }

/// Month view of reserved, pending and available nights for each place.
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late Future<(List<Listing>, List<Booking>)> _data = _load();
  late final RealtimeChannel _channel;

  @override
  void initState() {
    super.initState();
    // Refresh when a booking for one of this owner's places changes.
    _channel = supabase
        .channel('owner-calendar')
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

  Future<(List<Listing>, List<Booking>)> _load() =>
      (fetchMyListings(), fetchOwnerBookings()).wait;

  Future<void> _reload() async {
    final future = _load();
    setState(() {
      _data = future;
    });
    await future.catchError((_) => (<Listing>[], <Booking>[]));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: PageHeader(subtitle: 'Availability', title: 'Calendar'),
            ),
            Expanded(
              child: FutureBuilder<(List<Listing>, List<Booking>)>(
                future: _data,
                builder: (context, snap) {
                  if (snap.hasError) {
                    return RefreshIndicator(
                      onRefresh: _reload,
                      child: EmptyState(
                        icon: Icons.cloud_off_rounded,
                        title: "Couldn't load your calendar",
                        message: errorMessage(snap.error!),
                      ),
                    );
                  }
                  if (!snap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final (listings, bookings) = snap.data!;
                  if (listings.isEmpty) {
                    return RefreshIndicator(
                      onRefresh: _reload,
                      child: const EmptyState(
                        icon: Icons.calendar_month_rounded,
                        title: 'No places yet',
                        message:
                            'Add a place in My Places to see its calendar here.',
                      ),
                    );
                  }
                  return AvailabilityCalendar(
                    listings: listings,
                    bookings: bookings,
                    onRefresh: _reload,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The calendar itself, separate from loading so it can be previewed and
/// tested with sample data.
class AvailabilityCalendar extends StatefulWidget {
  final List<Listing> listings;
  final List<Booking> bookings;
  final Future<void> Function() onRefresh;

  const AvailabilityCalendar({
    super.key,
    required this.listings,
    required this.bookings,
    required this.onRefresh,
  });

  @override
  State<AvailabilityCalendar> createState() => _AvailabilityCalendarState();
}

class _AvailabilityCalendarState extends State<AvailabilityCalendar> {
  String? _listingId;
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime _selected = DateUtils.dateOnly(DateTime.now());

  void _changeMonth(int delta) {
    setState(() {
      _month = DateTime(_month.year, _month.month + delta);
    });
  }

  @override
  Widget build(BuildContext context) {
    final listings = widget.listings;
    final listing = listings.firstWhere(
      (l) => l.id == _listingId,
      orElse: () => listings.first,
    );
    // Declined and cancelled requests don't occupy any nights.
    final bookings = widget.bookings
        .where(
          (b) =>
              b.listingId == listing.id &&
              (b.status == BookingStatus.accepted ||
                  b.status == BookingStatus.pending),
        )
        .toList();

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            children: [
              if (listings.length > 1) ...[
                SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: listings.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, i) {
                      final l = listings[i];
                      final selected = l.id == listing.id;
                      return ChoiceChip(
                        label: Text(l.title),
                        selected: selected,
                        showCheckmark: false,
                        selectedColor: AppColors.brand,
                        backgroundColor: Colors.white,
                        side: BorderSide(
                          color: selected ? AppColors.brand : AppColors.line,
                        ),
                        shape: const StadiumBorder(),
                        labelStyle: TextStyle(
                          color: selected ? Colors.white : AppColors.ink,
                          fontWeight: FontWeight.w600,
                        ),
                        onSelected: (_) => setState(() {
                          _listingId = l.id;
                        }),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],
              _MonthCard(
                month: _month,
                selected: _selected,
                statusOf: (day) => _statusOf(day, bookings),
                onPrevious: () => _changeMonth(-1),
                onNext: () => _changeMonth(1),
                onSelect: (day) => setState(() {
                  _selected = day;
                }),
              ),
              const SizedBox(height: 12),
              const _Legend(),
              const SizedBox(height: 20),
              _MonthSummary(
                month: _month,
                statusOf: (day) => _statusOf(day, bookings),
              ),
              const SizedBox(height: 28),
              _DayDetails(day: _selected, bookings: bookings),
            ],
          ),
        ),
      ),
    );
  }

  static _NightStatus _statusOf(DateTime day, List<Booking> bookings) {
    var pending = false;
    for (final b in bookings) {
      if (!b.coversNight(day)) continue;
      if (b.status == BookingStatus.accepted) return _NightStatus.reserved;
      pending = true;
    }
    return pending ? _NightStatus.pending : _NightStatus.available;
  }
}

class _MonthCard extends StatelessWidget {
  final DateTime month;
  final DateTime selected;
  final _NightStatus Function(DateTime day) statusOf;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final ValueChanged<DateTime> onSelect;

  const _MonthCard({
    required this.month,
    required this.selected,
    required this.statusOf,
    required this.onPrevious,
    required this.onNext,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final today = DateUtils.dateOnly(DateTime.now());
    final daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);
    // Weeks start on Sunday; DateTime.weekday is 1 (Mon) to 7 (Sun).
    final leadingBlanks = DateTime(month.year, month.month, 1).weekday % 7;

    return AppCard(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                tooltip: 'Previous month',
                onPressed: onPrevious,
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              Expanded(
                child: Text(
                  _monthFormat.format(month),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Next month',
                onPressed: onNext,
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final d in _weekdays)
                Expanded(
                  child: Text(
                    d,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            children: [
              for (var i = 0; i < leadingBlanks; i++) const SizedBox.shrink(),
              for (var d = 1; d <= daysInMonth; d++)
                _DayCell(
                  day: DateTime(month.year, month.month, d),
                  status: statusOf(DateTime(month.year, month.month, d)),
                  isToday: DateTime(month.year, month.month, d) == today,
                  isPast: DateTime(month.year, month.month, d).isBefore(today),
                  isSelected: DateTime(month.year, month.month, d) == selected,
                  onTap: onSelect,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  final DateTime day;
  final _NightStatus status;
  final bool isToday;
  final bool isPast;
  final bool isSelected;
  final ValueChanged<DateTime> onTap;

  const _DayCell({
    required this.day,
    required this.status,
    required this.isToday,
    required this.isPast,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = switch (status) {
      _NightStatus.reserved => (AppColors.brand, Colors.white),
      _NightStatus.pending => (_pendingBackground, _pendingColor),
      _NightStatus.available => (Colors.transparent, AppColors.ink),
    };
    return Opacity(
      opacity: isPast ? 0.4 : 1,
      child: InkWell(
        onTap: () => onTap(day),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(12),
            border: isSelected
                ? Border.all(color: AppColors.ink, width: 2)
                : isToday
                ? Border.all(color: AppColors.brand, width: 1.5)
                : null,
          ),
          child: Text(
            '${day.day}',
            style: TextStyle(
              color: foreground,
              fontWeight: status == _NightStatus.available && !isToday
                  ? FontWeight.w500
                  : FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    Widget item(Color color, String label, {Color? border}) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: border == null ? null : Border.all(color: border),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(color: AppColors.muted, fontSize: 13),
        ),
      ],
    );

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 18,
      runSpacing: 8,
      children: [
        item(AppColors.brand, 'Reserved'),
        item(_pendingBackground, 'Pending request', border: _pendingColor),
        item(Colors.white, 'Available', border: AppColors.line),
      ],
    );
  }
}

class _MonthSummary extends StatelessWidget {
  final DateTime month;
  final _NightStatus Function(DateTime day) statusOf;

  const _MonthSummary({required this.month, required this.statusOf});

  @override
  Widget build(BuildContext context) {
    final days = DateUtils.getDaysInMonth(month.year, month.month);
    var reserved = 0;
    var pending = 0;
    for (var d = 1; d <= days; d++) {
      switch (statusOf(DateTime(month.year, month.month, d))) {
        case _NightStatus.reserved:
          reserved++;
        case _NightStatus.pending:
          pending++;
        case _NightStatus.available:
          break;
      }
    }
    final available = days - reserved - pending;
    final occupancy = (reserved / days * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle('${DateFormat('MMMM').format(month)} at a glance'),
        Row(
          children: [
            Expanded(
              child: _SummaryTile(
                value: '$reserved',
                label: 'Reserved',
                color: AppColors.brand,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SummaryTile(
                value: '$pending',
                label: 'Pending',
                color: _pendingColor,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SummaryTile(
                value: '$available',
                label: 'Available',
                color: AppColors.muted,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SummaryTile(
                value: '$occupancy%',
                label: 'Occupancy',
                color: AppColors.accent,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _SummaryTile({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: color,
              ),
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

class _DayDetails extends StatelessWidget {
  final DateTime day;
  final List<Booking> bookings;

  const _DayDetails({required this.day, required this.bookings});

  @override
  Widget build(BuildContext context) {
    final staying = bookings.where((b) => b.coversNight(day)).toList();
    final leaving = bookings.where((b) => b.checkOut == day).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(_dayTitleFormat.format(day)),
        if (staying.isEmpty && leaving.isEmpty)
          AppCard(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.brand.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.event_available_rounded,
                    color: AppColors.brand,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Text(
                    'Available — no guests this night.',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        for (final b in staying) ...[
          BookingCard(booking: b, showGuest: true),
          const SizedBox(height: 12),
        ],
        if (leaving.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: Text(
              'Checking out',
              style: TextStyle(
                color: AppColors.muted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          for (final b in leaving) ...[
            BookingCard(booking: b, showGuest: true),
            const SizedBox(height: 12),
          ],
        ],
      ],
    );
  }
}
