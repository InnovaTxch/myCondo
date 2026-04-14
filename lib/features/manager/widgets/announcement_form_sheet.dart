import 'package:flutter/material.dart';
import 'package:mycondo/data/models/manager/announcement_models.dart';

class AnnouncementFormSheet extends StatefulWidget {
  const AnnouncementFormSheet({
    super.key,
    this.existing,
    required this.onSave,
    required this.managerName,
  });

  final Announcement? existing;
  final Future<void> Function(String title, String message, String category)
      onSave;
  final String managerName;

  @override
  State<AnnouncementFormSheet> createState() => _AnnouncementFormSheetState();
}

class _AnnouncementFormSheetState extends State<AnnouncementFormSheet> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _messageCtrl;
  late String _category;
  bool _saving = false;

  static const List<(String, String, IconData, Color)> _categories = [
    ('urgent', 'Urgent', Icons.warning_rounded, Color(0xFFE05555)),
    ('reminder', 'Reminder', Icons.access_time_rounded, Color(0xFFE8A020)),
    ('info', 'Info', Icons.info_outline_rounded, Color(0xFF3A8FE8)),
  ];

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.existing?.title ?? '');
    _messageCtrl = TextEditingController(text: widget.existing?.message ?? '');
    _category = widget.existing?.category ?? 'info';
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final title = _titleCtrl.text.trim();
    final message = _messageCtrl.text.trim();
    if (title.isEmpty || message.isEmpty) return;

    setState(() => _saving = true);
    try {
      await widget.onSave(title, message, _category);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  color: const Color(0xFFDDDDDD),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            Text(
              isEdit ? 'Edit Announcement' : 'Post New Announcement',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 18),
            // Category selector
            const Text(
              'Category',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF888888)),
            ),
            const SizedBox(height: 8),
            Row(
              children: _categories.map((cat) {
                final isSelected = _category == cat.$1;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _category = cat.$1),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? cat.$4.withOpacity(0.12) : const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? cat.$4 : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(cat.$3,
                              color: isSelected ? cat.$4 : const Color(0xFFAAAAAA),
                              size: 20),
                          const SizedBox(height: 4),
                          Text(
                            cat.$2,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? cat.$4 : const Color(0xFFAAAAAA),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            // Title field
            _InputLabel(label: 'Title'),
            const SizedBox(height: 6),
            TextField(
              controller: _titleCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: _inputDecoration('e.g. Power Outage Notice'),
            ),
            const SizedBox(height: 14),
            // Message field
            _InputLabel(label: 'Message'),
            const SizedBox(height: 6),
            TextField(
              controller: _messageCtrl,
              maxLines: 3,
              decoration: _inputDecoration('Write your announcement here...'),
            ),
            const SizedBox(height: 22),
            // Submit button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _saving ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A1A1A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        isEdit ? 'Save Changes' : 'Post Announcement',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFFBBBBBB), fontSize: 13),
      filled: true,
      fillColor: const Color(0xFFF7F7F7),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF1A1A1A), width: 1.5),
      ),
    );
  }
}

class _InputLabel extends StatelessWidget {
  const _InputLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Color(0xFF888888),
      ),
    );
  }
}