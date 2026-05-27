import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xF8FFFFFF), Color(0xFFF1F8FF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: Colors.white),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x120F4170),
                          blurRadius: 24,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _AboutHeader(canEdit: widget.canEdit, onEdit: () => _edit(about)),
                        const SizedBox(height: 22),
                        _CondoHeroStack(
                          about: about,
                          canEdit: widget.canEdit,
                          onEdit: () => _edit(about),
                        ),
                        const SizedBox(height: 18),
                        _DescriptionCard(
                          about: about,
                          description: about.description,
                          canEdit: widget.canEdit,
                          onEdit: () => _edit(about),
                        ),
                        const SizedBox(height: 14),
                        _GalleryCard(
                          about: about,
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
  const _AboutHeader({required this.canEdit, required this.onEdit});

  final bool canEdit;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Condo Story',
                style: TextStyle(
                  color: AppColors.primaryBlue,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
              ),
              SizedBox(height: 8),
              Text.rich(
                TextSpan(
                  text: 'About ',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    // height: 1,
                  ),
                  children: [
                    TextSpan(
                      text: 'myCondo',
                      style: TextStyle(
                        color: AppColors.primaryBlue,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ], 
                ),
              ),
              // SizedBox(height: 6),
              // Text(
              //   'A cleaner, friendlier snapshot of the place residents call home.',
              //   style: TextStyle(
              //     color: Color(0xFF5E6A72),
              //     fontSize: 14,
              //     fontWeight: FontWeight.w500,
              //     height: 1.3,
              //   ),
              // ),
            ],
          ),
        ),
        if (canEdit)
          Padding(
            padding: const EdgeInsets.only(left: 14, top: 2),
            child: _EditPillButton(onPressed: onEdit),
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
    final imageCount = about.galleryUrls.where((url) => url.trim().isNotEmpty).length;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        AspectRatio(
          aspectRatio: 1.08,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1A275B8A),
                  blurRadius: 24,
                  offset: Offset(0, 14),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _NetworkOrPlaceholder(
                    imageUrl: about.imageUrl,
                    icon: Icons.apartment_rounded,
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.06),
                          Colors.black.withValues(alpha: 0.14),
                          Colors.black.withValues(alpha: 0.58),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _HeroInfoChip(
                              icon: Icons.place_outlined,
                              label: about.location.isEmpty
                                  ? 'Location unavailable'
                                  : about.location,
                            ),
                            _HeroInfoChip(
                              icon: Icons.photo_library_outlined,
                              label: imageCount == 0
                                  ? 'No gallery yet'
                                  : '$imageCount gallery photos',
                            ),
                          ],
                        ),
                        const Spacer(),
                        Text(
                          about.name.isEmpty ? 'Condo Name' : about.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1.03,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          about.description.isEmpty
                              ? 'Add a short overview to help residents understand the character of the property.'
                              : about.description,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.88),
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (canEdit)
          Positioned(
            top: 12,
            right: 12,
            child: _EditIconButton(onPressed: onEdit),
          ),
      ],
    );
  }
}

class _DescriptionCard extends StatelessWidget {
  const _DescriptionCard({
    required this.about,
    required this.description,
    required this.canEdit,
    required this.onEdit,
  });

  final CondoAbout about;
  final String description;
  final bool canEdit;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final trimmedDescription = description.trim();

