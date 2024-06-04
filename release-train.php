<?php
    session_start();
    //To prevent user to access the page without login
    if(isset($_SESSION['username'])){
        if($_SESSION['username'] != 'admin1' && $_SESSION['username'] != 'admin'){
          header('Location: user.php');
        }
    }
    else{
        header('Location: admin-login.php');
    }
    
    include "include/connection.inc.php";
    DatabaseConnect();

    $errors = array('train_number' => '', 'date' => '', 'num_ac' => '', 'num_sleeper' => '', 'checks' => '', 'error' => '');
    $train_number = $date = $num_ac = $num_sleeper = $checks = $error = ''; 
    $admin_name = $_SESSION['username'];
   
    if(isset($_POST['release']) && isset ($_POST['train_number']) && isset ($_POST['date']) && isset ($_POST['num_ac']) && isset ($_POST['num_sleeper'])){

        // Anti-CSRF
        // if (array_key_exists ("session_token", $_SESSION)) {
        //   $session_token = $_SESSION[ 'session_token' ];
        // } else {
        //   $session_token = "";
        // }

        // checkToken( $_REQUEST[ 'user_token' ], $session_token, 'release-train.php' );

        $train_number = $_POST['train_number'];
        $train_number = trim( $train_number );
        $train_number = stripslashes( $train_number );
        $train_number = ((isset($GLOBALS["___conn"]) && is_object($GLOBALS["___conn"])) ? mysqli_real_escape_string($GLOBALS["___conn"],  $train_number ) : ((trigger_error("[MySQLConverterToo] Fix the mysql_escape_string() call! This code does not work.", E_USER_ERROR)) ? "" : ""));
        if(!preg_match('/^[0-9]+$/', $train_number)){
            $errors['error'] .= 'Train No must consist of Number only';
        }

        $date = $_POST['date'];
        $date = trim($date);
        $date = stripslashes($date);
        $date = ((isset($GLOBALS["___conn"]) && is_object($GLOBALS["___conn"])) ? mysqli_real_escape_string($GLOBALS["___conn"],  $date ) : ((trigger_error("[MySQLConverterToo] Fix the mysql_escape_string() call! This code does not work.", E_USER_ERROR)) ? "" : ""));
        // if (!preg_match('/^\d{4}-\d{2}-\d{2}$/', $date)) {
        //     $errors['error'] .= 'Date must be in the format YYYY-MM-DD';
        // }

        $num_ac = $_POST['num_ac'];
        $num_ac = trim($num_ac);
        $num_ac = stripslashes($num_ac);
        $num_ac = ((isset($GLOBALS["___conn"]) && is_object($GLOBALS["___conn"])) ? mysqli_real_escape_string($GLOBALS["___conn"],  $num_ac ) : ((trigger_error("[MySQLConverterToo] Fix the mysql_escape_string() call! This code does not work.", E_USER_ERROR)) ? "" : ""));
        if (!preg_match('/^[0-9]+$/', $num_ac)) {
            $errors['error'] .= 'AC coaches must consist of numbers only';
        }

        $num_sleeper = $_POST['num_sleeper'];
        $num_sleeper = trim($num_sleeper);
        $num_sleeper = stripslashes($num_sleeper);
        $num_sleeper = ((isset($GLOBALS["___conn"]) && is_object($GLOBALS["___conn"])) ? mysqli_real_escape_string($GLOBALS["___conn"],  $num_sleeper ) : ((trigger_error("[MySQLConverterToo] Fix the mysql_escape_string() call! This code does not work.", E_USER_ERROR)) ? "" : ""));
        if (!preg_match('/^[0-9]+$/', $num_sleeper)) {
            $errors['error'] .= 'Sleeper coaches must consist of numbers only';
        }

        // Check the database (Check train information)
        $data = $db->prepare( 'SELECT t_number, t_date FROM train WHERE t_number = (:train_number) AND t_date = (:date) LIMIT 1;' );
        $data->bindParam(':train_number', $train_number, PDO::PARAM_STR);
        $data->bindParam(':date', $date, PDO::PARAM_STR);
        $data->execute();
        $row = $data->fetch();

        if( ( $data->rowCount() == 1 ) && ( $row[ 't_number' ] == $train_number ) && ( $row[ 't_date' ] == $date) )  {
            $errors['error'] = 'This Train Already Released on that day';
        }
 
        if (! array_filter($errors)) {
            
            $data = $db->prepare('INSERT INTO train (t_number, t_date, num_ac, num_sleeper, released_by) VALUES (:train_number, :date, :num_ac, :num_sleeper, :released)');
            $data->bindParam(':train_number', $train_number, PDO::PARAM_STR);
            $data->bindParam(':date', $date, PDO::PARAM_STR);
            $data->bindParam(':num_ac', $num_ac, PDO::PARAM_INT);
            $data->bindParam(':num_sleeper', $num_sleeper, PDO::PARAM_INT);
            $data->bindParam(':released', $admin_name, PDO::PARAM_INT);
        
            if ($data->execute()) {
                if ($data->rowCount() == 1) {

                    $data = $db->prepare('INSERT INTO train_status (t_number, t_date, seats_b_ac, seats_b_sleeper) VALUES (:train_number, :date, 0, 0)');
                    $data->bindParam(':train_number', $train_number, PDO::PARAM_STR);
                    $data->bindParam(':date', $date, PDO::PARAM_STR);

                    if ($data->execute()) {
                        if ($data->rowCount() == 1) {
                            $db = NULL;
                            $errors['error'] = 'sucess';
                            $success['success'] .= "Train has been registered.";
                            sleep(6);
                            header('Location: admin-page.php');
                            exit(); 
                        }
                    }

                    
                } else {
                    $errors['error'] .= "Error inserting train.";
                }
            } else {
                $errors['error'] .= "Error inserting train.";
            }
        }

    }
    $welcome_name = $_SESSION['username'] ?? 'Guest';
