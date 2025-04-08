#!/bin/bash
# WordPress Admin Remover (Standalone)
# Usage: ./wp-del-admin.sh --path=/path/to/wordpress --username=admin-to-delete [options]

# chmod +x wp-del-admin.sh
# Contoh 1: Hapus admin dengan transfer konten
# ./wp-del-admin.sh --path=/var/www/html --username=oldadmin --transfer-to=existingadmin

# Contoh 2: Hapus admin tanpa transfer konten
# ./wp-del-admin.sh --path=/var/www/html --username=oldadmin

# Contoh 3: Lihat daftar admin sebelum hapus
# ./wp-del-admin.sh --path=/var/www/html --show-users
export PATH="$HOME/bin:$PATH"

# Warna output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Validasi root
if [ "$(id -u)" -eq 0 ]; then
  echo -e "${RED}Jangan jalankan sebagai root! Gunakan akun normal.${NC}"
  exit 1
fi

# Default values
WP_PATH=""
ADMIN_USERNAME=""
TRANSFER_TO=""
SHOW_USERS="no"

# Parse arguments
while [ "$#" -gt 0 ]; do
  case "$1" in
    --path=*)
      WP_PATH="${1#*=}"
      ;;
    --username=*)
      ADMIN_USERNAME="${1#*=}"
      ;;
    --transfer-to=*)
      TRANSFER_TO="${1#*=}"
      ;;
    --show-users)
      SHOW_USERS="yes"
      ;;
    *)
      echo -e "${RED}Error: Unknown option '$1'${NC}"
      exit 1
      ;;
  esac
  shift
done

# Validasi path WordPress
if [ -z "$WP_PATH" ]; then
  echo -e "${RED}Error: WordPress path is required${NC}"
  echo -e "Usage: $0 --path=/path/to/wordpress --username=admin-to-delete [--transfer-to=existing-admin] [--show-users]"
  exit 1
fi

if [ ! -f "$WP_PATH/wp-config.php" ]; then
  echo -e "${RED}Error: WordPress installation not found at specified path${NC}"
  exit 1
fi

# Cek WP-CLI
if ! command -v wp &> /dev/null; then
  echo -e "${RED}Error: WP-CLI is not installed or not in PATH${NC}"
  echo -e "Install with: curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && chmod +x wp-cli.phar && sudo mv wp-cli.phar /usr/local/bin/wp"
  exit 1
fi

cd "$WP_PATH" || exit

# Tampilkan daftar admin jika diminta
if [ "$SHOW_USERS" = "yes" ]; then
  echo -e "${YELLOW}Current Administrators:${NC}"
  wp user list --role=administrator --fields=ID,user_login,user_email,user_registered --allow-root
  echo ""
fi

# Validasi username target
if [ -z "$ADMIN_USERNAME" ]; then
  echo -e "${RED}Error: Username to delete is required${NC}"
  echo -e "Usage: $0 --path=/path/to/wordpress --username=admin-to-delete"
  exit 1
fi

if ! wp user get "$ADMIN_USERNAME" --allow-root &> /dev/null; then
  echo -e "${RED}Error: User '$ADMIN_USERNAME' not found${NC}"
  exit 1
fi

# Validasi bukan last admin
ADMIN_COUNT=$(wp user list --role=administrator --format=count --allow-root)
if [ "$ADMIN_COUNT" -le 1 ]; then
  echo -e "${RED}CRITICAL: Cannot delete the last administrator!${NC}"
  echo -e "${YELLOW}Create another admin first or use --transfer-to option${NC}"
  exit 1
fi

# Konfirmasi penghapusan
echo -e "${YELLOW}⚠️ You are about to PERMANENTLY delete:${NC}"
wp user get "$ADMIN_USERNAME" --fields=user_login,user_email,roles,ID --allow-root
echo ""

read -p "Are you sure? (y/n) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo -e "${YELLOW}Deletion cancelled${NC}"
  exit 0
fi

# Transfer konten jika diperlukan
if [ -n "$TRANSFER_TO" ]; then
  if ! wp user get "$TRANSFER_TO" --allow-root &> /dev/null; then
    echo -e "${RED}Error: Transfer target user '$TRANSFER_TO' not found${NC}"
    exit 1
  fi
  
  echo -e "${YELLOW}Transferring content to $TRANSFER_TO...${NC}"
  wp post list --author="$ADMIN_USERNAME" --format=ids --allow-root | xargs -0 -d ' ' -I % wp post update % --post_author="$TRANSFER_TO" --allow-root
fi

# Eksekusi penghapusan
echo -e "${YELLOW}Deleting user '$ADMIN_USERNAME'...${NC}"
if [ -z "$TRANSFER_TO" ]; then
  wp user delete "$ADMIN_USERNAME" --yes --allow-root
else
  wp user delete "$ADMIN_USERNAME" --reassign="$TRANSFER_TO" --yes --allow-root
fi

if [ $? -eq 0 ]; then
  echo -e "${GREEN}✓ User '$ADMIN_USERNAME' successfully deleted${NC}"
else
  echo -e "${RED}✗ Failed to delete user${NC}"
  exit 1
fi

# Verifikasi akhir
echo -e "\n${YELLOW}Remaining Administrators:${NC}"
wp user list --role=administrator --fields=user_login,user_email --allow-root