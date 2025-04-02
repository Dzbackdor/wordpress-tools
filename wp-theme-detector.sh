#!/bin/bash

# ==============================================
# ADVANCED WORDPRESS ENVIRONMENT DETECTOR
# ==============================================
# Fitur:
# 1. Deteksi tema induk dan child theme
# 2. Analisis komponen aktif (Elementor, WooCommerce, dll)
# 3. Pemeriksaan konfigurasi server
# 4. Deteksi plugin dan versinya
# 5. Identifikasi kerentanan umum
# 6. Teknik fingerprinting canggih
# chmod +x wp-theme-detector.sh
# ./wp-theme-detector.sh https://example.com
# ==============================================

# Konfigurasi
SITE_URL=${1%/}
USER_AGENT="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"
TIMEOUT=10
MAX_REDIRECTS=3

# Fungsi untuk ekstrak versi dari string
extract_version() {
    echo "$1" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -n1
}

# Header
echo "=============================================="
echo " ADVANCED WORDPRESS ENVIRONMENT DETECTOR"
echo " Scan dimulai: $(date)"
echo " Target: $SITE_URL"
echo "=============================================="
echo ""

# 1. DETECT WORDPRESS CORE
echo "[1] WORDPRESS CORE DETECTION"
echo "----------------------------"
WP_README=$(curl -s -L -A "$USER_AGENT" --connect-timeout $TIMEOUT --max-redirs $MAX_REDIRECTS "$SITE_URL/readme.txt")
if [[ "$WP_README" == *"WordPress"* ]]; then
    WP_VERSION=$(extract_version "$(echo "$WP_README" | grep -i 'version')")
    echo "[+] WordPress Version: ${WP_VERSION:-Unknown}"
