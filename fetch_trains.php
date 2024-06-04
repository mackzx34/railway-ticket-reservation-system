<?php
include "include/connection.inc.php";
DatabaseConnect();

if (isset($_GET['date'])) {
    $date = $_GET['date'];
    $query = $db->prepare('SELECT t_number FROM train WHERE t_date = :date');
    $query->bindParam(':date', $date, PDO::PARAM_STR);
    $query->execute();
    $trains = $query->fetchAll(PDO::FETCH_ASSOC);
    
    if (empty($trains)) {
        echo json_encode(['status' => 'no_trains']);
    } else {
        echo json_encode(['status' => 'found', 'trains' => $trains]);
    }
}
?>
