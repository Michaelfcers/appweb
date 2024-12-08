import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../styles/colors.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController nicknameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  bool isLoading = false;

  Map<String, String?> errorMessages = {
    "name": null,
    "nickname": null,
  };

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() {
      isLoading = true;
    });

    final userId = _supabase.auth.currentUser?.id;
    final userEmail = _supabase.auth.currentUser?.email;

    if (userId == null || userEmail == null) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    try {
      final response = await _supabase
          .from('users')
          .select('name, nickname')
          .eq('id', userId)
          .single();

      if (response != null) {
        setState(() {
          nameController.text = response['name'] ?? '';
          nicknameController.text = response['nickname'] ?? '';
          emailController.text = userEmail;
        });
      } else {
        _showErrorDialog("No se encontraron datos del perfil.");
      }
    } catch (e) {
      _showErrorDialog("Error al cargar perfil.");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _saveChanges() async {
    setState(() {
      errorMessages = {"name": null, "nickname": null};
    });

    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    // Validaciones dinámicas
    bool hasErrors = false;

    final name = nameController.text.trim();
    if (name.isEmpty) {
      errorMessages["name"] = "El nombre no puede estar vacío.";
      hasErrors = true;
    } else if (!RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]+$').hasMatch(name)) {
      errorMessages["name"] = "El nombre solo puede contener letras y espacios.";
      hasErrors = true;
    }

    final nickname = nicknameController.text.trim();
    if (nickname.isEmpty) {
      errorMessages["nickname"] = "El nickname no puede estar vacío.";
      hasErrors = true;
    } else if (!RegExp(r'^[a-zA-Z0-9._]+$').hasMatch(nickname)) {
      errorMessages["nickname"] =
          "El nickname solo puede contener letras, números, _ y .";
      hasErrors = true;
    }

    // Mostrar errores si existen
    if (hasErrors) {
      setState(() {});
      return;
    }

    final updates = {
      'name': name,
      'nickname': nickname,
      'updated_at': DateTime.now().toIso8601String(),
    };

    try {
      await _supabase.from('users').update(updates).eq('id', userId);
      _showSuccessDialog();
    } catch (e) {
      _showErrorDialog("No se pudo guardar el perfil.");
    }
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
            "Perfil actualizado con éxito.",
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
            onPressed: () => Navigator.of(context).pop(),
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



  void _showErrorDialog(String message) {
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
          const Icon(Icons.error, color: Colors.red, size: 60),
          const SizedBox(height: 16),
          Text(
            "Error",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.dialogTitleText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
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
            onPressed: () => Navigator.of(context).pop(),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text(
          "Editar Perfil",
          style: TextStyle(color: AppColors.textPrimary),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
              child: Column(
                children: [
                  Center(
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: AppColors.shadow,
                      child: Icon(
                        Icons.person,
                        size: 50,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildFieldContainer(
                      "Nombre", nameController, errorMessages["name"]),
                  const SizedBox(height: 20),
                  _buildFieldContainer(
                      "Nickname", nicknameController, errorMessages["nickname"]),
                  const SizedBox(height: 20),
                  _buildNonEditableFieldContainer("Correo", emailController),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.iconSelected,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: _saveChanges,
                    child: Text(
                      "Guardar cambios",
                      style: TextStyle(color: AppColors.textPrimary),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildFieldContainer(String label, TextEditingController controller, String? error) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 16,
        ),
      ),
      const SizedBox(height: 5),
      TextField(
        controller: controller,
        style: const TextStyle(color: Colors.black), // Texto siempre negro
        decoration: InputDecoration(
          filled: true,
          fillColor: AppColors.cardBackground,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          errorText: error,
        ),
      ),
    ],
  );
}

Widget _buildNonEditableFieldContainer(String label, TextEditingController controller) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 16,
        ),
      ),
      const SizedBox(height: 5),
      TextField(
        controller: controller,
        enabled: false,
        style: const TextStyle(color: Colors.black), // Texto siempre negro
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.grey.shade300, // Fondo gris claro
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    ],
  );
}

}
