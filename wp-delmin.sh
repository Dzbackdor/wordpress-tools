#!/bin/bash

# WordPress Admin Removal Tool
# Usage:
# Hapus admin dengan transfer konten:
#   ./wp-del-admin.sh --path=/path/to/wordpress --username=oldadmin --transfer-to=existingadmin
# Hapus admin tanpa transfer konten:
#   ./wp-del-admin.sh --path=/path/to/wordpress --username=oldadmin
# Lihat daftar admin:
#   ./wp-del-admin.sh --path=/path/to/wordpress --show-users

# Fungsi untuk menampilkan bantuan
show_help() {
    echo "WordPress Admin Removal Tool"
    echo "Usage:"
    echo "  Hapus admin dengan transfer konten:"
    echo "    $0 --path=/path/to/wordpress --username=oldadmin --transfer-to=existingadmin"
    echo "  Hapus admin tanpa transfer konten:"
    echo "    $0 --path=/path/to/wordpress --username=oldadmin"
    echo "  Lihat daftar admin:"
    echo "    $0 --path=/path/to/wordpress --show-users"
    echo ""
    echo "Options:"
    echo "  --path=PATH       Path ke instalasi WordPress"
    echo "  --username=USER   Username admin yang akan dihapus"
    echo "  --transfer-to=USER Username admin tujuan untuk transfer konten"
    echo "  --show-users      Tampilkan daftar admin"
    echo "  --help            Tampilkan bantuan ini"
    exit 0
}

# Parse arguments
WP_PATH=""
TARGET_USER=""
TRANSFER_TO=""
SHOW_USERS=false

for arg in "$@"; do
    case $arg in
        --path=*)
            WP_PATH="${arg#*=}"
            ;;
        --username=*)
            TARGET_USER="${arg#*=}"
            ;;
        --transfer-to=*)
            TRANSFER_TO="${arg#*=}"
            ;;
        --show-users)
            SHOW_USERS=true
            ;;
        --help)
            show_help
            ;;
        *)
            echo "Error: Argument tidak dikenali - $arg"
            show_help
            exit 1
            ;;
    esac
done

WP_CONFIG="${WP_PATH}/wp-config.php"

# Ekstrak konfigurasi database dari wp-config.php
DB_NAME=$(grep -oP "define\(\s*'DB_NAME'\s*,\s*'\K[^']+(?=')" "$WP_CONFIG")
DB_USER=$(grep -oP "define\(\s*'DB_USER'\s*,\s*'\K[^']+(?=')" "$WP_CONFIG")
DB_PASS=$(grep -oP "define\(\s*'DB_PASSWORD'\s*,\s*'\K[^']+(?=')" "$WP_CONFIG")
# Fix the table prefix extraction regex
DB_PREFIX=$(grep -oP "\$table_prefix\s*=\s*'\K[^']+(?=')" "$WP_CONFIG")

# Fungsi untuk mendapatkan user ID dari username
get_user_id() {
    local username=$1
    mysql -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" -sN -e "
    SELECT ID FROM ${DB_PREFIX}users WHERE user_login = '$username';"
}

# Fungsi untuk menampilkan daftar admin
show_admin_users() {
    echo "Daftar Admin WordPress:"
    mysql -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" -e "
    SELECT u.ID, u.user_login, u.user_email, u.user_registered
    FROM ${DB_PREFIX}users u
    JOIN ${DB_PREFIX}usermeta m ON u.ID = m.user_id
    WHERE m.meta_key = '${DB_PREFIX}capabilities'
    AND m.meta_value LIKE '%administrator%'
    ORDER BY u.user_registered;"
}

# Fungsi untuk menghapus admin
delete_admin() {
    local admin_id=$1
    local target_id=$2
    
    # Jika ada target admin, pindahkan konten
    if [ -n "$target_id" ]; then
        echo "Memindahkan konten dari admin ID $admin_id ke admin ID $target_id..."
        mysql -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" -e "
        UPDATE ${DB_PREFIX}posts SET post_author = $target_id WHERE post_author = $admin_id;
        UPDATE ${DB_PREFIX}comments SET user_id = $target_id WHERE user_id = $admin_id;"
    fi
    
    # Hapus admin
    echo "Menghapus admin ID $admin_id..."
    mysql -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" -e "
    DELETE FROM ${DB_PREFIX}usermeta WHERE user_id = $admin_id;
    DELETE FROM ${DB_PREFIX}users WHERE ID = $admin_id;"
    
    echo "Operasi selesai. Admin dengan ID $admin_id telah dihapus."
}

# Main logic
if [ "$SHOW_USERS" = true ]; then
    show_admin_users
    exit 0
fi

# Dapatkan ID user target
TARGET_ID=$(get_user_id "$TARGET_USER")

# Jika ada transfer, dapatkan ID user tujuan
TRANSFER_ID=""
if [ -n "$TRANSFER_TO" ]; then
    TRANSFER_ID=$(get_user_id "$TRANSFER_TO")
fi

# Tampilkan konfirmasi
echo "Konfigurasi WordPress:"
echo "Path: $WP_PATH"
echo "Database: $DB_NAME"
echo "User Database: $DB_USER"
echo "Table Prefix: $DB_PREFIX"
echo "----------------------------------------"
echo "Aksi yang akan dilakukan:"
echo "Hapus admin: $TARGET_USER (ID: $TARGET_ID)"

if [ -n "$TRANSFER_TO" ]; then
    echo "Transfer konten ke: $TRANSFER_TO (ID: $TRANSFER_ID)"
else
    echo "Tidak ada transfer konten"
fi

read -p "Lanjutkan? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Operasi dibatalkan."
    exit 0
fi

# Eksekusi penghapusan
delete_admin "$TARGET_ID" "$TRANSFER_ID"
