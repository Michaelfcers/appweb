import 'package:flutter/material.dart';
import '../../models/book_model.dart';
import '../../services/supabase_service.dart';
import '../../styles/colors.dart';
import '../Books/book_details_screen.dart';
import '../Profile/user_profile_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

final SupabaseService _supabaseService = SupabaseService();

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _searchResults = [];
  List<String> _genres = [];
  String? _selectedGenre;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadGenres();
  }

  Future<void> _loadGenres() async {
    try {
      final genres = await _supabaseService.fetchGenresFromDatabase();
      if (mounted) {
        setState(() {
          _genres = genres;
        });
      }
    } catch (error) {
      debugPrint('Error al cargar géneros: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar los géneros')),
      );
    }
  }

  void _performSearch(String query) async {
    setState(() {
      _isLoading = true;
      _selectedGenre = null;
    });

    try {
      final bookResults = await _supabaseService.searchBooks(query);
      final authorResults = await _supabaseService.searchBooksByAuthor(query);
      final userResults = await _supabaseService.searchUsers(query);

      if (mounted) {
        setState(() {
          _searchResults = [
            ...bookResults,
            ...authorResults,
            ...userResults,
          ];
          _isLoading = false;
        });
      }
    } catch (error) {
      debugPrint('Error al realizar la búsqueda: $error');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _selectGenre(String? genre) async {
    if (genre == null) return;

    setState(() {
      _isLoading = true;
      _searchController.clear();
      _selectedGenre = genre;
    });

    try {
      final results = await _supabaseService.searchBooksByGenre(genre);
      if (mounted) {
        setState(() {
          _searchResults = results.where((book) => book.status == 'enabled').toList();
          _isLoading = false;
        });
      }
    } catch (error) {
      debugPrint('Error al buscar por género: $error');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _searchResults.clear();
      _selectedGenre = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text(
          "Buscar",
          style: TextStyle(color: AppColors.textPrimary),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar
            Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
                borderRadius: BorderRadius.circular(20),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  if (value.isEmpty) {
                    _clearSearch();
                  } else {
                    _performSearch(value);
                  }
                },
                decoration: InputDecoration(
                  hintText: 'Buscar libros, autores o usuarios...',
                  hintStyle: TextStyle(color: AppColors.textSecondary, fontSize: 16),
                  prefixIcon: Icon(Icons.search, color: AppColors.iconSelected, size: 24),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: AppColors.cardBackground,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                ),
                style: TextStyle(
                  color: AppColors.black,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Genre Dropdown
            if (_genres.isNotEmpty)
  GestureDetector(
    onTap: () => _showGenreSelector(context),
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.transparent),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            _selectedGenre ?? "Seleccionar género",
            style: TextStyle(
              color: _selectedGenre != null
                  ? AppColors.textPrimary
                  : AppColors.textSecondary,
              fontSize: 16,
            ),
          ),
          Icon(Icons.arrow_drop_down, color: AppColors.iconSelected),
        ],
      ),
    ),
  ),


const SizedBox(height: 16),


            // Search Results
            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    )
                  : _searchResults.isEmpty
                      ? Center(
                          child: _searchController.text.isNotEmpty || _selectedGenre != null
                              ? Text(
                                  "No se encontraron resultados",
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 16,
                                  ),
                                )
                              : null,
                        )
                      : ListView.builder(
                          itemCount: _searchResults.length,
                          itemBuilder: (context, index) {
                            final result = _searchResults[index];

                            if (result is Book) {
                              return _buildBookCard(result);
                            } else if (result is Map<String, String>) {
                              return _buildUserCard(result);
                            }
                            return SizedBox.shrink();
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

void _showGenreSelector(BuildContext context) {
  showModalBottomSheet(
    context: context,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (BuildContext context) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Selecciona un Género',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _genres.length,
                itemBuilder: (context, index) {
                  final genre = _genres[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(context); // Cierra el modal
                        _selectGenre(genre); // Llama a la búsqueda por género
                      },
                      child: Material(
                        elevation: 3,
                        borderRadius: BorderRadius.circular(10),
                        color: AppColors.cardBackground,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 16, horizontal: 20),
                          child: Text(
                            genre,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );
    },
  );
}



  Widget _buildBookCard(Book book) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      elevation: 5,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Hero(
          tag: book.id,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: Image.network(
              _determineThumbnail(book),
              width: 50,
              height: 50,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  Icon(Icons.broken_image, size: 50, color: AppColors.textSecondary),
            ),
          ),
        ),
        title: Text(
          book.title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          book.author,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BookDetailsScreen(
                book: book,
                heroTag: book.id,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildUserCard(Map<String, String> user) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      elevation: 5,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          child: Icon(Icons.person, color: AppColors.textPrimary),
        ),
        title: Text(
          user['name']!,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          '@${user['nickname']}',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UserProfileScreen(userId: user['id']!),
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
