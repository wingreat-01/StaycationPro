import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models.dart';
import '../../repository.dart';
import '../../theme.dart';
import '../../widgets.dart';

class ListingFormScreen extends StatefulWidget {
  final Listing? listing;

  const ListingFormScreen({super.key, this.listing});

  @override
  State<ListingFormScreen> createState() => _ListingFormScreenState();
}

class _ListingFormScreenState extends State<ListingFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.listing?.title);
  late final _description = TextEditingController(
    text: widget.listing?.description,
  );
  late final _location = TextEditingController(text: widget.listing?.location);
  late final _price = TextEditingController(
    text: widget.listing?.pricePerNight.toStringAsFixed(0),
  );
  late final _maxGuests = TextEditingController(
    text: (widget.listing?.maxGuests ?? 2).toString(),
  );
  late String? _imageUrl = widget.listing?.imageUrl;
  late bool _isActive = widget.listing?.isActive ?? true;
  bool _busy = false;
  bool _uploading = false;
  bool _saved = false;

  // Photos uploaded while this screen was open; any not used get cleaned up.
  final List<String> _sessionUploads = [];

  bool get _isEditing => widget.listing != null;

  @override
  void dispose() {
    for (final c in [_title, _description, _location, _price, _maxGuests]) {
      c.dispose();
    }
    if (!_saved) _deletePhotos(_sessionUploads);
    super.dispose();
  }

  void _deletePhotos(Iterable<String> urls) {
    for (final url in urls) {
      deleteListingPhoto(url).catchError((_) {});
    }
  }

  Future<void> _choosePhotoSource() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            if (_imageUrl != null)
              ListTile(
                leading: Icon(
                  Icons.delete_outline_rounded,
                  color: Theme.of(ctx).colorScheme.error,
                ),
                title: Text(
                  'Remove photo',
                  style: TextStyle(color: Theme.of(ctx).colorScheme.error),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() => _imageUrl = null);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (source != null) await _uploadPhoto(source);
  }

  Future<void> _uploadPhoto(ImageSource source) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      // Resized and compressed on the device to keep uploads fast.
      final picked = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 80,
      );
      if (picked == null) return;
      setState(() => _uploading = true);
      final bytes = await picked.readAsBytes();
      var ext = picked.name.split('.').last.toLowerCase();
      if (!['jpg', 'jpeg', 'png', 'webp'].contains(ext)) ext = 'jpg';
      final url = await uploadListingPhoto(bytes, ext);
      _sessionUploads.add(url);
      if (mounted) setState(() => _imageUrl = url);
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Upload failed: ${errorMessage(e)}')),
      );
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() => _busy = true);
    try {
      final image = _imageUrl ?? '';
      await saveListing(
        Listing(
          id: widget.listing?.id,
          ownerId: currentUserId,
          title: _title.text.trim(),
          description: _description.text.trim(),
          location: _location.text.trim(),
          pricePerNight: double.parse(_price.text.trim()),
          maxGuests: int.parse(_maxGuests.text.trim()),
          imageUrl: image.isEmpty ? null : image,
          isActive: _isActive,
        ),
      );
      _saved = true;
      // Clean up photos that were replaced or never used.
      _deletePhotos(
        {
          ...?(widget.listing?.imageUrl == null
              ? null
              : [widget.listing!.imageUrl!]),
          ..._sessionUploads,
        }.where((u) => u != _imageUrl),
      );
      navigator.pop(true);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(errorMessage(e))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final ok = await confirmDialog(
      context,
      'Delete this place?',
      'This also deletes all of its bookings. To stop new bookings but keep '
          'history, turn off "Visible to guests" instead.',
      confirm: 'Delete',
    );
    if (!ok || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await deleteListing(widget.listing!.id!);
      _deletePhotos([?widget.listing!.imageUrl]);
      navigator.pop(true);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(errorMessage(e))));
    }
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Required' : null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit place' : 'New place'),
        actions: [
          if (_isEditing)
            IconButton(
              tooltip: 'Delete',
              onPressed: _busy ? null : _delete,
              icon: const Icon(Icons.delete_outline_rounded),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                _PhotoPicker(
                  url: _imageUrl,
                  uploading: _uploading,
                  onTap: _uploading || _busy ? null : _choosePhotoSource,
                ),
                const SizedBox(height: 20),
                _Section(
                  title: 'Basics',
                  children: [
                    TextFormField(
                      controller: _title,
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        hintText: 'e.g. Cozy Condo with Taal View',
                        prefixIcon: Icon(Icons.villa_outlined),
                      ),
                      textCapitalization: TextCapitalization.words,
                      validator: _required,
                    ),
                    TextFormField(
                      controller: _location,
                      decoration: const InputDecoration(
                        labelText: 'Location',
                        hintText: 'e.g. Tagaytay City, Cavite',
                        prefixIcon: Icon(Icons.place_outlined),
                      ),
                      textCapitalization: TextCapitalization.words,
                      validator: _required,
                    ),
                    TextFormField(
                      controller: _description,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText: 'Amenities, house rules, check-in time…',
                        alignLabelWithHint: true,
                      ),
                      maxLines: 5,
                    ),
                  ],
                ),
                _Section(
                  title: 'Pricing & capacity',
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _price,
                            decoration: const InputDecoration(
                              labelText: 'Price per night',
                              prefixText: '₱ ',
                            ),
                            keyboardType: TextInputType.number,
                            validator: (v) {
                              final n = double.tryParse(v?.trim() ?? '');
                              return (n == null || n < 0)
                                  ? 'Enter a price'
                                  : null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _maxGuests,
                            decoration: const InputDecoration(
                              labelText: 'Max guests',
                              prefixIcon: Icon(Icons.group_outlined),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (v) {
                              final n = int.tryParse(v?.trim() ?? '');
                              return (n == null || n < 1) ? 'At least 1' : null;
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                AppCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Visible to guests',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: const Text(
                      'Turn off to stop receiving new requests',
                      style: TextStyle(color: AppColors.muted),
                    ),
                    value: _isActive,
                    onChanged: (v) => setState(() => _isActive = v),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.line)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: FilledButton(
              onPressed: _busy || _uploading ? null : _save,
              child: _busy
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.white,
                      ),
                    )
                  : Text(_isEditing ? 'Save changes' : 'Publish place'),
            ),
          ),
        ),
      ),
    );
  }
}

class _PhotoPicker extends StatelessWidget {
  final String? url;
  final bool uploading;
  final VoidCallback? onTap;

  const _PhotoPicker({
    required this.url,
    required this.uploading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhoto = url != null && url!.isNotEmpty;
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: SizedBox(
          height: 220,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (hasPhoto)
                ListingImage(url: url)
              else
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.brand.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: AppColors.brand.withValues(alpha: 0.35),
                      width: 1.5,
                    ),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_photo_alternate_outlined,
                        size: 44,
                        color: AppColors.brand,
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Upload a photo',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.brand,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'A bright, wide shot gets the most bookings',
                        style: TextStyle(color: AppColors.muted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              if (hasPhoto && !uploading)
                Positioned(
                  right: 12,
                  bottom: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: softShadow,
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.edit_outlined, size: 16),
                        SizedBox(width: 6),
                        Text(
                          'Change photo',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ),
              if (uploading)
                Container(
                  color: Colors.black.withValues(alpha: 0.45),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Colors.white),
                      SizedBox(height: 12),
                      Text(
                        'Uploading…',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: AppCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionTitle(title),
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) const SizedBox(height: 12),
              children[i],
            ],
          ],
        ),
      ),
    );
  }
}
