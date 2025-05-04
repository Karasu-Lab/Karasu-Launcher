import 'package:flutter/material.dart';

class TabItem {
  final String title;
  final Widget content;

  const TabItem({required this.title, required this.content});
}

class TabWidget extends StatefulWidget {
  final List<TabItem> tabs;
  final Function(int)? onTabChanged;

  const TabWidget({super.key, required this.tabs, this.onTabChanged});

  @override
  State<TabWidget> createState() => _TabWidgetState();
}

class _TabWidgetState extends State<TabWidget> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: widget.tabs.length, vsync: this);

    _tabController.addListener(_handleTabSelection);
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging ||
        _tabController.index != _tabController.previousIndex) {
      if (widget.onTabChanged != null) {
        widget.onTabChanged!(_tabController.index);
      }
    }
  }

  @override
  void didUpdateWidget(TabWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.tabs.length != oldWidget.tabs.length) {
      _tabController.removeListener(_handleTabSelection);
      _tabController.dispose();
      _tabController = TabController(length: widget.tabs.length, vsync: this);
      _tabController.addListener(_handleTabSelection);
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: widget.tabs.length,
      child: Builder(
        builder: (BuildContext context) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                color: Theme.of(context).colorScheme.surface,
                child: Material(
                  color: Colors.transparent,

                  child: Builder(
                    builder: (BuildContext materialContext) {
                      return TabBar(
                        controller: _tabController,
                        labelColor: Theme.of(context).colorScheme.primary,
                        unselectedLabelColor: Theme.of(
                          context,
                        ).colorScheme.onSurface.withAlpha(153),
                        indicatorColor: Theme.of(context).colorScheme.primary,
                        tabs:
                            widget.tabs
                                .map((tab) => Tab(text: tab.title))
                                .toList(),
                      );
                    },
                  ),
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: widget.tabs.map((tab) => tab.content).toList(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
