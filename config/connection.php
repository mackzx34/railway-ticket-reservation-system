<?php
    //local devlopment

     $servername = "localhost";
     $username = "root";
     $password = "9852Ab@";
     $database = "rdb";
    
    $conn = new mysqli($servername, $username, $password, $database);
    if($conn -> connect_error){
        die("Connection failed: " . $conn -> connect_error);
    }
?>