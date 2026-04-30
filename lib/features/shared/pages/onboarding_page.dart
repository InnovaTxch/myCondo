import 'package:flutter/material.dart';

import 'package:mycondo/data/repositories/onboarding/onboarding_service.dart';

import 'package:mycondo/features/shared/widgets/input_field.dart';
import 'package:mycondo/features/shared/widgets/submit_button.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final OnboardingService _service = OnboardingService();
  final _formKey = GlobalKey<FormState>();
  final _condoNameController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _galleryController = TextEditingController();

  bool _isLoading = false;

  void _handleFinalSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _service.setupManagerAccount(
        ManagerCondoSetupInput(
          name: _condoNameController.text,
          location: _locationController.text,
          description: _descriptionController.text,
          imageUrl: _imageUrlController.text,
          galleryUrls: _parseGalleryUrls(_galleryController.text),
        ),
      );

      if (!mounted) return;

      Navigator.pushReplacementNamed(context, '/manager-dashboard');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _condoNameController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _condoNameController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    _galleryController.dispose();
    super.dispose();
  }

  List<String> _parseGalleryUrls(String value) {
    return value
        .split(RegExp(r'[\n,]+'))
        .map((url) => url.trim())
        .where((url) => url.isNotEmpty)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Set up your condo",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                "Only managers can sign up. Residents get their account from their condo manager.",
                style: TextStyle(
                  color: Colors.black.withValues(alpha: 0.6),
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 32),

              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FieldLabel("Condominium Name"),
                    InputField(
                      hint: "e.g. Blue Residences",
                      controller: _condoNameController,
                      validator: (value) {
                        if ((value ?? '').trim().isEmpty) {
                          return 'Condo name is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),
                    _FieldLabel("Location"),
                    InputField(
                      hint: "e.g. Quezon City, Metro Manila",
                      controller: _locationController,
                    ),
                    const SizedBox(height: 18),
                    _FieldLabel("Description"),
                    _LargeInputField(
                      hint:
                          "Add a short description residents will see in About.",
                      controller: _descriptionController,
                    ),
                    const SizedBox(height: 18),
                    _FieldLabel("Main Condo Image URL"),
                    InputField(
                      hint: "https://example.com/condo.jpg",
                      controller: _imageUrlController,
                    ),
                    const SizedBox(height: 18),
                    _FieldLabel("Gallery Image URLs"),
                    _LargeInputField(
                      hint:
                          "Paste one URL per line, or separate them with commas.",
                      controller: _galleryController,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              SubmitButton(
                text: "Start Managing",
                onPressed: _condoNameController.text.trim().isNotEmpty
                    ? _handleFinalSubmit
                    : null,
                color: Color(0xFF5DA9E9),
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
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
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _LargeInputField extends StatelessWidget {
  const _LargeInputField({
    required this.hint,
    required this.controller,
  });

  final String hint;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      minLines: 3,
      maxLines: 5,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 14,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: Color(0xFF5DA9E9)),
        ),
      ),
    );
  }
}
