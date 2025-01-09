import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../styles/colors.dart';

class RecoveryPasswordScreen extends StatefulWidget {
  const RecoveryPasswordScreen({super.key});

  @override
  _RecoveryPasswordScreenState createState() => _RecoveryPasswordScreenState();
}

class _RecoveryPasswordScreenState extends State<RecoveryPasswordScreen> {
  final SupabaseClient supabase = Supabase.instance.client;

  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmNewPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _showCurrentPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;

  String? _currentPasswordError;
  String? _newPasswordError;
  String? _confirmNewPasswordError;

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  bool _isPasswordValid(String password) {
    final passwordRegex =
        RegExp(r'^(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$');
    return passwordRegex.hasMatch(password);
  }

  Future<void> _changePassword() async {
    setState(() {
      _currentPasswordError = _currentPasswordController.text.trim().isEmpty
          ? 'La contraseña actual es obligatoria.'
          : null;

      _newPasswordError = _newPasswordController.text.trim().isEmpty
          ? 'La nueva contraseña es obligatoria.'
          : !_isPasswordValid(_newPasswordController.text.trim())
              ? 'Debe tener 8 caracteres, 1 mayúscula, 1 número y 1 símbolo.'
              : null;

      _confirmNewPasswordError = _confirmNewPasswordController.text.trim().isEmpty
          ? 'Confirma tu nueva contraseña.'
          : _newPasswordController.text.trim() !=
                  _confirmNewPasswordController.text.trim()
              ? 'Las contraseñas no coinciden.'
              : null;
    });

    if (_currentPasswordError != null ||
        _newPasswordError != null ||
        _confirmNewPasswordError != null) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Cambiar la contraseña en Supabase
      await supabase.auth.updateUser(
        UserAttributes(password: _newPasswordController.text.trim()),
      );

      _showSnackBar('Contraseña actualizada exitosamente.');
      Navigator.pop(context); // Regresar a la pantalla anterior
    } catch (error) {
      _showSnackBar('Error al actualizar la contraseña: $error');
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
          "Cambiar Contraseña",
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
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 30.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                Text(
                  "Actualiza tu contraseña",
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 40),
                _buildTextField(
                  "Contraseña Actual",
                  Icons.lock,
                  _currentPasswordController,
                  _currentPasswordError,
                  !_showCurrentPassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _showCurrentPassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: AppColors.iconSelected,
                    ),
                    onPressed: () {
                      setState(() {
                        _showCurrentPassword = !_showCurrentPassword;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  "Nueva Contraseña",
                  Icons.lock_outline,
                  _newPasswordController,
                  _newPasswordError,
                  !_showNewPassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _showNewPassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: AppColors.iconSelected,
                    ),
                    onPressed: () {
                      setState(() {
                        _showNewPassword = !_showNewPassword;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  "Confirmar Nueva Contraseña",
                  Icons.lock_outline,
                  _confirmNewPasswordController,
                  _confirmNewPasswordError,
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
                  onPressed: _isLoading ? null : _changePassword,
                  child: _isLoading
                      ? CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        )
                      : Text(
                          "ACTUALIZAR",
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.white,
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
        if (errorText != null)
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
