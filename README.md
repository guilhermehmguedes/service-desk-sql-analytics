# Indicadores de Service Desk com SQL

Projeto de portfólio que analisa dados **fictícios** de chamados de suporte de TI usando **SQL Server (T-SQL)**. O objetivo é responder perguntas de negócio de uma operação de service desk: volume, prazo, cumprimento de SLA, desempenho por analista e evolução ao longo do tempo.

> Os dados foram gerados por script para fins de estudo e não representam nenhuma empresa real.

## Perguntas de negócio respondidas

1. Como os chamados se distribuem por faixa de tempo de resolução?
2. Qual o volume de chamados fechados e em aberto por setor?
3. Qual setor cumpre melhor o SLA (resolução em até 2 dias)?
4. Quem são os 3 analistas com mais chamados no prazo em cada setor?
5. Quais setores estão abaixo da média de SLA?
6. Qual o tempo médio de resolução por analista?
7. Qual o intervalo entre chamados consecutivos de cada analista?
8. Quantos chamados cada analista atendeu (incluindo quem não atendeu nenhum)?
9. Como evolui o volume mensal (acumulado e variação)?
10. Existem chamados possivelmente duplicados?
11. Qual a mediana de dias de resolução por setor?

## Estrutura

```
sql/
  01_schema.sql      -- criação das tabelas
  02_dados.sql       -- dados fictícios
  03_consultas.sql   -- consultas de indicadores (T-SQL)
```

Tabelas: `setores`, `analistas` e `chamados` (628 chamados, de 2026-01 a 2026-11).

## Como executar

Requer SQL Server 2016 ou superior (a versão gratuita Express também serve) e o SSMS ou o Azure Data Studio.

1. Crie um banco de dados vazio (por exemplo, `ServiceDesk`) e selecione-o.
2. Execute `sql/01_schema.sql`, depois `sql/02_dados.sql`.
3. Execute as consultas de `sql/03_consultas.sql`, uma de cada vez.

**Conferência rápida:** após carregar os dados, `SELECT COUNT(*) FROM chamados;` deve devolver 628, e `SELECT COUNT(*) FROM chamados WHERE data_fechamento IS NULL;` deve devolver 35.

## Recursos de SQL utilizados

`JOIN` e `LEFT JOIN`, CTEs encadeadas (`WITH`), `CASE WHEN`, funções de janela (`RANK`, `LAG`, `SUM() OVER`, `COUNT() OVER`), `HAVING`, tratamento de `NULL`, mediana, `DATEDIFF`, `PERCENTILE_CONT` e conversão de tipos (`CAST`).

## Casos de borda nos dados

Chamados em aberto (`NULL` em `data_fechamento`), um mês sem chamados, analistas sem nenhum chamado e chamados com a mesma combinação de analista, categoria e dia. Cada um deles aparece em pelo menos uma consulta.

## Principais resultados (dados fictícios)

- Dos 628 chamados, 35 continuam em aberto.
- A taxa geral de cumprimento do SLA (até 2 dias) entre os chamados fechados é de 65.09%.

| Setor | Chamados fechados | Cumprimento do SLA |
|---|---|---|
| Sistemas ERP | 125 | 74.4% |
| Seguranca | 72 | 72.22% |
| Service Desk N1 | 115 | 67.83% |
| Atendimento Presencial | 65 | 67.69% |
| Redes | 93 | 58.06% |
| Infraestrutura | 123 | 52.85% |

- Os setores abaixo da média de SLA são os que lidam com demandas de maior complexidade (Infraestrutura e Redes), o que é coerente com a forma como os dados foram simulados.

## Limitações e próximos passos

- O volume de setembro aparece bem acima dos demais meses porque, na geração dos dados, os chamados que cairiam em agosto foram remanejados para setembro (agosto ficou propositalmente sem chamados, para testar o caso de mês faltante). Em dados reais, um pico assim pediria investigação.
- A consulta mensal não mostra meses sem chamados. Para uma série contínua, o próximo passo é juntar com uma tabela de calendário.
- Em casos de empate (consultas 4, 6 e 8), o desempate é feito pelo nome do analista, para o resultado ser sempre o mesmo.
- A média de resolução considera apenas chamados já fechados, então não captura o efeito dos chamados parados.
- Próximo passo: dashboard no Power BI com SLA, backlog e tempo de resolução e, depois, uma análise em Python com pandas.

## Autor

Guilherme Guedes · [LinkedIn](https://www.linkedin.com/in/guilherme-henrique-guedes/)
