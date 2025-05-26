import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../models/universe.dart';
import '../services/api_service.dart';
import 'character_create_screen.dart';
import 'character_detail_screen.dart';
import 'character_list_screen.dart';

class UniverseDetailScreen extends StatefulWidget {
  final String universeId;
  final Universe universe;

  UniverseDetailScreen({required this.universeId, required this.universe});

  @override
  _UniverseDetailScreenState createState() => _UniverseDetailScreenState();
}

class _UniverseDetailScreenState extends State<UniverseDetailScreen> {
  bool _isLoading = true;
  late Universe _universe;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _universe = widget.universe;
    _isLoading = false;
    _loadUniverseDetails();
  }

  Future<void> _loadUniverseDetails() async {
    try {
      final universe = await _apiService.getUniverses(widget.universeId);
      if (mounted) {
        setState(() {
          _universe = universe as Universe;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement: ${e.toString()}')),
        );
      }
    }
  }

  String? _getFullImageUrl() {
    if (_universe.imageUrl == null || _universe.imageUrl!.isEmpty) {
      return null;
    }
    if (_universe.imageUrl!.startsWith('http')) {
      return _universe.imageUrl;
    } else {
      return "https://yodai.wevox.cloud/image_data/${_universe.imageUrl}";
    }
  }

  String? _getCharacterImageUrl(String? imageUrl) {
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
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                _buildSliverAppBar(),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDescriptionSection(),
                        SizedBox(height: 24),
                        _buildCharactersSection(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CharacterListScreen(
                universeId: widget.universeId,
                universeName: _universe.name,
              ),
            ),
          ).then((_) => _loadUniverseDetails());
        },
        child: Icon(Icons.people),
        backgroundColor: Color(0xFF6A1B9A),
        tooltip: 'Voir les personnages',
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 250,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          _universe.name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                blurRadius: 4,
                color: Colors.black.withOpacity(0.5),
                offset: Offset(0, 1),
              ),
            ],
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Image de fond
            _universe.imageUrl != null
                ? CachedNetworkImage(
                    imageUrl: _getFullImageUrl() ?? '',
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[300],
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[300],
                      child: Icon(Icons.public, size: 50, color: Colors.grey[600]),
                    ),
                  )
                : Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFF6A1B9A),
                          Color(0xFF4A148C),
                        ],
                      ),
                    ),
                    child: Icon(Icons.public, size: 80, color: Colors.white.withOpacity(0.5)),
                  ),
            // Dégradé pour améliorer la lisibilité du texte
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.edit),
          onPressed: () {
            // Implémenter la modification de l'univers
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Fonctionnalité à venir')),
            );
          },
          tooltip: 'Modifier',
        ),
        IconButton(
          icon: Icon(Icons.delete),
          onPressed: _confirmDelete,
          tooltip: 'Supprimer',
        ),
      ],
    );
  }

  Widget _buildDescriptionSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Color(0xFF6A1B9A)),
                SizedBox(width: 8),
                Text(
                  'Description',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6A1B9A),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              _universe.description ?? 'Aucune description disponible.',
              style: TextStyle(
                fontSize: 16,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCharactersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Personnages',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6A1B9A),
              ),
            ),
            TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CharacterListScreen(
                      universeId: widget.universeId,
                      universeName: _universe.name,
                    ),
                  ),
                ).then((_) => _loadUniverseDetails());
              },
              icon: Icon(Icons.arrow_forward),
              label: Text('Voir tous'),
              style: TextButton.styleFrom(
                foregroundColor: Color(0xFF6A1B9A),
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Container(
          height: 200,
          child: FutureBuilder(
            future: _apiService.getCharacters(widget.universeId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Erreur lors du chargement des personnages',
                    style: TextStyle(color: Colors.red),
                  ),
                );
              } else if (!snapshot.hasData || (snapshot.data as List).isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.person_off,
                        size: 48,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Aucun personnage',
                        style: TextStyle(color: Colors.grey),
                      ),
                      SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CharacterCreateScreen(
                                universeId: widget.universeId,
                                universeName: _universe.name,
                              ),
                            ),
                          ).then((_) => setState(() {}));
                        },
                        icon: Icon(Icons.add),
                        label: Text('Créer un personnage'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF6A1B9A),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                );
              } else {
                final characters = snapshot.data as List;
                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: characters.length,
                  itemBuilder: (context, index) {
                    final character = characters[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CharacterDetailScreen(
                              character: character,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        width: 150,
                        margin: EdgeInsets.only(right: 16),
                        child: Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: character.imageUrl != null
                                    ? // Dans la partie qui affiche les personnages
                                        CachedNetworkImage(
                                          imageUrl: _getCharacterImageUrl(character.imageUrl) ?? '',
                                          fit: BoxFit.cover,
                                          placeholder: (context, url) => Container(
                                            color: Colors.grey[300],
                                            child: Center(child: CircularProgressIndicator()),
                                          ),
                                          errorWidget: (context, url, error) => Container(
                                            color: Colors.grey[300],
                                            child: Icon(Icons.person, size: 40, color: Colors.grey[600]),
                                          ),
                                        )
                                    : Container(
                                        color: Colors.grey[200],
                                        child: Icon(
                                          Icons.person,
                                          size: 50,
                                          color: Colors.grey,
                                        ),
                                      ),
                              ),
                              Padding(
                                padding: EdgeInsets.all(8),
                                child: Text(
                                  character.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
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
            },
          ),
        ),
      ],
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Supprimer l\'univers'),
        content: Text('Êtes-vous sûr de vouloir supprimer cet univers ? Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _apiService.deleteUniverse(widget.universeId);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Univers supprimé avec succès')),
                );
                Navigator.pop(context, true);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erreur lors de la suppression: ${e.toString()}')),
                );
              }
            },
            child: Text('Supprimer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
          ),
        ],
      ),
    );
  }
}
