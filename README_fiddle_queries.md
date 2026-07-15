--1- No site https://www.db-fiddle.com/ mude a linguagem para PostgreSQL v16 
       
--2- Adicione o arquivo fiddle_schema no painel esquerdo do site fiddle chamado Schema
SQL
       
-- Execute cada secao separadamente colando no painel direito do fiddle chamado query SQL e clicando em "Run" após colar.

-- CRUD 1: Verificar existencia e inserir atendimento
SELECT EXISTS(SELECT 1 FROM PACIENTE  WHERE id_pessoa       = 1) AS paciente_ok,
       EXISTS(SELECT 1 FROM RESIDENTE WHERE id_profissional  = 8) AS residente_ok,
       EXISTS(SELECT 1 FROM PRECEPTOR WHERE id_profissional  = 13) AS preceptor_ok;

-- CRUD 2: Atendimentos de um paciente ordenados por data (id_paciente = 1)
SELECT a.id_atendimento,
       a.data_hora,
       a.duracao_minutos,
       pe_pac.nome          AS paciente,
       pe_res.nome          AS residente,
       res.ano_residencia,
       pe_pre.nome          AS preceptor
FROM ATENDIMENTO a
JOIN PACIENTE    pac    ON pac.id_pessoa       = a.id_paciente
JOIN PESSOA      pe_pac ON pe_pac.id_pessoa    = pac.id_pessoa
JOIN RESIDENTE   res    ON res.id_profissional = a.id_residente
JOIN PESSOA      pe_res ON pe_res.id_pessoa    = res.id_profissional
JOIN PRECEPTOR   pre    ON pre.id_profissional = a.id_preceptor
JOIN PESSOA      pe_pre ON pe_pre.id_pessoa    = pre.id_profissional
WHERE a.id_paciente = 1
ORDER BY a.data_hora;

-- CRUD 3: Procedimentos realizados em um atendimento (id_atendimento = 2)
SELECT p.codigo,
       p.nome              AS procedimento,
       pr.quantidade,
       pr.tempo_real_minutos,
       pr.observacao,
       p.nivel_risco
FROM PROCEDIMENTO_REALIZADO pr
JOIN PROCEDIMENTO p ON p.id_procedimento = pr.id_procedimento
WHERE pr.id_atendimento = 2
ORDER BY p.nome;

-- CRUD 4: Atualizar convenio e alergias de um paciente (id_paciente = 1)
UPDATE PACIENTE
SET num_convenio = 'UNIMED-99999',
    alergias     = 'Dipirona, AAS'
WHERE id_pessoa = 1;

SELECT pe.nome, p.num_convenio, p.alergias, p.grupo_sanguineo
FROM PACIENTE p
JOIN PESSOA pe ON pe.id_pessoa = p.id_pessoa
WHERE p.id_pessoa = 1;

-- CRUD 5: Remover procedimento nao faturado (atendimento=1, procedimento=2, faturado=FALSE)
DELETE FROM PROCEDIMENTO_REALIZADO
WHERE id_atendimento  = 1
  AND id_procedimento = 2
  AND faturado = FALSE;

-- Tentativa de remover procedimento ja faturado (deve retornar 0 linhas deletadas)
DELETE FROM PROCEDIMENTO_REALIZADO
WHERE id_atendimento  = 2
  AND id_procedimento = 3
  AND faturado = FALSE;

-- CRUD 6: Tempo medio de duracao dos atendimentos por residente
SELECT pe.nome                           AS residente,
       r.ano_residencia,
       COUNT(a.id_atendimento)           AS total_atendimentos,
       ROUND(AVG(a.duracao_minutos), 2)  AS media_duracao_minutos
FROM RESIDENTE r
JOIN PROFISSIONAL prof ON prof.id_pessoa    = r.id_profissional
JOIN PESSOA       pe   ON pe.id_pessoa      = prof.id_pessoa
LEFT JOIN ATENDIMENTO a ON a.id_residente   = r.id_profissional
GROUP BY pe.nome, r.ano_residencia
ORDER BY media_duracao_minutos DESC NULLS LAST;

-- ANALITICA 1: Ranking de residentes por numero de atendimentos
SELECT RANK() OVER (ORDER BY COUNT(a.id_atendimento) DESC) AS posicao,
       pe.nome                                              AS residente,
       r.ano_residencia,
       COUNT(a.id_atendimento)                             AS total_atendimentos
FROM RESIDENTE r
JOIN PROFISSIONAL prof ON prof.id_pessoa   = r.id_profissional
JOIN PESSOA       pe   ON pe.id_pessoa     = prof.id_pessoa
LEFT JOIN ATENDIMENTO a ON a.id_residente  = r.id_profissional
GROUP BY pe.nome, r.ano_residencia
ORDER BY total_atendimentos DESC, pe.nome;

-- ANALITICA 2: Preceptores com mais de 2 atendimentos em junho/2025
-- (HAVING > 5 retorna vazio nos dados de teste; use > 1 para ver resultado)
SELECT pe.nome                         AS preceptor,
       pre.titulacao,
       COUNT(a.id_atendimento)         AS total_supervisionados,
       TO_CHAR(a.data_hora,'MM/YYYY') AS mes_referencia
FROM PRECEPTOR pre
JOIN PROFISSIONAL prof ON prof.id_pessoa   = pre.id_profissional
JOIN PESSOA       pe   ON pe.id_pessoa     = prof.id_pessoa
JOIN ATENDIMENTO  a    ON a.id_preceptor   = pre.id_profissional
WHERE DATE_TRUNC('month', a.data_hora) = DATE_TRUNC('month', DATE '2025-06-01')
GROUP BY pe.nome, pre.titulacao, TO_CHAR(a.data_hora,'MM/YYYY')
HAVING COUNT(a.id_atendimento) > 1
ORDER BY total_supervisionados DESC;

-- ANALITICA 3: Plantoes escalados por residente em cada unidade
SELECT u.nome                        AS unidade,
       pe.nome                       AS residente,
       r.ano_residencia,
       COUNT(e.id_escala)            AS plantoes_escalados
FROM ESCALA e
JOIN UNIDADE     u    ON u.id_unidade           = e.id_unidade
JOIN RESIDENTE   r    ON r.id_profissional      = e.id_residente
JOIN PROFISSIONAL prof ON prof.id_pessoa        = r.id_profissional
JOIN PESSOA       pe   ON pe.id_pessoa          = prof.id_pessoa
GROUP BY u.nome, pe.nome, r.ano_residencia
ORDER BY u.nome, plantoes_escalados DESC;

-- ANALITICA 4: Pacientes que NUNCA fizeram procedimento de risco ALTO
SELECT pe.id_pessoa,
       pe.nome           AS paciente,
       pe.is_flamengo,
       pac.grupo_sanguineo,
       pac.num_convenio
FROM PACIENTE pac
JOIN PESSOA pe ON pe.id_pessoa = pac.id_pessoa
WHERE pac.id_pessoa NOT IN (
    SELECT DISTINCT a.id_paciente
    FROM ATENDIMENTO a
    JOIN PROCEDIMENTO_REALIZADO pr ON pr.id_atendimento = a.id_atendimento
    JOIN PROCEDIMENTO           p  ON p.id_procedimento  = pr.id_procedimento
    WHERE p.nivel_risco = 'ALTO'
)
ORDER BY pe.nome;
