<?php
/**
 * Script untuk membuat admin WordPress
 * 
 * Cara penggunaan:
 * 1. Simpan file ini di root directory WordPress (satu folder dengan wp-config.php)
 * 2. Akses file ini melalui browser atau jalankan via command line
 */

// Fungsi untuk menghasilkan password acak yang kuat
function generateStrongPassword($length = 16) {
    $sets = [];
    $sets[] = 'abcdefghjkmnpqrstuvwxyz'; // huruf kecil tanpa huruf yang mudah keliru
    $sets[] = 'ABCDEFGHJKMNPQRSTUVWXYZ'; // huruf besar tanpa huruf yang mudah keliru
    $sets[] = '23456789'; // angka tanpa 0 dan 1 yang mudah keliru
    $sets[] = '!@#$%^&*()_+-=[]{}|;:,.<>?'; // karakter khusus

    $password = '';
    
    // Pastikan minimal satu karakter dari setiap set
    foreach ($sets as $set) {
        $password .= $set[random_int(0, strlen($set) - 1)];
    }
    
    // Isi sisa password dengan karakter acak dari semua set
    $allChars = implode('', $sets);
    for ($i = strlen($password); $i < $length; $i++) {
        $password .= $allChars[random_int(0, strlen($allChars) - 1)];
    }
    
    // Acak lagi urutan karakter untuk meningkatkan keacakan
    $password = str_shuffle($password);
    
    return $password;
}

// Pastikan script diakses dengan cara yang valid
if (php_sapi_name() !== 'cli' && !isset($_SERVER['HTTP_HOST'])) {
    die('Script ini harus diakses melalui browser atau command line.');
}

// Cek apakah WordPress sudah terinstall
if (!file_exists('wp-load.php')) {
    die('Error: File wp-load.php tidak ditemukan. Pastikan script ini berada di root directory WordPress.');
}

// Load WordPress environment
require_once('wp-load.php');
require_once(ABSPATH . 'wp-includes/pluggable.php');

// Konfigurasi admin baru
$username = 'superadmin'; // Ganti dengan username yang diinginkan
$password = generateStrongPassword(); // Password acak yang kuat
$email = 'admin@example.com'; // Ganti dengan email yang valid

// Cek jika user sudah ada
if (username_exists($username)) {
    die("Error: Username '$username' sudah terdaftar.");
}

if (email_exists($email)) {
    die("Error: Email '$email' sudah terdaftar.");
}

// Buat user baru
$user_id = wp_create_user($username, $password, $email);

if (is_wp_error($user_id)) {
    die("Error saat membuat user: " . $user_id->get_error_message());
}

// Set role user sebagai administrator
$user = new WP_User($user_id);
$user->set_role('administrator');

// Output hasil
echo "<h2>Admin WordPress berhasil dibuat!</h2>";
echo "<div style='background:#f5f5f5; padding:20px; border-radius:5px; font-family:monospace;'>";
echo "<strong>Detail Login:</strong><br>";
echo "URL Login: " . esc_url(wp_login_url()) . "<br>";
echo "Username: <strong>" . esc_html($username) . "</strong><br>";
echo "Password: <strong>" . esc_html($password) . "</strong><br>";
echo "Email: " . esc_html($email) . "<br>";
echo "</div>";


// Jika diakses via browser, tampilkan style yang lebih baik
if (!empty($_SERVER['HTTP_HOST'])) {
    echo "<style>
        body {
            font-family: Arial, sans-serif;
            line-height: 1.6;
            margin: 20px;
            color: #333;
        }
        h2 {
            color: #2271b1;
        }
    </style>";
}
?>