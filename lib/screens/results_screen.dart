import 'package:flutter/material.dart';
import 'dart:io';
import '../services/file_scanner_service.dart';
import 'category_detail_screen.dart';

class ResultsScreen extends StatefulWidget {
  final Map<FileType, List<FileItem>> scannedFiles;
  final Map<FileType, List<List<FileItem>>> duplicates;

  const ResultsScreen({
    super.key,
    required this.scannedFiles,
    required this.duplicates,
  });

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  final FileScannerService _scannerService = FileScannerService();
  late Map<FileType, List<FileItem>> _allFiles;
  late Map<FileType, List<List<FileItem>>> _duplicates;

  @override
  void initState() {
    super.initState();
    _allFiles = Map.from(widget.scannedFiles);
    _duplicates = Map.from(widget.duplicates);
  }

  int get totalDuplicates {
    int count = 0;
    _duplicates.forEach((type, groups) {
      for (var group in groups) {
        count += group.length - 1; // -1 porque mantemos 1 original
      }
    });
    return count;
  }

  int get totalDuplicateSize {
    int size = 0;
    _duplicates.forEach((type, groups) {
      for (var group in groups) {
        // Somar tamanho de todos exceto o primeiro (original)
        for (int i = 1; i < group.length; i++) {
          size += group[i].size;
        }
      }
    });
    return size;
  }

  int _getCategoryDuplicateCount(FileType type) {
    int count = 0;
    final groups = _duplicates[type] ?? [];
    for (var group in groups) {
      count += group.length - 1;
    }
    return count;
  }

  int _getCategoryDuplicateSize(FileType type) {
    int size = 0;
    final groups = _duplicates[type] ?? [];
    for (var group in groups) {
      for (int i = 1; i < group.length; i++) {
        size += group[i].size;
      }
    }
    return size;
  }

  void _openCategory(FileType type) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CategoryDetailScreen(
          type: type,
          allFiles: _allFiles[type] ?? [],
          duplicateGroups: _duplicates[type] ?? [],
          onFilesDeleted: (deletedPaths) {
            setState(() {
              // Remover ficheiros eliminados da lista
              _allFiles[type]?.removeWhere((f) => deletedPaths.contains(f.filePath));
              
              // Atualizar grupos de duplicados
              for (var group in _duplicates[type] ?? []) {
                group.removeWhere((f) => deletedPaths.contains(f.filePath));
              }
              _duplicates[type]?.removeWhere((group) => group.length <= 1);
            });
          },
        ),
      ),
    );
  }

  void _cleanAllDuplicates() async {
    // Confirmar ação
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Confirmar Limpeza', style: TextStyle(color: Colors.white)),
        content: Text(
          'Vai eliminar $totalDuplicates ficheiros duplicados e libertar ${_scannerService.formatSize(totalDuplicateSize)}.\n\nEsta ação não pode ser desfeita.',
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
            child: const Text('Eliminar', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Mostrar loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF00E676)),
      ),
    );

    // Eliminar todos os duplicados
    List<String> pathsToDelete = [];
    _duplicates.forEach((type, groups) {
      for (var group in groups) {
        for (int i = 1; i < group.length; i++) {
          pathsToDelete.add(group[i].filePath);
        }
      }
    });

    int deleted = await _scannerService.deleteFiles(pathsToDelete);
    int freedSize = totalDuplicateSize;

    // Atualizar estado
    setState(() {
      _duplicates.forEach((type, groups) {
        for (var group in groups) {
          if (group.length > 1) {
            final toRemove = group.sublist(1);
            for (var item in toRemove) {
              _allFiles[type]?.removeWhere((f) => f.filePath == item.filePath);
            }
            group.removeRange(1, group.length);
          }
        }
        groups.removeWhere((group) => group.length <= 1);
      });
    });

    // Fechar loading
    if (mounted) {
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.celebration, color: Color(0xFF00E676)),
              const SizedBox(width: 12),
              Text('$deleted ficheiros eliminados! ${_scannerService.formatSize(freedSize)} libertados'),
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
                          ? 'O seu dispositivo está limpo!'
                          : 'Pode libertar ${_scannerService.formatSize(totalDuplicateSize)}',
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
                children: [
                  _buildCategoryTile(
                    FileType.photo,
                    'Fotos',
                    Icons.photo_library,
                    const Color(0xFF2196F3),
                  ),
                  _buildCategoryTile(
                    FileType.screenshot,
                    'Screenshots',
                    Icons.smartphone,
                    const Color(0xFF9C27B0),
                  ),
                  _buildCategoryTile(
                    FileType.video,
                    'Vídeos',
                    Icons.videocam,
                    const Color(0xFFFF9800),
                  ),
                  _buildCategoryTile(
                    FileType.music,
                    'Músicas',
                    Icons.music_note,
                    const Color(0xFFE91E63),
                  ),
                ],
              ),
            ),

            // Botão Limpar Todos
            if (totalDuplicates > 0)
              Padding(
                padding: const EdgeInsets.all(20),
                child: GestureDetector(
                  onTap: _cleanAllDuplicates,
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
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryTile(FileType type, String name, IconData icon, Color color) {
    final allCount = _allFiles[type]?.length ?? 0;
    final dupCount = _getCategoryDuplicateCount(type);
    final dupSize = _getCategoryDuplicateSize(type);

    return GestureDetector(
      onTap: () => _openCategory(type),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(0.3),
          ),
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
                  _scannerService.formatSize(dupSize),
                  style: TextStyle(
                    color: color,
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
