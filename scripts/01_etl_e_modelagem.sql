--SQLQuery6 - Código ETL
CREATE OR REPLACE TABLE workspace.default.precos_limpo AS
WITH tipado AS (
  SELECT
    LEFT(SHA2(TRIM(`CNPJ da Revenda`), 256), 16) AS id_posto,
    UPPER(TRIM(`Regiao - Sigla`)) AS regiao,
    UPPER(TRIM(`Estado - Sigla`)) AS estado,
    UPPER(TRIM(Municipio))        AS municipio,
    UPPER(TRIM(Produto))          AS produto,
    `Data da Coleta`              AS data_coleta, -- Já vimos no Describe que está como DATE
    CAST(REPLACE(`Valor de Venda`, ',', '.') AS DECIMAL(8,3)) AS valor_venda,
    TRIM(`Unidade de Medida`)     AS unidade_medida,
    COALESCE(UPPER(TRIM(Bandeira)), 'NAO INFORMADA') AS bandeira
  FROM workspace.default.precos_semestrais_automotivos_2026_01
),
ranqueado AS (
  -- Esse comando numera as linhas. Se tiver um posto com o mesmo produto no mesmo dia,
  -- ele recebe o número 1, a cópia recebe o 2, etc.
  SELECT *, ROW_NUMBER() OVER (PARTITION BY id_posto, produto, data_coleta ORDER BY valor_venda) AS rn
  FROM tipado
)
-- Aqui nós selecionamos apenas as linhas de número 1 (excluindo as cópias)
SELECT id_posto, regiao, estado, municipio, produto, data_coleta, valor_venda, unidade_medida, bandeira
FROM ranqueado WHERE rn = 1;

--SQLQuery7 - Tabela Dimensão de Data
CREATE OR REPLACE TABLE workspace.default.dim_data AS
SELECT DISTINCT 
  data_coleta AS id_data,
  YEAR(data_coleta) AS ano,
  MONTH(data_coleta) AS mes,
  WEEKOFYEAR(data_coleta) AS semana_ano
FROM workspace.default.precos_limpo;

--SQLQuery8 - Tabela Dimensão de Localidade
CREATE OR REPLACE TABLE workspace.default.dim_local AS
SELECT DISTINCT 
  -- Cria um ID único juntando Estado e Município
  MD5(CONCAT(estado, municipio)) AS id_local, 
  regiao,
  estado,
  municipio
FROM workspace.default.precos_limpo;

--SQLQuery9 - Tabela Dimensão de Produto
CREATE OR REPLACE TABLE workspace.default.dim_produto AS
SELECT DISTINCT 
  MD5(produto) AS id_produto,
  produto,
  unidade_medida
FROM workspace.default.precos_limpo;

--SQLQuery10 - Tabela Dimensão de Bandeira
CREATE OR REPLACE TABLE workspace.default.dim_bandeira AS
SELECT DISTINCT 
  MD5(bandeira) AS id_bandeira,
  bandeira
FROM workspace.default.precos_limpo;

--SQLQuery11 - Tabela Fato
CREATE OR REPLACE TABLE workspace.default.fato_precos AS
SELECT 
  p.data_coleta AS id_data,
  MD5(CONCAT(p.estado, p.municipio)) AS id_local,
  MD5(p.produto) AS id_produto,
  MD5(p.bandeira) AS id_bandeira,
  p.id_posto,
  p.valor_venda
FROM workspace.default.precos_limpo p;