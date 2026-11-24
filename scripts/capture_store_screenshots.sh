#!/usr/bin/env bash
# Captures the eight store screenshots per UI language from the demo-data app and writes MANIFEST.md.
# Usage: scripts/capture_store_screenshots.sh [language ...]   (default: all 16 languages, en and de first)
# See docs/store-screenshots.md. Needs UI automation enabled once on this Mac: sudo DevToolsSecurity -enable
set -euo pipefail

cd "$(dirname "$0")/.."
repo=$PWD
version=${CCM_CAPTURE_VERSION:-2.3.0}
root=${CCM_CAPTURE_ROOT:-$HOME/Developer/tmp/ccm-164-captures}
out=$root/civocloudmanager-$version
derived=${CCM_DERIVED_DATA:-$root/derived-data}
logs=$root/logs
screens=(01-dashboard 02-firewall-change 03-firewall-rules 04-resize 05-k8s-upgrade 06-reserved-ips 07-tag-filter 08-billing)
all_languages=(en de fr es it ja ko nl pl pt ru tr zh-Hans ar hi id)
languages=("$@")
[[ ${#languages[@]} -gt 0 ]] || languages=("${all_languages[@]}")
for language in "${languages[@]}"; do
    [[ " ${all_languages[*]} " == *" $language "* ]] || { echo "Unsupported language: $language" >&2; exit 2; }
done

mkdir -p "$out" "$logs"

# One heavy build at a time: wait for any other xcodebuild, never kill it. Called right before every xcodebuild.
wait_for_idle_xcodebuild() { while pgrep -x xcodebuild >/dev/null; do sleep 15; done; }

wait_for_idle_xcodebuild
if pgrep -x "Civo Cloud Manager" >/dev/null; then
    echo "Civo Cloud Manager is running; quit it first so the demo run cannot touch it." >&2
    exit 1
fi

caffeinate -d -w $$ &

wait_for_idle_xcodebuild
xcodebuild build-for-testing -project CivoCloudManager.xcodeproj -scheme CivoCloudManagerScreenshots \
    -destination 'platform=macOS' -derivedDataPath "$derived" >"$logs/build.log" 2>&1

pixel_size() { echo "$(sips -g pixelWidth "$1" | awk '/pixelWidth/ {print $2}')x$(sips -g pixelHeight "$1" | awk '/pixelHeight/ {print $2}')"; }

failed=()
for language in "${languages[@]}"; do
    rm -rf "${out:?}/$language"
    wait_for_idle_xcodebuild
    # xcodebuild forwards TEST_RUNNER_ variables to the test runner without the prefix.
    TEST_RUNNER_CCM_CAPTURE_LANG=$language TEST_RUNNER_CCM_CAPTURE_OUT=$out \
        TEST_RUNNER_CCM_STRINGS_PATH=$repo/CivoCloudManager/Localizable.xcstrings \
        xcodebuild test-without-building -project CivoCloudManager.xcodeproj -scheme CivoCloudManagerScreenshots \
        -destination 'platform=macOS' -derivedDataPath "$derived" \
        -resultBundlePath "$logs/$language-$(date +%H%M%S).xcresult" >"$logs/$language.log" 2>&1 || failed+=("$language")
done

{
    echo "# CivoCloudManager $version store captures"
    echo
    echo "- Generated: $(date '+%Y-%m-%d %H:%M %Z') from commit $(git rev-parse --short HEAD), $(xcodebuild -version | head -1)"
    echo "- Appearance: light. Data: fictional demo data only (language-neutral English fixtures in every folder)."
    echo "- Format: PNG, whole window without desktop, menu bar or cursor, window 1440 x 900 pt on a 2x display."
    echo "- Shadow: none on every file (exact window rectangle, no shadow padding)."
    echo
    echo "| Language | Files present | Missing | Pixel sizes |"
    echo "|---|---|---|---|"
    for language in "${all_languages[@]}"; do
        present=() missing=() sizes=()
        for screen in "${screens[@]}"; do
            file=$out/$language/$screen.png
            if [[ -f $file ]]; then present+=("$screen"); sizes+=("$(pixel_size "$file")"); else missing+=("$screen"); fi
        done
        [[ -d $out/$language || " ${languages[*]} " == *" $language "* ]] || continue
        echo "| $language | ${#present[@]} of ${#screens[@]} | ${missing[*]:-none} | $(printf '%s\n' "${sizes[@]:-}" | sort -u | paste -sd ' ' -) |"
    done
} >"$out/MANIFEST.md"
echo "Manifest: $out/MANIFEST.md"
if [[ ${#failed[@]} -gt 0 ]]; then
    echo "Capture failed for: ${failed[*]} (logs in $logs)" >&2
    exit 1
fi
