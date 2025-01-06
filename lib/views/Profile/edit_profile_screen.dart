import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
  bool isUploadingImage = false; // Animación de carga
  String? avatarUrl;

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
          .select('name, nickname, avatar_url')
          .eq('id', userId)
          .single();

      if (response != null) {
        setState(() {
          nameController.text = response['name'] ?? '';
          nicknameController.text = response['nickname'] ?? '';
          emailController.text = userEmail;
          avatarUrl = response['avatar_url'];
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

  Future<void> _pickAndUploadImage() async {
  final picker = ImagePicker();
  final pickedFile = await picker.pickImage(source: ImageSource.gallery);

  if (pickedFile == null) return;

  setState(() {
    isLoading = true; // Mostrar animación de carga
  });

  try {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      _showErrorDialog("Usuario no autenticado.");
      return;
    }

    // Definir el nombre del archivo basado en el usuario
    final fileName = 'avatars/$userId-avatar.jpg';

    // Leer los bytes de la imagen seleccionada
    final fileBytes = await pickedFile.readAsBytes();

    // Subir el nuevo archivo
    await _supabase.storage
        .from('avatars')
        .uploadBinary(fileName, fileBytes, fileOptions: const FileOptions(upsert: true));

    // Obtener la nueva URL pública con cache busting
    final publicUrl =
        '${_supabase.storage.from('avatars').getPublicUrl(fileName)}?t=${DateTime.now().millisecondsSinceEpoch}';

    // Actualizar la URL en la base de datos del usuario
    final response = await _supabase
        .from('users')
        .update({'avatar_url': publicUrl})
        .eq('id', userId)
        .select(); // Asegurar obtener la respuesta actualizada

    // Verificar si hubo algún error en la respuesta
    if (response.isNotEmpty) {
      final updatedAvatarUrl = response[0]['avatar_url'];
      setState(() {
        avatarUrl = updatedAvatarUrl; // Actualizar la imagen de perfil en tiempo real
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Imagen de perfil actualizada con éxito.')),
      );
    } else {
      throw Exception("Error al actualizar la imagen en la base de datos.");
    }
  } catch (e) {
    _showErrorDialog("Error al subir la imagen: $e");
  } finally {
    setState(() {
      isLoading = false; // Ocultar animación de carga
    });
  }
}



  Future<void> _saveChanges() async {
    setState(() {
      errorMessages = {"name": null, "nickname": null};
    });

    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

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

    if (hasErrors) {
      setState(() {}); // Actualizar la UI para mostrar errores
      return;
    }

    final updates = {
      'name': name,
      'nickname': nickname,
      'updated_at': DateTime.now().toIso8601String(),
    };

    try {
      await _supabase.from('users').update(updates).eq('id', userId);
      _showSuccessDialog("Perfil actualizado con éxito.");
    } catch (e) {
      _showErrorDialog("No se pudo guardar el perfil.");
    }
  }

  void _showSuccessDialog(String message) {
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
              onPressed: () {
                Navigator.of(context).pop(); // Cierra el diálogo
                Navigator.of(context).pop(true); // Regresa a la pantalla anterior con valor true
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
  child: Stack(
    children: [
      CircleAvatar(
        radius: 60,
        backgroundImage:
            avatarUrl != null ? NetworkImage(avatarUrl!) : null,
        child: avatarUrl == null
            ? Icon(Icons.person, size: 50, color: AppColors.textPrimary)
            : null,
      ),
      if (isUploadingImage)
        Positioned.fill(
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      Positioned(
        bottom: 0,
        right: 0,
        child: InkWell(
          onTap: _pickAndUploadImage,
          child: CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.iconSelected,
            child: const Icon(Icons.camera_alt, color: Colors.white),
          ),
        ),
      ),
    ],
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

  Widget _buildFieldContainer(
      String label, TextEditingController controller, String? error) {
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
          style: const TextStyle(color: Colors.black),
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

  Widget _buildNonEditableFieldContainer(
      String label, TextEditingController controller) {
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
          style: const TextStyle(color: Colors.black),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey.shade300,
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
