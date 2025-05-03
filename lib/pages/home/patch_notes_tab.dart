import 'package:flutter/material.dart';
import '../../widgets/patch_note_card.dart';
import '../../api/Minecraft.dart';

class PatchNotesTab extends StatefulWidget {
  const PatchNotesTab({super.key});

  @override
  State<PatchNotesTab> createState() => _PatchNotesTabState();
}

class _PatchNotesTabState extends State<PatchNotesTab> {
  final List<PatchNoteCard> _patchNotes = [];
  bool _isLoading = true;
  String? _errorMessage;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchPatchNotes();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchPatchNotes() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final minecraftAdaptor = MinecraftAdaptor();
      final javaPatchNote = await minecraftAdaptor.getJavaPatchNotes();

      final List<PatchNoteCard> fetchedNotes =
          javaPatchNote.entries.map((entry) {
            return PatchNoteCard(
              key: ValueKey(entry.version),
              title: entry.title,
              version: entry.version,
              description: entry.body,
              imageUrl: entry.image?.url,
              onTap: () {},
            );
          }).toList();

      if (mounted) {
        setState(() {
          _patchNotes.clear();
          _patchNotes.addAll(fetchedNotes);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'パッチノートの取得に失敗しました: ${e.toString()}';
          _isLoading = false;
        });
      }
      debugPrint('Error fetching patch notes: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(_errorMessage!),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _fetchPatchNotes,
              child: const Text('再試行'),
            ),
          ],
        ),
      );
    }

    if (_patchNotes.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.article, size: 48),
            SizedBox(height: 16),
            Text('パッチノートがありません'),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchPatchNotes,
      child: GridView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(8.0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 0.7,
          crossAxisSpacing: 8.0,
          mainAxisSpacing: 12.0,
        ),
        itemCount: _patchNotes.length,
        itemBuilder: (context, index) => _patchNotes[index],
        cacheExtent: 500,
      ),
    );
  }
}
