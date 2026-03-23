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

# Test: Preserve filename
function test_preserve_filename
    echo ""
    set_color --bold
    echo "=== Preserve Filename Tests ==="
    set_color normal

    assert_eq "PpuUsageController" (_gc_preserve_filename "app/Http/Controllers/PpuUsageController.php") "PascalCase preserved"
    assert_eq "useReadPosts" (_gc_preserve_filename "src/hooks/useReadPosts.ts") "camelCase preserved"
    assert_eq "ppu_usage" (_gc_preserve_filename "lib/ppu_usage.rb") "snake_case preserved"
    assert_eq "PpuUsageController" (_gc_preserve_filename "tests/PpuUsageController.test.php") "Test suffix stripped, case preserved"
    assert_eq "client" (_gc_preserve_filename "src/api/client.ts") "Lowercase filename stays lowercase"
end

# Test: Detect verb
function test_detect_verb
    echo ""
    set_color --bold
    echo "=== Detect Verb Tests ==="
    set_color normal

    # Context-aware: diff keyword detection
    assert_eq "rename" (_gc_detect_verb "refactor" "rename the class to something") "rename keyword -> rename"
    assert_eq "extract" (_gc_detect_verb "refactor" "extract method from handler") "extract keyword -> extract"
    assert_eq "add" (_gc_detect_verb "chore" "add new configuration entry") "add keyword overrides type default"
    assert_eq "remove" (_gc_detect_verb "feat" "delete the old handler") "delete keyword -> remove"
    assert_eq "fix" (_gc_detect_verb "chore" "fix the broken handler") "fix keyword overrides type default"
    assert_eq "update" (_gc_detect_verb "feat" "update the component props") "update keyword overrides type default"

    # Type-based defaults (no keyword match)
    assert_eq "add" (_gc_detect_verb "feat" "plain stuff here") "feat default -> add"
    assert_eq "fix" (_gc_detect_verb "fix" "plain stuff here") "fix default -> fix"
    assert_eq "update" (_gc_detect_verb "refactor" "plain stuff here") "refactor default -> update"
    assert_eq "remove" (_gc_detect_verb "chore" "plain stuff here") "chore default -> remove"
    assert_eq "update" (_gc_detect_verb "docs" "plain stuff here") "docs default -> update"
    assert_eq "add" (_gc_detect_verb "test" "plain stuff here") "test default -> add"
    assert_eq "format" (_gc_detect_verb "style" "plain stuff here") "style default -> format"
    assert_eq "optimize" (_gc_detect_verb "perf" "plain stuff here") "perf default -> optimize"
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

    # Single file with verb, PascalCase preserved
    assert_eq "update PpuUsageController" (_gc_generate_description "update" "app/Http/Controllers/PpuUsageController.php") "Single file: verb + PascalCase name"

    # Two files with verb
    assert_eq "update PpuUsageController and PpuUsageUpload" (_gc_generate_description "update" "app/Http/Controllers/PpuUsageController.php" "app/Http/Resources/PpuUsageUpload.php") "Two files: verb + both names"

    # camelCase preserved
    assert_eq "add useReadPosts" (_gc_generate_description "add" "src/hooks/useReadPosts.ts") "camelCase preserved"

    # Generic names filtered, specific ones kept
    assert_eq "update Settings" (_gc_generate_description "update" "src/pages/Settings.tsx" "src/types/index.ts") "Generic filtered, specific kept with case"

    # Test suffix stripped
    assert_eq "add client" (_gc_generate_description "add" "src/api/client.test.ts") "Test suffix stripped"

    # 3+ files: first two names
    assert_eq "update PpuUsageController and PpuUsageUpload" (_gc_generate_description "update" "app/Http/Controllers/PpuUsageController.php" "app/Http/Resources/PpuUsageUpload.php" "app/Http/Resources/PpuAgreement.php") "3+ files: verb + first two names"

    # All generic names: scope-based fallback with verb
    assert_eq "update types updates" (_gc_generate_description "update" "src/types/index.ts" "src/utils/index.ts") "All generic: verb + scope fallback"
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

    # Test 9: Modified with no keyword match defaults to chore
    set -l result (_gc_detect_type "modified" "" "no special keywords here just plain code")
    assert_eq "chore" "$result" "Modified with no keyword match defaults to chore"
end

# Run all tests
function run_tests
    set_color --bold cyan
    echo "Running gc.fish tests..."
    echo ""
    set_color normal

    test_preserve_filename
    test_detect_verb
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
