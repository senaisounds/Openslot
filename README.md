# Slotted - Event Booking and Management App

Slotted is a mobile application that allows users to discover, book, and manage event slots.

## Features

- Event discovery and search
- Event booking and management
- Interactive maps with location search
- User profiles and preferences
- Host event creation and management
- Real-time updates and notifications
- Payment processing integration

## Performance Optimizations

Slotted has been optimized for maximum performance and stability:

- **Image Caching**: Efficient image loading with CustomCacheManager
- **Memory Management**: Optimized memory usage and resource cleanup
- **Modern APIs**: Updated deprecated code with modern equivalents
- **Error Handling**: Graceful error recovery with ErrorBoundary
- **Performance Monitoring**: Built-in tools to track app performance

For details, see our [Performance Guide](PERFORMANCE_GUIDE.md) and [Optimization Summary](OPTIMIZATION_SUMMARY.md).

## Development

### Setup

```bash
# Clone the repository
git clone https://github.com/yourusername/slotted.git

# Install dependencies
flutter pub get

# Run the app
flutter run
```

### Performance Optimization

We've created several scripts to help maintain code quality and performance:

```bash
# Run all optimizations at once
./scripts/optimize_all.sh

# Or run individual scripts
dart scripts/remove_unused_code.dart
dart scripts/remove_unused_imports.dart
dart scripts/fix_withopacity_usage.dart
dart scripts/replace_prints.dart
dart scripts/fix_async_context.dart
```

## Testing

```bash
# Run unit tests
flutter test

# Run performance tests
flutter test test/performance/reservation_performance_test.dart
```

## Contributing

Please follow our coding standards and run the optimization scripts before submitting a pull request.

## Web Development

The Open Slot web version uses the HTML renderer for proper text display. To run the web version:

```bash
# Run with HTML renderer (recommended)
./run_web.sh

# Run with a clean build
./run_web.sh --clean
```

### Web-specific Considerations

- The web version uses system fonts instead of Google Fonts to ensure proper text rendering
- The HTML renderer is used instead of CanvasKit for better text compatibility
- Custom CSS in web/index.html provides fallback font support
- If text display issues occur, verify that the HTML renderer is being used

## License

This project is licensed under the MIT License - see the LICENSE file for details.
