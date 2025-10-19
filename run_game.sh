#!/bin/bash
# Quick game restart script

# Kill any existing Flutter processes
pkill -f "flutter run" 2>/dev/null

# Set Flutter path
export PATH="/home/frankbria/projects/pachinko/tools/flutter/bin:$PATH"

# Run the game
cd /home/frankbria/projects/pachinko
flutter run -d linux
