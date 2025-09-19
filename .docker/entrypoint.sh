#!/bin/bash
set -e

cd /home/decidim 
# Prepare rails app with module
git config --global --add safe.directory /home/module 
bundle config unset frozen 
bundle config unset deployment 
bundle config set without ''
# unless the module is already installed
if ! bundle list | grep -q decidim-community_templates; then
    bundle add decidim-community_templates --path /home/module 
fi
bundle install 

# Exit if chrome and imagemagick are already installed
if dpkg -l | grep -q google-chrome-stable && dpkg -l | grep -q imagemagick; then
    echo "Chrome and ImageMagick are already installed"
    echo "Sleeping forever... run a docker exec "
    sleep infinity
    exit 0
fi

# Prepare Capybara

echo "Installing Chrome and ImageMagick for Capybara testing..."


handle_error() {
    echo "Error occurred at line $1"
    echo "Last command failed. Exiting."
    exit 1
}
trap 'handle_error $LINENO' ERR

# Update package list
echo "Updating package list..."
apt update || { echo "Failed to update packages"; exit 1; }

# unless the dependencies are already installed
echo "Installing dependencies..."
    apt install -y wget gnupg ca-certificates imagemagick || { echo "Failed to install dependencies"; exit 1; }

# Add Google Chrome repository
echo "Adding Google Chrome repository..."
wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor -o /usr/share/keyrings/google-chrome-keyring.gpg || { echo "Failed to download GPG key"; exit 1; }

echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome-keyring.gpg] http://dl.google.com/linux/chrome/deb/ stable main" | tee /etc/apt/sources.list.d/google-chrome.list || { echo "Failed to add repository"; exit 1; }

# Update package list again
echo "Updating package list with new repository..."
apt update || { echo "Failed to update packages after adding repository"; exit 1; }

# Check available Chrome versions
echo "Available Chrome versions:"
apt list -a google-chrome-stable

# Try to install specific version first, fallback to latest
echo "Attempting to install Chrome version 136.0.7103.92..."
if apt install -y google-chrome-stable=136.0.7103.92; then
    echo "Successfully installed Chrome 136.0.7103.92"
    apt-mark hold google-chrome-stable
else
    echo "Specific version not available, installing latest..."
    apt install -y google-chrome-stable
fi

# Verify installations
echo "Verifying installations..."
google-chrome --version || { echo "Chrome verification failed"; exit 1; }
convert -version || { echo "ImageMagick verification failed"; exit 1; }

# Prepare Chrome for headless testing
echo "Preparing Chrome for Capybara testing..."

# Create Chrome user data directory for testing
mkdir -p ~/.chrome-test-profile

# Set up Chrome flags for Capybara
cat > ~/.chrome-capybara-flags << 'EOF'
--no-sandbox
--disable-dev-shm-usage
--disable-gpu
--disable-web-security
--disable-features=VizDisplayCompositor
--remote-debugging-port=9222
--disable-background-timer-throttling
--disable-backgrounding-occluded-windows
--disable-renderer-backgrounding
--disable-extensions
--disable-plugins
--disable-default-apps
--disable-sync
--disable-translate
--hide-scrollbars
--mute-audio
--no-first-run
--no-default-browser-check
--disable-logging
--disable-permissions-api
--disable-popup-blocking
--disable-prompt-on-repost
--disable-hang-monitor
--disable-client-side-phishing-detection
--disable-component-update
--disable-domain-reliability
--disable-features=TranslateUI
--disable-ipc-flooding-protection
EOF

echo "Chrome and ImageMagick installation complete!"
echo ""
echo "Chrome version:"
google-chrome --version
echo ""
echo "ImageMagick version:"
convert -version | head -1
echo ""
echo "To use Chrome with Capybara, set these environment variables:"
echo "export CHROME_BIN=/usr/bin/google-chrome"
echo "export CHROME_FLAGS=\"\$(cat ~/.chrome-capybara-flags)\""

echo "Sleeping forever... run a docker exec "
sleep infinity
