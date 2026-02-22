<?php
require_once 'db.php';

$data = json_decode(file_get_contents("php://input"));

if (!empty($data->email) && !empty($data->password)) {
    $email = $data->email;
    $password = password_hash($data->password, PASSWORD_BCRYPT);
    $name = !empty($data->name) ? $data->name : 'User';

    try {
        $stmt = $pdo->prepare("INSERT INTO users (name, email, password) VALUES (?, ?, ?)");
        if ($stmt->execute([$name, $email, $password])) {
            echo json_encode(["status" => "success", "message" => "User registered successfully"]);
        } else {
            echo json_encode(["status" => "error", "message" => "Registration failed"]);
        }
    } catch (Exception $e) {
        echo json_encode(["status" => "error", "message" => "Email already exists"]);
    }
} else {
    echo json_encode(["status" => "error", "message" => "Incomplete data"]);
}
?>
