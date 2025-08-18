#!/bin/bash

# Kubernetes script to check S3Express transfer speeds
# in pods with label app: s3express-app

set -e

# Only show read test results:
# - Save original stdout on FD 3
# - Redirect normal stdout to /dev/null
exec 3>&1
exec >/dev/null

echo "=== S3Express Transfer Speed Test ==="
echo "Testing pods with label: app=s3express-app"
echo ""

# Start overall timing
SCRIPT_START_TIME=$(date +%s.%N)

# Get all pods with the specified label in namespace s3onezone
PODS=$(kubectl get pods -n s3onezone -l app=s3express-app -o jsonpath='{.items[*].metadata.name}')

if [ -z "$PODS" ]; then
    echo "❌ No pods found with label 'app=s3express-app' in namespace 's3onezone'"
    exit 1
fi

echo "Found pods: $PODS"
echo ""

# Test file sizes (in GB) for read tests only
TEST_SIZES_GB=(1 10 30)
S3EXPRESS_MOUNT="/mnt/s3express"

# Check each pod
POD_COUNT=0
for pod in $PODS; do
    POD_COUNT=$((POD_COUNT + 1))
    echo "🔍 Testing pod $POD_COUNT: $pod"
    
    # Check if pod is running
    POD_STATUS=$(kubectl get pod $pod -n s3onezone -o jsonpath='{.status.phase}')
    
    if [ "$POD_STATUS" != "Running" ]; then
        echo "   ⚠️  Pod is not running (status: $POD_STATUS)"
        echo ""
        continue
    fi
    
    # Check if /mnt/s3express folder exists
    echo "   📁 Checking if $S3EXPRESS_MOUNT folder exists..."
    START_TIME=$(date +%s.%N)
    if kubectl exec $pod -n s3onezone -- test -d $S3EXPRESS_MOUNT; then
        END_TIME=$(date +%s.%N)
        FOLDER_CHECK_TIME=$(echo "$END_TIME - $START_TIME" | bc -l 2>/dev/null || echo "0")
        echo "   ✅ Folder $S3EXPRESS_MOUNT exists (took ${FOLDER_CHECK_TIME}s)"
        
        echo ""
        echo "   🚀 Starting read speed tests (1 GB, 10 GB, 30 GB)..."
        echo ""

        # Read tests only, expecting files to already exist in mount
        for size_gb in "${TEST_SIZES_GB[@]}"; do
            file_path="$S3EXPRESS_MOUNT/read_test_${size_gb}GB.dat"
            count_mb=$((size_gb * 1024))

            echo "   📖 Read test (${size_gb} GB)..."

            # Verify file exists before attempting to read
            if kubectl exec $pod -n s3onezone -- test -f "$file_path"; then
                START_TIME=$(date +%s.%N)
                kubectl exec $pod -n s3onezone -- dd if="$file_path" of=/dev/null bs=1M count=$count_mb 2>/dev/null
                END_TIME=$(date +%s.%N)
                READ_TIME=$(echo "$END_TIME - $START_TIME" | bc -l 2>/dev/null || echo "0")
                if [ "$READ_TIME" != "0" ]; then
                    READ_SPEED=$(echo "scale=2; $count_mb / $READ_TIME" | bc -l 2>/dev/null || echo "0")
                    echo >&3 "Read ${size_gb} GB: ${READ_SPEED} MB/s (${READ_TIME}s)"
                else
                    echo >&3 "Read ${size_gb} GB: FAILED"
                fi
            else
                echo >&3 "Read ${size_gb} GB: FILE NOT FOUND at $file_path"
            fi

            echo ""
        done
        
    else
        echo "   ❌ Folder $S3EXPRESS_MOUNT does not exist"
    fi
    
    echo ""
    echo "   =========================================="
    echo ""
done

# End overall timing
SCRIPT_END_TIME=$(date +%s.%N)
TOTAL_TIME=$(echo "$SCRIPT_END_TIME - $SCRIPT_START_TIME" | bc -l 2>/dev/null || echo "0")

echo "=== Speed Test Complete ==="

# Summary
echo ""
echo "📊 Summary:"
echo "Total pods tested: $(echo $PODS | wc -w | tr -d ' ')"
echo "Running pods: $(kubectl get pods -n s3onezone -l app=s3express-app --field-selector=status.phase=Running -o jsonpath='{.items[*].metadata.name}' | wc -w | tr -d ' ')"
echo "Read test file sizes: ${TEST_SIZES_GB[*]} GB"
echo "⏱️  Total script execution time: ${TOTAL_TIME}s"
