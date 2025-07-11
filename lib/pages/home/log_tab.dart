import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:karasu_launcher/providers/log_provider.dart';
import 'dart:async';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter_quill/flutter_quill.dart';

class LogTab extends ConsumerStatefulWidget {
  const LogTab({super.key});

  @override
  ConsumerState<LogTab> createState() => _LogTabState();
}

class _LogTabState extends ConsumerState<LogTab>
    with AutomaticKeepAliveClientMixin {
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
  bool _isManualScrolling = false;
  final ScrollController _loadingScrollController = ScrollController();

  int _displayedLogsCount = 20;
  bool _isLoadingMore = false;
  static const int _loadBatchSize = 20;
  QuillController _quillController = QuillController.basic();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScrollChange);
    _updateTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (mounted) {
        final logState = ref.read(logProvider);
        final currentLogs = logState.logs;

        if (currentLogs == _lastLogs && !_needsRefiltration) {
          return;
        }

        _updateLogsWithoutFullReload(currentLogs);
      }
    });

    _quillController = QuillController(
      document: Document(),
      selection: const TextSelection.collapsed(offset: 0),
    );
  }

  void _updateLogsWithoutFullReload(List<LogMessage> currentLogs) {
    if (!mounted) return;

    final wasEmpty = _currentFilteredLogs.isEmpty;
    _lastLogs = currentLogs;

    if (_needsRefiltration) {
      _currentFilteredLogs = _filteredLogs(_lastLogs);
      _needsRefiltration = false;
    } else {
      final newItems = _lastLogs.length - _previousLogCount;
      if (newItems > 0) {
        final newLogs = _lastLogs.sublist(_previousLogCount);
        final filteredNewLogs = _filteredLogs(newLogs);
        _currentFilteredLogs.addAll(filteredNewLogs);
      }
    }

    setState(() {
      _updateQuillDocument();

      if (wasEmpty ||
          (_autoScroll &&
              _currentFilteredLogs.length > _previousLogCount &&
              !_isManualScrolling)) {
        _checkAndScrollToBottom();
      }
      _previousLogCount = _lastLogs.length;
    });
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    _scrollController.removeListener(_handleScrollChange);
    _scrollController.dispose();
    _loadingScrollController.dispose();
    _quillController.dispose();
    super.dispose();
  }

  void _handleScrollChange() {
    if (_scrollController.hasClients) {
      final isScrolling = _scrollController.position.isScrollingNotifier.value;

      if (isScrolling) {
        final isUserScroll =
            _scrollController.position.userScrollDirection !=
            ScrollDirection.idle;

        setState(() {
          _isManualScrolling = true;

          if (isUserScroll && _autoScroll) {
            _autoScroll = false;
          }
        });

        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted &&
              _scrollController.hasClients &&
              !_scrollController.position.isScrollingNotifier.value) {
            setState(() {
              _isManualScrolling = false;
            });
          }
        });
      }

      if (_scrollController.position.pixels <=
              _scrollController.position.minScrollExtent + 200 &&
          !_isLoadingMore &&
          _displayedLogsCount < _currentFilteredLogs.length) {
        _loadMoreLogs();
      }
    }
  }

  void _loadMoreLogs() {
    _isLoadingMore = true;

    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() {
        _displayedLogsCount += _loadBatchSize;
        _isLoadingMore = false;
      });
    });
  }

  void _clearLogs() {
    ref.read(logProvider.notifier).clearLogs();
    setState(() {
      _displayedLogsCount = 20;
      _previousLogCount = 0;
      _currentFilteredLogs.clear();
      _quillController.clear();
    });
  }

  void _onFilterChanged() {
    setState(() {
      _needsRefiltration = true;

      _currentFilteredLogs = _filteredLogs(_lastLogs);
      _needsRefiltration = false;
      _displayedLogsCount = 20;
      _updateQuillDocument();

      if (_autoScroll && _currentFilteredLogs.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _smoothScrollToBottom();
        });
      }
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
      switch (log.source) {
        case LogSource.javaStdOut:
          sourceMatch = _showJavaStdout;
          break;
        case LogSource.javaStdErr:
          sourceMatch = _showJavaStderr;
          break;
        case LogSource.app:
        case LogSource.network:
      }

      return levelMatch && sourceMatch;
    }).toList();
  }

  List<LogMessage> _getDisplayedLogs() {
    if (_currentFilteredLogs.isEmpty) return [];

    final startIndex =
        (_currentFilteredLogs.length > _displayedLogsCount)
            ? _currentFilteredLogs.length - _displayedLogsCount
            : 0;

    return _currentFilteredLogs.sublist(startIndex);
  }

  void _updateQuillDocument() {
    final displayedLogs = _getDisplayedLogs();

    final Delta delta = Delta();

    if (displayedLogs.isEmpty) {
      delta.insert('\n');
    } else {
      for (int i = 0; i < displayedLogs.length; i++) {
        final log = displayedLogs[i];
        final logText =
            '${_getFormattedTimestamp(log.timestamp)} ${log.message}\n';

        final color = _getColorForLog(log);
        final colorHex = '#${color.toARGB32().toRadixString(16).substring(2)}';

        delta.insert(logText, {'color': colorHex, 'font': 'monospace'});
      }
    }

    try {
      final document = Document.fromDelta(delta);

      final currentOffset = _quillController.selection.baseOffset;
      final isAtEnd = currentOffset >= _quillController.document.length - 1;

      _quillController.document = document;

      if (_autoScroll && !_isManualScrolling) {
        _quillController.updateSelection(
          TextSelection.collapsed(offset: document.length),
          ChangeSource.local,
        );
      } else if (!isAtEnd &&
          currentOffset > 0 &&
          currentOffset < document.length) {
        _quillController.updateSelection(
          TextSelection.collapsed(offset: currentOffset),
          ChangeSource.local,
        );
      }
    } catch (e) {
      debugPrint('QuillController更新エラー: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_autoScroll &&
          !_isManualScrolling &&
          _currentFilteredLogs.isNotEmpty) {
        _smoothScrollToBottom();
      }
    });

    final displayedLogs = _getDisplayedLogs();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Row(
                children: [
                  Text('${FlutterI18n.translate(context, 'logTab.type')}: '),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: Text(FlutterI18n.translate(context, 'logTab.info')),
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
                    label: Text(
                      FlutterI18n.translate(context, 'logTab.assetFetch'),
                    ),
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
                    label: Text(
                      FlutterI18n.translate(context, 'logTab.libraryFetch'),
                    ),
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
                    label: Text(FlutterI18n.translate(context, 'logTab.error')),
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
                  Text('${FlutterI18n.translate(context, 'logTab.source')}: '),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: Text(
                      FlutterI18n.translate(context, 'logTab.javaStdOut'),
                    ),
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
                    label: Text(
                      FlutterI18n.translate(context, 'logTab.javaStdErr'),
                    ),
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
                      Text(FlutterI18n.translate(context, 'logTab.autoScroll')),
                    ],
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () {
                      _clearLogs();
                    },
                    child: Text(FlutterI18n.translate(context, 'logTab.clear')),
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
                displayedLogs.isEmpty
                    ? Center(
                      child: SelectableText(
                        FlutterI18n.translate(context, 'logTab.noLogs'),
                        style: const TextStyle(color: Colors.white70),
                      ),
                    )
                    : RepaintBoundary(
                      child: Stack(
                        children: [
                          QuillEditor(
                            controller: _quillController,
                            scrollController: _scrollController,
                            focusNode: FocusNode(),
                            config: QuillEditorConfig(
                              scrollable: true,
                              autoFocus: false,

                              expands: true,
                              padding: const EdgeInsets.all(8),
                              keyboardAppearance: Brightness.dark,
                              enableSelectionToolbar: true,
                              showCursor: false,
                              placeholder: FlutterI18n.translate(
                                context,
                                'logTab.noLogs',
                              ),
                              customStyles: DefaultStyles(
                                placeHolder: DefaultTextBlockStyle(
                                  const TextStyle(color: Colors.white70),
                                  const HorizontalSpacing(0, 0),
                                  const VerticalSpacing(0, 0),
                                  const VerticalSpacing(0, 0),
                                  null,
                                ),
                                paragraph: DefaultTextBlockStyle(
                                  const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    height: 1.3,
                                    fontFamily: 'monospace',
                                  ),
                                  const HorizontalSpacing(0, 0),
                                  const VerticalSpacing(0, 0),
                                  const VerticalSpacing(0, 0),
                                  null,
                                ),
                              ),
                            ),
                          ),

                          if (_currentFilteredLogs.length > _displayedLogsCount)
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '$_displayedLogsCount/${_currentFilteredLogs.length}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
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

    Future.delayed(const Duration(milliseconds: 50), () {
      if (!mounted || !_scrollController.hasClients) return;

      if (_isManualScrolling) {
        return;
      }

      try {
        final maxExtent = _scrollController.position.maxScrollExtent;
        _scrollController.animateTo(
          maxExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      } catch (e) {
        debugPrint('Scroll error: $e');
      }
    });
  }

  void _checkAndScrollToBottom() {
    if (_autoScroll && _currentFilteredLogs.isNotEmpty && !_isManualScrolling) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _smoothScrollToBottom();
      });
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

  Color _getColorForLog(LogMessage log) {
    if (log.source == LogSource.javaStdOut) {
      return Colors.lightBlue.shade300;
    }

    return _getColorForLogLevel(log.level);
  }

  @override
  bool get wantKeepAlive => true;
}
