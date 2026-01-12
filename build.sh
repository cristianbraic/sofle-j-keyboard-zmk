#!/bin/bash
# Local ZMK Build Script using Docker
# Usage: ./build.sh [left|right|left_studio|settings_reset]

set -e

BOARD_LEFT="eyelash_sofle_left"
BOARD_RIGHT="eyelash_sofle_right"
SHIELD="nice_view"
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="$PROJECT_DIR/build_output"

# Create output directory
mkdir -p "$BUILD_DIR"

build_firmware() {
    local board=$1
    local shield=$2
    local extra_args=$3
    local output_name=$4
    
    echo "========================================"
    echo "Building: $output_name"
    echo "Board: $board"
    echo "Shield: $shield"
    echo "========================================"
    
    docker run --rm \
        -v "$PROJECT_DIR:/project" \
        -v "$BUILD_DIR:/build_output" \
        -w /project \
        docker.io/zmkfirmware/zmk-build-arm:stable \
        bash -c "
            west init -l config 2>/dev/null || true
            west update
            west zephyr-export
            west build -s zmk/app -p -b $board -- \
                -DZMK_CONFIG=/project/config \
                -DSHIELD='$shield' \
                -DBOARD_ROOT=/project \
                $extra_args
            cp build/zephyr/zmk.uf2 /build_output/${output_name}.uf2 2>/dev/null || \
            cp build/zephyr/zmk.bin /build_output/${output_name}.bin 2>/dev/null || \
            echo 'Build output not found'
        "
    
    echo "✅ Built: $output_name"
}

case "${1:-all}" in
    left)
        build_firmware "$BOARD_LEFT" "$SHIELD" "" "eyelash_sofle_left-nice_view"
        ;;
    right)
        build_firmware "$BOARD_RIGHT" "$SHIELD" "" "eyelash_sofle_right-nice_view"
        ;;
    left_studio)
        build_firmware "$BOARD_LEFT" "$SHIELD" "-DCONFIG_ZMK_STUDIO=y -DCONFIG_ZMK_STUDIO_LOCKING=n -DSNIPPET=studio-rpc-usb-uart" "eyelash_sofle_studio_left-nice_view"
        ;;
    settings_reset)
        build_firmware "$BOARD_LEFT" "settings_reset" "" "eyelash_sofle_left-settings_reset"
        ;;
    all)
        build_firmware "$BOARD_RIGHT" "$SHIELD" "" "eyelash_sofle_right-nice_view"
        build_firmware "$BOARD_LEFT" "$SHIELD" "-DCONFIG_ZMK_STUDIO=y -DCONFIG_ZMK_STUDIO_LOCKING=n -DSNIPPET=studio-rpc-usb-uart" "eyelash_sofle_studio_left-nice_view"
        build_firmware "$BOARD_LEFT" "settings_reset" "" "eyelash_sofle_left-settings_reset"
        ;;
    *)
        echo "Usage: $0 [left|right|left_studio|settings_reset|all]"
        exit 1
        ;;
esac

echo ""
echo "========================================"
echo "Build complete! Firmware files in: $BUILD_DIR"
ls -la "$BUILD_DIR"/*.uf2 2>/dev/null || ls -la "$BUILD_DIR"/*.bin 2>/dev/null || echo "No firmware files found"
