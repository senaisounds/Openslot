#!/bin/bash

echo "Serving the built web app locally..."
echo "Access the app at: http://localhost:8000"
echo "Press Ctrl+C to stop the server"
echo ""

# Change to the build/web directory
cd build/web

# Check if Python 3 is available
if command -v python3 &>/dev/null; then
    python3 -m http.server 8000
# Fall back to Python 2 if needed
elif command -v python &>/dev/null; then
    python -m SimpleHTTPServer 8000
else
    echo "Error: Python is not installed. Please install Python to run this server."
    exit 1
fi 