import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/book_model.dart';
import '../../services/google_books_service.dart';
import '../../services/user_service.dart';
import '../../styles/colors.dart';
import '../Books/add_book_manual_screen.dart';

class AddBookDialog extends StatefulWidget {
  const AddBookDialog({super.key});

  @override
  _AddBookDialogState createState() => _AddBookDialogState();
}

class _AddBookDialogState extends State<AddBookDialog> {
  final GoogleBooksService _googleBooksService = GoogleBooksService();
  final UserService _userService = UserService();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _authorController = TextEditingController();
  final TextEditingController _genreController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _conditionController = TextEditingController();

List<String> _genres = []; // Lista para almacenar los géneros disponibles

@override
void initState() {
  super.initState();
  _loadGenres(); // Llama a la función para cargar los géneros
}

Future<void> _loadGenres() async {
  try {
    final genres = await _userService.fetchGenresFromDatabase();
    setState(() {
      _genres = genres; // Actualiza la lista con los géneros obtenidos
    });
  } catch (e) {
    _showErrorDialog("Error al cargar géneros: ${e.toString()}");
  }
}

  String? _thumbnailUrl;
  bool _isLoading = false;
  bool _titleError = false;
  bool _conditionError = false;
  bool _imageError = false;
  final List<Book> _searchResults = [];
  final List<File> _uploadedPhotos = [];

  Future<void> _fetchBookDetails(Book book) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _titleController.text = book.title;
      _authorController.text = book.author;
      _genreController.text = book.genre ?? '';
      _descriptionController.text = book.description ?? '';
      _thumbnailUrl = book.thumbnail;
      _isLoading = false;
    });
  }

  Future<void> _searchBooks(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults.clear();
      });
      return;
    }

    try {
      final books = await _googleBooksService.fetchBooks(query);
      if (!mounted) return;
      setState(() {
        _searchResults.clear();
        _searchResults.addAll(books);
      });
    } catch (e) {
      _showErrorDialog('Error al buscar libros. Por favor, intenta nuevamente.');
    }
  }

  Future<void> _addBookToUser() async {
    setState(() {
      _titleError = _titleController.text.trim().isEmpty;
      _conditionError = _conditionController.text.trim().isEmpty;
      _imageError = _uploadedPhotos.isEmpty;
    });

    if (_titleError || _conditionError || _imageError) return;

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

      _thumbnailUrl = uploadedUrls.first;

      await _userService.addBookToUser(
        title: _titleController.text.trim(),
        author: _authorController.text.trim(),
        genre: _genreController.text.trim(),
        description: _descriptionController.text.trim(),
        condition: _conditionController.text.trim(),
        photos: uploadedUrls,
        thumbnail: _thumbnailUrl!,
      );

      if (!mounted) return;

      _showSuccessDialog();
    } catch (e) {
      _showErrorDialog(
          'Ocurrió un error al agregar el libro. Por favor, intenta nuevamente.');
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
                Navigator.pop(context, true); // Notifica que el libro se agregó
              },
              child: const Text('Aceptar'),
            ),
          ),
        ],
      );
    },
  );
}


  void _showErrorDialog(String message) {
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
              Icon(Icons.error_outline, color: Colors.red, size: 60),
              const SizedBox(height: 10),
              const Text(
                'Error',
                style: TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          content: Text(
            message,
            textAlign: TextAlign.center,
          ),
          actions: [
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Aceptar'),
              ),
            ),
          ],
        );
      },
    );
  }

  void _navigateToManualAdd() async {
  // Navega a la pantalla de agregar libro manual
  final bool? shouldUpdate = await Navigator.push<bool>(
    context,
    MaterialPageRoute(
      builder: (context) => const AddBookManualScreen(),
    ),
  );

  // Cierra el diálogo actual y notifica al perfil
  if (mounted && shouldUpdate == true) {
    Navigator.pop(context, true); // Devuelve `true` a ProfileScreen
  }
}




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text(
          "Agregar Libro",
          style: TextStyle(color: AppColors.textPrimary),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          AbsorbPointer(
            absorbing: _isLoading,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
  crossAxisAlignment: CrossAxisAlignment.center,
  children: [
    _buildThumbnail(),
    const SizedBox(height: 24),
    _buildTitleAutocomplete(),
    if (_titleError)
      Text('El título es obligatorio', style: TextStyle(color: Colors.red)),
    const SizedBox(height: 10),
    _buildReadOnlyField(_authorController, 'Autor'),
    const SizedBox(height: 10),
    _buildGenreDropdown(_genreController), // Campo de género como Dropdown
    const SizedBox(height: 10),
    _buildTextField(_descriptionController, 'Descripción / Sinopsis'),
    const SizedBox(height: 10),
    _buildTextField(_conditionController, 'Condición'),
    if (_conditionError)
      Text('Este campo es obligatorio', style: TextStyle(color: Colors.red)),
    const SizedBox(height: 10),
    _buildPhotoPicker(),
    if (_imageError)
      Text('Sube al menos una imagen', style: TextStyle(color: Colors.red)),
    const SizedBox(height: 24),
    _buildSubmitButton(),
    const SizedBox(height: 24),
    Divider(color: AppColors.iconSelected.withOpacity(0.5)),
    const SizedBox(height: 16),
    _buildManualAddOption(),
  ],
),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGenreDropdown(TextEditingController controller) {
  return GestureDetector(
    onTap: () => _showGenreSelector(controller),
    child: AbsorbPointer(
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: 'Seleccionar Género',
          labelStyle: TextStyle(color: AppColors.iconSelected),
          filled: true,
          fillColor: AppColors.cardBackground,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: AppColors.iconSelected),
          ),
          suffixIcon: Icon(
            Icons.arrow_drop_down, // Flecha única
            color: AppColors.iconSelected,
          ),
        ),
      ),
    ),
  );
}

