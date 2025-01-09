import 'package:flutter/material.dart';
import '../../models/book_model.dart';
import '../../services/user_service.dart';
import '../../styles/colors.dart';
import '../Books/book_details_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserProfileScreen extends StatefulWidget {
  final String userId;

  const UserProfileScreen({super.key, required this.userId});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final UserService userService = UserService();
  Map<String, dynamic>? userProfile;
  List<Book> userBooks = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUserProfileAndBooks();
  }

  Future<void> fetchUserProfileAndBooks() async {
  try {
    debugPrint('userId: ${widget.userId}');
    final response = await userService.getUserProfileAndBooks(widget.userId);

    setState(() {
      userProfile = response['userDetails'];
      userBooks = response['userBooks'];
      isLoading = false;
    });

    // Depura el valor de avatar_url
    debugPrint('Avatar URL en base de datos: ${userProfile?['avatar_url']}');
  } catch (error) {
    debugPrint('Error al obtener datos del usuario: $error');
    setState(() {
      isLoading = false;
    });
  }
}




  Future<String> getAvatarUrl(String? avatarPath) async {
  if (avatarPath == null || avatarPath.isEmpty) {
    debugPrint('El avatarPath está vacío o es nulo. No se puede generar una URL.');
    return ''; // Devuelve una URL vacía
  }

  try {
    final signedUrlResponse = await Supabase.instance.client.storage
        .from('avatars')
        .createSignedUrl(avatarPath, 60 * 60); // URL válida por 1 hora
    debugPrint('Signed URL: $signedUrlResponse');
    return signedUrlResponse;
  } catch (e) {
    debugPrint('Error al obtener la URL firmada: $e');
    return ''; // Devuelve una URL vacía en caso de error
  }
}







  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text(
          userProfile != null ? userProfile!['nickname'] : "Perfil",
          style: TextStyle(color: AppColors.textPrimary),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
  radius: 50,
  backgroundColor: AppColors.shadow,
  child: FutureBuilder<String>(
    future: getAvatarUrl(userProfile?['avatar_url']),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return CircularProgressIndicator(color: AppColors.iconSelected);
      }
      if (snapshot.hasError || snapshot.data == '') {
        return Icon(Icons.person, size: 50, color: AppColors.textPrimary);
      }
      return ClipOval(
        child: Image.network(
          snapshot.data!,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Icon(Icons.person, size: 50, color: AppColors.textPrimary);
          },
        ),
      );
    },
  ),
),


                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userProfile?['nickname'] ?? "Usuario",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              userProfile?['name'] ?? "Nombre no disponible",
                              style: TextStyle(
                                fontSize: 16,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 10),
                            LinearProgressIndicator(
                              value: ((userProfile?['experience'] ?? 0) % 1000) /
                                  1000,
                              color: AppColors.iconSelected,
                              backgroundColor: AppColors.shadow,
                            ),
                            const SizedBox(height: 5),
                            Text(
                              '${(userProfile?['experience'] ?? 0) % 1000}/1000 XP',
                              style: TextStyle(color: AppColors.textPrimary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Libros subidos",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 8.0,
                        crossAxisSpacing: 8.0,
                        childAspectRatio: 0.8,
                      ),
                      itemCount: userBooks.length,
                      itemBuilder: (context, index) {
                        final book = userBooks[index];
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
                          child: Card(
                            color: AppColors.cardBackground,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(10),
                                    topRight: Radius.circular(10),
                                  ),
                                  child: Image.network(
                                    _determineThumbnail(book),
                                    height: 120,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    book.title,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 8.0),
                                  child: Text(
                                    book.author,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(height: 8),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  String _determineThumbnail(Book book) {
    try {
      if (book.photos != null && book.photos!.isNotEmpty) {
        return _sanitizeImageUrl(book.photos!.first);
      }
      if (book.thumbnail.isNotEmpty) {
        return _sanitizeImageUrl(book.thumbnail);
      }
    } catch (e) {
      debugPrint('Error determinando el thumbnail: $e');
    }
    return 'https://via.placeholder.com/150?text=No+Image';
  }

  String _sanitizeImageUrl(String url) {
    try {
      if (url.contains('/books/books/')) {
        return url.replaceAll('/books/books/', '/books/');
      }
      return url;
    } catch (e) {
      debugPrint('Error sanitizando la URL de la imagen: $e');
      return 'https://via.placeholder.com/150?text=Error';
    }
  }
}
