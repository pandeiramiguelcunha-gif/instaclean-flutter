import 'package:flutter/material.dart';
import 'category_detail_screen.dart';

class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  // Dados das categorias
  Map<String, CategoryData> categories = {
    'photos': CategoryData(
      name: 'Fotos',
      icon: Icons.photo_library,
      color: const Color(0xFF2196F3),
      allItems: 245,
      duplicates: 47,
      allSize: 1200,
      duplicatesSize: 850,
    ),
    'screenshots': CategoryData(
      name: 'Screenshots',
      icon: Icons.smartphone,
      color: const Color(0xFF9C27B0),
      allItems: 310,
      duplicates: 123,
      allSize: 890,
      duplicatesSize: 620,
    ),
    'videos': CategoryData(
      name: 'Vídeos',
      icon: Icons.videocam,
      color: const Color(0xFFFF9800),
      allItems: 85,
      duplicates: 18,
      allSize: 4500,
      duplicatesSize: 980,
    ),
    'contacts': CategoryData(
      name: 'Contactos',
      icon: Icons.people,
      color: const Color(0xFF4CAF50),
      allItems: 520,
      duplicates: 35,
      allSize: 45,
      duplicatesSize: 12,
    ),
    'music': CategoryData(
      name: 'Músicas',
      icon: Icons.music_note,
      color: const Color(0xFFE91E63),
      allItems: 156,
      duplicates: 28,
      allSize: 2800,
      duplicatesSize: 540,
    ),
  };

  double get totalDuplicatesSize {
    double total = 0;
    categories.forEach((key, value) {
      total += value.duplicatesSize;
    });
    return total;
  }

  int get totalDuplicates {
    int total = 0;
    categories.forEach((key, value) {
      total += value.duplicates;
    });
    return total;
  }

  void _openCategory(String categoryKey) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CategoryDetailScreen(
          categoryKey: categoryKey,
          categoryData: categories[categoryKey]!,
          onClean: (cleanedDuplicates, cleanedSize) {
            setState(() {
              categories[categoryKey]!.duplicates -= cleanedDuplicates;
              categories[categoryKey]!.duplicatesSize -= cleanedSize;
            });
          },
        ),
      ),
    );
  }

  void _cleanAllDuplicates() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF00E676)),
      ),
    );

    await Future.delayed(const Duration(seconds: 2));

    double totalCleaned = totalDuplicatesSize;

    setState(() {
      categories.forEach((key, value) {
        value.duplicates = 0;
        value.duplicatesSize = 0;
      });
    });

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.celebration, color: Color(0xFF00E676)),
              const SizedBox(width: 12),
              Text('Limpeza total! ${totalCleaned.toStringAsFixed(0)} MB libertados'),
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
        title: const Text(
          'Resultados',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Resumo
            Padding(
              padding: const EdgeInsets.all(20),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF00E676).withOpacity(0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      '$totalDuplicates duplicados encontrados',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Pode libertar ${(totalDuplicatesSize / 1024).toStringAsFixed(1)} GB',
                      style: const TextStyle(
                        color: Color(0xFF00E676),
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Lista de categorias
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: categories.entries.map((entry) {
                  return _buildCategoryTile(entry.key, entry.value);
                }).toList(),
              ),
            ),

            // Botão Limpar Duplicados
            Padding(
              padding: const EdgeInsets.all(20),
              child: GestureDetector(
                onTap: totalDuplicates == 0 ? null : _cleanAllDuplicates,
                child: Container(
                  width: double.infinity,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: totalDuplicates == 0
                          ? [Colors.grey.shade700, Colors.grey.shade600]
                          : [const Color(0xFF00E676), const Color(0xFF00BCD4)],
                    ),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: totalDuplicates == 0
                        ? []
                        : [
                            BoxShadow(
                              color: const Color(0xFF00E676).withOpacity(0.4),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                  ),
                  child: Center(
                    child: Text(
                      totalDuplicates == 0
                          ? 'Sem Duplicados!'
                          : 'Limpar Todos os Duplicados',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryTile(String key, CategoryData data) {
    return GestureDetector(
      onTap: () => _openCategory(key),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: data.color.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: data.color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(data.icon, color: data.color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${data.allItems} total • ${data.duplicates} duplicados',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${data.duplicatesSize.toStringAsFixed(0)} MB',
                  style: TextStyle(
                    color: data.color,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: Colors.white54,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class CategoryData {
  String name;
  IconData icon;
  Color color;
  int allItems;
  int duplicates;
  double allSize;
  double duplicatesSize;

  CategoryData({
    required this.name,
    required this.icon,
    required this.color,
    required this.allItems,
    required this.duplicates,
    required this.allSize,
    required this.duplicatesSize,
  });
}
