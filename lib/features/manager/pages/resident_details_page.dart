import 'package:flutter/material.dart';
import 'package:mycondo/data/models/manager/resident_profile.dart';
import 'package:mycondo/data/repositories/manager/resident_repository.dart';

class ResidentDetailsPage extends StatefulWidget {
  const ResidentDetailsPage({super.key, required this.residentId});

  final String residentId;

  @override
  State<ResidentDetailsPage> createState() => _ResidentDetailsPageState();
}

class _ResidentDetailsPageState extends State<ResidentDetailsPage> {
  final _formKey = GlobalKey<FormState>();
  final ResidentRepository _repository = ResidentRepository.instance;

  final _nameController = TextEditingController();
  final _unitController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _avatarUrlController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isLoading = true;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _unitController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _avatarUrlController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final resident = await _repository.getResidentById(widget.residentId);
    if (!mounted) return;

    if (resident != null) {
      _nameController.text = resident.name;
      _unitController.text = resident.unit;
      _emailController.text = resident.email ?? '';
      _phoneController.text = resident.phone ?? '';
      _avatarUrlController.text = resident.avatarUrl ?? '';
      _notesController.text = resident.notes ?? '';
    }

    setState(() => _isLoading = false);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    await _repository.updateResident(
      widget.residentId,
      ResidentUpsertInput(
        name: _nameController.text,
        unit: _unitController.text,
        email: _emailController.text,
        phone: _phoneController.text,
        avatarUrl: _avatarUrlController.text,
        notes: _notesController.text,
      ),
    );

    if (!mounted) return;
    setState(() => _isEditing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Resident profile updated.')),
    );
  }

  Future<void> _delete() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Remove Resident'),
          content: const Text('This will permanently remove this profile.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;

    await _repository.deleteResident(widget.residentId);

    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Resident Details')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _nameController,
                  enabled: _isEditing,
                  decoration: const InputDecoration(labelText: 'Full Name'),
                  validator: (value) {
                    if ((value ?? '').trim().isEmpty) return 'Name is required';
                    return null;
                  },
                ),
                TextFormField(
                  controller: _unitController,
                  enabled: _isEditing,
                  decoration: const InputDecoration(labelText: 'Unit'),
                  validator: (value) {
                    if ((value ?? '').trim().isEmpty) return 'Unit is required';
                    return null;
                  },
                ),
                TextFormField(
                  controller: _emailController,
                  enabled: _isEditing,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                TextFormField(
                  controller: _phoneController,
                  enabled: _isEditing,
                  decoration: const InputDecoration(labelText: 'Phone'),
                ),
                TextFormField(
                  controller: _avatarUrlController,
                  enabled: _isEditing,
                  decoration: const InputDecoration(labelText: 'Avatar URL'),
                ),
                TextFormField(
                  controller: _notesController,
                  enabled: _isEditing,
                  decoration: const InputDecoration(labelText: 'Notes'),
                  minLines: 2,
                  maxLines: 4,
                ),
                const SizedBox(height: 24),
                if (_isEditing) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _save,
                      child: const Text('Save Changes'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () => setState(() => _isEditing = false),
                    child: const Text('Cancel'),
                  ),
                ] else ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => setState(() => _isEditing = true),
                      child: const Text('Edit Profile'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _delete,
                      child: const Text('Remove Resident'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
