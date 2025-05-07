import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RouterState<T> {
  final T currentRoute;
  final List<T> history;
  final int currentIndex;

  const RouterState({
    required this.currentRoute,
    required this.history,
    required this.currentIndex,
  });

  factory RouterState.initial(T initialRoute) {
    return RouterState(
      currentRoute: initialRoute,
      history: [initialRoute],
      currentIndex: 0,
    );
  }

  RouterState<T> navigate(T route) {
    if (route == currentRoute) return this;

    final newHistory = history.sublist(0, currentIndex + 1)..add(route);
    return RouterState(
      currentRoute: route,
      history: newHistory,
      currentIndex: newHistory.length - 1,
    );
  }

  RouterState<T> back() {
    if (currentIndex <= 0) return this;

    return RouterState(
      currentRoute: history[currentIndex - 1],
      history: history,
      currentIndex: currentIndex - 1,
    );
  }

  RouterState<T> forward() {
    if (currentIndex >= history.length - 1) return this;

    return RouterState(
      currentRoute: history[currentIndex + 1],
      history: history,
      currentIndex: currentIndex + 1,
    );
  }

  RouterState<T> jumpTo(int index) {
    if (index < 0 || index >= history.length || index == currentIndex) {
      return this;
    }

    return RouterState(
      currentRoute: history[index],
      history: history,
      currentIndex: index,
    );
  }

  RouterState<T> replace(T route) {
    if (route == currentRoute) return this;

    final newHistory = List<T>.from(history);
    newHistory[currentIndex] = route;

    return RouterState(
      currentRoute: route,
      history: newHistory,
      currentIndex: currentIndex,
    );
  }

  RouterState<T> reset(T route) {
    return RouterState.initial(route);
  }

  bool get canGoBack => currentIndex > 0;

  bool get canGoForward => currentIndex < history.length - 1;
}

class RouterNotifier<T> extends StateNotifier<RouterState<T>> {
  RouterNotifier(T initialRoute) : super(RouterState.initial(initialRoute));

  void navigate(T route) {
    state = state.navigate(route);
  }

  void back() {
    state = state.back();
  }

  void forward() {
    state = state.forward();
  }

  void jumpTo(int index) {
    state = state.jumpTo(index);
  }

  void replace(T route) {
    state = state.replace(route);
  }

  void reset(T route) {
    state = state.reset(route);
  }

  T get currentRoute => state.currentRoute;

  List<T> get history => state.history;

  int get currentIndex => state.currentIndex;

  bool get canGoBack => state.canGoBack;

  bool get canGoForward => state.canGoForward;
}

StateNotifierProvider<RouterNotifier<T>, RouterState<T>>
createRouterProvider<T>(T initialRoute) {
  return StateNotifierProvider<RouterNotifier<T>, RouterState<T>>(
    (ref) => RouterNotifier<T>(initialRoute),
  );
}

void handleSideMenuSelection<T>(
  WidgetRef ref,
  StateNotifierProvider<RouterNotifier<T>, RouterState<T>> provider,
  T route,
) {
  ref.read(provider.notifier).navigate(route);
}

bool isSideMenuItemActive<T>(
  WidgetRef ref,
  StateNotifierProvider<RouterNotifier<T>, RouterState<T>> provider,
  T route,
) {
  return ref.watch(provider).currentRoute == route;
}

Widget buildRouterHistory<T>(
  WidgetRef ref,
  StateNotifierProvider<RouterNotifier<T>, RouterState<T>> provider, {
  required Widget Function(T route, bool isActive, VoidCallback onTap)
  itemBuilder,
}) {
  final routerState = ref.watch(provider);

  return ListView.builder(
    shrinkWrap: true,
    itemCount: routerState.history.length,
    itemBuilder: (context, index) {
      final route = routerState.history[index];
      final isActive = index == routerState.currentIndex;
      return itemBuilder(
        route,
        isActive,
        () => ref.read(provider.notifier).jumpTo(index),
      );
    },
  );
}
