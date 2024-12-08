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
    final genres = await _supabaseService.fetchGenres();
    setState(() {
      _genres = genres;
    });
  }

  void _performSearch(String query) async {
    setState(() {
      _isLoading = true;
      _selectedGenre = null;
    });

    final results = await _supabaseService.searchBooks(query);

    setState(() {
      _searchResults = results;
      _isLoading = false;
    });
  }

  void _selectGenre(String genre) async {
    setState(() {
      _isLoading = true;
      _searchController.clear();
      _selectedGenre = genre;
    });

    final results = await _supabaseService.searchBooksByGenre(genre);

    setState(() {
      _searchResults = results;
      _isLoading = false;
    });
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
            ),
            const SizedBox(height: 16),
            // Botones de Géneros dinámicos
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
                                  book.thumbnail,
                                  width: 50,
                                  fit: BoxFit.cover,
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
                                style:
                                    TextStyle(color: AppColors.textSecondary),
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
}
