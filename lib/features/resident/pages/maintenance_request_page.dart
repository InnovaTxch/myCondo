import 'package:flutter/material.dart';
import 'package:mycondo/theme/app_theme.dart';
import 'package:mycondo/data/repositories/resident/maintenance_request_service.dart';
import 'package:mycondo/utils/app_snackbar.dart';
import 'package:mycondo/features/shared/widgets/app_states.dart';

class MaintenanceRequestPage extends StatefulWidget {
  const MaintenanceRequestPage({super.key});

  @override
  State<MaintenanceRequestPage> createState() => _MaintenanceRequestPageState();
}

class _MaintenanceRequestPageState extends State<MaintenanceRequestPage> {
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
      Navigator.pop(context);
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
                padding: const EdgeInsets.fromLTRB(24, 18, 24, 32),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.chevron_left_rounded),
                      label: const Text('Back'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.black,
                        textStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.fromLTRB(22, 32, 22, 36),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x19000000),
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Center(
                            child: Text(
                              'Maintenance Request Form',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          const SizedBox(height: 30),
                          Container(
                            padding: const EdgeInsets.fromLTRB(14, 16, 14, 22),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFF55AEFF),
                                width: 1.3,
                              ),
                            ),
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
                                        validator: _required,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _RequestTextField(
                                        controller: _lastNameController,
                                        hintText: 'Last Name',
                                        validator: _required,
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
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const _FieldLabel('Room Number'),
                                          _RequestTextField(
                                            controller: _roomController,
                                            hintText: 'i.e. Room 1',
                                            validator: _required,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const _FieldLabel('Priority Level'),
                                          _RequestDropdown(
                                            value: _priority,
                                            hintText: 'Priority Level',
                                            items: _priorities,
                                            onChanged: (value) => setState(
                                              () => _priority = value,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                const _FieldLabel('Type of Problem'),
                                _RequestDropdown(
                                  value: _problemType,
                                  hintText: 'Type of Problem',
                                  items: _problemTypes,
                                  onChanged: (value) =>
                                      setState(() => _problemType = value),
                                ),
                                const SizedBox(height: 16),
                                const _FieldLabel(
                                  'Please describe the problem',
                                ),
                                _RequestTextField(
                                  controller: _descriptionController,
                                  hintText: 'Description here.',
                                  minLines: 9,
                                  maxLines: 12,
                                  validator: _required,
                                ),
                                const SizedBox(height: 28),
                                Center(
                                  child: SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: _isSubmitting ? null : _submit,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF55AEF5,
                                        ),
                                        foregroundColor: Colors.white,
                                        minimumSize: const Size.fromHeight(48),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            24,
                                          ),
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
                                              'Submit',
                                              style: TextStyle(fontSize: 16),
                                            ),
                                    ),
                                  ),
                                ),
                              ],
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
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.black,
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
  });

  final TextEditingController controller;
  final String hintText;
  final String? Function(String?)? validator;
  final int minLines;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      minLines: minLines,
      maxLines: maxLines,
      validator: validator,
      decoration: _fieldDecoration(hintText),
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

InputDecoration _fieldDecoration(String? hintText) {
  return InputDecoration(
    hintText: hintText,
    hintStyle: const TextStyle(color: Color(0xFF888888), fontSize: 13),
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(7),
      borderSide: const BorderSide(color: Color(0xFF55AEFF), width: 1.4),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(7),
      borderSide: const BorderSide(color: Color(0xFF178BEF), width: 1.6),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(7),
      borderSide: const BorderSide(color: Colors.redAccent, width: 1.2),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(7),
      borderSide: const BorderSide(color: Colors.redAccent, width: 1.4),
    ),
  );
}