    return _SoftPanel(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            eyebrow: 'Overview',
            title: 'Description',
            canEdit: canEdit,
            onEdit: onEdit,
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE3EEF8)),
            ),
            child: Text(
              trimmedDescription.isEmpty
                  ? 'No description has been added yet.'
                  : trimmedDescription,
              style: const TextStyle(
                fontSize: 14,
                height: 1.55,
                color: Color(0xFF24313B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _StatPill(
                icon: Icons.apartment_rounded,
                label: about.name.isEmpty ? 'Condo profile' : about.name,
              ),
              _StatPill(
                icon: Icons.place_rounded,
                label: about.location.isEmpty ? 'Location not set' : about.location,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroInfoChip extends StatelessWidget {
  const _HeroInfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 220),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: Colors.white),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GalleryCard extends StatelessWidget {
  const _GalleryCard({
    required this.about,
    required this.urls,
    required this.canEdit,
    required this.onEdit,
  });

  final CondoAbout about;
  final List<String> urls;
  final bool canEdit;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final galleryUrls = urls.where((url) => url.trim().isNotEmpty).toList();
    final previewUrls = galleryUrls.take(6).toList();
    final isCompact = screenWidth < 390;

    return _SoftPanel(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            eyebrow: 'Spaces',
            title: 'Gallery',
            subtitle: galleryUrls.isEmpty
                ? 'No photos uploaded yet.'
                : '${galleryUrls.length} photos that help residents visualize the property.',
            canEdit: canEdit,
            onEdit: onEdit,
          ),
          const SizedBox(height: 16),
          if (galleryUrls.isEmpty)
            Container(
              height: 128,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF8FBFE), Color(0xFFF0F6FC)],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFDDEAF6)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(
                    Icons.photo_library_outlined,
                    color: Color(0xFF7D90A4),
                    size: 30,
                  ),
                  SizedBox(height: 10),
                  Text(
                    'No gallery photos yet.',
                    style: TextStyle(
                      color: Color(0xFF66737C),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: previewUrls.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isCompact ? 2 : 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: isCompact ? 1.14 : 0.96,
              ),
              itemBuilder: (context, index) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _NetworkOrPlaceholder(
                        imageUrl: previewUrls[index],
                        icon: Icons.image_outlined,
                      ),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.05),
                              Colors.black.withValues(alpha: 0.28),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 10,
                        bottom: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.92),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '${about.name.isEmpty ? 'Space' : 'View'} ${index + 1}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF32414E),
                            ),
                          ),
                        ),
                      ),
                      if (galleryUrls.length > previewUrls.length &&
                          index == previewUrls.length - 1)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.62),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '+${galleryUrls.length - previewUrls.length}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
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
  const _SoftPanel({required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.fromLTRB(24, 24, 24, 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF7FBFF), Color(0xFFF2F8FE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A16486E),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.eyebrow,
    required this.title,
    this.subtitle,
    required this.canEdit,
    required this.onEdit,
  });

  final String eyebrow;
  final String title;
  final String? subtitle;
  final bool canEdit;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eyebrow.toUpperCase(),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                  color: AppColors.primaryBlue,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF22313C),
                  height: 1.1,
                ),
              ),
              if ((subtitle ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 7),
                Text(
                  subtitle!,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF677581),
                    height: 1.35,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (canEdit)
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: _EditIconButton(onPressed: onEdit, compact: true),
          ),
      ],
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 42, maxWidth: 260),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF4FB),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF50708E)),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF355066),
              ),
            ),
          ),
        ],
      ),
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

class _EditPillButton extends StatelessWidget {
  const _EditPillButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primaryBlue,
        backgroundColor: const Color(0xFFE9F3FF),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      icon: const Icon(Icons.edit_outlined, size: 16),
      label: const Text(
        'Edit',
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
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
    final dataBytes = _tryDecodeDataImage(url);
    if (dataBytes != null) {
      return Image.memory(
        dataBytes,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _PlaceholderImage(icon: icon);
        },
      );
    }

    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return _PlaceholderImage(icon: icon);
      },
    );
  }
}

