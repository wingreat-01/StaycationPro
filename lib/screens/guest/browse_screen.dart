import 'package:flutter/material.dart';

import '../../models.dart';
import '../../repository.dart';
import '../../theme.dart';
import '../../widgets.dart';
import 'listing_detail_screen.dart';

class BrowseScreen extends StatefulWidget {
  const BrowseScreen({super.key});

  @override
  State<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends State<BrowseScreen> {
  final _search = TextEditingController();
  late Future<List<Listing>> _listings = fetchActiveListings();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    final future = fetchActiveListings(search: _search.text);
    setState(() => _listings = future);
    await future.catchError((_) => <Listing>[]);
  }

  String get _firstName {
    final name =
        supabase.auth.currentUser?.userMetadata?['full_name'] as String? ?? '';
    final first = name.trim().split(' ').first;
    return first.isEmpty ? 'there' : first;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _reload,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      PageHeader(
                        subtitle: 'Hi, $_firstName 👋',
                        title: 'Where to next?',
                      ),
                      const SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: softShadow,
                        ),
                        child: TextField(
                          controller: _search,
                          textInputAction: TextInputAction.search,
                          onSubmitted: (_) => _reload(),
                          decoration: InputDecoration(
                            fillColor: Colors.white,
                            hintText: 'Search a city or place, e.g. Tagaytay',
                            prefixIcon: const Icon(Icons.search_rounded),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.close_rounded),
                              onPressed: () {
                                _search.clear();
                                _reload();
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
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
                        title: "Couldn't load stays",
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
                        icon: Icons.travel_explore_rounded,
                        title: 'No stays found',
                        message: 'Try another city, or check back soon.',
                        scrollable: false,
                      ),
                    );
                  }
                  return SliverMainAxisGroup(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                          child: Row(
                            children: [
                              const SectionTitle('Available stays'),
                              const Spacer(),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Text(
                                  '${listings.length} place${listings.length == 1 ? '' : 's'}',
                                  style: const TextStyle(
                                    color: AppColors.muted,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                        sliver: SliverGrid.builder(
                          gridDelegate: listingGridDelegate,
                          itemCount: listings.length,
                          itemBuilder: (context, i) => ListingTile(
                            listing: listings[i],
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    ListingDetailScreen(listing: listings[i]),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
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
