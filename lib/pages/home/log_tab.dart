import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:karasu_launcher/models/minecraft_state.dart';
import 'package:karasu_launcher/providers/minecraft_state_provider.dart';
import 'dart:async';

class LogTab extends ConsumerStatefulWidget {
  const LogTab({super.key});

  @override
  ConsumerState<LogTab> createState() => _LogTabState();
}

class _LogTabState extends ConsumerState<LogTab> {
  bool _showInfoLogs = true;
  bool _showDebugLogs = true;
  bool _showWarningLogs = true;
  bool _showErrorLogs = true;

  bool _showJavaStdout = true;
  bool _showJavaStderr = true;
  bool _autoScroll = true;
  final ScrollController _scrollController = ScrollController();
  int _previousLogCount = 0;
  List<LogMessage> _currentFilteredLogs = [];
  Timer? _updateTimer;
  List<LogMessage> _lastLogs = [];
  bool _needsRefiltration = true;

  @override
  void initState() {
    super.initState();
    _updateTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (mounted) {
        final minecraftState = ref.read(minecraftStateProvider);

        if (minecraftState.logs == _lastLogs && !_needsRefiltration) {
          return;
        }

        _lastLogs = minecraftState.logs;

        Future.microtask(() {
          if (!mounted) return;
          setState(() {
            _currentFilteredLogs = _filteredLogs(_lastLogs);
            _needsRefiltration = false;

            if (_autoScroll &&
                _currentFilteredLogs.length > _previousLogCount) {
              Future.microtask(() => _smoothScrollToBottom());
            }
            _previousLogCount = _currentFilteredLogs.length;
          });
        });
      }
    });
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _clearLogs() {
    ref.read(minecraftStateProvider.notifier).clearLogs();
  }

  void _onFilterChanged() {
    setState(() {
      _needsRefiltration = true;

      _currentFilteredLogs = _filteredLogs(_lastLogs);
      _needsRefiltration = false;
    });
  }

  List<LogMessage> _filteredLogs(List<LogMessage> logs) {
    if (logs.isEmpty) return [];

    return logs.where((log) {
      bool levelMatch = false;
      if (log.level == LogLevel.info && _showInfoLogs) levelMatch = true;
      if (log.level == LogLevel.debug && _showDebugLogs) levelMatch = true;
      if (log.level == LogLevel.warning && _showWarningLogs) levelMatch = true;
      if (log.level == LogLevel.error && _showErrorLogs) levelMatch = true;

      bool sourceMatch = true;
      if (log.source == LogSource.javaStdOut && !_showJavaStdout) {
        sourceMatch = false;
      }
      if (log.source == LogSource.javaStdErr && !_showJavaStderr) {
        sourceMatch = false;
      }

      return levelMatch && sourceMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Row(
                children: [
                  const Text('種類: '),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('情報'),
                    selected: _showInfoLogs,
                    onSelected: (value) {
                      setState(() {
                        _showInfoLogs = value;
                        _onFilterChanged();
                      });
                    },
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('アセット取得'),
                    selected: _showDebugLogs,
                    onSelected: (value) {
                      setState(() {
                        _showDebugLogs = value;
                        _onFilterChanged();
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('ライブラリ取得'),
                    selected: _showWarningLogs,
                    onSelected: (value) {
                      setState(() {
                        _showWarningLogs = value;
                        _onFilterChanged();
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('エラー'),
                    selected: _showErrorLogs,
                    onSelected: (value) {
                      setState(() {
                        _showErrorLogs = value;
                        _onFilterChanged();
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  const Text('ソース: '),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Java 標準出力'),
                    selected: _showJavaStdout,
                    onSelected: (value) {
                      setState(() {
                        _showJavaStdout = value;
                        _onFilterChanged();
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Java エラー出力'),
                    selected: _showJavaStderr,
                    onSelected: (value) {
                      setState(() {
                        _showJavaStderr = value;
                        _onFilterChanged();
                      });
                    },
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Checkbox(
                        value: _autoScroll,
                        onChanged: (value) {
                          setState(() {
                            _autoScroll = value ?? true;
                            if (_autoScroll &&
                                _currentFilteredLogs.isNotEmpty) {
                              _smoothScrollToBottom();
                            }
                          });
                        },
                      ),
                      const Text('自動スクロール'),
                    ],
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () {
                      _clearLogs();
                    },
                    child: const Text("クリア"),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 40, 40, 40),
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(4),
            ),
            height: 300,
            margin: const EdgeInsets.all(8.0),
            child:
                _currentFilteredLogs.isEmpty
                    ? const Center(child: Text('ログはありません'))
                    : ListView.builder(
                      controller: _scrollController,
                      itemCount: _currentFilteredLogs.length,
                      itemBuilder: (context, index) {
                        final log = _currentFilteredLogs[index];
                        return ListTile(
                          dense: true,
                          visualDensity: VisualDensity.compact,
                          leading: _getIconForLogLevel(log.level),
                          title: Text(
                            '${_getFormattedTimestamp(log.timestamp)} ${log.message}',
                          ),
                          textColor: _getColorForLogLevel(log.level),
                        );
                      },
                    ),
          ),
        ),
      ],
    );
  }

  String _getFormattedTimestamp(DateTime timestamp) {
    return '[${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}]';
  }

  void _smoothScrollToBottom() {
    if (!_scrollController.hasClients) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;

      if (_scrollController.position.pixels >
          _scrollController.position.maxScrollExtent - 100) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      } else {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Icon _getIconForLogLevel(LogLevel level) {
    switch (level) {
      case LogLevel.info:
        return const Icon(Icons.app_shortcut, color: Colors.blue);
      case LogLevel.debug:
        return const Icon(Icons.file_download, color: Colors.green);
      case LogLevel.warning:
        return const Icon(Icons.library_books, color: Colors.orange);
      case LogLevel.error:
        return const Icon(Icons.error_outline, color: Colors.red);
    }
  }

  Color _getColorForLogLevel(LogLevel level) {
    switch (level) {
      case LogLevel.info:
        return Colors.white;
      case LogLevel.debug:
        return Colors.green.shade700;
      case LogLevel.warning:
        return Colors.orange.shade700;
      case LogLevel.error:
        return Colors.red.shade700;
    }
  }
}
