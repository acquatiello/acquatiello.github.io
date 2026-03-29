<!DOCTYPE html>
<html lang="pt-br">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Contato</title>
<link rel="icon" type="image/png" href="/htdocs/logo.png">
<link rel="shortcut icon" type="image/png" href="/htdocs/logo.png">
<link href="https://fonts.googleapis.com/css2?family=Montserrat:wght@300;400;600;700&display=swap" rel="stylesheet">
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
<style>
:root { --azul-acqua: #5fd6ff; --texto: #0f172a; }
* { box-sizing: border-box; margin: 0; padding: 0; }
body { font-family: 'Montserrat', sans-serif; background: #f5f7fa; color: var(--texto); }
.wrap { max-width: 900px; margin: 40px auto; padding: 0 20px; }
.card { background: #fff; border: 1px solid #eee; border-radius: 12px; box-shadow: 0 10px 30px rgba(0,0,0,0.08); overflow: hidden; }
.card-header { background: linear-gradient(90deg, #000c14, #00243a); color: #7fdfff; padding: 20px; display:flex; align-items:center; justify-content:space-between; }
.card-title { font-size: 20px; font-weight: 700; }
.card-body { padding: 20px; }
.row { display: grid; grid-template-columns: repeat(auto-fit, minmax(220px, 1fr)); gap: 15px; }
.form-group { display:flex; flex-direction:column; gap:6px; }
label { font-size: 11px; font-weight: 700; color: #666; text-transform: uppercase; }
input, textarea { padding: 10px; border: 1px solid #ddd; border-radius: 8px; outline-color: var(--azul-acqua); font-family: 'Montserrat', sans-serif; }
textarea { min-height: 140px; resize: vertical; }
.actions { display:flex; gap:10px; margin-top: 18px; }
.btn { appearance: none; border: 1px solid rgba(95,214,255,0.35); background: #000c14; color: #7fdfff; font-weight: 700; letter-spacing: .02em; padding: 10px 14px; border-radius: 999px; cursor: pointer; transition: .2s ease; font-family: 'Montserrat', sans-serif; font-size: 12px; text-decoration:none; display:inline-flex; align-items:center; gap:8px; }
.btn:hover { border-color: #5fd6ff; transform: translateY(-1px); box-shadow: 0 0 15px rgba(95,214,255,0.3); }
.alert-ok { background:#dcfce7; color:#166534; padding:12px; border-radius:12px; margin-bottom:12px; font-weight:700; }
.alert-err { background:#fee2e2; color:#991b1b; padding:12px; border-radius:12px; margin-bottom:12px; font-weight:700; }
.small { font-size:12px; color:#64748b; margin-top:8px; }
</style>
</head>
<body>
<?php
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $nome = trim($_POST['nome'] ?? '');
    $email = trim($_POST['email'] ?? '');
    $tel = trim($_POST['tel'] ?? '');
    $mensagem = trim($_POST['mensagem'] ?? '');
    $ok = $nome && $mensagem && filter_var($email, FILTER_VALIDATE_EMAIL);
    $enviado = false;
    $arquivo = '';
    if ($ok) {
        $assunto = 'Contato pelo site';
        $conteudo = "NOME: $nome\nEMAIL: $email\nTEL: $tel\n\nMENSAGEM:\n$mensagem\n";
        $headers = "Content-Type: text/plain; charset=UTF-8\r\n";
        $headers .= "Reply-To: $email\r\n";
        $destino = 'acquatiello@gmail.com';
        $enviado = function_exists('mail') ? @mail($destino, $assunto, $conteudo, $headers) : false;
        if (!$enviado) {
            $dir = __DIR__ . DIRECTORY_SEPARATOR . 'Mensagens';
            if (!is_dir($dir)) @mkdir($dir, 0777, true);
            $nomeArq = 'contato_' . date('Ymd_His') . '.txt';
            $path = $dir . DIRECTORY_SEPARATOR . $nomeArq;
            @file_put_contents($path, $conteudo);
            $arquivo = $nomeArq;
        }
    }
    echo '<div class="wrap"><div class="card"><div class="card-header"><div class="card-title">Contato</div><a class="btn" href="/"><i class="fas fa-home"></i> Início</a></div><div class="card-body">';
    if ($ok) {
        echo '<div class="alert-ok">Mensagem enviada. Se o e-mail falhar, ela foi salva na pasta Mensagens.</div>';
        if ($arquivo) echo '<div class="small">Arquivo: Mensagens/' . htmlspecialchars($arquivo, ENT_QUOTES, 'UTF-8') . '</div>';
    } else {
        echo '<div class="alert-err">Preencha nome, e-mail válido e mensagem.</div>';
    }
    echo '<div class="actions"><a class="btn" href="contato.php"><i class="fas fa-arrow-left"></i> Voltar</a><a class="btn" target="_blank" rel="noopener" href="https://wa.me/5511985397740"><i class="fab fa-whatsapp"></i> WhatsApp</a></div></div></div></div>';
    echo '</body></html>';
    exit;
}
?>
<div class="wrap">
    <div class="card">
        <div class="card-header">
            <div class="card-title">Contato</div>
            <a class="btn" href="/"><i class="fas fa-home"></i> Início</a>
        </div>
        <div class="card-body">
            <form method="post" action="" enctype="application/x-www-form-urlencoded">
                <div class="row">
                    <div class="form-group">
                        <label>Nome Completo</label>
                        <input type="text" name="nome" required>
                    </div>
                    <div class="form-group">
                        <label>E-mail</label>
                        <input type="email" name="email" required>
                    </div>
                    <div class="form-group">
                        <label>Telefone</label>
                        <input type="text" name="tel" placeholder="(00) 00000-0000">
                    </div>
                    <div class="form-group" style="grid-column: 1 / -1;">
                        <label>Mensagem</label>
                        <textarea name="mensagem" required></textarea>
                    </div>
                </div>
                <div class="actions">
                    <button type="submit" class="btn"><i class="fas fa-paper-plane"></i> Enviar</button>
                    <a class="btn" target="_blank" rel="noopener" href="https://wa.me/5511985397740"><i class="fab fa-whatsapp"></i> WhatsApp</a>
                </div>
                <div class="small">Ao enviar, tentamos encaminhar por e-mail. Se indisponível, salvamos sua mensagem no site.</div>
            </form>
        </div>
    </div>
</div>
</body>
</html>
