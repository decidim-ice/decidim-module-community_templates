#!/bin/bash
set -e

# Environment variables for Chrome and ChromeDriver versions
export CHROME_VERSION=${CHROME_VERSION:-136}
export CHROME_DRIVER_VERSION=${CHROME_DRIVER_VERSION:-136.0.7103.92}
export CHROME_VERSION_FULL=${CHROME_VERSION_FULL:-136.0.7103.92}

cd /home/decidim 
# Prepare rails app with module
git config --global --add safe.directory /home/module 
bundle config unset frozen 
bundle config unset deployment 
bundle config set without ''

# Fix catalog ownership if catalog exists
if [ -d /home/module/spec/decidim_dummy_app/public/catalog ]; then
    git config --global --add safe.directory /home/module/spec/decidim_dummy_app/public/catalog
fi
if [ -d /home/decidim/public/catalog ]; then
    git config --global --add safe.directory /home/decidim/public/catalog
fi

# unless the module is already installed
bundle install 
if ! bundle list | grep -q decidim-community_templates; then
    bundle add decidim-community_templates --path /home/module 
fi
# install deps if not present
if ! bundle list | grep -q deface; then
    bundle add deface --git https://github.com/froger/deface --branch fix/js-overrides
fi
bundle exec rails decidim:update
bundle exec rails db:migrate


# Exit if chrome and imagemagick are already installed
if dpkg -l | grep -q google-chrome-stable && dpkg -l | grep -q imagemagick && command -v chromedriver >/dev/null 2>&1; then
    echo "Chrome, ImageMagick and ChromeDriver are already installed"
    echo "Sleeping forever... run a docker exec "
    sleep infinity
    exit 0
fi

# Prepare Capybara

echo "Installing Chrome, ChromeDriver and ImageMagick for Capybara testing..."


handle_error() {
    echo "Error occurred at line $1"
    echo "Last command failed. Exiting."
    exit 1
}
trap 'handle_error $LINENO' ERR

# Update package list
echo "Updating package list..."
apt update || { echo "Failed to update packages"; exit 1; }

# Install dependencies
echo "Installing dependencies..."
apt install -y wget gnupg ca-certificates imagemagick unzip || { echo "Failed to install dependencies"; exit 1; }

# Add Google Chrome repository
echo "Adding Google Chrome repository..."
wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor -o /usr/share/keyrings/google-chrome-keyring.gpg || { echo "Failed to download GPG key"; exit 1; }

echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome-keyring.gpg] http://dl.google.com/linux/chrome/deb/ stable main" | tee /etc/apt/sources.list.d/google-chrome.list || { echo "Failed to add repository"; exit 1; }

# Update package list again
echo "Updating package list with new repository..."
apt update || { echo "Failed to update packages after adding repository"; exit 1; }

# Install Chrome
echo "Installing Chrome version $CHROME_VERSION_FULL..."
if apt install -y google-chrome-stable=$CHROME_VERSION_FULL; then
    echo "Successfully installed Chrome $CHROME_VERSION_FULL"
    apt-mark hold google-chrome-stable
else
    echo "Specific version not available, installing latest..."
    apt install -y google-chrome-stable
    # Update ChromeDriver to match the installed Chrome version
    INSTALLED_CHROME_VERSION=$(google-chrome --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+')
    echo "Detected Chrome version: $INSTALLED_CHROME_VERSION"
    echo "Updating ChromeDriver to match Chrome version..."
    
    # Download ChromeDriver for the installed Chrome version
    CHROME_DRIVER_URL="https://storage.googleapis.com/chrome-for-testing-public/$INSTALLED_CHROME_VERSION/linux64/chromedriver-linux64.zip"
    echo "Downloading ChromeDriver from: $CHROME_DRIVER_URL"
    
    wget -O /tmp/chromedriver.zip "$CHROME_DRIVER_URL" || { echo "Failed to download ChromeDriver for version $INSTALLED_CHROME_VERSION"; exit 1; }
    unzip -o /tmp/chromedriver.zip -d /tmp/ || { echo "Failed to extract ChromeDriver"; exit 1; }
    mv /tmp/chromedriver-linux64/chromedriver /usr/local/bin/ || { echo "Failed to move ChromeDriver"; exit 1; }
    chmod +x /usr/local/bin/chromedriver || { echo "Failed to make ChromeDriver executable"; exit 1; }
    rm -rf /tmp/chromedriver.zip /tmp/chromedriver-linux64 || { echo "Failed to clean up ChromeDriver files"; exit 1; }
fi

# Verify installations
echo "Verifying installations..."
google-chrome --version || { echo "Chrome verification failed"; exit 1; }
convert -version || { echo "ImageMagick verification failed"; exit 1; }
chromedriver --version || { echo "ChromeDriver verification failed"; exit 1; }

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

echo "Chrome, ChromeDriver and ImageMagick installation complete!"
echo ""
echo "Chrome version:"
google-chrome --version
echo ""
echo "ChromeDriver version:"
chromedriver --version
echo ""
echo "ImageMagick version:"
convert -version | head -1
echo ""
echo "Environment variables:"
echo "CHROME_VERSION=$CHROME_VERSION"
echo "CHROME_DRIVER_VERSION=$CHROME_DRIVER_VERSION"
echo "CHROME_VERSION_FULL=$CHROME_VERSION_FULL"
echo ""
echo "To use Chrome with Capybara, set these environment variables:"
echo "export CHROME_BIN=/usr/bin/google-chrome"
echo "export CHROME_FLAGS=\"\$(cat ~/.chrome-capybara-flags)\""

echo "Sleeping forever... run a docker exec "
sleep infinity
