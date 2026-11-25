-- Conferencia: roda as 11 consultas de uma vez, com um titulo antes de cada resultado.
-- Use Ctrl+T (Resultados em Texto) antes de executar para juntar tudo em uma unica aba.

SELECT '=== Consulta 1: Distribuicao dos chamados por faixa de prazo de resolucao ===' AS consulta;
-- 1. Distribuicao dos chamados por faixa de prazo de resolucao
-- Pergunta: quantos chamados caem em cada faixa de tempo de resolucao?
WITH classificados AS (
    SELECT
        id,
        CASE
            WHEN data_fechamento IS NULL THEN 'Em aberto'
            WHEN DATEDIFF(DAY, data_abertura, data_fechamento) <= 1 THEN 'Ate 1 dia'
            WHEN DATEDIFF(DAY, data_abertura, data_fechamento) <= 3 THEN '2 a 3 dias'
            ELSE 'Acima de 3 dias'
        END AS prazo
    FROM chamados
)
SELECT prazo, COUNT(*) AS quantidade
FROM classificados
GROUP BY prazo
ORDER BY quantidade DESC;

SELECT '=== Consulta 2: Chamados fechados e abertos por setor ===' AS consulta;
-- 2. Chamados fechados e abertos por setor
-- Pergunta: qual o volume de chamados fechados e em aberto em cada setor?
SELECT
    s.nome AS setor,
    SUM(CASE WHEN c.data_fechamento IS NOT NULL THEN 1 ELSE 0 END) AS chamados_fechados,
    SUM(CASE WHEN c.data_fechamento IS NULL THEN 1 ELSE 0 END)     AS chamados_abertos
FROM chamados c
JOIN setores s ON s.id = c.setor
GROUP BY s.nome
ORDER BY s.nome;

SELECT '=== Consulta 3: Taxa de cumprimento de SLA por setor (SLA = ate 2 dias) ===' AS consulta;
-- 3. Taxa de cumprimento de SLA por setor (SLA = ate 2 dias)
-- Pergunta: qual percentual dos chamados fechados foi resolvido dentro do SLA?
SELECT
    s.nome AS setor,
    COUNT(*) AS total_fechados,
    SUM(CASE WHEN DATEDIFF(DAY, c.data_abertura, c.data_fechamento) <= 2 THEN 1 ELSE 0 END) AS dentro_sla,
    CAST(ROUND(100.0 * SUM(CASE WHEN DATEDIFF(DAY, c.data_abertura, c.data_fechamento) <= 2 THEN 1 ELSE 0 END)
          / NULLIF(COUNT(*), 0), 2) AS DECIMAL(10,2)) AS taxa_sla
FROM chamados c
JOIN setores s ON s.id = c.setor
WHERE c.data_fechamento IS NOT NULL
GROUP BY s.nome
ORDER BY taxa_sla DESC;

SELECT '=== Consulta 4: Top 3 analistas por chamados no prazo em cada setor ===' AS consulta;
-- 4. Top 3 analistas por chamados no prazo em cada setor
-- Pergunta: quem sao os 3 analistas com mais chamados resolvidos dentro do SLA por setor? (RANK mantem empates)
WITH no_prazo AS (
    SELECT
        c.setor,
        c.analista,
        CASE WHEN c.data_fechamento IS NOT NULL
                  AND DATEDIFF(DAY, c.data_abertura, c.data_fechamento) <= 2
             THEN 1 ELSE 0 END AS dentro_prazo
    FROM chamados c
),
por_analista AS (
    SELECT setor, analista, SUM(dentro_prazo) AS total_no_prazo
    FROM no_prazo
    GROUP BY setor, analista
),
ranking AS (
    SELECT setor, analista, total_no_prazo,
           RANK() OVER (PARTITION BY setor ORDER BY total_no_prazo DESC) AS posicao
    FROM por_analista
)
SELECT s.nome AS setor, a.nome AS analista, r.total_no_prazo, r.posicao
FROM ranking r
JOIN setores s ON s.id = r.setor
JOIN analistas a ON a.id = r.analista
WHERE r.posicao <= 3
ORDER BY s.nome, r.posicao, a.nome;

SELECT '=== Consulta 5: Setores com taxa de SLA abaixo da media dos setores ===' AS consulta;
-- 5. Setores com taxa de SLA abaixo da media dos setores
-- Pergunta: quais setores estao abaixo da media? (media das taxas dos setores, nao a taxa global)
WITH sla_setor AS (
    SELECT
        s.nome AS setor,
        CAST(ROUND(100.0 * SUM(CASE WHEN DATEDIFF(DAY, c.data_abertura, c.data_fechamento) <= 2 THEN 1 ELSE 0 END)
              / NULLIF(COUNT(*), 0), 2) AS DECIMAL(10,2)) AS taxa_sla
    FROM chamados c
    JOIN setores s ON s.id = c.setor
    WHERE c.data_fechamento IS NOT NULL
    GROUP BY s.nome
)
SELECT setor, taxa_sla
FROM sla_setor
WHERE taxa_sla < (SELECT AVG(taxa_sla) FROM sla_setor)
ORDER BY taxa_sla;

