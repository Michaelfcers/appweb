import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/book_model.dart';
import '../../../services/user_service.dart';
import '../Settings/settings_screen.dart';
import '../Books/add_book_dialog.dart';
import '../Books/book_detail_edit_screen.dart';
import '../../styles/colors.dart';
import 'edit_profile_screen.dart';
import '../../styles/theme_notifier.dart';
import '../../auth_notifier.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  ProfileScreenState createState() => ProfileScreenState();
}

class ProfileScreenState extends State<ProfileScreen> {
  final UserService userService = UserService(); // Instancia de UserService
  List<Book> uploadedBooks = [];
  bool isLoading = true;

  String nickname = "Usuario"; // Nickname inicial
  int experience = 0; // Experiencia inicial
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    fetchUserData(); // Obtiene los datos del usuario
    fetchUploadedBooks(); // Obtiene los libros subidos
  }

  // Método para obtener los datos del usuario desde Supabase
  Future<void> fetchUserData() async {
    try {
      final userProfile = await userService.getUserProfile();
      setState(() {
        nickname = userProfile['nickname'] ?? "Usuario";
        experience = userProfile['experience'] ?? 0;
      });
    } catch (error) {
      debugPrint('Error al obtener el perfil del usuario: $error');
    }
  }

  // Método para obtener los libros subidos por el usuario
  Future<void> fetchUploadedBooks() async {
    try {
      final books = await userService.getUploadedBooks();
      setState(() {
        uploadedBooks = books; // Asignamos los libros obtenidos
        isLoading = false;
      });
    } catch (error) {
      debugPrint('Error al cargar los libros subidos: $error');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final authNotifier = Provider.of<AuthNotifier>(context);

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
              );
              setState(() {
                AppColors.toggleTheme(themeNotifier.isDarkMode);
              });
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
                  radius: 40,
                  backgroundColor: AppColors.shadow,
                  child: Icon(Icons.person,
                      size: 40, color: AppColors.textPrimary),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nickname,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Nivel ${experience ~/ 1000} - Lector Ávido',
                        style: TextStyle(color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 10),
                      LinearProgressIndicator(
                        value: (experience % 1000) / 1000,
                        color: AppColors.iconSelected,
                        backgroundColor: AppColors.shadow,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${experience % 1000}/1000 XP',
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
                          );
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
                final shouldUpdate = await showDialog<bool>(
                  context: context,
                  builder: (BuildContext context) => const AddBookDialog(),
                );

                if (shouldUpdate == true) {
                  await fetchUploadedBooks();
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
                      Icon(Icons.add,
                          color: AppColors.iconSelected, size: 36),
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
            return GestureDetector(
              onTap: () async {
                final shouldUpdate = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BookDetailsScreen(
                      book: book,
                      onDelete: (deletedBookId) {
                        setState(() {
                          uploadedBooks
                              .removeWhere((b) => b.id == deletedBookId);
                        });
                      },
                    ),
                  ),
                );

                if (shouldUpdate == true) {
                  await fetchUploadedBooks();
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
                          image: NetworkImage(book.thumbnail),
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

  Widget _buildAchievementsList() {
    final achievements = [
      {
        "title": "Bibliófilo Novato",
        "description": "Subir 5 libros para trueque."
      },
      {
        "title": "Lector Ávido",
        "description": "Realizar 10 trueques exitosos."
      },
      {
        "title": "Explorador de Géneros",
        "description": "Trueques en 5 géneros diferentes."
      },
    ];

    return ListView.builder(
      itemCount: achievements.length,
      itemBuilder: (context, index) {
        final achievement = achievements[index];
        return Card(
          color: AppColors.cardBackground,
          margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 16),
          child: ListTile(
            leading: Icon(Icons.emoji_events, color: AppColors.iconSelected),
            title: Text(
              achievement["title"]!,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            subtitle: Text(
              achievement["description"]!,
              style: TextStyle(color: AppColors.textSecondary),
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
}
