#!/bin/bash

# ==============================================
# WORDPRESS ULTIMATE CACHE PURGE PRO
# ==============================================
# Fitur:
# 1. Membersihkan semua jenis cache WordPress
# 2. Support berbagai plugin cache populer
# 3. Membersihkan server-level cache (OPcache, Redis, etc)
# 4. Membersihkan CDN dan browser cache
# 5. Auto-detect konfigurasi caching
# chmod +x wp-purge-cache-pro.sh
# ./wp-purge-cache-pro.sh /path/to/wordpress
# ==============================================

# Konfigurasi
WP_PATH=${1:-'.'}  # Path WordPress (default: current dir)
SITE_URL=$(wp option get siteurl --path="$WP_PATH" 2>/dev/null | sed -e 's/^https\?:\/\///g' -e 's/\/$//g')
USER_AGENT="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"

# Fungsi utama
function purge_all_wp_cache() {
    echo "=============================================="
    echo " WORDPRESS ULTIMATE CACHE PURGE PRO"
    echo " Tanggal: $(date)"
    echo " Situs: $SITE_URL"
    echo "=============================================="
    echo ""

    # 1. WordPress Core Cache
    purge_wp_core_cache
    
    # 2. Object Cache
    purge_object_cache
    
    # 3. Plugin Cache
    purge_plugin_cache
    
    # 4. Server-Level Cache
    purge_server_cache
    
    # 5. CDN Cache
    purge_cdn_cache
    
    # 6. Browser Cache
    purge_browser_cache
    
    echo ""
    echo "=============================================="
    echo " SEMUA CACHE TELAH DIBERSIHKAN!"
    echo " Konten terbaru sekarang seharusnya terlihat."
    echo "=============================================="
}

# 1. WordPress Core Cache
function purge_wp_core_cache() {
    echo "[1] Membersihkan WordPress Core Cache..."
    
    # Transients
    wp transient delete --all --path="$WP_PATH" 2>/dev/null && echo "  ✓ Transients cleared"
    
    # Rewrite rules
    wp rewrite flush --path="$WP_PATH" 2>/dev/null && echo "  ✓ Rewrite rules flushed"
    
    # Cache direktori
    rm -rf "$WP_PATH/wp-content/cache/"* 2>/dev/null && echo "  ✓ Cache files removed"
}

# 2. Object Cache
function purge_object_cache() {
    echo "[2] Membersihkan Object Cache..."
    
    # WP Object Cache
    wp cache flush --path="$WP_PATH" 2>/dev/null && echo "  ✓ WordPress object cache flushed"
    
    # Redis
    if wp plugin is-active redis-cache --path="$WP_PATH" 2>/dev/null; then
        wp redis flush --path="$WP_PATH" 2>/dev/null && echo "  ✓ Redis cache flushed"
    fi
    
    # Memcached
    if [ -f "$WP_PATH/wp-content/object-cache.php" ]; then
        rm -f "$WP_PATH/wp-content/object-cache.php" 2>/dev/null
        echo "  ✓ Memcached disabled (object-cache.php removed)"
    fi
}

# 3. Plugin Cache
function purge_plugin_cache() {
    echo "[3] Membersihkan Plugin Cache..."
    
    # WP Rocket
    if wp plugin is-active wp-rocket --path="$WP_PATH" 2>/dev/null; then
        wp rocket clean --confirm --path="$WP_PATH" 2>/dev/null && echo "  ✓ WP Rocket cache cleared"
    fi
    
    # W3 Total Cache
    if wp plugin is-active w3-total-cache --path="$WP_PATH" 2>/dev/null; then
        wp w3-total-cache flush all --path="$WP_PATH" 2>/dev/null && echo "  ✓ W3 Total Cache cleared"
    fi
    
    # LiteSpeed Cache
    if wp plugin is-active litespeed-cache --path="$WP_PATH" 2>/dev/null; then
        wp litespeed-purge all --path="$WP_PATH" 2>/dev/null && echo "  ✓ LiteSpeed Cache cleared"
    fi
    
    # Autoptimize
    if wp plugin is-active autoptimize --path="$WP_PATH" 2>/dev/null; then
        rm -rf "$WP_PATH/wp-content/cache/autoptimize/"* 2>/dev/null && echo "  ✓ Autoptimize cache cleared"
    fi
    
    # WP Super Cache
    if wp plugin is-active wp-super-cache --path="$WP_PATH" 2>/dev/null; then
        wp super-cache flush --path="$WP_PATH" 2>/dev/null && echo "  ✓ WP Super Cache cleared"
    fi
    
    # Cloudflare
    if wp plugin is-active cloudflare --path="$WP_PATH" 2>/dev/null; then
        wp cloudflare purge_everything --path="$WP_PATH" 2>/dev/null && echo "  ✓ Cloudflare cache purged"
    fi
}

# 4. Server-Level Cache
function purge_server_cache() {
    echo "[4] Membersihkan Server-Level Cache..."
    
    # OPcache
    if [ -n "$(command -v php)" ]; then
        php -r 'if (function_exists("opcache_reset")) { opcache_reset(); echo "  ✓ OPcache reset\n"; }'
    fi
    
    # Nginx FastCGI
    if [ -n "$(command -v nginx)" ]; then
        sudo service nginx reload 2>/dev/null && echo "  ✓ Nginx cache cleared"
    fi
    
    # Apache mod_cache
    if [ -n "$(command -v apachectl)" ]; then
        sudo apachectl graceful 2>/dev/null && echo "  ✓ Apache cache cleared"
    fi
    
    # Varnish
    if [ -n "$(command -v varnishadm)" ]; then
        sudo varnishadm "ban req.url ~ /" 2>/dev/null && echo "  ✓ Varnish cache banned"
    fi
}

# 5. CDN Cache
function purge_cdn_cache() {
    echo "[5] Membersihkan CDN Cache..."
    
    # Generic CDN cache purge
    curl -s -X PURGE "$SITE_URL" -H "Host: $SITE_URL" -H "User-Agent: $USER_AGENT" 2>/dev/null && echo "  ✓ CDN cache purged"
    
    # StackPath
    curl -s -X PURGE "$SITE_URL" -H "Host: $SITE_URL" -H "User-Agent: $USER_AGENT" -H "Cache-Tag: *" 2>/dev/null
    
    # KeyCDN
    curl -s -X PURGE "$SITE_URL" -H "Host: $SITE_URL" -H "User-Agent: $USER_AGENT" -H "X-Purge-Method: wildcard" 2>/dev/null
}

# 6. Browser Cache
function purge_browser_cache() {
    echo "[6] Membersihkan Browser Cache..."
    
    # Generate new version string
    NEW_VERSION=$(date +%s)
    
    # Update WordPress version string
    wp option update asset_version "$NEW_VERSION" --path="$WP_PATH" 2>/dev/null && echo "  ✓ Asset version updated to $NEW_VERSION"
    
    # Add cache control headers
    if [ -f "$WP_PATH/.htaccess" ]; then
        sed -i '/Header set Cache-Control/d' "$WP_PATH/.htaccess" 2>/dev/null
        echo 'Header set Cache-Control "no-cache, must-revalidate"' >> "$WP_PATH/.htaccess" 2>/dev/null
    fi
}

# Eksekusi utama
if [ ! -f "$WP_PATH/wp-config.php" ]; then
    echo "Error: WordPress tidak ditemukan di path ini."
    exit 1
fi

purge_all_wp_cache