import 'package:flutter/material.dart';

import 'package:mycondo/data/repositories/onboarding/onboarding_service.dart';

import 'package:mycondo/features/shared/widgets/role_card.dart';
import 'package:mycondo/features/shared/widgets/input_field.dart';
import 'package:mycondo/features/shared/widgets/submit_button.dart';



class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final OnboardingService _service = OnboardingService();
  final _extraInfoController = TextEditingController();

  String selectedRole = "unassigned";
  bool _isLoading = false;

  void _handleFinalSubmit() async {
    final input = _extraInfoController.text.trim();
    if (input.isEmpty || selectedRole == "unassigned") return;

    setState(() => _isLoading = true);

    try {
      switch (selectedRole) {
        case "manager":
          await _service.setupManagerAccount(input);
          break;
        case "resident":
          // await _service.setupResidentAccount(input);
          break;
      }

      if (!mounted) return;

      Navigator.pushReplacementNamed(
        context, 
        selectedRole == 'manager' ? '/manager-dashboard' : '/resident-dashboard'
      );

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
    _extraInfoController.addListener(() =>setState(() {}));
  }

  @override
  void dispose() {
    _extraInfoController.dispose(); // Always clean up your controllers
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView( // Added to prevent overflow when keyboard appears
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Tell us about yourself", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 32),
              
              // Role Selection
              RoleCard(
                title: "I am a Resident",
                description: "I want to pay rent and view notices.",
                icon: Icons.home_work_outlined,
                isSelected: selectedRole == 'resident',
                onTap: () {
                  setState(() {
                    selectedRole = 'resident';
                    _extraInfoController.clear(); // Clear if they switch roles
                  });
                },
              ),
              const SizedBox(height: 16),
              RoleCard(
                title: "I am a Manager",
                description: "I manage properties and tenants.",
                icon: Icons.admin_panel_settings_outlined,
                isSelected: selectedRole == 'manager',
                onTap: () {
                  setState(() {
                    selectedRole = 'manager';
                    _extraInfoController.clear();
                  });
                },
              ),

              const SizedBox(height: 32),

              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: selectedRole == "unassigned"
                    ? const SizedBox.shrink()
                    : Column(
                        key: ValueKey(selectedRole),
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            selectedRole == 'manager' 
                                ? "Condominium Name" 
                                : "Enter Condo Code",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          InputField(
                            hint: selectedRole == 'manager' 
                                ? "e.g. Blue Residences" 
                                : "e.g. ABCD1234",
                            controller: _extraInfoController,
                          ),
                        ],
                      ),
              ),
              
              const SizedBox(height: 32),

              SubmitButton(
                text: "Get Started",
                onPressed: selectedRole != "unassigned" && _extraInfoController.text.isNotEmpty
                    ? _handleFinalSubmit
                    : null,
                color: Color(0xFF5DA9E9),
                isLoading: _isLoading
              ),
            ],
          ),
        ),
      ),
    );
  }
}
