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
            style: TextStyle(fontWeight: FontWeight.bold),
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
        ),
        body: RefreshIndicator(
          onRefresh: _loadUniverses,
          child: _isLoading
              ? Center(child: CircularProgressIndicator())
              : _universes.isEmpty
              ? _buildEmptyState()
              : _buildUniverseGridView(),
        ),
        floatingActionButton: FloatingActionButton.extended(
          icon: Icon(Icons.add),
          label: Text('Créer un univers'),
          onPressed: _navigateToCreate,
        ),
      );
    }

    Widget _buildEmptyState() {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.category_outlined,
              size: 80,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Aucun univers trouvé',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Créez votre premier univers pour commencer',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              icon: Icon(Icons.add),
              label: Text('Créer un univers'),
              style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                onPressed: _navigateToCreate,
              ),
            ],
          ),
        );
      }

    Widget _buildUniverseGridView() {
      // Calculer le nombre de colonnes en fonction de la largeur d'écran
      double screenWidth = MediaQuery.of(context).size.width;
      int crossAxisCount = 2; // Par défaut pour mobile

      // Ajustement adaptatif du nombre de colonnes
      if (screenWidth > 1200) {
        crossAxisCount = 5; // Pour très grands écrans
      } else if (screenWidth > 900) {
        crossAxisCount = 4; // Pour grands écrans
      } else if (screenWidth > 600) {
        crossAxisCount = 3; // Pour tablettes et écrans moyens
      }

      return GridView.builder(
        padding: EdgeInsets.all(16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          childAspectRatio: 0.85, // Ratio ajusté
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: _universes.length,
        itemBuilder: (context, index) {
          return _buildUniverseCard(_universes[index]);
        },
      );
    }

    Widget _buildUniverseCard(Universe universe) {
      // Construction de l'URL complète
      String? fullImageUrl;
      if (universe.imageUrl != null && universe.imageUrl!.isNotEmpty) {
        if (universe.imageUrl!.startsWith('http')) {
          fullImageUrl = universe.imageUrl;
        } else {
          fullImageUrl = "https://yodai.wevox.cloud/image_data/${universe.imageUrl}";
        }
      }

      return Card(
        clipBehavior: Clip.antiAlias,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          onTap: () => _navigateToDetail(universe),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image avec overlay pour le titre
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Hero(
                      tag: 'universe_image_${universe.id}',
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
                        errorWidget: (context, url, error) {
                          return Container(
                            color: Colors.grey.shade200,
                            child: Center(
                              child: Icon(
                                Icons.image_not_supported_outlined,
                                size: 30,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          );
                        },
                      )
                          : Container(
                        color: Colors.grey.shade200,
                        child: Center(
                          child: Icon(
                            Icons.photo_library,
                            size: 40,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ),
                    ),
                    // Dégradé pour améliorer la lisibilité du titre
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 60,
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
                    // Nom de l'univers sur l'image
                    Positioned(
                      bottom: 8,
                      left: 12,
                      right: 12,
                      child: Text(
                        universe.name,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          shadows: [
                            Shadow(
                              offset: Offset(0, 1),
                              blurRadius: 2,
                              color: Colors.black.withOpacity(0.5),
                            ),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              // Description compact en bas
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Text(
                  universe.description,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
