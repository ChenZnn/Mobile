import 'package:flutter/material.dart';
  import 'package:cached_network_image/cached_network_image.dart';
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

  class _UniverseListScreenState extends State<UniverseListScreen> with SingleTickerProviderStateMixin {
    final ApiService _apiService = ApiService();
    final AuthService _authService = AuthService();
    List<Universe> _universes = [];
    bool _isLoading = true;
    late AnimationController _animationController;
    bool _isRefreshing = false;

    @override
    void initState() {
      super.initState();
      _animationController = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 300),
      );
      _loadUniverses();
    }

    @override
    void dispose() {
      _animationController.dispose();
      super.dispose();
    }

    Future<void> _loadUniverses() async {
      if (_isRefreshing) return;

      setState(() {
        _isLoading = true;
        _isRefreshing = true;
      });

      try {
        final universes = await _apiService.getUniverses("all");
        setState(() {
          _universes = universes;
          _isLoading = false;
          _isRefreshing = false;
        });
      } catch (e) {
        setState(() {
          _isLoading = false;
          _isRefreshing = false;
        });

        // Affichage d'un snackbar plus élégant pour les erreurs
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 16),
                Expanded(child: Text('Impossible de charger les univers: ${e.toString()}')),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red.shade700,
            duration: Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Réessayer',
              textColor: Colors.white,
              onPressed: _loadUniverses,
            ),
          ),
        );
      }
    }

    Future<void> _logout() async {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Déconnexion'),
          content: Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Annuler'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
              ),
              onPressed: () async {
                Navigator.pop(context);
                await _authService.logout();
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => LoginScreen()),
                );
              },
              child: Text('Déconnexion'),
            ),
          ],
        ),
      );
    }

    void _navigateToCreate() {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => UniverseCreateScreen()),
      ).then((value) {
        if (value == true) {
          _loadUniverses();
        }
      });
    }

    void _navigateToDetail(Universe universe) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => UniverseDetailScreen(
            universe: universe,
            universeId: universe.id,
          ),
        ),
      ).then((_) => _loadUniverses());
    }

    @override
    Widget build(BuildContext context) {
      final theme = Theme.of(context);

      return Scaffold(
        appBar: AppBar(
          title: Text(
            'Mes Univers',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
          ),
          elevation: 0,
          actions: [
            IconButton(
              icon: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _isRefreshing ? _animationController.value * 6.28 : 0,
                    child: Icon(Icons.refresh),
                  );
                },
              ),
              onPressed: () {
                _loadUniverses();
                _animationController.forward(from: 0).whenComplete(() {
                  if (_isRefreshing) {
                    _animationController.repeat();
                  } else {
                    _animationController.reset();
                  }
                });
              },
              tooltip: 'Actualiser',
            ),
            IconButton(
              icon: Icon(Icons.logout),
              onPressed: _logout,
              tooltip: 'Déconnexion',
            ),
          ],
          backgroundColor: Color(0xFF6A1B9A),
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF6A1B9A).withOpacity(0.8),
                Color(0xFF4A148C),
              ],
            ),
          ),
          child: _isLoading
              ? Center(child: CircularProgressIndicator(color: Colors.white))
              : RefreshIndicator(
                onRefresh: _loadUniverses,
                color: Color(0xFF6A1B9A),
                child: _universes.isEmpty
                    ? _buildEmptyState()
                    : _buildUniverseGrid(),
              ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _navigateToCreate,
          child: Icon(Icons.add),
          backgroundColor: Color(0xFF6A1B9A),
          elevation: 4,
          tooltip: 'Créer un univers',
        ),
      );
    }

    Widget _buildEmptyState() {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.public_off,
              size: 80,
              color: Colors.white70,
            ),
            SizedBox(height: 16),
            Text(
              'Aucun univers trouvé',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Créez votre premier univers en appuyant sur le bouton +',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70),
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _navigateToCreate,
              icon: Icon(Icons.add),
              label: Text('Créer un univers'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Color(0xFF6A1B9A),
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
            ],
          ),
        );
      }

    Widget _buildUniverseGrid() {
      return GridView.builder(
        padding: EdgeInsets.all(16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: _universes.length,
        itemBuilder: (context, index) {
          final universe = _universes[index];
          return _buildUniverseCard(universe);
        },
      );
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

    Widget _buildUniverseCard(Universe universe) {
      return GestureDetector(
        onTap: () => _navigateToDetail(universe),
        child: Card(
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Image de fond
              universe.imageUrl != null
                ? CachedNetworkImage(
                    imageUrl: _getFullImageUrl(universe.imageUrl) ?? '',
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
                    color: Colors.deepPurple[100],
                    child: Icon(Icons.public, size: 50, color: Colors.deepPurple[300]),
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
              // Informations de l'univers
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        universe.name,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),
                      Text(
                        universe.description ?? 'Aucune description',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    String _formatDate(DateTime date) {
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    }
  }
