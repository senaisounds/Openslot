#!/bin/bash

# Script to run the app with minimal logging
cd "$(dirname "$0")"
flutter run -t lib/run_quiet.dart "$@" 