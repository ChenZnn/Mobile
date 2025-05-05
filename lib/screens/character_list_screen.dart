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
        title: Text('Personnages: ${widget.universeName}'),
        elevation: 0,
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
        tooltip: 'Ajouter un personnage',
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _characters.isEmpty
          ? _buildEmptyState()
          : _buildCharacterList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 80,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'Aucun personnage pour cet univers',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            icon: Icon(Icons.add),
            label: Text('Créer un personnage'),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
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
      padding: EdgeInsets.all(12),
      itemCount: _characters.length,
      itemBuilder: (context, index) {
        final character = _characters[index];
        final String? fullImageUrl = _getFullImageUrl(character.imageUrl);

        debugPrint(fullImageUrl);

        return Card(
          margin: EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
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
              padding: const EdgeInsets.all(4.0),
              child: Row(
                children: [
                  // Image du personnage
                  Hero(
                    tag: 'character_image_${character.id}',
                    child: Container(
                      width: 80,
                      height: 80,
                      margin: EdgeInsets.only(right: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: Offset(0, 2),
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
                                ),
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) {
                            debugPrint("Erreur de chargement de l'image: $error"); // Log de l'erreur
                            return Container(
                              color: Colors.blue.withOpacity(0.1),
                              child: Center(
                                child: Text(
                                  character.name.isNotEmpty
                                      ? character.name.substring(0, 1).toUpperCase()
                                      : '?',
                                  style: TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue[800],
                                  ),
                                ),
                              ),
                            );
                          },
                        )
                            : Container(
                          color: Colors.blue.withOpacity(0.1),
                          child: Center(
                            child: Text(
                              character.name.isNotEmpty
                                  ? character.name.substring(0, 1).toUpperCase()
                                  : '?',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[800],
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
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4),
                        // Description du personnage
                        Text(
                          character.description ?? 'Aucune description',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 6),
                        // Date de création
                        Text(
                          'Créé le ${character.createdAt.day}/${character.createdAt.month}/${character.createdAt.year}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Icône de navigation
                  Icon(
                    Icons.chevron_right,
                    color: Colors.grey[400],
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
