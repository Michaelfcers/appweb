import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../../models/book_model.dart';
import '../../services/user_service.dart';
import '../../services/notification_service.dart';
import '../Books/add_book_dialog.dart';
import '../Notifications/notifications_screen.dart';
import '../Messages/messages_screen.dart';
import '../Books/book_details_screen.dart';
import '../../styles/colors.dart';
import '../../auth_notifier.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final UserService userService = UserService(); // Servicio para obtener libros
  final NotificationService notificationService = NotificationService(); // Servicio de notificaciones
  List<Book> allBooks = []; // Lista de libros obtenidos
  bool isLoading = true; // Estado de carga
  int unreadMessagesCount = 0; // Contador de mensajes no leídos
  int unreadNotificationsCount = 0; // Contador de notificaciones no leídas

  @override
  void initState() {
    super.initState();
    fetchBooks();
    fetchUnreadCounts();
    setupRealtimeListeners(); // Configura las suscripciones en tiempo real
  }

  /// Configuración de las suscripciones en tiempo real
  void setupRealtimeListeners() {
    // Suscripción en tiempo real a nuevos mensajes
    notificationService.subscribeToMessages((message) async {
      final unreadChats = await notificationService.getUnreadChatsCount();
      if (!mounted) return;
      setState(() {
        unreadMessagesCount = unreadChats;
      });
    });

    // Suscripción en tiempo real a nuevas notificaciones
    notificationService.subscribeToNotifications(() async {
      final unreadNotifications = await notificationService.getUnreadNotificationsCount();
      if (!mounted) return;
      setState(() {
        unreadNotificationsCount = unreadNotifications;
      });
    });
  }

  @override
  void dispose() {
    notificationService.dispose(); // Limpia las suscripciones
    super.dispose();
  }

  /// Obtiene la lista de libros del servidor
  Future<void> fetchBooks() async {
    try {
      final books = await userService.getBooksFromOtherUsers();
      if (!mounted) return;
      setState(() {
        allBooks = books;
      });
    } catch (error) {
      debugPrint('Error al cargar libros: $error');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  /// Obtiene la cantidad de mensajes y notificaciones no leídos
  Future<void> fetchUnreadCounts() async {
    try {
      final unreadChats = await notificationService.getUnreadChatsCount();
      final unreadNotifications = await notificationService.getUnreadNotificationsCount();

      if (!mounted) return;

      setState(() {
        unreadMessagesCount = unreadChats;
        unreadNotificationsCount = unreadNotifications;
      });
    } catch (error) {
      debugPrint('Error al obtener conteos de no leídos: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authNotifier = Provider.of<AuthNotifier>(context);

    // Redirigir a pantalla de login si el usuario no está autenticado
    if (!authNotifier.isLoggedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/homeLoggedOut');
      });
      return Container();
    }

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: _buildAppBar(context),
      body: isLoading
          ? _buildSkeletonGrid()
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async {
                await fetchBooks();
                await fetchUnreadCounts();
              },
              child: _buildBookList(),
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

  /// Construcción del AppBar con íconos para mensajes y notificaciones
  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
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
        Stack(
          children: [
            IconButton(
              icon: Icon(Icons.message, color: AppColors.textPrimary),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MessagesScreen(),
                  ),
                ).then((_) => fetchUnreadCounts());
              },
            ),
            if (unreadMessagesCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: _buildBadge(unreadMessagesCount),
              ),
          ],
        ),
        Stack(
          children: [
            IconButton(
              icon: Icon(Icons.notifications, color: AppColors.textPrimary),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const NotificationsScreen()),
                ).then((_) => fetchUnreadCounts());
              },
            ),
            if (unreadNotificationsCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: _buildBadge(unreadNotificationsCount),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildBadge(int count) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: const BoxDecoration(
        color: Colors.red,
        shape: BoxShape.circle,
      ),
      child: Text(
        '$count',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildBookList() {
    return ListView(
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
            final heroTag = 'book-${book.id}-$index';

            return _buildBookCard(book, heroTag);
          },
        ),
      ],
    );
  }

  Widget _buildBookCard(Book book, String heroTag) {
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
                        debugPrint('Error loading image: $exception');
                      },
                    ),
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
  }

  Widget _buildSkeletonGrid() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
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
    );
  }

  String _determineThumbnail(Book book) {
    if (book.photos != null && book.photos!.isNotEmpty) {
      return _sanitizeImageUrl(book.photos!.first);
    }
    if (book.thumbnail.isNotEmpty) {
      return _sanitizeImageUrl(book.thumbnail);
    }
    return 'https://via.placeholder.com/150';
  }

  String _sanitizeImageUrl(String url) {
    if (url.contains('/books/books/')) {
      return url.replaceAll('/books/books/', '/books/');
    }
    return url;
  }
}
