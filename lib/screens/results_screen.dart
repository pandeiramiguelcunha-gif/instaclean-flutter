import 'package:flutter/material.dart';

class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  // Contadores dinâmicos - simulam dados reais
  int duplicatePhotos = 47;
  int screenshots = 123;
  int videos = 18;
  int contacts = 35;
  
  double potentialSavings = 2.4; // GB que podem ser libertados
  bool isDeleting = false;

  void _deleteCategory(String category, int count, double sizeMB) async {
    setState(() {
      isDeleting = true;
    });

    // Simular eliminação
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      isDeleting = false;
      switch (category) {
        case 'photos':
          duplicatePhotos = 0;
          break;
        case 'screenshots':
          screenshots = 0;
          break;
        case 'videos':
          videos = 0;
          break;
        case 'contacts':
          contacts = 0;
          break;
      }
      potentialSavings -= sizeMB / 1024;
      if (potentialSavings < 0) potentialSavings = 0;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Color(0xFF00E676)),
              const SizedBox(width: 12),
              Text('Limpeza concluída! ${sizeMB.toStringAsFixed(0)} MB libertados'),
            ],
          ),
          backgroundColor: const Color(0xFF2D2D2D),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  void _cleanAll() async {
    setState(() {
      isDeleting = true;
    });

    await Future.delayed(const Duration(seconds: 3));

    double totalCleaned = potentialSavings;

    setState(() {
      isDeleting = false;
      duplicatePhotos = 0;
      screenshots = 0;
      videos = 0;
      contacts = 0;
      potentialSavings = 0;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.celebration, color: Color(0xFF00E676)),
              const SizedBox(width: 12),
              Text('Limpeza total concluída! ${(totalCleaned * 1024).toStringAsFixed(0)} MB libertados'),
            ],
          ),
          backgroundColor: const Color(0xFF2D2D2D),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    int totalItems = duplicatePhotos + screenshots + videos + contacts;
    
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
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // Resumo no topo
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF00E676).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      '$totalItems itens encontrados',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Pode libertar ${potentialSavings.toStringAsFixed(1)} GB',
                      style: TextStyle(
                        color: const Color(0xFF00E676),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Grid de categorias
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.1,
                  children: [
                    _buildCategoryCard(
                      icon: Icons.photo_library,
                      title: 'Fotos Duplicadas',
                      count: duplicatePhotos,
                      size: 850,
                      color: const Color(0xFF2196F3),
                      category: 'photos',
                    ),
                    _buildCategoryCard(
                      icon: Icons.smartphone,
                      title: 'Screenshots',
                      count: screenshots,
                      size: 620,
                      color: const Color(0xFF9C27B0),
                      category: 'screenshots',
                    ),
                    _buildCategoryCard(
                      icon: Icons.videocam,
                      title: 'Vídeos',
                      count: videos,
                      size: 980,
                      color: const Color(0xFFFF9800),
                      category: 'videos',
                    ),
                    _buildCategoryCard(
                      icon: Icons.people,
                      title: 'Contactos',
                      count: contacts,
                      size: 12,
                      color: const Color(0xFF4CAF50),
                      category: 'contacts',
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Botão Limpar Tudo
              GestureDetector(
                onTap: (isDeleting || totalItems == 0) ? null : _cleanAll,
                child: Container(
                  width: double.infinity,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: (isDeleting || totalItems == 0)
                          ? [Colors.grey.shade700, Colors.grey.shade600]
                          : [const Color(0xFF00E676), const Color(0xFF00BCD4)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: (isDeleting || totalItems == 0)
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
                    child: isDeleting
                        ? const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              ),
                              SizedBox(width: 12),
                              Text(
                                'A Limpar...',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.cleaning_services, color: Colors.white, size: 28),
                              const SizedBox(width: 12),
                              Text(
                                totalItems == 0 ? 'Tudo Limpo!' : 'Limpar Tudo',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryCard({
    required IconData icon,
    required String title,
    required int count,
    required double size,
    required Color color,
    required String category,
  }) {
    bool isEmpty = count == 0;
    
    return GestureDetector(
      onTap: isEmpty ? null : () => _deleteCategory(category, count, size),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: isEmpty ? const Color(0xFF1A1A1A) : const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isEmpty ? Colors.grey.shade800 : color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: isEmpty ? Colors.grey.shade800 : color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  isEmpty ? Icons.check_circle : icon,
                  color: isEmpty ? Colors.grey : color,
                  size: 30,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  color: isEmpty ? Colors.grey : Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                isEmpty ? 'Limpo' : '$count itens',
                style: TextStyle(
                  color: isEmpty ? Colors.grey.shade600 : color,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (!isEmpty)
                Text(
                  '${size.toStringAsFixed(0)} MB',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
