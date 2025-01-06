import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart' as app_provider;
import '../../../services/user_service.dart';
import '../Settings/settings_screen.dart';
import '../Books/add_book_dialog.dart';
import '../Books/book_detail_edit_screen.dart';
import '../../styles/colors.dart';
import 'edit_profile_screen.dart';
import '../../styles/theme_notifier.dart';
import '../../auth_notifier.dart';
import '../../../models/book_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  ProfileScreenState createState() => ProfileScreenState();
}

class ProfileScreenState extends State<ProfileScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final UserService userService = UserService();
  List<Book> uploadedBooks = [];
  List<Map<String, dynamic>> achievements = [];
  int totalXp = 0;
  bool isLoading = true;
  String nickname = "Usuario";
  String name = "Nombre del Usuario"; // Campo para el nombre
  String? avatarUrl; // Campo para la URL del avatar
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
    });

    try {
      await Future.wait([
        fetchUserData(),
        fetchUploadedBooks(),
        fetchAchievements(),
      ]);
    } catch (error) {
      debugPrint('Error al cargar los datos: $error');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> fetchUserData() async {
    final userId = _supabase.auth.currentUser?.id;

    if (userId == null) {
      debugPrint("Usuario no autenticado");
      return;
    }

    try {
      final response = await _supabase
          .from('users')
          .select('name, nickname, avatar_url, experience')
          .eq('id', userId)
          .single();

      if (response != null) {
        setState(() {
          name = response['name'] ?? "Nombre del Usuario";
          nickname = response['nickname'] ?? "Usuario";
          avatarUrl = response['avatar_url'];
          totalXp = response['experience'] ?? 0;
        });
      }
    } catch (error) {
      debugPrint('Error al obtener el perfil del usuario: $error');
    }
  }

  Future<void> fetchUploadedBooks() async {
    try {
      final books = await userService.getUploadedBooks();
      if (!mounted) return;
      setState(() {
        uploadedBooks = books;
      });
    } catch (error) {
      debugPrint('Error al cargar los libros subidos: $error');
    }
  }

  Future<void> fetchAchievements() async {
    try {
      final allAchievements = await userService.fetchAllAchievements();
      final completedAchievements = await userService.fetchUserAchievements();
      final completedIds = completedAchievements
          .map((achievement) => achievement['achievement_id'])
          .toSet();

      if (!mounted) return;
      setState(() {
        achievements = allAchievements.map((achievement) {
          return {
            'id': achievement['id'],
            'name': achievement['name'],
            'description': achievement['description'],
            'xp': achievement['xp'],
            'completed': completedIds.contains(achievement['id']),
          };
        }).toList();
      });
    } catch (error) {
      debugPrint('Error al obtener logros: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = app_provider.Provider.of<ThemeNotifier>(context);
    final authNotifier = app_provider.Provider.of<AuthNotifier>(context);

    if (!authNotifier.isLoggedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/profile');
      });
      return Container();
    }

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text(
          "Perfil",
          style: TextStyle(color: AppColors.textPrimary),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.settings, color: AppColors.textPrimary),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              ).then((value) {
                if (mounted) {
                  fetchUserData();
                  fetchUploadedBooks();
                }
              });

              if (mounted) {
                setState(() {
                  AppColors.toggleTheme(themeNotifier.isDarkMode);
                });
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundImage:
                      avatarUrl != null ? NetworkImage(avatarUrl!) : null,
                  child: avatarUrl == null
                      ? Icon(Icons.person, size: 50, color: AppColors.textPrimary)
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '@$nickname',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Nivel ${totalXp ~/ 1000} - Lector Ávido',
                        style: TextStyle(color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 10),
                      LinearProgressIndicator(
                        value: (totalXp % 1000) / 1000,
                        color: AppColors.iconSelected,
                        backgroundColor: AppColors.shadow,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${totalXp % 1000}/1000 XP',
                        style: TextStyle(color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppColors.iconSelected),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditProfileScreen(),
                            ),
                          ).then((value) {
                            if (value == true) {
                              fetchUserData(); // Recarga los datos al regresar
                            }
                          });
                        },
                        child: Text(
                          "Editar perfil",
                          style: TextStyle(color: AppColors.iconSelected),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            color: Colors.transparent,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildTabIcon(Icons.book, 0),
                _buildTabIcon(Icons.emoji_events, 1),
              ],
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : _selectedTabIndex == 0
                    ? _buildBooksGrid()
                    : _buildAchievementsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBooksGrid() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 8.0,
          crossAxisSpacing: 8.0,
          childAspectRatio: 1.0,
        ),
        itemCount: uploadedBooks.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return GestureDetector(
              onTap: () async {
                final bool? shouldUpdate = await showDialog<bool>(
                  context: context,
                  builder: (BuildContext context) => const AddBookDialog(),
                );

                if (shouldUpdate == true) {
                  await fetchUploadedBooks();
                  if (mounted) setState(() {});
                }
              },
              child: Card(
                color: AppColors.cardBackground,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 3,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add, color: AppColors.iconSelected, size: 36),
                      const SizedBox(height: 8),
                      Text(
                        'Agregar libro',
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
          } else {
            final book = uploadedBooks[index - 1];
            final String thumbnail = _determineThumbnail(book);

            return GestureDetector(
              onTap: () async {
                final bool? shouldUpdate = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BookDetailsScreen(
                      bookId: book.id,
                      onDelete: (deletedBookId) {
                        setState(() {
                          uploadedBooks.removeWhere((b) => b.id == deletedBookId);
                        });
                      },
                    ),
                  ),
                );

                if (shouldUpdate == true) {
                  await fetchUploadedBooks();
                  if (mounted) setState(() {});
                }
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
                    Container(
                      height: 100,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(10),
                          topRight: Radius.circular(10),
                        ),
                        image: DecorationImage(
                          image: NetworkImage(thumbnail),
                          fit: BoxFit.cover,
                        ),
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
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
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
          }
        },
      ),
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

  Widget _buildAchievementsList() {
    return ListView.builder(
      itemCount: achievements.length,
      itemBuilder: (context, index) {
        final achievement = achievements[index];

        return Card(
          color: achievement['completed']
              ? AppColors.iconSelected
              : AppColors.cardBackground,
          margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 16),
          child: ListTile(
            leading: Icon(
              Icons.emoji_events,
              color: achievement['completed']
                  ? AppColors.primary
                  : AppColors.textSecondary,
            ),
            title: Text(
              achievement['name'],
              style: TextStyle(
                color: AppColors.textPrimary,
              ),
            ),
            subtitle: Text(
              achievement['description'],
              style: TextStyle(
                color: AppColors.textSecondary,
              ),
            ),
            trailing: Text(
              '+${achievement['xp']} XP',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTabIcon(IconData icon, int index) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (!mounted) return;
          setState(() {
            _selectedTabIndex = index;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: _selectedTabIndex == index
                    ? AppColors.iconSelected
                    : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Center(
            child: Icon(
              icon,
              color: _selectedTabIndex == index
                  ? AppColors.iconSelected
                  : AppColors.textPrimary,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }

  void _handleManualAddResult(bool? shouldUpdate) async {
    if (shouldUpdate == true) {
      await fetchUploadedBooks();
      if (mounted) {
        setState(() {});
      }
    }
  }
}
