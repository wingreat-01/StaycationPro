import 'package:flutter/material.dart';

import '../../models.dart';
import '../../repository.dart';
import '../../widgets.dart';
import 'listing_form_screen.dart';

class MyListingsScreen extends StatefulWidget {
  const MyListingsScreen({super.key});

  @override
  State<MyListingsScreen> createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends State<MyListingsScreen> {
  late Future<List<Listing>> _listings = fetchMyListings();

  Future<void> _reload() async {
    final future = fetchMyListings();
    setState(() {
      _listings = future;
    });
    await future.catchError((_) => <Listing>[]);
  }

  Future<void> _openForm([Listing? listing]) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => ListingFormScreen(listing: listing)),
    );
    if (saved == true) _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        shape: const StadiumBorder(),
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Add place',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _reload,
          child: CustomScrollView(
            slivers: [
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 16, 20, 20),
                  child: PageHeader(
                    subtitle: 'Your listings',
                    title: 'My places',
                  ),
                ),
              ),
              FutureBuilder<List<Listing>>(
                future: _listings,
                builder: (context, snap) {
                  if (snap.hasError) {
                    return SliverFillRemaining(
                      hasScrollBody: false,
                      child: EmptyState(
                        icon: Icons.cloud_off_rounded,
                        title: "Couldn't load your places",
                        message: errorMessage(snap.error!),
                        scrollable: false,
                      ),
                    );
                  }
                  if (!snap.hasData) {
                    return const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final listings = snap.data!;
                  if (listings.isEmpty) {
                    return const SliverFillRemaining(
                      hasScrollBody: false,
                      child: EmptyState(
                        icon: Icons.add_home_work_rounded,
                        title: 'List your first place',
                        message:
                            'Add your staycation so guests can find and book it.',
                        scrollable: false,
                      ),
                    );
                  }
                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                    sliver: SliverGrid.builder(
                      gridDelegate: listingGridDelegate,
                      itemCount: listings.length,
                      itemBuilder: (context, i) {
                        final l = listings[i];
                        return ListingTile(
                          listing: l,
                          onTap: () => _openForm(l),
                          badge: l.isActive
                              ? const Pill(
                                  icon: Icons.circle,
                                  label: 'Live',
                                  color: Color(0xFF047857),
                                  background: Color(0xFFD1FAE5),
                                )
                              : const Pill(
                                  icon: Icons.visibility_off_outlined,
                                  label: 'Hidden',
                                  color: Color(0xFF475569),
                                  background: Color(0xFFF1F5F9),
                                ),
                        );
                      },
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
