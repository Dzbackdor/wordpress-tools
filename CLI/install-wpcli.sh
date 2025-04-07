#!/bin/bash

# WP-CLI Installer for Non-Root Users
# Version: 1.1 (no colors, fixed completion)
# chmod +x install-wpcli.sh
# ./install-wpcli.sh
# Fungsi untuk mengecek dependency
check_dependencies() {
    echo "🔍 Checking dependencies..."
    
    # Cek curl
    if ! command -v curl &> /dev/null; then
        echo "❌ Error: curl not found. Please install curl first."
        exit 1
    fi
    
    # Cek PHP
    if ! command -v php &> /dev/null; then
        echo "❌ Error: PHP CLI not found. Please install PHP CLI first."
        exit 1
    fi
    
    echo "✅ All dependencies met (curl, php)"
}

# Fungsi utama install WP-CLI
install_wpcli() {
    # Buat direktori bin jika belum ada
    mkdir -p ~/bin
    
    # Download WP-CLI
    echo "⬇️ Downloading WP-CLI..."
    curl -s -o ~/bin/wp https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
    
    # Beri permission executable
    chmod +x ~/bin/wp
    
    # Tambahkan ke PATH
    echo "🛠️ Configuring PATH..."
    if [[ ! "$PATH" == *"$HOME/bin"* ]]; then
        echo 'export PATH="$HOME/bin:$PATH"' >> ~/.bashrc
        echo "✔ Added ~/bin to PATH in .bashrc"
        
        # Untuk Zsh users
        if [ -n "$ZSH_VERSION" ]; then
            echo 'export PATH="$HOME/bin:$PATH"' >> ~/.zshrc
            echo "✔ Also added to .zshrc"
        fi
        
        # Reload shell config
        source ~/.bashrc
    else
        echo "✔ ~/bin already in PATH"
    fi
    
    # Verifikasi installasi
    echo "🔍 Verifying installation..."
    if ~/bin/wp --allow-root --version &> /dev/null; then
        echo "🎉 WP-CLI installed successfully!"
        echo "Version: $(~/bin/wp --allow-root --version)"
    else
        echo "❌ Installation failed!"
        exit 1
    fi
}

# Fungsi untuk konfigurasi auto-completion (fixed version)
setup_completion() {
    echo "⚙️ Setting up auto-completion..."
    
    # Bash completion (fixed command)
    if [ -n "$BASH_VERSION" ]; then
        ~/bin/wp cli completions --bash > ~/.wp-completion.bash 2>/dev/null || {
            echo "⚠️ Could not generate bash completion (older WP-CLI version)"
            return
        }
        echo "source ~/.wp-completion.bash" >> ~/.bashrc
        echo "✔ Bash completion installed"
    fi
    
    # Zsh completion (fixed command)
    if [ -n "$ZSH_VERSION" ]; then
        ~/bin/wp cli completions --zsh > ~/.wp-completion.zsh 2>/dev/null || {
            echo "⚠️ Could not generate zsh completion (older WP-CLI version)"
            return
        }
        echo "source ~/.wp-completion.zsh" >> ~/.zshrc
        echo "✔ Zsh completion installed"
    fi
    
    echo "ℹ️ Restart your shell to enable auto-completion"
}

# Main execution
clear
echo "🚀 WP-CLI Non-Root Installer"
echo "----------------------------------"

check_dependencies
install_wpcli
setup_completion

# Tips penggunaan
echo ""
echo "💡 Usage Tips:"
echo "1. Untuk WordPress di subdirectory:"
echo "   wp --path=/path/to/wordpress option get siteurl"
echo "2. Daftar perintah lengkap:"
echo "   wp help"
echo ""
echo "✅ Installation complete!"