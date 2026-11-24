#!/bin/bash
# push-to-github.sh
# Run this after creating a GitHub repository at https://github.com/new
# Repository name: universallite-os

set -euo pipefail

REPO_URL="${1:-}"

if [[ -z "$REPO_URL" ]]; then
    echo "Usage: $0 <github-repo-url>"
    echo ""
    echo "Example:"
    echo "  $0 https://github.com/YOUR_USERNAME/universallite-os.git"
    echo "  $0 git@github.com:YOUR_USERNAME/universallite-os.git"
    echo ""
    echo "First, create the repository at: https://github.com/new"
    echo "Repository name: universallite-os"
    echo "Description: UniversalLite OS - Super-fast, lightweight OS with Windows & Android app support"
    echo "Visibility: Public (or Private)"
    echo "DO NOT initialize with README, .gitignore, or license"
    exit 1
fi

echo "=== Pushing UniversalLite OS to GitHub ==="
echo "Repository: $REPO_URL"

# Add remote
git remote add origin "$REPO_URL" 2>/dev/null || git remote set-url origin "$REPO_URL"

# Rename branch to main (GitHub default)
git branch -M main

# Push
echo "Pushing to GitHub..."
git push -u origin main

echo ""
echo "=== Push Complete ==="
echo "Repository: $REPO_URL"
echo ""
echo "Next steps:"
echo "1. Go to GitHub Actions tab to see builds"
echo "2. Create a tag to trigger release: git tag v1.0.0-dev && git push origin v1.0.0-dev"
echo "3. Check Actions for build artifacts"
echo "4. Download ISOs from workflow artifacts or releases"