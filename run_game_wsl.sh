#!/bin/bash
# WSL2-optimized game launcher with display configuration

echo "=== Pachinko Game Launcher for WSL2 ==="
echo ""

# Set Flutter path
export PATH="/home/frankbria/projects/pachinko/tools/flutter/bin:$PATH"

# Kill any existing Flutter processes
echo "Stopping existing Flutter processes..."
pkill -f "flutter run" 2>/dev/null
sleep 2

# Check if DISPLAY is set
if [ -z "$DISPLAY" ]; then
    echo "⚠️  DISPLAY not set. Setting to :0"
    export DISPLAY=:0
fi

echo "Display: $DISPLAY"
echo ""

# Navigate to project
cd /home/frankbria/projects/pachinko

# Check Flutter installation
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter not found in PATH"
    exit 1
fi

echo "Flutter version:"
flutter --version | head -1
echo ""

# Run with better error handling
echo "🚀 Launching Pachinko game..."
echo "   (This may take 30-60 seconds to build and launch)"
echo ""
echo "If you don't see a window, you may need to:"
echo "  1. Install an X server on Windows (VcXsrv, X410, etc.)"
echo "  2. Configure X server to allow connections from WSL"
echo "  3. Set DISPLAY in WSL: export DISPLAY=\$(cat /etc/resolv.conf | grep nameserver | awk '{print \$2}'):0"
echo ""

flutter run -d linux 2>&1 | tee /tmp/pachinko_run.log

echo ""
echo "Log saved to: /tmp/pachinko_run.log"
