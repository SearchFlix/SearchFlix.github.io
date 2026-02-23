<?php
require_once 'db.php';

$data = json_decode(file_get_contents("php://input"));

if (!empty($data->user_id)) {
    $user_id = $data->user_id;
    $action = $data->action ?? 'get'; // 'get', 'add', 'remove'

    if ($action == 'get') {
        $stmt = $pdo->prepare("SELECT movie_id, movie_data FROM watchlist WHERE user_id = ?");
        $stmt->execute([$user_id]);
        $items = $stmt->fetchAll();
        echo json_encode(["status" => "success", "data" => $items]);
    } elseif ($action == 'add' && !empty($data->movie_id)) {
        $movie_data = json_encode($data->movie_data);
        $stmt = $pdo->prepare("INSERT INTO watchlist (user_id, movie_id, movie_data) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE movie_data = ?");
        $stmt->execute([$user_id, $data->movie_id, $movie_data, $movie_data]);
        echo json_encode(["status" => "success", "message" => "Added to watchlist"]);
    } elseif ($action == 'remove' && !empty($data->movie_id)) {
        $stmt = $pdo->prepare("DELETE FROM watchlist WHERE user_id = ? AND movie_id = ?");
        $stmt->execute([$user_id, $data->movie_id]);
        echo json_encode(["status" => "success", "message" => "Removed from watchlist"]);
    } else {
        echo json_encode(["status" => "error", "message" => "Invalid action or missing data"]);
    }
} else {
    echo json_encode(["status" => "error", "message" => "User ID required"]);
}
?>
