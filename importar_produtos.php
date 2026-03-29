<!DOCTYPE html>
<html lang="pt-br">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Importar Produtos</title>
    <link rel="icon" type="image/png" href="/htdocs/logo.png">
    <link rel="shortcut icon" type="image/png" href="/htdocs/logo.png">
    <link href="https://fonts.googleapis.com/css2?family=Montserrat:wght@300;400;600;700&display=swap" rel="stylesheet">
    <style>
        :root { --azul-acqua: #5fd6ff; --texto: #0f172a; }
        * { box-sizing: border-box; margin: 0; padding: 0; }
        body { font-family: 'Montserrat', sans-serif; background: #f5f7fa; color: var(--texto); }
        .wrap { max-width: 900px; margin: 40px auto; padding: 0 20px; }
        .card { background: #fff; border: 1px solid #eee; border-radius: 12px; box-shadow: 0 10px 30px rgba(0,0,0,0.08); overflow: hidden; }
        .card-header { background: linear-gradient(90deg, #000c14, #00243a); color: #7fdfff; padding: 20px; display:flex; align-items:center; justify-content:space-between; gap: 12px; }
        .card-title { font-size: 18px; font-weight: 700; }
        .card-body { padding: 20px; }
        .btn { appearance: none; border: 1px solid rgba(95,214,255,0.35); background: #000c14; color: #7fdfff; font-weight: 700; letter-spacing: .02em; padding: 10px 14px; border-radius: 999px; cursor: pointer; transition: .2s ease; font-family: 'Montserrat', sans-serif; font-size: 12px; text-decoration:none; display:inline-flex; align-items:center; gap:8px; }
        .btn:hover { border-color: #5fd6ff; transform: translateY(-1px); box-shadow: 0 0 15px rgba(95,214,255,0.3); }
        .row { display:flex; gap: 10px; flex-wrap: wrap; margin-bottom: 12px; }
        .muted { font-size: 12px; color: #64748b; }
        pre { background: #0b1220; color: #e5f3ff; padding: 12px; border-radius: 12px; overflow:auto; font-size: 12px; }
    </style>
</head>
<body>
    <div class="wrap">
        <div class="card">
            <div class="card-header">
                <div class="card-title">Importar produtos.xlsx para o banco</div>
                <a class="btn" href="/"><span>Início</span></a>
            </div>
            <div class="card-body">
                <div class="row">
                    <button type="button" class="btn" id="btn-importar">Importar agora</button>
                    <a class="btn" href="/Vendas/baixar_pedidos.php">Baixar pedidos.csv</a>
                </div>
                <div class="muted">Este processo lê /produtos/produtos.xlsx e grava no arquivo acqua.sqlite (mesmo arquivo pode ser copiado para o site).</div>
                <div style="height:12px"></div>
                <pre id="log">Pronto.</pre>
            </div>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/xlsx@0.18.5/dist/xlsx.full.min.js"></script>
    <script>
        function normalizarPreco(v){
            const s = String(v ?? '').trim();
            if(!s) return 0;
            const limpo = s.replace(/\s/g,'').replace(/\./g,'').replace(',', '.');
            const n = Number(limpo);
            return Number.isFinite(n) ? n : 0;
        }

        function mapCategoria(v){
            const s = String(v ?? '').toLowerCase().trim();
            if(!s) return '';
            const mapa = {
                'camarão':'camarao','camarao':'camarao','camarões':'camarao','camaroes':'camarao',
                'peixe':'peixes','peixes':'peixes',
                'planta':'plantas','plantas':'plantas',
                'aquário':'aquarios','aquario':'aquarios','aquários':'aquarios','aquarios':'aquarios',
                'equipamento':'equipamentos','equipamentos':'equipamentos',
                'ração':'racao','racao':'racao',
                'acessório':'acessorios','acessorio':'acessorios','acessórios':'acessorios','acessorios':'acessorios',
                'outros':'outros','outro':'outros'
            };
            return mapa[s] || s;
        }

        function log(msg){
            const el = document.getElementById('log');
            el.textContent = msg;
        }

        async function importar(){
            log('Baixando Excel...');
            const resp = await fetch('/produtos/produtos.xlsx', { cache: 'no-store' });
            if(!resp.ok) throw new Error('Não encontrei /produtos/produtos.xlsx');

            const ab = await resp.arrayBuffer();
            const wb = XLSX.read(new Uint8Array(ab), { type: 'array' });
            const ws = wb.Sheets[wb.SheetNames[0]];
            const json = XLSX.utils.sheet_to_json(ws);

            log('Lendo linhas: ' + json.length);

            const produtos = json.map(row => {
                const id = Number(row.id || row.ID || 0);
                if(!id) return null;

                const imgs = [];
                for(let i=1;i<=5;i++){
                    const val = row[`img ${i}`] || row[`img${i}`] || row[`IMG ${i}`] || row[`IMG${i}`];
                    const url = String(val || '').replace(/[`'"]/g,'').trim();
                    if(url) imgs.push(url);
                }
                if(imgs.length === 0){
                    const val = row.img || row.Img || row.IMG;
                    const url = String(val || '').replace(/[`'"]/g,'').trim();
                    if(url) imgs.push(url);
                }

                return {
                    id,
                    sku: String(row.SKU || row.sku || '').trim(),
                    ean: String(row.EAN || row.ean || '').trim(),
                    nome: String(row.nome || row.Nome || '').trim(),
                    preco: normalizarPreco(row.preco ?? row.Preco ?? 0),
                    qtde: Number(row.qtde || row.Qtde || 0),
                    unid: String(row.unid || row.Unid || '').trim(),
                    cat: mapCategoria(row.cat || row.categoria || ''),
                    marca: String(row.marca || row.Marca || '').toUpperCase().trim(),
                    descricaoAnuncio: String(row['Descrição Anuncio'] || row['Descrição  Anuncio'] || row.descricaoAnuncio || '').trim(),
                    img: imgs[0] || '',
                    imgs
                };
            }).filter(Boolean);

            log('Enviando para o banco: ' + produtos.length);
            const res = await fetch('/produtos_import.php', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ produtos })
            });
            const out = await res.json().catch(()=> ({}));
            if(!res.ok || !out.ok) throw new Error(out.erro || 'Falha ao importar');

            log('Importação concluída. Importados: ' + out.importados + ' | Falhas: ' + out.falhas);
        }

        document.getElementById('btn-importar').addEventListener('click', () => {
            importar().catch(e => log('Erro: ' + (e && e.message ? e.message : String(e))));
        });
    </script>
</body>
</html>

