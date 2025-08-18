#!/bin/bash

# Kubernetes script to check /mnt/s3express folder existence and size
# in pods with label app: s3express-app

set -e

echo "=== S3Express Folder Check Script ==="
echo "Checking pods with label: app=s3express-app"
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

# Check each pod
POD_COUNT=0
for pod in $PODS; do
    POD_COUNT=$((POD_COUNT + 1))
    echo "🔍 Checking pod $POD_COUNT: $pod"
    
    # Check if pod is running
    POD_STATUS=$(kubectl get pod $pod -n s3onezone -o jsonpath='{.status.phase}')
    
    if [ "$POD_STATUS" != "Running" ]; then
        echo "   ⚠️  Pod is not running (status: $POD_STATUS)"
        echo ""
        continue
    fi
    
    # Check if /mnt/s3express folder exists with timing
    echo "   📁 Checking if /mnt/s3express folder exists..."
    START_TIME=$(date +%s.%N)
    if kubectl exec $pod -n s3onezone -- test -d /mnt/s3express; then
        END_TIME=$(date +%s.%N)
        FOLDER_CHECK_TIME=$(echo "$END_TIME - $START_TIME" | bc -l 2>/dev/null || echo "0")
        echo "   ✅ Folder /mnt/s3express exists (took ${FOLDER_CHECK_TIME}s)"
        
        # Get folder size with timing
        echo "   📊 Getting folder size..."
        START_TIME=$(date +%s.%N)
        FOLDER_SIZE=$(kubectl exec $pod -n s3onezone -- du -sh /mnt/s3express 2>/dev/null | cut -f1)
        END_TIME=$(date +%s.%N)
        SIZE_TIME=$(echo "$END_TIME - $START_TIME" | bc -l 2>/dev/null || echo "0")
        
        if [ -n "$FOLDER_SIZE" ]; then
            echo "   📈 Folder size: $FOLDER_SIZE (took ${SIZE_TIME}s)"
        else
            echo "   ⚠️  Could not determine folder size (took ${SIZE_TIME}s)"
        fi
        
        # Count files and measure time
        echo "   📄 Counting files in folder..."
        START_TIME=$(date +%s.%N)
        FILE_COUNT=$(kubectl exec $pod -n s3onezone -- find /mnt/s3express -type f 2>/dev/null | wc -l)
        END_TIME=$(date +%s.%N)
        COUNT_TIME=$(echo "$END_TIME - $START_TIME" | bc -l 2>/dev/null || echo "0")
        
        echo "   📊 Total files: $FILE_COUNT (took ${COUNT_TIME}s)"
        
        # Check if files exist (quick check)
        echo "   🔍 Quick file existence check..."
        START_TIME=$(date +%s.%N)
        FILE_EXISTS=$(kubectl exec $pod -n s3onezone -- test -e /mnt/s3express/* && echo "true" || echo "false" 2>/dev/null)
        END_TIME=$(date +%s.%N)
        EXIST_TIME=$(echo "$END_TIME - $START_TIME" | bc -l 2>/dev/null || echo "0")
        
        if [ "$FILE_EXISTS" = "true" ]; then
            echo "   ✅ Files exist in folder (took ${EXIST_TIME}s)"
        fi
        
    else
        echo "   ❌ Folder /mnt/s3express does not exist"
    fi
    
    echo ""
done

# End overall timing
SCRIPT_END_TIME=$(date +%s.%N)
TOTAL_TIME=$(echo "$SCRIPT_END_TIME - $SCRIPT_START_TIME" | bc -l 2>/dev/null || echo "0")

echo "=== Check Complete ==="

# Summary
echo ""
echo "📊 Summary:"
echo "Total pods checked: $(echo $PODS | wc -w | tr -d ' ')"
echo "Running pods: $(kubectl get pods -n s3onezone -l app=s3express-app --field-selector=status.phase=Running -o jsonpath='{.items[*].metadata.name}' | wc -w | tr -d ' ')"
echo "⏱️  Total script execution time: ${TOTAL_TIME}s"
