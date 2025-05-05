import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../models/universe.dart';
import '../services/api_service.dart';
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

  // Fonction pour construire l'URL complète de l'image
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Chargement...')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final String? fullImageUrl = _getFullImageUrl();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // AppBar avec l'image en arrière-plan
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                _universe.name,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      offset: Offset(0, 1),
                      blurRadius: 3,
                      color: Colors.black.withOpacity(0.5),
                    ),
                  ],
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Image avec Hero animation pour la transition
                  Hero(
                    tag: 'universe_image_${_universe.id}',
                    child: fullImageUrl != null
                        ? CachedNetworkImage(
                      imageUrl: fullImageUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey.shade200,
                        child: Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey.shade300,
                        child: Icon(
                          Icons.image_not_supported,
                          size: 50,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    )
                        : Container(
                      color: Colors.grey.shade300,
                      child: Icon(
                        Icons.image_not_supported,
                        size: 50,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                  // Dégradé pour améliorer la lisibilité du titre
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                        stops: [0.6, 1.0],
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Modification non implémentée')),
                  );
                },
              ),
            ],
          ),
          // Contenu
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date de création avec style amélioré
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Créé le ${_universe.createdAt?.day}/${_universe.createdAt?.month}/${_universe.createdAt?.year}',
                      style: TextStyle(
                        color: Colors.blue[800],
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
                  // Description avec style amélioré
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Description',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.blue[800],
                          ),
                        ),
                        Divider(),
                        SizedBox(height: 8),
                        Text(
                          _universe.description,
                          style: TextStyle(
                            fontSize: 16,
                            height: 1.5,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 32),
                  // Boutons d'action
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.people),
                      label: Text('Voir les personnages'),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CharacterListScreen(
                              universeId: _universe.id,
                              universeName: _universe.name,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: Icon(Icons.delete_outline),
                      label: Text('Supprimer cet univers'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: BorderSide(color: Colors.red),
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {
                        _showDeleteConfirmationDialog();
                      },
                    ),
                  ),
                  SizedBox(height: 24), // Espace en bas
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirmer la suppression'),
          content: Text(
            'Êtes-vous sûr de vouloir supprimer l\'univers "${_universe.name}" ? Cette action est irréversible et supprimera également tous les personnages associés.',
          ),
          actions: [
            TextButton(
              child: Text('Annuler'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(
                'Supprimer',
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  await _apiService.deleteUniverse(_universe.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Univers supprimé avec succès'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  Navigator.of(context).pop(true); // Retour avec mise à jour
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erreur: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        );
      },
    );
  }
}
