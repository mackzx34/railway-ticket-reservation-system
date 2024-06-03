<?php
session_start();
include "config/connection.php";

if(isset($_SESSION['username'])){
    if($_SESSION['username'] == 'admin1' || $_SESSION['username'] == 'admin'){
        header('Location: admin-page.php');
    }
    else{
        header('Location: user.php');
    }
}

$errors = array('username' => '', 'password' => '', 'authenticate' => '');
$username = $password = '';

if(isset($_POST['signin'])){
    $username = $_POST['username'];
    $password = $_POST['password'];

    if(empty($username)){
        $errors['username'] = 'Username is required';
    }
    if(empty($password)){
        $errors['password'] = 'Password is required';
    }

    if(!array_filter($errors)){
        $username = $conn->real_escape_string($username);
        $password = md5($conn->real_escape_string($password));
        
        // For debugging purposes, let's use a direct query
        $query = "SELECT * FROM user WHERE username = '$username' AND password = '$password'";
        $result = $conn->query($query);

        if ($result) {
            if ($result->num_rows > 0) {
                $_SESSION['username'] = $username;
                header('Location: user.php');
            } else {
                $errors['authenticate'] = 'Incorrect username or password';
            }
            $result->free();
        } else {
            $errors['authenticate'] = 'Error executing query: ' . $conn->error;
        }

        $conn->close();
    }
}
?>
<!DOCTYPE html>
<html lang="en">
<?php include "template/header.php" ?>
<div style="margin-top:100px;">
<form action="index.php" method="POST">
    <h3 class="heading">Welcome to eRail</h3>
    <label>
        <p class="label-txt">ENTER YOUR USERNAME</p>
        <input type="text" class="input" name="username" value="<?php echo htmlspecialchars($username) ?>">
        <div class="line-box">
            <div class="line"></div>
        </div>
        <p class="bg-danger text-white"><?php echo htmlspecialchars($errors['username'])?></p>
    </label>
    <label>
        <p class="label-txt">ENTER YOUR PASSWORD</p>
        <input type="password" class="input" name="password" value="<?php echo htmlspecialchars($password) ?>">
        <div class="line-box">
            <div class="line"></div>
        </div>
        <p class="bg-danger text-white"><?php echo htmlspecialchars($errors['password'])?></p>
    </label>
    <p class="bg-danger text-white"><?php echo htmlspecialchars($errors['authenticate'])?></p>
    <button type="submit" name="signin" value="submit">Sign-In</button>
    <a href="register.php" class="register">Not A Member? Register</a>
</form>
</div>
</html>
