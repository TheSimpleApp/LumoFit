#!/bin/bash

# Setup App Store Connect API environment variables

echo "Setting up App Store Connect API environment variables..."

# Add to .zshrc
cat >> ~/.zshrc << 'EOF'

# App Store Connect API Keys (added by setup script)
export APP_STORE_CONNECT_API_KEY_KEY_ID="A2V8W6A9R6"
export APP_STORE_CONNECT_API_KEY_ISSUER_ID="de08df77-e326-4658-9551-6564df7daa7a"
export APP_STORE_CONNECT_API_KEY_KEY=$(cat "/Users/daviddotson/Library/Group Containers/group.com.apple.notes/Accounts/6FB87648-DEAF-4B92-96EC-565C2E98021D/Media/A1CC8AB5-6202-4CBF-8132-F6E985B177BF/1_D45811B4-07EF-4ECE-9997-D590C2FC9E4E/AuthKey_A2V8W6A9R6.p8" | base64)
EOF

echo ""
echo "✅ Environment variables added to ~/.zshrc"
echo ""
echo "Configuration:"
echo "  Key ID: A2V8W6A9R6"
echo "  Issuer ID: de08df77-e326-4658-9551-6564df7daa7a"
echo "  Private Key: Loaded from .p8 file"
echo ""
echo "To activate in current shell, run:"
echo "  source ~/.zshrc"
echo ""
echo "To verify, run:"
echo "  echo \$APP_STORE_CONNECT_API_KEY_KEY_ID"
echo "  echo \$APP_STORE_CONNECT_API_KEY_ISSUER_ID"

