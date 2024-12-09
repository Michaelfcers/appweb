import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../styles/colors.dart';
import '../../auth_notifier.dart';
import 'signup_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final TextEditingController emailController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          "Login",
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            Text(
              "BookSwap",
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 50),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.person, color: AppColors.iconSelected),
                labelText: "Correo", // Cambiado para reflejar el campo de correo
                labelStyle: TextStyle(color: AppColors.textSecondary, fontSize: 18),
                filled: true,
                fillColor: AppColors.cardBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.iconSelected, width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.iconSelected, width: 2),
                ),
              ),
              style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.lock, color: AppColors.iconSelected),
                labelText: "Contraseña",
                labelStyle: TextStyle(color: AppColors.textSecondary, fontSize: 18),
                filled: true,
                fillColor: AppColors.cardBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.iconSelected, width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.iconSelected, width: 2),
                ),
              ),
              style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
            ),
            const SizedBox(height: 20),
            Consumer<AuthNotifier>(
              builder: (context, authNotifier, child) {
                return ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.iconSelected,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 100),
                  ),
                  onPressed: () async {
                    final email = emailController.text.trim();
                    final password = passwordController.text.trim();

                    // Validar que los campos no estén vacíos
                    if (email.isEmpty || password.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Por favor, completa todos los campos.')),
                      );
                      return;
                    }

                    // Intentar iniciar sesión
                    try {
                      await authNotifier.logIn(email, password);
                      Navigator.pushReplacementNamed(context, '/home'); // Navegar al home
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: ${e.toString()}')),
                      );
                    }
                  },
                  child: authNotifier.isLoggedIn
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "INGRESAR",
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                );
              },
            ),
            const SizedBox(height: 30),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SignUpScreen()),
                );
              },
              child: Text(
                "¿NO TIENES CUENTA? REGÍSTRATE",
                style: TextStyle(
                  color: AppColors.iconSelected,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
