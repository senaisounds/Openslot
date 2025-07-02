import 'dart:async';
import 'package:flutter/widgets.dart';

/// Stream Optimizer to reduce unnecessary rebuilds
/// This helps batch updates and prevent excessive setState calls
class StreamOptimizer<T> {
  final Duration batchDelay;
  Timer? _timer;
  T? _latestValue;
  bool _hasPendingUpdate = false;
  final StreamController<T> _controller = StreamController<T>.broadcast();

  StreamOptimizer({this.batchDelay = const Duration(milliseconds: 16)});

  /// Optimized stream that batches rapid updates
  Stream<T> get stream => _controller.stream;

  /// Add a new value (will be batched if updates come rapidly)
  void add(T value) {
    _latestValue = value;
    
    if (!_hasPendingUpdate) {
      _hasPendingUpdate = true;
      _timer = Timer(batchDelay, () {
        final currentValue = _latestValue;
        if (currentValue != null) {
          _controller.add(currentValue);
        }
        _hasPendingUpdate = false;
      });
    }
  }

  /// Immediately emit the current value without batching
  void addImmediate(T value) {
    _timer?.cancel();
    _hasPendingUpdate = false;
    _controller.add(value);
  }

  void dispose() {
    _timer?.cancel();
    _controller.close();
  }
}

/// Debounced Stream Transformer
/// Useful for search inputs and other rapid user interactions
class DebouncedStream<T> {
  final Duration delay;
  final StreamController<T> _controller = StreamController<T>();
  Timer? _timer;

  DebouncedStream({this.delay = const Duration(milliseconds: 300)});

  Stream<T> get stream => _controller.stream;

  void add(T value) {
    _timer?.cancel();
    _timer = Timer(delay, () {
      _controller.add(value);
    });
  }

  void dispose() {
    _timer?.cancel();
    _controller.close();
  }
}

/// Performance optimized StreamBuilder
/// Reduces unnecessary rebuilds by comparing data changes
class OptimizedStreamBuilder<T> extends StatefulWidget {
  final Stream<T>? stream;
  final T? initialData;
  final Widget Function(BuildContext context, AsyncSnapshot<T>) builder;

  const OptimizedStreamBuilder({
    super.key,
    this.stream,
    this.initialData,
    required this.builder,
  });

  @override
  State<OptimizedStreamBuilder<T>> createState() => _OptimizedStreamBuilderState<T>();
}

class _OptimizedStreamBuilderState<T> extends State<OptimizedStreamBuilder<T>> {
  AsyncSnapshot<T>? _lastSnapshot;
  
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<T>(
      stream: widget.stream,
      initialData: widget.initialData,
      builder: (context, snapshot) {
        // Only rebuild if data actually changed
        if (_lastSnapshot != null && 
            _lastSnapshot!.hasData && 
            snapshot.hasData &&
            _lastSnapshot!.data == snapshot.data) {
          return widget.builder(context, _lastSnapshot!);
        }
        
        _lastSnapshot = snapshot;
        return widget.builder(context, snapshot);
      },
    );
  }
}

/// Chat message optimization for Live page
/// Batches message updates to prevent UI stuttering
class ChatStreamOptimizer {
  static const Duration _batchDelay = Duration(milliseconds: 50);
  
  final StreamController<List<dynamic>> _controller = 
      StreamController<List<dynamic>>.broadcast();
  Timer? _batchTimer;
  List<dynamic> _pendingMessages = [];
  bool _hasPendingBatch = false;

  Stream<List<dynamic>> get stream => _controller.stream;

  void addMessage(dynamic message) {
    _pendingMessages.add(message);
    
    if (!_hasPendingBatch) {
      _hasPendingBatch = true;
      _batchTimer = Timer(_batchDelay, _flushBatch);
    }
  }

  void addMessages(List<dynamic> messages) {
    _pendingMessages.addAll(messages);
    
    if (!_hasPendingBatch) {
      _hasPendingBatch = true;
      _batchTimer = Timer(_batchDelay, _flushBatch);
    }
  }

  void _flushBatch() {
    if (_pendingMessages.isNotEmpty) {
      _controller.add(List.from(_pendingMessages));
      _pendingMessages.clear();
    }
    _hasPendingBatch = false;
  }

  void dispose() {
    _batchTimer?.cancel();
    _controller.close();
  }
}

/// Memory-efficient event stream
/// Reduces memory usage for event lists
class EventStreamOptimizer {
  final int maxCacheSize;
  final Map<String, dynamic> _eventCache = {};
  final List<String> _cacheOrder = [];
  
  EventStreamOptimizer({this.maxCacheSize = 50});

  void cacheEvent(String eventId, dynamic eventData) {
    // Remove oldest if cache is full
    if (_eventCache.length >= maxCacheSize && !_eventCache.containsKey(eventId)) {
      final oldestId = _cacheOrder.removeAt(0);
      _eventCache.remove(oldestId);
    }
    
    // Add/update event
    if (!_eventCache.containsKey(eventId)) {
      _cacheOrder.add(eventId);
    }
    _eventCache[eventId] = eventData;
  }

  dynamic getCachedEvent(String eventId) {
    return _eventCache[eventId];
  }

  void clearCache() {
    _eventCache.clear();
    _cacheOrder.clear();
  }
}

/// Usage examples:

// 1. For search functionality (debounced):
// final searchDebouncer = DebouncedStream<String>();
// searchDebouncer.stream.listen((query) => _performSearch(query));
// 
// // In onChanged:
// searchDebouncer.add(newSearchText);

// 2. For chat messages (batched):
// final chatOptimizer = ChatStreamOptimizer();
// chatOptimizer.stream.listen((messages) => _updateChatUI(messages));
//
// // When new message arrives:
// chatOptimizer.addMessage(newMessage);

// 3. For general streams (optimized rebuilds):
// OptimizedStreamBuilder<List<Event>>(
//   stream: eventsStream,
//   builder: (context, snapshot) => _buildEventsList(snapshot.data),
// ) 