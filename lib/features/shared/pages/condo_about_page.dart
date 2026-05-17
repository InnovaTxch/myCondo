import 'package:flutter/material.dart';
import 'package:mycondo/theme/app_theme.dart';
import 'package:mycondo/data/models/shared/condo_about.dart';
import 'package:mycondo/data/repositories/shared/condo_about_service.dart';
import 'package:mycondo/utils/app_snackbar.dart';
import 'package:mycondo/features/shared/widgets/app_states.dart';

class CondoAboutPage extends StatefulWidget {
  const CondoAboutPage({super.key, required this.canEdit});

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
    context.showAppSnackBar(const SnackBar(content: Text('About page updated.')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBlueBackground,
      body: SafeArea(
        child: FutureBuilder<CondoAbout>(
          future: _aboutFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const AppLoadingState();
            }

            if (snapshot.hasError) {
              return AppErrorState(
                message: 'Unable to load condo details. Try again.',
                onRetry: _refresh,
              );
            }

            final about = snapshot.data!;
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(22, 22, 22, 30),
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(28, 36, 28, 28),
                    decoration: BoxDecoration(
                      color: const Color(0xEFFFFFFF),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _AboutHeader(),
                        const SizedBox(height: 32),
                        _CondoHeroStack(
                          about: about,
                          canEdit: widget.canEdit,
                          onEdit: () => _edit(about),
                        ),
                        const SizedBox(height: 12),
                        _DescriptionCard(
                          description: about.description,
                          canEdit: widget.canEdit,
                          onEdit: () => _edit(about),
                        ),
                        const SizedBox(height: 10),
                        _GalleryCard(
                          urls: about.galleryUrls,
                          canEdit: widget.canEdit,
                          onEdit: () => _edit(about),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _AboutHeader extends StatelessWidget {
  const _AboutHeader();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            text: 'About ',
            style: TextStyle(
              color: Colors.black,
              fontSize: 30,
              fontWeight: FontWeight.w600,
              height: 1,
            ),
            children: [
              TextSpan(
                text: 'myCondo',
                style: TextStyle(
                  color: AppColors.primaryBlue,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Discover your condo unit better.',
          style: TextStyle(
            color: Color(0xFF5E6A72),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _CondoHeroStack extends StatelessWidget {
  const _CondoHeroStack({
    required this.about,
    required this.canEdit,
    required this.onEdit,
  });

  final CondoAbout about;
  final bool canEdit;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        AspectRatio(
          aspectRatio: 1.12,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: _NetworkOrPlaceholder(
              imageUrl: about.imageUrl,
              icon: Icons.apartment_rounded,
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: -48,
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            decoration: BoxDecoration(
              color: const Color(0xEDEFF5F5),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(26),
              ),
              border: Border.all(color: Colors.white),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    about.name.isEmpty ? 'Condo Name' : about.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                      height: 1.05,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Flexible(
                  child: Text(
                    about.location.isEmpty ? 'Location' : about.location,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF5E5E5E),
                      height: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (canEdit)
          Positioned(
            top: 12,
            right: 12,
            child: _EditIconButton(onPressed: onEdit),
          ),
        const SizedBox(height: 48),
      ],
    );
  }
}

class _DescriptionCard extends StatelessWidget {
  const _DescriptionCard({
    required this.description,
    required this.canEdit,
    required this.onEdit,
  });

  final String description;
  final bool canEdit;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 48),
      child: _SoftPanel(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 2, 28, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF3D4650),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    description.isEmpty
                        ? 'No description has been added yet.'
                        : description,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.26,
                      color: Color(0xFF1F2428),
                    ),
                  ),
                ],
              ),
            ),
            if (canEdit)
              Positioned(
                top: 0,
                right: 0,
                child: _EditIconButton(onPressed: onEdit, compact: true),
              ),
          ],
        ),
      ),
    );
  }
}

class _GalleryCard extends StatelessWidget {
  const _GalleryCard({
    required this.urls,
    required this.canEdit,
    required this.onEdit,
  });

  final List<String> urls;
  final bool canEdit;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return _SoftPanel(
      child: Column(
        children: [
          Stack(
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEAF4FB),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.home_outlined,
                      color: Color(0xFF4A5158),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    height: 52,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: const Color(0xFFE1EEF7)),
                    ),
                    child: const Text(
                      'Gallery',
                      style: TextStyle(
                        color: Color(0xFF4A5158),
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              if (canEdit)
                Positioned(
                  top: 0,
                  right: 0,
                  child: _EditIconButton(onPressed: onEdit, compact: true),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (urls.isEmpty)
            Container(
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
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: urls.length.clamp(0, 6),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1.08,
              ),
              itemBuilder: (context, index) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _NetworkOrPlaceholder(
                        imageUrl: urls[index],
                        icon: Icons.image_outlined,
                      ),
                      if (index == 0 || index == 1 || index == 3)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'Rm ${index + 1}'.padLeft(5, '0'),
                              style: const TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF66737C),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _SoftPanel extends StatelessWidget {
  const _SoftPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      decoration: BoxDecoration(
        color: const Color(0xF2F8FCFF),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white),
      ),
      child: child,
    );
  }
}

class _EditIconButton extends StatelessWidget {
  const _EditIconButton({required this.onPressed, this.compact = false});

  final VoidCallback onPressed;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF7BC3FA),
        minimumSize: Size.square(compact ? 34 : 42),
      ),
      icon: Icon(Icons.edit_outlined, size: compact ? 24 : 26),
      tooltip: 'Edit about page',
    );
  }
}

class _NetworkOrPlaceholder extends StatelessWidget {
  const _NetworkOrPlaceholder({required this.imageUrl, required this.icon});

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
      child: Icon(icon, size: 42, color: const Color(0xFF6D879B)),
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
    _descriptionController = TextEditingController(
      text: widget.about.description,
    );
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



