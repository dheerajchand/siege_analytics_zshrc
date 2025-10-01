#!/usr/bin/env zsh

echo "=== MINIMAL VARIABLE ASSIGNMENT TEST ==="

echo "Test 1: Simple assignment"
test_var=''
echo "test_var: '$test_var'"

echo ""
echo "Test 2: Command substitution that fails"
test_var2=$(false && echo "should not appear" || true)
echo "test_var2: '$test_var2'"

echo ""
echo "Test 3: Command substitution with nonexistent command"
test_var3=$(nonexistentcommand 2>/dev/null || true)
echo "test_var3: '$test_var3'"

echo ""
echo "Test 4: Security command that fails"
test_var4=$(security find-generic-password -s "nonexistent" -a "user" -w 2>/dev/null || true)
echo "test_var4: '$test_var4'"

echo ""
echo "Done."