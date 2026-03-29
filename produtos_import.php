<?php
declare(strict_types=1);

require __DIR__ . '/acqua_db.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    acqua_json_response(['ok' => false, 'erro' => 'Método inválido'], 405);
    exit;
}

$raw = file_get_contents('php://input');
$data = json_decode($raw ?: '', true);
if (!is_array($data)) {
    acqua_json_response(['ok' => false, 'erro' => 'JSON inválido'], 400);
    exit;
}

$produtos = $data['produtos'] ?? null;
if (!is_array($produtos)) {
    acqua_json_response(['ok' => false, 'erro' => 'Campo produtos inválido'], 400);
    exit;
}

try {
    $pdo = acqua_db();
    $pdo->beginTransaction();

    $stmt = $pdo->prepare('INSERT INTO produtos (id, sku, ean, nome, preco, qtde, unid, cat, marca, descricaoAnuncio, img, imgs_json, atualizado_em)
        VALUES (:id, :sku, :ean, :nome, :preco, :qtde, :unid, :cat, :marca, :descricaoAnuncio, :img, :imgs_json, datetime(\'now\'))
        ON CONFLICT(id) DO UPDATE SET
            sku=excluded.sku,
            ean=excluded.ean,
            nome=excluded.nome,
            preco=excluded.preco,
            qtde=excluded.qtde,
            unid=excluded.unid,
            cat=excluded.cat,
            marca=excluded.marca,
            descricaoAnuncio=excluded.descricaoAnuncio,
            img=excluded.img,
            imgs_json=excluded.imgs_json,
            atualizado_em=datetime(\'now\')');

    $ok = 0;
    $falhas = 0;

    foreach ($produtos as $p) {
        if (!is_array($p)) { $falhas++; continue; }
        $id = (int)($p['id'] ?? 0);
        if ($id <= 0) { $falhas++; continue; }

        $imgs = $p['imgs'] ?? [];
        if (!is_array($imgs)) $imgs = [];
        $imgs = array_values(array_filter(array_map(static fn($x) => trim((string)$x), $imgs), static fn($x) => $x !== ''));

        $stmt->execute([
            ':id' => $id,
            ':sku' => trim((string)($p['sku'] ?? '')),
            ':ean' => trim((string)($p['ean'] ?? '')),
            ':nome' => trim((string)($p['nome'] ?? '')),
            ':preco' => (float)($p['preco'] ?? 0),
            ':qtde' => (float)($p['qtde'] ?? 0),
            ':unid' => trim((string)($p['unid'] ?? '')),
            ':cat' => trim((string)($p['cat'] ?? '')),
            ':marca' => trim((string)($p['marca'] ?? '')),
            ':descricaoAnuncio' => trim((string)($p['descricaoAnuncio'] ?? '')),
            ':img' => trim((string)($p['img'] ?? ($imgs[0] ?? ''))),
            ':imgs_json' => json_encode($imgs, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES),
        ]);
        $ok++;
    }

    $pdo->commit();
    acqua_json_response(['ok' => true, 'importados' => $ok, 'falhas' => $falhas], 200);
} catch (Throwable $e) {
    if (isset($pdo) && $pdo instanceof PDO && $pdo->inTransaction()) $pdo->rollBack();
    acqua_json_response(['ok' => false, 'erro' => 'Falha ao importar'], 500);
}

