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

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isLoading = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;

  String? _usernameError;
  String? _nameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showSuccessDialog() {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      backgroundColor: AppColors.dialogBackground,
      contentPadding: const EdgeInsets.all(20),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 60),
          const SizedBox(height: 16),
          Text(
            "Éxito",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.dialogTitleText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Registro exitoso. Revisa tu correo para confirmar la cuenta.",
            style: TextStyle(
              fontSize: 16,
              color: AppColors.dialogBodyText,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      actions: [
        Center(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.iconSelected,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              Navigator.of(context).pop(); // Cierra el diálogo
              Navigator.pushReplacementNamed(context, '/login'); // Envía al login
            },
            child: const Text(
              "Aceptar",
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFFF1EFE7),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

  bool _isEmailValid(String email) {
    final emailRegex =
        RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(email);
  }

  bool _isPasswordValid(String password) {
    final passwordRegex =
        RegExp(r'^(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$');
    return passwordRegex.hasMatch(password);
  }

  Future<void> _signUp() async {
  setState(() {
    _usernameError = _usernameController.text.trim().isEmpty
        ? 'El nombre de usuario es obligatorio.'
        : null;

    _nameError = _nameController.text.trim().isEmpty
        ? 'El nombre es obligatorio.'
        : null;

    _emailError = _emailController.text.trim().isEmpty
        ? 'El correo es obligatorio.'
        : !_isEmailValid(_emailController.text.trim())
            ? 'Por favor, ingresa un correo válido.'
            : null;

    _passwordError = _passwordController.text.trim().isEmpty
        ? 'La contraseña es obligatoria.'
        : !_isPasswordValid(_passwordController.text.trim())
            ? 'Debe tener 8 caracteres, 1 mayúscula, 1 número y 1 símbolo.'
            : null;

    _confirmPasswordError = _confirmPasswordController.text.trim().isEmpty
        ? 'Confirma tu contraseña.'
        : _passwordController.text.trim() !=
                _confirmPasswordController.text.trim()
            ? 'Las contraseñas no coinciden.'
            : null;
  });

  if (_usernameError != null ||
      _nameError != null ||
      _emailError != null ||
      _passwordError != null ||
      _confirmPasswordError != null) {
    return;
  }

  setState(() {
    _isLoading = true;
  });

  try {
    // Registrar usuario en Supabase Auth
    final response = await supabase.auth.signUp(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );

    if (response.user == null) {
      _showSnackBar(
          'Error al registrarse. Verifica los datos ingresados.');
      return;
    }

    // Obtener el ID del usuario creado
    final userId = response.user!.id;

    // Comprobar si el usuario ya existe en la tabla `users`
    final existingUser = await supabase
        .from('users')
        .select('id')
        .eq('id', userId)
        .maybeSingle();

    if (existingUser == null) {
      // Insertar nickname y name en la tabla `users`
      await supabase.from('users').insert({
        'id': userId,
        'nickname': _usernameController.text.trim(),
        'name': _nameController.text.trim(),
      });
    } else {
      // Actualizar nickname y name en caso de que el usuario ya exista
      await supabase.from('users').update({
        'nickname': _usernameController.text.trim(),
        'name': _nameController.text.trim(),
      }).eq('id', userId);
    }

    _showSuccessDialog(); // Mostrar el diálogo de éxito
  } catch (error) {
    _showSnackBar('Error al registrarse: $error');
  } finally {
    setState(() {
      _isLoading = false;
    });
  }
}


  @override
  Widget build(BuildContext context) {
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
      body: Stack(
        children: [
          SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(horizontal: 20.0, vertical: 30.0),
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
                _buildTextField(
                    "Nombre", Icons.person, _nameController, _nameError, false),
                const SizedBox(height: 20),
                _buildTextField("Usuario", Icons.person_outline,
                    _usernameController, _usernameError, false),
                const SizedBox(height: 20),
                _buildTextField("Correo", Icons.email, _emailController,
                    _emailError, false,
                    keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 20),
                _buildTextField(
                  "Contraseña",
                  Icons.lock,
                  _passwordController,
                  _passwordError,
                  !_showPassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _showPassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: AppColors.iconSelected,
                    ),
                    onPressed: () {
                      setState(() {
                        _showPassword = !_showPassword;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  "Confirmar Contraseña",
                  Icons.lock,
                  _confirmPasswordController,
                  _confirmPasswordError,
                  !_showConfirmPassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _showConfirmPassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: AppColors.iconSelected,
                    ),
                    onPressed: () {
                      setState(() {
                        _showConfirmPassword = !_showConfirmPassword;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.iconSelected,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                        vertical: 18, horizontal: 100),
                  ),
                  onPressed: _isLoading ? null : _signUp,
                  child: _isLoading
                      ? CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        )
                      : Text(
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
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label,
    IconData icon,
    TextEditingController controller,
    String? errorText,
    bool obscureText, {
    Widget? suffixIcon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppColors.iconSelected),
            labelText: label,
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
            suffixIcon: suffixIcon,
          ),
          style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
        ),
        if (errorText != null) // Mostrar el error debajo del campo
          Padding(
            padding: const EdgeInsets.only(top: 5.0),
            child: Text(
              errorText,
              style: TextStyle(color: Colors.red, fontSize: 14),
            ),
          ),
      ],
    );
  }
}
