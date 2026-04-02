import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:photo_manager/photo_manager.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/cleaner_service.dart';
import '../services/ad_service.dart';
import '../services/analytics_service.dart';

class CategoryDetailScreen extends StatefulWidget {
  final MediaCategory category;
  final String categoryName;
  final Color categoryColor;

  const CategoryDetailScreen({
    super.key,
    required this.category,
    required this.categoryName,
    required this.categoryColor,
  });

  @override
  State<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends State<CategoryDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final CleanerService _cleanerService = CleanerService();
  final AdService _adService = AdService();
  final AnalyticsService _analyticsService = AnalyticsService();
  
  List<MediaItem> _allItems = [];
  List<MediaItem> _duplicateItems = [];
  bool _isLoading = true;
  bool _selectMode = false;
  BannerAd? _bannerAd;
  bool _isBannerLoaded = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadItems();
    // Pré-carregar intersticial e banner
    _adService.loadInterstitialAd();
    _loadBannerAd();
  }

  void _loadBannerAd() {
    _adService.loadBannerAd(
      onLoaded: () {
        if (mounted) {
          setState(() {
            _bannerAd = _adService.bannerAd;
            _isBannerLoaded = true;
          });
        }
      },
    );
  }

  void _loadItems() {
    _allItems = List.from(_cleanerService.allMedia[widget.category] ?? []);
    
    // Obter duplicados (todos exceto o primeiro de cada grupo)
    _duplicateItems = [];
    final groups = _cleanerService.duplicates[widget.category] ?? [];
    for (var group in groups) {
      if (group.length > 1) {
        _duplicateItems.addAll(group.sublist(1));
      }
    }
    
    setState(() => _isLoading = false);
  }

  void _toggleSelectMode() {
    setState(() {
      _selectMode = !_selectMode;
      if (!_selectMode) {
        // Desselecionar todos
        for (var item in _allItems) {
          item.isSelected = false;
        }
        for (var item in _duplicateItems) {
          item.isSelected = false;
        }
      }
    });
  }

  void _toggleItemSelection(MediaItem item) {
    if (_selectMode) {
      setState(() {
        item.isSelected = !item.isSelected;
      });
    }
  }

  void _selectAllDuplicates() {
    setState(() {
      for (var item in _duplicateItems) {
        item.isSelected = true;
      }
    });
  }

  int get _selectedCount {
    int count = 0;
    for (var item in _allItems) {
      if (item.isSelected) count++;
    }
    for (var item in _duplicateItems) {
      if (item.isSelected) count++;
    }
    return count;
  }

  int get _selectedSize {
    int size = 0;
    for (var item in _allItems) {
      if (item.isSelected) size += item.size;
    }
    for (var item in _duplicateItems) {
      if (item.isSelected) size += item.size;
    }
    return size;
  }

  void _deleteSelected() async {
    if (_selectedCount == 0) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Confirmar Eliminação', style: TextStyle(color: Colors.white)),
        content: Text(
          'Vai eliminar $_selectedCount ficheiros (${_cleanerService.formatSize(_selectedSize)}).\n\nEsta ação não pode ser desfeita.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF00E676)),
      ),
    );

    // Eliminar selecionados
    List<String> idsToDelete = [];
    for (var item in _allItems) {
      if (item.isSelected) idsToDelete.add(item.id);
    }
    for (var item in _duplicateItems) {
      if (item.isSelected) idsToDelete.add(item.id);
    }

    int deleted = 0;
    try {
      final result = await PhotoManager.editor.deleteWithIds(idsToDelete);
      deleted = result.length;
    } catch (e) {
      debugPrint('Erro: $e');
    }

    // Atualizar listas
    _allItems.removeWhere((item) => item.isSelected);
    _duplicateItems.removeWhere((item) => item.isSelected);
    _selectMode = false;

    // Registar evento no Firebase Analytics
    _analyticsService.logLimpezaConcluida(
      ficheirosEliminados: deleted,
      categoria: widget.categoryName,
      tamanhoLibertado: _selectedSize,
    );

    if (mounted) {
      Navigator.pop(context); // Fechar loading
      setState(() {});

      // Mostrar anúncio
      _adService.showInterstitialAd(
        onDismissed: () {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Color(0xFF00E676)),
                    const SizedBox(width: 12),
                    Text('$deleted ficheiros eliminados!'),
                  ],
                ),
                backgroundColor: const Color(0xFF2D2D2D),
              ),
            );
          }
        },
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.categoryName,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          if (!_isLoading)
            IconButton(
              icon: Icon(
                _selectMode ? Icons.close : Icons.checklist,
                color: _selectMode ? Colors.red : Colors.white,
              ),
              onPressed: _toggleSelectMode,
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: widget.categoryColor,
          labelColor: widget.categoryColor,
          unselectedLabelColor: Colors.white54,
          tabs: [
            Tab(text: 'Todos (${_allItems.length})'),
            Tab(text: 'Duplicados (${_duplicateItems.length})'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00E676)))
          : Column(
              children: [
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildGrid(_allItems),
                      _buildGrid(_duplicateItems, isDuplicates: true),
                    ],
                  ),
                ),
                // Banner Ad
                if (_isBannerLoaded && _bannerAd != null)
                  Container(
                    width: _bannerAd!.size.width.toDouble(),
                    height: _bannerAd!.size.height.toDouble(),
                    child: AdWidget(ad: _bannerAd!),
                  ),
              ],
            ),
      bottomNavigationBar: _selectMode && _selectedCount > 0
          ? SafeArea(
              child: Container(
                padding: const EdgeInsets.all(16),
                color: const Color(0xFF1E1E1E),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$_selectedCount selecionados',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            _cleanerService.formatSize(_selectedSize),
                            style: TextStyle(color: widget.categoryColor),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _deleteSelected,
                      icon: const Icon(Icons.delete, color: Colors.white),
                      label: const Text('Eliminar', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : _duplicateItems.isNotEmpty && !_selectMode
              ? SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: ElevatedButton(
                      onPressed: () {
                        _selectMode = true;
                        _selectAllDuplicates();
                        setState(() {});
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.categoryColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                      child: Text(
                        'Selecionar ${_duplicateItems.length} Duplicados',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ),
                )
              : null,
    );
  }

  Widget _buildGrid(List<MediaItem> items, {bool isDuplicates = false}) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isDuplicates ? Icons.check_circle_outline : Icons.folder_open,
              size: 80,
              color: Colors.white24,
            ),
            const SizedBox(height: 16),
            Text(
              isDuplicates ? 'Sem duplicados!' : 'Nenhum ficheiro encontrado',
              style: const TextStyle(color: Colors.white54, fontSize: 18),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return _buildGridItem(items[index], isDuplicates);
      },
    );
  }

  Widget _buildGridItem(MediaItem item, bool isDuplicate) {
    return GestureDetector(
      onTap: () => _toggleItemSelection(item),
      onLongPress: () {
        if (!_selectMode) {
          _selectMode = true;
          item.isSelected = true;
          setState(() {});
        }
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Thumbnail
          FutureBuilder<Uint8List?>(
            future: _cleanerService.getThumbnail(item),
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data != null) {
                return Image.memory(
                  snapshot.data!,
                  fit: BoxFit.cover,
                );
              }
              return Container(
                color: const Color(0xFF2D2D2D),
                child: Icon(
                  _getIconForType(item.type),
                  color: widget.categoryColor.withOpacity(0.5),
                  size: 40,
                ),
              );
            },
          ),

          // Overlay para duplicados
          if (isDuplicate)
            Positioned(
              top: 4,
              left: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'DUP',
                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ),

          // Checkbox de seleção
          if (_selectMode)
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: item.isSelected ? widget.categoryColor : Colors.black54,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: item.isSelected
                    ? const Icon(Icons.check, color: Colors.white, size: 18)
                    : null,
              ),
            ),

          // Tamanho do ficheiro
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                ),
              ),
              child: Text(
                _cleanerService.formatSize(item.size),
                style: const TextStyle(color: Colors.white, fontSize: 10),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          // Overlay de seleção
          if (_selectMode && item.isSelected)
            Container(
              color: widget.categoryColor.withOpacity(0.3),
            ),
        ],
      ),
    );
  }

  IconData _getIconForType(AssetType type) {
    switch (type) {
      case AssetType.video:
        return Icons.play_circle_filled;
      default:
        return Icons.image;
    }
  }
}
