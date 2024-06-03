<?php
session_start();
include "config/connection.php";

// Redirect if user is already logged in
if(isset($_SESSION['username'])){
    if($_SESSION['username'] == 'admin1' || $_SESSION['username'] == 'admin'){
        header('Location: admin-page.php');
    } else {
        header('Location: user.php');
    }
    exit(); // Ensure script termination after redirection
}

$errors = array('username' => '', 'password' => '', 'authenticate' => '');
$username = $password = '';

if(isset($_POST['signin'])){
    // Validate input
    $username = trim($_POST['username']);
    $password = trim($_POST['password']);

    if(empty($username)){
        $errors['username'] = 'Username is required';
    }
    if(empty($password)){
        $errors['password'] = 'Password is required';
    }

    if(!array_filter($errors)){
        // Hash password
        $hashed_password = md5($password);

        // Prepare and execute query
        $stmt = $conn->prepare("SELECT * FROM user WHERE username = ? AND password = ?");
        $stmt->bind_param("ss", $username, $hashed_password);
        if ($stmt->execute()) {
            $result = $stmt->get_result();
            if ($result->num_rows > 0) {
                $_SESSION['username'] = $username;
                header('Location: admin-page.php');
                exit(); // Ensure script termination after redirection
            } else {
                $errors['authenticate'] = 'Incorrect username or password';
            }
        } else {
            $errors['authenticate'] = 'Error executing query: ' . $stmt->error;
        }

        // Close statement
        $stmt->close();
    }
    // Close connection
    $conn->close();
}
?>

<!DOCTYPE html>
<html lang="en">
<head>
    <title>Admin Login</title>
</head>
<?php include "template/header.php" ?>

<div style="margin-top:100px;">
<form action="admin-login.php" method="POST">
    <h3 class="heading">Welcome Admin</h3>
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
</form>
</div>

</html>
