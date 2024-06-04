<?php
    include "include/connection.inc.php";
    Logout();
    session_destroy();
    header("Location:index.php");
?>