import 'package:flutter/material.dart';
import 'results_screen.dart';

class CategoryDetailScreen extends StatefulWidget {
  final String categoryKey;
  final CategoryData categoryData;
  final Function(int, double) onClean;

  const CategoryDetailScreen({
    super.key,
    required this.categoryKey,
    required this.categoryData,
    required this.onClean,
  });

  @override
  State<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends State<CategoryDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late CategoryData data;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    data = widget.categoryData;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String get allTabTitle {
    switch (widget.categoryKey) {
      case 'photos':
        return 'Todas as Fotos';
      case 'screenshots':
        return 'Todos os Screenshots';
      case 'videos':
        return 'Todos os Vídeos';
      case 'contacts':
        return 'Todos os Contactos';
      case 'music':
        return 'Todas as Músicas';
      default:
        return 'Todos';
    }
  }

  String get duplicatesTabTitle {
    switch (widget.categoryKey) {
      case 'photos':
        return 'Fotos Duplicadas';
      case 'screenshots':
        return 'Screenshots Duplicados';
      case 'videos':
        return 'Vídeos Duplicados';
      case 'contacts':
        return 'Contactos Duplicados';
      case 'music':
        return 'Músicas Duplicadas';
      default:
        return 'Duplicados';
    }
  }

  void _cleanDuplicates() async {
    if (data.duplicates == 0) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF00E676)),
      ),
    );

    await Future.delayed(const Duration(seconds: 2));

    int cleanedCount = data.duplicates;
    double cleanedSize = data.duplicatesSize;

    setState(() {
      data.duplicates = 0;
      data.duplicatesSize = 0;
    });

    widget.onClean(cleanedCount, cleanedSize);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Color(0xFF00E676)),
              const SizedBox(width: 12),
              Text('$cleanedCount itens eliminados! ${cleanedSize.toStringAsFixed(0)} MB libertados'),
            ],
          ),
          backgroundColor: const Color(0xFF2D2D2D),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
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
          data.name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: data.color,
          labelColor: data.color,
          unselectedLabelColor: Colors.white54,
          tabs: [
            Tab(text: allTabTitle),
            Tab(text: duplicatesTabTitle),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab: Todos os itens
          _buildItemsGrid(data.allItems, false),
          
          // Tab: Duplicados
          _buildItemsGrid(data.duplicates, true),
        ],
      ),
      bottomNavigationBar: _tabController.index == 1 || data.duplicates > 0
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: GestureDetector(
                  onTap: data.duplicates == 0 ? null : _cleanDuplicates,
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: data.duplicates == 0
                            ? [Colors.grey.shade700, Colors.grey.shade600]
                            : [data.color, data.color.withOpacity(0.7)],
                      ),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: data.duplicates == 0
                          ? []
                          : [
                              BoxShadow(
                                color: data.color.withOpacity(0.4),
                                blurRadius: 15,
                                offset: const Offset(0, 6),
                              ),
                            ],
                    ),
                    child: Center(
                      child: Text(
                        data.duplicates == 0
                            ? 'Sem Duplicados'
                            : 'Eliminar ${data.duplicates} Duplicados (${data.duplicatesSize.toStringAsFixed(0)} MB)',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildItemsGrid(int count, bool isDuplicates) {
    if (count == 0) {
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
              isDuplicates ? 'Sem duplicados!' : 'Nenhum item encontrado',
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 18,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: count > 50 ? 50 : count, // Mostrar máximo 50 para performance
      itemBuilder: (context, index) {
        return _buildItemTile(index, isDuplicates);
      },
    );
  }

  Widget _buildItemTile(int index, bool isDuplicates) {
    IconData icon;
    switch (widget.categoryKey) {
      case 'photos':
      case 'screenshots':
        icon = Icons.image;
        break;
      case 'videos':
        icon = Icons.play_circle_filled;
        break;
      case 'contacts':
        icon = Icons.person;
        break;
      case 'music':
        icon = Icons.music_note;
        break;
      default:
        icon = Icons.file_present;
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: isDuplicates
            ? Border.all(color: Colors.red.withOpacity(0.5), width: 2)
            : null,
      ),
      child: Stack(
        children: [
          Center(
            child: Icon(
              icon,
              color: data.color.withOpacity(0.6),
              size: 40,
            ),
          ),
          if (isDuplicates)
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 12,
                ),
              ),
            ),
          Positioned(
            bottom: 4,
            left: 4,
            right: 4,
            child: Text(
              '${widget.categoryKey}_${index + 1}',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