?>

<!DOCTYPE html>
<html lang="en">
<head>
    <title>Release Train</title>
</head>
<?php include "template/header-name.php" ?>

<div style="margin-top:100px;">
<form action="release-train.php" method="POST">
    <h3 class="heading">Release New Train</h3> <br>
    <label>
    <p class="label-txt">TRAIN NUMBER</p>
    <input type="number" class="input" min=0 name="train_number" value="<?php echo htmlspecialchars($train_number) ?>">
    <div class="line-box">
        <div class="line"></div>
    </div>
    <p class= "bg-danger text-white"><?php echo htmlspecialchars($errors['train_number'])?></p>
    </label>
    <label>
    <p class="label-txt">DATE</p>
    <input type="date" class="input" name="date" value="<?php echo htmlspecialchars($date) ?>">
    <div class="line-box">
        <div class="line"></div>
    </div>
    <p class= "bg-danger text-white"><?php echo htmlspecialchars($errors['date'])?></p>
    </label>
    <label>
    <p class="label-txt">NUMBER OF AC COACHES</p>
    <input type="number" class="input" min=0 name="num_ac" value="<?php echo htmlspecialchars($num_ac) ?>">
    <div class="line-box">
        <div class="line"></div>
    </div>
    <p class= "bg-danger text-white"><?php echo htmlspecialchars($errors['num_ac'])?></p>
    </label>
    <label>
    <p class="label-txt">NUMBER OF SLEEPER COACHES</p>
    <input type="number" class="input" name="num_sleeper" min=0 value="<?php echo htmlspecialchars($num_sleeper) ?>">
    <div class="line-box">
        <div class="line"></div>
    </div>
    <p class= "bg-danger text-white"><?php echo htmlspecialchars($errors['num_sleeper'])?></p>
    </label>
    <p class= "bg-danger text-white"><?php echo htmlspecialchars($errors['checks'])?></p>
    <p class= "bg-danger text-white"><?php echo htmlspecialchars($errors['error'])?></p>
    <a href="admin-page.php" class="register">Back</a>
    <button type="submit" name="release" value="submit">Release</button>
</form>
</div>


</html>
