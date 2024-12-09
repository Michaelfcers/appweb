import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../../models/book_model.dart';
import '../../services/google_books_service.dart';
import '../../styles/colors.dart';
import '../Layout/layout.dart';

class HomeScreenLoggedOut extends StatefulWidget { 
  const HomeScreenLoggedOut({super.key});

  @override
  _HomeScreenLoggedOutState createState() => _HomeScreenLoggedOutState();
}

class _HomeScreenLoggedOutState extends State<HomeScreenLoggedOut> {
  final GoogleBooksService booksService = GoogleBooksService();
  List<Book> allBooks = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchBooks();
  }

  Future<void> fetchBooks() async {
    try {
      // Obtenemos varias listas y las combinamos en una sola
      final featured = await booksService.fetchBooks('flutter');
      final recommended = await booksService.fetchBooks('dart programming');
      final popular = await booksService.fetchBooks('technology');

      // Combinar todas las listas en una sola (por ejemplo)
      final combined = [...featured, ...recommended, ...popular];

      if (!mounted) return;

      setState(() {
        allBooks = combined;
        isLoading = false;
      });
    } catch (error) {
      debugPrint('Error: $error');

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Layout(
      body: Scaffold(
        backgroundColor: AppColors.scaffoldBackground,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: AppColors.primary,
          title: Text(
            "BookSwap",
            style: GoogleFonts.poppins(
              color: AppColors.tittle,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: Icon(Icons.message, color: AppColors.textPrimary),
              onPressed: () {
                _showLoginPrompt(context);
              },
            ),
            IconButton(
              icon: Icon(Icons.notifications, color: AppColors.textPrimary),
              onPressed: () {
                _showLoginPrompt(context);
              },
            ),
          ],
        ),
        body: Container(
          color: AppColors.scaffoldBackground,
          child: isLoading
              ? _buildSkeletonGrid()
              : RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: fetchBooks,
                  child: ListView(
                    padding: const EdgeInsets.all(16.0),
                    children: [
                      Text(
                        "¡Empieza a explorar nuevos libros y haz trueques!",
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 20),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2, 
                          crossAxisSpacing: 16.0,
                          mainAxisSpacing: 16.0,
                          childAspectRatio: 0.7,
                        ),
                        itemCount: allBooks.length,
                        itemBuilder: (context, index) {
                          final book = allBooks[index];
                          return GestureDetector(
                            onTap: () {
                              _showLoginPrompt(context);
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15),
                                color: AppColors.cardBackground,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.shadow,
                                    spreadRadius: 2,
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(15),
                                          topRight: Radius.circular(15),
                                        ),
                                        image: DecorationImage(
                                          image: NetworkImage(book.thumbnail),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          book.title,
                                          style: GoogleFonts.poppins(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.textPrimary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          book.author,
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            color: AppColors.textSecondary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
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
                    ],
                  ),
                ),
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: AppColors.iconSelected,
          onPressed: () {
            _showLoginPrompt(context);
          },
          child: Icon(Icons.add, color: AppColors.textPrimary),
        ),
      ),
      currentIndex: 0,
    );
  }

  void _showLoginPrompt(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          backgroundColor: AppColors.dialogBackground,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Inicia Sesión",
                  style: TextStyle(
                    color: AppColors.dialogTitleText,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "Debes iniciar sesión para acceder a esta funcionalidad.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.dialogBodyText,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        "Cancelar",
                        style: TextStyle(
                          color: AppColors.dialogSecondaryButtonText,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/login');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.dialogPrimaryButton,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        "Iniciar Sesión",
                        style: TextStyle(
                          color: AppColors.dialogPrimaryButtonText,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSkeletonGrid() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        children: [
          Text(
            "¡Empieza a explorar nuevos libros y haz trueques!",
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            key: const Key('skeleton_grid_logged_out'),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, 
              crossAxisSpacing: 16.0,
              mainAxisSpacing: 16.0,
              childAspectRatio: 0.7,
            ),
            itemCount: 6,
            itemBuilder: (context, index) {
              return Shimmer.fromColors(
                baseColor: AppColors.shadow,
                highlightColor: AppColors.cardBackground,
                period: const Duration(seconds: 1),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    color: AppColors.cardBackground,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
