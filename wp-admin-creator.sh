#!/bin/bash

# WordPress Auto-Admin Creator
# Usage: ./wp-admin-creator.sh --path=/path/to/wordpress [options]
# chmod +x wp-admin-creator.sh
# ./wp-admin-creator.sh --path=/home/u113203900/domains/domain.com/public_html/ --username=superadmin --email=laciescarlet@ptct.net --show-password

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

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
      echo -e "${RED}Error: Unknown option '$1'${NC}"
      exit 1
      ;;
  esac
  shift
done

# Validate WordPress path
if [ -z "$WP_PATH" ]; then
  echo -e "${RED}Error: WordPress path is required${NC}"
  echo "Usage: $0 --path=/path/to/wordpress [--username=admin] [--email=admin@example.com] [--password=pass] [--show-password]"
  exit 1
fi

if [ ! -f "$WP_PATH/wp-config.php" ]; then
  echo -e "${RED}Error: WordPress installation not found at specified path${NC}"
  exit 1
fi

# Check if WP-CLI is installed
if ! command -v wp &> /dev/null; then
  echo -e "${RED}Error: WP-CLI is not installed. Please install it first.${NC}"
  echo "Installation guide: https://wp-cli.org/#installing"
  exit 1
fi

# Create the admin user
echo -e "${YELLOW}Creating WordPress administrator...${NC}"

cd "$WP_PATH" || exit

wp user create "$USERNAME" "$EMAIL" --role="$ROLE" --user_pass="$PASSWORD"

if [ $? -eq 0 ]; then
  echo -e "${GREEN}✓ Administrator created successfully${NC}"
  echo ""
  echo "Username: $USERNAME"
  echo "Email: $EMAIL"
  
  if [ "$SHOW_PASSWORD" = "yes" ]; then
    echo "Password: $PASSWORD"
  else
    echo "Password: [hidden] (use --show-password to display)"
  fi
  
  echo ""
  echo -e "${YELLOW}Important: Change this password immediately after first login!${NC}"
else
  echo -e "${RED}✗ Failed to create administrator${NC}"
  exit 1
fi