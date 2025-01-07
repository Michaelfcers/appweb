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
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildUserCard(book),
                const SizedBox(height: 16),
                _buildBookImage(book),
                const SizedBox(height: 16),
                _buildBookDetails(book),
                const SizedBox(height: 16),
                if (book.condition != null && book.condition!.isNotEmpty)
                  _buildCondition(book),
                if (book.photos != null && book.photos!.isNotEmpty)
                  _buildImagesSection(book),
                const SizedBox(height: 80), // Espacio para el botón flotante
              ],
            ),
          ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.iconSelected,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TradeProposalScreen(
                      receiverId: book.userId ?? "unknown",
                      targetBookId: book.id, // Enviar el ID del libro objetivo
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.swap_horiz),
              label: const Text(
                "Proponer Trueque",
                style: TextStyle(fontSize: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildUserCard(Book book) {
    return GestureDetector(
      onTap: book.userId == null
          ? null
          : () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => UserProfileScreen(userId: book.userId!),
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
    );
  }

  Widget _buildBookImage(Book book) {
    return Hero(
      tag: widget.heroTag,
      child: Container(
        width: double.infinity,
        height: 220,
        decoration: BoxDecoration(
          color: AppColors.shadow,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Image.network(
          _determineThumbnail(book),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Center(
              child: Icon(
                Icons.broken_image,
                size: 50,
                color: AppColors.textSecondary,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBookDetails(Book book) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          book.title,
          style: TextStyle(
            fontSize: 26, // Aumentado
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'Autor: ',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18, // Aumentado
                  color: AppColors.textPrimary,
                ),
              ),
              TextSpan(
                text: book.author,
                style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
              ),
              TextSpan(
                text: ' | Género: ',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18, // Aumentado
                  color: AppColors.textPrimary,
                ),
              ),
              TextSpan(
                text: book.genre ?? 'Sin género especificado',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          "Sinopsis",
          style: TextStyle(
            fontSize: 22, // Aumentado
            fontWeight: FontWeight.bold,
            color: AppColors.iconSelected,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          book.description?.isNotEmpty == true
              ? book.description!
              : "Sin descripción disponible.",
          textAlign: TextAlign.justify,
          maxLines: isExpanded ? null : 5,
          overflow: isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
          style: TextStyle(fontSize: 18, color: AppColors.textPrimary),
        ),
        if (book.description != null && book.description!.length > 100)
          Center(
            child: TextButton(
              onPressed: () => setState(() => isExpanded = !isExpanded),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
      ],
    );
  }

  Widget _buildCondition(Book book) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Condición",
          style: TextStyle(
            fontSize: 22, // Aumentado
            fontWeight: FontWeight.bold,
            color: AppColors.iconSelected,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          book.condition!,
          style: TextStyle(fontSize: 18, color: AppColors.textPrimary),
        ),
      ],
    );
  }

  Widget _buildImagesSection(Book book) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Imágenes del libro",
          style: TextStyle(
            fontSize: 22, // Aumentado
            fontWeight: FontWeight.bold,
            color: AppColors.iconSelected,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 150,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: book.photos!.length,
            itemBuilder: (context, index) {
              final photoUrl = book.photos![index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    _sanitizeImageUrl(photoUrl),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Center(
                        child: Icon(
                          Icons.broken_image,
                          size: 50,
                          color: AppColors.textSecondary,
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
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
}
