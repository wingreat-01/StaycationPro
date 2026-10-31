import 'package:flutter/material.dart';

import '../../models.dart';
import '../../repository.dart';
import '../../theme.dart';
import '../../widgets.dart';

class ListingDetailScreen extends StatefulWidget {
  final Listing listing;

  const ListingDetailScreen({super.key, required this.listing});

  @override
  State<ListingDetailScreen> createState() => _ListingDetailScreenState();
}

class _ListingDetailScreenState extends State<ListingDetailScreen> {
  final _note = TextEditingController();
  List<DateSpan> _booked = [];
  DateTimeRange? _dates;
  int _guests = 1;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    fetchBookedRanges(widget.listing.id!)
        .then((r) {
          if (mounted) setState(() => _booked = r);
        })
        .catchError((_) {});
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  bool get _datesTaken =>
      _dates != null &&
      _booked.any((s) => s.overlaps(_dates!.start, _dates!.end));

  Future<void> _pickDates() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final picked = await showDateRangePicker(
      context: context,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
      initialDateRange: _dates,
      helpText: 'Select check-in and check-out',
      saveText: 'Done',
    );
    if (picked != null) {
      setState(() => _dates = picked);
    }
  }

  Future<void> _submit() async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() => _busy = true);
    try {
      await requestBooking(
        listingId: widget.listing.id!,
        checkIn: _dates!.start,
        checkOut: _dates!.end,
        guests: _guests,
        note: _note.text,
      );
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Request sent! The host will confirm your booking.'),
        ),
      );
      navigator.pop();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(errorMessage(e))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = widget.listing;
    final theme = Theme.of(context);
    final nights = _dates?.duration.inDays ?? 0;
    final canBook = _dates != null && nights > 0 && !_datesTaken && !_busy;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 340,
            pinned: true,
            stretch: true,
            backgroundColor: Colors.white,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: _CircleButton(
                icon: Icons.arrow_back_rounded,
                onTap: () => Navigator.pop(context),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: 'listing-${l.id}',
                child: ListingImage(url: l.imageUrl),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.title,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.place_outlined,
                            size: 18,
                            color: AppColors.muted,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              l.location,
                              style: const TextStyle(color: AppColors.muted),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: _InfoTile(
                              icon: Icons.payments_outlined,
                              value: peso.format(l.pricePerNight),
                              label: 'per night',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _InfoTile(
                              icon: Icons.group_outlined,
                              value: 'Up to ${l.maxGuests}',
                              label: 'guests',
                            ),
                          ),
                        ],
                      ),
                      if (l.description.isNotEmpty) ...[
                        const SizedBox(height: 28),
                        const SectionTitle('About this place'),
                        Text(
                          l.description,
                          style: const TextStyle(
                            color: AppColors.muted,
                            height: 1.55,
                          ),
                        ),
                      ],
                      if (_booked.isNotEmpty) ...[
                        const SizedBox(height: 28),
                        const SectionTitle('Unavailable dates'),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final s in _booked)
                              Pill(
                                icon: Icons.block_rounded,
                                label:
                                    '${shortDate.format(s.start)} – ${shortDate.format(s.end)}',
                                color: const Color(0xFFB91C1C),
                                background: const Color(0xFFFEE2E2),
                              ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 28),
                      const SectionTitle('Your stay'),
                      AppCard(
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: [
                            InkWell(
                              onTap: _pickDates,
                              child: IntrinsicHeight(
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: _DateBox(
                                        label: 'Check-in',
                                        date: _dates?.start,
                                      ),
                                    ),
                                    const VerticalDivider(width: 1),
                                    Expanded(
                                      child: _DateBox(
                                        label: 'Check-out',
                                        date: _dates?.end,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const Divider(),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.group_outlined,
                                    color: AppColors.muted,
                                  ),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Text(
                                      'Guests',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  _StepperButton(
                                    icon: Icons.remove_rounded,
                                    onTap: _guests > 1
                                        ? () => setState(() => _guests--)
                                        : null,
                                  ),
                                  SizedBox(
                                    width: 40,
                                    child: Text(
                                      '$_guests',
                                      textAlign: TextAlign.center,
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                  ),
                                  _StepperButton(
                                    icon: Icons.add_rounded,
                                    onTap: _guests < l.maxGuests
                                        ? () => setState(() => _guests++)
                                        : null,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_datesTaken)
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Row(
                            children: [
                              Icon(
                                Icons.error_outline_rounded,
                                size: 18,
                                color: theme.colorScheme.error,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Those dates overlap an existing booking.',
                                style: TextStyle(
                                  color: theme.colorScheme.error,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _note,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          fillColor: Colors.white,
                          hintText:
                              'Message to host (optional) — arrival time, special requests…',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.line)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: Row(
              children: [
                Expanded(
                  child: nights > 0
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              peso.format(l.pricePerNight * nights),
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              'for $nights night${nights == 1 ? '' : 's'}',
                              style: const TextStyle(color: AppColors.muted),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: peso.format(l.pricePerNight),
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const TextSpan(
                                    text: ' /night',
                                    style: TextStyle(color: AppColors.muted),
                                  ),
                                ],
                              ),
                            ),
                            const Text(
                              'Add dates to see the total',
                              style: TextStyle(color: AppColors.muted),
                            ),
                          ],
                        ),
                ),
                FilledButton(
                  onPressed: canBook ? _submit : null,
                  child: _busy
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Request to book'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 2,
      shadowColor: Colors.black26,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Icon(icon, color: AppColors.ink, size: 22),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _InfoTile({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.brand.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.brand, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                Text(
                  label,
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DateBox extends StatelessWidget {
  final String label;
  final DateTime? date;

  const _DateBox({required this.label, required this.date});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            date == null ? 'Add date' : shortDate.format(date!),
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: date == null ? AppColors.brand : AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _StepperButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: enabled ? AppColors.muted : AppColors.line),
        ),
        child: Icon(
          icon,
          size: 18,
          color: enabled ? AppColors.ink : AppColors.line,
        ),
      ),
    );
  }
}
