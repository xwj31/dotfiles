#!/usr/bin/env fish
# Tests for gc.fish commit message generation

# Source the function
source (dirname (status filename))/../functions/gc.fish

# Test counters
set -g tests_passed 0
set -g tests_failed 0

# Assertion helper
function assert_eq -a expected actual test_name
    if test "$expected" = "$actual"
        set tests_passed (math $tests_passed + 1)
        set_color green
        echo "✓ $test_name"
        set_color normal
    else
        set tests_failed (math $tests_failed + 1)
        set_color red
        echo "✗ $test_name"
        echo "  Expected: '$expected'"
        echo "  Actual:   '$actual'"
        set_color normal
    end
end

function assert_not_eq -a unexpected actual test_name
    if test "$unexpected" != "$actual"
        set tests_passed (math $tests_passed + 1)
        set_color green
        echo "✓ $test_name"
        set_color normal
    else
        set tests_failed (math $tests_failed + 1)
        set_color red
        echo "✗ $test_name"
        echo "  Should NOT be: '$unexpected'"
        echo "  Actual:        '$actual'"
        set_color normal
    end
end

# Test: Scope extraction
function test_scope_extraction
    echo ""
    set_color --bold
    echo "=== Scope Extraction Tests ==="
    set_color normal

    # Test 1: Single file
    set -l result (_gc_extract_scopes "src/api/client.ts")
    assert_eq "api" "$result" "Single file: src/api/client.ts → scope 'api'"

    # Test 2: Multiple files same area
    set -l result (_gc_extract_scopes "src/routes/feed.ts" "src/routes/users.ts")
    assert_eq "routes" "$result" "Same area: routes/feed.ts, routes/users.ts → scope 'routes'"

    # Test 3: Multiple files different areas
    set -l result (_gc_extract_scopes "src/pages/Settings.tsx" "workers/feed.ts")
    assert_eq "pages,workers" "$result" "Different areas → scope 'pages,workers'"

    # Test 4: More than 2 areas (should limit to 2)
    set -l result (_gc_extract_scopes "src/pages/Home.tsx" "src/api/client.ts" "workers/feed.ts")
    assert_eq "pages,api" "$result" "3+ areas → first two scopes"

    # Test 5: Files in types folder (should not skip types as scope)
    set -l result (_gc_extract_scopes "src/types/index.ts" "src/api/client.ts")
    assert_eq "types,api" "$result" "types folder should be a valid scope"

    # Test 6: Workers nested path
    set -l result (_gc_extract_scopes "workers/reddit-api-worker/src/routes/feed.ts")
    assert_eq "workers" "$result" "Nested workers path → scope 'workers'"

    # Test 7: Many files across 4 areas (should limit to first 2)
    set -l result (_gc_extract_scopes "src/hooks/useReadPosts.ts" "src/utils/readPosts.ts" "src/components/Feed.tsx" "src/pages/Home.tsx")
    assert_eq "hooks,utils" "$result" "4 areas → first two 'hooks,utils'"
end

# Test: Description generation
function test_description_generation
    echo ""
    set_color --bold
    echo "=== Description Generation Tests ==="
    set_color normal

    # Test 1: Single file
    set -l result (_gc_generate_description "src/api/client.ts")
    assert_eq "client" "$result" "Single file: client.ts → desc 'client'"

    # Test 2: Two files
    set -l result (_gc_generate_description "src/routes/feed.ts" "src/routes/users.ts")
    assert_eq "feed and users" "$result" "Two files → 'feed and users'"

    # Test 3: Multiple files different areas
    set -l result (_gc_generate_description "src/pages/Settings.tsx" "workers/api/feed.ts")
    assert_eq "settings and feed" "$result" "Different areas → both names"

    # Test 4: Files with generic names (index, types, utils)
    set -l result (_gc_generate_description "src/types/index.ts" "src/utils/index.ts")
    # Should fall back to scope-based since all names are generic
    # This depends on scope context, so we test it doesn't return empty
    assert_not_eq "" "$result" "Generic names should still produce description"

    # Test 5: Mix of generic and specific
    set -l result (_gc_generate_description "src/pages/Settings.tsx" "src/types/index.ts")
    assert_eq "settings" "$result" "Mix: Settings.tsx + index.ts → 'settings'"

    # Test 6: Test file naming
    set -l result (_gc_generate_description "src/api/client.test.ts")
    assert_eq "client" "$result" "Test file: client.test.ts → 'client'"
end

# Test: Type detection
function test_type_detection
    echo ""
    set_color --bold
    echo "=== Type Detection Tests ==="
    set_color normal

    # Test 1: Code with "// comment" should NOT trigger docs
    set -l result (_gc_detect_type "modified" "" "// this is a comment\nconst x = 1")
    assert_not_eq "docs" "$result" "Code comments should NOT trigger 'docs' type"

    # Test 2: Fix keywords in diff
    set -l result (_gc_detect_type "modified" "" "fix bug in handler")
    assert_eq "fix" "$result" "Diff with 'fix bug' → type 'fix'"

    # Test 3: New file
    set -l result (_gc_detect_type "added" "src/components/Button.tsx" "")
    assert_eq "feat" "$result" "New component file → type 'feat'"

    # Test 4: New test file
    set -l result (_gc_detect_type "added" "src/api/client.test.ts" "")
    assert_eq "test" "$result" "New test file → type 'test'"

    # Test 5: Only deletions
    set -l result (_gc_detect_type "deleted" "" "")
    assert_eq "chore" "$result" "Only deletions → type 'chore'"

    # Test 6: README file
    set -l result (_gc_detect_type "modified" "README.md" "")
    assert_eq "docs" "$result" "README.md → type 'docs'"

    # Test 7: Mixed new + modify → feat
    set -l result (_gc_detect_type "mixed" "hooks/use.ts components/button.tsx" "")
    assert_eq "feat" "$result" "Mixed new+modify → type 'feat'"

    # Test 8: Mixed new + modify with fix in diff → fix
    set -l result (_gc_detect_type "mixed" "hooks/use.ts" "fix the bug")
    assert_eq "fix" "$result" "Mixed with fix in diff → type 'fix'"
end

# Run all tests
function run_tests
    set_color --bold cyan
    echo "Running gc.fish tests..."
    echo ""
    set_color normal

    test_scope_extraction
    test_description_generation
    test_type_detection

    echo ""
    set_color --bold
    echo "=== Results ==="
    set_color normal
    set_color green
    echo "Passed: $tests_passed"
    set_color red
    echo "Failed: $tests_failed"
    set_color normal

    if test $tests_failed -gt 0
        return 1
    end
    return 0
end

# Run if executed directly
if test (basename (status filename)) = "test_gc.fish"
    run_tests
end
