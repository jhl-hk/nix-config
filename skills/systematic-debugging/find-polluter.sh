#!/usr/bin/env bash
# Runs test files one by one to find which test creates unwanted files/state.
# Run from the project root.
# Usage: ./find-polluter.sh <file_or_dir_to_check> <test_pattern>
# Example: ./find-polluter.sh '.git' 'src/**/*.test.ts'
# TEST_CMD sets the command each test file is passed to (default: bun test).
# Example: TEST_CMD='bunx vitest run' ./find-polluter.sh '.git' 'src/**/*.test.ts'

set -e

if [ $# -ne 2 ]; then
  echo "Usage: $0 <file_to_check> <test_pattern>"
  echo "Example: $0 '.git' 'src/**/*.test.ts'"
  echo "Set TEST_CMD to change the test command (default: bun test)."
  exit 1
fi

POLLUTION_CHECK="$1"
TEST_PATTERN="$2"
TEST_CMD="${TEST_CMD:-bun test}"

echo "🔍 Searching for test that creates: $POLLUTION_CHECK"
echo "Test pattern: $TEST_PATTERN"
echo "Test command: $TEST_CMD"
echo ""

# Every test would be skipped and the run would end "all clean", so refuse.
if [ -e "$POLLUTION_CHECK" ]; then
  echo "❌ Pollution already exists before any test runs: $POLLUTION_CHECK"
  echo "   Remove it, then re-run."
  exit 2
fi

# Get list of test files (find . emits ./-prefixed paths, so accept the
# pattern written with or without a leading ./; bun test also needs the ./
# prefix to treat an argument as a path rather than a name filter)
TEST_PATTERN="${TEST_PATTERN#./}"
# find -path can't match '**/' against zero directory levels, so a pattern
# like src/**/*.test.ts would skip src/top.test.ts; also try the pattern
# with '**/' collapsed to cover files directly under the base directory.
TEST_FILES=()
while IFS= read -r FILE; do
  TEST_FILES+=("$FILE")
done < <(find . \( -path "./$TEST_PATTERN" -o -path "./${TEST_PATTERN//\*\*\//}" \) | sort -u)
TOTAL=${#TEST_FILES[@]}

echo "Found $TOTAL test files"
echo ""

COUNT=0
for TEST_FILE in "${TEST_FILES[@]}"; do
  COUNT=$((COUNT + 1))

  echo "[$COUNT/$TOTAL] Testing: $TEST_FILE"

  # Run the test; TEST_CMD is split into words on purpose
  # shellcheck disable=SC2086
  $TEST_CMD "$TEST_FILE" > /dev/null 2>&1 || true

  # Check if pollution appeared
  if [ -e "$POLLUTION_CHECK" ]; then
    echo ""
    echo "🎯 FOUND POLLUTER!"
    echo "   Test: $TEST_FILE"
    echo "   Created: $POLLUTION_CHECK"
    echo ""
    echo "Pollution details:"
    ls -la "$POLLUTION_CHECK"
    echo ""
    echo "To investigate:"
    echo "  $TEST_CMD '$TEST_FILE'    # Run just this test"
    echo "  cat '$TEST_FILE'          # Review test code"
    exit 1
  fi
done

echo ""
echo "✅ No polluter found - all tests clean!"
exit 0
