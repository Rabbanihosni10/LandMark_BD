<?php

header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Origin, X-Requested-With, Content-Type, Accept, Authorization');
header('Access-Control-Allow-Credentials: true');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}


$dbFile = __DIR__ . '/landmarks.json';
function getDb() {
    global $dbFile;
    if (!file_exists($dbFile)) {
        return [];
    }
    return json_decode(file_get_contents($dbFile), true) ?: [];
}

function saveDb($data) {
    global $dbFile;
    file_put_contents($dbFile, json_encode($data, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES));
}

function generateId() {
    return uniqid('lm_', true);
}

if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    header('Content-Type: application/json');
    $db = getDb();
    echo json_encode($db);
    exit();
}

if ($_SERVER['REQUEST_METHOD'] === 'POST' && preg_match('/\/upload\/?$/i', $_SERVER['REQUEST_URI'])) {
    header('Content-Type: application/json');
    
    if (empty($_FILES['image']) || $_FILES['image']['error'] !== UPLOAD_ERR_OK) {
        http_response_code(400);
        echo json_encode(['error' => 'No image uploaded or upload error']);
        exit();
    }

    $uploadsDir = __DIR__ . '/uploads';
    if (!is_dir($uploadsDir)) {
        mkdir($uploadsDir, 0755, true);
    }

    $file = $_FILES['image'];
    $name = time() . '_' . basename($file['name']);
    $dest = $uploadsDir . '/' . $name;

    if (move_uploaded_file($file['tmp_name'], $dest)) {
        echo json_encode([
            'id' => $name,
            'url' => '/uploads/' . $name,
            'path' => '/uploads/' . $name,
        ]);
    } else {
        http_response_code(500);
        echo json_encode(['error' => 'Failed to save image']);
    }
    exit();
}

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    header('Content-Type: application/json');
    
    $title = $_POST['title'] ?? '';
    $lat = $_POST['lat'] ?? 0;
    $lon = $_POST['lon'] ?? 0;

    if (empty($title)) {
        http_response_code(400);
        echo json_encode(['error' => 'Title is required']);
        exit();
    }

    $imagePath = null;
    if (!empty($_FILES['image']) && $_FILES['image']['error'] === UPLOAD_ERR_OK) {
        $uploadsDir = __DIR__ . '/uploads';
        if (!is_dir($uploadsDir)) {
            mkdir($uploadsDir, 0755, true);
        }

        $file = $_FILES['image'];
        $name = time() . '_' . basename($file['name']);
        $dest = $uploadsDir . '/' . $name;

        if (!move_uploaded_file($file['tmp_name'], $dest)) {
            http_response_code(500);
            echo json_encode(['error' => 'Failed to save image']);
            exit();
        }
        $imagePath = '/uploads/' . $name;
    }


    $id = generateId();
    $landmark = [
        'id' => $id,
        'title' => $title,
        'lat' => (double) $lat,
        'lon' => (double) $lon,
        'image' => $imagePath,
        'createdAt' => date('c'),
    ];

    $db = getDb();
    $db[] = $landmark;
    saveDb($db);

    http_response_code(201);
    echo json_encode($landmark);
    exit();
}


if ($_SERVER['REQUEST_METHOD'] === 'PUT') {
    header('Content-Type: application/json');

    parse_str(file_get_contents('php://input'), $data);
    
    $id = $data['id'] ?? $_POST['id'] ?? null;
    $title = $data['title'] ?? $_POST['title'] ?? null;
    $lat = $data['lat'] ?? $_POST['lat'] ?? null;
    $lon = $data['lon'] ?? $_POST['lon'] ?? null;

    if (!$id) {
        http_response_code(400);
        echo json_encode(['error' => 'ID is required']);
        exit();
    }

    $db = getDb();
    $found = false;

    foreach ($db as &$item) {
        if ($item['id'] === $id) {
            $found = true;
            if ($title !== null) $item['title'] = $title;
            if ($lat !== null) $item['lat'] = (double) $lat;
            if ($lon !== null) $item['lon'] = (double) $lon;
            break;
        }
    }

    if (!$found) {
        http_response_code(404);
        echo json_encode(['error' => 'Landmark not found']);
        exit();
    }

    saveDb($db);
    echo json_encode(current($db)); // Return updated item
    exit();
}


if ($_SERVER['REQUEST_METHOD'] === 'POST' && ($_POST['_method'] ?? '') === 'PUT') {
    header('Content-Type: application/json');

    $id = $_POST['id'] ?? null;
    $title = $_POST['title'] ?? null;
    $lat = $_POST['lat'] ?? null;
    $lon = $_POST['lon'] ?? null;

    if (!$id) {
        http_response_code(400);
        echo json_encode(['error' => 'ID is required']);
        exit();
    }

    $db = getDb();
    $found = false;

    foreach ($db as &$item) {
        if ($item['id'] === $id) {
            $found = true;
            if ($title !== null) $item['title'] = $title;
            if ($lat !== null) $item['lat'] = (double) $lat;
            if ($lon !== null) $item['lon'] = (double) $lon;

            if (!empty($_FILES['image']) && $_FILES['image']['error'] === UPLOAD_ERR_OK) {
                $uploadsDir = __DIR__ . '/uploads';
                if (!is_dir($uploadsDir)) {
                    mkdir($uploadsDir, 0755, true);
                }

                $file = $_FILES['image'];
                $name = time() . '_' . basename($file['name']);
                $dest = $uploadsDir . '/' . $name;

                if (move_uploaded_file($file['tmp_name'], $dest)) {
                    $item['image'] = '/uploads/' . $name;
                } else {
                    http_response_code(500);
                    echo json_encode(['error' => 'Failed to save image']);
                    exit();
                }
            }
            break;
        }
    }

    if (!$found) {
        http_response_code(404);
        echo json_encode(['error' => 'Landmark not found']);
        exit();
    }

    saveDb($db);
    echo json_encode(current($db)); // Return updated item
    exit();
}

if ($_SERVER['REQUEST_METHOD'] === 'DELETE') {
    header('Content-Type: application/json');

    parse_str(file_get_contents('php://input'), $data);
    $id = $data['id'] ?? null;

    if (!$id) {
        http_response_code(400);
        echo json_encode(['error' => 'ID is required']);
        exit();
    }

    $db = getDb();
    $initialCount = count($db);
    $db = array_filter($db, function ($item) use ($id) {
        return $item['id'] !== $id;
    });

    if (count($db) === $initialCount) {
        http_response_code(404);
        echo json_encode(['error' => 'Landmark not found']);
        exit();
    }

    saveDb(array_values($db)); // Reindex array
    echo json_encode(['message' => 'Deleted successfully']);
    exit();
}

http_response_code(405);
header('Content-Type: application/json');
echo json_encode(['error' => 'Method not supported']);
