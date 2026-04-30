import 'package:flutter/material.dart';
import 'package:mycondo/data/models/shared/condo_about.dart';
import 'package:mycondo/data/repositories/shared/condo_about_service.dart';

class CondoAboutPage extends StatefulWidget {
  const CondoAboutPage({
    super.key,
    required this.canEdit,
  });

  final bool canEdit;

  @override
  State<CondoAboutPage> createState() => _CondoAboutPageState();
}

class _CondoAboutPageState extends State<CondoAboutPage> {
  final CondoAboutService _service = CondoAboutService();
  late Future<CondoAbout> _aboutFuture;

  @override
  void initState() {
    super.initState();
    _aboutFuture = _fetchAbout();
  }

  Future<CondoAbout> _fetchAbout() {
    return widget.canEdit
        ? _service.fetchForManager()
        : _service.fetchForResident();
  }

  Future<void> _refresh() async {
    final future = _fetchAbout();
    setState(() {
      _aboutFuture = future;
    });
    await future;
  }

  Future<void> _edit(CondoAbout about) async {
    final updated = await showModalBottomSheet<CondoAbout>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _EditCondoAboutSheet(about: about),
    );

    if (updated == null) return;

    await _service.updateForManager(updated);
    if (!mounted) return;
    await _refresh();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('About page updated.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7F4),
      body: SafeArea(
        child: FutureBuilder<CondoAbout>(
          future: _aboutFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return _ErrorState(onRetry: _refresh);
            }

            final about = snapshot.data!;
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'About',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                      ),
                      if (widget.canEdit)
                        IconButton(
                          onPressed: () => _edit(about),
                          icon: const Icon(Icons.edit_outlined),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _CondoHeroImage(imageUrl: about.imageUrl),
                  const SizedBox(height: 18),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          about.name.isEmpty ? 'Condo Name' : about.name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Colors.black,
                            height: 1.05,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Flexible(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.place_outlined,
                              size: 18,
                              color: Color(0xFF66737C),
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                about.location.isEmpty
                                    ? 'Location'
                                    : about.location,
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF66737C),
                                  height: 1.2,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    about.description.isEmpty
                        ? 'No description has been added yet.'
                        : about.description,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.45,
                      color: Color(0xFF4E565C),
                    ),
                  ),
                  const SizedBox(height: 26),
                  const Text(
                    'Gallery',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _Gallery(urls: about.galleryUrls),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _CondoHeroImage extends StatelessWidget {
  const _CondoHeroImage({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: _NetworkOrPlaceholder(
          imageUrl: imageUrl,
          icon: Icons.apartment_rounded,
        ),
      ),
    );
  }
}

class _Gallery extends StatelessWidget {
  const _Gallery({required this.urls});

  final List<String> urls;

  @override
  Widget build(BuildContext context) {
    if (urls.isEmpty) {
      return Container(
        height: 128,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE8E4DD)),
        ),
        child: const Text(
          'No gallery photos yet.',
          style: TextStyle(color: Color(0xFF777777)),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: urls.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.2,
      ),
      itemBuilder: (context, index) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: _NetworkOrPlaceholder(
            imageUrl: urls[index],
            icon: Icons.image_outlined,
          ),
        );
      },
    );
  }
}

class _NetworkOrPlaceholder extends StatelessWidget {
  const _NetworkOrPlaceholder({
    required this.imageUrl,
    required this.icon,
  });

  final String imageUrl;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl.trim();
    if (url.isEmpty) return _PlaceholderImage(icon: icon);

    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return _PlaceholderImage(icon: icon);
      },
    );
  }
}

class _PlaceholderImage extends StatelessWidget {
  const _PlaceholderImage({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFEAF4FB),
      child: Icon(
        icon,
        size: 42,
        color: const Color(0xFF6D879B),
      ),
    );
  }
}

class _EditCondoAboutSheet extends StatefulWidget {
  const _EditCondoAboutSheet({required this.about});

  final CondoAbout about;

  @override
  State<_EditCondoAboutSheet> createState() => _EditCondoAboutSheetState();
}

class _EditCondoAboutSheetState extends State<_EditCondoAboutSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _locationController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _imageUrlController;
  late final TextEditingController _galleryController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.about.name);
    _locationController = TextEditingController(text: widget.about.location);
    _descriptionController =
        TextEditingController(text: widget.about.description);
    _imageUrlController = TextEditingController(text: widget.about.imageUrl);
    _galleryController = TextEditingController(
      text: widget.about.galleryUrls.join('\n'),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    _galleryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          18,
          20,
          MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Edit About',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 16),
              _field(_nameController, 'Condo name'),
              const SizedBox(height: 12),
              _field(_locationController, 'Location'),
              const SizedBox(height: 12),
              _field(_imageUrlController, 'Condo image URL'),
              const SizedBox(height: 12),
              _field(
                _descriptionController,
                'Description',
                minLines: 3,
                maxLines: 5,
              ),
              const SizedBox(height: 12),
              _field(
                _galleryController,
                'Gallery image URLs, one per line',
                minLines: 4,
                maxLines: 8,
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    int minLines = 1,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      minLines: minLines,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }

  void _save() {
    final galleryUrls = _galleryController.text
        .split('\n')
        .map((url) => url.trim())
        .where((url) => url.isNotEmpty)
        .toList();

    Navigator.pop(
      context,
      widget.about.copyWith(
        name: _nameController.text,
        location: _locationController.text,
        description: _descriptionController.text,
        imageUrl: _imageUrlController.text,
        galleryUrls: galleryUrls,
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: OutlinedButton(
        onPressed: onRetry,
        child: const Text('Unable to load condo details. Try again.'),
      ),
    );
  }
}
