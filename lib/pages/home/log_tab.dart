import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:karasu_launcher/models/minecraft_state.dart';
import 'package:karasu_launcher/providers/minecraft_state_provider.dart';
import 'dart:async';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

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
  bool _isLoading = false;
  bool _isManualScrolling = false;
  final ScrollController _loadingScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScrollChange);
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
            _isLoading = true;
          });

          Future.delayed(const Duration(milliseconds: 300), () {
            if (!mounted) return;
            setState(() {
              _currentFilteredLogs = _filteredLogs(_lastLogs);
              _needsRefiltration = false;
              _isLoading = false;

              if (_autoScroll &&
                  _currentFilteredLogs.length > _previousLogCount) {
                _checkAndScrollToBottom();
              }
              _previousLogCount = _currentFilteredLogs.length;
            });
          });
        });
      }
    });
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    _scrollController.removeListener(_handleScrollChange);
    _scrollController.dispose();
    _loadingScrollController.dispose();
    super.dispose();
  }

  void _handleScrollChange() {
    if (_scrollController.hasClients) {
      final isScrolling = _scrollController.position.isScrollingNotifier.value;

      if (isScrolling) {
        setState(() {
          _isManualScrolling = true;
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
    }
  }

  void _clearLogs() {
    ref.read(minecraftStateProvider.notifier).clearLogs();
  }

  void _onFilterChanged() {
    setState(() {
      _needsRefiltration = true;
      _isLoading = true;

      Future.delayed(const Duration(milliseconds: 300), () {
        if (!mounted) return;
        setState(() {
          _currentFilteredLogs = _filteredLogs(_lastLogs);
          _needsRefiltration = false;
          _isLoading = false;
        });
      });
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
    super.build(context);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_autoScroll && !_isLoading && _currentFilteredLogs.isNotEmpty) {
        _smoothScrollToBottom();
      }
    });

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
                _isLoading
                    ? _buildLoadingState()
                    : _currentFilteredLogs.isEmpty
                    ? Center(
                      child: Text(
                        FlutterI18n.translate(context, 'logTab.noLogs'),
                      ),
                    )
                    : RepaintBoundary(
                      child: CustomScrollView(
                        controller: _scrollController,
                        slivers: [
                          SliverList(
                            delegate: SliverChildBuilderDelegate((
                              context,
                              index,
                            ) {
                              final log = _currentFilteredLogs[index];
                              return Text(
                                '${_getFormattedTimestamp(log.timestamp)} ${log.message}',
                                style: TextStyle(
                                  color: _getColorForLogLevel(log.level),
                                ),
                              );
                            }, childCount: _currentFilteredLogs.length),
                          ),
                        ],
                      ),
                    ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Stack(
      children: [
        RepaintBoundary(
          child: Skeletonizer(
            enabled: true,
            child: ListView.builder(
              controller: _loadingScrollController,
              itemCount: 10,
              itemBuilder: (context, index) {
                final mockLevel =
                    index % 4 == 0
                        ? LogLevel.info
                        : index % 4 == 1
                        ? LogLevel.debug
                        : index % 4 == 2
                        ? LogLevel.warning
                        : LogLevel.error;

                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 4.0,
                  ),
                  child: Text(
                    '[00:00:00] ${FlutterI18n.translate(context, 'logTab.sampleLogMessage')} $index',
                    style: TextStyle(
                      color: _getColorForLogLevel(mockLevel),
                      fontSize: 13,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        Center(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const CircularProgressIndicator(),
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
          maxExtent + 200,
          duration: const Duration(milliseconds: 300),
          curve: Curves.linear,
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

  @override
  bool get wantKeepAlive => true;
}
