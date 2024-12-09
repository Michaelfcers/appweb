import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../styles/colors.dart';
import '../../styles/theme_notifier.dart';
import '../../auth_notifier.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text(
          "Configuración",
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          SwitchListTile(
            activeColor: AppColors.iconSelected,
            contentPadding: EdgeInsets.zero,
            title: Text(
              "Modo Oscuro",
              style: TextStyle(
                fontSize: 18,
                color: AppColors.textPrimary,
              ),
            ),
            value: themeNotifier.isDarkMode,
            onChanged: (bool value) {
              themeNotifier.updateTheme(value ? ThemeMode.dark : ThemeMode.light);
              AppColors.toggleTheme(value);
            },
          ),
          Divider(color: AppColors.divider),
          const SizedBox(height: 20),
          _buildSectionTitle("Seguridad"),
          const SizedBox(height: 10),
          _buildSettingsOption(
            context,
            icon: Icons.description,
            title: "Políticas de uso",
            onTap: () {
              // Implementar lógica para ver políticas de uso
            },
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.iconSelected,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(vertical: 15),
            ),
            onPressed: () => _showLogoutConfirmationDialog(context),
            child: Text(
              "Cerrar sesión",
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper para crear títulos de secciones
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: AppColors.iconSelected,
      ),
    );
  }

  // Helper para crear opciones de configuración
  Widget _buildSettingsOption(BuildContext context,
      {required IconData icon, required String title, VoidCallback? onTap}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8.0),
      leading: Icon(icon, color: AppColors.iconSelected, size: 28),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
      ),
      onTap: onTap,
    );
  }

  void _showLogoutConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.dialogBackground,
          title: Text(
            "Cerrar sesión",
            style: TextStyle(
              color: AppColors.dialogText,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            "¿Estás seguro de que quieres cerrar sesión?",
            style: TextStyle(color: AppColors.dialogText),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: Text(
                "Cancelar",
                style: TextStyle(color: AppColors.iconSelected),
              ),
            ),
            TextButton(
              onPressed: () async {
                final authNotifier = Provider.of<AuthNotifier>(context, listen: false);
                await authNotifier.logOut();
                Navigator.of(dialogContext).pop();
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                });
              },
              child: Text(
                "Cerrar sesión",
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }
}
