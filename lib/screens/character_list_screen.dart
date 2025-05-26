import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../models/character.dart';
import '../services/api_service.dart';
import 'character_create_screen.dart';
import 'character_detail_screen.dart';

class CharacterListScreen extends StatefulWidget {
  final String universeId;
  final String universeName;

  CharacterListScreen({required this.universeId, required this.universeName});

  @override
  _CharacterListScreenState createState() => _CharacterListScreenState();
}

class _CharacterListScreenState extends State<CharacterListScreen> {
  bool _isLoading = true;
  List<Character> _characters = [];
  final ApiService _apiService = ApiService();
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _loadCharacters();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  Future<void> _loadCharacters() async {
    if (_isDisposed) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final characters = await _apiService.getCharacters(widget.universeId);

      if (_isDisposed) return;

      setState(() {
        _characters = characters;
        _isLoading = false;
      });
    } catch (e) {
      if (_isDisposed) return;

      debugPrint("Erreur lors du chargement des personnages: $e"); // Log de l'erreur
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${e.toString()}')),
      );
    }
  }

  String? _getFullImageUrl(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return null;
    }
    if (imageUrl.startsWith('http')) {
      return imageUrl;
    } else {
      return "https://yodai.wevox.cloud/image_data/$imageUrl";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Personnages: ${widget.universeName}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        elevation: 0,
        backgroundColor: Color(0xFF6A1B9A),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadCharacters,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CharacterCreateScreen(
                universeId: widget.universeId,
                universeName: widget.universeName,
              ),
            ),
          ).then((value) {
            if (value == true) {
              _loadCharacters();
            }
          });
        },
        child: Icon(Icons.add),
        backgroundColor: Color(0xFF6A1B9A),
        elevation: 4,
        tooltip: 'Ajouter un personnage',
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF6A1B9A).withOpacity(0.05),
              Colors.white,
            ],
          ),
        ),
        child: _isLoading
            ? Center(child: CircularProgressIndicator(color: Color(0xFF6A1B9A)))
            : _characters.isEmpty
                ? _buildEmptyState()
                : _buildCharacterList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.people_outline,
              size: 80,
              color: Color(0xFF6A1B9A).withOpacity(0.6),
            ),
          ),
          SizedBox(height: 24),
          Text(
            'Aucun personnage pour cet univers',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF6A1B9A),
            ),
          ),
          SizedBox(height: 12),
          Text(
            'Créez votre premier personnage',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 32),
          ElevatedButton.icon(
            icon: Icon(Icons.add),
            label: Text(
              'Créer un personnage',
              style: TextStyle(fontSize: 16),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF6A1B9A),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 4,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CharacterCreateScreen(
                    universeId: widget.universeId,
                    universeName: widget.universeName,
                  ),
                ),
              ).then((value) {
                if (value == true) {
                  _loadCharacters();
                }
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCharacterList() {
    return ListView.builder(
      physics: AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.all(16),
      itemCount: _characters.length,
      itemBuilder: (context, index) {
        final character = _characters[index];
        final String? fullImageUrl = _getFullImageUrl(character.imageUrl);

        return Card(
          margin: EdgeInsets.only(bottom: 16),
          elevation: 3,
          shadowColor: Colors.black26,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CharacterDetailScreen(
                    character: character,
                  ),
                ),
              ).then((_) => _loadCharacters());
            },
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  // Image du personnage
                  Hero(
                    tag: 'character_image_${character.id}',
                    child: Container(
                      width: 90,
                      height: 90,
                      margin: EdgeInsets.only(right: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 6,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: fullImageUrl != null
                            ? CachedNetworkImage(
                                imageUrl: fullImageUrl,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  color: Colors.grey[200],
                                  child: Center(
                                    child: SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Color(0xFF6A1B9A),
                                      ),
                                    ),
                                  ),
                                ),
                                errorWidget: (context, url, error) {
                                  debugPrint("Erreur de chargement de l'image: $error");
                                  return Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          Color(0xFF6A1B9A).withOpacity(0.2),
                                          Color(0xFF6A1B9A).withOpacity(0.4),
                                        ],
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        character.name.isNotEmpty
                                            ? character.name.substring(0, 1).toUpperCase()
                                            : '?',
                                        style: TextStyle(
                                          fontSize: 32,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF6A1B9A),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              )
                            : Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(0xFF6A1B9A).withOpacity(0.2),
                                      Color(0xFF6A1B9A).withOpacity(0.4),
                                    ],
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    character.name.isNotEmpty
                                        ? character.name.substring(0, 1).toUpperCase()
                                        : '?',
                                    style: TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF6A1B9A),
                                    ),
                                  ),
                                ),
                              ),
                      ),
                    ),
                  ),
                  // Informations du personnage
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Nom du personnage
                        Text(
                          character.name,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF6A1B9A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 6),
                        // Description du personnage
                        Text(
                          character.description ?? 'Aucune description',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 8),
                        // Date de création
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 12,
                              color: Colors.grey[500],
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Créé le ${character.createdAt.day}/${character.createdAt.month}/${character.createdAt.year}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Icône de navigation
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Color(0xFF6A1B9A).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Color(0xFF6A1B9A),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
