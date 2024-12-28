import 'package:flutter/material.dart';
import '../../models/book_model.dart';
import '../../services/user_service.dart';
import '../Profile/user_profile_screen.dart';
import '../../styles/colors.dart';
import '../Books/trade_proposal_screen.dart';

class BookDetailsScreen extends StatefulWidget {
  final Book book;
  final String heroTag;

  const BookDetailsScreen({super.key, required this.book, required this.heroTag});

  @override
  State<BookDetailsScreen> createState() => _BookDetailsScreenState();
}

class _BookDetailsScreenState extends State<BookDetailsScreen> {
  String? userNickname;
  bool isNicknameLoading = true;
  bool isExpanded = false;
  final UserService userService = UserService();

  @override
  void initState() {
    super.initState();
    fetchUserNickname(widget.book.id);
  }

  Future<void> fetchUserNickname(String bookId) async {
    try {
      final userDetails = await userService.getUserDetailsByBookId(bookId);

      setState(() {
        userNickname = userDetails['nickname'] ?? "Usuario desconocido";
        isNicknameLoading = false;
      });
    } catch (e) {
      setState(() {
        userNickname = "Usuario desconocido";
        isNicknameLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final Book book = widget.book;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text(
          "Detalles del Libro",
          style: TextStyle(color: AppColors.textPrimary, fontSize: 22),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Usuario que subió el libro (ahora arriba de la imagen)
            GestureDetector(
              onTap: widget.book.userId == null
                  ? null
                  : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              UserProfileScreen(userId: widget.book.userId!),
                        ),
                      );
                    },
              child: Card(
                color: AppColors.cardBackground,
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppColors.shadow,
                        child: Text(
                          userNickname?.substring(0, 1).toUpperCase() ?? "?",
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        isNicknameLoading
                            ? 'Cargando...'
                            : "Subido por: $userNickname",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.iconSelected,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Imagen del libro con Hero
            Hero(
              tag: widget.heroTag,
              child: Container(
                width: 160,
                height: 220,
                decoration: BoxDecoration(
                  color: AppColors.shadow,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: book.thumbnail.isNotEmpty
                    ? Image.network(book.thumbnail, fit: BoxFit.cover)
                    : Center(
                        child: Text(
                          '160 x 220',
                          style: TextStyle(color: AppColors.textPrimary),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),

            // Título del libro
            Text(
              book.title,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Información del autor y género
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'Autor: ',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary),
                  ),
                  TextSpan(
                    text: book.author,
                    style: TextStyle(color: AppColors.textPrimary),
                  ),
                  TextSpan(
                    text: ' | Género: ',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary),
                  ),
                  TextSpan(
                    text: book.genre ?? 'Sin género especificado',
                    style: TextStyle(color: AppColors.textPrimary),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // Sinopsis
            Text(
              "Sinopsis",
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.iconSelected),
            ),
            const SizedBox(height: 12),
            Text(
              book.description?.isNotEmpty == true
                  ? book.description!
                  : "Sin descripción disponible.",
              textAlign: TextAlign.justify,
              maxLines: isExpanded ? null : 5,
              overflow: isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
              style: TextStyle(fontSize: 16, color: AppColors.textPrimary),
            ),
            if (book.description != null && book.description!.length > 100)
              Center(
                child: TextButton(
                  onPressed: () => setState(() => isExpanded = !isExpanded),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    backgroundColor: AppColors.iconSelected.withOpacity(0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    isExpanded ? "Ver menos" : "Ver más",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.iconSelected,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 24),

            // Botón Proponer Trueque
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.iconSelected,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TradeProposalScreen(
                      receiverId: book.userId ?? "unknown",
                    ),
                  ),
                );
              },
              child: Text(
                "Proponer Trueque",
                style: TextStyle(
                  fontSize: 18,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
