#!/bin/bash

# Download pre-built whisper.cpp binary for macOS
# This is a temporary solution until we can properly build whisper.cpp

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_DIR="$( cd "$SCRIPT_DIR/.." && pwd )"
OUTPUT_DIR="$PROJECT_DIR/Transcribe/Resources"

echo "Setting up whisper.cpp for the app..."

# Create output directory
mkdir -p "$OUTPUT_DIR"

# For now, create a wrapper script that will use whisper.cpp if installed
cat > "$OUTPUT_DIR/whisper" << 'EOF'
#!/bin/bash

# Wrapper script for whisper.cpp
# This script tries to find and use whisper.cpp installed on the system

# List of possible whisper locations
WHISPER_PATHS=(
    "/usr/local/bin/whisper"
    "/opt/homebrew/bin/whisper"
    "/opt/homebrew/bin/whisper-cpp"
    "$HOME/.local/bin/whisper"
    "/usr/bin/whisper"
)

# Find whisper executable
WHISPER_BIN=""
for path in "${WHISPER_PATHS[@]}"; do
    if [ -x "$path" ]; then
        WHISPER_BIN="$path"
        break
    fi
done

# If not found in standard locations, try which
if [ -z "$WHISPER_BIN" ]; then
    WHISPER_BIN=$(which whisper 2>/dev/null || echo "")
fi

# If still not found, show error
if [ -z "$WHISPER_BIN" ] || [ ! -x "$WHISPER_BIN" ]; then
    echo "Error: whisper.cpp not found on the system" >&2
    echo "Please install whisper.cpp using: brew install whisper-cpp" >&2
    exit 1
fi

# Execute whisper with all arguments
exec "$WHISPER_BIN" "$@"
EOF

chmod +x "$OUTPUT_DIR/whisper"

echo "✅ Whisper wrapper script created"
echo "Location: $OUTPUT_DIR/whisper"
echo ""
echo "Note: This is a temporary wrapper that uses system-installed whisper.cpp"
echo "To use KB models, users need to install whisper.cpp:"
echo "  brew install whisper-cpp"
echo ""
echo "A future update will bundle whisper.cpp directly in the app."