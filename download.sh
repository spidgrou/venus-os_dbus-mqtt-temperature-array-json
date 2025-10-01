#!/bin/bash
# Smart downloader script for the venus-os_dbus-mqtt-temperature-array-json project

# Stop on any error
set -e

echo "--- Starting Smart Downloader ---"

# Prerequisites check
echo "Checking for required tools (curl, jq, unzip)..."
opkg update > /dev/null
opkg install curl jq unzip > /dev/null

# GitHub API URL for your repository's latest release
API_URL="https://api.github.com/repos/spidgrou/venus-os_dbus-mqtt-temperature-array-json/releases/latest"

echo "Fetching latest release information from GitHub..."

# Use curl to get the data, and jq to parse the zipball_url
DOWNLOAD_URL=$(curl -s "$API_URL" | jq -r '.zipball_url')

if [ -z "$DOWNLOAD_URL" ] || [ "$DOWNLOAD_URL" == "null" ]; then
    echo "ERROR: Could not find the latest release URL. Please check the repository has a published release."
    exit 1
fi

echo "Latest release found. Downloading from: $DOWNLOAD_URL"

# Define destination paths
INSTALL_DIR="/data/etc/dbus-mqtt-temperature"
TMP_ZIP_FILE="/tmp/release.zip"

# Download the zip file of the latest release
wget -O "$TMP_ZIP_FILE" "$DOWNLOAD_URL"

echo "Download complete. Extracting files..."

# Ensure the target directory is clean before installing
if [ -d "$INSTALL_DIR" ]; then
    echo "Removing previous installation..."
    # Attempt to run uninstaller if it exists
    [ -f "$INSTALL_DIR/uninstall.sh" ] && bash "$INSTALL_DIR/uninstall.sh"
    rm -rf "$INSTALL_DIR"
fi

# Unzip to a temporary location
TMP_EXTRACT_DIR="/tmp/dbus-mqtt-extract"
rm -rf "$TMP_EXTRACT_DIR"
unzip -q "$TMP_ZIP_FILE" -d "$TMP_EXTRACT_DIR"

# The unzipped folder has an unpredictable name, so we find it
# It's the only directory inside the extraction folder
EXTRACTED_FOLDER_NAME=$(ls "$TMP_EXTRACT_DIR")

# Move the contents to the final installation directory
mv "$TMP_EXTRACT_DIR/$EXTRACTED_FOLDER_NAME" "$INSTALL_DIR"

echo "Files installed to $INSTALL_DIR"

# Clean up temporary files
rm "$TMP_ZIP_FILE"
rm -rf "$TMP_EXTRACT_DIR"

echo "--- Smart Downloader finished successfully! ---"
echo "Next steps: Edit config.ini and run install.sh"
echo "cd $INSTALL_DIR"
