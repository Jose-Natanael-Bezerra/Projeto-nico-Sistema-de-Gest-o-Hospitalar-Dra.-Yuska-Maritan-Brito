-- Cole este bloco inteiro no painel ESQUERDO (Schema SQL) do db-fiddle
-- Selecione: PostgreSQL 16

DROP TABLE IF EXISTS ESCALA CASCADE;
DROP TABLE IF EXISTS PROCEDIMENTO_REALIZADO CASCADE;
DROP TABLE IF EXISTS ATENDIMENTO CASCADE;
DROP TABLE IF EXISTS PROCEDIMENTO CASCADE;
DROP TABLE IF EXISTS UNIDADE CASCADE;
DROP TABLE IF EXISTS PRECEPTOR CASCADE;
DROP TABLE IF EXISTS RESIDENTE CASCADE;
DROP TABLE IF EXISTS PROFISSIONAL CASCADE;
DROP TABLE IF EXISTS PACIENTE CASCADE;
DROP TABLE IF EXISTS PESSOA CASCADE;

CREATE TABLE PESSOA (
    id_pessoa       SERIAL       PRIMARY KEY,
    nome            VARCHAR(150) NOT NULL,
    cpf             CHAR(11)     NOT NULL UNIQUE CHECK (cpf ~ '^[0-9]{11}$'),
    data_nascimento DATE         NOT NULL,
    is_flamengo     BOOLEAN      NOT NULL DEFAULT FALSE,
    telefone        VARCHAR(20)
);

CREATE TABLE PACIENTE (
    id_pessoa       INTEGER PRIMARY KEY REFERENCES PESSOA(id_pessoa) ON DELETE CASCADE,
    num_convenio    VARCHAR(50),
    alergias        TEXT,
    grupo_sanguineo VARCHAR(5) CHECK (grupo_sanguineo IN ('A+','A-','B+','B-','AB+','AB-','O+','O-'))
);

CREATE TABLE PROFISSIONAL (
    id_pessoa     INTEGER      PRIMARY KEY REFERENCES PESSOA(id_pessoa) ON DELETE CASCADE,
    crm           VARCHAR(20)  NOT NULL UNIQUE,
    data_admissao DATE         NOT NULL,
    especialidade VARCHAR(100) NOT NULL
);

CREATE TABLE PRECEPTOR (
    id_profissional INTEGER    PRIMARY KEY REFERENCES PROFISSIONAL(id_pessoa) ON DELETE CASCADE,
    titulacao       VARCHAR(20) NOT NULL CHECK (titulacao IN ('especialista','mestre','doutor','livre-docente','professor titular'))
);

CREATE TABLE RESIDENTE (
    id_profissional INTEGER   PRIMARY KEY REFERENCES PROFISSIONAL(id_pessoa) ON DELETE CASCADE,
    ano_residencia  VARCHAR(2) NOT NULL CHECK (ano_residencia IN ('R1','R2','R3'))
);

CREATE TABLE UNIDADE (
    id_unidade        SERIAL       PRIMARY KEY,
    nome              VARCHAR(100) NOT NULL,
    tipo              VARCHAR(15)  NOT NULL CHECK (tipo IN ('Enfermaria','UTI','Pronto-Socorro','Ambulatorio')),
    capacidade_leitos INTEGER      NOT NULL CHECK (capacidade_leitos > 0)
);

CREATE TABLE PROCEDIMENTO (
    id_procedimento     SERIAL       PRIMARY KEY,
    codigo              VARCHAR(20)  NOT NULL UNIQUE,
    nome                VARCHAR(150) NOT NULL,
    tempo_medio_minutos INTEGER      NOT NULL CHECK (tempo_medio_minutos > 0),
    nivel_risco         VARCHAR(5)   NOT NULL DEFAULT 'BAIXO' CHECK (nivel_risco IN ('BAIXO','MEDIO','ALTO'))
);

CREATE TABLE ATENDIMENTO (
    id_atendimento  SERIAL    PRIMARY KEY,
    data_hora       TIMESTAMP NOT NULL,
    duracao_minutos INTEGER   NOT NULL CHECK (duracao_minutos > 0),
    id_paciente     INTEGER   NOT NULL REFERENCES PACIENTE(id_pessoa),
    id_residente    INTEGER   NOT NULL REFERENCES RESIDENTE(id_profissional),
    id_preceptor    INTEGER   NOT NULL REFERENCES PRECEPTOR(id_profissional)
);

