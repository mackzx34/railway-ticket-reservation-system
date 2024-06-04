<?php
    
  include "include/connection.inc.php";
  DatabaseConnect();
  $errors = array('authenticate' => '');
  mysqli_report(MYSQLI_REPORT_ERROR | MYSQLI_REPORT_STRICT);

  if(isset($_POST['signin'])){
    // Anti-CSRF
    if (array_key_exists ("session_token", $_SESSION)) {
      $session_token = $_SESSION[ 'session_token' ];
    } else {
      $session_token = "";
    }

    checkToken( $_REQUEST[ 'user_token' ], $session_token, 'admin-login.php' );

    $user = $_POST[ 'username' ];
	  $user = stripslashes( $user );
    $user = ((isset($GLOBALS["___conn"]) && is_object($GLOBALS["___conn"])) ? mysqli_real_escape_string($GLOBALS["___conn"],  $user ) : ((trigger_error("[MySQLConverterToo] Fix the mysql_escape_string() call! This code does not work.", E_USER_ERROR)) ? "" : ""));

    $pass = $_POST[ 'password' ];
    $pass = stripslashes( $pass );
    $pass = ((isset($GLOBALS["___conn"]) && is_object($GLOBALS["___conn"])) ? mysqli_real_escape_string($GLOBALS["___conn"],  $pass ) : ((trigger_error("[MySQLConverterToo] Fix the mysql_escape_string() call! This code does not work.", E_USER_ERROR)) ? "" : ""));
    $pass = md5( $pass );

        
        if(! array_filter($errors)){
            $username = $conn->real_escape_string($username);
            $password = $conn->real_escape_string($password);
            
            //CHECK CORRECT USERNAME PASSWORD
            $query = ("SELECT * FROM user WHERE username = '$user' AND password = '$pass' LIMIT 1");
            $result = @mysqli_query($GLOBALS["___conn"],  $query );
            if( mysqli_num_rows( $result ) != 1 ) {
              $errors['authenticate'] = 'Incorrect username or password';
            }

            if( $result && mysqli_num_rows( $result ) == 1 ) {
              $_SESSION['username'] = $user;
              $row = mysqli_fetch_assoc($result);
              
                if($row["role"] == TRUE){
                  header('Location: admin-page.php');
                } else {
                  header('Location: user.php');
                }

            }

            $conn->close();
        }
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
