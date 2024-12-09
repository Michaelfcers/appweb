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
  final UserService userService = UserService();
  List<Book> uploadedBooks = [];
  List<Map<String, dynamic>> achievements = [];
  int totalXp = 0;
  bool isLoading = true;
  String nickname = "Usuario";
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    fetchUserData();
    fetchUploadedBooks();
    fetchAchievements();
  }

  Future<void> fetchUserData() async {
    try {
      final userProfile = await userService.getUserProfile();
      setState(() {
        nickname = userProfile['nickname'] ?? "Usuario";
        totalXp = userProfile['experience'] ?? 0;
      });
    } catch (error) {
      debugPrint('Error al obtener el perfil del usuario: $error');
    }
  }

  Future<void> fetchUploadedBooks() async {
    try {
      final books = await userService.getUploadedBooks();
      setState(() {
        uploadedBooks = books;
        isLoading = false;
      });
    } catch (error) {
      debugPrint('Error al cargar los libros subidos: $error');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> fetchAchievements() async {
    try {
      // Obtener logros disponibles y completados
      final allAchievements = await userService.fetchAllAchievements();
      final completedAchievements = await userService.fetchUserAchievements();
      final completedIds = completedAchievements
          .map((achievement) => achievement['achievement_id'])
          .toSet();

      // Combinar logros y marcar los completados
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
        isLoading = false;
      });
    } catch (error) {
      debugPrint('Error al obtener logros: $error');
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
