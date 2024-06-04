<?php
    
  include "include/connection.inc.php";
  DatabaseConnect();
  $errors = array('authenticate' => '');

  if(isset($_POST['signin']) && isset ($_POST['username']) && isset ($_POST['password'])){
    // Anti-CSRF
    if (array_key_exists ("session_token", $_SESSION)) {
      $session_token = $_SESSION[ 'session_token' ];
    } else {
      $session_token = "";
    }

    checkToken( $_REQUEST[ 'user_token' ], $session_token, 'admin-login.php' );

    // Sanitise username input
    $user = $_POST[ 'username' ];
	  $user = stripslashes( $user );
    $user = ((isset($GLOBALS["___conn"]) && is_object($GLOBALS["___conn"])) ? mysqli_real_escape_string($GLOBALS["___conn"],  $user ) : ((trigger_error("[MySQLConverterToo] Fix the mysql_escape_string() call! This code does not work.", E_USER_ERROR)) ? "" : ""));

    // Sanitise password input
    $pass = $_POST[ 'password' ];
    $pass = stripslashes( $pass );
    $pass = ((isset($GLOBALS["___conn"]) && is_object($GLOBALS["___conn"])) ? mysqli_real_escape_string($GLOBALS["___conn"],  $pass ) : ((trigger_error("[MySQLConverterToo] Fix the mysql_escape_string() call! This code does not work.", E_USER_ERROR)) ? "" : ""));
    $pass = md5( $pass );

    // Default values
    $total_failed_login = 3;
    $lockout_time       = 15;
    $account_locked     = false;

    // Check the database (Check user information)
    $data = $db->prepare( 'SELECT failed_login, last_login FROM users WHERE user = (:user) LIMIT 1;' );
    $data->bindParam( ':user', $user, PDO::PARAM_STR );
    $data->execute();
    $row = $data->fetch();

    // Check to see if the user has been locked out.
    if( ( $data->rowCount() == 1 ) && ( $row[ 'failed_login' ] >= $total_failed_login ) )  {
      // User locked out.  Note, using this method would allow for user enumeration!
      //$html .= "<pre><br />This account has been locked due to too many incorrect logins.</pre>";

      // Calculate when the user would be allowed to login again
      $last_login = strtotime( $row[ 'last_login' ] );
      $timeout    = $last_login + ($lockout_time * 60);
      $timenow    = time();


      // Check to see if enough time has passed, if it hasn't locked the account
      if( $timenow < $timeout ) {
        $account_locked = true;
        // print "The account is locked<br />";
      }
    }

    // Check the database (if username matches the password)
    $data = $db->prepare( 'SELECT * FROM users WHERE user = (:user) AND password = (:password) LIMIT 1;' );
    $data->bindParam( ':user', $user, PDO::PARAM_STR);
    $data->bindParam( ':password', $pass, PDO::PARAM_STR );
    $data->execute();
    $row = $data->fetch();

    // If its a valid login...
    if( ( $data->rowCount() == 1 ) && ( $account_locked == false ) ) {
      // Get users details
      // $avatar       = $row[ 'avatar' ];
      $failed_login = $row[ 'failed_login' ];
      $last_login   = $row[ 'last_login' ];
      $user         = $row[ 'user'];
      $role         = $row[ 'role'];

      // Login successful
      $_SESSION['username'] = $user;
      if($role == TRUE){
        header('Location: admin-page.php');
      } else {
        header('Location: user.php');
      }
      

      // Had the account been locked out since last login?
      // if( $failed_login >= $total_failed_login ) {
      //   $errors['authenticate']  .= "<p><em>Warning</em>: Someone might of been brute forcing your account.</p>";
      //   $errors['authenticate']  .= "<p>Number of login attempts: <em>{$failed_login}</em>.<br />Last login attempt was at: <em>{$last_login}</em>.</p>";
      // }

      // Reset bad login count
      $data = $db->prepare( 'UPDATE users SET failed_login = "0" WHERE user = (:user) LIMIT 1;' );
      $data->bindParam( ':user', $user, PDO::PARAM_STR );
      $data->execute();
    } else {
      // Login failed
      sleep( rand( 2, 4 ) );

      // Give the user some feedback
      $errors['authenticate'] = "Incorrect username or password <em>please try again in {$lockout_time} minutes</em>";
      // $html .= "<pre><br />Username and/or password incorrect.<br /><br/>Alternative, the account has been locked because of too many failed logins.<br />If this is the case, <em>please try again in {$lockout_time} minutes</em>.</pre>";

      // Update bad login count
      $data = $db->prepare( 'UPDATE users SET failed_login = (failed_login + 1) WHERE user = (:user) LIMIT 1;' );
      $data->bindParam( ':user', $user, PDO::PARAM_STR );
      $data->execute();
    }

    // Set the last login time
    $data = $db->prepare( 'UPDATE users SET last_login = now() WHERE user = (:user) LIMIT 1;' );
    $data->bindParam( ':user', $user, PDO::PARAM_STR );
    $data->execute();
  }

    Header( 'Cache-Control: no-cache, must-revalidate');    // HTTP/1.1
    Header( 'Content-Type: text/html;charset=utf-8' );      // TODO- proper XHTML headers...
    Header( 'Expires: Tue, 23 Jun 2009 12:00:00 GMT' );     // Date in the past
    
    // Anti-CSRF
    generateSessionToken();



echo "
<!DOCTYPE html>
<html lang=\"en\">
<head>
    <title>Admin Login</title>
</head>";

  include "template/header.php";
echo "
<div style=\"margin-top:100px;\">
<form action=\"admin-login.php\" method=\"POST\">
    <h3 class=\"heading\">Welcome Admin</h3>
  <label>
    <p class=\"label-txt\">ENTER YOUR USERNAME</p>
    <input type=\"text\" class=\"input\" name=\"username\" size=\"10\" required>
    <div class=\"line-box\">
      <div class=\"line\"></div>
    </div>
  </label>
  <label>
    <p class=\"label-txt\">ENTER YOUR PASSWORD</p>
    <input type=\"password\" class=\"input\" name=\"password\" AUTOCOMPLETE=\"off\" size=\"20\" required>
    <div class=\"line-box\">
      <div class=\"line\"></div>
    </div>
  </label>
  <p class=\"bg-danger text-white\"> ". htmlspecialchars($errors['authenticate']) . " </p>
  <button type=\"submit\" name=\"signin\" value=\"submit\">Sign-In</button>

  " . tokenField() . "

</form>
</div>

</html>";
?>
