import 'package:flutter/material.dart';
import 'dart:io';
import '../services/file_scanner_service.dart';

class CategoryDetailScreen extends StatefulWidget {
  final FileType type;
  final List<FileItem> allFiles;
  final List<List<FileItem>> duplicateGroups;
  final Function(List<String>) onFilesDeleted;

  const CategoryDetailScreen({
    super.key,
    required this.type,
    required this.allFiles,
    required this.duplicateGroups,
    required this.onFilesDeleted,
  });

  @override
  State<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends State<CategoryDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FileScannerService _scannerService = FileScannerService();
  
  late List<FileItem> _allFiles;
  late List<List<FileItem>> _duplicateGroups;
  Set<String> _selectedForDeletion = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _allFiles = List.from(widget.allFiles);
    _duplicateGroups = widget.duplicateGroups.map((g) => List<FileItem>.from(g)).toList();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String get categoryName {
    switch (widget.type) {
      case FileType.photo: return 'Fotos';
      case FileType.screenshot: return 'Screenshots';
      case FileType.video: return 'Vídeos';
      case FileType.music: return 'Músicas';
      case FileType.contact: return 'Contactos';
    }
  }

  String get allTabTitle {
    switch (widget.type) {
      case FileType.photo: return 'Todas as Fotos';
      case FileType.screenshot: return 'Todos os Screenshots';
      case FileType.video: return 'Todos os Vídeos';
      case FileType.music: return 'Todas as Músicas';
      case FileType.contact: return 'Todos os Contactos';
    }
  }

  String get duplicatesTabTitle {
    switch (widget.type) {
      case FileType.photo: return 'Fotos Duplicadas';
      case FileType.screenshot: return 'Screenshots Duplicados';
      case FileType.video: return 'Vídeos Duplicados';
      case FileType.music: return 'Músicas Duplicadas';
      case FileType.contact: return 'Contactos Duplicados';
    }
  }

  Color get categoryColor {
    switch (widget.type) {
      case FileType.photo: return const Color(0xFF2196F3);
      case FileType.screenshot: return const Color(0xFF9C27B0);
      case FileType.video: return const Color(0xFFFF9800);
      case FileType.music: return const Color(0xFFE91E63);
      case FileType.contact: return const Color(0xFF4CAF50);
    }
  }

  List<FileItem> get duplicateFiles {
    List<FileItem> duplicates = [];
    for (var group in _duplicateGroups) {
      if (group.length > 1) {
        // Adicionar todos exceto o primeiro (que é o "original")
        duplicates.addAll(group.sublist(1));
      }
    }
    return duplicates;
  }

  int get duplicateSize {
    int size = 0;
    for (var file in duplicateFiles) {
      size += file.size;
    }
    return size;
  }

  void _deleteDuplicates() async {
    if (duplicateFiles.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Confirmar Eliminação', style: TextStyle(color: Colors.white)),
        content: Text(
          'Vai eliminar ${duplicateFiles.length} ficheiros duplicados e libertar ${_scannerService.formatSize(duplicateSize)}.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: categoryColor),
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: CircularProgressIndicator(color: categoryColor),
      ),
    );

    List<String> pathsToDelete = duplicateFiles.map((f) => f.filePath).toList();
    int deleted = await _scannerService.deleteFiles(pathsToDelete);
    int freedSize = duplicateSize;

    // Atualizar estado
    setState(() {
      for (var path in pathsToDelete) {
        _allFiles.removeWhere((f) => f.filePath == path);
      }
      for (var group in _duplicateGroups) {
        if (group.length > 1) {
          group.removeRange(1, group.length);
        }
      }
      _duplicateGroups.removeWhere((g) => g.length <= 1);
    });

    widget.onFilesDeleted(pathsToDelete);

    if (mounted) {
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: categoryColor),
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
        title: Text(
          categoryName,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: categoryColor,
          labelColor: categoryColor,
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
          _buildFilesGrid(_allFiles, false),
          
          // Tab: Duplicados
          _buildFilesGrid(duplicateFiles, true),
        ],
      ),
      bottomNavigationBar: duplicateFiles.isNotEmpty
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: GestureDetector(
                  onTap: _deleteDuplicates,
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [categoryColor, categoryColor.withOpacity(0.7)],
                      ),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: categoryColor.withOpacity(0.4),
                          blurRadius: 15,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        'Eliminar ${duplicateFiles.length} Duplicados (${_scannerService.formatSize(duplicateSize)})',
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

  Widget _buildFilesGrid(List<FileItem> files, bool isDuplicates) {
    if (files.isEmpty) {
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
      itemCount: files.length,
      itemBuilder: (context, index) {
        return _buildFileTile(files[index], isDuplicates);
      },
    );
  }

  Widget _buildFileTile(FileItem file, bool isDuplicate) {
    Widget thumbnail;
    
    if (widget.type == FileType.photo || widget.type == FileType.screenshot) {
      // Mostrar thumbnail da imagem
      thumbnail = Image.file(
        File(file.filePath),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Icon(Icons.image, color: categoryColor.withOpacity(0.6), size: 40);
        },
      );
    } else if (widget.type == FileType.video) {
      thumbnail = Stack(
        alignment: Alignment.center,
        children: [
          Container(color: const Color(0xFF2D2D2D)),
          Icon(Icons.play_circle_filled, color: categoryColor, size: 40),
        ],
      );
    } else {
      thumbnail = Icon(
        widget.type == FileType.music ? Icons.music_note : Icons.insert_drive_file,
        color: categoryColor.withOpacity(0.6),
        size: 40,
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: isDuplicate
            ? Border.all(color: Colors.red.withOpacity(0.5), width: 2)
            : null,
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: thumbnail,
          ),
          if (isDuplicate)
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
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
              ),
              child: Text(
                _scannerService.formatSize(file.size),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
