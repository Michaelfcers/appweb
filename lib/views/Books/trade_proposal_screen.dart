import 'package:flutter/material.dart';
import '../../models/book_model.dart';
import '../../services/user_service.dart';
import '../../styles/colors.dart';

class TradeProposalScreen extends StatefulWidget {
  final String receiverId;
  final String targetBookId; // ID del libro objetivo, enviado desde la pantalla previa.

  const TradeProposalScreen({
    super.key,
    required this.receiverId,
    required this.targetBookId,
  });

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

  Future<void> fetchUserBooks() async {
    try {
      final books = await userService.getUploadedBooks();
      if (!mounted) return;
      setState(() {
        availableBooks = books;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error al cargar los libros del usuario: $e');
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
    }
  }

  String _determineThumbnail(Book book) {
    if (book.photos != null && book.photos!.isNotEmpty) {
      return _sanitizeImageUrl(book.photos!.first);
    }
    return _sanitizeImageUrl(book.thumbnail);
  }

  String _sanitizeImageUrl(String url) {
    if (url.contains('/books/books/')) {
      return url.replaceAll('/books/books/', '/books/');
    }
    return url;
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
        selectedBooks.clear();
        selectedBooks.addAll(availableBooks);
      } else {
        selectedBooks.clear();
      }
    });
  }

  Future<void> proposeTrade() async {
  if (selectedBooks.isEmpty) return;

  final confirm = await showDialog<bool>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: Text(
          'Confirmar Propuesta',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          '¿Estás seguro que deseas proponer el trueque con los libros seleccionados?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancelar', style: TextStyle(color: AppColors.iconSelected)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.iconSelected,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Confirmar', style: TextStyle(color: AppColors.cardBackground)),
          ),
        ],
      );
    },
  );

  if (confirm != true) return;

  try {
    final String? proposerId = userService.getCurrentUserId();

    if (proposerId == null) {
      throw Exception("Usuario no autenticado.");
    }

    // Aquí colocamos el debugPrint
    debugPrint('Datos enviados:');
    debugPrint('Proposer ID: $proposerId');
    debugPrint('Receiver ID: ${widget.receiverId}');
    debugPrint('Target Book ID: ${widget.targetBookId}');
    debugPrint('Selected Books: ${selectedBooks.map((b) => b.id).toList()}');

    final String barterId = await userService.createBarter(
      proposerId: proposerId,
      receiverId: widget.receiverId,
      targetBookId: widget.targetBookId, // Pasar el libro objetivo automáticamente
    );

    for (final book in selectedBooks) {
      await userService.addBarterDetail(
        barterId: barterId,
        bookId: book.id,
        offeredBy: proposerId,
      );
    }

    await userService.notifyUser(
      receiverId: widget.receiverId,
      content: 'Tienes una nueva propuesta de trueque.',
      type: 'trade_request',
      barterId: barterId,
    );

    if (!mounted) return;
    showSuccessDialog();
  } catch (e) {
    debugPrint('Error al proponer el trueque: $e');
    if (!mounted) return;
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: AppColors.cardBackground,
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
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "¡Propuesta realizada con éxito!",
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
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
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  "Aceptar",
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.cardBackground,
                  ),
                ),
              ),
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
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.shadow.withOpacity(0.2),
                          blurRadius: 6,
                          offset: const Offset(2, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Selecciona los libros que deseas proponer para el trueque',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.iconSelected,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onPressed: toggleSelectAll,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          selectAll ? Icons.check_box : Icons.check_box_outline_blank,
                          color: AppColors.cardBackground,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          selectAll ? 'Deseleccionar todos' : 'Seleccionar todos',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.cardBackground,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      itemCount: availableBooks.length,
                      itemBuilder: (context, index) {
                        final book = availableBooks[index];
                        final isSelected = selectedBooks.contains(book);
                        final thumbnail = _determineThumbnail(book);

                        return GestureDetector(
                          onTap: () => toggleBookSelection(book),
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 8.0),
                            padding: const EdgeInsets.all(8.0),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.iconSelected.withOpacity(0.1)
                                  : AppColors.cardBackground,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.iconSelected
                                    : Colors.transparent,
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.shadow.withOpacity(0.2),
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
                                    image: DecorationImage(
                                      image: NetworkImage(thumbnail),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
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
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.iconSelected,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onPressed: selectedBooks.isEmpty ? null : proposeTrade,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.swap_horiz, color: AppColors.cardBackground),
                          const SizedBox(width: 8),
                          Text(
                            'Proponer Trueque',
                            style: TextStyle(
                              fontSize: 16,
                              color: AppColors.cardBackground,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
