#!/bin/bash

# Build whisper.cpp for macOS
# This script builds whisper.cpp for the current architecture

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_DIR="$( cd "$SCRIPT_DIR/.." && pwd )"
WHISPER_DIR="$PROJECT_DIR/Libraries/whisper.cpp"
OUTPUT_DIR="$PROJECT_DIR/Transcribe/Resources"

echo "Building whisper.cpp..."

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Navigate to whisper.cpp directory
cd "$WHISPER_DIR"

# Build whisper.cpp using the existing Makefile
echo "Compiling whisper.cpp..."
make clean 2>/dev/null || true
make -j8

# Copy the binary to Resources
# The main executable is usually created as 'main' or in bin/main
if [ -f "main" ]; then
    cp main "$OUTPUT_DIR/whisper"
elif [ -f "bin/main" ]; then
    cp bin/main "$OUTPUT_DIR/whisper"
elif [ -f "examples/main/main" ]; then
    cp examples/main/main "$OUTPUT_DIR/whisper"
else
    echo "❌ Build failed - main executable not found"
    echo "Looking for executable in:"
    find . -name "main" -type f 2>/dev/null | head -10
    exit 1
fi

chmod +x "$OUTPUT_DIR/whisper"
echo "✅ whisper.cpp built successfully!"
echo "Binary location: $OUTPUT_DIR/whisper"

# Verify the binary
file "$OUTPUT_DIR/whisper"
ls -lh "$OUTPUT_DIR/whisper"