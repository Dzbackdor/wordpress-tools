#!/bin/bash

# WordPress Auto-Admin Creator
# Usage: ./wp-admin-creator.sh --path=/path/to/wordpress [options]

# Pastikan PATH sudah include ~/bin
export PATH="$HOME/bin:$PATH"

# Default values
WP_PATH=""
USERNAME="admin_$(date +%s | sha256sum | base64 | head -c 8)"
EMAIL="admin_${USERNAME}@example.com"
PASSWORD=$(openssl rand -base64 16)
ROLE="administrator"
SHOW_PASSWORD="no"

# Parse arguments
while [ "$#" -gt 0 ]; do
  case "$1" in
    --path=*)
      WP_PATH="${1#*=}"
      ;;
    --username=*)
      USERNAME="${1#*=}"
      ;;
    --email=*)
      EMAIL="${1#*=}"
      ;;
    --password=*)
      PASSWORD="${1#*=}"
      ;;
    --show-password)
      SHOW_PASSWORD="yes"
      ;;
    *)
      echo "Error: Unknown option '$1'"
      exit 1
      ;;
  esac
  shift
done

# Validate WordPress path
if [ -z "$WP_PATH" ]; then
  echo "Error: WordPress path is required"
  echo "Usage: $0 --path=/path/to/wordpress [--username=admin] [--email=admin@example.com] [--password=pass] [--show-password]"
  exit 1
fi

if [ ! -f "$WP_PATH/wp-config.php" ]; then
  echo "Error: WordPress installation not found at specified path"
  exit 1
fi

# Check if WP-CLI is installed
if ! command -v wp &> /dev/null; then
  echo "Error: WP-CLI is not found in PATH"
  echo "Trying alternative locations..."
  
  # Cek di lokasi alternatif
  if [ -f "$HOME/bin/wp" ]; then
    WP_CMD="$HOME/bin/wp"
  elif [ -f "/usr/local/bin/wp" ]; then
    WP_CMD="/usr/local/bin/wp"
  else
    echo "WP-CLI is not installed. Please install it first."
    echo "Installation guide: https://wp-cli.org/#installing"
    exit 1
  fi
else
  WP_CMD="wp"
fi

# Create the admin user
echo "Creating WordPress administrator..."

cd "$WP_PATH" || exit

$WP_CMD user create "$USERNAME" "$EMAIL" --role="$ROLE" --user_pass="$PASSWORD"

if [ $? -eq 0 ]; then
  echo "✓ Administrator created successfully"
  echo ""
  echo "Username: $USERNAME"
  echo "Email: $EMAIL"
  
  if [ "$SHOW_PASSWORD" = "yes" ]; then
    echo "Password: $PASSWORD"
  else
    echo "Password: [hidden] (use --show-password to display)"
  fi
  
  echo ""
  echo "Important: Change this password immediately after first login!"
else
  echo "✗ Failed to create administrator"
  exit 1
fi