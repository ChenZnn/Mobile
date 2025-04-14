// lib/screens/universe_detail_screen.dart
import 'package:flutter/material.dart';
import '../models/universe.dart';
import '../services/api_service.dart';
import 'character_list_screen.dart';

class UniverseDetailScreen extends StatefulWidget {
  final String universeId;

  UniverseDetailScreen({required this.universeId, required Universe universe});

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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Chargement...')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_universe.name),
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () {
              // Naviguer vers l'écran de modification (à implémenter séparément)
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Modification non implémentée')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_universe.imageUrl != null)
              Container(
                height: 250,
                width: double.infinity,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage(_universe.imageUrl!),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _universe.name,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Créé le ${_universe.createdAt?.day}/${_universe.createdAt?.month}/${_universe.createdAt?.year}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 16),
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Description',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          _universe.description,
                          style: TextStyle(
                            fontSize: 16,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.people),
                      label: Text('Voir les personnages'),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
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
                      ),
                      onPressed: () {
                        _showDeleteConfirmationDialog();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
                    SnackBar(content: Text('Univers supprimé avec succès')),
                  );
                  Navigator.of(context).pop(true); // Retour avec mise à jour
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erreur: ${e.toString()}')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }
}
