import 'package:flutter/material.dart';
import 'package:mycondo/data/repositories/resident/maintenance_request_service.dart';
import 'package:mycondo/features/shared/widgets/app_states.dart';
import 'package:mycondo/theme/app_theme.dart';
import 'package:mycondo/utils/app_snackbar.dart';

class MaintenanceRequestFormPage extends StatefulWidget {
  const MaintenanceRequestFormPage({super.key});

  @override
  State<MaintenanceRequestFormPage> createState() =>
      _MaintenanceRequestFormPageState();
}

class _MaintenanceRequestFormPageState
    extends State<MaintenanceRequestFormPage> {
  final _service = MaintenanceRequestService();
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _roomController = TextEditingController();
  final _descriptionController = TextEditingController();

  String? _priority;
  String? _problemType;
  bool _isLoading = true;
  bool _isSubmitting = false;

  static const _priorities = ['Low', 'Medium', 'High', 'Urgent'];
  static const _problemTypes = [
    'Plumbing',
    'Electrical',
    'Appliance',
    'Internet',
    'Pest Control',
    'Security',
    'Structural',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _loadResidentDetails();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _roomController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadResidentDetails() async {
    try {
      final details = await _service.fetchResidentDetails();
      if (!mounted) return;
      setState(() {
        _firstNameController.text = details.firstName;
        _lastNameController.text = details.lastName;
        _roomController.text = details.roomNumber;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      context.showAppSnackBar(
        const SnackBar(content: Text('Unable to load resident details.')),
      );
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      await _service.submitRequest(
        MaintenanceRequestInput(
          firstName: _firstNameController.text,
          lastName: _lastNameController.text,
          roomNumber: _roomController.text,
          priority: _priority!,
          problemType: _problemType!,
          description: _descriptionController.text,
        ),
      );
      if (!mounted) return;
      context.showAppSnackBar(
        const SnackBar(content: Text('Maintenance request submitted.')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      context.showAppSnackBar(SnackBar(content: Text('Submission failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBlueBackground,
      body: SafeArea(
        child: _isLoading
            ? const AppLoadingState()
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.chevron_left_rounded),
                      ),
                      const SizedBox(width: 4),
                      const Expanded(
                        child: Text(
                          'Request Maintenance',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: AppColors.darkText,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'Fill out the details and submit your request.',
                      style: TextStyle(
                        color: AppColors.secondaryText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SectionCard(
                    title: 'Request Details',
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _FieldLabel('Name'),
                          Row(
                            children: [
                              Expanded(
                                child: _RequestTextField(
                                  controller: _firstNameController,
                                  hintText: 'First Name',
                                  readOnly: true,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _RequestTextField(
                                  controller: _lastNameController,
                                  hintText: 'Last Name',
                                  readOnly: true,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const _FieldLabel('Room Number'),
                                    _RequestTextField(
                                      controller: _roomController,
                                      hintText: 'Unit or room',
                                      readOnly: true,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const _FieldLabel('Priority'),
                                    _RequestDropdown(
                                      value: _priority,
                                      hintText: 'Select priority',
                                      items: _priorities,
                                      onChanged: (value) =>
                                          setState(() => _priority = value),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          const _FieldLabel('Problem Type'),
                          _RequestDropdown(
                            value: _problemType,
                            hintText: 'Select issue type',
                            items: _problemTypes,
                            onChanged: (value) =>
                                setState(() => _problemType = value),
                          ),
                          const SizedBox(height: 14),
                          const _FieldLabel('Description'),
                          _RequestTextField(
                            controller: _descriptionController,
                            hintText: 'Describe what happened and where.',
                            minLines: 6,
                            maxLines: 8,
                            validator: _required,
                          ),
                          const SizedBox(height: 18),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isSubmitting ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.darkText,
                                foregroundColor: Colors.white,
                                minimumSize: const Size.fromHeight(50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: _isSubmitting
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'Submit Request',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  String? _required(String? value) {
    if ((value ?? '').trim().isEmpty) return 'Required';
    return null;
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.darkText,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: Color(0xFF5F6F7C),
        ),
      ),
    );
  }
}

class _RequestTextField extends StatelessWidget {
  const _RequestTextField({
    required this.controller,
    required this.hintText,
    this.validator,
    this.minLines = 1,
    this.maxLines = 1,
    this.readOnly = false,
  });

  final TextEditingController controller;
  final String hintText;
  final String? Function(String?)? validator;
  final int minLines;
  final int maxLines;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      minLines: minLines,
      maxLines: maxLines,
      readOnly: readOnly,
      validator: validator,
      decoration: _fieldDecoration(hintText, readOnly: readOnly),
    );
  }
}

class _RequestDropdown extends StatelessWidget {
  const _RequestDropdown({
    required this.value,
    required this.hintText,
    required this.items,
    required this.onChanged,
  });

  final String? value;
  final String hintText;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      hint: Text(hintText, overflow: TextOverflow.ellipsis),
      decoration: _fieldDecoration(null),
      items: items
          .map(
            (item) => DropdownMenuItem<String>(value: item, child: Text(item)),
          )
          .toList(),
      validator: (value) => value == null ? 'Required' : null,
      onChanged: onChanged,
    );
  }
}

InputDecoration _fieldDecoration(String? hintText, {bool readOnly = false}) {
  return InputDecoration(
    hintText: hintText,
    hintStyle: const TextStyle(color: AppColors.secondaryText, fontSize: 13),
    filled: true,
    fillColor: readOnly ? const Color(0xFFEFF4FB) : AppColors.creamWhite,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.softGray),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.errorRed),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.errorRed, width: 1.4),
    ),
  );
}
