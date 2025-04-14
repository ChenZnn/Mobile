import 'package:flutter/material.dart';
import '../models/universe.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'auth/login_screen.dart';
import 'universe_detail_screen.dart';
import 'universe_create_screen.dart';


class UniverseListScreen extends StatefulWidget {
  @override
  _UniverseListScreenState createState() => _UniverseListScreenState();
}

class _UniverseListScreenState extends State<UniverseListScreen> {
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();
  List<Universe> _universes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUniverses();
  }

  Future<void> _loadUniverses() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final universes = await _apiService.getUniverses("all");
      setState(() {
        _universes = universes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${e.toString()}')),
      );
    }
  }

  Future<void> _logout() async {
    await _authService.logout();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mes Univers'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadUniverses,
          ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _universes.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Aucun univers trouvé',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UniverseCreateScreen(),
                  ),
                ).then((value) {
                  if (value == true) {
                    _loadUniverses();
                  }
                });
              },
              child: Text('Créer un univers'),
            ),
          ],
        ),
      )
          : ListView.builder(
        itemCount: _universes.length,
        itemBuilder: (context, index) {
          final universe = _universes[index];
          return Card(
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              title: Text(universe.name),
              subtitle: Text(
                universe.description.length > 50
                    ? '${universe.description.substring(0, 50)}...'
                    : universe.description,
              ),
              trailing: Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UniverseDetailScreen(
                      universe: universe, universeId: '',
                    ),
                  ),
                ).then((_) => _loadUniverses());
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UniverseCreateScreen(),
            ),
          ).then((value) {
            if (value == true) {
              _loadUniverses();
            }
          });
        },
        child: Icon(Icons.add),
        tooltip: 'Créer un univers',
      ),
    );
  }
}