CREATE TABLE PROCEDIMENTO_REALIZADO (
    id_atendimento     INTEGER NOT NULL REFERENCES ATENDIMENTO(id_atendimento),
    id_procedimento    INTEGER NOT NULL REFERENCES PROCEDIMENTO(id_procedimento),
    quantidade         INTEGER NOT NULL DEFAULT 1 CHECK (quantidade > 0),
    tempo_real_minutos INTEGER NOT NULL CHECK (tempo_real_minutos > 0),
    observacao         TEXT,
    faturado           BOOLEAN NOT NULL DEFAULT FALSE,
    PRIMARY KEY (id_atendimento, id_procedimento)
);

CREATE TABLE ESCALA (
    id_escala    SERIAL      PRIMARY KEY,
    id_unidade   INTEGER     NOT NULL REFERENCES UNIDADE(id_unidade),
    dia_semana   VARCHAR(10) NOT NULL CHECK (dia_semana IN ('segunda','terca','quarta','quinta','sexta','sabado','domingo')),
    turno        VARCHAR(5)  NOT NULL CHECK (turno IN ('manha','tarde','noite')),
    id_residente INTEGER     NOT NULL REFERENCES RESIDENTE(id_profissional),
    id_preceptor INTEGER     NOT NULL REFERENCES PRECEPTOR(id_profissional),
    UNIQUE (id_unidade, dia_semana, turno, id_residente)
);

-- DADOS DE TESTE
INSERT INTO PESSOA (nome, cpf, data_nascimento, is_flamengo, telefone) VALUES
  ('Camila Ferreira Duarte',     '04512378901', '1990-03-14', TRUE,  '(21) 98001-1111'),
  ('Rodrigo Menezes Leal',       '15623489012', '1985-07-22', FALSE, '(21) 97002-2222'),
  ('Beatriz Tavares Nogueira',   '26734590123', '2000-11-05', TRUE,  '(21) 96003-3333'),
  ('Fernando Alves Correa',      '37845601234', '1978-01-30', FALSE, '(21) 95004-4444'),
  ('Larissa Pinto Cavalcanti',   '48956712345', '1995-06-18', TRUE,  '(21) 94005-5555'),
  ('Thiago Moraes Cardoso',      '50167823456', '1993-09-09', FALSE, '(21) 93006-6666'),
  ('Juliana Souza Meireles',     '61278934567', '1994-02-25', TRUE,  '(21) 92007-7777'),
  ('Paulo Henrique Bittencourt', '72389045678', '1992-12-03', FALSE, '(21) 91008-8888'),
  ('Ana Clara Rezende',          '83490156789', '1996-04-17', TRUE,  '(21) 90009-9999'),
  ('Gustavo Faria Pimentel',     '94501267890', '1993-08-11', FALSE, '(21) 89010-0000'),
  ('Dra. Marcia Lima Barbosa',   '05612378901', '1975-05-20', FALSE, '(21) 88011-1111'),
  ('Dr. Roberto Cunha Silveira', '16723489012', '1970-11-14', TRUE,  '(21) 87012-2222'),
  ('Dra. Fernanda Rocha Assis',  '27834590123', '1968-07-07', FALSE, '(21) 86013-3333'),
  ('Dr. Marcelo Vieira Nunes',   '38945601234', '1972-03-28', FALSE, '(21) 85014-4444'),
  ('Dra. Patricia Gomes Ramos',  '49056712345', '1965-09-02', TRUE,  '(21) 84015-5555');

INSERT INTO PACIENTE (id_pessoa, num_convenio, alergias, grupo_sanguineo) VALUES
  (1, 'UNIMED-00234',  'Dipirona',           'A+'),
  (2, 'BRADESCO-0455', NULL,                 'O-'),
  (3, 'SULAMERICA-77', 'Penicilina, Sulfa',  'B+'),
  (4, NULL,            'Latex',              'AB+'),
  (5, 'AMIL-10091',    NULL,                 'O+');

INSERT INTO PROFISSIONAL (id_pessoa, crm, data_admissao, especialidade) VALUES
  ( 6, 'CRM-RJ-990001', '2022-03-01', 'Clinica Medica'),
  ( 7, 'CRM-RJ-990002', '2022-03-01', 'Cirurgia Geral'),
  ( 8, 'CRM-RJ-990003', '2023-03-01', 'Pediatria'),
  ( 9, 'CRM-RJ-990004', '2023-03-01', 'Ortopedia'),
  (10, 'CRM-RJ-990005', '2024-03-01', 'Neurologia'),
  (11, 'CRM-RJ-110001', '2010-01-15', 'Cardiologia'),
  (12, 'CRM-RJ-110002', '2008-06-10', 'Cirurgia Geral'),
  (13, 'CRM-RJ-110003', '2005-09-20', 'Clinica Medica'),
  (14, 'CRM-RJ-110004', '2012-04-05', 'Ortopedia'),
  (15, 'CRM-RJ-110005', '2003-11-30', 'Neurologia');

