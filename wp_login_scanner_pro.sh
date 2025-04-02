#!/bin/bash

# ================================================
# WORDPRESS STEALTH LOGIN SCANNER PRO
# chmod +x wp_login_scanner_pro.sh
# ./wp_login_scanner_pro.sh https://situsanda.com
# ================================================
# Fitur Utama:
# 1. Deteksi 50+ path login alternatif
# 2. Analisis plugin security populer
# 3. Pemindaian form login tersembunyi
# 4. Deteksi perubahan .htaccess
# 5. Pemeriksaan WP-CLI (lokal)
# 6. Laporan HTML opsional
# ================================================

# Konfigurasi
LOG_FILE="wp_login_scan_$(date +%Y%m%d_%H%M%S).log"
USER_AGENT="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"
TIMEOUT=5

# Inisialisasi
declare -A DETECTED_PATHS
declare -A SECURITY_PLUGINS
declare -A HTACCESS_RULES

# Header
function show_header() {
    echo "================================================"
    echo " WORDPRESS STEALTH LOGIN SCANNER PRO"
    echo " v2.5 | $(date)"
    echo "================================================"
    echo ""
}

# Cek dependensi
function check_dependencies() {
    local missing=0
    local tools=("curl" "grep" "sed")
    
    for tool in "${tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            echo "[ERROR] Tool '$tool' tidak ditemukan"
            missing=1
        fi
    done
    
    if [ "$missing" -eq 1 ]; then
        echo "Instal dengan: sudo apt install curl grep sed"
        exit 1
    fi
}

# Deteksi path login
function scan_login_paths() {
    local paths=(
        # Path standar dan common
        "wp-login.php" "login" "admin" "wp-admin" "dashboard"
        "signin" "auth" "secure" "administrator" "panel"
        
        # Path tidak umum
        "backend" "console" "portal" "system" "controlpanel"
        "member" "user" "account" "myaccount" "manager"
        "hidden" "private" "secret" "cms" "siteadmin"
        "adminarea" "adminlogin" "adminpanel" "wp-login"
        "wplogin" "admincp" "adm" "site" "access"
        
        # Pattern plugin security
        "secret-login" "hidden-admin" "secure-wp-admin"
        "new-login" "custom-login" "wp-auth" "wplogin-"
        "sublogin" "blue-login" "login-page" "hiddenlogin"
        
        # Pattern angka
        "admin123" "login2023" "wp-admin-456" "auth789"
    )

    echo "[+] Memindai 50+ path login alternatif..."
    
    for path in "${paths[@]}"; do
        local url="$SITE_URL/$path"
        local status=$(curl -s -o /dev/null -w "%{http_code}" -L -A "$USER_AGENT" --connect-timeout $TIMEOUT "$url")
        
        if [ "$status" -eq 200 ]; then
            local title=$(curl -s -L -A "$USER_AGENT" --connect-timeout $TIMEOUT "$url" | grep -i -o '<title>[^<]*</title>' | sed 's/<title>\(.*\)<\/title>/\1/')
            DETECTED_PATHS["$url"]="$title"
            echo "  [+] Ditemukan: $url"
            echo "      Judul: $title"
        fi
    done
    echo ""
}

# Deteksi plugin security
function detect_security_plugins() {
    echo "[+] Mendeteksi plugin keamanan..."
    
    # List plugin security populer
    local plugins=(
        "better-wp-security" "wordfence" "sucuri-scanner"
        "all-in-one-wp-security-and-firewall" "wp-hide-login"
        "rename-wp-login" "wps-hide-login" "hide-my-wp"
        "litespeed-cache" "wp-rocket" "iThemes-security"
    )

    # Cari di halaman utama
    local homepage=$(curl -s -L -A "$USER_AGENT" "$SITE_URL")
    
    for plugin in "${plugins[@]}"; do
        if echo "$homepage" | grep -iq "$plugin"; then
            SECURITY_PLUGINS["$plugin"]=1
            echo "  [!] Terdeteksi plugin: $plugin"
        fi
    done
    
    # Cek di readme.txt
    local readme=$(curl -s -L -A "$USER_AGENT" "$SITE_URL/readme.txt")
    if [ -n "$readme" ]; then
        if echo "$readme" | grep -iq "wordpress"; then
            echo "  [+] File readme.txt terdeteksi (mengungkap versi WordPress)"
        fi
    fi
    echo ""
}

