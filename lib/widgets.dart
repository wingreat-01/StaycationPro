import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'models.dart';
import 'theme.dart';

final _dayFormat = DateFormat('EEE, MMM d');

String initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
  if (parts.isEmpty) return '?';
  return parts.take(2).map((p) => p[0].toUpperCase()).join();
}

/// White rounded surface with a soft shadow, used for most content blocks.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: softShadow,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Large title used at the top of each main tab.
class PageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;

  const PageHeader({super.key, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (subtitle != null)
          Text(
            subtitle!,
            style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.muted),
          ),
        Text(
          title,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String text;

  const SectionTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class Pill extends StatelessWidget {
  final String label;
  final Color color;
  final Color background;
  final IconData? icon;

  const Pill({
    super.key,
    required this.label,
    required this.color,
    required this.background,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class StatusChip extends StatelessWidget {
  final BookingStatus status;

  const StatusChip(this.status, {super.key});

  @override
  Widget build(BuildContext context) {
    final (label, fg, bg) = switch (status) {
      BookingStatus.pending => (
        'Pending',
        const Color(0xFFB45309),
        const Color(0xFFFEF3C7),
      ),
      BookingStatus.accepted => (
        'Confirmed',
        const Color(0xFF047857),
        const Color(0xFFD1FAE5),
      ),
      BookingStatus.declined => (
        'Declined',
        const Color(0xFFB91C1C),
        const Color(0xFFFEE2E2),
      ),
      BookingStatus.cancelled => (
        'Cancelled',
        const Color(0xFF475569),
        const Color(0xFFF1F5F9),
      ),
    };
    return Pill(label: label, color: fg, background: bg);
  }
}

class ListingImage extends StatelessWidget {
  final String? url;
  final double? height;

  const ListingImage({super.key, required this.url, this.height});

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      height: height,
      width: double.infinity,
      decoration: const BoxDecoration(gradient: brandGradient),
      child: Icon(
        Icons.villa_rounded,
        size: 56,
        color: Colors.white.withValues(alpha: 0.85),
      ),
    );
    if (url == null || url!.isEmpty) return placeholder;
    return Image.network(
      url!,
      height: height,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => placeholder,
    );
  }
}

/// Responsive grid: one column on phones, more on tablets and web.
const listingGridDelegate = SliverGridDelegateWithMaxCrossAxisExtent(
  maxCrossAxisExtent: 460,
  mainAxisSpacing: 24,
  crossAxisSpacing: 20,
  childAspectRatio: 1.05,
);

/// Photo-first listing card with a price tag on the image.
class ListingTile extends StatelessWidget {
  final Listing listing;
  final VoidCallback onTap;
  final Widget? badge;

  const ListingTile({
    super.key,
    required this.listing,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: softShadow,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Hero(
                      tag: 'listing-${listing.id}',
                      child: ListingImage(url: listing.imageUrl),
                    ),
                    if (badge != null)
                      Positioned(top: 12, left: 12, child: badge!),
                    Positioned(
                      bottom: 12,
                      left: 12,
                      child: _PriceTag(price: listing.pricePerNight),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  listing.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Icon(
                Icons.group_outlined,
                size: 16,
                color: AppColors.muted,
              ),
              const SizedBox(width: 4),
              Text(
                '${listing.maxGuests}',
                style: const TextStyle(color: AppColors.muted),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              const Icon(
                Icons.place_outlined,
                size: 16,
                color: AppColors.muted,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  listing.location,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.muted),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PriceTag extends StatelessWidget {
  final double price;

  const _PriceTag({required this.price});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: peso.format(price),
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
            const TextSpan(
              text: ' /night',
              style: TextStyle(color: AppColors.muted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

/// A booking summary used on both the guest and owner sides.
class BookingCard extends StatelessWidget {
  final Booking booking;
  final bool showGuest;
  final List<Widget> actions;

  const BookingCard({
    super.key,
    required this.booking,
    this.showGuest = false,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    final b = booking;
    final theme = Theme.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.brand.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.villa_rounded, color: AppColors.brand),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      b.listingTitle ?? 'Listing unavailable',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (b.listingLocation != null)
                      Text(
                        b.listingLocation!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.muted),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              StatusChip(b.status),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.field,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(child: _dateColumn('Check-in', b.checkIn)),
                const Icon(
                  Icons.arrow_forward_rounded,
                  size: 18,
                  color: AppColors.muted,
                ),
                const SizedBox(width: 12),
                Expanded(child: _dateColumn('Check-out', b.checkOut)),
                Pill(
                  label: '${b.nights} night${b.nights == 1 ? '' : 's'}',
                  color: AppColors.brand,
                  background: Colors.white,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.group_outlined,
                size: 18,
                color: AppColors.muted,
              ),
              const SizedBox(width: 6),
              Text(
                '${b.guests} guest${b.guests == 1 ? '' : 's'}',
                style: const TextStyle(color: AppColors.muted),
              ),
              const Spacer(),
              Text(
                peso.format(b.totalPrice),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.brand,
                ),
              ),
            ],
          ),
          if (showGuest) ...[
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.accent.withValues(alpha: 0.15),
                  child: Text(
                    initials(b.guestName ?? ''),
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        b.guestName ?? 'Guest',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      if (b.guestPhone?.isNotEmpty == true)
                        Text(
                          b.guestPhone!,
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 13,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ],
          if (b.note?.isNotEmpty == true) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.line),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                '“${b.note!}”',
                style: const TextStyle(
                  fontStyle: FontStyle.italic,
                  color: AppColors.muted,
                ),
              ),
            ),
          ],
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                for (var i = 0; i < actions.length; i++) ...[
                  if (i > 0) const SizedBox(width: 12),
                  Expanded(child: actions[i]),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _dateColumn(String label, DateTime date) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
      const SizedBox(height: 2),
      Text(
        _dayFormat.format(date),
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ],
  );
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  /// Wraps the content in a ListView so RefreshIndicator still works when empty.
  final bool scrollable;

  const EmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.title = 'Nothing here yet',
    this.scrollable = true,
  });

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: AppColors.brand.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 44, color: AppColors.brand),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.muted),
          ),
        ],
      ),
    );
    if (!scrollable) return Center(child: content);
    return ListView(children: [const SizedBox(height: 40), content]);
  }
}

Future<bool> confirmDialog(
  BuildContext context,
  String title,
  String body, {
  String confirm = 'Yes',
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      content: Text(body),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('No'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(confirm),
        ),
      ],
    ),
  );
  return ok ?? false;
}