else
    # Fallback: Check generator meta tag
    WP_HOME=$(curl -s -L -A "$USER_AGENT" --connect-timeout $TIMEOUT --max-redirs $MAX_REDIRECTS "$SITE_URL")
    WP_VERSION=$(echo "$WP_HOME" | grep -i 'generator' | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
    echo "[+] WordPress Version (from meta): ${WP_VERSION:-Unknown}"
fi

# 2. THEME DETECTION (MULTI-METHOD)
echo ""
echo "[2] THEME ANALYSIS"
echo "------------------"

# Method 1: style.css detection
CSS_PATHS=(
    "/wp-content/themes/[^/]+/style.css"
    "/wp-content/themes/[^/]+/assets/css/style.css"
    "/wp-content/themes/[^/]+/css/main.css"
)

for path in "${CSS_PATHS[@]}"; do
    THEME_CSS=$(curl -s -L -A "$USER_AGENT" --connect-timeout $TIMEOUT --max-redirs $MAX_REDIRECTS "$SITE_URL" | grep -oE "$path" | head -n1)
    if [ -n "$THEME_CSS" ]; then
        THEME_URL="$SITE_URL$THEME_CSS"
        CSS_CONTENT=$(curl -s -L -A "$USER_AGENT" --connect-timeout $TIMEOUT "$THEME_URL")
        
        THEME_NAME=$(echo "$CSS_CONTENT" | grep -i 'Theme Name:' | cut -d':' -f2- | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        THEME_VER=$(extract_version "$(echo "$CSS_CONTENT" | grep -i 'Version:')")
        PARENT_THEME=$(echo "$CSS_CONTENT" | grep -i 'Template:' | cut -d':' -f2- | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        
        if [ -n "$THEME_NAME" ]; then
            echo "[+] Theme Found: $THEME_NAME"
            echo "    |- Version: ${THEME_VER:-Unknown}"
            echo "    |- Path: $(dirname "$THEME_CSS")"
            
            if [ -n "$PARENT_THEME" ]; then
                echo "    |- Parent Theme: $PARENT_THEME"
                # Check parent theme files
                PARENT_CSS="$SITE_URL/wp-content/themes/$PARENT_THEME/style.css"
                PARENT_INFO=$(curl -s -L -A "$USER_AGENT" --head --connect-timeout $TIMEOUT "$PARENT_CSS" | head -n1)
                if [[ "$PARENT_INFO" == *"200"* ]]; then
                    PARENT_CONTENT=$(curl -s -L -A "$USER_AGENT" --connect-timeout $TIMEOUT "$PARENT_CSS")
                    PARENT_VER=$(extract_version "$(echo "$PARENT_CONTENT" | grep -i 'Version:')")
                    echo "    |- Parent Version: ${PARENT_VER:-Unknown}"
                fi
            fi
            break
        fi
    fi
done

# Method 2: wp-json API
WP_JSON=$(curl -s -L -A "$USER_AGENT" --connect-timeout $TIMEOUT --max-redirs $MAX_REDIRECTS "$SITE_URL/wp-json/wp/v2/themes?status=active")
if [[ "$WP_JSON" == *"stylesheet"* ]]; then
    THEME_SLUG=$(echo "$WP_JSON" | grep -o '"stylesheet":"[^"]*"' | cut -d'"' -f4)
    THEME_NAME=$(echo "$WP_JSON" | grep -o '"name":"[^"]*"' | cut -d'"' -f4)
    
    if [ -n "$THEME_SLUG" ] && [ -z "$THEME_NAME" ]; then
        echo "[+] Theme Slug: $THEME_SLUG"
        # Try to get more info from theme files
        THEME_HEADER=$(curl -s -L -A "$USER_AGENT" --head --connect-timeout $TIMEOUT "$SITE_URL/wp-content/themes/$THEME_SLUG/style.css")
        if [[ "$THEME_HEADER" == *"200"* ]]; then
            THEME_CONTENT=$(curl -s -L -A "$USER_AGENT" --connect-timeout $TIMEOUT "$SITE_URL/wp-content/themes/$THEME_SLUG/style.css")
            THEME_NAME=$(echo "$THEME_CONTENT" | grep -i 'Theme Name:' | cut -d':' -f2- | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
            echo "[+] Theme Name: $THEME_NAME"
        fi
    fi
fi

# 3. PLUGIN DETECTION
echo ""
echo "[3] PLUGIN ANALYSIS"
echo "-------------------"

# Method 1: Check common plugin files
PLUGINS_LIST=()
PLUGIN_PATHS=($(curl -s -L -A "$USER_AGENT" --connect-timeout $TIMEOUT --max-redirs $MAX_REDIRECTS "$SITE_URL/wp-content/plugins/" | grep -oE 'href="[^"]+"' | cut -d'"' -f2 | grep -vE '\.\.|index'))

for plugin_path in "${PLUGIN_PATHS[@]}"; do
    plugin_name=$(basename "$plugin_path")
    PLUGINS_LIST+=("$plugin_name")
done

# Method 2: Check source code for plugin traces
COMMON_PLUGINS=(
    "elementor" "woocommerce" "yoast" "akismet" "contact-form-7" 
    "jetpack" "wordfence" "all-in-one-seo-pack" "wp-rocket"
)

for plugin in "${COMMON_PLUGINS[@]}"; do
    if curl -s -L -A "$USER_AGENT" --connect-timeout $TIMEOUT --max-redirs $MAX_REDIRECTS "$SITE_URL" | grep -iq "$plugin"; then
        PLUGINS_LIST+=("$plugin")
    fi
done

# Display unique plugins
if [ ${#PLUGINS_LIST[@]} -gt 0 ]; then
    echo "[+] Detected Plugins:"
    printf '    |- %s\n' "${PLUGINS_LIST[@]}" | sort -u
else
    echo "[!] No plugins detected"
fi

# 4. SERVER CONFIGURATION
echo ""
echo "[4] SERVER ANALYSIS"
echo "-------------------"

# Get server headers
SERVER_HEADERS=$(curl -I -s -L -A "$USER_AGENT" --connect-timeout $TIMEOUT --max-redirs $MAX_REDIRECTS "$SITE_URL" | grep -iE 'server|x-powered-by')

echo "[+] Server Info:"
echo "$SERVER_HEADERS" | sed 's/^/    |- /'

# Check .htaccess
HTACCESS=$(curl -s -L -A "$USER_AGENT" --connect-timeout $TIMEOUT --max-redirs $MAX_REDIRECTS "$SITE_URL/.htaccess")
if [ -n "$HTACCESS" ]; then
    echo "[+] .htaccess detected"
    # Check for security headers
    if [[ "$HTACCESS" == *"Header set X-Frame-Options"* ]]; then
        echo "    |- Security Headers: X-Frame-Options found"
    fi
fi

# 5. SECURITY CHECKS
echo ""
echo "[5] BASIC SECURITY CHECKS"
echo "-------------------------"

# Check common files
COMMON_FILES=(
    "/wp-config.php" "/wp-admin/admin-ajax.php" 
    "/xmlrpc.php" "/wp-login.php"
)

for file in "${COMMON_FILES[@]}"; do
    status=$(curl -o /dev/null -s -w "%{http_code}" -L -A "$USER_AGENT" --connect-timeout $TIMEOUT --max-redirs $MAX_REDIRECTS "$SITE_URL$file")
    if [ "$status" -eq 200 ]; then
        echo "[!] Publicly accessible: $file"
    fi
done

# Check directory listing
DIR_LISTING=$(curl -I -s -L -A "$USER_AGENT" --connect-timeout $TIMEOUT --max-redirs $MAX_REDIRECTS "$SITE_URL/wp-content/uploads/")
if [[ "$DIR_LISTING" == *"Index of"* ]]; then
    echo "[!] Directory listing enabled: /wp-content/uploads/"
fi

echo ""
echo "=============================================="
echo " SCAN COMPLETED"
echo "=============================================="