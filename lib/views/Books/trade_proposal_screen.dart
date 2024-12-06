import 'package:flutter/material.dart';
import '../../models/book_model.dart';
import '../../services/user_service.dart';
import '../../styles/colors.dart';
import 'add_book_dialog.dart';

class TradeProposalScreen extends StatefulWidget {
  final String receiverId; // ID del propietario del libro al que se le propone el trueque

  const TradeProposalScreen({super.key, required this.receiverId});

  @override
  TradeProposalScreenState createState() => TradeProposalScreenState();
}

class TradeProposalScreenState extends State<TradeProposalScreen> {
  final UserService userService = UserService();
  final List<Book> selectedBooks = [];
  List<Book> availableBooks = [];
  bool selectAll = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUserBooks();
  }

  // Cargar libros subidos por el usuario autenticado
  Future<void> fetchUserBooks() async {
    try {
      final books = await userService.getUploadedBooks();
      setState(() {
        availableBooks = books;
        isLoading = false;
      });
    } catch (e) {
      print('Error al cargar los libros del usuario: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  void toggleBookSelection(Book book) {
    setState(() {
      if (selectedBooks.contains(book)) {
        selectedBooks.remove(book);
      } else {
        selectedBooks.add(book);
      }
      selectAll = selectedBooks.length == availableBooks.length;
    });
  }

  void toggleSelectAll() {
    setState(() {
      selectAll = !selectAll;
      if (selectAll) {
        selectedBooks.addAll(availableBooks);
      } else {
        selectedBooks.clear();
      }
    });
  }

  Future<void> addNewBook() async {
    final Book? newBook = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return const AddBookDialog();
      },
    );

    if (newBook != null) {
      setState(() {
        availableBooks.add(newBook);
      });
    }
  }

  Future<void> proposeTrade() async {
    if (selectedBooks.isEmpty) return;

    try {
      final String? proposerId = userService.getCurrentUserId();

      if (proposerId == null) {
        throw Exception("Usuario no autenticado.");
      }

      // Crear una nueva entrada en la tabla `barters`
      final String barterId = await userService.createBarter(
        proposerId: proposerId,
        receiverId: widget.receiverId,
      );

      // Agregar los detalles del trueque (libros seleccionados)
      for (final book in selectedBooks) {
        await userService.addBarterDetail(
          barterId: barterId,
          bookId: book.id,
          offeredBy: proposerId,
        );
      }

      // Notificar al usuario receptor
      await userService.notifyUser(
        receiverId: widget.receiverId,
        message: 'Tienes una nueva propuesta de trueque.',
      );

      // Mostrar mensaje de éxito
      showSuccessDialog();
    } catch (e) {
      print('Error al proponer el trueque: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error al enviar la propuesta: ${e.toString()}',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void showSuccessDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.cardBackground,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 60),
              const SizedBox(height: 10),
              Text(
                '¡Propuesta realizada con éxito!',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textPrimary),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Cierra el diálogo
                Navigator.of(context).pop(); // Regresa a la pantalla anterior
              },
              child: Text('Aceptar', style: TextStyle(color: AppColors.iconSelected)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text('Proponer Trueque', style: TextStyle(color: AppColors.textPrimary)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    'Selecciona los libros que deseas proponer para el trueque',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Seleccionar Todo',
                        style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
                      ),
                      Checkbox(
                        value: selectAll,
                        onChanged: (_) => toggleSelectAll(),
                        activeColor: AppColors.iconSelected,
                        checkColor: AppColors.cardBackground,
                      ),
                    ],
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: availableBooks.length,
                      itemBuilder: (context, index) {
                        final book = availableBooks[index];
                        final isSelected = selectedBooks.contains(book);

                        return GestureDetector(
                          onTap: () => toggleBookSelection(book),
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 8.0),
                            padding: const EdgeInsets.all(8.0),
                            decoration: BoxDecoration(
                              color: AppColors.cardBackground,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.shadow,
                                  blurRadius: 4,
                                  offset: const Offset(2, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 60,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    color: AppColors.shadow,
                                    image: book.thumbnail.isNotEmpty
                                        ? DecorationImage(
                                            image: NetworkImage(book.thumbnail),
                                            fit: BoxFit.cover,
                                          )
                                        : null,
                                  ),
                                  child: book.thumbnail.isEmpty
                                      ? Center(
                                          child: Text(
                                            'Sin imagen',
                                            style: TextStyle(color: AppColors.textSecondary),
                                          ),
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        book.title,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textPrimary,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        book.author,
                                        style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                                Checkbox(
                                  value: isSelected,
                                  activeColor: AppColors.iconSelected,
                                  onChanged: (_) => toggleBookSelection(book),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: selectedBooks.isEmpty ? AppColors.shadow : AppColors.iconSelected,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    ),
                    onPressed: selectedBooks.isEmpty ? null : proposeTrade,
                    child: Text(
                      'Proponer Trueque',
                      style: TextStyle(fontSize: 16, color: AppColors.textPrimary),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
