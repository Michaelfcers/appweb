import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../../models/book_model.dart';
import '../../services/user_service.dart';
import '../Books/add_book_dialog.dart';
import '../Notifications/notifications_screen.dart';
import '../Messages/messages_screen.dart';
import '../Books/book_details_screen.dart';
import '../../styles/colors.dart';
import '../../auth_notifier.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  final UserService userService = UserService();
  List<Book> allBooks = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchBooks();
  }

  Future<void> fetchBooks() async {
    try {
      final books = await userService.getBooksFromOtherUsers();
      if (!mounted) return;
      setState(() {
        allBooks = books;
        isLoading = false;
      });
    } catch (error) {
      debugPrint('Error al cargar libros: $error');
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authNotifier = Provider.of<AuthNotifier>(context);

    if (!authNotifier.isLoggedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/homeLoggedOut');
      });
      return Container();
    }

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.primary,
        title: Text(
          "BookSwap",
          style: GoogleFonts.poppins(
            color: AppColors.textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(Icons.message, color: AppColors.textPrimary),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MessagesScreen()),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.notifications, color: AppColors.textPrimary),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const NotificationsScreen()),
              );
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
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16.0,
                        mainAxisSpacing: 16.0,
                        childAspectRatio: 0.7,
                      ),
                      itemCount: allBooks.length,
                      itemBuilder: (context, index) {
                        final book = allBooks[index];
                        final heroTag = 'book-${book.id}-$index';

                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BookDetailsScreen(
                                  book: book,
                                  heroTag: heroTag,
                                ),
                              ),
                            );
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
                                  child: Hero(
                                    tag: heroTag,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(15),
                                          topRight: Radius.circular(15),
                                        ),
                                        image: DecorationImage(
                                          image: NetworkImage(
                                            _determineThumbnail(book),
                                          ),
                                          fit: BoxFit.cover,
                                          onError: (exception, stackTrace) {
                                            debugPrint(
                                                'Error loading image: $exception');
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        book.title,
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.cardTitleColor,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        book.author,
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          color: AppColors.cardAuthorColor,
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
          showDialog(
            context: context,
            builder: (BuildContext context) => const AddBookDialog(),
          );
        },
        child: Icon(Icons.add, color: AppColors.textPrimary),
      ),
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
            key: const Key('skeleton_grid'),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16.0,
              mainAxisSpacing: 16.0,
              childAspectRatio: 0.7,
            ),
            itemCount: 6,
            itemBuilder: (context, index) {
              return Shimmer.fromColors(
                baseColor: AppColors.shadow.withOpacity(0.3),
                highlightColor: AppColors.cardBackground,
                period: const Duration(milliseconds: 800),
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

  String _determineThumbnail(Book book) {
    // Prioriza las imágenes subidas manualmente.
    if (book.photos != null && book.photos!.isNotEmpty) {
      return _sanitizeImageUrl(book.photos!.first);
    }

    // Si no hay imágenes subidas, usa el thumbnail de la API.
    if (book.thumbnail.isNotEmpty) {
      return _sanitizeImageUrl(book.thumbnail);
    }

    // Si no hay ninguna imagen, usa una imagen predeterminada.
    return 'https://via.placeholder.com/150';
  }

  String _sanitizeImageUrl(String url) {
    if (url.contains('/books/books/')) {
      return url.replaceAll('/books/books/', '/books/');
    }
    return url;
  }
}
