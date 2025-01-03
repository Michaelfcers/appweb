import 'package:flutter/material.dart';
import '../../models/book_model.dart';
import '../../services/supabase_service.dart';
import '../../styles/colors.dart';
import '../Books/book_details_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Book> _searchResults = [];
  List<String> _genres = [];
  String? _selectedGenre;
  bool _isLoading = false;

  final SupabaseService _supabaseService = SupabaseService();

  @override
  void initState() {
    super.initState();
    _loadGenres(); // Carga los géneros al iniciar la pantalla
  }

  Future<void> _loadGenres() async {
    try {
      final genres = await _supabaseService.fetchGenres();
      if (mounted) {
        setState(() {
          _genres = genres;
        });
      }
    } catch (error) {
      debugPrint('Error al cargar géneros: $error');
    }
  }

  void _performSearch(String query) async {
    setState(() {
      _isLoading = true;
      _selectedGenre = null;
    });

    try {
      final results = await _supabaseService.searchBooks(query);
      if (mounted) {
        setState(() {
          _searchResults = results;
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

  void _selectGenre(String genre) async {
    setState(() {
      _isLoading = true;
      _searchController.clear();
      _selectedGenre = genre;
    });

    try {
      final results = await _supabaseService.searchBooksByGenre(genre);
      if (mounted) {
        setState(() {
          _searchResults = results;
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
          "Buscar libros",
          style: TextStyle(color: AppColors.textPrimary),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              onChanged: (value) {
                if (value.isEmpty) {
                  _clearSearch();
                } else {
                  _performSearch(value);
                }
              },
              decoration: InputDecoration(
                hintText: 'Buscar libros...',
                hintStyle: TextStyle(color: AppColors.textSecondary),
                prefixIcon: Icon(Icons.search, color: AppColors.iconSelected),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: AppColors.cardBackground,
              ),
              style: TextStyle(
                color: AppColors.black,
              ),
            ),
            const SizedBox(height: 16),
            if (_genres.isNotEmpty)
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: _genres.map((genre) {
                  return ChoiceChip(
                    label: Text(genre),
                    selected: _selectedGenre == genre,
                    onSelected: (isSelected) {
                      _selectGenre(genre);
                    },
                    selectedColor: AppColors.iconSelected,
                    backgroundColor: AppColors.cardBackground,
                    labelStyle: TextStyle(
                      color: _selectedGenre == genre
                          ? AppColors.textPrimary
                          : AppColors.iconSelected,
                    ),
                  );
                }).toList(),
              ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    )
                  : _searchResults.isEmpty
                      ? Center(
                          child: _searchController.text.isNotEmpty ||
                                  _selectedGenre != null
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
                            final book = _searchResults[index];
                            return ListTile(
                              leading: Hero(
                                tag: book.id,
                                child: Image.network(
                                  _determineThumbnail(book),
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                  errorBuilder:
                                      (context, error, stackTrace) => Icon(
                                    Icons.broken_image,
                                    size: 50,
                                    color: AppColors.textSecondary,
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
                                  color: AppColors.textPrimary,
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
                            );
                          },
                        ),
            ),
          ],
        ),
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
