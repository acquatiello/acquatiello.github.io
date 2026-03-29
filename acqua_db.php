<?php
declare(strict_types=1);

function acqua_db_path(): string {
    return __DIR__ . DIRECTORY_SEPARATOR . 'acqua.sqlite';
}

function acqua_db(): PDO {
    static $pdo = null;
    if ($pdo instanceof PDO) return $pdo;

    $pdo = new PDO('sqlite:' . acqua_db_path(), null, null, [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        PDO::ATTR_EMULATE_PREPARES => false,
    ]);

    $pdo->exec('PRAGMA journal_mode = WAL;');
    $pdo->exec('PRAGMA foreign_keys = ON;');

    acqua_db_migrate($pdo);
    return $pdo;
}

function acqua_db_migrate(PDO $pdo): void {
    $pdo->exec('CREATE TABLE IF NOT EXISTS produtos (
        id INTEGER PRIMARY KEY,
        sku TEXT NOT NULL DEFAULT \'\',
        ean TEXT NOT NULL DEFAULT \'\',
        nome TEXT NOT NULL DEFAULT \'\',
        preco REAL NOT NULL DEFAULT 0,
        qtde REAL NOT NULL DEFAULT 0,
        unid TEXT NOT NULL DEFAULT \'\',
        cat TEXT NOT NULL DEFAULT \'\',
        marca TEXT NOT NULL DEFAULT \'\',
        descricaoAnuncio TEXT NOT NULL DEFAULT \'\',
        img TEXT NOT NULL DEFAULT \'\',
        imgs_json TEXT NOT NULL DEFAULT \'[]\',
        atualizado_em TEXT NOT NULL DEFAULT (datetime(\'now\'))
    );');

    $pdo->exec('CREATE INDEX IF NOT EXISTS idx_produtos_sku ON produtos(sku);');
    $pdo->exec('CREATE INDEX IF NOT EXISTS idx_produtos_ean ON produtos(ean);');
    $pdo->exec('CREATE INDEX IF NOT EXISTS idx_produtos_cat ON produtos(cat);');
    $pdo->exec('CREATE INDEX IF NOT EXISTS idx_produtos_marca ON produtos(marca);');

    $pdo->exec('CREATE TABLE IF NOT EXISTS pedidos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        pedido_num TEXT NOT NULL DEFAULT \'\',
        cliente_id TEXT NOT NULL DEFAULT \'\',
        criado_em TEXT NOT NULL DEFAULT (datetime(\'now\')),
        assunto TEXT NOT NULL DEFAULT \'\',
        email_cliente TEXT NOT NULL DEFAULT \'\',
        email_empresa TEXT NOT NULL DEFAULT \'\',
        conteudo TEXT NOT NULL DEFAULT \'\'
    );');

    $pdo->exec('CREATE INDEX IF NOT EXISTS idx_pedidos_criado_em ON pedidos(criado_em);');
}

function acqua_json_response(array $data, int $status = 200): void {
    http_response_code($status);
    header('Content-Type: application/json; charset=UTF-8');
    echo json_encode($data, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
}

