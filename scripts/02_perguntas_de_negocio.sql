--SQLQuery13 - Regra dos 70% Etanol-Gasolina
-- Pergunta 1: Regra dos 70% (Em quais estados compensa usar Etanol?)
WITH precos_uf AS (
  SELECT 
    l.estado,
    AVG(CASE WHEN p.produto = 'ETANOL' THEN f.valor_venda END) AS preco_etanol,
    AVG(CASE WHEN p.produto = 'GASOLINA' THEN f.valor_venda END) AS preco_gasolina
  FROM workspace.default.fato_precos f
  JOIN workspace.default.dim_local l ON f.id_local = l.id_local
  JOIN workspace.default.dim_produto p ON f.id_produto = p.id_produto
  GROUP BY l.estado
)
SELECT 
  estado,
  ROUND(preco_etanol, 3) AS preco_medio_etanol,
  ROUND(preco_gasolina, 3) AS preco_medio_gasolina,
  ROUND((preco_etanol / preco_gasolina), 3) AS proporcao,
  CASE WHEN (preco_etanol / preco_gasolina) <= 0.70 THEN 'ETANOL' ELSE 'GASOLINA' END AS melhor_combustivel
FROM precos_uf
WHERE preco_etanol IS NOT NULL AND preco_gasolina IS NOT NULL
ORDER BY proporcao ASC;

--SQLQuery14 - Variação de preços entre Bandeiras (Gasolina)
-- Pergunta 2: Variação de preços entre Bandeiras (Gasolina)
SELECT 
  b.bandeira,
  COUNT(f.valor_venda) AS total_cotacoes,
  ROUND(AVG(f.valor_venda), 3) AS preco_medio,
  ROUND(MAX(f.valor_venda) - MIN(f.valor_venda), 3) AS amplitude_reais
FROM workspace.default.fato_precos f
JOIN workspace.default.dim_bandeira b ON f.id_bandeira = b.id_bandeira
JOIN workspace.default.dim_produto p ON f.id_produto = p.id_produto
WHERE p.produto = 'GASOLINA'
GROUP BY b.bandeira
ORDER BY preco_medio ASC;

--SQLQuery15 - Onde a pesquisa de preços de Gasolina mais compensa (Top 10 Municípios)
-- Pergunta 3: Onde a pesquisa de preços de Gasolina mais compensa? (Top 10 Municípios)
SELECT 
  l.estado,
  l.municipio,
  ROUND(MIN(f.valor_venda), 3) AS preco_minimo,
  ROUND(MAX(f.valor_venda), 3) AS preco_maximo,
  ROUND(MAX(f.valor_venda) - MIN(f.valor_venda), 3) AS diferenca_reais
FROM workspace.default.fato_precos f
JOIN workspace.default.dim_local l ON f.id_local = l.id_local
JOIN workspace.default.dim_produto p ON f.id_produto = p.id_produto
WHERE p.produto = 'GASOLINA'
GROUP BY l.estado, l.municipio
ORDER BY diferenca_reais DESC
LIMIT 10;

--SQLQuery16 - Evolução semanal do preço médio da Gasolina e Diesel
-- Pergunta 4: Evolução semanal do preço médio da Gasolina e Diesel
SELECT 
  d.semana_ano,
  p.produto,
  ROUND(AVG(f.valor_venda), 3) AS preco_medio
FROM workspace.default.fato_precos f
JOIN workspace.default.dim_data d ON f.id_data = d.id_data
JOIN workspace.default.dim_produto p ON f.id_produto = p.id_produto
WHERE p.produto IN ('GASOLINA', 'DIESEL')
GROUP BY d.semana_ano, p.produto
ORDER BY d.semana_ano, p.produto;