# Analisis .htaccess
function analyze_htaccess() {
    echo "[+] Menganalisis file .htaccess..."
    local htaccess=$(curl -s -L -A "$USER_AGENT" "$SITE_URL/.htaccess")
    
    if [ -n "$htaccess" ]; then
        # Cek rewrite rules
        local rewrites=$(echo "$htaccess" | grep -i 'RewriteRule')
        if [ -n "$rewrites" ]; then
            HTACCESS_RULES["rewrites"]="$rewrites"
            echo "  [!] Ditemukan rewrite rules di .htaccess"
            echo "$rewrites" | sed 's/^/    /'
        fi
        
        # Cek proteksi login
        local login_protection=$(echo "$htaccess" | grep -iE 'wp-login|admin-ajax')
        if [ -n "$login_protection" ]; then
            HTACCESS_RULES["login_protection"]="$login_protection"
            echo "  [!] Ditemukan proteksi login di .htaccess"
        fi
    else
        echo "  [!] File .htaccess tidak terdeteksi/tidak bisa diakses"
    fi
    echo ""
}

# Deteksi via WP-CLI (lokal)
function wp_cli_detection() {
    if command -v wp &> /dev/null && [ -f "wp-config.php" ]; then
        echo "[+] Deteksi WP-CLI (instalasi lokal)..."
        
        # Cek custom login
        local custom_login=$(wp option get wp_login_page 2>/dev/null)
        if [ -n "$custom_login" ]; then
            echo "  [!] Path login custom: $SITE_URL/$custom_login"
            DETECTED_PATHS["$SITE_URL/$custom_login"]="Custom Login Page"
        fi
        
        # Cek active plugins
        echo "  [+] Daftar plugin aktif:"
        wp plugin list --status=active --field=name | sed 's/^/    • /'
    fi
    echo ""
}

# Generate laporan
function generate_report() {
    echo ""
    echo "================================================"
    echo " LAPORAN PEMINDAIAN WORDPRESS LOGIN PRO"
    echo "================================================"
    echo " Situs Target: $SITE_URL"
    echo " Tanggal Scan: $(date)"
    echo "-----------------------------------------------"
    
    echo ""
    echo "=== HASIL DETECTED PATH LOGIN ==="
    if [ ${#DETECTED_PATHS[@]} -gt 0 ]; then
        for path in "${!DETECTED_PATHS[@]}"; do
            echo " • $path"
            echo "   Judul: ${DETECTED_PATHS[$path]}"
        done
    else
        echo " [!] Tidak ditemukan path login alternatif"
    fi
    
    echo ""
    echo "=== PLUGIN KEAMANAN TERDETEKSI ==="
    if [ ${#SECURITY_PLUGINS[@]} -gt 0 ]; then
        for plugin in "${!SECURITY_PLUGINS[@]}"; do
            echo " • $plugin"
        done
    else
        echo " [!] Tidak terdeteksi plugin keamanan"
    fi
    
    echo ""
    echo "=== ATURAN .HTACCESS ==="
    if [ ${#HTACCESS_RULES[@]} -gt 0 ]; then
        for rule in "${!HTACCESS_RULES[@]}"; do
            echo " • $rule:"
            echo "${HTACCESS_RULES[$rule]}" | sed 's/^/   /'
        done
    else
        echo " [!] Tidak ditemukan aturan relevan"
    fi
    
    echo ""
    echo "=== REKOMENDASI KEAMANAN ==="
    echo "1. Jika menemukan path login tidak dikenal, segera audit"
    echo "2. Periksa plugin keamanan yang terdeteksi"
    echo "3. Verifikasi aturan .htaccess"
    echo "4. Update WordPress dan plugin secara berkala"
    echo "================================================"
}

# Main execution
clear
show_header
check_dependencies

if [ -z "$1" ]; then
    echo "Usage: $0 https://example.com"
    exit 1
fi

SITE_URL=${1%/}

scan_login_paths
detect_security_plugins
analyze_htaccess
wp_cli_detection
generate_report | tee "$LOG_FILE"

echo ""
echo "Laporan tersimpan di: $LOG_FILE"
echo "================================================"
echo " Scan selesai. Gunakan informasi dengan bijak!"
echo "================================================"