Uint8List? _tryDecodeDataImage(String value) {
  if (!value.startsWith('data:image/')) return null;
  final commaIndex = value.indexOf(',');
  if (commaIndex == -1) return null;
  final base64Value = value.substring(commaIndex + 1);
  try {
    return base64Decode(base64Value);
  } catch (_) {
    return null;
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
  final ImagePicker _picker = ImagePicker();
  late final TextEditingController _nameController;
  late final TextEditingController _locationController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _imageUrlController;
  late List<String> _galleryImages;
  bool _isPickingCover = false;
  bool _isPickingGallery = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.about.name);
    _locationController = TextEditingController(text: widget.about.location);
    _descriptionController = TextEditingController(
      text: widget.about.description,
    );
    _imageUrlController = TextEditingController(text: widget.about.imageUrl);
    _galleryImages = List<String>.from(widget.about.galleryUrls);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
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
              const SizedBox(height: 6),
              const Text(
                'Add a cover image and gallery photos directly from your device, or keep using image URLs if you prefer.',
                style: TextStyle(
                  color: AppColors.secondaryText,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 16),
              _field(_nameController, 'Condo name'),
              const SizedBox(height: 12),
              _field(_locationController, 'Location'),
              const SizedBox(height: 12),
              _ImageEditorSection(
                title: 'Cover image',
                imageValue: _imageUrlController.text.trim(),
                emptyLabel: 'No cover image selected yet.',
                isPicking: _isPickingCover,
                onPick: _pickCoverImage,
                onRemove: _imageUrlController.text.trim().isEmpty
                    ? null
                    : _removeCoverImage,
              ),
              const SizedBox(height: 10),
              _field(
                _imageUrlController,
                'Or paste cover image URL',
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              _field(
                _descriptionController,
                'Description',
                minLines: 3,
                maxLines: 5,
              ),
              const SizedBox(height: 12),
              _GalleryEditorSection(
                images: _galleryImages,
                isPicking: _isPickingGallery,
                onAddImages: _pickGalleryImages,
                onRemoveImage: _removeGalleryImage,
              ),
              const SizedBox(height: 10),
              _GalleryUrlPasteField(
                onAddUrl: _addGalleryUrl,
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

  Future<void> _pickCoverImage() async {
    setState(() => _isPickingCover = true);
    try {
      final file = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 72,
        maxWidth: 1800,
      );
      if (file == null) return;
      final dataImage = await _xFileToDataImage(file);
      if (!mounted) return;
      setState(() => _imageUrlController.text = dataImage);
    } finally {
      if (mounted) setState(() => _isPickingCover = false);
    }
  }

  Future<void> _pickGalleryImages() async {
    setState(() => _isPickingGallery = true);
    try {
      final files = await _picker.pickMultiImage(
        imageQuality: 72,
        maxWidth: 1800,
      );
      if (files.isEmpty) return;
      final converted = <String>[];
      for (final file in files) {
        converted.add(await _xFileToDataImage(file));
      }
      if (!mounted) return;
      setState(() => _galleryImages = [..._galleryImages, ...converted]);
    } finally {
      if (mounted) setState(() => _isPickingGallery = false);
    }
  }

  Future<String> _xFileToDataImage(XFile file) async {
    final bytes = await file.readAsBytes();
    final mimeType = _mimeTypeFor(file.name);
    return 'data:$mimeType;base64,${base64Encode(bytes)}';
  }

  String _mimeTypeFor(String filename) {
    final normalized = filename.toLowerCase();
    if (normalized.endsWith('.png')) return 'image/png';
    if (normalized.endsWith('.webp')) return 'image/webp';
    if (normalized.endsWith('.gif')) return 'image/gif';
    if (normalized.endsWith('.heic')) return 'image/heic';
    return 'image/jpeg';
  }

  void _removeCoverImage() {
    setState(() => _imageUrlController.clear());
  }

  void _removeGalleryImage(int index) {
    setState(() => _galleryImages.removeAt(index));
  }

  void _addGalleryUrl(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return;
    setState(() => _galleryImages = [..._galleryImages, trimmed]);
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    int minLines = 1,
    int maxLines = 1,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: controller,
      minLines: minLines,
      maxLines: maxLines,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }

  void _save() {
    Navigator.pop(
      context,
      widget.about.copyWith(
        name: _nameController.text,
        location: _locationController.text,
        description: _descriptionController.text,
        imageUrl: _imageUrlController.text.trim(),
        galleryUrls: _galleryImages
            .map((url) => url.trim())
            .where((url) => url.isNotEmpty)
            .toList(),
      ),
    );
  }
}

class _ImageEditorSection extends StatelessWidget {
  const _ImageEditorSection({
    required this.title,
    required this.imageValue,
    required this.emptyLabel,
    required this.isPicking,
    required this.onPick,
    required this.onRemove,
  });

  final String title;
  final String imageValue;
  final String emptyLabel;
  final bool isPicking;
  final VoidCallback onPick;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final hasImage = imageValue.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.creamWhite,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.softGray),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: AspectRatio(
                  aspectRatio: 1.4,
                  child: hasImage
                      ? _NetworkOrPlaceholder(
                          imageUrl: imageValue,
                          icon: Icons.apartment_rounded,
                        )
                      : const _PlaceholderImage(icon: Icons.apartment_rounded),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                hasImage ? 'Image ready' : emptyLabel,
                style: const TextStyle(
                  color: AppColors.secondaryText,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: isPicking ? null : onPick,
                      icon: Icon(
                        isPicking
                            ? Icons.hourglass_top_rounded
                            : Icons.add_photo_alternate_outlined,
                        size: 18,
                      ),
                      label: Text(isPicking ? 'Picking...' : 'Choose image'),
                    ),
                  ),
                  if (onRemove != null) ...[
                    const SizedBox(width: 10),
                    OutlinedButton(
                      onPressed: onRemove,
                      child: const Text('Remove'),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GalleryEditorSection extends StatelessWidget {
  const _GalleryEditorSection({
    required this.images,
    required this.isPicking,
    required this.onAddImages,
    required this.onRemoveImage,
  });

  final List<String> images;
  final bool isPicking;
  final VoidCallback onAddImages;
  final ValueChanged<int> onRemoveImage;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Gallery images',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            Text(
              '${images.length} selected',
              style: const TextStyle(
                color: AppColors.secondaryText,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.creamWhite,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.softGray),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (images.isEmpty)
                const SizedBox(
                  height: 110,
                  child: Center(
                    child: Text(
                      'No gallery photos selected yet.',
                      style: TextStyle(
                        color: AppColors.secondaryText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: images.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 0.95,
                  ),
                  itemBuilder: (context, index) {
                    return Stack(
                      children: [
                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: _NetworkOrPlaceholder(
                              imageUrl: images[index],
                              icon: Icons.image_outlined,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 6,
                          right: 6,
                          child: Material(
                            color: Colors.black.withValues(alpha: 0.58),
                            shape: const CircleBorder(),
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: () => onRemoveImage(index),
                              child: const Padding(
                                padding: EdgeInsets.all(6),
                                child: Icon(
                                  Icons.close_rounded,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isPicking ? null : onAddImages,
                  icon: Icon(
                    isPicking
                        ? Icons.hourglass_top_rounded
                        : Icons.collections_outlined,
                    size: 18,
                  ),
                  label: Text(isPicking ? 'Picking...' : 'Add gallery photos'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GalleryUrlPasteField extends StatefulWidget {
  const _GalleryUrlPasteField({required this.onAddUrl});

  final ValueChanged<String> onAddUrl;

  @override
  State<_GalleryUrlPasteField> createState() => _GalleryUrlPasteFieldState();
}

class _GalleryUrlPasteFieldState extends State<_GalleryUrlPasteField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            decoration: const InputDecoration(
              labelText: 'Or paste one gallery image URL',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        const SizedBox(width: 10),
        ElevatedButton(
          onPressed: () {
            final value = _controller.text.trim();
            if (value.isEmpty) return;
            widget.onAddUrl(value);
            _controller.clear();
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}
