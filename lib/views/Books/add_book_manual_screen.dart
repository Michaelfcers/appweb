import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/user_service.dart';
import '../../styles/colors.dart';

class AddBookManualScreen extends StatefulWidget {
  const AddBookManualScreen({super.key});

  @override
  _AddBookManualScreenState createState() => _AddBookManualScreenState();
}

class _AddBookManualScreenState extends State<AddBookManualScreen> {
  final UserService _userService = UserService();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _authorController = TextEditingController();
  final TextEditingController _genreController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _conditionController = TextEditingController();

  final List<File> _uploadedPhotos = [];
  bool _isLoading = false;

  Future<void> _addManualBook() async {
    try {
      if (_titleController.text.trim().isEmpty ||
          _conditionController.text.trim().isEmpty) {
        throw Exception('Por favor, completa todos los campos obligatorios');
      }

      await _userService.addBookToUser(
        title: _titleController.text.trim(),
        author: _authorController.text.trim(),
        genre: _genreController.text.trim(),
        description: _descriptionController.text.trim(),
        condition: _conditionController.text.trim(),
        photos: _uploadedPhotos.map((photo) => photo.path).toList(),
        thumbnail: "", // Sin portada predeterminada
      );

      if (!mounted) return;

      _showSuccessDialog(); // Muestra el diálogo de éxito
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al agregar el libro: $e')),
      );
    }
  }

  Future<void> _pickImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile>? images = await picker.pickMultiImage();

    if (images != null) {
      setState(() {
        _uploadedPhotos.addAll(images.map((img) => File(img.path)));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text(
          "Agregar Libro Manualmente",
          style: TextStyle(color: AppColors.textPrimary),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildThumbnailPlaceholder(),
            const SizedBox(height: 24),
            _buildTextField(_titleController, 'Título'),
            const SizedBox(height: 10),
            _buildTextField(_authorController, 'Autor'),
            const SizedBox(height: 10),
            _buildTextField(_genreController, 'Género'),
            const SizedBox(height: 10),
            _buildTextField(_descriptionController, 'Descripción / Sinopsis'),
            const SizedBox(height: 10),
            _buildTextField(_conditionController, 'Condición'),
            const SizedBox(height: 10),
            _buildPhotoPicker(),
            const SizedBox(height: 24),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnailPlaceholder() {
    return Container(
      width: 160,
      height: 220,
      decoration: BoxDecoration(
        color: AppColors.shadow,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Icon(
          Icons.book,
          size: 50,
          color: AppColors.textPrimary.withOpacity(0.7),
        ),
      ),
    );
  }

  Widget _buildPhotoPicker() {
    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: _pickImages,
          icon: const Icon(Icons.upload_file),
          label: const Text("Subir Imágenes"),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.iconSelected,
          ),
        ),
        Wrap(
          spacing: 8.0,
          runSpacing: 4.0,
          children: _uploadedPhotos
              .map((photo) => ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      photo,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.iconSelected,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      onPressed: _isLoading ? null : _addManualBook,
      child: _isLoading
          ? const CircularProgressIndicator(color: Colors.white)
          : Text(
              "Agregar Libro",
              style: TextStyle(fontSize: 18, color: AppColors.textPrimary),
            ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: AppColors.iconSelected),
        filled: true,
        fillColor: AppColors.cardBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.iconSelected),
        ),
      ),
      style: const TextStyle(color: Colors.black),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 60),
              const SizedBox(height: 10),
              const Text(
                'Éxito',
                style: TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          content: const Text(
            'El libro se guardó con éxito.',
            textAlign: TextAlign.center,
          ),
          actions: [
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.iconSelected,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context); // Cierra el diálogo
                  Navigator.pop(context, true); // Regresa al flujo principal
                },
                child: const Text('Aceptar'),
              ),
            ),
          ],
        );
      },
    );
  }
}
