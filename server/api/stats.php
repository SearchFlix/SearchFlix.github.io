<?php
require_once 'db.php';

$data = json_decode(file_get_contents("php://input"));
$action = $_GET['action'] ?? 'get'; // 'get' or 'track'

if ($action == 'track') {
    $stmt = $pdo->prepare("UPDATE site_stats SET page_hits = page_hits + 1 WHERE id = 1");
    $stmt->execute();
    echo json_encode(["status" => "success", "message" => "Hit tracked"]);
} else {
    $stmt = $pdo->query("SELECT page_hits, unique_visitors, last_updated FROM site_stats WHERE id = 1");
    $stats = $stmt->fetch();
    echo json_encode(["status" => "success", "data" => $stats]);
}
?>
