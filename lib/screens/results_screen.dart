import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/cleaner_service.dart';
import '../services/ad_service.dart';
import '../services/analytics_service.dart';
import 'category_detail_screen.dart';

class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  final CleanerService _cleanerService = CleanerService();
  final AdService _adService = AdService();
  final AnalyticsService _analyticsService = AnalyticsService();
  BannerAd? _bannerAd;
  bool _isBannerLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
    // Garantir que intersticial está pré-carregado
    _adService.loadInterstitialAd();
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

  @override
  void dispose() {
    // NAO chamar _adService.dispose() - é singleton, destrói anúncios globais
    super.dispose();
  }

  void _openCategory(MediaCategory category, String name, Color color) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CategoryDetailScreen(
          category: category,
          categoryName: name,
          categoryColor: color,
        ),
      ),
    ).then((_) {
      // Atualizar ao voltar
      setState(() {});
    });
  }

  void _cleanAll() async {
    if (_cleanerService.totalDuplicatesCount == 0) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Limpar Todos os Duplicados', style: TextStyle(color: Colors.white)),
        content: Text(
          'Vai eliminar ${_cleanerService.totalDuplicatesCount} ficheiros duplicados (${_cleanerService.formatSize(_cleanerService.totalDuplicatesSize)}).\n\nEsta ação não pode ser desfeita.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E676)),
            child: const Text('Eliminar Todos', style: TextStyle(color: Colors.black)),
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

    final deleted = await _cleanerService.deleteAllDuplicates();

    // Registar evento no Firebase Analytics
    _analyticsService.logLimpezaTotal(ficheirosEliminados: deleted);

    if (mounted) {
      Navigator.pop(context);
      setState(() {});

      _adService.showInterstitialAd(
        onDismissed: () {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.celebration, color: Color(0xFF00E676)),
                    const SizedBox(width: 12),
                    Text('Limpeza total! $deleted ficheiros eliminados!'),
                  ],
                ),
                backgroundColor: const Color(0xFF2D2D2D),
                duration: const Duration(seconds: 4),
              ),
            );
          }
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalDuplicates = _cleanerService.totalDuplicatesCount;
    final totalSize = _cleanerService.totalDuplicatesSize;

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
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22),
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
                  border: Border.all(color: const Color(0xFF00E676).withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Text(
                      totalDuplicates == 0 
                          ? 'Nenhum duplicado encontrado!' 
                          : '$totalDuplicates duplicados encontrados',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      totalDuplicates == 0
                          ? 'A sua galeria está limpa!'
                          : 'Pode libertar ${_cleanerService.formatSize(totalSize)}',
                      style: const TextStyle(color: Color(0xFF00E676), fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),

            // Lista de categorias
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _buildCategoryTile(
                    MediaCategory.photos,
                    'Fotos',
                    Icons.photo_library,
                    const Color(0xFF2196F3),
                  ),
                  _buildCategoryTile(
                    MediaCategory.screenshots,
                    'Screenshots',
                    Icons.screenshot,
                    const Color(0xFF9C27B0),
                  ),
                  _buildCategoryTile(
                    MediaCategory.videos,
                    'Vídeos',
                    Icons.videocam,
                    const Color(0xFFFF9800),
                  ),
                ],
              ),
            ),

            // Botão Limpar Todos
            if (totalDuplicates > 0)
              Padding(
                padding: const EdgeInsets.all(20),
                child: GestureDetector(
                  onTap: _cleanAll,
                  child: Container(
                    width: double.infinity,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00E676), Color(0xFF00BCD4)],
                      ),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00E676).withOpacity(0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        'Limpar Todos os Duplicados',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
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
      ),
    );
  }

  Widget _buildCategoryTile(MediaCategory category, String name, IconData icon, Color color) {
    final allCount = _cleanerService.allMedia[category]?.length ?? 0;
    final duplicateGroups = _cleanerService.duplicates[category] ?? [];
    
    int dupCount = 0;
    int dupSize = 0;
    for (var group in duplicateGroups) {
      dupCount += group.length - 1;
      for (int i = 1; i < group.length; i++) {
        dupSize += group[i].size;
      }
    }

    return GestureDetector(
      onTap: () => _openCategory(category, name, color),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$allCount total • $dupCount duplicados',
                    style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (dupCount > 0)
                  Text(
                    _cleanerService.formatSize(dupSize),
                    style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                const Icon(Icons.chevron_right, color: Colors.white54),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
