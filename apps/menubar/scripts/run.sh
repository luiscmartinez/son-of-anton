#!/usr/bin/env bash
# Build and launch Codogotchi with floating-pet perf logging enabled.
# Console filter: FloatingPetPerf
set -euo pipefail

export CODOGOTCHI_FLOATING_PERF_DEBUG=1

ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
PROJECT="${ROOT}/apps/menubar/Codogotchi.xcodeproj"
SCHEME="Codogotchi"
CONFIG="Debug"

echo "Building ${SCHEME} (Debug)…"
xcodebuild \
	-project "${PROJECT}" \
	-scheme "${SCHEME}" \
	-configuration "${CONFIG}" \
	CODE_SIGNING_ALLOWED=NO \
	build \
	| tail -3

BUILT_PRODUCTS_DIR="$(
	xcodebuild \
		-project "${PROJECT}" \
		-scheme "${SCHEME}" \
		-configuration "${CONFIG}" \
		-showBuildSettings 2>/dev/null \
	| sed -n 's/^[[:space:]]*BUILT_PRODUCTS_DIR = //p' \
	| head -1
)"

APP="${BUILT_PRODUCTS_DIR}/Codogotchi.app"
BINARY="${APP}/Contents/MacOS/Codogotchi"

if [[ ! -x "${BINARY}" ]]; then
	echo "error: ${BINARY} not found — build may have failed" >&2
	exit 1
fi

echo "Launching ${APP} with CODOGOTCHI_FLOATING_PERF_DEBUG=1"
echo "Open Console.app and filter for: FloatingPetPerf"
exec env CODOGOTCHI_FLOATING_PERF_DEBUG=1 "${BINARY}"
