import 'package:flutter/material.dart';
import '../models/character.dart';
import '../services/api_service.dart';
import 'character_create_screen.dart';
import 'character_detail_screen.dart'; // Import manquant

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

  @override
  void initState() {
    super.initState();
    _loadCharacters();
  }

  Future<void> _loadCharacters() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final characters = await _apiService.getCharacters(widget.universeId);
      if (mounted) {
        setState(() {
          _characters = characters;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Personnages: ${widget.universeName}'),
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
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Aucun personnage pour cet univers',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            ElevatedButton(
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
              child: Text('Créer un personnage'),
            ),
          ],
        ),
      )
          : ListView.builder(
        itemCount: _characters.length,
        itemBuilder: (context, index) {
          final character = _characters[index];
          return Card(
            margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            elevation: 2,
            child: ListTile(
              leading: character.imageUrl != null
                  ? ClipRRect(
                borderRadius: BorderRadius.circular(25),
                child: Image.network(
                  character.imageUrl!,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return CircleAvatar(
                      child: Text(
                        character.name.substring(0, 1).toUpperCase(),
                      ),
                    );
                  },
                ),
              )
                  : CircleAvatar(
                child: Text(
                  character.name.substring(0, 1).toUpperCase(),
                ),
              ),
              title: Text(character.name),
              subtitle: Text(
                character.description ?? 'Aucune description',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
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
            ),
          );
        },
      ),
    );
  }
}
