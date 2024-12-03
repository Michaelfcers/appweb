import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../styles/colors.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final SupabaseClient supabase = Supabase.instance.client;

  // Controladores para los campos de entrada
  final TextEditingController _usernameController = TextEditingController(); // Para el nickname
  final TextEditingController _nameController = TextEditingController(); // Para el nombre
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Método para mostrar mensajes
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // Método para el registro
  Future<void> _signUp() async {
    try {
      // Verificar si el nickname (username) está disponible
      final responseNickname = await supabase
          .from('users')
          .select('id')
          .eq('nickname', _usernameController.text.trim())
          .maybeSingle();

      if (responseNickname != null) {
        _showSnackBar('El nombre de usuario ya está en uso. Por favor, elige otro.');
        return;
      }

      // Crear el usuario en auth.users
      final response = await supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (response.user == null) {
        _showSnackBar('Error al registrarse. Verifica los datos ingresados.');
      } else {
        // Actualizar la tabla public.users con nickname y nombre
        await supabase.from('users').update({
          'nickname': _usernameController.text.trim(),
          'name': _nameController.text.trim(), // Usamos el nameController
        }).eq('id', response.user!.id);

        _showSnackBar(
            'Registro exitoso. Revisa tu correo para confirmar la cuenta.');

        // Navegar a la pantalla de inicio o la que corresponda después del registro
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (error) {
      _showSnackBar('Error al registrarse: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Añadir un controlador para el campo de nombre (opcional)
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
          "Registro",
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
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            Text(
              "Crea una cuenta",
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 40),
            // Campo para el nombre (opcional)
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.person, color: AppColors.iconSelected),
                labelText: "Nombre",
                labelStyle:
                    TextStyle(color: AppColors.textSecondary, fontSize: 18),
                filled: true,
                fillColor: AppColors.cardBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: AppColors.iconSelected, width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: AppColors.iconSelected, width: 2),
                ),
              ),
              style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.person_outline,
                    color: AppColors.iconSelected),
                labelText: "Usuario",
                labelStyle:
                    TextStyle(color: AppColors.textSecondary, fontSize: 18),
                filled: true,
                fillColor: AppColors.cardBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: AppColors.iconSelected, width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: AppColors.iconSelected, width: 2),
                ),
              ),
              style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.email, color: AppColors.iconSelected),
                labelText: "Correo",
                labelStyle:
                    TextStyle(color: AppColors.textSecondary, fontSize: 18),
                filled: true,
                fillColor: AppColors.cardBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: AppColors.iconSelected, width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: AppColors.iconSelected, width: 2),
                ),
              ),
              style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.lock, color: AppColors.iconSelected),
                labelText: "Contraseña",
                labelStyle:
                    TextStyle(color: AppColors.textSecondary, fontSize: 18),
                filled: true,
                fillColor: AppColors.cardBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: AppColors.iconSelected, width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: AppColors.iconSelected, width: 2),
                ),
              ),
              style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.iconSelected,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding:
                    const EdgeInsets.symmetric(vertical: 18, horizontal: 100),
              ),
              onPressed: _signUp,
              child: Text(
                "REGISTRARSE",
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(
                "¿Ya tienes una cuenta? Inicia Sesión",
                style: TextStyle(
                  color: AppColors.iconSelected,
                  fontSize: 16,
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