#!/usr/bin/env zsh

test_function() {
    local service="$1"
    local user="$2"

    echo "In function, service=$service, user=$user" >&2

    local secret_value
    echo "After declaring secret_value" >&2

    secret_value=$(security find-generic-password -s "nonexistent" -a "user" -w 2>/dev/null || true)
    echo "After assignment, secret_value='$secret_value'" >&2

    return 1
}

echo "Calling test function..."
test_function "test" "user" 2>&1