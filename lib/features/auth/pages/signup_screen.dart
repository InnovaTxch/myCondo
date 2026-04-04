import 'package:flutter/material.dart';
import 'package:mycondo/data/repositories/auth/auth_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen>{
  // get auth service
  final authService = AuthService();

  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;

  // SIGNUP BUTTON PRESSED
  Future <void> signUp() async {
    final isValid = _formKey.currentState!.validate();
    if(!isValid) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    setState(() {
      _isLoading = true;
    });

    try {
      await authService.signUpWithEmailPassword(email, password);
      if(!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Signup successful!")));

    } catch (e) {
      if(!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error signup up: $e")));

    } finally {
      if(!mounted) return;
      setState(() {
        _isLoading = false;
      });

    }

  }

  @override
  void dispose(){
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
  }

  String? emailValidator(String? value) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) {
      return 'Please enter your email';
    }

    if (!text.contains('@') || !text.contains('.')) {
      return 'Please enter a valid email';
    }

    return null;
  }

  String? passwordValidator(String? value) {
    final text = value ?? '';

    if (text.isEmpty) {
      return 'Please enter your password';
    }

    if (text.length < 6) {
      return 'Password must be at least 6 characters';
    }

    return null;
  }

  String? confirmPasswordValidator(String? value) {
    if ((value ?? '').isEmpty) {
      return 'Please confirm your password';
    }

    if (value != _passwordController.text) {
      return 'Passwords do not match';
    }

    return null;
  }


  Widget inputField({
    required String hint,
    required TextEditingController controller,
    String? Function(String?)? validator
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        validator: validator,
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(horizontal: 20),

          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: const BorderSide(color: Color(0xFF5DA9E9)),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: const BorderSide(color: Colors.red),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: const BorderSide(color: Colors.red),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final role =
        ModalRoute.of(context)?.settings.arguments as String? ?? 'tenant';

    return Scaffold(
      backgroundColor: Color(0xFFF4F4F4),

      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 30),

        child: ListView(
          children: [

            const SizedBox(height: 60),

            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("< Back"),
            ),

            const SizedBox(height: 10),

            Text(
              "Create an\naccount.",
              style: TextStyle(
                fontFamily: "Urbanist",
                fontSize: 45,
                fontWeight: FontWeight.w500,
                height: 1.0,
              ),
            ),

            const SizedBox(height: 30),

            Form(
              key: _formKey,
              child: Column(
                children: [
                  inputField(
                    hint: "Email",
                    controller: _emailController,
                    validator: emailValidator,
                  ),
                  inputField(
                    hint: "Password",
                    controller: _passwordController,
                    validator: passwordValidator,
                  ),
                  inputField(
                    hint: "Confirm Password",
                    controller: _confirmPasswordController,
                    validator: confirmPasswordValidator,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF5DA9E9),
                minimumSize: Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),

              onPressed: _isLoading ? null : signUp,

              child: _isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    "Sign up",
                    style: TextStyle(
                      fontFamily: "Urbanist",
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                      height: 1.0,
                    ),
                  ),
            ),

            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Already have an account? ",
                  style: TextStyle(
                    fontFamily: "Urbanist",
                    fontSize: 15,
                    color: Colors.black.withValues(alpha: 0.6),
                    height: 1.0,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(context, '/login');
                  },
                  child: Text(
                    "Log in",
                    style: TextStyle(
                      fontFamily: "Urbanist",
                      fontSize: 15,
                      color: Color(0xFF53B1FD),
                      height: 1.0,
                    ),
                  ),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}
