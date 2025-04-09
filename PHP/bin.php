#!/usr/bin/env php
<?php
/**
 * WordPress Admin Manager (Check & Delete)
 * 
 * Usage: 
 * - List admins: php wp-admin-tool.php --path=/path/to/wp --list
 * - Delete admin: php wp-admin-tool.php --path=/path/to/wp --delete=username [--transfer-to=username]
 */

// Basic setup
error_reporting(E_ALL);
ini_set('display_errors', 1);

if (php_sapi_name() !== 'cli') {
    die("This script must be run from command line\n");
}

// Parse arguments
$options = getopt('', ['path:', 'list', 'delete:', 'transfer-to:']);
$wp_path = $options['path'] ?? '';
$list_mode = isset($options['list']);
$delete_user = $options['delete'] ?? '';
$transfer_to = $options['transfer-to'] ?? '';

// Validate path
if (empty($wp_path) {
    die("Error: WordPress path is required (--path=)\n");
}

if (!file_exists("$wp_path/wp-config.php")) {
    die("Error: Invalid WordPress path\n");
}

// Load WordPress
require_once "$wp_path/wp-load.php";

// Function to list all admins
function list_admins() {
    $admins = get_users(['role' => 'administrator', 'orderby' => 'user_login']);
    
    echo "ID\tUsername\tEmail\n";
    echo "--------------------------------\n";
    foreach ($admins as $admin) {
        echo "{$admin->ID}\t{$admin->user_login}\t{$admin->user_email}\n";
    }
}

// List mode
if ($list_mode) {
    list_admins();
    exit;
}

// Delete mode
if (!empty($delete_user)) {
    $user = get_user_by('login', $delete_user);
    if (!$user) {
        die("Error: User '$delete_user' not found\n");
    }

    // Show user info
    echo "User to delete:\n";
    echo "ID: {$user->ID}\n";
    echo "Username: {$user->user_login}\n";
    echo "Email: {$user->user_email}\n";
    echo "Registered: {$user->user_registered}\n\n";

    // Transfer content if specified
    if (!empty($transfer_to)) {
        $new_admin = get_user_by('login', $transfer_to);
        if (!$new_admin) {
            die("Error: Transfer user '$transfer_to' not found\n");
        }

        echo "Transferring content to $transfer_to...\n";
        
        $post_types = get_post_types(['public' => true], 'names');
        foreach ($post_types as $type) {
            $posts = get_posts([
                'post_type' => $type,
                'author' => $user->ID,
                'numberposts' => -1,
                'fields' => 'ids'
            ]);
            
            foreach ($posts as $post_id) {
                wp_update_post([
                    'ID' => $post_id,
                    'post_author' => $new_admin->ID
                ]);
            }
            echo "Transferred " . count($posts) . " $type posts\n";
        }
    }

    // Delete user
    $result = !empty($transfer_to) 
        ? wp_delete_user($user->ID, $new_admin->ID) 
        : wp_delete_user($user->ID);

    echo $result ? "User deleted successfully\n" : "Failed to delete user\n";
    exit;
}

// No valid command
echo "Usage:\n";
echo "List admins: php wp-admin-tool.php --path=/path/to/wp --list\n";
echo "Delete admin: php wp-admin-tool.php --path=/path/to/wp --delete=username [--transfer-to=username]\n";