void _showGenreSelector(TextEditingController controller) {
  showModalBottomSheet(
    context: context,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (BuildContext context) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Selecciona un Género',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _genres.length,
                itemBuilder: (context, index) {
                  final genre = _genres[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          controller.text = genre;
                        });
                        Navigator.pop(context); // Cierra el modal
                      },
                      child: Material(
                        elevation: 3,
                        borderRadius: BorderRadius.circular(10),
                        color: AppColors.cardBackground,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 16, horizontal: 20),
                          child: Text(
                            genre,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );
    },
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

  void _reorderImages(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final File movedImage = _uploadedPhotos.removeAt(oldIndex);
      _uploadedPhotos.insert(newIndex, movedImage);
    });
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
      onPressed: _isLoading ? null : _addBookToUser,
      child: _isLoading
          ? const CircularProgressIndicator(color: Colors.white)
          : Text(
              "Agregar Libro",
              style: TextStyle(fontSize: 18, color: AppColors.textPrimary),
            ),
    );
  }

  Widget _buildTitleAutocomplete() {
    return Autocomplete<Book>(
      optionsBuilder: (TextEditingValue textEditingValue) async {
        if (textEditingValue.text.isEmpty) {
          return const Iterable<Book>.empty();
        }
        await _searchBooks(textEditingValue.text);
        return _searchResults;
      },
      displayStringForOption: (Book book) => book.title,
      onSelected: (Book selectedBook) {
        _fetchBookDetails(selectedBook);
      },
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        _titleController.text = controller.text;
        return TextField(
          controller: controller,
          focusNode: focusNode,
          onChanged: (value) {
            setState(() {
              _titleError = false;
            });
            _searchBooks(value);
          },
          decoration: InputDecoration(
            labelText: 'Título',
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
      },
    );
  }

  Widget _buildReadOnlyField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      readOnly: true,
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

  Widget _buildTextField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      onChanged: (value) {
        setState(() {
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
    );
  }

  Widget _buildManualAddOption() {
    return Column(
      children: [
        Text(
          "¿No encuentras tu libro?",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: _navigateToManualAdd,
          icon: const Icon(Icons.add_circle_outline),
          label: const Text("Agregar Manualmente"),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.iconSelected,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }
}
