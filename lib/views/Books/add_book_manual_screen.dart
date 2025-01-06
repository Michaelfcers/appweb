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

  // Control de errores para cada campo
  bool _titleError = false;
  bool _authorError = false;
  bool _genreError = false;
  bool _descriptionError = false;
  bool _conditionError = false;
  bool _imageError = false;

  Future<void> _addManualBook() async {
    // Validación de los campos obligatorios
    setState(() {
      _titleError = _titleController.text.trim().isEmpty;
      _authorError = _authorController.text.trim().isEmpty;
      _genreError = _genreController.text.trim().isEmpty;
      _descriptionError = _descriptionController.text.trim().isEmpty;
      _conditionError = _conditionController.text.trim().isEmpty;
      _imageError = _uploadedPhotos.isEmpty;
    });

    if (_titleError ||
        _authorError ||
        _genreError ||
        _descriptionError ||
        _conditionError ||
        _imageError) return;

    setState(() {
      _isLoading = true;
    });

    try {
      List<String> uploadedUrls = [];
      for (int i = 0; i < _uploadedPhotos.length; i++) {
        final imageUrl = await _userService.uploadImageToStorage(
          _uploadedPhotos[i].path,
          'image_${DateTime.now().millisecondsSinceEpoch}_$i.jpg',
        );
        uploadedUrls.add(imageUrl);
      }

      if (uploadedUrls.isEmpty) {
        throw Exception('Error al subir imágenes. Intenta nuevamente.');
      }

      final thumbnailUrl = uploadedUrls.first;

      await _userService.addBookToUser(
        title: _titleController.text.trim(),
        author: _authorController.text.trim(),
        genre: _genreController.text.trim(),
        description: _descriptionController.text.trim(),
        condition: _conditionController.text.trim(),
        photos: uploadedUrls,
        thumbnail: thumbnailUrl,
      );

      if (!mounted) return;

      _showSuccessDialog();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al agregar el libro: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile>? images = await picker.pickMultiImage();

    if (images != null) {
      setState(() {
        _uploadedPhotos.addAll(images.map((img) => File(img.path)));
        _imageError = false;
      });
    }
  }

  void _reorderImages(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final File movedImage = _uploadedPhotos.removeAt(oldIndex);
      _uploadedPhotos.insert(newIndex, movedImage);
    });
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
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildThumbnail(),
                const SizedBox(height: 24),
                _buildTextField(_titleController, 'Título', _titleError),
                const SizedBox(height: 10),
                _buildTextField(_authorController, 'Autor', _authorError),
                const SizedBox(height: 10),
                _buildTextField(_genreController, 'Género', _genreError),
                const SizedBox(height: 10),
                _buildTextField(
                    _descriptionController, 'Descripción / Sinopsis', _descriptionError),
                const SizedBox(height: 10),
                _buildTextField(_conditionController, 'Condición', _conditionError),
                const SizedBox(height: 10),
                _buildPhotoPicker(),
                if (_imageError)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      'Sube al menos una imagen',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                const SizedBox(height: 24),
                _buildSubmitButton(),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      color: AppColors.primary,
                      strokeWidth: 4,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Guardando libro...",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildThumbnail() {
    return Container(
      width: 160,
      height: 220,
      decoration: BoxDecoration(
        color: AppColors.shadow,
        borderRadius: BorderRadius.circular(8),
      ),
      child: _uploadedPhotos.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                _uploadedPhotos.first,
                fit: BoxFit.cover,
              ),
            )
          : Center(
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
        if (_uploadedPhotos.isNotEmpty)
          ReorderableListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            onReorder: _reorderImages,
            children: _uploadedPhotos
                .map((photo) => ListTile(
                      key: ValueKey(photo),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          photo,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                        ),
                      ),
                      title: const Text("Arrastra para cambiar portada"),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            _uploadedPhotos.remove(photo);
                          });
                        },
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

  Widget _buildTextField(
      TextEditingController controller, String label, bool hasError) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          onChanged: (value) {
            setState(() {
              if (label == 'Título') _titleError = false;
              if (label == 'Autor') _authorError = false;
              if (label == 'Género') _genreError = false;
              if (label == 'Descripción / Sinopsis') _descriptionError = false;
              if (label == 'Condición') _conditionError = false;
            });
          },
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
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              'Este campo es obligatorio',
              style: TextStyle(color: Colors.red),
            ),
          ),
      ],
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
                Navigator.pop(context, true); // Devuelve `true` a AddBookDialog
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