INSERT INTO RESIDENTE (id_profissional, ano_residencia) VALUES
  ( 6, 'R2'), ( 7, 'R3'), ( 8, 'R1'), ( 9, 'R2'), (10, 'R1');

INSERT INTO PRECEPTOR (id_profissional, titulacao) VALUES
  (11, 'doutor'), (12, 'mestre'), (13, 'doutor'), (14, 'especialista'), (15, 'livre-docente');

INSERT INTO UNIDADE (nome, tipo, capacidade_leitos) VALUES
  ('Enfermaria Geral A', 'Enfermaria',    30),
  ('UTI Adulto',         'UTI',           10),
  ('Pronto-Socorro',     'Pronto-Socorro', 20);

INSERT INTO PROCEDIMENTO (codigo, nome, tempo_medio_minutos, nivel_risco) VALUES
  ('PROC-001', 'Sutura simples',               20, 'BAIXO'),
  ('PROC-002', 'Coleta de sangue',             10, 'BAIXO'),
  ('PROC-003', 'Aplicacao de medicacao EV',    15, 'MEDIO'),
  ('PROC-004', 'Intubacao orotraqueal',         25, 'ALTO'),
  ('PROC-005', 'Curativo complexo',            30, 'MEDIO'),
  ('PROC-006', 'Puncao lombar',               45, 'ALTO'),
  ('PROC-007', 'Eletrocardiograma',            15, 'BAIXO'),
  ('PROC-008', 'Sondagem vesical',             20, 'MEDIO'),
  ('PROC-009', 'Drenagem de abscesso',         40, 'ALTO'),
  ('PROC-010', 'Administracao de hemoderivado',60, 'ALTO'),
  ('PROC-011', 'Nebulizacao',                  20, 'BAIXO'),
  ('PROC-012', 'Cateterismo venoso central',   50, 'ALTO');

INSERT INTO ATENDIMENTO (data_hora, duracao_minutos, id_paciente, id_residente, id_preceptor) VALUES
  ('2025-06-02 08:15:00', 45, 1,  6, 11),
  ('2025-06-05 14:30:00', 60, 2,  7, 12),
  ('2025-06-10 09:00:00', 30, 3,  8, 13),
  ('2025-06-15 16:45:00', 90, 4,  9, 14),
  ('2025-06-18 11:20:00', 50, 5, 10, 15),
  ('2025-07-01 08:00:00', 40, 1,  7, 11),
  ('2025-07-03 13:10:00', 55, 2,  6, 13),
  ('2025-07-08 17:00:00', 35, 3,  9, 12),
  ('2025-07-12 10:30:00', 70, 4,  8, 14),
  ('2025-07-20 15:00:00', 80, 5,  6, 15);

INSERT INTO PROCEDIMENTO_REALIZADO (id_atendimento, id_procedimento, quantidade, tempo_real_minutos, observacao, faturado) VALUES
  (1,  1, 1, 22, 'Sutura sem intercorrencias',            FALSE),
  (1,  2, 2, 12, 'Coleta duplicada por hemolise',         FALSE),
  (2,  3, 1, 18, NULL,                                    TRUE),
  (2,  4, 1, 30, 'Intubacao com suporte de capnografia',  FALSE),
  (3,  5, 1, 35, 'Curativo em membro inferior',           FALSE),
  (3, 11, 1, 22, NULL,                                    TRUE),
  (4,  7, 1, 15, 'ECG com alteracao de repolarizacao',    FALSE),
  (4,  8, 1, 25, NULL,                                    FALSE),
  (5,  9, 1, 45, 'Drenagem de abscesso axilar direito',   FALSE),
  (5, 10, 1, 65, 'Transfusao 2 unidades de concentrado',  FALSE),
  (6,  2, 1, 10, NULL,                                    FALSE),
  (7,  3, 2, 20, 'Segunda dose administrada',             FALSE),
  (8,  1, 1, 18, NULL,                                    TRUE),
  (9,  6, 1, 50, 'Puncao L4-L5 sem intercorrencias',      FALSE),
  (10,12, 1, 55, 'CVC em veia subclavia direita',         FALSE);

INSERT INTO ESCALA (id_unidade, dia_semana, turno, id_residente, id_preceptor) VALUES
  (1, 'segunda', 'manha',  6, 11),
  (1, 'segunda', 'tarde',  7, 12),
  (1, 'terca',   'manha',  8, 13),
  (2, 'segunda', 'manha',  9, 14),
  (2, 'terca',   'tarde', 10, 15),
  (3, 'quarta',  'noite',  6, 13),
  (3, 'quinta',  'manha',  7, 11),
  (1, 'sexta',   'tarde',  9, 12),
  (2, 'sabado',  'noite',  8, 15),
  (3, 'domingo', 'manha', 10, 14);
