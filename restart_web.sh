#!/bin/bash
echo "Stopping any running Flutter processes..."
pkill -f "flutter"
sleep 2

echo "Clearing Flutter web cache..."
flutter clean
rm -rf build/web

# Set environment variable for HTML renderer
export FLUTTER_WEB_RENDERER=html

echo "Rebuilding and starting the app..."
flutter run -d chrome

# Once the app is running, open the force_html.html file
echo "Opening the special HTML renderer page..."
sleep 10
open http://localhost:*/force_html.html 