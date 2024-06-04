<?php
session_start();
// To prevent user to access the page without login
if(isset($_SESSION['username'])){
    if($_SESSION['username'] == 'admin1' || $_SESSION['username'] == 'admin'){
        header('Location: admin-page.php');
    }
}
else{
    header('Location: index.php');
}
include "include/connection.inc.php";
DatabaseConnect();
$errors = array('train_number' => '', 'date' => '', 'num_passengers' => '', 'validate' => '', 'error' => '');
$train_number = $date = $coach = $num_passengers = $error = ''; 

if(isset($_POST['next']) && isset($_POST['train_number']) && isset($_POST['date'])){
    

    // Sanitize the input
    $train_number = $_POST['train_number'];
    $train_number = trim($train_number);
    $train_number = stripslashes($train_number);
    $train_number = htmlspecialchars($train_number, ENT_QUOTES, 'UTF-8');

    $date = $_POST['date'];
    $date = trim($date);
    $date = stripslashes($date);
    $date = htmlspecialchars($date, ENT_QUOTES, 'UTF-8');

    $coach = $_POST['coach'];
    $coach = trim($coach);
    $coach = stripslashes($coach);
    $coach = htmlspecialchars($coach, ENT_QUOTES, 'UTF-8');

    $num_passengers = $_POST['num_passengers'];
    $num_passengers = trim($num_passengers);
    $num_passengers = stripslashes($num_passengers);
    $num_passengers = htmlspecialchars($num_passengers, ENT_QUOTES, 'UTF-8');

    // Assuming $GLOBALS["___conn"] is your MySQLi connection
    if (isset($GLOBALS["___conn"]) && is_object($GLOBALS["___conn"])) {
        $train_number = mysqli_real_escape_string($GLOBALS["___conn"], $train_number);
        $date = mysqli_real_escape_string($GLOBALS["___conn"], $date);
        $coach = mysqli_real_escape_string($GLOBALS["___conn"], $coach);
        $num_passengers = mysqli_real_escape_string($GLOBALS["___conn"], $num_passengers);
    } else {
        trigger_error("[MySQLConverterToo] Fix the mysql_escape_string() call! This code does not work.", E_USER_ERROR);
    }


    if(empty($train_number)){
        $errors['train_number'] = 'Train Number is required';
    }
    if(empty($date)){
        $errors['date'] = 'Date is required';
    }
    if(empty($num_passengers)){
        $errors['num_passengers'] = 'Enter Number Of Passengers';
    }

    // IF NO PREVIOUS ERRORS THEN CHECK VALIDITY OF TRAIN NUMBER & DATE
    if(!array_filter($errors)){
        $data = $db->prepare('SELECT t_number, t_date FROM train WHERE t_number = :t_no AND t_date = :date LIMIT 1;');
        $data->bindParam(':t_no', $train_number, PDO::PARAM_STR);
        $data->bindParam(':date', $date, PDO::PARAM_STR);
        $data->execute();
        $row = $data->fetch();

        // If its a valid login...
        if($data->rowCount() != 1) {
            $errors['error'] = "No Train Available";
        }
    }

    // IF NO ERRORS ENTER DETAILS OF PASSENGER
    if(!array_filter($errors)){
        $_SESSION['train_number'] = $train_number;
        $_SESSION['date'] = $date;
        $_SESSION['coach'] = $coach;
        $_SESSION['num_passengers'] = $num_passengers;
        header('Location: passenger-details.php');
    }
}
?>

<!DOCTYPE html>
<html lang="en">
<head>
    <title>Book Ticket</title>
    <script>
        function findtrain() {
            var date = document.getElementById("date").value;
            var errorMessage = document.getElementById("error");
            errorMessage.textContent = "";
            var xhr = new XMLHttpRequest();
            xhr.open('GET', 'fetch_trains.php?date=' + date, true);
            xhr.onload = function () {
                if (xhr.status === 200) {
                    var response = JSON.parse(xhr.responseText);
                    var trainSelect = document.getElementById("train_number");
                    trainSelect.innerHTML = '<option value="">Select Train</option>'; // Clear previous options
                    if (response.status === 'no_trains') {
                        errorMessage.textContent = "No trains available for the selected date.";
                    } else {
                        response.trains.forEach(function(train) {
                            var option = document.createElement("option");
                            option.value = train.t_number;
                            option.text = train.t_number;
                            trainSelect.add(option);
                        });
                    }
                } 
            };
            xhr.send();
        }
    </script>
</head>
<?php include "template/header-name.php"; ?>

<div style="margin-top:100px;">
<form action="book-ticket.php" method="POST">
    <h3 class="heading">Book Ticket</h3> <br>

    <label>
        <p class="label-txt">DATE</p>
        <input type="date" class="input" name="date" id="date" value="<?php echo htmlspecialchars($date) ?>" onchange="findtrain()">
        <div class="line-box">
            <div class="line"></div>
        </div>
        <p class="bg-danger text-white"><?php echo htmlspecialchars($errors['date'])?></p>
    </label>

    <label>
        <p class="label-txt">TRAIN NUMBER</p>
        <select id="train_number" name="train_number" class="input">
            <option value="">Select Train</option>
        </select>
    </label>
    <p class="bg-danger text-white" id="error"><?php echo htmlspecialchars($errors['validate'])?></p>
    <label>
        <p class="label-txt">COACH&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
            <input type="radio" name="coach" value="ac" checked>&nbsp;&nbsp;&nbsp;AC</input>&nbsp;&nbsp;&nbsp;
            <input type="radio" name="coach" value="sleeper">&nbsp;&nbsp;&nbsp;SLEEPER</input></p><br>
    </label>
    <label>
        <p class="label-txt">NUMBER OF PASSENGERS</p>
        <input type="number" class="input" min="1" name="num_passengers" value="<?php echo htmlspecialchars($num_passengers) ?>">
        <div class="line-box">
            <div class="line"></div>
        </div>
        <p class="bg-danger text-white"><?php echo htmlspecialchars($errors['num_passengers'])?></p>
    </label>
    <p class="bg-danger text-white"><?php echo htmlspecialchars($errors['error'])?></p>
    <br>
    <a href="user.php" class="register">Back</a>
    <button type="submit" name="next" value="submit">Next</button>
</form>
</div>
</html>

