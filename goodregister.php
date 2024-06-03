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

        
        if(! array_filter($errors)){
            $username = $conn->real_escape_string($username);
            $password = $conn->real_escape_string($password);
            //CHECK CORRECT USERNAME PASSWORD
          
        // Retrieve user's hashed password based on username (assuming a column named 'password')
        $query1 = "SELECT password FROM user WHERE username = '$username'";
        $result = $conn->query($query1);

        if ($result->num_rows === 1) {
            $user = $result->fetch_assoc();
            $stored_hashed_password = $user['password'];

            // Verify password using password_verify
            if (password_verify($password, $stored_hashed_password)) {
                $_SESSION['username'] = $username;
                header('Location: user.php'); // Replace with your desired redirect after successful login
            } else {
                $errors['authenticate'] = 'Invalid username or password';
            }
        } else {
            $errors['authenticate'] = 'Invalid username or password';
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
    <h3 class="heading">Registration Successful! You can now log in to your account</h3>
  <label>
    <p class="label-txt">ENTER YOUR USERNAME</p>
    <input type="text" class="input" name="username" value="<?php echo htmlspecialchars($username) ?>">
    <div class="line-box">
      <div class="line"></div>
    </div>
    <p class= "bg-danger text-white"><?php echo htmlspecialchars($errors['username'])?></p>
  </label>
  <label>
    <p class="label-txt">ENTER YOUR PASSWORD</p>
    <input type="password" class="input" name="password" value="<?php echo htmlspecialchars($password) ?>">
    <div class="line-box">
      <div class="line"></div>
    </div>
    <p class= "bg-danger text-white"><?php echo htmlspecialchars($errors['password'])?></p>
  </label>
  <p class= "bg-danger text-white"><?php echo htmlspecialchars($errors['authenticate'])?></p>
  <button type="submit" name="signin" value="submit">Sign-In</button>
  <a href="register.php" class="register">Not A Member? Register</a>
</form>
</div>

</html>