SELECT '=== Consulta 6: Tempo medio de resolucao por analista ===' AS consulta;
-- 6. Tempo medio de resolucao por analista
-- Pergunta: qual a media de dias de resolucao por analista? (AVG ignora chamados em aberto)
SELECT
    a.nome AS analista,
    CAST(ROUND(AVG(1.0 * DATEDIFF(DAY, c.data_abertura, c.data_fechamento)), 2) AS DECIMAL(10,2)) AS media_dias_resolucao,
    COUNT(*) - COUNT(c.data_fechamento) AS chamados_em_aberto
FROM chamados c
JOIN analistas a ON a.id = c.analista
GROUP BY a.nome
ORDER BY media_dias_resolucao, analista;

SELECT '=== Consulta 7: Intervalo entre chamados consecutivos de cada analista ===' AS consulta;
-- 7. Intervalo entre chamados consecutivos de cada analista
-- Pergunta: quantos dias separam um chamado do anterior, por analista? (LAG)
WITH anteriores AS (
    SELECT
        id, analista, data_abertura,
        LAG(data_abertura) OVER (PARTITION BY analista ORDER BY data_abertura, id) AS abertura_anterior
    FROM chamados
)
SELECT TOP 15
    id, analista, data_abertura, abertura_anterior,
    DATEDIFF(DAY, abertura_anterior, data_abertura) AS intervalo_dias
FROM anteriores
ORDER BY analista, data_abertura, id;

SELECT '=== Consulta 8: Total de chamados por analista, incluindo quem nao tem nenhum ===' AS consulta;
-- 8. Total de chamados por analista, incluindo quem nao tem nenhum
-- Pergunta: quantos chamados cada analista atendeu? (LEFT JOIN mantem analistas sem chamados)
SELECT
    a.id,
    a.nome AS analista,
    s.nome AS setor,
    COUNT(c.id) AS total_chamados
FROM analistas a
LEFT JOIN setores s  ON s.id = a.setor
LEFT JOIN chamados c ON c.analista = a.id
GROUP BY a.id, a.nome, s.nome
ORDER BY total_chamados DESC, a.nome;

SELECT '=== Consulta 9: Chamados abertos por mes, acumulado e variacao ===' AS consulta;
-- 9. Chamados abertos por mes, acumulado e variacao
-- Pergunta: como evolui o volume mensal? Meses sem chamados nao aparecem (limitacao conhecida).
WITH mensais AS (
    SELECT YEAR(data_abertura) AS ano, MONTH(data_abertura) AS mes, COUNT(*) AS total_mes
    FROM chamados
    GROUP BY YEAR(data_abertura), MONTH(data_abertura)
),
indicadores AS (
    SELECT ano, mes, total_mes,
           SUM(total_mes) OVER (ORDER BY ano, mes
                                ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS total_acumulado,
           LAG(total_mes) OVER (ORDER BY ano, mes) AS total_mes_anterior
    FROM mensais
)
SELECT ano, mes, total_mes, total_acumulado, total_mes_anterior,
       total_mes - total_mes_anterior AS variacao
FROM indicadores
ORDER BY ano, mes;

SELECT '=== Consulta 10: Chamados possivelmente duplicados ===' AS consulta;
-- 10. Chamados possivelmente duplicados
-- Pergunta: ha chamados do mesmo analista, categoria e dia? (confirmar com o negocio antes de apagar)
WITH marcados AS (
    SELECT *,
           COUNT(*) OVER (PARTITION BY analista, categoria, CAST(data_abertura AS DATE)) AS qtd
    FROM chamados
)
SELECT TOP 15 id, analista, categoria, data_abertura, qtd
FROM marcados
WHERE qtd > 1
ORDER BY analista, categoria, data_abertura;

SELECT '=== Consulta 11: Mediana de dias de resolucao por setor ===' AS consulta;
-- 11. Mediana de dias de resolucao por setor
-- Pergunta: qual o tempo tipico de resolucao por setor? (a mediana resiste a valores extremos)
WITH tempo AS (
    SELECT setor, CAST(DATEDIFF(DAY, data_abertura, data_fechamento) AS FLOAT) AS dias
    FROM chamados
    WHERE data_fechamento IS NOT NULL
),
medianas AS (
    SELECT setor,
           PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY dias) OVER (PARTITION BY setor) AS mediana_dias
    FROM tempo
)
SELECT DISTINCT s.nome AS setor, m.mediana_dias
FROM medianas m
JOIN setores s ON s.id = m.setor
ORDER BY s.nome;
