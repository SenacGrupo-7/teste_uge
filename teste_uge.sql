--
-- PostgreSQL database dump
--

\restrict p8iEfsY6Mh0EJtdRReRSvbdyFiX5uEqLd5tDfz0qQi3LnDJeLvhtlhWsoHrRSnI

-- Dumped from database version 18.6
-- Dumped by pg_dump version 18.6

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: backup; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA backup;


ALTER SCHEMA backup OWNER TO postgres;

--
-- Name: fn_inserir_diaria(character, smallint, date, character varying, text, numeric, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_inserir_diaria(p_cpf_servidor character, p_id_tipo smallint, p_data_inicial date, p_destino character varying, p_motivo text, p_valor_diaria numeric, p_numero_processo character varying) RETURNS bigint
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_id_processo BIGINT;
    v_id_diaria   BIGINT;
BEGIN

    -- Validação do CPF
    IF NOT EXISTS (
        SELECT 1
        FROM servidores
        WHERE cpf_servidor = p_cpf_servidor
    ) THEN
        RAISE EXCEPTION
            'Servidor CPF % não cadastrado.',
            p_cpf_servidor;
    END IF;

    -- Validação do tipo
    IF NOT EXISTS (
        SELECT 1
        FROM tipos_diaria
        WHERE id_tipo = p_id_tipo
    ) THEN
        RAISE EXCEPTION
            'Tipo de diária % não cadastrado.',
            p_id_tipo;
    END IF;

    -- Localiza ou cria processo
    SELECT id_processo
    INTO v_id_processo
    FROM processos
    WHERE numero_processo = p_numero_processo;

    IF v_id_processo IS NULL THEN

        INSERT INTO processos (
            numero_processo
        )
        VALUES (
            p_numero_processo
        )
        RETURNING id_processo
        INTO v_id_processo;

    END IF;

    -- Insere diária
    INSERT INTO diarias (
        cpf_servidor,
        id_tipo,
        data_inicial,
        destino,
        motivo,
        valor_diaria,
        processo,
        id_processo
    )
    VALUES (
        p_cpf_servidor,
        p_id_tipo,
        p_data_inicial,
        p_destino,
        p_motivo,
        p_valor_diaria,
        p_numero_processo,
        v_id_processo
    )
    RETURNING id_diaria
    INTO v_id_diaria;

    RETURN v_id_diaria;

END;
$$;


ALTER FUNCTION public.fn_inserir_diaria(p_cpf_servidor character, p_id_tipo smallint, p_data_inicial date, p_destino character varying, p_motivo text, p_valor_diaria numeric, p_numero_processo character varying) OWNER TO postgres;

--
-- Name: processar_lancamentos(); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.processar_lancamentos()
    LANGUAGE plpgsql
    AS $$
DECLARE
    r RECORD;
    v_id_processo BIGINT;
BEGIN
    FOR r IN
        SELECT *
        FROM lancamentos
        WHERE processado = FALSE
    LOOP

        -- Cria o processo se nÆo existir
        INSERT INTO processos (numero_processo)
        VALUES (r.processo)
        ON CONFLICT (numero_processo) DO NOTHING;

        -- Obt‚m o ID do processo
        SELECT id_processo
        INTO v_id_processo
        FROM processos
        WHERE numero_processo = r.processo;

        -- Insere a di ria
        INSERT INTO diarias (
            cpf_servidor,
            id_tipo,
            data_inicial,
            destino,
            motivo,
            valor_diaria,
            processo,
            id_processo
        )
        VALUES (
            r.cpf_servidor,
            r.id_tipo,
            r.data_inicial,
            r.destino,
            r.motivo,
            r.valor_diaria,
            r.processo,
            v_id_processo
        );

        -- Insere PD se informado
        IF r.numero_pd IS NOT NULL THEN

            INSERT INTO pagamentos_processo (
                id_processo,
                numero_pd,
                data_pagamento
            )
            VALUES (
                v_id_processo,
                r.numero_pd,
                r.data_pagamento
            );

        END IF;

        -- Marca como processado
        UPDATE lancamentos
        SET processado = TRUE
        WHERE id_lancamento = r.id_lancamento;

    END LOOP;
END;
$$;


ALTER PROCEDURE public.processar_lancamentos() OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: diarias_bkp_20261021; Type: TABLE; Schema: backup; Owner: postgres
--

CREATE TABLE backup.diarias_bkp_20261021 (
    id_diaria bigint,
    cpf_servidor character(11),
    id_tipo smallint,
    data_inicial date,
    destino character varying(100),
    motivo text,
    valor_diaria numeric(12,2),
    processo character varying(30),
    data_cadastro timestamp without time zone,
    id_processo bigint,
    observacao character varying(200),
    numero_pd character varying(30)
);


ALTER TABLE backup.diarias_bkp_20261021 OWNER TO postgres;

--
-- Name: diarias_bkp_20261021_v2; Type: TABLE; Schema: backup; Owner: postgres
--

CREATE TABLE backup.diarias_bkp_20261021_v2 (
    id_diaria bigint,
    cpf_servidor character(11),
    id_tipo smallint,
    data_inicial date,
    destino character varying(100),
    motivo text,
    valor_diaria numeric(12,2),
    processo character varying(30),
    data_cadastro timestamp without time zone,
    id_processo bigint,
    observacao character varying(200),
    numero_pd character varying(30)
);


ALTER TABLE backup.diarias_bkp_20261021_v2 OWNER TO postgres;

--
-- Name: diarias_bkp_auditoria; Type: TABLE; Schema: backup; Owner: postgres
--

CREATE TABLE backup.diarias_bkp_auditoria (
    id_diaria bigint,
    cpf_servidor character(11),
    id_tipo smallint,
    data_inicial date,
    destino character varying(100),
    motivo text,
    valor_diaria numeric(12,2),
    data_cadastro timestamp without time zone,
    id_processo bigint,
    observacao character varying(200),
    numero_pd character varying(30)
);


ALTER TABLE backup.diarias_bkp_auditoria OWNER TO postgres;

--
-- Name: diarias_bkp_limpeza_duplicadas; Type: TABLE; Schema: backup; Owner: postgres
--

CREATE TABLE backup.diarias_bkp_limpeza_duplicadas (
    id_diaria bigint,
    cpf_servidor character(11),
    id_tipo smallint,
    data_inicial date,
    destino character varying(100),
    motivo text,
    valor_diaria numeric(12,2),
    data_cadastro timestamp without time zone,
    id_processo bigint,
    observacao character varying(200),
    numero_pd character varying(30)
);


ALTER TABLE backup.diarias_bkp_limpeza_duplicadas OWNER TO postgres;

--
-- Name: pagamentos_processo_bkp_20261021; Type: TABLE; Schema: backup; Owner: postgres
--

CREATE TABLE backup.pagamentos_processo_bkp_20261021 (
    id_pagamento bigint,
    id_processo bigint,
    numero_pd character varying(30),
    data_pagamento date,
    valor_pagamento numeric(12,2)
);


ALTER TABLE backup.pagamentos_processo_bkp_20261021 OWNER TO postgres;

--
-- Name: pagamentos_processo_bkp_20261021_v2; Type: TABLE; Schema: backup; Owner: postgres
--

CREATE TABLE backup.pagamentos_processo_bkp_20261021_v2 (
    id_pagamento bigint,
    id_processo bigint,
    numero_pd character varying(30),
    data_pagamento date,
    valor_pagamento numeric(12,2)
);


ALTER TABLE backup.pagamentos_processo_bkp_20261021_v2 OWNER TO postgres;

--
-- Name: pagamentos_processo_bkp_auditoria; Type: TABLE; Schema: backup; Owner: postgres
--

CREATE TABLE backup.pagamentos_processo_bkp_auditoria (
    id_pagamento bigint,
    id_processo bigint,
    numero_pd character varying(30),
    data_pagamento date,
    valor_pagamento numeric(12,2),
    id_pd bigint
);


ALTER TABLE backup.pagamentos_processo_bkp_auditoria OWNER TO postgres;

--
-- Name: pds_bkp_20261021_v2; Type: TABLE; Schema: backup; Owner: postgres
--

CREATE TABLE backup.pds_bkp_20261021_v2 (
    id_pd bigint,
    numero_pd character varying(30),
    data_pagamento date,
    valor_pagamento numeric(12,2)
);


ALTER TABLE backup.pds_bkp_20261021_v2 OWNER TO postgres;

--
-- Name: pds_bkp_antes_limpeza; Type: TABLE; Schema: backup; Owner: postgres
--

CREATE TABLE backup.pds_bkp_antes_limpeza (
    id_pd bigint,
    numero_pd character varying(30),
    data_pagamento date,
    valor_pagamento numeric(12,2)
);


ALTER TABLE backup.pds_bkp_antes_limpeza OWNER TO postgres;

--
-- Name: pds_bkp_auditoria; Type: TABLE; Schema: backup; Owner: postgres
--

CREATE TABLE backup.pds_bkp_auditoria (
    id_pd bigint,
    numero_pd character varying(30),
    data_pagamento date
);


ALTER TABLE backup.pds_bkp_auditoria OWNER TO postgres;

--
-- Name: pds_bkp_consolidacao; Type: TABLE; Schema: backup; Owner: postgres
--

CREATE TABLE backup.pds_bkp_consolidacao (
    id_pd bigint,
    numero_pd character varying(30),
    data_pagamento date,
    valor_pagamento numeric(12,2)
);


ALTER TABLE backup.pds_bkp_consolidacao OWNER TO postgres;

--
-- Name: processos_bkp_20261021; Type: TABLE; Schema: backup; Owner: postgres
--

CREATE TABLE backup.processos_bkp_20261021 (
    id_processo bigint,
    numero_processo character varying(30)
);


ALTER TABLE backup.processos_bkp_20261021 OWNER TO postgres;

--
-- Name: processos_bkp_20261021_v2; Type: TABLE; Schema: backup; Owner: postgres
--

CREATE TABLE backup.processos_bkp_20261021_v2 (
    id_processo bigint,
    numero_processo character varying(30)
);


ALTER TABLE backup.processos_bkp_20261021_v2 OWNER TO postgres;

--
-- Name: processos_bkp_auditoria; Type: TABLE; Schema: backup; Owner: postgres
--

CREATE TABLE backup.processos_bkp_auditoria (
    id_processo bigint,
    numero_processo character varying(30)
);


ALTER TABLE backup.processos_bkp_auditoria OWNER TO postgres;

--
-- Name: servidores_bkp_20261021; Type: TABLE; Schema: backup; Owner: postgres
--

CREATE TABLE backup.servidores_bkp_20261021 (
    cpf_servidor character(11),
    nome_servidor character varying(200),
    id_cargo smallint
);


ALTER TABLE backup.servidores_bkp_20261021 OWNER TO postgres;

--
-- Name: servidores_bkp_20261021_v2; Type: TABLE; Schema: backup; Owner: postgres
--

CREATE TABLE backup.servidores_bkp_20261021_v2 (
    cpf_servidor character(11),
    nome_servidor character varying(200),
    id_cargo smallint
);


ALTER TABLE backup.servidores_bkp_20261021_v2 OWNER TO postgres;

--
-- Name: auditoria_log; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.auditoria_log (
    id_log bigint NOT NULL,
    tabela character varying(100) NOT NULL,
    operacao character varying(20) NOT NULL,
    usuario_bd character varying(100) NOT NULL,
    data_evento timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    chave_registro text,
    dados_anteriores jsonb,
    dados_novos jsonb
);


ALTER TABLE public.auditoria_log OWNER TO postgres;

--
-- Name: auditoria_log_id_log_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.auditoria_log_id_log_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.auditoria_log_id_log_seq OWNER TO postgres;

--
-- Name: auditoria_log_id_log_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.auditoria_log_id_log_seq OWNED BY public.auditoria_log.id_log;


--
-- Name: auditoria_migracao; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.auditoria_migracao (
    id bigint NOT NULL,
    data_execucao timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    etapa text,
    status text,
    observacao text
);


ALTER TABLE public.auditoria_migracao OWNER TO postgres;

--
-- Name: auditoria_migracao_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.auditoria_migracao_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.auditoria_migracao_id_seq OWNER TO postgres;

--
-- Name: auditoria_migracao_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.auditoria_migracao_id_seq OWNED BY public.auditoria_migracao.id;


--
-- Name: cargo; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.cargo (
    id_cargo smallint CONSTRAINT cargos_id_cargo_not_null NOT NULL,
    nome_cargo character varying(50) CONSTRAINT cargos_descricao_not_null NOT NULL
);


ALTER TABLE public.cargo OWNER TO postgres;

--
-- Name: cargos_id_cargo_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.cargos_id_cargo_seq
    AS smallint
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.cargos_id_cargo_seq OWNER TO postgres;

--
-- Name: cargos_id_cargo_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.cargos_id_cargo_seq OWNED BY public.cargo.id_cargo;


--
-- Name: diarias; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.diarias (
    id_diaria bigint NOT NULL,
    cpf_servidor character(11) NOT NULL,
    id_tipo smallint NOT NULL,
    data_inicial date NOT NULL,
    destino character varying(100) NOT NULL,
    motivo text NOT NULL,
    valor_diaria numeric(12,2) NOT NULL,
    data_cadastro timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    id_processo bigint NOT NULL,
    observacao character varying(200),
    numero_pd character varying(30),
    CONSTRAINT chk_diarias_cpf CHECK ((cpf_servidor ~ '^[0-9]{11}$'::text)),
    CONSTRAINT ck_destino_nao_vazio CHECK ((TRIM(BOTH FROM destino) <> ''::text)),
    CONSTRAINT ck_motivo_nao_vazio CHECK ((TRIM(BOTH FROM motivo) <> ''::text)),
    CONSTRAINT ck_valor_diaria_positivo CHECK ((valor_diaria > (0)::numeric))
);


ALTER TABLE public.diarias OWNER TO postgres;

--
-- Name: diarias_id_diaria_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.diarias_id_diaria_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.diarias_id_diaria_seq OWNER TO postgres;

--
-- Name: diarias_id_diaria_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.diarias_id_diaria_seq OWNED BY public.diarias.id_diaria;


--
-- Name: lancamentos; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.lancamentos (
    id_lancamento bigint NOT NULL,
    cpf_servidor character(11) NOT NULL,
    id_tipo smallint NOT NULL,
    data_inicial date NOT NULL,
    destino character varying(100) NOT NULL,
    motivo text NOT NULL,
    valor_diaria numeric(12,2) NOT NULL,
    processo character varying(30) NOT NULL,
    numero_pd character varying(30),
    data_pagamento date,
    processado boolean DEFAULT false
);


ALTER TABLE public.lancamentos OWNER TO postgres;

--
-- Name: lancamentos_id_lancamento_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.lancamentos_id_lancamento_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.lancamentos_id_lancamento_seq OWNER TO postgres;

--
-- Name: lancamentos_id_lancamento_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.lancamentos_id_lancamento_seq OWNED BY public.lancamentos.id_lancamento;


--
-- Name: pagamentos_processo; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pagamentos_processo (
    id_pagamento bigint NOT NULL,
    id_processo bigint NOT NULL,
    numero_pd character varying(30) NOT NULL,
    data_pagamento date NOT NULL,
    valor_pagamento numeric(12,2),
    id_pd bigint NOT NULL
);


ALTER TABLE public.pagamentos_processo OWNER TO postgres;

--
-- Name: pagamentos_processo_id_pagamento_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.pagamentos_processo_id_pagamento_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.pagamentos_processo_id_pagamento_seq OWNER TO postgres;

--
-- Name: pagamentos_processo_id_pagamento_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.pagamentos_processo_id_pagamento_seq OWNED BY public.pagamentos_processo.id_pagamento;


--
-- Name: pds; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pds (
    id_pd bigint NOT NULL,
    numero_pd character varying(30) NOT NULL,
    data_pagamento date,
    valor_total numeric(14,2)
);


ALTER TABLE public.pds OWNER TO postgres;

--
-- Name: pds_id_pd_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.pds_id_pd_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.pds_id_pd_seq OWNER TO postgres;

--
-- Name: pds_id_pd_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.pds_id_pd_seq OWNED BY public.pds.id_pd;


--
-- Name: processos; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.processos (
    id_processo bigint NOT NULL,
    numero_processo character varying(30) NOT NULL,
    situacao character varying(20),
    data_cadastro timestamp without time zone
);


ALTER TABLE public.processos OWNER TO postgres;

--
-- Name: processos_id_processo_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.processos_id_processo_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.processos_id_processo_seq OWNER TO postgres;

--
-- Name: processos_id_processo_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.processos_id_processo_seq OWNED BY public.processos.id_processo;


--
-- Name: servidores; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.servidores (
    cpf_servidor character(11) NOT NULL,
    nome_servidor character varying(200) NOT NULL,
    id_cargo smallint NOT NULL,
    ativo boolean DEFAULT true,
    CONSTRAINT chk_servidores_cpf CHECK ((cpf_servidor ~ '^[0-9]{11}$'::text)),
    CONSTRAINT ck_cpf_11 CHECK ((length(regexp_replace((cpf_servidor)::text, '[^0-9]'::text, ''::text, 'g'::text)) = 11))
);


ALTER TABLE public.servidores OWNER TO postgres;

--
-- Name: tipos_diaria; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tipos_diaria (
    id_tipo smallint NOT NULL,
    descricao character varying(50) NOT NULL
);


ALTER TABLE public.tipos_diaria OWNER TO postgres;

--
-- Name: tipos_diaria_id_tipo_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.tipos_diaria_id_tipo_seq
    AS smallint
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.tipos_diaria_id_tipo_seq OWNER TO postgres;

--
-- Name: tipos_diaria_id_tipo_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.tipos_diaria_id_tipo_seq OWNED BY public.tipos_diaria.id_tipo;


--
-- Name: vw_diarias_por_cpf; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vw_diarias_por_cpf AS
 SELECT s.cpf_servidor,
    s.nome_servidor,
    c.nome_cargo,
    p.numero_processo,
    td.descricao AS tipo_diaria,
    d.data_inicial,
    d.destino,
    d.motivo,
    d.valor_diaria,
    d.numero_pd
   FROM ((((public.diarias d
     JOIN public.servidores s ON ((s.cpf_servidor = d.cpf_servidor)))
     JOIN public.cargo c ON ((c.id_cargo = s.id_cargo)))
     JOIN public.processos p ON ((p.id_processo = d.id_processo)))
     JOIN public.tipos_diaria td ON ((td.id_tipo = d.id_tipo)));


ALTER VIEW public.vw_diarias_por_cpf OWNER TO postgres;

--
-- Name: vw_pagamentos_processo; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vw_pagamentos_processo AS
 SELECT p.numero_processo,
    pd.numero_pd,
    pd.data_pagamento,
    pp.valor_pagamento
   FROM ((public.pagamentos_processo pp
     JOIN public.processos p ON ((p.id_processo = pp.id_processo)))
     JOIN public.pds pd ON ((pd.id_pd = pp.id_pd)));


ALTER VIEW public.vw_pagamentos_processo OWNER TO postgres;

--
-- Name: vw_portal_transparencia; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vw_portal_transparencia AS
 WITH base AS (
         SELECT s.nome_servidor AS nome_favorecido,
            s.cpf_servidor AS cpf,
            c.nome_cargo AS cargo,
            to_char((d.data_inicial)::timestamp with time zone, 'MM/YYYY'::text) AS competencia,
            td.descricao AS tipo_deslocamento,
            d.id_diaria,
            d.data_inicial,
            d.destino,
            d.motivo,
            d.valor_diaria,
            p.numero_processo AS processo,
            row_number() OVER (PARTITION BY d.cpf_servidor, (date_trunc('month'::text, (d.data_inicial)::timestamp with time zone)) ORDER BY d.data_inicial DESC, d.id_diaria DESC) AS ultima_linha,
            count(*) OVER (PARTITION BY d.cpf_servidor, (date_trunc('month'::text, (d.data_inicial)::timestamp with time zone))) AS quantidade_diarias_mes,
            sum(d.valor_diaria) OVER (PARTITION BY d.cpf_servidor, (date_trunc('month'::text, (d.data_inicial)::timestamp with time zone))) AS valor_total_diarias_mes
           FROM ((((public.diarias d
             JOIN public.servidores s ON ((s.cpf_servidor = d.cpf_servidor)))
             JOIN public.cargo c ON ((c.id_cargo = s.id_cargo)))
             JOIN public.tipos_diaria td ON ((td.id_tipo = d.id_tipo)))
             JOIN public.processos p ON ((p.id_processo = d.id_processo)))
        )
 SELECT competencia,
    cpf,
    nome_favorecido,
    cargo,
    data_inicial,
    destino,
    tipo_deslocamento,
    motivo,
    valor_diaria,
        CASE
            WHEN (ultima_linha = 1) THEN round(valor_total_diarias_mes, 2)
            ELSE NULL::numeric
        END AS total_mes,
        CASE
            WHEN (ultima_linha = 1) THEN quantidade_diarias_mes
            ELSE NULL::bigint
        END AS qtd_mes,
    processo
   FROM base;


ALTER VIEW public.vw_portal_transparencia OWNER TO postgres;

--
-- Name: vw_processos_sem_diaria; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vw_processos_sem_diaria AS
 SELECT p.id_processo,
    p.numero_processo
   FROM (public.processos p
     LEFT JOIN public.diarias d ON ((d.id_processo = p.id_processo)))
  WHERE (d.id_diaria IS NULL);


ALTER VIEW public.vw_processos_sem_diaria OWNER TO postgres;

--
-- Name: vw_relatorio_pagamentos; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vw_relatorio_pagamentos AS
 SELECT s.nome_servidor AS nome_favorecido,
    s.cpf_servidor AS cpf,
    c.nome_cargo AS cargo,
    to_char((d.data_inicial)::timestamp with time zone, 'DD/MM/YYYY'::text) AS data_inicial,
    d.destino,
    d.motivo,
    p.numero_processo AS processo,
    d.valor_diaria AS valor_diarias,
    pd.numero_pd,
    pp.valor_pagamento AS valor_pd,
    to_char((pd.data_pagamento)::timestamp with time zone, 'DD/MM/YYYY'::text) AS data_pagamento
   FROM (((((public.diarias d
     JOIN public.servidores s ON ((s.cpf_servidor = d.cpf_servidor)))
     JOIN public.cargo c ON ((c.id_cargo = s.id_cargo)))
     JOIN public.processos p ON ((p.id_processo = d.id_processo)))
     LEFT JOIN public.pagamentos_processo pp ON ((pp.id_processo = p.id_processo)))
     LEFT JOIN public.pds pd ON ((pd.id_pd = pp.id_pd)))
  ORDER BY s.nome_servidor, d.data_inicial;


ALTER VIEW public.vw_relatorio_pagamentos OWNER TO postgres;

--
-- Name: vw_transparencia_uge; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vw_transparencia_uge AS
 SELECT s.cpf_servidor,
    s.nome_servidor,
    c.nome_cargo,
    p.numero_processo,
    td.descricao AS tipo_diaria,
    d.data_inicial,
    d.destino,
    d.motivo,
    d.valor_diaria,
    string_agg(DISTINCT (pp.numero_pd)::text, ', '::text ORDER BY (pp.numero_pd)::text) AS numeros_pd,
    max(pp.data_pagamento) AS data_pagamento,
    max(pp.valor_pagamento) AS valor_pagamento
   FROM (((((public.diarias d
     JOIN public.processos p ON ((p.id_processo = d.id_processo)))
     LEFT JOIN public.servidores s ON ((s.cpf_servidor = d.cpf_servidor)))
     LEFT JOIN public.cargo c ON ((c.id_cargo = s.id_cargo)))
     LEFT JOIN public.tipos_diaria td ON ((td.id_tipo = d.id_tipo)))
     LEFT JOIN public.pagamentos_processo pp ON ((pp.id_processo = p.id_processo)))
  GROUP BY s.cpf_servidor, s.nome_servidor, c.nome_cargo, p.numero_processo, td.descricao, d.data_inicial, d.destino, d.motivo, d.valor_diaria;


ALTER VIEW public.vw_transparencia_uge OWNER TO postgres;

--
-- Name: auditoria_log id_log; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.auditoria_log ALTER COLUMN id_log SET DEFAULT nextval('public.auditoria_log_id_log_seq'::regclass);


--
-- Name: auditoria_migracao id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.auditoria_migracao ALTER COLUMN id SET DEFAULT nextval('public.auditoria_migracao_id_seq'::regclass);


--
-- Name: cargo id_cargo; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cargo ALTER COLUMN id_cargo SET DEFAULT nextval('public.cargos_id_cargo_seq'::regclass);


--
-- Name: diarias id_diaria; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.diarias ALTER COLUMN id_diaria SET DEFAULT nextval('public.diarias_id_diaria_seq'::regclass);


--
-- Name: lancamentos id_lancamento; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lancamentos ALTER COLUMN id_lancamento SET DEFAULT nextval('public.lancamentos_id_lancamento_seq'::regclass);


--
-- Name: pagamentos_processo id_pagamento; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pagamentos_processo ALTER COLUMN id_pagamento SET DEFAULT nextval('public.pagamentos_processo_id_pagamento_seq'::regclass);


--
-- Name: pds id_pd; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pds ALTER COLUMN id_pd SET DEFAULT nextval('public.pds_id_pd_seq'::regclass);


--
-- Name: processos id_processo; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.processos ALTER COLUMN id_processo SET DEFAULT nextval('public.processos_id_processo_seq'::regclass);


--
-- Name: tipos_diaria id_tipo; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tipos_diaria ALTER COLUMN id_tipo SET DEFAULT nextval('public.tipos_diaria_id_tipo_seq'::regclass);


--
-- Data for Name: diarias_bkp_20261021; Type: TABLE DATA; Schema: backup; Owner: postgres
--

COPY backup.diarias_bkp_20261021 (id_diaria, cpf_servidor, id_tipo, data_inicial, destino, motivo, valor_diaria, processo, data_cadastro, id_processo, observacao, numero_pd) FROM stdin;
850	18208623806	2	2026-05-25	SAO PAULO	PALESTRA SISTEMA DE JUSTICA	110.65	\N	2026-10-21 09:58:26.750297	450	\N	\N
521	04307176103	1	2026-02-10	SAO PAULO	SERVIÇO POLICIAL	248.96	058.00020984/202691	2026-10-13 17:57:00.859604	505	\N	2026PD00068
627	09085540950	1	2026-08-05	CASA BRANCA	SERVIÇO POLICIAL	207.46	058.00094808/202695	2026-10-13 17:57:00.859604	466	\N	2026PD00344
808	19216935847	2	2026-09-30	SAO PAULO	CURSO COP	726.13	058.00116811/2026-77	2026-10-14 10:40:15.851882	565	\N	\N
810	05484576709	1	2026-02-26	POCOS DE CALDAS	SERVICO POLICIAL	207.46	058.00010202/202616	2026-10-14 14:52:38.767455	566	\N	\N
638	36750397816	1	2026-07-16	MOCOCA	SERVICO POLICIAL	69.15	058.00085732/202615	2026-10-13 17:57:00.859604	530	\N	\N
815	26451064807	1	2026-06-19	RIO DE JANEIRO	SERVICO POLICIAL	822.94	058.00074761/202643	2026-10-14 15:27:31.549516	487	\N	\N
820	10410326682	1	2026-02-25	PIRACICABA	SERVICO POLICIAL	207.46	058.00003690/202602	2026-10-14 15:42:04.872453	446	\N	\N
798	01110375816	2	2023-09-06	SAO PAULO	CURSO SSP	3360.96	058.00115646/202636	2026-10-13 17:57:00.859604	381	\N	2026PD00408
775	01110375816	2	2026-04-01	SAO PAULO	CURSO SSP	871.36	058.00055684/202622	2026-10-13 17:57:00.859604	409	\N	2026PD00161
776	01110375816	2	2026-04-05	SAO PAULO	CURSO SSP	3360.96	058.00055684/202622	2026-10-13 17:57:00.859604	409	\N	2026PD00161
827	04307176103	2	2026-09-24	PIRACICABA	CURSO MBA	103.73	058.00113983/202699	2026-10-15 15:41:17.369817	579	\N	\N
828	04307176103	2	2026-09-26	PIRACICABA	CURSO MBA	103.73	058.00113983/202699	2026-10-15 15:44:46.548372	579	\N	\N
829	19203432884	2	2026-09-17	PIRACICABA	CURSO MBA	103.73	058.00111491/202669	2026-10-15 15:45:38.180307	580	\N	\N
831	19216935847	2	2026-09-26	PIRACICABA	CURSO MBA	103.73	058.00113978/202686	2026-10-15 15:47:48.448063	581	\N	\N
832	42610681844	2	2026-09-17	PIRACICABA	CURSO MBA	80.68	058.00111029/202661	2026-10-15 15:49:17.328371	582	\N	\N
833	85920356510	2	2026-09-24	PIRACICABA	CURSO MBA	103.73	058.00114776/202651	2026-10-15 15:53:44.745113	583	\N	\N
834	85920356510	2	2026-09-26	PIRACICABA	CURSO MBA	103.73	058.00114776/202651	2026-10-15 15:54:20.108825	583	\N	\N
835	10995999899	1	2026-09-01	LIMEIRA	ACUMULO DE FUNCAO	107.57	058.00116234/202613	2026-10-15 15:55:55.417902	584	\N	\N
836	10995999899	1	2026-09-04	LIMEIRA	ACUMULO DE FUNCAO	107.57	058.00116234/202613	2026-10-15 15:56:01.455005	584	\N	\N
837	10995999899	1	2026-09-07	LIMEIRA	ACUMULO DE FUNCAO	107.57	058.00116234/202613	2026-10-15 15:56:06.780392	584	\N	\N
838	10995999899	1	2026-09-10	LIMEIRA	ACUMULO DE FUNCAO	107.57	058.00116234/202613	2026-10-15 15:56:12.032533	584	\N	\N
839	10995999899	1	2026-09-13	LIMEIRA	ACUMULO DE FUNCAO	107.57	058.00116234/202613	2026-10-15 15:56:20.680416	584	\N	\N
840	10995999899	1	2026-09-14	LIMEIRA	ACUMULO DE FUNCAO	107.57	058.00116234/202613	2026-10-15 15:56:26.064817	584	\N	\N
841	10995999899	1	2026-09-16	LIMEIRA	ACUMULO DE FUNCAO	107.57	058.00116234/202613	2026-10-15 15:56:32.12167	584	\N	\N
842	10995999899	1	2026-09-22	LIMEIRA	ACUMULO DE FUNCAO	107.57	058.00116234/202613	2026-10-15 15:56:38.802749	584	\N	\N
843	10995999899	1	2026-09-25	LIMEIRA	ACUMULO DE FUNCAO	107.57	058.00116234/202613	2026-10-15 15:56:43.449109	584	\N	\N
844	10995999899	1	2026-09-28	LIMEIRA	ACUMULO DE FUNCAO	107.57	058.00116234/202613	2026-10-15 15:56:49.346365	584	\N	\N
845	09085540950	1	2026-09-25	SAO PAULO	SERVIÇO POLICIAL	124.48	058.00116140/202644	2026-10-15 15:58:54.507043	585	\N	\N
847	13934950876	1	2026-09-26	LIMEIRA	ACUMULO DE FUNCAO	161.36	058.00116200/202629	2026-10-15 16:01:12.186859	586	\N	\N
848	13934950876	1	2026-09-27	LIMEIRA	ACUMULO DE FUNCAO	161.36	058.00116200/202629	2026-10-15 16:01:20.301849	586	\N	\N
849	13934950876	1	2026-09-28	LIMEIRA	ACUMULO DE FUNCAO	161.36	058.00116200/202629	2026-10-15 16:01:27.748525	586	\N	\N
743	00496426850	2	2026-08-27	SAO PAULO	AGOSTO LILAS	248.96	05800104239/202601	2026-10-13 17:57:00.859604	377	\N	2026PD00367
777	01110375816	2	2026-04-12	SAO PAULO	CURSO SSP	3360.96	058.00055684/202622	2026-10-13 17:57:00.859604	409	\N	2026PD00161
778	01110375816	2	2026-04-21	SAO PAULO	CURSO SSP	2116.16	058.00055684/202622	2026-10-13 17:57:00.859604	409	\N	2026PD00161
779	01110375816	2	2026-04-26	SAO PAULO	CURSO SSP	3360.96	058.00055684/202622	2026-10-13 17:57:00.859604	409	\N	2026PD00161
780	01110375816	2	2026-05-03	SAO PAULO	CURSO SSP	3360.96	05800067369/202648	2026-10-13 17:57:00.859604	423	\N	2026PD00218
781	01110375816	2	2026-05-10	SAO PAULO	CURSO SSP	3360.96	05800067369/202648	2026-10-13 17:57:00.859604	423	\N	2026PD00218
782	01110375816	2	2026-05-17	SAO PAULO	CURSO SSP	3360.96	05800067369/202648	2026-10-13 17:57:00.859604	423	\N	2026PD00218
783	01110375816	2	2026-05-24	SAO PAULO	CURSO SSP	3360.96	05800067369/202648	2026-10-13 17:57:00.859604	423	\N	2026PD00218
784	01110375816	2	2026-05-31	SAO PAULO	CURSO SSP	3112.00	058.00079231/202691	2026-10-13 17:57:00.859604	472	\N	2026PD00260
785	01110375816	2	2026-06-07	SAO PAULO	CURSO SSP	3112.00	058.00079231/202691	2026-10-13 17:57:00.859604	472	\N	2026PD00260
786	01110375816	2	2026-06-14	SAO PAULO	CURSO SSP	3112.00	058.00079231/202691	2026-10-13 17:57:00.859604	472	\N	2026PD00260
787	01110375816	2	2026-06-21	SAO PAULO	CURSO SSP	3112.00	058.00079231/202691	2026-10-13 17:57:00.859604	472	\N	2026PD00260
788	01110375816	2	2026-06-28	SAO PAULO	CURSO SSP	3112.00	058.00088428/202611	2026-10-13 17:57:00.859604	516	\N	2026PD00304
789	01110375816	2	2026-07-05	SAO PAULO	CURSO SSP	3112.00	058.00088428/202611	2026-10-13 17:57:00.859604	516	\N	2026PD00304
790	01110375816	2	2026-07-12	SAO PAULO	CURSO SSP	3112.00	058.00088428/202611	2026-10-13 17:57:00.859604	516	\N	2026PD00304
791	01110375816	2	2026-07-19	SAO PAULO	CURSO SSP	3112.00	058.00088428/202611	2026-10-13 17:57:00.859604	516	\N	2026PD00304
792	01110375816	2	2026-07-26	SAO PAULO	CURSO SSP	3112.00	058.00088428/202611	2026-10-13 17:57:00.859604	516	\N	2026PD00304
793	01110375816	2	2026-08-02	SAO PAULO	CURSO SSP	3360.96	058.00102235/202681	2026-10-13 17:57:00.859604	371	\N	2026PD00371
794	01110375816	2	2026-08-09	SAO PAULO	CURSO SSP	3360.96	058.00102235/202681	2026-10-13 17:57:00.859604	371	\N	2026PD00371
795	01110375816	2	2026-08-16	SAO PAULO	CURSO SSP	3360.96	058.00102235/202681	2026-10-13 17:57:00.859604	371	\N	2026PD00371
796	01110375816	2	2026-08-23	SAO PAULO	CURSO SSP	3360.96	058.00102235/202681	2026-10-13 17:57:00.859604	371	\N	2026PD00371
797	01110375816	2	2026-08-30	SAO PAULO	CURSO SSP	3360.96	058.00115646/202636	2026-10-13 17:57:00.859604	381	\N	2026PD00408
799	01110375816	2	2026-09-13	SAO PAULO	CURSO SSP	3360.96	058.00115646/202636	2026-10-13 17:57:00.859604	381	\N	2026PD00408
800	01110375816	2	2026-09-20	SAO PAULO	CURSO SSP	3360.96	058.00115646/202636	2026-10-13 17:57:00.859604	381	\N	2026PD00408
801	01110375816	2	2026-09-27	SAO PAULO	CURSO SSP	3360.96	058.00115646/202636	2026-10-13 17:57:00.859604	381	\N	2026PD00408
522	04307176103	1	2026-04-16	LIMEIRA	SERVIÇO POLICIAL	103.73	058.00049520/202666	2026-10-13 17:57:00.859604	492	\N	2026PD00169
565	04704982858	1	2026-06-09	SAO PAULO	SERVIÇO POLICIAL	248.96	058.00070439/202645	2026-10-13 17:57:00.859604	384	\N	2026/PD00283
560	05484576709	1	2026-02-25	SAO PAULO	SERVIÇO POLICIAL	248.96	058.00029861/202615	2026-10-13 17:57:00.859604	469	\N	2026PD00129
738	05484576709	2	2026-03-16	SAO PAULO	CURSO OPERACIONAL PMSP	248.96	058.00040676/202681	2026-10-13 17:57:00.859604	448	\N	\N
739	05484576709	2	2026-03-17	SAO PAULO	CURSO OPERACIONAL PMSP	248.96	058.00040676/202681	2026-10-13 17:57:00.859604	448	\N	\N
740	05484576709	2	2026-03-18	SAO PAULO	CURSO OPERACIONAL PMSP	248.96	058.00040676/202681	2026-10-13 17:57:00.859604	448	\N	\N
741	05484576709	2	2026-03-19	SAO PAULO	CURSO OPERACIONAL PMSP	248.96	058.00040676/202681	2026-10-13 17:57:00.859604	448	\N	\N
742	05484576709	2	2026-03-20	SAO PAULO	CURSO OPERACIONAL PMSP	248.96	058.00040676/202681	2026-10-13 17:57:00.859604	448	\N	\N
745	05484576709	2	2026-03-23	SAO PAULO	CURSO OPERACIONAL PMSP	248.96	058.00040676/202681	2026-10-13 17:57:00.859604	448	\N	\N
750	05484576709	2	2026-03-24	SAO PAULO	CURSO OPERACIONAL PMSP	248.96	058.00040676/202681	2026-10-13 17:57:00.859604	448	\N	\N
754	05484576709	2	2026-03-25	SAO PAULO	CURSO OPERACIONAL PMSP	248.96	058.00040676/202681	2026-10-13 17:57:00.859604	448	\N	\N
755	05484576709	2	2026-03-26	SAO PAULO	CURSO OPERACIONAL PMSP	248.96	058.00040676/202681	2026-10-13 17:57:00.859604	448	\N	\N
756	05484576709	2	2026-03-27	SAO PAULO	CURSO OPERACIONAL PMSP	248.96	058.00040676/202681	2026-10-13 17:57:00.859604	448	\N	\N
717	06762410855	2	2026-08-02	SAO PAULO	ENCONTRO UGES	622.40	058.00091820/202648	2026-10-13 17:57:00.859604	538	\N	2026PD00340
558	06762410855	1	2026-08-06	ITU	SERVIÇO POLICIAL	103.73	058.00094014/202621	2026-10-13 17:57:00.859604	547	\N	2026PD00341
542	07666429681	1	2026-04-28	PIRACICABA	SERVIÇO POLICIAL	69.15	058.00052997/202629	2026-10-13 17:57:00.859604	372	\N	2026PD00170
813	07902044792	1	2026-04-09	SAO PAULO	SERVICO POLICIAL	124.48	058.00046220/202625	2026-10-14 15:20:48.32486	562	\N	\N
642	07902044792	1	2026-04-09	SAO PAULO	SERVIÇO POLICIAL	124.48	058.00046220/202625	2026-10-13 17:57:00.859604	562	\N	\N
566	08922377674	1	2026-08-10	SAO PAULO	SERVIÇO POLICIAL	248.96	058.00095143/202637	2026-10-13 17:57:00.859604	560	\N	2026PD00332
814	09595897833	1	2026-02-12	CAPIVARI	SERVICO POLICIAL	69.15	058.00021373/202660	2026-10-14 15:23:19.777539	412	\N	\N
643	09595897833	1	2026-02-12	CAPIVARI	SERVIÇO POLICIAL	69.15	058.00021373/202660	2026-10-13 17:57:00.859604	412	\N	\N
649	10410326682	1	2026-01-07	PIRACICABA	PLANTAO POLICIAL LIMEIRA	207.46	058.00003690/202602	2026-10-13 17:57:00.859604	446	\N	\N
650	10410326682	1	2026-02-07	PIRACICABA	PLANTAO POLICIAL LIMEIRA	207.46	058.00018719/202642	2026-10-13 17:57:00.859604	408	\N	2026PD00070
651	10410326682	1	2026-02-14	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	138.31	058.00031378/202609	2026-10-13 17:57:00.859604	444	\N	\N
821	10410326682	1	2026-02-14	PIRASSUNUNGA	SERVICO POLICIAL	138.31	058.00031378/202609	2026-10-14 15:47:02.602612	444	\N	\N
652	10410326682	1	2026-02-15	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	138.31	058.00031378/202609	2026-10-13 17:57:00.859604	444	\N	\N
822	10410326682	1	2026-02-15	PIRASSUNUNGA	SERVICO POLICIAL	138.31	058.00031378/202609	2026-10-14 15:47:17.322943	444	\N	\N
653	10410326682	1	2026-02-22	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	69.15	058.00031378/202609	2026-10-13 17:57:00.859604	444	\N	\N
825	10410326682	1	2026-02-22	PIRASSUNUNGA	SERVICO POLICIAL	69.15	058.00031378/202609	2026-10-14 15:47:48.416271	444	\N	\N
654	10410326682	1	2026-02-23	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	138.31	058.00031378/202609	2026-10-13 17:57:00.859604	444	\N	\N
823	10410326682	1	2026-02-23	PIRASSUNUNGA	SERVICO POLICIAL	138.31	058.00031378/202609	2026-10-14 15:47:26.244429	444	\N	\N
655	10410326682	1	2026-02-27	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	138.31	058.00031378/202609	2026-10-13 17:57:00.859604	444	\N	\N
824	10410326682	1	2026-02-27	PIRASSUNUNGA	SERVICO POLICIAL	138.31	058.00031378/202609	2026-10-14 15:47:32.122151	444	\N	\N
656	10410326682	1	2026-03-03	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	138.31	058.00041351/202616	2026-10-13 17:57:00.859604	386	\N	2026PD00130
657	10410326682	1	2026-03-05	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	138.31	058.00041351/202616	2026-10-13 17:57:00.859604	386	\N	2026PD00130
658	10410326682	1	2026-03-09	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	138.31	058.00041351/202616	2026-10-13 17:57:00.859604	386	\N	2026PD00130
659	10410326682	1	2026-03-11	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	138.31	058.00041351/202616	2026-10-13 17:57:00.859604	386	\N	2026PD00130
660	10410326682	1	2026-03-14	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	69.15	058.00041351/202616	2026-10-13 17:57:00.859604	386	\N	2026PD00130
661	10410326682	1	2026-03-15	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	138.31	058.00041351/202616	2026-10-13 17:57:00.859604	386	\N	2026PD00130
662	10410326682	1	2026-03-19	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	138.31	058.00041351/202616	2026-10-13 17:57:00.859604	386	\N	2026PD00130
663	10410326682	1	2026-03-21	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	138.31	058.00041351/202616	2026-10-13 17:57:00.859604	386	\N	2026PD00130
664	10410326682	1	2026-03-23	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	138.31	058.00041351/202616	2026-10-13 17:57:00.859604	386	\N	2026PD00130
665	10410326682	1	2026-03-27	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	138.31	058.00041351/202616	2026-10-13 17:57:00.859604	386	\N	2026PD00130
666	10410326682	1	2026-03-31	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	138.31	058.00041351/202616	2026-10-13 17:57:00.859604	386	\N	2026PD00130
667	10410326682	1	2026-04-06	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	138.31	058.00054445/202655	2026-10-13 17:57:00.859604	422	\N	2026PD00172
668	10410326682	1	2026-04-09	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	138.31	058.00054445/202655	2026-10-13 17:57:00.859604	422	\N	2026PD00172
669	10410326682	1	2026-04-11	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	138.31	058.00054445/202655	2026-10-13 17:57:00.859604	422	\N	2026PD00172
670	10410326682	1	2026-04-13	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	138.31	058.00054445/202655	2026-10-13 17:57:00.859604	422	\N	2026PD00172
671	10410326682	1	2026-04-15	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	138.31	058.00054445/202655	2026-10-13 17:57:00.859604	422	\N	2026PD00172
672	10410326682	1	2026-04-17	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	138.31	058.00054445/202655	2026-10-13 17:57:00.859604	422	\N	2026PD00172
673	10410326682	1	2026-04-19	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	138.31	058.00054445/202655	2026-10-13 17:57:00.859604	422	\N	2026PD00172
674	10410326682	1	2026-04-21	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	138.31	058.00054445/202655	2026-10-13 17:57:00.859604	422	\N	2026PD00172
675	10410326682	1	2026-04-23	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	138.31	058.00054445/202655	2026-10-13 17:57:00.859604	422	\N	2026PD00172
676	10410326682	1	2026-04-27	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	138.31	058.00054445/202655	2026-10-13 17:57:00.859604	422	\N	2026PD00172
677	10410326682	1	2026-04-29	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	138.31	058.00054445/202655	2026-10-13 17:57:00.859604	422	\N	2026PD00172
678	10410326682	1	2026-05-01	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	138.31	058.00066721/202628	2026-10-13 17:57:00.859604	391	\N	2026PD00237
679	10410326682	1	2026-05-03	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	69.15	058.00066721/202628	2026-10-13 17:57:00.859604	391	\N	2026PD00237
680	10410326682	1	2026-05-05	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	138.31	058.00066721/202628	2026-10-13 17:57:00.859604	391	\N	2026PD00237
681	10410326682	1	2026-05-11	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	138.31	058.00066721/202628	2026-10-13 17:57:00.859604	391	\N	2026PD00237
682	10410326682	1	2026-05-14	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	138.31	058.00066721/202628	2026-10-13 17:57:00.859604	391	\N	2026PD00237
683	10410326682	1	2026-05-16	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	138.31	058.00066721/202628	2026-10-13 17:57:00.859604	391	\N	2026PD00237
684	10410326682	1	2026-05-17	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	138.31	058.00066721/202628	2026-10-13 17:57:00.859604	391	\N	2026PD00237
685	10410326682	1	2026-05-20	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	138.31	058.00066721/202628	2026-10-13 17:57:00.859604	391	\N	2026PD00237
686	10410326682	1	2026-05-23	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	69.15	058.00066721/202628	2026-10-13 17:57:00.859604	391	\N	2026PD00237
687	10410326682	1	2026-05-24	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	69.15	058.00066721/202628	2026-10-13 17:57:00.859604	391	\N	2026PD00237
688	10410326682	1	2026-05-26	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	138.31	058.00066721/202628	2026-10-13 17:57:00.859604	391	\N	2026PD00237
446	10531583600	1	2026-01-27	PIRACICABA	PLANTAO POLICIAL LIMEIRA	207.46	058.00012724/202641	2026-10-13 17:57:00.859604	389	\N	2026PD00048
567	10995999899	1	2026-03-01	LIMEIRA	ACUMULO DE FUNÇÃO	107.57	058.00040508/202696	2026-10-13 17:57:00.859604	434	\N	2026PD00115
568	10995999899	1	2026-03-04	LIMEIRA	ACUMULO DE FUNÇÃO	107.57	058.00040508/202696	2026-10-13 17:57:00.859604	434	\N	2026PD00115
569	10995999899	1	2026-03-06	LIMEIRA	ACUMULO DE FUNÇÃO	107.57	058.00040508/202696	2026-10-13 17:57:00.859604	434	\N	2026PD00115
570	10995999899	1	2026-03-07	LIMEIRA	ACUMULO DE FUNÇÃO	107.57	058.00040508/202696	2026-10-13 17:57:00.859604	434	\N	2026PD00115
571	10995999899	1	2026-03-10	LIMEIRA	ACUMULO DE FUNÇÃO	107.57	058.00040508/202696	2026-10-13 17:57:00.859604	434	\N	2026PD00115
572	10995999899	1	2026-03-13	LIMEIRA	ACUMULO DE FUNÇÃO	107.57	058.00040508/202696	2026-10-13 17:57:00.859604	434	\N	2026PD00115
573	10995999899	1	2026-03-17	LIMEIRA	ACUMULO DE FUNÇÃO	107.57	058.00040508/202696	2026-10-13 17:57:00.859604	434	\N	2026PD00115
574	10995999899	1	2026-03-21	LIMEIRA	ACUMULO DE FUNÇÃO	107.57	058.00040508/202696	2026-10-13 17:57:00.859604	434	\N	2026PD00115
575	10995999899	1	2026-03-25	LIMEIRA	ACUMULO DE FUNÇÃO	107.57	058.00040508/202696	2026-10-13 17:57:00.859604	434	\N	2026PD00115
723	10995999899	2	2026-03-27	PIRACICABA	CURSO TIRO	80.68	058.00040479/202662	2026-10-13 17:57:00.859604	460	\N	2026PD00131
576	10995999899	1	2026-04-02	LIMEIRA	ACUMULO DE FUNÇÃO	107.57	058.00047272/202619	2026-10-13 17:57:00.859604	528	\N	2026PD00173
577	10995999899	1	2026-04-04	LIMEIRA	ACUMULO DE FUNÇÃO	107.57	058.00047272/202619	2026-10-13 17:57:00.859604	528	\N	2026PD00173
578	10995999899	1	2026-04-05	LIMEIRA	ACUMULO DE FUNÇÃO	107.57	058.00047272/202619	2026-10-13 17:57:00.859604	528	\N	2026PD00173
579	10995999899	1	2026-04-08	LIMEIRA	ACUMULO DE FUNÇÃO	107.57	058.00047272/202619	2026-10-13 17:57:00.859604	528	\N	2026PD00173
580	10995999899	1	2026-04-10	LIMEIRA	ACUMULO DE FUNÇÃO	107.57	058.00047272/202619	2026-10-13 17:57:00.859604	528	\N	2026PD00173
581	10995999899	1	2026-05-01	LIMEIRA	ACUMULO DE FUNÇÃO	107.57	058.00057022/202697	2026-10-13 17:57:00.859604	523	\N	2026PD00238
582	10995999899	1	2026-05-05	LIMEIRA	ACUMULO DE FUNÇÃO	107.57	058.00057022/202697	2026-10-13 17:57:00.859604	523	\N	2026PD00238
583	10995999899	1	2026-05-07	LIMEIRA	ACUMULO DE FUNÇÃO	107.57	058.00057022/202697	2026-10-13 17:57:00.859604	523	\N	2026PD00238
584	10995999899	1	2026-05-09	LIMEIRA	ACUMULO DE FUNÇÃO	107.57	058.00057022/202697	2026-10-13 17:57:00.859604	523	\N	2026PD00238
585	10995999899	1	2026-06-01	LIMEIRA	ACUMULO DE FUNÇÃO	107.57	058.00077592/202601	2026-10-13 17:57:00.859604	542	\N	2026PD00282
586	10995999899	1	2026-06-02	LIMEIRA	ACUMULO DE FUNÇÃO	107.57	058.00077592/202601	2026-10-13 17:57:00.859604	542	\N	2026PD00282
587	10995999899	1	2026-06-03	LIMEIRA	ACUMULO DE FUNÇÃO	107.57	058.00077592/202601	2026-10-13 17:57:00.859604	542	\N	2026PD00282
588	10995999899	1	2026-06-14	LIMEIRA	ACUMULO DE FUNÇÃO	107.57	058.00077592/202601	2026-10-13 17:57:00.859604	542	\N	2026PD00282
589	10995999899	1	2026-06-17	LIMEIRA	ACUMULO DE FUNÇÃO	107.57	058.00077592/202601	2026-10-13 17:57:00.859604	542	\N	2026PD00282
590	10995999899	1	2026-06-18	LIMEIRA	ACUMULO DE FUNÇÃO	107.57	058.00077592/202601	2026-10-13 17:57:00.859604	542	\N	2026PD00282
591	10995999899	1	2026-06-21	LIMEIRA	ACUMULO DE FUNÇÃO	107.57	058.00077592/202601	2026-10-13 17:57:00.859604	542	\N	2026PD00282
592	10995999899	1	2026-06-22	LIMEIRA	ACUMULO DE FUNÇÃO	107.57	058.00077592/202601	2026-10-13 17:57:00.859604	542	\N	2026PD00282
593	10995999899	1	2026-06-25	LIMEIRA	ACUMULO DE FUNÇÃO	107.57	058.00077592/202601	2026-10-13 17:57:00.859604	542	\N	2026PD00282
594	10995999899	1	2026-06-26	LIMEIRA	ACUMULO DE FUNÇÃO	107.57	058.00077592/202601	2026-10-13 17:57:00.859604	542	\N	2026PD00282
595	10995999899	1	2026-07-02	LIMEIRA	ACUMULO DE FUNÇÃO	107.57	058.00091579/202657	2026-10-13 17:57:00.859604	440	\N	2026PD00306
596	10995999899	1	2026-07-05	LIMEIRA	ACUMULO DE FUNÇÃO	107.57	058.00091579/202658	2026-10-13 17:57:00.859604	415	\N	2026PD00306
597	10995999899	1	2026-07-08	LIMEIRA	ACUMULO DE FUNÇÃO	107.57	058.00091579/202659	2026-10-13 17:57:00.859604	405	\N	2026PD00306
598	10995999899	1	2026-07-11	LIMEIRA	ACUMULO DE FUNÇÃO	107.57	058.00091579/202660	2026-10-13 17:57:00.859604	533	\N	2026PD00306
599	10995999899	1	2026-07-14	LIMEIRA	ACUMULO DE FUNÇÃO	107.57	058.00091579/202661	2026-10-13 17:57:00.859604	458	\N	2026PD00306
600	10995999899	1	2026-07-17	LIMEIRA	ACUMULO DE FUNÇÃO	107.57	058.00091579/202662	2026-10-13 17:57:00.859604	501	\N	2026PD00306
601	10995999899	1	2026-07-20	LIMEIRA	ACUMULO DE FUNÇÃO	107.57	058.00091579/202663	2026-10-13 17:57:00.859604	404	\N	2026PD00306
602	10995999899	1	2026-07-21	LIMEIRA	ACUMULO DE FUNÇÃO	107.57	058.00091579/202664	2026-10-13 17:57:00.859604	403	\N	2026PD00306
603	10995999899	1	2026-07-24	LIMEIRA	ACUMULO DE FUNÇÃO	107.57	058.00091579/202665	2026-10-13 17:57:00.859604	484	\N	2026PD00306
604	10995999899	1	2026-07-25	LIMEIRA	ACUMULO DE FUNÇÃO	107.57	058.00091579/202666	2026-10-13 17:57:00.859604	539	\N	2026PD00306
605	10995999899	1	2026-07-28	LIMEIRA	ACUMULO DE FUNÇÃO	107.57	058.00091579/202667	2026-10-13 17:57:00.859604	479	\N	2026PD00306
606	10995999899	1	2026-07-29	LIMEIRA	ACUMULO DE FUNÇÃO	107.57	058.00091579/202668	2026-10-13 17:57:00.859604	532	\N	2026PD00306
607	10995999899	1	2026-08-05	LIMEIRA	ACUMULO DE FUNÇÃO	107.57	058.00104889/202649	2026-10-13 17:57:00.859604	461	\N	2026PD00402
608	10995999899	1	2026-08-09	LIMEIRA	ACUMULO DE FUNÇÃO	107.57	058.00104889/202649	2026-10-13 17:57:00.859604	461	\N	2026PD00402
609	10995999899	1	2026-08-11	LIMEIRA	ACUMULO DE FUNÇÃO	107.57	058.00104889/202649	2026-10-13 17:57:00.859604	461	\N	2026PD00402
610	10995999899	1	2026-08-14	LIMEIRA	ACUMULO DE FUNÇÃO	107.57	058.00104889/202649	2026-10-13 17:57:00.859604	461	\N	2026PD00402
611	10995999899	1	2026-08-20	LIMEIRA	ACUMULO DE FUNÇÃO	107.57	058.00104889/202649	2026-10-13 17:57:00.859604	461	\N	2026PD00402
612	10995999899	1	2026-08-21	LIMEIRA	ACUMULO DE FUNÇÃO	107.57	058.00104889/202649	2026-10-13 17:57:00.859604	461	\N	2026PD00402
613	10995999899	1	2026-08-22	LIMEIRA	ACUMULO DE FUNÇÃO	107.57	058.00104889/202649	2026-10-13 17:57:00.859604	461	\N	2026PD00402
614	10995999899	1	2026-08-23	LIMEIRA	ACUMULO DE FUNÇÃO	107.57	058.00104889/202649	2026-10-13 17:57:00.859604	461	\N	2026PD00402
615	10995999899	1	2026-08-26	LIMEIRA	ACUMULO DE FUNÇÃO	107.57	058.00104889/202649	2026-10-13 17:57:00.859604	461	\N	2026PD00402
616	10995999899	1	2026-08-29	LIMEIRA	ACUMULO DE FUNÇÃO	107.57	058.00104889/202649	2026-10-13 17:57:00.859604	461	\N	2026PD00402
523	11374959600	1	2026-08-05	BARUERI	SERVIÇO POLICIAL	103.73	058.00093477/202676	2026-10-13 17:57:00.859604	393	\N	2026PD00334
524	11374959600	1	2026-08-17	PIRACICABA	SERVIÇO POLICIAL	103.73	058.00098581/202657	2026-10-13 17:57:00.859604	473	\N	2026PD00402
716	12328788807	2	2026-07-16	SAO PAULO	TREINAMENTO	193.63	058.00085150/202621	2026-10-13 17:57:00.859604	459	\N	2026PD00136
725	12375581660	2	2026-03-27	RIO CLARO	CURSO TIRO	69.15	058.00044639/202642	2026-10-13 17:57:00.859604	430	\N	2026PD00184
441	12794506730	1	2026-06-09	SAO PAULO	SERVIÇO POLICIAL	248.96	058.00070656/202635	2026-10-13 17:57:00.859604	457	\N	2026PD00296
694	13934950876	1	2026-05-02	LIMEIRA	PLANTAO POLICIAL LIMEIRA	161.36	058.00067125/202665	2026-10-13 17:57:00.859604	485	\N	2026PD00239
695	13934950876	1	2026-05-05	LIMEIRA	PLANTAO POLICIAL LIMEIRA	161.36	058.00067125/202665	2026-10-13 17:57:00.859604	485	\N	2026PD00239
696	13934950876	1	2026-05-08	LIMEIRA	PLANTAO POLICIAL LIMEIRA	161.36	058.00067125/202665	2026-10-13 17:57:00.859604	485	\N	2026PD00239
697	13934950876	1	2026-05-11	LIMEIRA	PLANTAO POLICIAL LIMEIRA	161.36	058.00067125/202665	2026-10-13 17:57:00.859604	485	\N	2026PD00239
698	13934950876	1	2026-05-14	LIMEIRA	PLANTAO POLICIAL LIMEIRA	161.36	058.00067125/202665	2026-10-13 17:57:00.859604	485	\N	2026PD00239
699	13934950876	1	2026-05-17	LIMEIRA	PLANTAO POLICIAL LIMEIRA	161.36	058.00067125/202665	2026-10-13 17:57:00.859604	485	\N	2026PD00239
400	13934950876	1	2026-05-21	LIMEIRA	PLANTAO POLICIAL LIMEIRA	161.36	058.00067125/202665	2026-10-13 17:57:00.859604	485	\N	2026PD00239
401	13934950876	1	2026-05-24	LIMEIRA	PLANTAO POLICIAL LIMEIRA	161.36	058.00067125/202665	2026-10-13 17:57:00.859604	485	\N	2026PD00239
402	13934950876	1	2026-05-28	LIMEIRA	PLANTAO POLICIAL LIMEIRA	161.36	058.00067125/202665	2026-10-13 17:57:00.859604	485	\N	2026PD00239
403	13934950876	1	2026-05-31	LIMEIRA	PLANTAO POLICIAL LIMEIRA	161.36	058.00067125/202665	2026-10-13 17:57:00.859604	485	\N	2026PD00247
404	13934950876	1	2026-06-04	LIMEIRA	PLANTAO POLICIAL LIMEIRA	161.36	058.00083398/202657	2026-10-13 17:57:00.859604	495	\N	2026PD00307
405	13934950876	1	2026-06-09	LIMEIRA	PLANTAO POLICIAL LIMEIRA	161.36	058.00083398/202658	2026-10-13 17:57:00.859604	488	\N	2026PD00307
406	13934950876	1	2026-06-14	LIMEIRA	PLANTAO POLICIAL LIMEIRA	161.36	058.00083398/202659	2026-10-13 17:57:00.859604	370	\N	2026PD00307
395	13934950876	1	2026-06-19	LIMEIRA	PLANTAO POLICIAL LIMEIRA	161.36	058.00083398/202660	2026-10-13 17:57:00.859604	480	\N	2026PD00307
407	13934950876	1	2026-06-21	LIMEIRA	PLANTAO POLICIAL LIMEIRA	161.36	058.00083398/202661	2026-10-13 17:57:00.859604	400	\N	2026PD00307
408	13934950876	1	2026-06-24	LIMEIRA	PLANTAO POLICIAL LIMEIRA	161.36	058.00083398/202662	2026-10-13 17:57:00.859604	470	\N	2026PD00307
409	13934950876	1	2026-06-27	LIMEIRA	PLANTAO POLICIAL LIMEIRA	161.36	058.00083398/202663	2026-10-13 17:57:00.859604	438	\N	2026PD00307
410	13934950876	1	2026-06-29	LIMEIRA	PLANTAO POLICIAL LIMEIRA	161.36	058.00083398/202664	2026-10-13 17:57:00.859604	435	\N	2026PD00307
411	13934950876	1	2026-07-02	LIMEIRA	ACUMULO DE FUNÇÃO	161.36	058.00092056/202628	2026-10-13 17:57:00.859604	494	\N	2026PD00335
412	13934950876	1	2026-07-04	LIMEIRA	ACUMULO DE FUNÇÃO	161.36	058.00092056/202628	2026-10-13 17:57:00.859604	494	\N	2026PD00335
413	13934950876	1	2026-07-06	LIMEIRA	ACUMULO DE FUNÇÃO	161.36	058.00092056/202628	2026-10-13 17:57:00.859604	494	\N	2026PD00335
414	13934950876	1	2026-07-09	LIMEIRA	ACUMULO DE FUNÇÃO	161.36	058.00092056/202628	2026-10-13 17:57:00.859604	494	\N	2026PD00335
415	13934950876	1	2026-07-11	LIMEIRA	ACUMULO DE FUNÇÃO	161.36	058.00092056/202628	2026-10-13 17:57:00.859604	494	\N	2026PD00335
416	13934950876	1	2026-07-12	LIMEIRA	ACUMULO DE FUNÇÃO	161.36	058.00092056/202628	2026-10-13 17:57:00.859604	494	\N	2026PD00335
417	13934950876	1	2026-07-15	LIMEIRA	ACUMULO DE FUNÇÃO	161.36	058.00092056/202628	2026-10-13 17:57:00.859604	494	\N	2026PD00335
418	13934950876	1	2026-07-18	LIMEIRA	ACUMULO DE FUNÇÃO	161.36	058.00092056/202628	2026-10-13 17:57:00.859604	494	\N	2026PD00335
419	13934950876	1	2026-07-20	LIMEIRA	ACUMULO DE FUNÇÃO	161.36	058.00092056/202628	2026-10-13 17:57:00.859604	494	\N	2026PD00335
420	13934950876	1	2026-07-23	LIMEIRA	ACUMULO DE FUNÇÃO	161.36	058.00092056/202628	2026-10-13 17:57:00.859604	494	\N	2026PD00335
421	13934950876	1	2026-07-25	LIMEIRA	ACUMULO DE FUNÇÃO	161.36	058.00092056/202628	2026-10-13 17:57:00.859604	494	\N	2026PD00335
422	13934950876	1	2026-07-27	LIMEIRA	ACUMULO DE FUNÇÃO	161.36	058.00092056/202628	2026-10-13 17:57:00.859604	494	\N	2026PD00335
423	13934950876	1	2026-07-30	LIMEIRA	ACUMULO DE FUNÇÃO	161.36	058.00092056/202628	2026-10-13 17:57:00.859604	494	\N	2026PD00335
424	13934950876	1	2026-08-02	LIMEIRA	ACUMULO DE FUNÇÃO	161.36	058.00103897/202678	2026-10-13 17:57:00.859604	454	\N	2026PD00402
425	13934950876	1	2026-08-06	LIMEIRA	ACUMULO DE FUNÇÃO	161.36	058.00103897/202678	2026-10-13 17:57:00.859604	454	\N	2026PD00402
426	13934950876	1	2026-08-09	LIMEIRA	ACUMULO DE FUNÇÃO	161.36	058.00103897/202678	2026-10-13 17:57:00.859604	454	\N	2026PD00402
427	13934950876	1	2026-08-12	LIMEIRA	ACUMULO DE FUNÇÃO	161.36	058.00103897/202678	2026-10-13 17:57:00.859604	454	\N	2026PD00402
428	13934950876	1	2026-08-15	LIMEIRA	ACUMULO DE FUNÇÃO	161.36	058.00103897/202678	2026-10-13 17:57:00.859604	454	\N	2026PD00402
429	13934950876	1	2026-08-18	LIMEIRA	ACUMULO DE FUNÇÃO	161.36	058.00103897/202678	2026-10-13 17:57:00.859604	454	\N	2026PD00402
430	13934950876	1	2026-08-22	LIMEIRA	ACUMULO DE FUNÇÃO	161.36	058.00103897/202678	2026-10-13 17:57:00.859604	454	\N	2026PD00402
431	13934950876	1	2026-08-24	LIMEIRA	ACUMULO DE FUNÇÃO	161.36	058.00103897/202678	2026-10-13 17:57:00.859604	454	\N	2026PD00402
432	13934950876	1	2026-08-28	LIMEIRA	ACUMULO DE FUNÇÃO	161.36	058.00103897/202678	2026-10-13 17:57:00.859604	454	\N	2026PD00402
433	13934950876	1	2026-08-30	LIMEIRA	ACUMULO DE FUNÇÃO	161.36	058.00103897/202678	2026-10-13 17:57:00.859604	454	\N	2026PD00402
625	14694180703	1	2026-06-09	SAO PAULO	SERVIÇO POLICIAL	248.96	058.00070662/202692	2026-10-13 17:57:00.859604	519	\N	2026PD00284
626	14694180703	1	2026-08-05	BARUERI	SERVIÇO POLICIAL	103.73	058.00093806/202689	2026-10-13 17:57:00.859604	436	\N	2026PD00402
744	15721307846	2	2026-07-16	SAO PAULO	TREINAMENTO	248.96	058.00085156/202606	2026-10-13 17:57:00.859604	522	\N	2026PD00317
520	16791203870	1	2026-08-05	BARUERI	SERVIÇO POLICIAL	103.73	058.00093837/202630	2026-10-13 17:57:00.859604	378	\N	2026PD00336
628	18208623806	1	2026-01-11	LIMEIRA	PLANTAO POLICIAL LIMEIRA	207.46	058.00004380/202605	2026-10-13 17:57:00.859604	429	\N	2026PD00049
708	18208623806	2	2026-01-29	SAO PAULO	CURSO ACADEPOL APH	871.36	058.00014312/202646	2026-10-13 17:57:00.859604	462	\N	2026PD00059
629	18208623806	1	2026-03-06	JAGUARIUNA	SERVIÇO POLICIAL	69.15	058.00031183/202651	2026-10-13 17:57:00.859604	555	\N	2026PD00116
713	18208623806	2	2026-04-30	SALTINHO	CURSO ENTRADAS TATICAS	138.31	058.00053438/202639	2026-10-13 17:57:00.859604	546	\N	2026PD00162
630	18208623806	1	2026-07-13	LIMEIRA	PLANTAO POLICIAL LIMEIRA	207.46	058.00083424/202647	2026-10-13 17:57:00.859604	468	\N	2026PD00308
631	18208623806	1	2026-08-29	LIMEIRA	PLANTAO POLICIAL LIMEIRA	103.73	058.00104642/202622	2026-10-13 17:57:00.859604	419	\N	2026PD00402
434	19163513870	1	2026-01-01	PIRACICABA	PLANTAO POLICIAL LIMEIRA	207.46	058.00001044/202601	2026-10-13 17:57:00.859604	418	\N	2026PD00050
689	19174943863	1	2026-02-20	SAO PAULO	SERVIÇO POLICIAL	248.96	058.00024388/202680	2026-10-13 17:57:00.859604	427	\N	2026PD00071
447	19203432884	1	2026-04-15	SAO PAULO	SERVIÇO POLICIAL	248.96	058.00048533/202618	2026-10-13 17:57:00.859604	506	\N	2026PD00174
448	19203432884	1	2026-06-09	SAO PAULO	SERVIÇO POLICIAL	248.96	058.00070445/202601	2026-10-13 17:57:00.859604	453	\N	2026PD00285
639	19216935847	1	2026-03-06	JAGUARIUNA	SERVIÇO POLICIAL	69.15	058.00031520/202618	2026-10-13 17:57:00.859604	390	\N	2026PD00117
640	19216935847	1	2026-03-11	RIO CLARO	SERVIÇO POLICIAL	69.15	058.00033318/202612	2026-10-13 17:57:00.859604	421	\N	\N
812	19216935847	1	2026-04-16	LIMEIRA	SERVICO POLICIAL	103.73	058.00048851/202689	2026-10-14 15:17:54.234558	557	\N	\N
641	19216935847	1	2026-04-16	LIMEIRA	SERVIÇO POLICIAL	103.73	058.00048851/202689	2026-10-13 17:57:00.859604	557	\N	\N
517	21360741801	1	2026-02-12	CAPIVARI	SERVIÇO POLICIAL	138.31	058.00021480/202698	2026-10-13 17:57:00.859604	417	\N	2026PD00072
518	21360741801	1	2026-03-13	PIRACICABA	SERVIÇO POLICIAL	53.78	058.00035389/202650	2026-10-13 17:57:00.859604	499	\N	2026PD00118
519	21360741801	1	2026-03-20	SAO PAULO	SERVIÇO POLICIAL	96.81	058.00037136/202611	2026-10-13 17:57:00.859604	536	\N	2026PD00118
534	21675933847	1	2026-02-26	POÇOS DE CALDAS	SERVIÇO POLICIAL	207.46	058.00028495/202687	2026-10-13 17:57:00.859604	545	\N	2026PD00119
559	22444646878	1	2026-02-19	PIRACICABA	PLANTAO POLICIAL LIMEIRA	207.46	058.00024300/202620	2026-10-13 17:57:00.859604	449	\N	2026PD00073
533	24886549810	1	2026-04-15	SAO PAULO	SERVIÇO POLICIAL	248.96	058.00048535/202615	2026-10-13 17:57:00.859604	525	\N	2026PD00175
435	24999284847	1	2026-01-19	PIRACICABA	PLANTAO POLICIAL LIMEIRA	138.31	058.00007397/202614	2026-10-13 17:57:00.859604	478	\N	2026PD00051
436	24999284847	1	2026-05-14	LIMEIRA	PLANTAO POLICIAL LIMEIRA	138.31	058.00059627/202612	2026-10-13 17:57:00.859604	398	\N	2026PD00240
437	24999284847	1	2026-06-15	LIMEIRA	PLANTAO POLICIAL LIMEIRA	138.31	058.00071344/202649	2026-10-13 17:57:00.859604	552	\N	2026PD00286
438	24999284847	1	2026-07-18	LIMEIRA	PLANTAO POLICIAL LIMEIRA	138.31	058.00085564/202650	2026-10-13 17:57:00.859604	535	\N	2026PD00309
439	24999284847	1	2026-07-24	LIMEIRA	PLANTAO POLICIAL LIMEIRA	138.31	058.00087987/202612	2026-10-13 17:57:00.859604	395	\N	2026PD00309
440	24999284847	1	2026-08-08	LIMEIRA	PLANTAO POLICIAL LIMEIRA	138.31	058.00094899/202669	2026-10-13 17:57:00.859604	517	\N	2026PD00342
644	26451064807	1	2026-06-16	RIO DE JANEIRO	SERVIÇO POLICIAL	822.94	058.00074761/202643	2026-10-13 17:57:00.859604	487	\N	\N
511	27057183895	1	2026-01-10	LIMEIRA	PLANTAO POLICIAL LIMEIRA	138.31	058.00004579/202625	2026-10-13 17:57:00.859604	549	\N	2026PD00052
512	27057183895	1	2026-02-21	LIMEIRA	PLANTAO POLICIAL LIMEIRA	138.31	058.00023653/202611	2026-10-13 17:57:00.859604	475	\N	2026PD00083
513	27057183895	1	2026-05-17	LIMEIRA	PLANTAO POLICIAL LIMEIRA	138.31	058.00059942/202640	2026-10-13 17:57:00.859604	452	\N	2026PD00241
514	27057183895	1	2026-06-07	LIMEIRA	PLANTAO POLICIAL LIMEIRA	138.31	058.00068481/202604	2026-10-13 17:57:00.859604	368	\N	2026PD00288
515	27057183895	1	2026-06-21	LIMEIRA	PLANTAO POLICIAL LIMEIRA	138.31	058.00074673/202641	2026-10-13 17:57:00.859604	526	\N	2026PD00288
617	27206162819	1	2026-01-18	LIMEIRA	PLANTAO POLICIAL LIMEIRA	138.31	058.00010411/202659	2026-10-13 17:57:00.859604	486	\N	2026PD00053
618	27206162819	1	2026-03-22	LIMEIRA	PLANTAO POLICIAL LIMEIRA	138.31	058.00037432/202611	2026-10-13 17:57:00.859604	425	\N	2026PD00120
619	27206162819	1	2026-04-12	LIMEIRA	PLANTAO POLICIAL LIMEIRA	138.31	058.00047214/202695	2026-10-13 17:57:00.859604	447	\N	2026PD00176
620	27206162819	1	2026-05-04	LIMEIRA	PLANTAO POLICIAL LIMEIRA	138.31	058.00055452/202674	2026-10-13 17:57:00.859604	500	\N	2026PD00242
621	27206162819	1	2026-06-09	GUARULHOS	SERVIÇO POLICIAL	207.46	058.00070478/202642	2026-10-13 17:57:00.859604	380	\N	2026PD00289
622	27206162819	1	2026-06-20	LIMEIRA	PLANTAO POLICIAL LIMEIRA	138.31	058.00074505/202656	2026-10-13 17:57:00.859604	531	\N	2026PD00289
623	27206162819	1	2026-07-09	LIMEIRA	PLANTAO POLICIAL LIMEIRA	138.31	058.00082688/202683	2026-10-13 17:57:00.859604	376	\N	2026PD00310
624	27206162819	1	2026-08-09	LIMEIRA	PLANTAO POLICIAL LIMEIRA	138.31	058.00095060/202648	2026-10-13 17:57:00.859604	388	\N	\N
690	27935713855	1	2026-05-12	SAO PAULO	SERVIÇO POLICIAL	124.48	058.00059047/202625	2026-10-13 17:57:00.859604	483	\N	2026PD00243
691	27935713855	1	2026-05-20	SAO PAULO	SERVIÇO POLICIAL	124.48	058.00062241/202698	2026-10-13 17:57:00.859604	396	\N	2026PD00243
692	27935713855	1	2026-06-09	SAO PAULO	SERVIÇO POLICIAL	248.96	058.00070443/202611	2026-10-13 17:57:00.859604	508	\N	2026PD00243
693	29474854831	1	2026-08-05	BARUERI	SERVIÇO POLICIAL	80.68	058.00094473/202613	2026-10-13 17:57:00.859604	455	\N	\N
536	30310116864	1	2026-02-20	SAO PAULO	SERVIÇO POLICIAL	248.96	058.00023698/202687	2026-10-13 17:57:00.859604	451	\N	2026PD00074
751	30310116864	2	2026-02-25	SAO PAULO	CURSO ACADEPOL ACADEPOL	248.96	058.00027233/202603	2026-10-13 17:57:00.859604	476	\N	2026PD00085
752	30310116864	2	2026-02-26	SAO PAULO	CURSO ACADEPOL ACADEPOL	248.96	058.00027233/202603	2026-10-13 17:57:00.859604	476	\N	2026PD00085
753	30310116864	2	2026-02-27	SAO PAULO	CURSO ACADEPOL ACADEPOL	248.96	058.00027233/202603	2026-10-13 17:57:00.859604	476	\N	2026PD00085
632	30841335818	1	2026-06-09	SAO PAULO	SERVIÇO POLICIAL	248.96	058.00070660/202601	2026-10-13 17:57:00.859604	439	\N	\N
633	30841335818	1	2026-07-09	SAO PAULO	SERVIÇO POLICIAL	248.96	058.00070660/202601	2026-10-13 17:57:00.859604	439	\N	\N
538	31082697800	1	2026-08-17	PIRACICABA	SERVIÇO POLICIAL	103.73	058.00098567/202653	2026-10-13 17:57:00.859604	474	\N	2026PD00402
544	31239665857	1	2026-02-10	SAO PAULO	SERVIÇO POLICIAL	248.96	058.00020995/202671	2026-10-13 17:57:00.859604	510	\N	2026PD00075
545	31239665857	1	2026-03-06	JAGUARIUNA	SERVIÇO POLICIAL	69.15	058.00031514/202652	2026-10-13 17:57:00.859604	504	\N	2026PD00121
546	31239665857	1	2026-03-11	RIO CLARO	SERVIÇO POLICIAL	69.15	058.00034447/202628	2026-10-13 17:57:00.859604	481	\N	2026PD00121
535	31892853817	1	2026-03-06	JAGUARIUNA	SERVIÇO POLICIAL	69.15	058.00031519/202685	2026-10-13 17:57:00.859604	385	\N	2026PD00122
746	31892853817	2	2026-04-17	PIRACICABA	CURSO ACADEPOL TAT  I	103.73	058.00040442/202642	2026-10-13 17:57:00.859604	432	\N	2026PD00163
747	31892853817	2	2026-04-19	CHARQUEADA	CURSO ACADEPOL TAT  I	138.31	058.00040442/202642	2026-10-13 17:57:00.859604	432	\N	2026PD00163
748	31892853817	2	2026-04-23	CHARQUEADA	CURSO ACADEPOL TAT  I	69.15	058.00040442/202642	2026-10-13 17:57:00.859604	432	\N	2026PD00163
749	31892853817	2	2026-04-26	PIRACICABA	CURSO ACADEPOL TAT  I	103.73	058.00052028/202678	2026-10-13 17:57:00.859604	382	\N	2026PD00163
526	32540502822	1	2026-01-07	PIRACICABA	PLANTAO POLICIAL LIMEIRA	207.46	058.00003397/202637	2026-10-13 17:57:00.859604	437	\N	2026PD00054
527	32540502822	1	2026-02-14	LIMEIRA	PLANTAO POLICIAL LIMEIRA	138.31	058.00021611/202637	2026-10-13 17:57:00.859604	402	\N	2026PD00076
735	32540502822	2	2026-03-05	SAO PAULO	CURSO APH	995.84	058.00021611/202637	2026-10-13 17:57:00.859604	402	\N	2026PD00132
528	32540502822	1	2026-04-25	LIMEIRA	SERVIÇO POLICIAL	138.31	058.00052142/202606	2026-10-13 17:57:00.859604	424	\N	2026PD00177
529	32540502822	1	2026-05-12	LIMEIRA	PLANTAO POLICIAL LIMEIRA	138.31	058.00059213/202693	2026-10-13 17:57:00.859604	521	\N	2026PD00244
530	32540502822	1	2026-06-08	LIMEIRA	PLANTAO POLICIAL LIMEIRA	138.31	058.00069566/202600	2026-10-13 17:57:00.859604	383	\N	206PD00290
531	32540502822	1	2026-07-20	LIMEIRA	PLANTAO POLICIAL LIMEIRA	138.31	058.00086330/202620	2026-10-13 17:57:00.859604	529	\N	2026PD00311
532	32540502822	1	2026-08-26	LIMEIRA	PLANTAO POLICIAL LIMEIRA	138.31	058.00101723/202671	2026-10-13 17:57:00.859604	414	\N	2026PD00402
772	32628691809	2	2026-04-14	PIRACICABA	CURSO ACADEPOL	69.15	058.00048528/202613	2026-10-13 17:57:00.859604	413	\N	2026PD00164
773	32628691809	2	2026-05-04	PIRACICABA	CURSO ACADEPOL	69.15	058.00055990/202669	2026-10-13 17:57:00.859604	561	\N	2026PD00221
774	32628691809	2	2026-05-05	PIRACICABA	CURSO ACADEPOL	69.15	058.00055999/202670	2026-10-13 17:57:00.859604	550	\N	2026PD00221
803	32628691809	2	2026-05-06	PIRACICABA	CURSO ACADEPOL	69.15	058.00056002/202607	2026-10-13 17:57:00.859604	428	\N	2026PD00221
646	32968804880	1	2026-01-27	PIRACICABA	PLANTAO POLICIAL LIMEIRA	207.46	058.00012728/202620	2026-10-13 17:57:00.859604	543	\N	\N
817	32968804880	1	2026-01-27	PIRACICABA	SERVICO POLICIAL	207.46	058.00012728/202620	2026-10-14 15:33:21.063693	543	\N	\N
818	32968804880	1	2026-02-17	LIMEIRA	SERVICO POLICIAL	103.73	058.00022386/202656	2026-10-14 15:36:06.032777	387	\N	\N
647	32968804880	1	2026-02-17	LIMEIRA	SERVIÇO POLICIAL	103.73	058.00022386/202656	2026-10-13 17:57:00.859604	387	\N	\N
819	32968804880	1	2026-03-06	JAGARIUNA	SERVICO POLICIAL	69.15	058.00031510/202674	2026-10-14 15:38:52.861027	512	\N	\N
648	32968804880	1	2026-03-06	JAGUARIUNA	SERVIÇO POLICIAL	69.15	058.00031510/202674	2026-10-13 17:57:00.859604	512	\N	\N
769	32968804880	2	2026-08-27	SAO PAULO	AGOSTO LILAS	248.96	058.00102590/202650	2026-10-13 17:57:00.859604	553	\N	2026PD00368
702	33648957830	2	2026-05-04	PIRACICABA	CURSO ACADEPOL	69.15	058.00056878/202645	2026-10-13 17:57:00.859604	520	\N	2026PD00222
707	33648957830	2	2026-05-05	PIRACICABA	CURSO ACADEPOL	69.15	058.00056878/202645	2026-10-13 17:57:00.859604	520	\N	2026PD00222
710	33648957830	2	2026-05-06	PIRACICABA	CURSO ACADEPOL	69.15	058.00056878/202645	2026-10-13 17:57:00.859604	520	\N	2026PD00222
758	33648957830	2	2026-06-25	PIRACICABA	CURSO ACADEPOL	69.15	058.00078792/202673	2026-10-13 17:57:00.859604	493	\N	2026PD00261
770	33648957830	2	2026-06-26	PIRACICABA	CURSO ACADEPOL	69.15	058.00078792/202673	2026-10-13 17:57:00.859604	493	\N	2026PD00261
730	35313574841	2	2026-06-25	PIRACICABA	CURSO ACADEPOL	69.15	058.00078470/202624	2026-10-13 17:57:00.859604	445	\N	2026PD00262
731	35313574841	2	2026-06-26	PIRACICABA	CURSO ACADEPOL	69.15	058.00078470/202624	2026-10-13 17:57:00.859604	445	\N	2026PD00262
826	35500297805	2	2026-04-19	CHARQUEADA	CUSRO TAT I	69.15	058.00051312/202627	2026-10-14 16:11:58.837708	374	\N	2026PD00165
705	35500297805	2	2026-04-23	CHARQUEADA	CURSO ACADEPOL TAT  I	69.15	058.00051312/202627	2026-10-13 17:57:00.859604	374	\N	2026PD00165
706	35500297805	2	2026-04-26	CHARQUEADA	CURSO ACADEPOL TAT  I	69.15	058.00051312/202627	2026-10-13 17:57:00.859604	374	\N	2026PD00165
816	35500297805	1	2026-06-19	RIO DE JANEIRO	SERVICO POLICIAL	822.94	058.00074727/202679	2026-10-14 15:30:36.609726	399	\N	\N
645	35500297805	1	2026-06-19	RIO DE JANEIRO	SERVIÇO POLICIAL	822.94	058.00074727/202679	2026-10-13 17:57:00.859604	399	\N	\N
771	35932472839	2	2026-03-27	PIRACICABA	CURSO TIRO	69.15	058.00041533/202668	2026-10-13 17:57:00.859604	511	\N	2026PD00133
547	36025331820	1	2026-02-07	PIRACICABA	PLANTAO POLICIAL LIMEIRA	207.46	058.00018728/202633	2026-10-13 17:57:00.859604	477	\N	2026PD00078
548	36025331820	1	2026-03-16	SAO PAULO	SERVIÇO POLICIAL	248.96	058.00036565/202671	2026-10-13 17:57:00.859604	524	\N	2026PD00124
634	36750397816	1	2026-02-04	CAPIVARI	SERVIÇO POLICIAL	138.31	058.00020892/202619	2026-10-13 17:57:00.859604	513	\N	2026PD00079
635	36750397816	1	2026-03-10	MONTE MOR	SERVIÇO POLICIAL	69.15	058.00033148/202676	2026-10-13 17:57:00.859604	442	\N	2026PD00125
636	36750397816	1	2026-03-13	PIRACICABA	SERVIÇO POLICIAL	69.15	058.00035638/202615	2026-10-13 17:57:00.859604	373	\N	2026PD00125
637	36750397816	1	2026-04-09	SAO PAULO	SERVIÇO POLICIAL	248.96	058.00045732/202674	2026-10-13 17:57:00.859604	482	\N	2026PD00178
722	36819640846	2	2026-08-27	SAO PAULO	AGOSTO LILAS	248.96	058.00101929/202609	2026-10-13 17:57:00.859604	515	\N	2026PD00369
543	38355373855	1	2026-08-05	PIRACICABA	SERVIÇO POLICIAL	103.73	058.00094564/202641	2026-10-13 17:57:00.859604	507	\N	2026PD00402
549	39460172822	1	2026-01-27	PIRACICABA	PLANTAO POLICIAL LIMEIRA	207.46	058.00012100/202624	2026-10-13 17:57:00.859604	544	\N	2026PD00056
550	39460172822	1	2026-02-10	SAO PAULO	SERVIÇO POLICIAL	248.96	058.00020495/202639	2026-10-13 17:57:00.859604	548	\N	2026PD00080
551	39460172822	1	2026-02-22	LIMEIRA	PLANTAO POLICIAL LIMEIRA	207.46	058.00023999/202619	2026-10-13 17:57:00.859604	394	\N	2026PD00080
552	39460172822	1	2026-03-06	JAGUARIUNA	SERVIÇO POLICIAL	69.15	058.00031184/202603	2026-10-13 17:57:00.859604	554	\N	2026PD00126
553	39460172822	1	2026-04-26	LIMEIRA	SERVIÇO POLICIAL	207.45	058.00051656/202636	2026-10-13 17:57:00.859604	551	\N	2026PD00179
554	39460172822	1	2026-06-12	LIMEIRA	PLANTAO POLICIAL LIMEIRA	207.46	058.00074738/202659	2026-10-13 17:57:00.859604	497	\N	2026PD00292
555	39460172822	1	2026-06-25	LIMEIRA	PLANTAO POLICIAL LIMEIRA	207.46	058.00077762/202640	2026-10-13 17:57:00.859604	401	\N	2026PD00292
712	39460172822	2	2026-06-25	SAO PAULO	SEMINARIO	248.96	058.00077762/202640	2026-10-13 17:57:00.859604	401	\N	2026PD00292
556	39460172822	1	2026-07-03	LIMEIRA	PLANTAO POLICIAL LIMEIRA	207.46	058.00080648/202605	2026-10-13 17:57:00.859604	540	\N	2026PD00313
557	39460172822	1	2026-08-22	LIMEIRA	PLANTAO POLICIAL LIMEIRA	207.46	058.00099842/202656	2026-10-13 17:57:00.859604	426	\N	2026PD00402
539	40381911845	1	2026-02-25	SAO PAULO	SERVIÇO POLICIAL	248.96	058.00027335/202611	2026-10-13 17:57:00.859604	498	\N	2026PD00081
540	40381911845	1	2026-02-26	POÇOS DE CALDAS	SERVIÇO POLICIAL	207.46	058.00027352/202658	2026-10-13 17:57:00.859604	410	\N	2026PD00081
759	40381911845	2	2026-03-16	SAO PAULO	CURSO OPERACIONAL PMSP	248.96	058.00041483/202648	2026-10-13 17:57:00.859604	509	\N	2026PD00134
760	40381911845	2	2026-03-17	SAO PAULO	CURSO OPERACIONAL PMSP	248.96	058.00041483/202648	2026-10-13 17:57:00.859604	509	\N	2026PD00134
761	40381911845	2	2026-03-18	SAO PAULO	CURSO OPERACIONAL PMSP	248.96	058.00041483/202648	2026-10-13 17:57:00.859604	509	\N	2026PD00134
762	40381911845	2	2026-03-19	SAO PAULO	CURSO OPERACIONAL PMSP	248.96	058.00041483/202648	2026-10-13 17:57:00.859604	509	\N	2026PD00134
763	40381911845	2	2026-03-20	SAO PAULO	CURSO OPERACIONAL PMSP	248.96	058.00041483/202648	2026-10-13 17:57:00.859604	509	\N	2026PD00134
764	40381911845	2	2026-03-23	SAO PAULO	CURSO OPERACIONAL PMSP	248.96	058.00041483/202648	2026-10-13 17:57:00.859604	509	\N	2026PD00134
765	40381911845	2	2026-03-24	SAO PAULO	CURSO OPERACIONAL PMSP	248.96	058.00041483/202648	2026-10-13 17:57:00.859604	509	\N	2026PD00134
766	40381911845	2	2026-03-25	SAO PAULO	CURSO OPERACIONAL PMSP	248.96	058.00041483/202648	2026-10-13 17:57:00.859604	509	\N	2026PD00134
767	40381911845	2	2026-03-26	SAO PAULO	CURSO OPERACIONAL PMSP	248.96	058.00041483/202648	2026-10-13 17:57:00.859604	509	\N	2026PD00134
768	40381911845	2	2026-03-27	SAO PAULO	CURSO OPERACIONAL PMSP	248.96	058.00041483/202648	2026-10-13 17:57:00.859604	509	\N	2026PD00134
541	40381911845	1	2026-06-19	RIO DE JANEIRO	SERVIÇO POLICIAL	822.94	058.00074738/2026-59	2026-10-13 17:57:00.859604	518	\N	2026PD00293
442	40952268892	1	2026-02-12	CAPIVARI	SERVIÇO POLICIAL	138.31	058.00020923/202623	2026-10-13 17:57:00.859604	406	\N	2026PD00082
443	40952268892	1	2026-03-10	MONTE MOR	SERVIÇO POLICIAL	69.15	058.00033157/202667	2026-10-13 17:57:00.859604	392	\N	2026PD00127
444	40952268892	1	2026-03-13	PIRACICABA	SERVIÇO POLICIAL	69.15	058.00035649/202697	2026-10-13 17:57:00.859604	527	\N	2026PD00127
445	40952268892	1	2026-04-09	SAO PAULO	SERVIÇO POLICIAL	248.96	058.00045723/202683	2026-10-13 17:57:00.859604	467	\N	2026PD00180
396	42582609838	1	2026-01-01	PIRACICABA	PLANTAO POLICIAL LIMEIRA	207.46	058.00001037/202609	2026-10-13 17:57:00.859604	375	\N	2026PD00057
397	42582609838	1	2026-02-08	LIMEIRA	PLANTAO POLICIAL LIMEIRA	69.15	058.00018050/202699	2026-10-13 17:57:00.859604	514	\N	2026PD00083
398	42582609838	1	2026-02-12	LIMEIRA	PLANTAO POLICIAL LIMEIRA	207.46	058.00024277/202673	2026-10-13 17:57:00.859604	503	\N	2026PD00083
399	42582609838	1	2026-03-07	LIMEIRA	PLANTAO POLICIAL LIMEIRA	69.15	058.00031765/202637	2026-10-13 17:57:00.859604	416	\N	2026PD00128
700	42582609838	2	2026-03-16	SAO PAULO	SEMINARIO FEMINICIDIO	248.96	058.00036561/202692	2026-10-13 17:57:00.859604	464	\N	2026PD00135
701	42582609838	2	2026-03-26	RIO CLARO	CURSO TIRO	69.15	058.00040322/202637	2026-10-13 17:57:00.859604	490	\N	2026PD00135
504	42582609838	1	2026-03-29	LIMEIRA	PLANTAO POLICIAL LIMEIRA	69.15	058.00040310/202611	2026-10-13 17:57:00.859604	441	\N	2026PD00128
505	42582609838	1	2026-04-21	LIMEIRA	PLANTAO POLICIAL LIMEIRA	69.15	058.00052538/202645	2026-10-13 17:57:00.859604	537	\N	2026PD00166
704	42582609838	2	2026-04-23	SAO PAULO	PALESTRA ACADEPOL	124.48	058.00052548/202681	2026-10-13 17:57:00.859604	433	\N	2026PD00166
506	42582609838	1	2026-05-09	LIMEIRA	PLANTAO POLICIAL LIMEIRA	69.15	058.00057813/202617	2026-10-13 17:57:00.859604	369	\N	2026PD00245
507	42582609838	1	2026-06-29	LIMEIRA	PLANTAO POLICIAL LIMEIRA	138.31	058.00081687/202611	2026-10-13 17:57:00.859604	397	\N	2026PD00128
508	42582609838	1	2026-07-11	LIMEIRA	PLANTAO POLICIAL LIMEIRA	69.15	058.00084233/202601	2026-10-13 17:57:00.859604	563	\N	2026PD00314
509	42582609838	1	2026-07-28	LIMEIRA	PLANTAO POLICIAL LIMEIRA	138.31	058.00090988/202636	2026-10-13 17:57:00.859604	379	\N	2026PD00337
709	42582609838	2	2026-08-27	LIMEIRA	AGOSTO LILAS	248.96	058.00102757/202682	2026-10-13 17:57:00.859604	431	\N	2026PD00370
510	42582609838	1	2026-08-28	LIMEIRA	PLANTAO POLICIAL LIMEIRA	138.31	058.00102726/202621	2026-10-13 17:57:00.859604	407	\N	2026PD00402
711	42582609838	2	2026-09-02	LIMEIRA	VIOLENCIA DE GENERO	248.96	058.00105727/202628	2026-10-13 17:57:00.859604	456	\N	2026PD00370
757	42610681844	2	2026-03-26	RIO CLARO	CURSO TIRO	107.57	058.00040956/202690	2026-10-13 17:57:00.859604	471	\N	2026PD00167
562	42610681844	1	2026-05-20	SAO PAULO	SERVIÇO POLICIAL	193.63	058.00063384/202617	2026-10-13 17:57:00.859604	559	\N	2026PD00246
563	42610681844	1	2026-06-09	SAO PAULO	SERVIÇO POLICIAL	193.63	058.00070670/202639	2026-10-13 17:57:00.859604	411	\N	2026PD00294
525	43992425827	1	2026-01-07	PIRACICABA	PLANTAO POLICIAL LIMEIRA	207.46	058.00003563/202603	2026-10-13 17:57:00.859604	463	\N	2026PD00058
449	44519520851	1	2026-06-01	LIMEIRA	SERVIÇO POLICIAL	69.15	058.00080283/202619	2026-10-13 17:57:00.859604	420	\N	2026PD00297
450	44519520851	1	2026-06-02	LIMEIRA	SERVIÇO POLICIAL	69.15	058.00080283/202619	2026-10-13 17:57:00.859604	420	\N	2026PD00297
451	44519520851	1	2026-06-03	LIMEIRA	SERVIÇO POLICIAL	69.15	058.00080283/202619	2026-10-13 17:57:00.859604	420	\N	2026PD00297
452	44519520851	1	2026-06-04	LIMEIRA	SERVIÇO POLICIAL	69.15	058.00080283/202619	2026-10-13 17:57:00.859604	420	\N	2026PD00297
453	44519520851	1	2026-06-05	LIMEIRA	SERVIÇO POLICIAL	69.15	058.00080283/202619	2026-10-13 17:57:00.859604	420	\N	2026PD00297
454	44519520851	1	2026-06-08	LIMEIRA	SERVIÇO POLICIAL	69.15	058.00080283/202619	2026-10-13 17:57:00.859604	420	\N	2026PD00297
455	44519520851	1	2026-06-09	LIMEIRA	SERVIÇO POLICIAL	69.15	058.00080283/202619	2026-10-13 17:57:00.859604	420	\N	2026PD00297
456	44519520851	1	2026-06-10	LIMEIRA	SERVIÇO POLICIAL	69.15	058.00080283/202619	2026-10-13 17:57:00.859604	420	\N	2026PD00297
457	44519520851	1	2026-06-11	LIMEIRA	SERVIÇO POLICIAL	69.15	058.00080283/202619	2026-10-13 17:57:00.859604	420	\N	2026PD00297
458	44519520851	1	2026-06-12	LIMEIRA	SERVIÇO POLICIAL	69.15	058.00080283/202619	2026-10-13 17:57:00.859604	420	\N	2026PD00297
459	44519520851	1	2026-06-15	LIMEIRA	SERVIÇO POLICIAL	69.15	058.00080283/202619	2026-10-13 17:57:00.859604	420	\N	2026PD00297
460	44519520851	1	2026-06-16	LIMEIRA	SERVIÇO POLICIAL	69.15	058.00080283/202619	2026-10-13 17:57:00.859604	420	\N	2026PD00297
461	44519520851	1	2026-06-17	LIMEIRA	SERVIÇO POLICIAL	69.15	058.00080283/202619	2026-10-13 17:57:00.859604	420	\N	2026PD00297
462	44519520851	1	2026-06-18	LIMEIRA	SERVIÇO POLICIAL	69.15	058.00080283/202619	2026-10-13 17:57:00.859604	420	\N	2026PD00297
463	44519520851	1	2026-06-19	LIMEIRA	SERVIÇO POLICIAL	69.15	058.00080283/202619	2026-10-13 17:57:00.859604	420	\N	2026PD00297
464	44519520851	1	2026-06-22	LIMEIRA	SERVIÇO POLICIAL	69.15	058.00080283/202619	2026-10-13 17:57:00.859604	420	\N	2026PD00297
465	44519520851	1	2026-06-23	LIMEIRA	SERVIÇO POLICIAL	69.15	058.00080283/202619	2026-10-13 17:57:00.859604	420	\N	2026PD00297
466	44519520851	1	2026-06-24	LIMEIRA	SERVIÇO POLICIAL	69.15	058.00080283/202619	2026-10-13 17:57:00.859604	420	\N	2026PD00297
467	44519520851	1	2026-06-25	LIMEIRA	SERVIÇO POLICIAL	69.15	058.00080283/202619	2026-10-13 17:57:00.859604	420	\N	2026PD00297
468	44519520851	1	2026-06-26	LIMEIRA	SERVIÇO POLICIAL	69.15	058.00080283/202619	2026-10-13 17:57:00.859604	420	\N	2026PD00297
469	44519520851	1	2026-07-14	LIMEIRA	ACUMULO DE FUNÇÃO	69.15	058.00092795/202610	2026-10-13 17:57:00.859604	496	\N	2026PD00338
470	44519520851	1	2026-07-15	LIMEIRA	ACUMULO DE FUNÇÃO	69.15	058.00092795/202610	2026-10-13 17:57:00.859604	496	\N	2026PD00338
471	44519520851	1	2026-07-16	LIMEIRA	ACUMULO DE FUNÇÃO	69.15	058.00092795/202610	2026-10-13 17:57:00.859604	496	\N	2026PD00338
472	44519520851	1	2026-07-17	LIMEIRA	ACUMULO DE FUNÇÃO	69.15	058.00092795/202610	2026-10-13 17:57:00.859604	496	\N	2026PD00338
473	44519520851	1	2026-07-20	LIMEIRA	ACUMULO DE FUNÇÃO	69.15	058.00092795/202610	2026-10-13 17:57:00.859604	496	\N	2026PD00338
474	44519520851	1	2026-07-21	LIMEIRA	ACUMULO DE FUNÇÃO	69.15	058.00092795/202610	2026-10-13 17:57:00.859604	496	\N	2026PD00338
475	44519520851	1	2026-07-22	LIMEIRA	ACUMULO DE FUNÇÃO	69.15	058.00092795/202610	2026-10-13 17:57:00.859604	496	\N	2026PD00338
476	44519520851	1	2026-07-23	LIMEIRA	ACUMULO DE FUNÇÃO	69.15	058.00092795/202610	2026-10-13 17:57:00.859604	496	\N	2026PD00338
477	44519520851	1	2026-07-24	LIMEIRA	ACUMULO DE FUNÇÃO	69.15	058.00092795/202610	2026-10-13 17:57:00.859604	496	\N	2026PD00338
478	44519520851	1	2026-07-27	LIMEIRA	ACUMULO DE FUNÇÃO	69.15	058.00092795/202610	2026-10-13 17:57:00.859604	496	\N	2026PD00338
479	44519520851	1	2026-07-28	LIMEIRA	ACUMULO DE FUNÇÃO	69.15	058.00092795/202610	2026-10-13 17:57:00.859604	496	\N	2026PD00338
480	44519520851	1	2026-07-29	LIMEIRA	ACUMULO DE FUNÇÃO	69.15	058.00092795/202610	2026-10-13 17:57:00.859604	496	\N	2026PD00338
481	44519520851	1	2026-07-30	LIMEIRA	ACUMULO DE FUNÇÃO	69.15	058.00092795/202610	2026-10-13 17:57:00.859604	496	\N	2026PD00338
482	44519520851	1	2026-07-31	LIMEIRA	ACUMULO DE FUNÇÃO	69.15	058.00092795/202610	2026-10-13 17:57:00.859604	496	\N	2026PD00338
483	44519520851	1	2026-08-03	LIMEIRA	ACUMULO DE FUNÇÃO	69.15	058.00103808/202693	2026-10-13 17:57:00.859604	465	\N	2026PD00402
484	44519520851	1	2026-08-04	LIMEIRA	ACUMULO DE FUNÇÃO	69.15	058.00103808/202693	2026-10-13 17:57:00.859604	465	\N	2026PD00402
485	44519520851	1	2026-08-05	LIMEIRA	ACUMULO DE FUNÇÃO	69.15	058.00103808/202693	2026-10-13 17:57:00.859604	465	\N	2026PD00402
486	44519520851	1	2026-08-06	LIMEIRA	ACUMULO DE FUNÇÃO	69.15	058.00103808/202693	2026-10-13 17:57:00.859604	465	\N	2026PD00402
487	44519520851	1	2026-08-07	LIMEIRA	ACUMULO DE FUNÇÃO	69.15	058.00103808/202693	2026-10-13 17:57:00.859604	465	\N	2026PD00402
488	44519520851	1	2026-08-10	LIMEIRA	ACUMULO DE FUNÇÃO	69.15	058.00103808/202693	2026-10-13 17:57:00.859604	465	\N	2026PD00402
489	44519520851	1	2026-08-11	LIMEIRA	ACUMULO DE FUNÇÃO	69.15	058.00103808/202693	2026-10-13 17:57:00.859604	465	\N	2026PD00402
490	44519520851	1	2026-08-12	LIMEIRA	ACUMULO DE FUNÇÃO	69.15	058.00103808/202693	2026-10-13 17:57:00.859604	465	\N	2026PD00402
491	44519520851	1	2026-08-13	LIMEIRA	ACUMULO DE FUNÇÃO	69.15	058.00103808/202693	2026-10-13 17:57:00.859604	465	\N	2026PD00402
492	44519520851	1	2026-08-14	LIMEIRA	ACUMULO DE FUNÇÃO	69.15	058.00103808/202693	2026-10-13 17:57:00.859604	465	\N	2026PD00402
493	44519520851	1	2026-08-17	LIMEIRA	ACUMULO DE FUNÇÃO	69.15	058.00103808/202693	2026-10-13 17:57:00.859604	465	\N	2026PD00402
494	44519520851	1	2026-08-18	LIMEIRA	ACUMULO DE FUNÇÃO	69.15	058.00103808/202693	2026-10-13 17:57:00.859604	465	\N	2026PD00402
495	44519520851	1	2026-08-19	LIMEIRA	ACUMULO DE FUNÇÃO	69.15	058.00103808/202693	2026-10-13 17:57:00.859604	465	\N	2026PD00402
496	44519520851	1	2026-08-20	LIMEIRA	ACUMULO DE FUNÇÃO	69.15	058.00103808/202693	2026-10-13 17:57:00.859604	465	\N	2026PD00402
497	44519520851	1	2026-08-21	LIMEIRA	ACUMULO DE FUNÇÃO	69.15	058.00103808/202693	2026-10-13 17:57:00.859604	465	\N	2026PD00402
498	44519520851	1	2026-08-24	LIMEIRA	ACUMULO DE FUNÇÃO	69.15	058.00103808/202693	2026-10-13 17:57:00.859604	465	\N	2026PD00402
499	44519520851	1	2026-08-25	LIMEIRA	ACUMULO DE FUNÇÃO	69.15	058.00103808/202693	2026-10-13 17:57:00.859604	465	\N	2026PD00402
500	44519520851	1	2026-08-26	LIMEIRA	ACUMULO DE FUNÇÃO	69.15	058.00103808/202693	2026-10-13 17:57:00.859604	465	\N	2026PD00402
501	44519520851	1	2026-08-27	LIMEIRA	ACUMULO DE FUNÇÃO	69.15	058.00103808/202693	2026-10-13 17:57:00.859604	465	\N	2026PD00402
502	44519520851	1	2026-08-28	LIMEIRA	ACUMULO DE FUNÇÃO	69.15	058.00103808/202693	2026-10-13 17:57:00.859604	465	\N	2026PD00402
503	44519520851	1	2026-08-31	LIMEIRA	ACUMULO DE FUNÇÃO	69.15	058.00103808/202693	2026-10-13 17:57:00.859604	465	\N	2026PD00402
516	46508753827	1	2026-04-09	SAO PAULO	SERVIÇO POLICIAL	248.96	058.00045929/202611	2026-10-13 17:57:00.859604	502	\N	2026PD00183
718	46508753827	2	2026-05-04	PIRACICABA	CURSO ACADEPOL	69.15	058.00056375/202670	2026-10-13 17:57:00.859604	541	\N	2026PD00223
719	46508753827	2	2026-05-05	PIRACICABA	CURSO ACADEPOL	69.15	058.00056379/202658	2026-10-13 17:57:00.859604	489	\N	2026PD00223
720	46508753827	2	2026-05-06	PIRACICABA	CURSO ACADEPOL	69.15	058.00056381/202627	2026-10-13 17:57:00.859604	491	\N	2026PD00223
564	47033640854	1	2026-06-19	RIO DE JANEIRO	SERVIÇO POLICIAL	822.94	058.00074730/202692	2026-10-13 17:57:00.859604	558	\N	2026PD00295
537	80184782104	1	2026-08-05	BARUERI	SERVIÇO POLICIAL	103.73	058.00094690/202603	2026-10-13 17:57:00.859604	534	\N	2026PD00343
802	82897123915	2	2026-04-23	SALTINHO	CURSO ACADEPOL	138.31	058.00052368/202607	2026-10-13 17:57:00.859604	556	\N	2026PD00168
\.


--
-- Data for Name: diarias_bkp_20261021_v2; Type: TABLE DATA; Schema: backup; Owner: postgres
--

COPY backup.diarias_bkp_20261021_v2 (id_diaria, cpf_servidor, id_tipo, data_inicial, destino, motivo, valor_diaria, processo, data_cadastro, id_processo, observacao, numero_pd) FROM stdin;
850	18208623806	2	2026-05-25	SAO PAULO	PALESTRA SISTEMA DE JUSTICA	248.96	\N	2026-10-21 09:58:26.750297	450	\N	2026PD00220
834	85920356510	2	2026-09-26	PIRACICABA	CURSO MBA	103.73	058.00114776/202651	2026-10-15 15:54:20.108825	583	\N	2026PD00418
835	10995999899	1	2026-09-01	LIMEIRA	ACUMULO DE FUNCAO	107.57	058.00116234/202613	2026-10-15 15:55:55.417902	584	\N	2026PD00419
836	10995999899	1	2026-09-04	LIMEIRA	ACUMULO DE FUNCAO	107.57	058.00116234/202613	2026-10-15 15:56:01.455005	584	\N	2026PD00419
837	10995999899	1	2026-09-07	LIMEIRA	ACUMULO DE FUNCAO	107.57	058.00116234/202613	2026-10-15 15:56:06.780392	584	\N	2026PD00419
838	10995999899	1	2026-09-10	LIMEIRA	ACUMULO DE FUNCAO	107.57	058.00116234/202613	2026-10-15 15:56:12.032533	584	\N	2026PD00419
839	10995999899	1	2026-09-13	LIMEIRA	ACUMULO DE FUNCAO	107.57	058.00116234/202613	2026-10-15 15:56:20.680416	584	\N	2026PD00419
840	10995999899	1	2026-09-14	LIMEIRA	ACUMULO DE FUNCAO	107.57	058.00116234/202613	2026-10-15 15:56:26.064817	584	\N	2026PD00419
841	10995999899	1	2026-09-16	LIMEIRA	ACUMULO DE FUNCAO	107.57	058.00116234/202613	2026-10-15 15:56:32.12167	584	\N	2026PD00419
842	10995999899	1	2026-09-22	LIMEIRA	ACUMULO DE FUNCAO	107.57	058.00116234/202613	2026-10-15 15:56:38.802749	584	\N	2026PD00419
843	10995999899	1	2026-09-25	LIMEIRA	ACUMULO DE FUNCAO	107.57	058.00116234/202613	2026-10-15 15:56:43.449109	584	\N	2026PD00419
844	10995999899	1	2026-09-28	LIMEIRA	ACUMULO DE FUNCAO	107.57	058.00116234/202613	2026-10-15 15:56:49.346365	584	\N	2026PD00419
845	09085540950	1	2026-09-25	SAO PAULO	SERVIÇO POLICIAL	124.48	058.00116140/202644	2026-10-15 15:58:54.507043	585	\N	2026PD00420
847	13934950876	1	2026-09-26	LIMEIRA	ACUMULO DE FUNCAO	161.36	058.00116200/202629	2026-10-15 16:01:12.186859	586	\N	2026PD00421
848	13934950876	1	2026-09-27	LIMEIRA	ACUMULO DE FUNCAO	161.36	058.00116200/202629	2026-10-15 16:01:20.301849	586	\N	2026PD00421
849	13934950876	1	2026-09-28	LIMEIRA	ACUMULO DE FUNCAO	161.36	058.00116200/202629	2026-10-15 16:01:27.748525	586	\N	2026PD00421
813	07902044792	1	2026-04-09	SAO PAULO	SERVICO POLICIAL	124.48	058.00046220/202625	2026-10-14 15:20:48.32486	562	\N	2026PD00171
642	07902044792	1	2026-04-09	SAO PAULO	SERVIÇO POLICIAL	124.48	058.00046220/202625	2026-10-13 17:57:00.859604	562	\N	2026PD00171
814	09595897833	1	2026-02-12	CAPIVARI	SERVICO POLICIAL	69.15	058.00021373/202660	2026-10-14 15:23:19.777539	412	\N	2026PD00069
643	09595897833	1	2026-02-12	CAPIVARI	SERVIÇO POLICIAL	69.15	058.00021373/202660	2026-10-13 17:57:00.859604	412	\N	2026PD00069
649	10410326682	1	2026-01-07	PIRACICABA	PLANTAO POLICIAL LIMEIRA	207.46	058.00003690/202602	2026-10-13 17:57:00.859604	446	\N	2026PD00047
651	10410326682	1	2026-02-14	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	138.31	058.00031378/202609	2026-10-13 17:57:00.859604	444	\N	2026PD00114
821	10410326682	1	2026-02-14	PIRASSUNUNGA	SERVICO POLICIAL	138.31	058.00031378/202609	2026-10-14 15:47:02.602612	444	\N	2026PD00114
652	10410326682	1	2026-02-15	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	138.31	058.00031378/202609	2026-10-13 17:57:00.859604	444	\N	2026PD00114
822	10410326682	1	2026-02-15	PIRASSUNUNGA	SERVICO POLICIAL	138.31	058.00031378/202609	2026-10-14 15:47:17.322943	444	\N	2026PD00114
653	10410326682	1	2026-02-22	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	69.15	058.00031378/202609	2026-10-13 17:57:00.859604	444	\N	2026PD00114
825	10410326682	1	2026-02-22	PIRASSUNUNGA	SERVICO POLICIAL	69.15	058.00031378/202609	2026-10-14 15:47:48.416271	444	\N	2026PD00114
654	10410326682	1	2026-02-23	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	138.31	058.00031378/202609	2026-10-13 17:57:00.859604	444	\N	2026PD00114
823	10410326682	1	2026-02-23	PIRASSUNUNGA	SERVICO POLICIAL	138.31	058.00031378/202609	2026-10-14 15:47:26.244429	444	\N	2026PD00114
655	10410326682	1	2026-02-27	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	138.31	058.00031378/202609	2026-10-13 17:57:00.859604	444	\N	2026PD00114
824	10410326682	1	2026-02-27	PIRASSUNUNGA	SERVICO POLICIAL	138.31	058.00031378/202609	2026-10-14 15:47:32.122151	444	\N	2026PD00114
646	32968804880	1	2026-01-27	PIRACICABA	PLANTAO POLICIAL LIMEIRA	207.46	058.00012728/202620	2026-10-13 17:57:00.859604	543	\N	2026PD00055
817	32968804880	1	2026-01-27	PIRACICABA	SERVICO POLICIAL	207.46	058.00012728/202620	2026-10-14 15:33:21.063693	543	\N	2026PD00055
818	32968804880	1	2026-02-17	LIMEIRA	SERVICO POLICIAL	103.73	058.00022386/202656	2026-10-14 15:36:06.032777	387	\N	2026PD00077
647	32968804880	1	2026-02-17	LIMEIRA	SERVIÇO POLICIAL	103.73	058.00022386/202656	2026-10-13 17:57:00.859604	387	\N	2026PD00077
819	32968804880	1	2026-03-06	JAGARIUNA	SERVICO POLICIAL	69.15	058.00031510/202674	2026-10-14 15:38:52.861027	512	\N	2026PD00123
648	32968804880	1	2026-03-06	JAGUARIUNA	SERVIÇO POLICIAL	69.15	058.00031510/202674	2026-10-13 17:57:00.859604	512	\N	2026PD00123
645	35500297805	1	2026-06-19	RIO DE JANEIRO	SERVIÇO POLICIAL	822.94	058.00074727/202679	2026-10-13 17:57:00.859604	399	\N	2026PD00291
521	04307176103	1	2026-02-10	SAO PAULO	SERVIÇO POLICIAL	248.96	058.00020984/202691	2026-10-13 17:57:00.859604	505	\N	2026PD00068
627	09085540950	1	2026-08-05	CASA BRANCA	SERVIÇO POLICIAL	207.46	058.00094808/202695	2026-10-13 17:57:00.859604	466	\N	2026PD00344
810	05484576709	1	2026-02-26	POCOS DE CALDAS	SERVICO POLICIAL	207.46	058.00010202/202616	2026-10-14 14:52:38.767455	566	\N	2026PD00113
638	36750397816	1	2026-07-16	MOCOCA	SERVICO POLICIAL	69.15	058.00085732/202615	2026-10-13 17:57:00.859604	530	\N	2026PD00315
815	26451064807	1	2026-06-19	RIO DE JANEIRO	SERVICO POLICIAL	822.94	058.00074761/202643	2026-10-14 15:27:31.549516	487	\N	2026PD00287
820	10410326682	1	2026-02-25	PIRACICABA	SERVICO POLICIAL	207.46	058.00003690/202602	2026-10-14 15:42:04.872453	446	\N	2026PD00047
808	19216935847	2	2026-09-30	SAO PAULO	CURSO COP	726.13	058.00116811/2026-77	2026-10-14 10:40:15.851882	565	\N	\N
798	01110375816	2	2023-09-06	SAO PAULO	CURSO SSP	3360.96	058.00115646/202636	2026-10-13 17:57:00.859604	381	\N	2026PD00408
775	01110375816	2	2026-04-01	SAO PAULO	CURSO SSP	871.36	058.00055684/202622	2026-10-13 17:57:00.859604	409	\N	2026PD00161
776	01110375816	2	2026-04-05	SAO PAULO	CURSO SSP	3360.96	058.00055684/202622	2026-10-13 17:57:00.859604	409	\N	2026PD00161
827	04307176103	2	2026-09-24	PIRACICABA	CURSO MBA	103.73	058.00113983/202699	2026-10-15 15:41:17.369817	579	\N	2026PD00414
828	04307176103	2	2026-09-26	PIRACICABA	CURSO MBA	103.73	058.00113983/202699	2026-10-15 15:44:46.548372	579	\N	2026PD00414
829	19203432884	2	2026-09-17	PIRACICABA	CURSO MBA	103.73	058.00111491/202669	2026-10-15 15:45:38.180307	580	\N	2026PD00415
831	19216935847	2	2026-09-26	PIRACICABA	CURSO MBA	103.73	058.00113978/202686	2026-10-15 15:47:48.448063	581	\N	2026PD00416
832	42610681844	2	2026-09-17	PIRACICABA	CURSO MBA	80.68	058.00111029/202661	2026-10-15 15:49:17.328371	582	\N	2026PD00417
833	85920356510	2	2026-09-24	PIRACICABA	CURSO MBA	103.73	058.00114776/202651	2026-10-15 15:53:44.745113	583	\N	2026PD00418
743	00496426850	2	2026-08-27	SAO PAULO	AGOSTO LILAS	248.96	05800104239/202601	2026-10-13 17:57:00.859604	377	\N	2026PD00367
777	01110375816	2	2026-04-12	SAO PAULO	CURSO SSP	3360.96	058.00055684/202622	2026-10-13 17:57:00.859604	409	\N	2026PD00161
778	01110375816	2	2026-04-21	SAO PAULO	CURSO SSP	2116.16	058.00055684/202622	2026-10-13 17:57:00.859604	409	\N	2026PD00161
779	01110375816	2	2026-04-26	SAO PAULO	CURSO SSP	3360.96	058.00055684/202622	2026-10-13 17:57:00.859604	409	\N	2026PD00161
780	01110375816	2	2026-05-03	SAO PAULO	CURSO SSP	3360.96	05800067369/202648	2026-10-13 17:57:00.859604	423	\N	2026PD00218
781	01110375816	2	2026-05-10	SAO PAULO	CURSO SSP	3360.96	05800067369/202648	2026-10-13 17:57:00.859604	423	\N	2026PD00218
782	01110375816	2	2026-05-17	SAO PAULO	CURSO SSP	3360.96	05800067369/202648	2026-10-13 17:57:00.859604	423	\N	2026PD00218
783	01110375816	2	2026-05-24	SAO PAULO	CURSO SSP	3360.96	05800067369/202648	2026-10-13 17:57:00.859604	423	\N	2026PD00218
784	01110375816	2	2026-05-31	SAO PAULO	CURSO SSP	3112.00	058.00079231/202691	2026-10-13 17:57:00.859604	472	\N	2026PD00260
785	01110375816	2	2026-06-07	SAO PAULO	CURSO SSP	3112.00	058.00079231/202691	2026-10-13 17:57:00.859604	472	\N	2026PD00260
786	01110375816	2	2026-06-14	SAO PAULO	CURSO SSP	3112.00	058.00079231/202691	2026-10-13 17:57:00.859604	472	\N	2026PD00260
787	01110375816	2	2026-06-21	SAO PAULO	CURSO SSP	3112.00	058.00079231/202691	2026-10-13 17:57:00.859604	472	\N	2026PD00260
788	01110375816	2	2026-06-28	SAO PAULO	CURSO SSP	3112.00	058.00088428/202611	2026-10-13 17:57:00.859604	516	\N	2026PD00304
789	01110375816	2	2026-07-05	SAO PAULO	CURSO SSP	3112.00	058.00088428/202611	2026-10-13 17:57:00.859604	516	\N	2026PD00304
790	01110375816	2	2026-07-12	SAO PAULO	CURSO SSP	3112.00	058.00088428/202611	2026-10-13 17:57:00.859604	516	\N	2026PD00304
791	01110375816	2	2026-07-19	SAO PAULO	CURSO SSP	3112.00	058.00088428/202611	2026-10-13 17:57:00.859604	516	\N	2026PD00304
792	01110375816	2	2026-07-26	SAO PAULO	CURSO SSP	3112.00	058.00088428/202611	2026-10-13 17:57:00.859604	516	\N	2026PD00304
793	01110375816	2	2026-08-02	SAO PAULO	CURSO SSP	3360.96	058.00102235/202681	2026-10-13 17:57:00.859604	371	\N	2026PD00371
794	01110375816	2	2026-08-09	SAO PAULO	CURSO SSP	3360.96	058.00102235/202681	2026-10-13 17:57:00.859604	371	\N	2026PD00371
795	01110375816	2	2026-08-16	SAO PAULO	CURSO SSP	3360.96	058.00102235/202681	2026-10-13 17:57:00.859604	371	\N	2026PD00371
796	01110375816	2	2026-08-23	SAO PAULO	CURSO SSP	3360.96	058.00102235/202681	2026-10-13 17:57:00.859604	371	\N	2026PD00371
797	01110375816	2	2026-08-30	SAO PAULO	CURSO SSP	3360.96	058.00115646/202636	2026-10-13 17:57:00.859604	381	\N	2026PD00408
799	01110375816	2	2026-09-13	SAO PAULO	CURSO SSP	3360.96	058.00115646/202636	2026-10-13 17:57:00.859604	381	\N	2026PD00408
800	01110375816	2	2026-09-20	SAO PAULO	CURSO SSP	3360.96	058.00115646/202636	2026-10-13 17:57:00.859604	381	\N	2026PD00408
801	01110375816	2	2026-09-27	SAO PAULO	CURSO SSP	3360.96	058.00115646/202636	2026-10-13 17:57:00.859604	381	\N	2026PD00408
522	04307176103	1	2026-04-16	LIMEIRA	SERVIÇO POLICIAL	103.73	058.00049520/202666	2026-10-13 17:57:00.859604	492	\N	2026PD00169
565	04704982858	1	2026-06-09	SAO PAULO	SERVIÇO POLICIAL	248.96	058.00070439/202645	2026-10-13 17:57:00.859604	384	\N	2026/PD00283
560	05484576709	1	2026-02-25	SAO PAULO	SERVIÇO POLICIAL	248.96	058.00029861/202615	2026-10-13 17:57:00.859604	469	\N	2026PD00129
717	06762410855	2	2026-08-02	SAO PAULO	ENCONTRO UGES	622.40	058.00091820/202648	2026-10-13 17:57:00.859604	538	\N	2026PD00340
558	06762410855	1	2026-08-06	ITU	SERVIÇO POLICIAL	103.73	058.00094014/202621	2026-10-13 17:57:00.859604	547	\N	2026PD00341
542	07666429681	1	2026-04-28	PIRACICABA	SERVIÇO POLICIAL	69.15	058.00052997/202629	2026-10-13 17:57:00.859604	372	\N	2026PD00170
566	08922377674	1	2026-08-10	SAO PAULO	SERVIÇO POLICIAL	248.96	058.00095143/202637	2026-10-13 17:57:00.859604	560	\N	2026PD00332
650	10410326682	1	2026-02-07	PIRACICABA	PLANTAO POLICIAL LIMEIRA	207.46	058.00018719/202642	2026-10-13 17:57:00.859604	408	\N	2026PD00070
656	10410326682	1	2026-03-03	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	138.31	058.00041351/202616	2026-10-13 17:57:00.859604	386	\N	2026PD00130
657	10410326682	1	2026-03-05	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	138.31	058.00041351/202616	2026-10-13 17:57:00.859604	386	\N	2026PD00130
658	10410326682	1	2026-03-09	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	138.31	058.00041351/202616	2026-10-13 17:57:00.859604	386	\N	2026PD00130
659	10410326682	1	2026-03-11	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	138.31	058.00041351/202616	2026-10-13 17:57:00.859604	386	\N	2026PD00130
660	10410326682	1	2026-03-14	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	69.15	058.00041351/202616	2026-10-13 17:57:00.859604	386	\N	2026PD00130
661	10410326682	1	2026-03-15	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	138.31	058.00041351/202616	2026-10-13 17:57:00.859604	386	\N	2026PD00130
662	10410326682	1	2026-03-19	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	138.31	058.00041351/202616	2026-10-13 17:57:00.859604	386	\N	2026PD00130
663	10410326682	1	2026-03-21	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	138.31	058.00041351/202616	2026-10-13 17:57:00.859604	386	\N	2026PD00130
664	10410326682	1	2026-03-23	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	138.31	058.00041351/202616	2026-10-13 17:57:00.859604	386	\N	2026PD00130
665	10410326682	1	2026-03-27	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	138.31	058.00041351/202616	2026-10-13 17:57:00.859604	386	\N	2026PD00130
666	10410326682	1	2026-03-31	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	138.31	058.00041351/202616	2026-10-13 17:57:00.859604	386	\N	2026PD00130
667	10410326682	1	2026-04-06	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	138.31	058.00054445/202655	2026-10-13 17:57:00.859604	422	\N	2026PD00172
668	10410326682	1	2026-04-09	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	138.31	058.00054445/202655	2026-10-13 17:57:00.859604	422	\N	2026PD00172
738	05484576709	2	2026-03-16	SAO PAULO	CURSO OPERACIONAL PMSP	248.96	058.00040676/202681	2026-10-13 17:57:00.859604	448	\N	2026PD00129
739	05484576709	2	2026-03-17	SAO PAULO	CURSO OPERACIONAL PMSP	248.96	058.00040676/202681	2026-10-13 17:57:00.859604	448	\N	2026PD00129
740	05484576709	2	2026-03-18	SAO PAULO	CURSO OPERACIONAL PMSP	248.96	058.00040676/202681	2026-10-13 17:57:00.859604	448	\N	2026PD00129
741	05484576709	2	2026-03-19	SAO PAULO	CURSO OPERACIONAL PMSP	248.96	058.00040676/202681	2026-10-13 17:57:00.859604	448	\N	2026PD00129
742	05484576709	2	2026-03-20	SAO PAULO	CURSO OPERACIONAL PMSP	248.96	058.00040676/202681	2026-10-13 17:57:00.859604	448	\N	2026PD00129
745	05484576709	2	2026-03-23	SAO PAULO	CURSO OPERACIONAL PMSP	248.96	058.00040676/202681	2026-10-13 17:57:00.859604	448	\N	2026PD00129
750	05484576709	2	2026-03-24	SAO PAULO	CURSO OPERACIONAL PMSP	248.96	058.00040676/202681	2026-10-13 17:57:00.859604	448	\N	2026PD00129
754	05484576709	2	2026-03-25	SAO PAULO	CURSO OPERACIONAL PMSP	248.96	058.00040676/202681	2026-10-13 17:57:00.859604	448	\N	2026PD00129
755	05484576709	2	2026-03-26	SAO PAULO	CURSO OPERACIONAL PMSP	248.96	058.00040676/202681	2026-10-13 17:57:00.859604	448	\N	2026PD00129
756	05484576709	2	2026-03-27	SAO PAULO	CURSO OPERACIONAL PMSP	248.96	058.00040676/202681	2026-10-13 17:57:00.859604	448	\N	2026PD00129
669	10410326682	1	2026-04-11	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	138.31	058.00054445/202655	2026-10-13 17:57:00.859604	422	\N	2026PD00172
670	10410326682	1	2026-04-13	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	138.31	058.00054445/202655	2026-10-13 17:57:00.859604	422	\N	2026PD00172
671	10410326682	1	2026-04-15	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	138.31	058.00054445/202655	2026-10-13 17:57:00.859604	422	\N	2026PD00172
672	10410326682	1	2026-04-17	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	138.31	058.00054445/202655	2026-10-13 17:57:00.859604	422	\N	2026PD00172
673	10410326682	1	2026-04-19	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	138.31	058.00054445/202655	2026-10-13 17:57:00.859604	422	\N	2026PD00172
674	10410326682	1	2026-04-21	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	138.31	058.00054445/202655	2026-10-13 17:57:00.859604	422	\N	2026PD00172
675	10410326682	1	2026-04-23	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	138.31	058.00054445/202655	2026-10-13 17:57:00.859604	422	\N	2026PD00172
676	10410326682	1	2026-04-27	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	138.31	058.00054445/202655	2026-10-13 17:57:00.859604	422	\N	2026PD00172
677	10410326682	1	2026-04-29	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	138.31	058.00054445/202655	2026-10-13 17:57:00.859604	422	\N	2026PD00172
678	10410326682	1	2026-05-01	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	138.31	058.00066721/202628	2026-10-13 17:57:00.859604	391	\N	2026PD00237
679	10410326682	1	2026-05-03	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	69.15	058.00066721/202628	2026-10-13 17:57:00.859604	391	\N	2026PD00237
680	10410326682	1	2026-05-05	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	138.31	058.00066721/202628	2026-10-13 17:57:00.859604	391	\N	2026PD00237
681	10410326682	1	2026-05-11	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	138.31	058.00066721/202628	2026-10-13 17:57:00.859604	391	\N	2026PD00237
682	10410326682	1	2026-05-14	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	138.31	058.00066721/202628	2026-10-13 17:57:00.859604	391	\N	2026PD00237
683	10410326682	1	2026-05-16	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	138.31	058.00066721/202628	2026-10-13 17:57:00.859604	391	\N	2026PD00237
684	10410326682	1	2026-05-17	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	138.31	058.00066721/202628	2026-10-13 17:57:00.859604	391	\N	2026PD00237
685	10410326682	1	2026-05-20	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	138.31	058.00066721/202628	2026-10-13 17:57:00.859604	391	\N	2026PD00237
686	10410326682	1	2026-05-23	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	69.15	058.00066721/202628	2026-10-13 17:57:00.859604	391	\N	2026PD00237
687	10410326682	1	2026-05-24	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	69.15	058.00066721/202628	2026-10-13 17:57:00.859604	391	\N	2026PD00237
688	10410326682	1	2026-05-26	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	138.31	058.00066721/202628	2026-10-13 17:57:00.859604	391	\N	2026PD00237
446	10531583600	1	2026-01-27	PIRACICABA	PLANTAO POLICIAL LIMEIRA	207.46	058.00012724/202641	2026-10-13 17:57:00.859604	389	\N	2026PD00048
567	10995999899	1	2026-03-01	LIMEIRA	ACUMULO DE FUNÇÃO	107.57	058.00040508/202696	2026-10-13 17:57:00.859604	434	\N	2026PD00115
568	10995999899	1	2026-03-04	LIMEIRA	ACUMULO DE FUNÇÃO	107.57	058.00040508/202696	2026-10-13 17:57:00.859604	434	\N	2026PD00115
569	10995999899	1	2026-03-06	LIMEIRA	ACUMULO DE FUNÇÃO	107.57	058.00040508/202696	2026-10-13 17:57:00.859604	434	\N	2026PD00115
570	10995999899	1	2026-03-07	LIMEIRA	ACUMULO DE FUNÇÃO	107.57	058.00040508/202696	2026-10-13 17:57:00.859604	434	\N	2026PD00115
571	10995999899	1	2026-03-10	LIMEIRA	ACUMULO DE FUNÇÃO	107.57	058.00040508/202696	2026-10-13 17:57:00.859604	434	\N	2026PD00115
572	10995999899	1	2026-03-13	LIMEIRA	ACUMULO DE FUNÇÃO	107.57	058.00040508/202696	2026-10-13 17:57:00.859604	434	\N	2026PD00115
573	10995999899	1	2026-03-17	LIMEIRA	ACUMULO DE FUNÇÃO	107.57	058.00040508/202696	2026-10-13 17:57:00.859604	434	\N	2026PD00115
574	10995999899	1	2026-03-21	LIMEIRA	ACUMULO DE FUNÇÃO	107.57	058.00040508/202696	2026-10-13 17:57:00.859604	434	\N	2026PD00115
575	10995999899	1	2026-03-25	LIMEIRA	ACUMULO DE FUNÇÃO	107.57	058.00040508/202696	2026-10-13 17:57:00.859604	434	\N	2026PD00115
723	10995999899	2	2026-03-27	PIRACICABA	CURSO TIRO	80.68	058.00040479/202662	2026-10-13 17:57:00.859604	460	\N	2026PD00131
576	10995999899	1	2026-04-02	LIMEIRA	ACUMULO DE FUNÇÃO	107.57	058.00047272/202619	2026-10-13 17:57:00.859604	528	\N	2026PD00173
577	10995999899	1	2026-04-04	LIMEIRA	ACUMULO DE FUNÇÃO	107.57	058.00047272/202619	2026-10-13 17:57:00.859604	528	\N	2026PD00173
578	10995999899	1	2026-04-05	LIMEIRA	ACUMULO DE FUNÇÃO	107.57	058.00047272/202619	2026-10-13 17:57:00.859604	528	\N	2026PD00173
579	10995999899	1	2026-04-08	LIMEIRA	ACUMULO DE FUNÇÃO	107.57	058.00047272/202619	2026-10-13 17:57:00.859604	528	\N	2026PD00173
580	10995999899	1	2026-04-10	LIMEIRA	ACUMULO DE FUNÇÃO	107.57	058.00047272/202619	2026-10-13 17:57:00.859604	528	\N	2026PD00173
581	10995999899	1	2026-05-01	LIMEIRA	ACUMULO DE FUNÇÃO	107.57	058.00057022/202697	2026-10-13 17:57:00.859604	523	\N	2026PD00238
582	10995999899	1	2026-05-05	LIMEIRA	ACUMULO DE FUNÇÃO	107.57	058.00057022/202697	2026-10-13 17:57:00.859604	523	\N	2026PD00238
583	10995999899	1	2026-05-07	LIMEIRA	ACUMULO DE FUNÇÃO	107.57	058.00057022/202697	2026-10-13 17:57:00.859604	523	\N	2026PD00238
584	10995999899	1	2026-05-09	LIMEIRA	ACUMULO DE FUNÇÃO	107.57	058.00057022/202697	2026-10-13 17:57:00.859604	523	\N	2026PD00238
585	10995999899	1	2026-06-01	LIMEIRA	ACUMULO DE FUNÇÃO	107.57	058.00077592/202601	2026-10-13 17:57:00.859604	542	\N	2026PD00282
586	10995999899	1	2026-06-02	LIMEIRA	ACUMULO DE FUNÇÃO	107.57	058.00077592/202601	2026-10-13 17:57:00.859604	542	\N	2026PD00282
587	10995999899	1	2026-06-03	LIMEIRA	ACUMULO DE FUNÇÃO	107.57	058.00077592/202601	2026-10-13 17:57:00.859604	542	\N	2026PD00282
588	10995999899	1	2026-06-14	LIMEIRA	ACUMULO DE FUNÇÃO	107.57	058.00077592/202601	2026-10-13 17:57:00.859604	542	\N	2026PD00282
589	10995999899	1	2026-06-17	LIMEIRA	ACUMULO DE FUNÇÃO	107.57	058.00077592/202601	2026-10-13 17:57:00.859604	542	\N	2026PD00282
590	10995999899	1	2026-06-18	LIMEIRA	ACUMULO DE FUNÇÃO	107.57	058.00077592/202601	2026-10-13 17:57:00.859604	542	\N	2026PD00282
591	10995999899	1	2026-06-21	LIMEIRA	ACUMULO DE FUNÇÃO	107.57	058.00077592/202601	2026-10-13 17:57:00.859604	542	\N	2026PD00282
592	10995999899	1	2026-06-22	LIMEIRA	ACUMULO DE FUNÇÃO	107.57	058.00077592/202601	2026-10-13 17:57:00.859604	542	\N	2026PD00282
593	10995999899	1	2026-06-25	LIMEIRA	ACUMULO DE FUNÇÃO	107.57	058.00077592/202601	2026-10-13 17:57:00.859604	542	\N	2026PD00282
594	10995999899	1	2026-06-26	LIMEIRA	ACUMULO DE FUNÇÃO	107.57	058.00077592/202601	2026-10-13 17:57:00.859604	542	\N	2026PD00282
595	10995999899	1	2026-07-02	LIMEIRA	ACUMULO DE FUNÇÃO	107.57	058.00091579/202657	2026-10-13 17:57:00.859604	440	\N	2026PD00306
596	10995999899	1	2026-07-05	LIMEIRA	ACUMULO DE FUNÇÃO	107.57	058.00091579/202658	2026-10-13 17:57:00.859604	415	\N	2026PD00306
597	10995999899	1	2026-07-08	LIMEIRA	ACUMULO DE FUNÇÃO	107.57	058.00091579/202659	2026-10-13 17:57:00.859604	405	\N	2026PD00306
598	10995999899	1	2026-07-11	LIMEIRA	ACUMULO DE FUNÇÃO	107.57	058.00091579/202660	2026-10-13 17:57:00.859604	533	\N	2026PD00306
599	10995999899	1	2026-07-14	LIMEIRA	ACUMULO DE FUNÇÃO	107.57	058.00091579/202661	2026-10-13 17:57:00.859604	458	\N	2026PD00306
600	10995999899	1	2026-07-17	LIMEIRA	ACUMULO DE FUNÇÃO	107.57	058.00091579/202662	2026-10-13 17:57:00.859604	501	\N	2026PD00306
601	10995999899	1	2026-07-20	LIMEIRA	ACUMULO DE FUNÇÃO	107.57	058.00091579/202663	2026-10-13 17:57:00.859604	404	\N	2026PD00306
602	10995999899	1	2026-07-21	LIMEIRA	ACUMULO DE FUNÇÃO	107.57	058.00091579/202664	2026-10-13 17:57:00.859604	403	\N	2026PD00306
603	10995999899	1	2026-07-24	LIMEIRA	ACUMULO DE FUNÇÃO	107.57	058.00091579/202665	2026-10-13 17:57:00.859604	484	\N	2026PD00306
604	10995999899	1	2026-07-25	LIMEIRA	ACUMULO DE FUNÇÃO	107.57	058.00091579/202666	2026-10-13 17:57:00.859604	539	\N	2026PD00306
605	10995999899	1	2026-07-28	LIMEIRA	ACUMULO DE FUNÇÃO	107.57	058.00091579/202667	2026-10-13 17:57:00.859604	479	\N	2026PD00306
606	10995999899	1	2026-07-29	LIMEIRA	ACUMULO DE FUNÇÃO	107.57	058.00091579/202668	2026-10-13 17:57:00.859604	532	\N	2026PD00306
607	10995999899	1	2026-08-05	LIMEIRA	ACUMULO DE FUNÇÃO	107.57	058.00104889/202649	2026-10-13 17:57:00.859604	461	\N	2026PD00402
608	10995999899	1	2026-08-09	LIMEIRA	ACUMULO DE FUNÇÃO	107.57	058.00104889/202649	2026-10-13 17:57:00.859604	461	\N	2026PD00402
609	10995999899	1	2026-08-11	LIMEIRA	ACUMULO DE FUNÇÃO	107.57	058.00104889/202649	2026-10-13 17:57:00.859604	461	\N	2026PD00402
610	10995999899	1	2026-08-14	LIMEIRA	ACUMULO DE FUNÇÃO	107.57	058.00104889/202649	2026-10-13 17:57:00.859604	461	\N	2026PD00402
611	10995999899	1	2026-08-20	LIMEIRA	ACUMULO DE FUNÇÃO	107.57	058.00104889/202649	2026-10-13 17:57:00.859604	461	\N	2026PD00402
612	10995999899	1	2026-08-21	LIMEIRA	ACUMULO DE FUNÇÃO	107.57	058.00104889/202649	2026-10-13 17:57:00.859604	461	\N	2026PD00402
613	10995999899	1	2026-08-22	LIMEIRA	ACUMULO DE FUNÇÃO	107.57	058.00104889/202649	2026-10-13 17:57:00.859604	461	\N	2026PD00402
614	10995999899	1	2026-08-23	LIMEIRA	ACUMULO DE FUNÇÃO	107.57	058.00104889/202649	2026-10-13 17:57:00.859604	461	\N	2026PD00402
615	10995999899	1	2026-08-26	LIMEIRA	ACUMULO DE FUNÇÃO	107.57	058.00104889/202649	2026-10-13 17:57:00.859604	461	\N	2026PD00402
616	10995999899	1	2026-08-29	LIMEIRA	ACUMULO DE FUNÇÃO	107.57	058.00104889/202649	2026-10-13 17:57:00.859604	461	\N	2026PD00402
523	11374959600	1	2026-08-05	BARUERI	SERVIÇO POLICIAL	103.73	058.00093477/202676	2026-10-13 17:57:00.859604	393	\N	2026PD00334
524	11374959600	1	2026-08-17	PIRACICABA	SERVIÇO POLICIAL	103.73	058.00098581/202657	2026-10-13 17:57:00.859604	473	\N	2026PD00402
716	12328788807	2	2026-07-16	SAO PAULO	TREINAMENTO	193.63	058.00085150/202621	2026-10-13 17:57:00.859604	459	\N	2026PD00136
725	12375581660	2	2026-03-27	RIO CLARO	CURSO TIRO	69.15	058.00044639/202642	2026-10-13 17:57:00.859604	430	\N	2026PD00184
441	12794506730	1	2026-06-09	SAO PAULO	SERVIÇO POLICIAL	248.96	058.00070656/202635	2026-10-13 17:57:00.859604	457	\N	2026PD00296
694	13934950876	1	2026-05-02	LIMEIRA	PLANTAO POLICIAL LIMEIRA	161.36	058.00067125/202665	2026-10-13 17:57:00.859604	485	\N	2026PD00239
695	13934950876	1	2026-05-05	LIMEIRA	PLANTAO POLICIAL LIMEIRA	161.36	058.00067125/202665	2026-10-13 17:57:00.859604	485	\N	2026PD00239
696	13934950876	1	2026-05-08	LIMEIRA	PLANTAO POLICIAL LIMEIRA	161.36	058.00067125/202665	2026-10-13 17:57:00.859604	485	\N	2026PD00239
697	13934950876	1	2026-05-11	LIMEIRA	PLANTAO POLICIAL LIMEIRA	161.36	058.00067125/202665	2026-10-13 17:57:00.859604	485	\N	2026PD00239
698	13934950876	1	2026-05-14	LIMEIRA	PLANTAO POLICIAL LIMEIRA	161.36	058.00067125/202665	2026-10-13 17:57:00.859604	485	\N	2026PD00239
699	13934950876	1	2026-05-17	LIMEIRA	PLANTAO POLICIAL LIMEIRA	161.36	058.00067125/202665	2026-10-13 17:57:00.859604	485	\N	2026PD00239
400	13934950876	1	2026-05-21	LIMEIRA	PLANTAO POLICIAL LIMEIRA	161.36	058.00067125/202665	2026-10-13 17:57:00.859604	485	\N	2026PD00239
401	13934950876	1	2026-05-24	LIMEIRA	PLANTAO POLICIAL LIMEIRA	161.36	058.00067125/202665	2026-10-13 17:57:00.859604	485	\N	2026PD00239
402	13934950876	1	2026-05-28	LIMEIRA	PLANTAO POLICIAL LIMEIRA	161.36	058.00067125/202665	2026-10-13 17:57:00.859604	485	\N	2026PD00239
403	13934950876	1	2026-05-31	LIMEIRA	PLANTAO POLICIAL LIMEIRA	161.36	058.00067125/202665	2026-10-13 17:57:00.859604	485	\N	2026PD00247
404	13934950876	1	2026-06-04	LIMEIRA	PLANTAO POLICIAL LIMEIRA	161.36	058.00083398/202657	2026-10-13 17:57:00.859604	495	\N	2026PD00307
405	13934950876	1	2026-06-09	LIMEIRA	PLANTAO POLICIAL LIMEIRA	161.36	058.00083398/202658	2026-10-13 17:57:00.859604	488	\N	2026PD00307
406	13934950876	1	2026-06-14	LIMEIRA	PLANTAO POLICIAL LIMEIRA	161.36	058.00083398/202659	2026-10-13 17:57:00.859604	370	\N	2026PD00307
395	13934950876	1	2026-06-19	LIMEIRA	PLANTAO POLICIAL LIMEIRA	161.36	058.00083398/202660	2026-10-13 17:57:00.859604	480	\N	2026PD00307
407	13934950876	1	2026-06-21	LIMEIRA	PLANTAO POLICIAL LIMEIRA	161.36	058.00083398/202661	2026-10-13 17:57:00.859604	400	\N	2026PD00307
408	13934950876	1	2026-06-24	LIMEIRA	PLANTAO POLICIAL LIMEIRA	161.36	058.00083398/202662	2026-10-13 17:57:00.859604	470	\N	2026PD00307
409	13934950876	1	2026-06-27	LIMEIRA	PLANTAO POLICIAL LIMEIRA	161.36	058.00083398/202663	2026-10-13 17:57:00.859604	438	\N	2026PD00307
410	13934950876	1	2026-06-29	LIMEIRA	PLANTAO POLICIAL LIMEIRA	161.36	058.00083398/202664	2026-10-13 17:57:00.859604	435	\N	2026PD00307
411	13934950876	1	2026-07-02	LIMEIRA	ACUMULO DE FUNÇÃO	161.36	058.00092056/202628	2026-10-13 17:57:00.859604	494	\N	2026PD00335
412	13934950876	1	2026-07-04	LIMEIRA	ACUMULO DE FUNÇÃO	161.36	058.00092056/202628	2026-10-13 17:57:00.859604	494	\N	2026PD00335
413	13934950876	1	2026-07-06	LIMEIRA	ACUMULO DE FUNÇÃO	161.36	058.00092056/202628	2026-10-13 17:57:00.859604	494	\N	2026PD00335
414	13934950876	1	2026-07-09	LIMEIRA	ACUMULO DE FUNÇÃO	161.36	058.00092056/202628	2026-10-13 17:57:00.859604	494	\N	2026PD00335
415	13934950876	1	2026-07-11	LIMEIRA	ACUMULO DE FUNÇÃO	161.36	058.00092056/202628	2026-10-13 17:57:00.859604	494	\N	2026PD00335
416	13934950876	1	2026-07-12	LIMEIRA	ACUMULO DE FUNÇÃO	161.36	058.00092056/202628	2026-10-13 17:57:00.859604	494	\N	2026PD00335
417	13934950876	1	2026-07-15	LIMEIRA	ACUMULO DE FUNÇÃO	161.36	058.00092056/202628	2026-10-13 17:57:00.859604	494	\N	2026PD00335
418	13934950876	1	2026-07-18	LIMEIRA	ACUMULO DE FUNÇÃO	161.36	058.00092056/202628	2026-10-13 17:57:00.859604	494	\N	2026PD00335
419	13934950876	1	2026-07-20	LIMEIRA	ACUMULO DE FUNÇÃO	161.36	058.00092056/202628	2026-10-13 17:57:00.859604	494	\N	2026PD00335
420	13934950876	1	2026-07-23	LIMEIRA	ACUMULO DE FUNÇÃO	161.36	058.00092056/202628	2026-10-13 17:57:00.859604	494	\N	2026PD00335
421	13934950876	1	2026-07-25	LIMEIRA	ACUMULO DE FUNÇÃO	161.36	058.00092056/202628	2026-10-13 17:57:00.859604	494	\N	2026PD00335
422	13934950876	1	2026-07-27	LIMEIRA	ACUMULO DE FUNÇÃO	161.36	058.00092056/202628	2026-10-13 17:57:00.859604	494	\N	2026PD00335
423	13934950876	1	2026-07-30	LIMEIRA	ACUMULO DE FUNÇÃO	161.36	058.00092056/202628	2026-10-13 17:57:00.859604	494	\N	2026PD00335
424	13934950876	1	2026-08-02	LIMEIRA	ACUMULO DE FUNÇÃO	161.36	058.00103897/202678	2026-10-13 17:57:00.859604	454	\N	2026PD00402
425	13934950876	1	2026-08-06	LIMEIRA	ACUMULO DE FUNÇÃO	161.36	058.00103897/202678	2026-10-13 17:57:00.859604	454	\N	2026PD00402
426	13934950876	1	2026-08-09	LIMEIRA	ACUMULO DE FUNÇÃO	161.36	058.00103897/202678	2026-10-13 17:57:00.859604	454	\N	2026PD00402
427	13934950876	1	2026-08-12	LIMEIRA	ACUMULO DE FUNÇÃO	161.36	058.00103897/202678	2026-10-13 17:57:00.859604	454	\N	2026PD00402
428	13934950876	1	2026-08-15	LIMEIRA	ACUMULO DE FUNÇÃO	161.36	058.00103897/202678	2026-10-13 17:57:00.859604	454	\N	2026PD00402
429	13934950876	1	2026-08-18	LIMEIRA	ACUMULO DE FUNÇÃO	161.36	058.00103897/202678	2026-10-13 17:57:00.859604	454	\N	2026PD00402
430	13934950876	1	2026-08-22	LIMEIRA	ACUMULO DE FUNÇÃO	161.36	058.00103897/202678	2026-10-13 17:57:00.859604	454	\N	2026PD00402
431	13934950876	1	2026-08-24	LIMEIRA	ACUMULO DE FUNÇÃO	161.36	058.00103897/202678	2026-10-13 17:57:00.859604	454	\N	2026PD00402
432	13934950876	1	2026-08-28	LIMEIRA	ACUMULO DE FUNÇÃO	161.36	058.00103897/202678	2026-10-13 17:57:00.859604	454	\N	2026PD00402
433	13934950876	1	2026-08-30	LIMEIRA	ACUMULO DE FUNÇÃO	161.36	058.00103897/202678	2026-10-13 17:57:00.859604	454	\N	2026PD00402
625	14694180703	1	2026-06-09	SAO PAULO	SERVIÇO POLICIAL	248.96	058.00070662/202692	2026-10-13 17:57:00.859604	519	\N	2026PD00284
626	14694180703	1	2026-08-05	BARUERI	SERVIÇO POLICIAL	103.73	058.00093806/202689	2026-10-13 17:57:00.859604	436	\N	2026PD00402
744	15721307846	2	2026-07-16	SAO PAULO	TREINAMENTO	248.96	058.00085156/202606	2026-10-13 17:57:00.859604	522	\N	2026PD00317
520	16791203870	1	2026-08-05	BARUERI	SERVIÇO POLICIAL	103.73	058.00093837/202630	2026-10-13 17:57:00.859604	378	\N	2026PD00336
628	18208623806	1	2026-01-11	LIMEIRA	PLANTAO POLICIAL LIMEIRA	207.46	058.00004380/202605	2026-10-13 17:57:00.859604	429	\N	2026PD00049
708	18208623806	2	2026-01-29	SAO PAULO	CURSO ACADEPOL APH	871.36	058.00014312/202646	2026-10-13 17:57:00.859604	462	\N	2026PD00059
629	18208623806	1	2026-03-06	JAGUARIUNA	SERVIÇO POLICIAL	69.15	058.00031183/202651	2026-10-13 17:57:00.859604	555	\N	2026PD00116
713	18208623806	2	2026-04-30	SALTINHO	CURSO ENTRADAS TATICAS	138.31	058.00053438/202639	2026-10-13 17:57:00.859604	546	\N	2026PD00162
630	18208623806	1	2026-07-13	LIMEIRA	PLANTAO POLICIAL LIMEIRA	207.46	058.00083424/202647	2026-10-13 17:57:00.859604	468	\N	2026PD00308
631	18208623806	1	2026-08-29	LIMEIRA	PLANTAO POLICIAL LIMEIRA	103.73	058.00104642/202622	2026-10-13 17:57:00.859604	419	\N	2026PD00402
434	19163513870	1	2026-01-01	PIRACICABA	PLANTAO POLICIAL LIMEIRA	207.46	058.00001044/202601	2026-10-13 17:57:00.859604	418	\N	2026PD00050
689	19174943863	1	2026-02-20	SAO PAULO	SERVIÇO POLICIAL	248.96	058.00024388/202680	2026-10-13 17:57:00.859604	427	\N	2026PD00071
447	19203432884	1	2026-04-15	SAO PAULO	SERVIÇO POLICIAL	248.96	058.00048533/202618	2026-10-13 17:57:00.859604	506	\N	2026PD00174
448	19203432884	1	2026-06-09	SAO PAULO	SERVIÇO POLICIAL	248.96	058.00070445/202601	2026-10-13 17:57:00.859604	453	\N	2026PD00285
639	19216935847	1	2026-03-06	JAGUARIUNA	SERVIÇO POLICIAL	69.15	058.00031520/202618	2026-10-13 17:57:00.859604	390	\N	2026PD00117
640	19216935847	1	2026-03-11	RIO CLARO	SERVIÇO POLICIAL	69.15	058.00033318/202612	2026-10-13 17:57:00.859604	421	\N	\N
517	21360741801	1	2026-02-12	CAPIVARI	SERVIÇO POLICIAL	138.31	058.00021480/202698	2026-10-13 17:57:00.859604	417	\N	2026PD00072
518	21360741801	1	2026-03-13	PIRACICABA	SERVIÇO POLICIAL	53.78	058.00035389/202650	2026-10-13 17:57:00.859604	499	\N	2026PD00118
519	21360741801	1	2026-03-20	SAO PAULO	SERVIÇO POLICIAL	96.81	058.00037136/202611	2026-10-13 17:57:00.859604	536	\N	2026PD00118
534	21675933847	1	2026-02-26	POÇOS DE CALDAS	SERVIÇO POLICIAL	207.46	058.00028495/202687	2026-10-13 17:57:00.859604	545	\N	2026PD00119
559	22444646878	1	2026-02-19	PIRACICABA	PLANTAO POLICIAL LIMEIRA	207.46	058.00024300/202620	2026-10-13 17:57:00.859604	449	\N	2026PD00073
533	24886549810	1	2026-04-15	SAO PAULO	SERVIÇO POLICIAL	248.96	058.00048535/202615	2026-10-13 17:57:00.859604	525	\N	2026PD00175
435	24999284847	1	2026-01-19	PIRACICABA	PLANTAO POLICIAL LIMEIRA	138.31	058.00007397/202614	2026-10-13 17:57:00.859604	478	\N	2026PD00051
436	24999284847	1	2026-05-14	LIMEIRA	PLANTAO POLICIAL LIMEIRA	138.31	058.00059627/202612	2026-10-13 17:57:00.859604	398	\N	2026PD00240
437	24999284847	1	2026-06-15	LIMEIRA	PLANTAO POLICIAL LIMEIRA	138.31	058.00071344/202649	2026-10-13 17:57:00.859604	552	\N	2026PD00286
438	24999284847	1	2026-07-18	LIMEIRA	PLANTAO POLICIAL LIMEIRA	138.31	058.00085564/202650	2026-10-13 17:57:00.859604	535	\N	2026PD00309
439	24999284847	1	2026-07-24	LIMEIRA	PLANTAO POLICIAL LIMEIRA	138.31	058.00087987/202612	2026-10-13 17:57:00.859604	395	\N	2026PD00309
440	24999284847	1	2026-08-08	LIMEIRA	PLANTAO POLICIAL LIMEIRA	138.31	058.00094899/202669	2026-10-13 17:57:00.859604	517	\N	2026PD00342
511	27057183895	1	2026-01-10	LIMEIRA	PLANTAO POLICIAL LIMEIRA	138.31	058.00004579/202625	2026-10-13 17:57:00.859604	549	\N	2026PD00052
512	27057183895	1	2026-02-21	LIMEIRA	PLANTAO POLICIAL LIMEIRA	138.31	058.00023653/202611	2026-10-13 17:57:00.859604	475	\N	2026PD00083
513	27057183895	1	2026-05-17	LIMEIRA	PLANTAO POLICIAL LIMEIRA	138.31	058.00059942/202640	2026-10-13 17:57:00.859604	452	\N	2026PD00241
812	19216935847	1	2026-04-16	LIMEIRA	SERVICO POLICIAL	103.73	058.00048851/202689	2026-10-14 15:17:54.234558	557	\N	2026PD00194
641	19216935847	1	2026-04-16	LIMEIRA	SERVIÇO POLICIAL	103.73	058.00048851/202689	2026-10-13 17:57:00.859604	557	\N	2026PD00194
644	26451064807	1	2026-06-16	RIO DE JANEIRO	SERVIÇO POLICIAL	822.94	058.00074761/202643	2026-10-13 17:57:00.859604	487	\N	2026PD00287
514	27057183895	1	2026-06-07	LIMEIRA	PLANTAO POLICIAL LIMEIRA	138.31	058.00068481/202604	2026-10-13 17:57:00.859604	368	\N	2026PD00288
515	27057183895	1	2026-06-21	LIMEIRA	PLANTAO POLICIAL LIMEIRA	138.31	058.00074673/202641	2026-10-13 17:57:00.859604	526	\N	2026PD00288
617	27206162819	1	2026-01-18	LIMEIRA	PLANTAO POLICIAL LIMEIRA	138.31	058.00010411/202659	2026-10-13 17:57:00.859604	486	\N	2026PD00053
618	27206162819	1	2026-03-22	LIMEIRA	PLANTAO POLICIAL LIMEIRA	138.31	058.00037432/202611	2026-10-13 17:57:00.859604	425	\N	2026PD00120
619	27206162819	1	2026-04-12	LIMEIRA	PLANTAO POLICIAL LIMEIRA	138.31	058.00047214/202695	2026-10-13 17:57:00.859604	447	\N	2026PD00176
620	27206162819	1	2026-05-04	LIMEIRA	PLANTAO POLICIAL LIMEIRA	138.31	058.00055452/202674	2026-10-13 17:57:00.859604	500	\N	2026PD00242
621	27206162819	1	2026-06-09	GUARULHOS	SERVIÇO POLICIAL	207.46	058.00070478/202642	2026-10-13 17:57:00.859604	380	\N	2026PD00289
622	27206162819	1	2026-06-20	LIMEIRA	PLANTAO POLICIAL LIMEIRA	138.31	058.00074505/202656	2026-10-13 17:57:00.859604	531	\N	2026PD00289
623	27206162819	1	2026-07-09	LIMEIRA	PLANTAO POLICIAL LIMEIRA	138.31	058.00082688/202683	2026-10-13 17:57:00.859604	376	\N	2026PD00310
624	27206162819	1	2026-08-09	LIMEIRA	PLANTAO POLICIAL LIMEIRA	138.31	058.00095060/202648	2026-10-13 17:57:00.859604	388	\N	\N
690	27935713855	1	2026-05-12	SAO PAULO	SERVIÇO POLICIAL	124.48	058.00059047/202625	2026-10-13 17:57:00.859604	483	\N	2026PD00243
691	27935713855	1	2026-05-20	SAO PAULO	SERVIÇO POLICIAL	124.48	058.00062241/202698	2026-10-13 17:57:00.859604	396	\N	2026PD00243
692	27935713855	1	2026-06-09	SAO PAULO	SERVIÇO POLICIAL	248.96	058.00070443/202611	2026-10-13 17:57:00.859604	508	\N	2026PD00243
693	29474854831	1	2026-08-05	BARUERI	SERVIÇO POLICIAL	80.68	058.00094473/202613	2026-10-13 17:57:00.859604	455	\N	\N
536	30310116864	1	2026-02-20	SAO PAULO	SERVIÇO POLICIAL	248.96	058.00023698/202687	2026-10-13 17:57:00.859604	451	\N	2026PD00074
751	30310116864	2	2026-02-25	SAO PAULO	CURSO ACADEPOL ACADEPOL	248.96	058.00027233/202603	2026-10-13 17:57:00.859604	476	\N	2026PD00085
752	30310116864	2	2026-02-26	SAO PAULO	CURSO ACADEPOL ACADEPOL	248.96	058.00027233/202603	2026-10-13 17:57:00.859604	476	\N	2026PD00085
753	30310116864	2	2026-02-27	SAO PAULO	CURSO ACADEPOL ACADEPOL	248.96	058.00027233/202603	2026-10-13 17:57:00.859604	476	\N	2026PD00085
632	30841335818	1	2026-06-09	SAO PAULO	SERVIÇO POLICIAL	248.96	058.00070660/202601	2026-10-13 17:57:00.859604	439	\N	\N
633	30841335818	1	2026-07-09	SAO PAULO	SERVIÇO POLICIAL	248.96	058.00070660/202601	2026-10-13 17:57:00.859604	439	\N	\N
538	31082697800	1	2026-08-17	PIRACICABA	SERVIÇO POLICIAL	103.73	058.00098567/202653	2026-10-13 17:57:00.859604	474	\N	2026PD00402
544	31239665857	1	2026-02-10	SAO PAULO	SERVIÇO POLICIAL	248.96	058.00020995/202671	2026-10-13 17:57:00.859604	510	\N	2026PD00075
545	31239665857	1	2026-03-06	JAGUARIUNA	SERVIÇO POLICIAL	69.15	058.00031514/202652	2026-10-13 17:57:00.859604	504	\N	2026PD00121
546	31239665857	1	2026-03-11	RIO CLARO	SERVIÇO POLICIAL	69.15	058.00034447/202628	2026-10-13 17:57:00.859604	481	\N	2026PD00121
535	31892853817	1	2026-03-06	JAGUARIUNA	SERVIÇO POLICIAL	69.15	058.00031519/202685	2026-10-13 17:57:00.859604	385	\N	2026PD00122
746	31892853817	2	2026-04-17	PIRACICABA	CURSO ACADEPOL TAT  I	103.73	058.00040442/202642	2026-10-13 17:57:00.859604	432	\N	2026PD00163
747	31892853817	2	2026-04-19	CHARQUEADA	CURSO ACADEPOL TAT  I	138.31	058.00040442/202642	2026-10-13 17:57:00.859604	432	\N	2026PD00163
748	31892853817	2	2026-04-23	CHARQUEADA	CURSO ACADEPOL TAT  I	69.15	058.00040442/202642	2026-10-13 17:57:00.859604	432	\N	2026PD00163
749	31892853817	2	2026-04-26	PIRACICABA	CURSO ACADEPOL TAT  I	103.73	058.00052028/202678	2026-10-13 17:57:00.859604	382	\N	2026PD00163
526	32540502822	1	2026-01-07	PIRACICABA	PLANTAO POLICIAL LIMEIRA	207.46	058.00003397/202637	2026-10-13 17:57:00.859604	437	\N	2026PD00054
527	32540502822	1	2026-02-14	LIMEIRA	PLANTAO POLICIAL LIMEIRA	138.31	058.00021611/202637	2026-10-13 17:57:00.859604	402	\N	2026PD00076
735	32540502822	2	2026-03-05	SAO PAULO	CURSO APH	995.84	058.00021611/202637	2026-10-13 17:57:00.859604	402	\N	2026PD00132
528	32540502822	1	2026-04-25	LIMEIRA	SERVIÇO POLICIAL	138.31	058.00052142/202606	2026-10-13 17:57:00.859604	424	\N	2026PD00177
529	32540502822	1	2026-05-12	LIMEIRA	PLANTAO POLICIAL LIMEIRA	138.31	058.00059213/202693	2026-10-13 17:57:00.859604	521	\N	2026PD00244
530	32540502822	1	2026-06-08	LIMEIRA	PLANTAO POLICIAL LIMEIRA	138.31	058.00069566/202600	2026-10-13 17:57:00.859604	383	\N	206PD00290
531	32540502822	1	2026-07-20	LIMEIRA	PLANTAO POLICIAL LIMEIRA	138.31	058.00086330/202620	2026-10-13 17:57:00.859604	529	\N	2026PD00311
532	32540502822	1	2026-08-26	LIMEIRA	PLANTAO POLICIAL LIMEIRA	138.31	058.00101723/202671	2026-10-13 17:57:00.859604	414	\N	2026PD00402
772	32628691809	2	2026-04-14	PIRACICABA	CURSO ACADEPOL	69.15	058.00048528/202613	2026-10-13 17:57:00.859604	413	\N	2026PD00164
773	32628691809	2	2026-05-04	PIRACICABA	CURSO ACADEPOL	69.15	058.00055990/202669	2026-10-13 17:57:00.859604	561	\N	2026PD00221
774	32628691809	2	2026-05-05	PIRACICABA	CURSO ACADEPOL	69.15	058.00055999/202670	2026-10-13 17:57:00.859604	550	\N	2026PD00221
803	32628691809	2	2026-05-06	PIRACICABA	CURSO ACADEPOL	69.15	058.00056002/202607	2026-10-13 17:57:00.859604	428	\N	2026PD00221
769	32968804880	2	2026-08-27	SAO PAULO	AGOSTO LILAS	248.96	058.00102590/202650	2026-10-13 17:57:00.859604	553	\N	2026PD00368
702	33648957830	2	2026-05-04	PIRACICABA	CURSO ACADEPOL	69.15	058.00056878/202645	2026-10-13 17:57:00.859604	520	\N	2026PD00222
707	33648957830	2	2026-05-05	PIRACICABA	CURSO ACADEPOL	69.15	058.00056878/202645	2026-10-13 17:57:00.859604	520	\N	2026PD00222
710	33648957830	2	2026-05-06	PIRACICABA	CURSO ACADEPOL	69.15	058.00056878/202645	2026-10-13 17:57:00.859604	520	\N	2026PD00222
758	33648957830	2	2026-06-25	PIRACICABA	CURSO ACADEPOL	69.15	058.00078792/202673	2026-10-13 17:57:00.859604	493	\N	2026PD00261
770	33648957830	2	2026-06-26	PIRACICABA	CURSO ACADEPOL	69.15	058.00078792/202673	2026-10-13 17:57:00.859604	493	\N	2026PD00261
730	35313574841	2	2026-06-25	PIRACICABA	CURSO ACADEPOL	69.15	058.00078470/202624	2026-10-13 17:57:00.859604	445	\N	2026PD00262
731	35313574841	2	2026-06-26	PIRACICABA	CURSO ACADEPOL	69.15	058.00078470/202624	2026-10-13 17:57:00.859604	445	\N	2026PD00262
826	35500297805	2	2026-04-19	CHARQUEADA	CUSRO TAT I	69.15	058.00051312/202627	2026-10-14 16:11:58.837708	374	\N	2026PD00165
705	35500297805	2	2026-04-23	CHARQUEADA	CURSO ACADEPOL TAT  I	69.15	058.00051312/202627	2026-10-13 17:57:00.859604	374	\N	2026PD00165
706	35500297805	2	2026-04-26	CHARQUEADA	CURSO ACADEPOL TAT  I	69.15	058.00051312/202627	2026-10-13 17:57:00.859604	374	\N	2026PD00165
771	35932472839	2	2026-03-27	PIRACICABA	CURSO TIRO	69.15	058.00041533/202668	2026-10-13 17:57:00.859604	511	\N	2026PD00133
547	36025331820	1	2026-02-07	PIRACICABA	PLANTAO POLICIAL LIMEIRA	207.46	058.00018728/202633	2026-10-13 17:57:00.859604	477	\N	2026PD00078
548	36025331820	1	2026-03-16	SAO PAULO	SERVIÇO POLICIAL	248.96	058.00036565/202671	2026-10-13 17:57:00.859604	524	\N	2026PD00124
634	36750397816	1	2026-02-04	CAPIVARI	SERVIÇO POLICIAL	138.31	058.00020892/202619	2026-10-13 17:57:00.859604	513	\N	2026PD00079
635	36750397816	1	2026-03-10	MONTE MOR	SERVIÇO POLICIAL	69.15	058.00033148/202676	2026-10-13 17:57:00.859604	442	\N	2026PD00125
636	36750397816	1	2026-03-13	PIRACICABA	SERVIÇO POLICIAL	69.15	058.00035638/202615	2026-10-13 17:57:00.859604	373	\N	2026PD00125
637	36750397816	1	2026-04-09	SAO PAULO	SERVIÇO POLICIAL	248.96	058.00045732/202674	2026-10-13 17:57:00.859604	482	\N	2026PD00178
722	36819640846	2	2026-08-27	SAO PAULO	AGOSTO LILAS	248.96	058.00101929/202609	2026-10-13 17:57:00.859604	515	\N	2026PD00369
543	38355373855	1	2026-08-05	PIRACICABA	SERVIÇO POLICIAL	103.73	058.00094564/202641	2026-10-13 17:57:00.859604	507	\N	2026PD00402
549	39460172822	1	2026-01-27	PIRACICABA	PLANTAO POLICIAL LIMEIRA	207.46	058.00012100/202624	2026-10-13 17:57:00.859604	544	\N	2026PD00056
550	39460172822	1	2026-02-10	SAO PAULO	SERVIÇO POLICIAL	248.96	058.00020495/202639	2026-10-13 17:57:00.859604	548	\N	2026PD00080
551	39460172822	1	2026-02-22	LIMEIRA	PLANTAO POLICIAL LIMEIRA	207.46	058.00023999/202619	2026-10-13 17:57:00.859604	394	\N	2026PD00080
552	39460172822	1	2026-03-06	JAGUARIUNA	SERVIÇO POLICIAL	69.15	058.00031184/202603	2026-10-13 17:57:00.859604	554	\N	2026PD00126
553	39460172822	1	2026-04-26	LIMEIRA	SERVIÇO POLICIAL	207.45	058.00051656/202636	2026-10-13 17:57:00.859604	551	\N	2026PD00179
554	39460172822	1	2026-06-12	LIMEIRA	PLANTAO POLICIAL LIMEIRA	207.46	058.00074738/202659	2026-10-13 17:57:00.859604	497	\N	2026PD00292
555	39460172822	1	2026-06-25	LIMEIRA	PLANTAO POLICIAL LIMEIRA	207.46	058.00077762/202640	2026-10-13 17:57:00.859604	401	\N	2026PD00292
712	39460172822	2	2026-06-25	SAO PAULO	SEMINARIO	248.96	058.00077762/202640	2026-10-13 17:57:00.859604	401	\N	2026PD00292
556	39460172822	1	2026-07-03	LIMEIRA	PLANTAO POLICIAL LIMEIRA	207.46	058.00080648/202605	2026-10-13 17:57:00.859604	540	\N	2026PD00313
557	39460172822	1	2026-08-22	LIMEIRA	PLANTAO POLICIAL LIMEIRA	207.46	058.00099842/202656	2026-10-13 17:57:00.859604	426	\N	2026PD00402
539	40381911845	1	2026-02-25	SAO PAULO	SERVIÇO POLICIAL	248.96	058.00027335/202611	2026-10-13 17:57:00.859604	498	\N	2026PD00081
540	40381911845	1	2026-02-26	POÇOS DE CALDAS	SERVIÇO POLICIAL	207.46	058.00027352/202658	2026-10-13 17:57:00.859604	410	\N	2026PD00081
759	40381911845	2	2026-03-16	SAO PAULO	CURSO OPERACIONAL PMSP	248.96	058.00041483/202648	2026-10-13 17:57:00.859604	509	\N	2026PD00134
760	40381911845	2	2026-03-17	SAO PAULO	CURSO OPERACIONAL PMSP	248.96	058.00041483/202648	2026-10-13 17:57:00.859604	509	\N	2026PD00134
761	40381911845	2	2026-03-18	SAO PAULO	CURSO OPERACIONAL PMSP	248.96	058.00041483/202648	2026-10-13 17:57:00.859604	509	\N	2026PD00134
762	40381911845	2	2026-03-19	SAO PAULO	CURSO OPERACIONAL PMSP	248.96	058.00041483/202648	2026-10-13 17:57:00.859604	509	\N	2026PD00134
763	40381911845	2	2026-03-20	SAO PAULO	CURSO OPERACIONAL PMSP	248.96	058.00041483/202648	2026-10-13 17:57:00.859604	509	\N	2026PD00134
764	40381911845	2	2026-03-23	SAO PAULO	CURSO OPERACIONAL PMSP	248.96	058.00041483/202648	2026-10-13 17:57:00.859604	509	\N	2026PD00134
765	40381911845	2	2026-03-24	SAO PAULO	CURSO OPERACIONAL PMSP	248.96	058.00041483/202648	2026-10-13 17:57:00.859604	509	\N	2026PD00134
766	40381911845	2	2026-03-25	SAO PAULO	CURSO OPERACIONAL PMSP	248.96	058.00041483/202648	2026-10-13 17:57:00.859604	509	\N	2026PD00134
767	40381911845	2	2026-03-26	SAO PAULO	CURSO OPERACIONAL PMSP	248.96	058.00041483/202648	2026-10-13 17:57:00.859604	509	\N	2026PD00134
768	40381911845	2	2026-03-27	SAO PAULO	CURSO OPERACIONAL PMSP	248.96	058.00041483/202648	2026-10-13 17:57:00.859604	509	\N	2026PD00134
541	40381911845	1	2026-06-19	RIO DE JANEIRO	SERVIÇO POLICIAL	822.94	058.00074738/2026-59	2026-10-13 17:57:00.859604	518	\N	2026PD00293
442	40952268892	1	2026-02-12	CAPIVARI	SERVIÇO POLICIAL	138.31	058.00020923/202623	2026-10-13 17:57:00.859604	406	\N	2026PD00082
443	40952268892	1	2026-03-10	MONTE MOR	SERVIÇO POLICIAL	69.15	058.00033157/202667	2026-10-13 17:57:00.859604	392	\N	2026PD00127
444	40952268892	1	2026-03-13	PIRACICABA	SERVIÇO POLICIAL	69.15	058.00035649/202697	2026-10-13 17:57:00.859604	527	\N	2026PD00127
445	40952268892	1	2026-04-09	SAO PAULO	SERVIÇO POLICIAL	248.96	058.00045723/202683	2026-10-13 17:57:00.859604	467	\N	2026PD00180
396	42582609838	1	2026-01-01	PIRACICABA	PLANTAO POLICIAL LIMEIRA	207.46	058.00001037/202609	2026-10-13 17:57:00.859604	375	\N	2026PD00057
397	42582609838	1	2026-02-08	LIMEIRA	PLANTAO POLICIAL LIMEIRA	69.15	058.00018050/202699	2026-10-13 17:57:00.859604	514	\N	2026PD00083
398	42582609838	1	2026-02-12	LIMEIRA	PLANTAO POLICIAL LIMEIRA	207.46	058.00024277/202673	2026-10-13 17:57:00.859604	503	\N	2026PD00083
399	42582609838	1	2026-03-07	LIMEIRA	PLANTAO POLICIAL LIMEIRA	69.15	058.00031765/202637	2026-10-13 17:57:00.859604	416	\N	2026PD00128
700	42582609838	2	2026-03-16	SAO PAULO	SEMINARIO FEMINICIDIO	248.96	058.00036561/202692	2026-10-13 17:57:00.859604	464	\N	2026PD00135
701	42582609838	2	2026-03-26	RIO CLARO	CURSO TIRO	69.15	058.00040322/202637	2026-10-13 17:57:00.859604	490	\N	2026PD00135
504	42582609838	1	2026-03-29	LIMEIRA	PLANTAO POLICIAL LIMEIRA	69.15	058.00040310/202611	2026-10-13 17:57:00.859604	441	\N	2026PD00128
505	42582609838	1	2026-04-21	LIMEIRA	PLANTAO POLICIAL LIMEIRA	69.15	058.00052538/202645	2026-10-13 17:57:00.859604	537	\N	2026PD00166
816	35500297805	1	2026-06-19	RIO DE JANEIRO	SERVICO POLICIAL	822.94	058.00074727/202679	2026-10-14 15:30:36.609726	399	\N	2026PD00291
704	42582609838	2	2026-04-23	SAO PAULO	PALESTRA ACADEPOL	124.48	058.00052548/202681	2026-10-13 17:57:00.859604	433	\N	2026PD00166
506	42582609838	1	2026-05-09	LIMEIRA	PLANTAO POLICIAL LIMEIRA	69.15	058.00057813/202617	2026-10-13 17:57:00.859604	369	\N	2026PD00245
507	42582609838	1	2026-06-29	LIMEIRA	PLANTAO POLICIAL LIMEIRA	138.31	058.00081687/202611	2026-10-13 17:57:00.859604	397	\N	2026PD00128
508	42582609838	1	2026-07-11	LIMEIRA	PLANTAO POLICIAL LIMEIRA	69.15	058.00084233/202601	2026-10-13 17:57:00.859604	563	\N	2026PD00314
509	42582609838	1	2026-07-28	LIMEIRA	PLANTAO POLICIAL LIMEIRA	138.31	058.00090988/202636	2026-10-13 17:57:00.859604	379	\N	2026PD00337
709	42582609838	2	2026-08-27	LIMEIRA	AGOSTO LILAS	248.96	058.00102757/202682	2026-10-13 17:57:00.859604	431	\N	2026PD00370
510	42582609838	1	2026-08-28	LIMEIRA	PLANTAO POLICIAL LIMEIRA	138.31	058.00102726/202621	2026-10-13 17:57:00.859604	407	\N	2026PD00402
711	42582609838	2	2026-09-02	LIMEIRA	VIOLENCIA DE GENERO	248.96	058.00105727/202628	2026-10-13 17:57:00.859604	456	\N	2026PD00370
757	42610681844	2	2026-03-26	RIO CLARO	CURSO TIRO	107.57	058.00040956/202690	2026-10-13 17:57:00.859604	471	\N	2026PD00167
562	42610681844	1	2026-05-20	SAO PAULO	SERVIÇO POLICIAL	193.63	058.00063384/202617	2026-10-13 17:57:00.859604	559	\N	2026PD00246
563	42610681844	1	2026-06-09	SAO PAULO	SERVIÇO POLICIAL	193.63	058.00070670/202639	2026-10-13 17:57:00.859604	411	\N	2026PD00294
525	43992425827	1	2026-01-07	PIRACICABA	PLANTAO POLICIAL LIMEIRA	207.46	058.00003563/202603	2026-10-13 17:57:00.859604	463	\N	2026PD00058
449	44519520851	1	2026-06-01	LIMEIRA	SERVIÇO POLICIAL	69.15	058.00080283/202619	2026-10-13 17:57:00.859604	420	\N	2026PD00297
450	44519520851	1	2026-06-02	LIMEIRA	SERVIÇO POLICIAL	69.15	058.00080283/202619	2026-10-13 17:57:00.859604	420	\N	2026PD00297
451	44519520851	1	2026-06-03	LIMEIRA	SERVIÇO POLICIAL	69.15	058.00080283/202619	2026-10-13 17:57:00.859604	420	\N	2026PD00297
452	44519520851	1	2026-06-04	LIMEIRA	SERVIÇO POLICIAL	69.15	058.00080283/202619	2026-10-13 17:57:00.859604	420	\N	2026PD00297
453	44519520851	1	2026-06-05	LIMEIRA	SERVIÇO POLICIAL	69.15	058.00080283/202619	2026-10-13 17:57:00.859604	420	\N	2026PD00297
454	44519520851	1	2026-06-08	LIMEIRA	SERVIÇO POLICIAL	69.15	058.00080283/202619	2026-10-13 17:57:00.859604	420	\N	2026PD00297
455	44519520851	1	2026-06-09	LIMEIRA	SERVIÇO POLICIAL	69.15	058.00080283/202619	2026-10-13 17:57:00.859604	420	\N	2026PD00297
456	44519520851	1	2026-06-10	LIMEIRA	SERVIÇO POLICIAL	69.15	058.00080283/202619	2026-10-13 17:57:00.859604	420	\N	2026PD00297
457	44519520851	1	2026-06-11	LIMEIRA	SERVIÇO POLICIAL	69.15	058.00080283/202619	2026-10-13 17:57:00.859604	420	\N	2026PD00297
458	44519520851	1	2026-06-12	LIMEIRA	SERVIÇO POLICIAL	69.15	058.00080283/202619	2026-10-13 17:57:00.859604	420	\N	2026PD00297
459	44519520851	1	2026-06-15	LIMEIRA	SERVIÇO POLICIAL	69.15	058.00080283/202619	2026-10-13 17:57:00.859604	420	\N	2026PD00297
460	44519520851	1	2026-06-16	LIMEIRA	SERVIÇO POLICIAL	69.15	058.00080283/202619	2026-10-13 17:57:00.859604	420	\N	2026PD00297
461	44519520851	1	2026-06-17	LIMEIRA	SERVIÇO POLICIAL	69.15	058.00080283/202619	2026-10-13 17:57:00.859604	420	\N	2026PD00297
462	44519520851	1	2026-06-18	LIMEIRA	SERVIÇO POLICIAL	69.15	058.00080283/202619	2026-10-13 17:57:00.859604	420	\N	2026PD00297
463	44519520851	1	2026-06-19	LIMEIRA	SERVIÇO POLICIAL	69.15	058.00080283/202619	2026-10-13 17:57:00.859604	420	\N	2026PD00297
464	44519520851	1	2026-06-22	LIMEIRA	SERVIÇO POLICIAL	69.15	058.00080283/202619	2026-10-13 17:57:00.859604	420	\N	2026PD00297
465	44519520851	1	2026-06-23	LIMEIRA	SERVIÇO POLICIAL	69.15	058.00080283/202619	2026-10-13 17:57:00.859604	420	\N	2026PD00297
466	44519520851	1	2026-06-24	LIMEIRA	SERVIÇO POLICIAL	69.15	058.00080283/202619	2026-10-13 17:57:00.859604	420	\N	2026PD00297
467	44519520851	1	2026-06-25	LIMEIRA	SERVIÇO POLICIAL	69.15	058.00080283/202619	2026-10-13 17:57:00.859604	420	\N	2026PD00297
468	44519520851	1	2026-06-26	LIMEIRA	SERVIÇO POLICIAL	69.15	058.00080283/202619	2026-10-13 17:57:00.859604	420	\N	2026PD00297
469	44519520851	1	2026-07-14	LIMEIRA	ACUMULO DE FUNÇÃO	69.15	058.00092795/202610	2026-10-13 17:57:00.859604	496	\N	2026PD00338
470	44519520851	1	2026-07-15	LIMEIRA	ACUMULO DE FUNÇÃO	69.15	058.00092795/202610	2026-10-13 17:57:00.859604	496	\N	2026PD00338
471	44519520851	1	2026-07-16	LIMEIRA	ACUMULO DE FUNÇÃO	69.15	058.00092795/202610	2026-10-13 17:57:00.859604	496	\N	2026PD00338
472	44519520851	1	2026-07-17	LIMEIRA	ACUMULO DE FUNÇÃO	69.15	058.00092795/202610	2026-10-13 17:57:00.859604	496	\N	2026PD00338
473	44519520851	1	2026-07-20	LIMEIRA	ACUMULO DE FUNÇÃO	69.15	058.00092795/202610	2026-10-13 17:57:00.859604	496	\N	2026PD00338
474	44519520851	1	2026-07-21	LIMEIRA	ACUMULO DE FUNÇÃO	69.15	058.00092795/202610	2026-10-13 17:57:00.859604	496	\N	2026PD00338
475	44519520851	1	2026-07-22	LIMEIRA	ACUMULO DE FUNÇÃO	69.15	058.00092795/202610	2026-10-13 17:57:00.859604	496	\N	2026PD00338
476	44519520851	1	2026-07-23	LIMEIRA	ACUMULO DE FUNÇÃO	69.15	058.00092795/202610	2026-10-13 17:57:00.859604	496	\N	2026PD00338
477	44519520851	1	2026-07-24	LIMEIRA	ACUMULO DE FUNÇÃO	69.15	058.00092795/202610	2026-10-13 17:57:00.859604	496	\N	2026PD00338
478	44519520851	1	2026-07-27	LIMEIRA	ACUMULO DE FUNÇÃO	69.15	058.00092795/202610	2026-10-13 17:57:00.859604	496	\N	2026PD00338
479	44519520851	1	2026-07-28	LIMEIRA	ACUMULO DE FUNÇÃO	69.15	058.00092795/202610	2026-10-13 17:57:00.859604	496	\N	2026PD00338
480	44519520851	1	2026-07-29	LIMEIRA	ACUMULO DE FUNÇÃO	69.15	058.00092795/202610	2026-10-13 17:57:00.859604	496	\N	2026PD00338
481	44519520851	1	2026-07-30	LIMEIRA	ACUMULO DE FUNÇÃO	69.15	058.00092795/202610	2026-10-13 17:57:00.859604	496	\N	2026PD00338
482	44519520851	1	2026-07-31	LIMEIRA	ACUMULO DE FUNÇÃO	69.15	058.00092795/202610	2026-10-13 17:57:00.859604	496	\N	2026PD00338
483	44519520851	1	2026-08-03	LIMEIRA	ACUMULO DE FUNÇÃO	69.15	058.00103808/202693	2026-10-13 17:57:00.859604	465	\N	2026PD00402
484	44519520851	1	2026-08-04	LIMEIRA	ACUMULO DE FUNÇÃO	69.15	058.00103808/202693	2026-10-13 17:57:00.859604	465	\N	2026PD00402
485	44519520851	1	2026-08-05	LIMEIRA	ACUMULO DE FUNÇÃO	69.15	058.00103808/202693	2026-10-13 17:57:00.859604	465	\N	2026PD00402
486	44519520851	1	2026-08-06	LIMEIRA	ACUMULO DE FUNÇÃO	69.15	058.00103808/202693	2026-10-13 17:57:00.859604	465	\N	2026PD00402
487	44519520851	1	2026-08-07	LIMEIRA	ACUMULO DE FUNÇÃO	69.15	058.00103808/202693	2026-10-13 17:57:00.859604	465	\N	2026PD00402
488	44519520851	1	2026-08-10	LIMEIRA	ACUMULO DE FUNÇÃO	69.15	058.00103808/202693	2026-10-13 17:57:00.859604	465	\N	2026PD00402
489	44519520851	1	2026-08-11	LIMEIRA	ACUMULO DE FUNÇÃO	69.15	058.00103808/202693	2026-10-13 17:57:00.859604	465	\N	2026PD00402
490	44519520851	1	2026-08-12	LIMEIRA	ACUMULO DE FUNÇÃO	69.15	058.00103808/202693	2026-10-13 17:57:00.859604	465	\N	2026PD00402
491	44519520851	1	2026-08-13	LIMEIRA	ACUMULO DE FUNÇÃO	69.15	058.00103808/202693	2026-10-13 17:57:00.859604	465	\N	2026PD00402
492	44519520851	1	2026-08-14	LIMEIRA	ACUMULO DE FUNÇÃO	69.15	058.00103808/202693	2026-10-13 17:57:00.859604	465	\N	2026PD00402
493	44519520851	1	2026-08-17	LIMEIRA	ACUMULO DE FUNÇÃO	69.15	058.00103808/202693	2026-10-13 17:57:00.859604	465	\N	2026PD00402
494	44519520851	1	2026-08-18	LIMEIRA	ACUMULO DE FUNÇÃO	69.15	058.00103808/202693	2026-10-13 17:57:00.859604	465	\N	2026PD00402
495	44519520851	1	2026-08-19	LIMEIRA	ACUMULO DE FUNÇÃO	69.15	058.00103808/202693	2026-10-13 17:57:00.859604	465	\N	2026PD00402
496	44519520851	1	2026-08-20	LIMEIRA	ACUMULO DE FUNÇÃO	69.15	058.00103808/202693	2026-10-13 17:57:00.859604	465	\N	2026PD00402
497	44519520851	1	2026-08-21	LIMEIRA	ACUMULO DE FUNÇÃO	69.15	058.00103808/202693	2026-10-13 17:57:00.859604	465	\N	2026PD00402
498	44519520851	1	2026-08-24	LIMEIRA	ACUMULO DE FUNÇÃO	69.15	058.00103808/202693	2026-10-13 17:57:00.859604	465	\N	2026PD00402
499	44519520851	1	2026-08-25	LIMEIRA	ACUMULO DE FUNÇÃO	69.15	058.00103808/202693	2026-10-13 17:57:00.859604	465	\N	2026PD00402
500	44519520851	1	2026-08-26	LIMEIRA	ACUMULO DE FUNÇÃO	69.15	058.00103808/202693	2026-10-13 17:57:00.859604	465	\N	2026PD00402
501	44519520851	1	2026-08-27	LIMEIRA	ACUMULO DE FUNÇÃO	69.15	058.00103808/202693	2026-10-13 17:57:00.859604	465	\N	2026PD00402
502	44519520851	1	2026-08-28	LIMEIRA	ACUMULO DE FUNÇÃO	69.15	058.00103808/202693	2026-10-13 17:57:00.859604	465	\N	2026PD00402
503	44519520851	1	2026-08-31	LIMEIRA	ACUMULO DE FUNÇÃO	69.15	058.00103808/202693	2026-10-13 17:57:00.859604	465	\N	2026PD00402
516	46508753827	1	2026-04-09	SAO PAULO	SERVIÇO POLICIAL	248.96	058.00045929/202611	2026-10-13 17:57:00.859604	502	\N	2026PD00183
718	46508753827	2	2026-05-04	PIRACICABA	CURSO ACADEPOL	69.15	058.00056375/202670	2026-10-13 17:57:00.859604	541	\N	2026PD00223
719	46508753827	2	2026-05-05	PIRACICABA	CURSO ACADEPOL	69.15	058.00056379/202658	2026-10-13 17:57:00.859604	489	\N	2026PD00223
720	46508753827	2	2026-05-06	PIRACICABA	CURSO ACADEPOL	69.15	058.00056381/202627	2026-10-13 17:57:00.859604	491	\N	2026PD00223
564	47033640854	1	2026-06-19	RIO DE JANEIRO	SERVIÇO POLICIAL	822.94	058.00074730/202692	2026-10-13 17:57:00.859604	558	\N	2026PD00295
537	80184782104	1	2026-08-05	BARUERI	SERVIÇO POLICIAL	103.73	058.00094690/202603	2026-10-13 17:57:00.859604	534	\N	2026PD00343
802	82897123915	2	2026-04-23	SALTINHO	CURSO ACADEPOL	138.31	058.00052368/202607	2026-10-13 17:57:00.859604	556	\N	2026PD00168
\.


--
-- Data for Name: diarias_bkp_auditoria; Type: TABLE DATA; Schema: backup; Owner: postgres
--

COPY backup.diarias_bkp_auditoria (id_diaria, cpf_servidor, id_tipo, data_inicial, destino, motivo, valor_diaria, data_cadastro, id_processo, observacao, numero_pd) FROM stdin;
850	18208623806	2	2026-05-25	SAO PAULO	PALESTRA SISTEMA DE JUSTICA	248.96	2026-10-21 09:58:26.750297	450	\N	2026PD00220
834	85920356510	2	2026-09-26	PIRACICABA	CURSO MBA	103.73	2026-10-15 15:54:20.108825	583	\N	2026PD00418
649	10410326682	1	2026-01-07	PIRACICABA	PLANTAO POLICIAL LIMEIRA	207.46	2026-10-13 17:57:00.859604	446	\N	2026PD00047
845	09085540950	1	2026-09-25	SAO PAULO	SERVICO POLICIAL	124.48	2026-10-15 15:58:54.507043	585	\N	2026PD00420
813	07902044792	1	2026-04-09	SAO PAULO	SERVICO POLICIAL	124.48	2026-10-14 15:20:48.32486	562	\N	2026PD00171
814	09595897833	1	2026-02-12	CAPIVARI	SERVICO POLICIAL	69.15	2026-10-14 15:23:19.777539	412	\N	2026PD00069
821	10410326682	1	2026-02-14	PIRASSUNUNGA	SERVICO POLICIAL	138.31	2026-10-14 15:47:02.602612	444	\N	2026PD00114
822	10410326682	1	2026-02-15	PIRASSUNUNGA	SERVICO POLICIAL	138.31	2026-10-14 15:47:17.322943	444	\N	2026PD00114
825	10410326682	1	2026-02-22	PIRASSUNUNGA	SERVICO POLICIAL	69.15	2026-10-14 15:47:48.416271	444	\N	2026PD00114
823	10410326682	1	2026-02-23	PIRASSUNUNGA	SERVICO POLICIAL	138.31	2026-10-14 15:47:26.244429	444	\N	2026PD00114
824	10410326682	1	2026-02-27	PIRASSUNUNGA	SERVICO POLICIAL	138.31	2026-10-14 15:47:32.122151	444	\N	2026PD00114
817	32968804880	1	2026-01-27	PIRACICABA	SERVICO POLICIAL	207.46	2026-10-14 15:33:21.063693	543	\N	2026PD00055
818	32968804880	1	2026-02-17	LIMEIRA	SERVICO POLICIAL	103.73	2026-10-14 15:36:06.032777	387	\N	2026PD00077
819	32968804880	1	2026-03-06	JAGARIUNA	SERVICO POLICIAL	69.15	2026-10-14 15:38:52.861027	512	\N	2026PD00123
648	32968804880	1	2026-03-06	JAGUARIUNA	SERVICO POLICIAL	69.15	2026-10-13 17:57:00.859604	512	\N	2026PD00123
835	10995999899	1	2026-09-01	LIMEIRA	ACUMULO DE FUNCAO	107.57	2026-10-15 15:55:55.417902	584	\N	2026PD00419
836	10995999899	1	2026-09-04	LIMEIRA	ACUMULO DE FUNCAO	107.57	2026-10-15 15:56:01.455005	584	\N	2026PD00419
837	10995999899	1	2026-09-07	LIMEIRA	ACUMULO DE FUNCAO	107.57	2026-10-15 15:56:06.780392	584	\N	2026PD00419
838	10995999899	1	2026-09-10	LIMEIRA	ACUMULO DE FUNCAO	107.57	2026-10-15 15:56:12.032533	584	\N	2026PD00419
839	10995999899	1	2026-09-13	LIMEIRA	ACUMULO DE FUNCAO	107.57	2026-10-15 15:56:20.680416	584	\N	2026PD00419
840	10995999899	1	2026-09-14	LIMEIRA	ACUMULO DE FUNCAO	107.57	2026-10-15 15:56:26.064817	584	\N	2026PD00419
841	10995999899	1	2026-09-16	LIMEIRA	ACUMULO DE FUNCAO	107.57	2026-10-15 15:56:32.12167	584	\N	2026PD00419
842	10995999899	1	2026-09-22	LIMEIRA	ACUMULO DE FUNCAO	107.57	2026-10-15 15:56:38.802749	584	\N	2026PD00419
843	10995999899	1	2026-09-25	LIMEIRA	ACUMULO DE FUNCAO	107.57	2026-10-15 15:56:43.449109	584	\N	2026PD00419
844	10995999899	1	2026-09-28	LIMEIRA	ACUMULO DE FUNCAO	107.57	2026-10-15 15:56:49.346365	584	\N	2026PD00419
847	13934950876	1	2026-09-26	LIMEIRA	ACUMULO DE FUNCAO	161.36	2026-10-15 16:01:12.186859	586	\N	2026PD00421
848	13934950876	1	2026-09-27	LIMEIRA	ACUMULO DE FUNCAO	161.36	2026-10-15 16:01:20.301849	586	\N	2026PD00421
849	13934950876	1	2026-09-28	LIMEIRA	ACUMULO DE FUNCAO	161.36	2026-10-15 16:01:27.748525	586	\N	2026PD00421
521	04307176103	1	2026-02-10	SAO PAULO	SERVICO POLICIAL	248.96	2026-10-13 17:57:00.859604	505	\N	2026PD00068
523	11374959600	1	2026-08-05	BARUERI	SERVICO POLICIAL	103.73	2026-10-13 17:57:00.859604	393	\N	2026PD00334
524	11374959600	1	2026-08-17	PIRACICABA	SERVICO POLICIAL	103.73	2026-10-13 17:57:00.859604	473	\N	2026PD00402
441	12794506730	1	2026-06-09	SAO PAULO	SERVICO POLICIAL	248.96	2026-10-13 17:57:00.859604	457	\N	2026PD00296
689	19174943863	1	2026-02-20	SAO PAULO	SERVICO POLICIAL	248.96	2026-10-13 17:57:00.859604	427	\N	2026PD00071
447	19203432884	1	2026-04-15	SAO PAULO	SERVICO POLICIAL	248.96	2026-10-13 17:57:00.859604	506	\N	2026PD00174
448	19203432884	1	2026-06-09	SAO PAULO	SERVICO POLICIAL	248.96	2026-10-13 17:57:00.859604	453	\N	2026PD00285
639	19216935847	1	2026-03-06	JAGUARIUNA	SERVICO POLICIAL	69.15	2026-10-13 17:57:00.859604	390	\N	2026PD00117
517	21360741801	1	2026-02-12	CAPIVARI	SERVICO POLICIAL	138.31	2026-10-13 17:57:00.859604	417	\N	2026PD00072
518	21360741801	1	2026-03-13	PIRACICABA	SERVICO POLICIAL	53.78	2026-10-13 17:57:00.859604	499	\N	2026PD00118
519	21360741801	1	2026-03-20	SAO PAULO	SERVICO POLICIAL	96.81	2026-10-13 17:57:00.859604	536	\N	2026PD00118
534	21675933847	1	2026-02-26	POÇOS DE CALDAS	SERVICO POLICIAL	207.46	2026-10-13 17:57:00.859604	545	\N	2026PD00119
533	24886549810	1	2026-04-15	SAO PAULO	SERVICO POLICIAL	248.96	2026-10-13 17:57:00.859604	525	\N	2026PD00175
812	19216935847	1	2026-04-16	LIMEIRA	SERVICO POLICIAL	103.73	2026-10-14 15:17:54.234558	557	\N	2026PD00194
644	26451064807	1	2026-06-16	RIO DE JANEIRO	SERVICO POLICIAL	822.94	2026-10-13 17:57:00.859604	487	\N	2026PD00287
632	30841335818	1	2026-06-09	SAO PAULO	SERVICO POLICIAL	248.96	2026-10-13 17:57:00.859604	439	\N	\N
633	30841335818	1	2026-07-09	SAO PAULO	SERVICO POLICIAL	248.96	2026-10-13 17:57:00.859604	439	\N	\N
538	31082697800	1	2026-08-17	PIRACICABA	SERVICO POLICIAL	103.73	2026-10-13 17:57:00.859604	474	\N	2026PD00402
544	31239665857	1	2026-02-10	SAO PAULO	SERVICO POLICIAL	248.96	2026-10-13 17:57:00.859604	510	\N	2026PD00075
545	31239665857	1	2026-03-06	JAGUARIUNA	SERVICO POLICIAL	69.15	2026-10-13 17:57:00.859604	504	\N	2026PD00121
546	31239665857	1	2026-03-11	RIO CLARO	SERVICO POLICIAL	69.15	2026-10-13 17:57:00.859604	481	\N	2026PD00121
535	31892853817	1	2026-03-06	JAGUARIUNA	SERVICO POLICIAL	69.15	2026-10-13 17:57:00.859604	385	\N	2026PD00122
528	32540502822	1	2026-04-25	LIMEIRA	SERVICO POLICIAL	138.31	2026-10-13 17:57:00.859604	424	\N	2026PD00177
635	36750397816	1	2026-03-10	MONTE MOR	SERVICO POLICIAL	69.15	2026-10-13 17:57:00.859604	442	\N	2026PD00125
636	36750397816	1	2026-03-13	PIRACICABA	SERVICO POLICIAL	69.15	2026-10-13 17:57:00.859604	373	\N	2026PD00125
637	36750397816	1	2026-04-09	SAO PAULO	SERVICO POLICIAL	248.96	2026-10-13 17:57:00.859604	482	\N	2026PD00178
543	38355373855	1	2026-08-05	PIRACICABA	SERVICO POLICIAL	103.73	2026-10-13 17:57:00.859604	507	\N	2026PD00402
550	39460172822	1	2026-02-10	SAO PAULO	SERVICO POLICIAL	248.96	2026-10-13 17:57:00.859604	548	\N	2026PD00080
552	39460172822	1	2026-03-06	JAGUARIUNA	SERVICO POLICIAL	69.15	2026-10-13 17:57:00.859604	554	\N	2026PD00126
553	39460172822	1	2026-04-26	LIMEIRA	SERVICO POLICIAL	207.45	2026-10-13 17:57:00.859604	551	\N	2026PD00179
539	40381911845	1	2026-02-25	SAO PAULO	SERVICO POLICIAL	248.96	2026-10-13 17:57:00.859604	498	\N	2026PD00081
540	40381911845	1	2026-02-26	POÇOS DE CALDAS	SERVICO POLICIAL	207.46	2026-10-13 17:57:00.859604	410	\N	2026PD00081
541	40381911845	1	2026-06-19	RIO DE JANEIRO	SERVICO POLICIAL	822.94	2026-10-13 17:57:00.859604	518	\N	2026PD00293
442	40952268892	1	2026-02-12	CAPIVARI	SERVICO POLICIAL	138.31	2026-10-13 17:57:00.859604	406	\N	2026PD00082
443	40952268892	1	2026-03-10	MONTE MOR	SERVICO POLICIAL	69.15	2026-10-13 17:57:00.859604	392	\N	2026PD00127
444	40952268892	1	2026-03-13	PIRACICABA	SERVICO POLICIAL	69.15	2026-10-13 17:57:00.859604	527	\N	2026PD00127
445	40952268892	1	2026-04-09	SAO PAULO	SERVICO POLICIAL	248.96	2026-10-13 17:57:00.859604	467	\N	2026PD00180
816	35500297805	1	2026-06-19	RIO DE JANEIRO	SERVICO POLICIAL	822.94	2026-10-14 15:30:36.609726	399	\N	2026PD00291
562	42610681844	1	2026-05-20	SAO PAULO	SERVICO POLICIAL	193.63	2026-10-13 17:57:00.859604	559	\N	2026PD00246
563	42610681844	1	2026-06-09	SAO PAULO	SERVICO POLICIAL	193.63	2026-10-13 17:57:00.859604	411	\N	2026PD00294
449	44519520851	1	2026-06-01	LIMEIRA	SERVICO POLICIAL	69.15	2026-10-13 17:57:00.859604	420	\N	2026PD00297
450	44519520851	1	2026-06-02	LIMEIRA	SERVICO POLICIAL	69.15	2026-10-13 17:57:00.859604	420	\N	2026PD00297
451	44519520851	1	2026-06-03	LIMEIRA	SERVICO POLICIAL	69.15	2026-10-13 17:57:00.859604	420	\N	2026PD00297
452	44519520851	1	2026-06-04	LIMEIRA	SERVICO POLICIAL	69.15	2026-10-13 17:57:00.859604	420	\N	2026PD00297
453	44519520851	1	2026-06-05	LIMEIRA	SERVICO POLICIAL	69.15	2026-10-13 17:57:00.859604	420	\N	2026PD00297
454	44519520851	1	2026-06-08	LIMEIRA	SERVICO POLICIAL	69.15	2026-10-13 17:57:00.859604	420	\N	2026PD00297
455	44519520851	1	2026-06-09	LIMEIRA	SERVICO POLICIAL	69.15	2026-10-13 17:57:00.859604	420	\N	2026PD00297
456	44519520851	1	2026-06-10	LIMEIRA	SERVICO POLICIAL	69.15	2026-10-13 17:57:00.859604	420	\N	2026PD00297
457	44519520851	1	2026-06-11	LIMEIRA	SERVICO POLICIAL	69.15	2026-10-13 17:57:00.859604	420	\N	2026PD00297
458	44519520851	1	2026-06-12	LIMEIRA	SERVICO POLICIAL	69.15	2026-10-13 17:57:00.859604	420	\N	2026PD00297
459	44519520851	1	2026-06-15	LIMEIRA	SERVICO POLICIAL	69.15	2026-10-13 17:57:00.859604	420	\N	2026PD00297
460	44519520851	1	2026-06-16	LIMEIRA	SERVICO POLICIAL	69.15	2026-10-13 17:57:00.859604	420	\N	2026PD00297
461	44519520851	1	2026-06-17	LIMEIRA	SERVICO POLICIAL	69.15	2026-10-13 17:57:00.859604	420	\N	2026PD00297
462	44519520851	1	2026-06-18	LIMEIRA	SERVICO POLICIAL	69.15	2026-10-13 17:57:00.859604	420	\N	2026PD00297
463	44519520851	1	2026-06-19	LIMEIRA	SERVICO POLICIAL	69.15	2026-10-13 17:57:00.859604	420	\N	2026PD00297
464	44519520851	1	2026-06-22	LIMEIRA	SERVICO POLICIAL	69.15	2026-10-13 17:57:00.859604	420	\N	2026PD00297
465	44519520851	1	2026-06-23	LIMEIRA	SERVICO POLICIAL	69.15	2026-10-13 17:57:00.859604	420	\N	2026PD00297
466	44519520851	1	2026-06-24	LIMEIRA	SERVICO POLICIAL	69.15	2026-10-13 17:57:00.859604	420	\N	2026PD00297
467	44519520851	1	2026-06-25	LIMEIRA	SERVICO POLICIAL	69.15	2026-10-13 17:57:00.859604	420	\N	2026PD00297
468	44519520851	1	2026-06-26	LIMEIRA	SERVICO POLICIAL	69.15	2026-10-13 17:57:00.859604	420	\N	2026PD00297
567	10995999899	1	2026-03-01	LIMEIRA	ACUMULO DE FUNCAO	107.57	2026-10-13 17:57:00.859604	434	\N	2026PD00115
627	09085540950	1	2026-08-05	CASA BRANCA	SERVICO POLICIAL	207.46	2026-10-13 17:57:00.859604	466	\N	2026PD00344
568	10995999899	1	2026-03-04	LIMEIRA	ACUMULO DE FUNCAO	107.57	2026-10-13 17:57:00.859604	434	\N	2026PD00115
569	10995999899	1	2026-03-06	LIMEIRA	ACUMULO DE FUNCAO	107.57	2026-10-13 17:57:00.859604	434	\N	2026PD00115
570	10995999899	1	2026-03-07	LIMEIRA	ACUMULO DE FUNCAO	107.57	2026-10-13 17:57:00.859604	434	\N	2026PD00115
571	10995999899	1	2026-03-10	LIMEIRA	ACUMULO DE FUNCAO	107.57	2026-10-13 17:57:00.859604	434	\N	2026PD00115
572	10995999899	1	2026-03-13	LIMEIRA	ACUMULO DE FUNCAO	107.57	2026-10-13 17:57:00.859604	434	\N	2026PD00115
573	10995999899	1	2026-03-17	LIMEIRA	ACUMULO DE FUNCAO	107.57	2026-10-13 17:57:00.859604	434	\N	2026PD00115
574	10995999899	1	2026-03-21	LIMEIRA	ACUMULO DE FUNCAO	107.57	2026-10-13 17:57:00.859604	434	\N	2026PD00115
575	10995999899	1	2026-03-25	LIMEIRA	ACUMULO DE FUNCAO	107.57	2026-10-13 17:57:00.859604	434	\N	2026PD00115
576	10995999899	1	2026-04-02	LIMEIRA	ACUMULO DE FUNCAO	107.57	2026-10-13 17:57:00.859604	528	\N	2026PD00173
577	10995999899	1	2026-04-04	LIMEIRA	ACUMULO DE FUNCAO	107.57	2026-10-13 17:57:00.859604	528	\N	2026PD00173
578	10995999899	1	2026-04-05	LIMEIRA	ACUMULO DE FUNCAO	107.57	2026-10-13 17:57:00.859604	528	\N	2026PD00173
579	10995999899	1	2026-04-08	LIMEIRA	ACUMULO DE FUNCAO	107.57	2026-10-13 17:57:00.859604	528	\N	2026PD00173
580	10995999899	1	2026-04-10	LIMEIRA	ACUMULO DE FUNCAO	107.57	2026-10-13 17:57:00.859604	528	\N	2026PD00173
581	10995999899	1	2026-05-01	LIMEIRA	ACUMULO DE FUNCAO	107.57	2026-10-13 17:57:00.859604	523	\N	2026PD00238
582	10995999899	1	2026-05-05	LIMEIRA	ACUMULO DE FUNCAO	107.57	2026-10-13 17:57:00.859604	523	\N	2026PD00238
583	10995999899	1	2026-05-07	LIMEIRA	ACUMULO DE FUNCAO	107.57	2026-10-13 17:57:00.859604	523	\N	2026PD00238
584	10995999899	1	2026-05-09	LIMEIRA	ACUMULO DE FUNCAO	107.57	2026-10-13 17:57:00.859604	523	\N	2026PD00238
585	10995999899	1	2026-06-01	LIMEIRA	ACUMULO DE FUNCAO	107.57	2026-10-13 17:57:00.859604	542	\N	2026PD00282
586	10995999899	1	2026-06-02	LIMEIRA	ACUMULO DE FUNCAO	107.57	2026-10-13 17:57:00.859604	542	\N	2026PD00282
587	10995999899	1	2026-06-03	LIMEIRA	ACUMULO DE FUNCAO	107.57	2026-10-13 17:57:00.859604	542	\N	2026PD00282
588	10995999899	1	2026-06-14	LIMEIRA	ACUMULO DE FUNCAO	107.57	2026-10-13 17:57:00.859604	542	\N	2026PD00282
589	10995999899	1	2026-06-17	LIMEIRA	ACUMULO DE FUNCAO	107.57	2026-10-13 17:57:00.859604	542	\N	2026PD00282
590	10995999899	1	2026-06-18	LIMEIRA	ACUMULO DE FUNCAO	107.57	2026-10-13 17:57:00.859604	542	\N	2026PD00282
591	10995999899	1	2026-06-21	LIMEIRA	ACUMULO DE FUNCAO	107.57	2026-10-13 17:57:00.859604	542	\N	2026PD00282
592	10995999899	1	2026-06-22	LIMEIRA	ACUMULO DE FUNCAO	107.57	2026-10-13 17:57:00.859604	542	\N	2026PD00282
593	10995999899	1	2026-06-25	LIMEIRA	ACUMULO DE FUNCAO	107.57	2026-10-13 17:57:00.859604	542	\N	2026PD00282
594	10995999899	1	2026-06-26	LIMEIRA	ACUMULO DE FUNCAO	107.57	2026-10-13 17:57:00.859604	542	\N	2026PD00282
595	10995999899	1	2026-07-02	LIMEIRA	ACUMULO DE FUNCAO	107.57	2026-10-13 17:57:00.859604	440	\N	2026PD00306
600	10995999899	1	2026-07-17	LIMEIRA	ACUMULO DE FUNCAO	107.57	2026-10-13 17:57:00.859604	501	\N	2026PD00306
601	10995999899	1	2026-07-20	LIMEIRA	ACUMULO DE FUNCAO	107.57	2026-10-13 17:57:00.859604	404	\N	2026PD00306
602	10995999899	1	2026-07-21	LIMEIRA	ACUMULO DE FUNCAO	107.57	2026-10-13 17:57:00.859604	403	\N	2026PD00306
603	10995999899	1	2026-07-24	LIMEIRA	ACUMULO DE FUNCAO	107.57	2026-10-13 17:57:00.859604	484	\N	2026PD00306
604	10995999899	1	2026-07-25	LIMEIRA	ACUMULO DE FUNCAO	107.57	2026-10-13 17:57:00.859604	539	\N	2026PD00306
605	10995999899	1	2026-07-28	LIMEIRA	ACUMULO DE FUNCAO	107.57	2026-10-13 17:57:00.859604	479	\N	2026PD00306
606	10995999899	1	2026-07-29	LIMEIRA	ACUMULO DE FUNCAO	107.57	2026-10-13 17:57:00.859604	532	\N	2026PD00306
607	10995999899	1	2026-08-05	LIMEIRA	ACUMULO DE FUNCAO	107.57	2026-10-13 17:57:00.859604	461	\N	2026PD00402
608	10995999899	1	2026-08-09	LIMEIRA	ACUMULO DE FUNCAO	107.57	2026-10-13 17:57:00.859604	461	\N	2026PD00402
609	10995999899	1	2026-08-11	LIMEIRA	ACUMULO DE FUNCAO	107.57	2026-10-13 17:57:00.859604	461	\N	2026PD00402
610	10995999899	1	2026-08-14	LIMEIRA	ACUMULO DE FUNCAO	107.57	2026-10-13 17:57:00.859604	461	\N	2026PD00402
611	10995999899	1	2026-08-20	LIMEIRA	ACUMULO DE FUNCAO	107.57	2026-10-13 17:57:00.859604	461	\N	2026PD00402
612	10995999899	1	2026-08-21	LIMEIRA	ACUMULO DE FUNCAO	107.57	2026-10-13 17:57:00.859604	461	\N	2026PD00402
613	10995999899	1	2026-08-22	LIMEIRA	ACUMULO DE FUNCAO	107.57	2026-10-13 17:57:00.859604	461	\N	2026PD00402
614	10995999899	1	2026-08-23	LIMEIRA	ACUMULO DE FUNCAO	107.57	2026-10-13 17:57:00.859604	461	\N	2026PD00402
615	10995999899	1	2026-08-26	LIMEIRA	ACUMULO DE FUNCAO	107.57	2026-10-13 17:57:00.859604	461	\N	2026PD00402
616	10995999899	1	2026-08-29	LIMEIRA	ACUMULO DE FUNCAO	107.57	2026-10-13 17:57:00.859604	461	\N	2026PD00402
411	13934950876	1	2026-07-02	LIMEIRA	ACUMULO DE FUNCAO	161.36	2026-10-13 17:57:00.859604	494	\N	2026PD00335
412	13934950876	1	2026-07-04	LIMEIRA	ACUMULO DE FUNCAO	161.36	2026-10-13 17:57:00.859604	494	\N	2026PD00335
413	13934950876	1	2026-07-06	LIMEIRA	ACUMULO DE FUNCAO	161.36	2026-10-13 17:57:00.859604	494	\N	2026PD00335
414	13934950876	1	2026-07-09	LIMEIRA	ACUMULO DE FUNCAO	161.36	2026-10-13 17:57:00.859604	494	\N	2026PD00335
415	13934950876	1	2026-07-11	LIMEIRA	ACUMULO DE FUNCAO	161.36	2026-10-13 17:57:00.859604	494	\N	2026PD00335
416	13934950876	1	2026-07-12	LIMEIRA	ACUMULO DE FUNCAO	161.36	2026-10-13 17:57:00.859604	494	\N	2026PD00335
417	13934950876	1	2026-07-15	LIMEIRA	ACUMULO DE FUNCAO	161.36	2026-10-13 17:57:00.859604	494	\N	2026PD00335
418	13934950876	1	2026-07-18	LIMEIRA	ACUMULO DE FUNCAO	161.36	2026-10-13 17:57:00.859604	494	\N	2026PD00335
810	05484576709	1	2026-02-26	POCOS DE CALDAS	SERVICO POLICIAL	207.46	2026-10-14 14:52:38.767455	566	\N	2026PD00113
638	36750397816	1	2026-07-16	MOCOCA	SERVICO POLICIAL	69.15	2026-10-13 17:57:00.859604	530	\N	2026PD00315
815	26451064807	1	2026-06-19	RIO DE JANEIRO	SERVICO POLICIAL	822.94	2026-10-14 15:27:31.549516	487	\N	2026PD00287
820	10410326682	1	2026-02-25	PIRACICABA	SERVICO POLICIAL	207.46	2026-10-14 15:42:04.872453	446	\N	2026PD00047
808	19216935847	2	2026-09-30	SAO PAULO	CURSO COP	726.13	2026-10-14 10:40:15.851882	565	\N	\N
798	01110375816	2	2023-09-06	SAO PAULO	CURSO SSP	3360.96	2026-10-13 17:57:00.859604	381	\N	2026PD00408
775	01110375816	2	2026-04-01	SAO PAULO	CURSO SSP	871.36	2026-10-13 17:57:00.859604	409	\N	2026PD00161
776	01110375816	2	2026-04-05	SAO PAULO	CURSO SSP	3360.96	2026-10-13 17:57:00.859604	409	\N	2026PD00161
827	04307176103	2	2026-09-24	PIRACICABA	CURSO MBA	103.73	2026-10-15 15:41:17.369817	579	\N	2026PD00414
828	04307176103	2	2026-09-26	PIRACICABA	CURSO MBA	103.73	2026-10-15 15:44:46.548372	579	\N	2026PD00414
829	19203432884	2	2026-09-17	PIRACICABA	CURSO MBA	103.73	2026-10-15 15:45:38.180307	580	\N	2026PD00415
831	19216935847	2	2026-09-26	PIRACICABA	CURSO MBA	103.73	2026-10-15 15:47:48.448063	581	\N	2026PD00416
832	42610681844	2	2026-09-17	PIRACICABA	CURSO MBA	80.68	2026-10-15 15:49:17.328371	582	\N	2026PD00417
833	85920356510	2	2026-09-24	PIRACICABA	CURSO MBA	103.73	2026-10-15 15:53:44.745113	583	\N	2026PD00418
522	04307176103	1	2026-04-16	LIMEIRA	SERVICO POLICIAL	103.73	2026-10-13 17:57:00.859604	492	\N	2026PD00169
743	00496426850	2	2026-08-27	SAO PAULO	AGOSTO LILAS	248.96	2026-10-13 17:57:00.859604	377	\N	2026PD00367
777	01110375816	2	2026-04-12	SAO PAULO	CURSO SSP	3360.96	2026-10-13 17:57:00.859604	409	\N	2026PD00161
778	01110375816	2	2026-04-21	SAO PAULO	CURSO SSP	2116.16	2026-10-13 17:57:00.859604	409	\N	2026PD00161
779	01110375816	2	2026-04-26	SAO PAULO	CURSO SSP	3360.96	2026-10-13 17:57:00.859604	409	\N	2026PD00161
780	01110375816	2	2026-05-03	SAO PAULO	CURSO SSP	3360.96	2026-10-13 17:57:00.859604	423	\N	2026PD00218
781	01110375816	2	2026-05-10	SAO PAULO	CURSO SSP	3360.96	2026-10-13 17:57:00.859604	423	\N	2026PD00218
782	01110375816	2	2026-05-17	SAO PAULO	CURSO SSP	3360.96	2026-10-13 17:57:00.859604	423	\N	2026PD00218
783	01110375816	2	2026-05-24	SAO PAULO	CURSO SSP	3360.96	2026-10-13 17:57:00.859604	423	\N	2026PD00218
784	01110375816	2	2026-05-31	SAO PAULO	CURSO SSP	3112.00	2026-10-13 17:57:00.859604	472	\N	2026PD00260
785	01110375816	2	2026-06-07	SAO PAULO	CURSO SSP	3112.00	2026-10-13 17:57:00.859604	472	\N	2026PD00260
786	01110375816	2	2026-06-14	SAO PAULO	CURSO SSP	3112.00	2026-10-13 17:57:00.859604	472	\N	2026PD00260
787	01110375816	2	2026-06-21	SAO PAULO	CURSO SSP	3112.00	2026-10-13 17:57:00.859604	472	\N	2026PD00260
788	01110375816	2	2026-06-28	SAO PAULO	CURSO SSP	3112.00	2026-10-13 17:57:00.859604	516	\N	2026PD00304
789	01110375816	2	2026-07-05	SAO PAULO	CURSO SSP	3112.00	2026-10-13 17:57:00.859604	516	\N	2026PD00304
790	01110375816	2	2026-07-12	SAO PAULO	CURSO SSP	3112.00	2026-10-13 17:57:00.859604	516	\N	2026PD00304
791	01110375816	2	2026-07-19	SAO PAULO	CURSO SSP	3112.00	2026-10-13 17:57:00.859604	516	\N	2026PD00304
792	01110375816	2	2026-07-26	SAO PAULO	CURSO SSP	3112.00	2026-10-13 17:57:00.859604	516	\N	2026PD00304
793	01110375816	2	2026-08-02	SAO PAULO	CURSO SSP	3360.96	2026-10-13 17:57:00.859604	371	\N	2026PD00371
794	01110375816	2	2026-08-09	SAO PAULO	CURSO SSP	3360.96	2026-10-13 17:57:00.859604	371	\N	2026PD00371
795	01110375816	2	2026-08-16	SAO PAULO	CURSO SSP	3360.96	2026-10-13 17:57:00.859604	371	\N	2026PD00371
796	01110375816	2	2026-08-23	SAO PAULO	CURSO SSP	3360.96	2026-10-13 17:57:00.859604	371	\N	2026PD00371
797	01110375816	2	2026-08-30	SAO PAULO	CURSO SSP	3360.96	2026-10-13 17:57:00.859604	381	\N	2026PD00408
799	01110375816	2	2026-09-13	SAO PAULO	CURSO SSP	3360.96	2026-10-13 17:57:00.859604	381	\N	2026PD00408
800	01110375816	2	2026-09-20	SAO PAULO	CURSO SSP	3360.96	2026-10-13 17:57:00.859604	381	\N	2026PD00408
801	01110375816	2	2026-09-27	SAO PAULO	CURSO SSP	3360.96	2026-10-13 17:57:00.859604	381	\N	2026PD00408
565	04704982858	1	2026-06-09	SAO PAULO	SERVICO POLICIAL	248.96	2026-10-13 17:57:00.859604	384	\N	2026/PD00283
560	05484576709	1	2026-02-25	SAO PAULO	SERVICO POLICIAL	248.96	2026-10-13 17:57:00.859604	469	\N	2026PD00129
717	06762410855	2	2026-08-02	SAO PAULO	ENCONTRO UGES	622.40	2026-10-13 17:57:00.859604	538	\N	2026PD00340
650	10410326682	1	2026-02-07	PIRACICABA	PLANTAO POLICIAL LIMEIRA	207.46	2026-10-13 17:57:00.859604	408	\N	2026PD00070
656	10410326682	1	2026-03-03	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	386	\N	2026PD00130
657	10410326682	1	2026-03-05	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	386	\N	2026PD00130
658	10410326682	1	2026-03-09	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	386	\N	2026PD00130
659	10410326682	1	2026-03-11	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	386	\N	2026PD00130
660	10410326682	1	2026-03-14	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	69.15	2026-10-13 17:57:00.859604	386	\N	2026PD00130
661	10410326682	1	2026-03-15	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	386	\N	2026PD00130
662	10410326682	1	2026-03-19	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	386	\N	2026PD00130
663	10410326682	1	2026-03-21	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	386	\N	2026PD00130
664	10410326682	1	2026-03-23	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	386	\N	2026PD00130
665	10410326682	1	2026-03-27	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	386	\N	2026PD00130
666	10410326682	1	2026-03-31	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	386	\N	2026PD00130
667	10410326682	1	2026-04-06	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	422	\N	2026PD00172
668	10410326682	1	2026-04-09	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	422	\N	2026PD00172
738	05484576709	2	2026-03-16	SAO PAULO	CURSO OPERACIONAL PMSP	248.96	2026-10-13 17:57:00.859604	448	\N	2026PD00129
739	05484576709	2	2026-03-17	SAO PAULO	CURSO OPERACIONAL PMSP	248.96	2026-10-13 17:57:00.859604	448	\N	2026PD00129
740	05484576709	2	2026-03-18	SAO PAULO	CURSO OPERACIONAL PMSP	248.96	2026-10-13 17:57:00.859604	448	\N	2026PD00129
741	05484576709	2	2026-03-19	SAO PAULO	CURSO OPERACIONAL PMSP	248.96	2026-10-13 17:57:00.859604	448	\N	2026PD00129
742	05484576709	2	2026-03-20	SAO PAULO	CURSO OPERACIONAL PMSP	248.96	2026-10-13 17:57:00.859604	448	\N	2026PD00129
745	05484576709	2	2026-03-23	SAO PAULO	CURSO OPERACIONAL PMSP	248.96	2026-10-13 17:57:00.859604	448	\N	2026PD00129
750	05484576709	2	2026-03-24	SAO PAULO	CURSO OPERACIONAL PMSP	248.96	2026-10-13 17:57:00.859604	448	\N	2026PD00129
754	05484576709	2	2026-03-25	SAO PAULO	CURSO OPERACIONAL PMSP	248.96	2026-10-13 17:57:00.859604	448	\N	2026PD00129
755	05484576709	2	2026-03-26	SAO PAULO	CURSO OPERACIONAL PMSP	248.96	2026-10-13 17:57:00.859604	448	\N	2026PD00129
756	05484576709	2	2026-03-27	SAO PAULO	CURSO OPERACIONAL PMSP	248.96	2026-10-13 17:57:00.859604	448	\N	2026PD00129
558	06762410855	1	2026-08-06	ITU	SERVICO POLICIAL	103.73	2026-10-13 17:57:00.859604	547	\N	2026PD00341
542	07666429681	1	2026-04-28	PIRACICABA	SERVICO POLICIAL	69.15	2026-10-13 17:57:00.859604	372	\N	2026PD00170
566	08922377674	1	2026-08-10	SAO PAULO	SERVICO POLICIAL	248.96	2026-10-13 17:57:00.859604	560	\N	2026PD00332
669	10410326682	1	2026-04-11	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	422	\N	2026PD00172
670	10410326682	1	2026-04-13	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	422	\N	2026PD00172
671	10410326682	1	2026-04-15	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	422	\N	2026PD00172
672	10410326682	1	2026-04-17	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	422	\N	2026PD00172
673	10410326682	1	2026-04-19	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	422	\N	2026PD00172
674	10410326682	1	2026-04-21	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	422	\N	2026PD00172
675	10410326682	1	2026-04-23	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	422	\N	2026PD00172
676	10410326682	1	2026-04-27	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	422	\N	2026PD00172
677	10410326682	1	2026-04-29	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	422	\N	2026PD00172
678	10410326682	1	2026-05-01	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	391	\N	2026PD00237
679	10410326682	1	2026-05-03	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	69.15	2026-10-13 17:57:00.859604	391	\N	2026PD00237
680	10410326682	1	2026-05-05	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	391	\N	2026PD00237
681	10410326682	1	2026-05-11	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	391	\N	2026PD00237
682	10410326682	1	2026-05-14	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	391	\N	2026PD00237
683	10410326682	1	2026-05-16	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	391	\N	2026PD00237
684	10410326682	1	2026-05-17	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	391	\N	2026PD00237
685	10410326682	1	2026-05-20	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	391	\N	2026PD00237
686	10410326682	1	2026-05-23	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	69.15	2026-10-13 17:57:00.859604	391	\N	2026PD00237
687	10410326682	1	2026-05-24	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	69.15	2026-10-13 17:57:00.859604	391	\N	2026PD00237
688	10410326682	1	2026-05-26	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	391	\N	2026PD00237
446	10531583600	1	2026-01-27	PIRACICABA	PLANTAO POLICIAL LIMEIRA	207.46	2026-10-13 17:57:00.859604	389	\N	2026PD00048
723	10995999899	2	2026-03-27	PIRACICABA	CURSO TIRO	80.68	2026-10-13 17:57:00.859604	460	\N	2026PD00131
694	13934950876	1	2026-05-02	LIMEIRA	ACUMULO DE FUNCAO	161.36	2026-10-13 17:57:00.859604	485	\N	2026PD00239
695	13934950876	1	2026-05-05	LIMEIRA	ACUMULO DE FUNCAO	161.36	2026-10-13 17:57:00.859604	485	\N	2026PD00239
696	13934950876	1	2026-05-08	LIMEIRA	ACUMULO DE FUNCAO	161.36	2026-10-13 17:57:00.859604	485	\N	2026PD00239
697	13934950876	1	2026-05-11	LIMEIRA	ACUMULO DE FUNCAO	161.36	2026-10-13 17:57:00.859604	485	\N	2026PD00239
698	13934950876	1	2026-05-14	LIMEIRA	ACUMULO DE FUNCAO	161.36	2026-10-13 17:57:00.859604	485	\N	2026PD00239
699	13934950876	1	2026-05-17	LIMEIRA	ACUMULO DE FUNCAO	161.36	2026-10-13 17:57:00.859604	485	\N	2026PD00239
400	13934950876	1	2026-05-21	LIMEIRA	ACUMULO DE FUNCAO	161.36	2026-10-13 17:57:00.859604	485	\N	2026PD00239
401	13934950876	1	2026-05-24	LIMEIRA	ACUMULO DE FUNCAO	161.36	2026-10-13 17:57:00.859604	485	\N	2026PD00239
402	13934950876	1	2026-05-28	LIMEIRA	ACUMULO DE FUNCAO	161.36	2026-10-13 17:57:00.859604	485	\N	2026PD00239
403	13934950876	1	2026-05-31	LIMEIRA	ACUMULO DE FUNCAO	161.36	2026-10-13 17:57:00.859604	485	\N	2026PD00247
404	13934950876	1	2026-06-04	LIMEIRA	ACUMULO DE FUNCAO	161.36	2026-10-13 17:57:00.859604	495	\N	2026PD00307
405	13934950876	1	2026-06-09	LIMEIRA	ACUMULO DE FUNCAO	161.36	2026-10-13 17:57:00.859604	488	\N	2026PD00307
406	13934950876	1	2026-06-14	LIMEIRA	ACUMULO DE FUNCAO	161.36	2026-10-13 17:57:00.859604	370	\N	2026PD00307
395	13934950876	1	2026-06-19	LIMEIRA	ACUMULO DE FUNCAO	161.36	2026-10-13 17:57:00.859604	480	\N	2026PD00307
407	13934950876	1	2026-06-21	LIMEIRA	ACUMULO DE FUNCAO	161.36	2026-10-13 17:57:00.859604	400	\N	2026PD00307
408	13934950876	1	2026-06-24	LIMEIRA	ACUMULO DE FUNCAO	161.36	2026-10-13 17:57:00.859604	470	\N	2026PD00307
409	13934950876	1	2026-06-27	LIMEIRA	ACUMULO DE FUNCAO	161.36	2026-10-13 17:57:00.859604	438	\N	2026PD00307
410	13934950876	1	2026-06-29	LIMEIRA	ACUMULO DE FUNCAO	161.36	2026-10-13 17:57:00.859604	435	\N	2026PD00307
716	12328788807	2	2026-07-16	SAO PAULO	TREINAMENTO	193.63	2026-10-13 17:57:00.859604	459	\N	2026PD00136
725	12375581660	2	2026-03-27	RIO CLARO	CURSO TIRO	69.15	2026-10-13 17:57:00.859604	430	\N	2026PD00184
596	10995999899	1	2026-07-05	LIMEIRA	ACUMULO DE FUNCAO	107.57	2026-10-13 17:57:00.859604	415	\N	2026PD00306
597	10995999899	1	2026-07-08	LIMEIRA	ACUMULO DE FUNCAO	107.57	2026-10-13 17:57:00.859604	405	\N	2026PD00306
598	10995999899	1	2026-07-11	LIMEIRA	ACUMULO DE FUNCAO	107.57	2026-10-13 17:57:00.859604	533	\N	2026PD00306
599	10995999899	1	2026-07-14	LIMEIRA	ACUMULO DE FUNCAO	107.57	2026-10-13 17:57:00.859604	458	\N	2026PD00306
744	15721307846	2	2026-07-16	SAO PAULO	TREINAMENTO	248.96	2026-10-13 17:57:00.859604	522	\N	2026PD00317
628	18208623806	1	2026-01-11	LIMEIRA	PLANTAO POLICIAL LIMEIRA	207.46	2026-10-13 17:57:00.859604	429	\N	2026PD00049
708	18208623806	2	2026-01-29	SAO PAULO	CURSO ACADEPOL APH	871.36	2026-10-13 17:57:00.859604	462	\N	2026PD00059
713	18208623806	2	2026-04-30	SALTINHO	CURSO ENTRADAS TATICAS	138.31	2026-10-13 17:57:00.859604	546	\N	2026PD00162
630	18208623806	1	2026-07-13	LIMEIRA	PLANTAO POLICIAL LIMEIRA	207.46	2026-10-13 17:57:00.859604	468	\N	2026PD00308
631	18208623806	1	2026-08-29	LIMEIRA	PLANTAO POLICIAL LIMEIRA	103.73	2026-10-13 17:57:00.859604	419	\N	2026PD00402
434	19163513870	1	2026-01-01	PIRACICABA	PLANTAO POLICIAL LIMEIRA	207.46	2026-10-13 17:57:00.859604	418	\N	2026PD00050
559	22444646878	1	2026-02-19	PIRACICABA	PLANTAO POLICIAL LIMEIRA	207.46	2026-10-13 17:57:00.859604	449	\N	2026PD00073
435	24999284847	1	2026-01-19	PIRACICABA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	478	\N	2026PD00051
436	24999284847	1	2026-05-14	LIMEIRA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	398	\N	2026PD00240
437	24999284847	1	2026-06-15	LIMEIRA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	552	\N	2026PD00286
438	24999284847	1	2026-07-18	LIMEIRA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	535	\N	2026PD00309
439	24999284847	1	2026-07-24	LIMEIRA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	395	\N	2026PD00309
440	24999284847	1	2026-08-08	LIMEIRA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	517	\N	2026PD00342
511	27057183895	1	2026-01-10	LIMEIRA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	549	\N	2026PD00052
512	27057183895	1	2026-02-21	LIMEIRA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	475	\N	2026PD00083
513	27057183895	1	2026-05-17	LIMEIRA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	452	\N	2026PD00241
419	13934950876	1	2026-07-20	LIMEIRA	ACUMULO DE FUNCAO	161.36	2026-10-13 17:57:00.859604	494	\N	2026PD00335
625	14694180703	1	2026-06-09	SAO PAULO	SERVICO POLICIAL	248.96	2026-10-13 17:57:00.859604	519	\N	2026PD00284
420	13934950876	1	2026-07-23	LIMEIRA	ACUMULO DE FUNCAO	161.36	2026-10-13 17:57:00.859604	494	\N	2026PD00335
626	14694180703	1	2026-08-05	BARUERI	SERVICO POLICIAL	103.73	2026-10-13 17:57:00.859604	436	\N	2026PD00402
520	16791203870	1	2026-08-05	BARUERI	SERVICO POLICIAL	103.73	2026-10-13 17:57:00.859604	378	\N	2026PD00336
629	18208623806	1	2026-03-06	JAGUARIUNA	SERVICO POLICIAL	69.15	2026-10-13 17:57:00.859604	555	\N	2026PD00116
640	19216935847	1	2026-03-11	RIO CLARO	SERVICO POLICIAL	69.15	2026-10-13 17:57:00.859604	421	\N	\N
421	13934950876	1	2026-07-25	LIMEIRA	ACUMULO DE FUNCAO	161.36	2026-10-13 17:57:00.859604	494	\N	2026PD00335
422	13934950876	1	2026-07-27	LIMEIRA	ACUMULO DE FUNCAO	161.36	2026-10-13 17:57:00.859604	494	\N	2026PD00335
423	13934950876	1	2026-07-30	LIMEIRA	ACUMULO DE FUNCAO	161.36	2026-10-13 17:57:00.859604	494	\N	2026PD00335
424	13934950876	1	2026-08-02	LIMEIRA	ACUMULO DE FUNCAO	161.36	2026-10-13 17:57:00.859604	454	\N	2026PD00402
425	13934950876	1	2026-08-06	LIMEIRA	ACUMULO DE FUNCAO	161.36	2026-10-13 17:57:00.859604	454	\N	2026PD00402
426	13934950876	1	2026-08-09	LIMEIRA	ACUMULO DE FUNCAO	161.36	2026-10-13 17:57:00.859604	454	\N	2026PD00402
427	13934950876	1	2026-08-12	LIMEIRA	ACUMULO DE FUNCAO	161.36	2026-10-13 17:57:00.859604	454	\N	2026PD00402
428	13934950876	1	2026-08-15	LIMEIRA	ACUMULO DE FUNCAO	161.36	2026-10-13 17:57:00.859604	454	\N	2026PD00402
429	13934950876	1	2026-08-18	LIMEIRA	ACUMULO DE FUNCAO	161.36	2026-10-13 17:57:00.859604	454	\N	2026PD00402
430	13934950876	1	2026-08-22	LIMEIRA	ACUMULO DE FUNCAO	161.36	2026-10-13 17:57:00.859604	454	\N	2026PD00402
431	13934950876	1	2026-08-24	LIMEIRA	ACUMULO DE FUNCAO	161.36	2026-10-13 17:57:00.859604	454	\N	2026PD00402
432	13934950876	1	2026-08-28	LIMEIRA	ACUMULO DE FUNCAO	161.36	2026-10-13 17:57:00.859604	454	\N	2026PD00402
433	13934950876	1	2026-08-30	LIMEIRA	ACUMULO DE FUNCAO	161.36	2026-10-13 17:57:00.859604	454	\N	2026PD00402
514	27057183895	1	2026-06-07	LIMEIRA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	368	\N	2026PD00288
515	27057183895	1	2026-06-21	LIMEIRA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	526	\N	2026PD00288
617	27206162819	1	2026-01-18	LIMEIRA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	486	\N	2026PD00053
618	27206162819	1	2026-03-22	LIMEIRA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	425	\N	2026PD00120
619	27206162819	1	2026-04-12	LIMEIRA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	447	\N	2026PD00176
620	27206162819	1	2026-05-04	LIMEIRA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	500	\N	2026PD00242
622	27206162819	1	2026-06-20	LIMEIRA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	531	\N	2026PD00289
623	27206162819	1	2026-07-09	LIMEIRA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	376	\N	2026PD00310
624	27206162819	1	2026-08-09	LIMEIRA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	388	\N	\N
751	30310116864	2	2026-02-25	SAO PAULO	CURSO ACADEPOL ACADEPOL	248.96	2026-10-13 17:57:00.859604	476	\N	2026PD00085
752	30310116864	2	2026-02-26	SAO PAULO	CURSO ACADEPOL ACADEPOL	248.96	2026-10-13 17:57:00.859604	476	\N	2026PD00085
753	30310116864	2	2026-02-27	SAO PAULO	CURSO ACADEPOL ACADEPOL	248.96	2026-10-13 17:57:00.859604	476	\N	2026PD00085
526	32540502822	1	2026-01-07	PIRACICABA	PLANTAO POLICIAL LIMEIRA	207.46	2026-10-13 17:57:00.859604	437	\N	2026PD00054
527	32540502822	1	2026-02-14	LIMEIRA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	402	\N	2026PD00076
735	32540502822	2	2026-03-05	SAO PAULO	CURSO APH	995.84	2026-10-13 17:57:00.859604	402	\N	2026PD00132
529	32540502822	1	2026-05-12	LIMEIRA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	521	\N	2026PD00244
530	32540502822	1	2026-06-08	LIMEIRA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	383	\N	206PD00290
531	32540502822	1	2026-07-20	LIMEIRA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	529	\N	2026PD00311
532	32540502822	1	2026-08-26	LIMEIRA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	414	\N	2026PD00402
772	32628691809	2	2026-04-14	PIRACICABA	CURSO ACADEPOL	69.15	2026-10-13 17:57:00.859604	413	\N	2026PD00164
773	32628691809	2	2026-05-04	PIRACICABA	CURSO ACADEPOL	69.15	2026-10-13 17:57:00.859604	561	\N	2026PD00221
774	32628691809	2	2026-05-05	PIRACICABA	CURSO ACADEPOL	69.15	2026-10-13 17:57:00.859604	550	\N	2026PD00221
803	32628691809	2	2026-05-06	PIRACICABA	CURSO ACADEPOL	69.15	2026-10-13 17:57:00.859604	428	\N	2026PD00221
769	32968804880	2	2026-08-27	SAO PAULO	AGOSTO LILAS	248.96	2026-10-13 17:57:00.859604	553	\N	2026PD00368
702	33648957830	2	2026-05-04	PIRACICABA	CURSO ACADEPOL	69.15	2026-10-13 17:57:00.859604	520	\N	2026PD00222
707	33648957830	2	2026-05-05	PIRACICABA	CURSO ACADEPOL	69.15	2026-10-13 17:57:00.859604	520	\N	2026PD00222
710	33648957830	2	2026-05-06	PIRACICABA	CURSO ACADEPOL	69.15	2026-10-13 17:57:00.859604	520	\N	2026PD00222
758	33648957830	2	2026-06-25	PIRACICABA	CURSO ACADEPOL	69.15	2026-10-13 17:57:00.859604	493	\N	2026PD00261
770	33648957830	2	2026-06-26	PIRACICABA	CURSO ACADEPOL	69.15	2026-10-13 17:57:00.859604	493	\N	2026PD00261
621	27206162819	1	2026-06-09	GUARULHOS	SERVICO POLICIAL	207.46	2026-10-13 17:57:00.859604	380	\N	2026PD00289
690	27935713855	1	2026-05-12	SAO PAULO	SERVICO POLICIAL	124.48	2026-10-13 17:57:00.859604	483	\N	2026PD00243
691	27935713855	1	2026-05-20	SAO PAULO	SERVICO POLICIAL	124.48	2026-10-13 17:57:00.859604	396	\N	2026PD00243
692	27935713855	1	2026-06-09	SAO PAULO	SERVICO POLICIAL	248.96	2026-10-13 17:57:00.859604	508	\N	2026PD00243
693	29474854831	1	2026-08-05	BARUERI	SERVICO POLICIAL	80.68	2026-10-13 17:57:00.859604	455	\N	\N
536	30310116864	1	2026-02-20	SAO PAULO	SERVICO POLICIAL	248.96	2026-10-13 17:57:00.859604	451	\N	2026PD00074
746	31892853817	2	2026-04-17	PIRACICABA	CURSO ACADEPOL TAT I	103.73	2026-10-13 17:57:00.859604	432	\N	2026PD00163
747	31892853817	2	2026-04-19	CHARQUEADA	CURSO ACADEPOL TAT I	138.31	2026-10-13 17:57:00.859604	432	\N	2026PD00163
748	31892853817	2	2026-04-23	CHARQUEADA	CURSO ACADEPOL TAT I	69.15	2026-10-13 17:57:00.859604	432	\N	2026PD00163
749	31892853817	2	2026-04-26	PIRACICABA	CURSO ACADEPOL TAT I	103.73	2026-10-13 17:57:00.859604	382	\N	2026PD00163
730	35313574841	2	2026-06-25	PIRACICABA	CURSO ACADEPOL	69.15	2026-10-13 17:57:00.859604	445	\N	2026PD00262
731	35313574841	2	2026-06-26	PIRACICABA	CURSO ACADEPOL	69.15	2026-10-13 17:57:00.859604	445	\N	2026PD00262
771	35932472839	2	2026-03-27	PIRACICABA	CURSO TIRO	69.15	2026-10-13 17:57:00.859604	511	\N	2026PD00133
547	36025331820	1	2026-02-07	PIRACICABA	PLANTAO POLICIAL LIMEIRA	207.46	2026-10-13 17:57:00.859604	477	\N	2026PD00078
722	36819640846	2	2026-08-27	SAO PAULO	AGOSTO LILAS	248.96	2026-10-13 17:57:00.859604	515	\N	2026PD00369
549	39460172822	1	2026-01-27	PIRACICABA	PLANTAO POLICIAL LIMEIRA	207.46	2026-10-13 17:57:00.859604	544	\N	2026PD00056
551	39460172822	1	2026-02-22	LIMEIRA	PLANTAO POLICIAL LIMEIRA	207.46	2026-10-13 17:57:00.859604	394	\N	2026PD00080
554	39460172822	1	2026-06-12	LIMEIRA	PLANTAO POLICIAL LIMEIRA	207.46	2026-10-13 17:57:00.859604	497	\N	2026PD00292
555	39460172822	1	2026-06-25	LIMEIRA	PLANTAO POLICIAL LIMEIRA	207.46	2026-10-13 17:57:00.859604	401	\N	2026PD00292
712	39460172822	2	2026-06-25	SAO PAULO	SEMINARIO	248.96	2026-10-13 17:57:00.859604	401	\N	2026PD00292
556	39460172822	1	2026-07-03	LIMEIRA	PLANTAO POLICIAL LIMEIRA	207.46	2026-10-13 17:57:00.859604	540	\N	2026PD00313
557	39460172822	1	2026-08-22	LIMEIRA	PLANTAO POLICIAL LIMEIRA	207.46	2026-10-13 17:57:00.859604	426	\N	2026PD00402
759	40381911845	2	2026-03-16	SAO PAULO	CURSO OPERACIONAL PMSP	248.96	2026-10-13 17:57:00.859604	509	\N	2026PD00134
760	40381911845	2	2026-03-17	SAO PAULO	CURSO OPERACIONAL PMSP	248.96	2026-10-13 17:57:00.859604	509	\N	2026PD00134
761	40381911845	2	2026-03-18	SAO PAULO	CURSO OPERACIONAL PMSP	248.96	2026-10-13 17:57:00.859604	509	\N	2026PD00134
762	40381911845	2	2026-03-19	SAO PAULO	CURSO OPERACIONAL PMSP	248.96	2026-10-13 17:57:00.859604	509	\N	2026PD00134
763	40381911845	2	2026-03-20	SAO PAULO	CURSO OPERACIONAL PMSP	248.96	2026-10-13 17:57:00.859604	509	\N	2026PD00134
764	40381911845	2	2026-03-23	SAO PAULO	CURSO OPERACIONAL PMSP	248.96	2026-10-13 17:57:00.859604	509	\N	2026PD00134
765	40381911845	2	2026-03-24	SAO PAULO	CURSO OPERACIONAL PMSP	248.96	2026-10-13 17:57:00.859604	509	\N	2026PD00134
766	40381911845	2	2026-03-25	SAO PAULO	CURSO OPERACIONAL PMSP	248.96	2026-10-13 17:57:00.859604	509	\N	2026PD00134
767	40381911845	2	2026-03-26	SAO PAULO	CURSO OPERACIONAL PMSP	248.96	2026-10-13 17:57:00.859604	509	\N	2026PD00134
768	40381911845	2	2026-03-27	SAO PAULO	CURSO OPERACIONAL PMSP	248.96	2026-10-13 17:57:00.859604	509	\N	2026PD00134
396	42582609838	1	2026-01-01	PIRACICABA	PLANTAO POLICIAL LIMEIRA	207.46	2026-10-13 17:57:00.859604	375	\N	2026PD00057
397	42582609838	1	2026-02-08	LIMEIRA	PLANTAO POLICIAL LIMEIRA	69.15	2026-10-13 17:57:00.859604	514	\N	2026PD00083
398	42582609838	1	2026-02-12	LIMEIRA	PLANTAO POLICIAL LIMEIRA	207.46	2026-10-13 17:57:00.859604	503	\N	2026PD00083
399	42582609838	1	2026-03-07	LIMEIRA	PLANTAO POLICIAL LIMEIRA	69.15	2026-10-13 17:57:00.859604	416	\N	2026PD00128
700	42582609838	2	2026-03-16	SAO PAULO	SEMINARIO FEMINICIDIO	248.96	2026-10-13 17:57:00.859604	464	\N	2026PD00135
701	42582609838	2	2026-03-26	RIO CLARO	CURSO TIRO	69.15	2026-10-13 17:57:00.859604	490	\N	2026PD00135
504	42582609838	1	2026-03-29	LIMEIRA	PLANTAO POLICIAL LIMEIRA	69.15	2026-10-13 17:57:00.859604	441	\N	2026PD00128
505	42582609838	1	2026-04-21	LIMEIRA	PLANTAO POLICIAL LIMEIRA	69.15	2026-10-13 17:57:00.859604	537	\N	2026PD00166
826	35500297805	2	2026-04-19	CHARQUEADA	CURSO ACADEPOL TAT I	69.15	2026-10-14 16:11:58.837708	374	\N	2026PD00165
548	36025331820	1	2026-03-16	SAO PAULO	SERVICO POLICIAL	248.96	2026-10-13 17:57:00.859604	524	\N	2026PD00124
634	36750397816	1	2026-02-04	CAPIVARI	SERVICO POLICIAL	138.31	2026-10-13 17:57:00.859604	513	\N	2026PD00079
705	35500297805	2	2026-04-23	CHARQUEADA	CURSO ACADEPOL TAT I	69.15	2026-10-13 17:57:00.859604	374	\N	2026PD00165
706	35500297805	2	2026-04-26	CHARQUEADA	CURSO ACADEPOL TAT I	69.15	2026-10-13 17:57:00.859604	374	\N	2026PD00165
704	42582609838	2	2026-04-23	SAO PAULO	PALESTRA ACADEPOL	124.48	2026-10-13 17:57:00.859604	433	\N	2026PD00166
506	42582609838	1	2026-05-09	LIMEIRA	PLANTAO POLICIAL LIMEIRA	69.15	2026-10-13 17:57:00.859604	369	\N	2026PD00245
507	42582609838	1	2026-06-29	LIMEIRA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	397	\N	2026PD00128
508	42582609838	1	2026-07-11	LIMEIRA	PLANTAO POLICIAL LIMEIRA	69.15	2026-10-13 17:57:00.859604	563	\N	2026PD00314
509	42582609838	1	2026-07-28	LIMEIRA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	379	\N	2026PD00337
709	42582609838	2	2026-08-27	LIMEIRA	AGOSTO LILAS	248.96	2026-10-13 17:57:00.859604	431	\N	2026PD00370
510	42582609838	1	2026-08-28	LIMEIRA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	407	\N	2026PD00402
711	42582609838	2	2026-09-02	LIMEIRA	VIOLENCIA DE GENERO	248.96	2026-10-13 17:57:00.859604	456	\N	2026PD00370
757	42610681844	2	2026-03-26	RIO CLARO	CURSO TIRO	107.57	2026-10-13 17:57:00.859604	471	\N	2026PD00167
525	43992425827	1	2026-01-07	PIRACICABA	PLANTAO POLICIAL LIMEIRA	207.46	2026-10-13 17:57:00.859604	463	\N	2026PD00058
469	44519520851	1	2026-07-14	LIMEIRA	ACUMULO DE FUNCAO	69.15	2026-10-13 17:57:00.859604	496	\N	2026PD00338
470	44519520851	1	2026-07-15	LIMEIRA	ACUMULO DE FUNCAO	69.15	2026-10-13 17:57:00.859604	496	\N	2026PD00338
471	44519520851	1	2026-07-16	LIMEIRA	ACUMULO DE FUNCAO	69.15	2026-10-13 17:57:00.859604	496	\N	2026PD00338
472	44519520851	1	2026-07-17	LIMEIRA	ACUMULO DE FUNCAO	69.15	2026-10-13 17:57:00.859604	496	\N	2026PD00338
473	44519520851	1	2026-07-20	LIMEIRA	ACUMULO DE FUNCAO	69.15	2026-10-13 17:57:00.859604	496	\N	2026PD00338
474	44519520851	1	2026-07-21	LIMEIRA	ACUMULO DE FUNCAO	69.15	2026-10-13 17:57:00.859604	496	\N	2026PD00338
475	44519520851	1	2026-07-22	LIMEIRA	ACUMULO DE FUNCAO	69.15	2026-10-13 17:57:00.859604	496	\N	2026PD00338
476	44519520851	1	2026-07-23	LIMEIRA	ACUMULO DE FUNCAO	69.15	2026-10-13 17:57:00.859604	496	\N	2026PD00338
477	44519520851	1	2026-07-24	LIMEIRA	ACUMULO DE FUNCAO	69.15	2026-10-13 17:57:00.859604	496	\N	2026PD00338
478	44519520851	1	2026-07-27	LIMEIRA	ACUMULO DE FUNCAO	69.15	2026-10-13 17:57:00.859604	496	\N	2026PD00338
479	44519520851	1	2026-07-28	LIMEIRA	ACUMULO DE FUNCAO	69.15	2026-10-13 17:57:00.859604	496	\N	2026PD00338
480	44519520851	1	2026-07-29	LIMEIRA	ACUMULO DE FUNCAO	69.15	2026-10-13 17:57:00.859604	496	\N	2026PD00338
481	44519520851	1	2026-07-30	LIMEIRA	ACUMULO DE FUNCAO	69.15	2026-10-13 17:57:00.859604	496	\N	2026PD00338
482	44519520851	1	2026-07-31	LIMEIRA	ACUMULO DE FUNCAO	69.15	2026-10-13 17:57:00.859604	496	\N	2026PD00338
483	44519520851	1	2026-08-03	LIMEIRA	ACUMULO DE FUNCAO	69.15	2026-10-13 17:57:00.859604	465	\N	2026PD00402
484	44519520851	1	2026-08-04	LIMEIRA	ACUMULO DE FUNCAO	69.15	2026-10-13 17:57:00.859604	465	\N	2026PD00402
485	44519520851	1	2026-08-05	LIMEIRA	ACUMULO DE FUNCAO	69.15	2026-10-13 17:57:00.859604	465	\N	2026PD00402
486	44519520851	1	2026-08-06	LIMEIRA	ACUMULO DE FUNCAO	69.15	2026-10-13 17:57:00.859604	465	\N	2026PD00402
487	44519520851	1	2026-08-07	LIMEIRA	ACUMULO DE FUNCAO	69.15	2026-10-13 17:57:00.859604	465	\N	2026PD00402
488	44519520851	1	2026-08-10	LIMEIRA	ACUMULO DE FUNCAO	69.15	2026-10-13 17:57:00.859604	465	\N	2026PD00402
718	46508753827	2	2026-05-04	PIRACICABA	CURSO ACADEPOL	69.15	2026-10-13 17:57:00.859604	541	\N	2026PD00223
719	46508753827	2	2026-05-05	PIRACICABA	CURSO ACADEPOL	69.15	2026-10-13 17:57:00.859604	489	\N	2026PD00223
720	46508753827	2	2026-05-06	PIRACICABA	CURSO ACADEPOL	69.15	2026-10-13 17:57:00.859604	491	\N	2026PD00223
802	82897123915	2	2026-04-23	SALTINHO	CURSO ACADEPOL	138.31	2026-10-13 17:57:00.859604	556	\N	2026PD00168
516	46508753827	1	2026-04-09	SAO PAULO	SERVICO POLICIAL	248.96	2026-10-13 17:57:00.859604	502	\N	2026PD00183
564	47033640854	1	2026-06-19	RIO DE JANEIRO	SERVICO POLICIAL	822.94	2026-10-13 17:57:00.859604	558	\N	2026PD00295
537	80184782104	1	2026-08-05	BARUERI	SERVICO POLICIAL	103.73	2026-10-13 17:57:00.859604	534	\N	2026PD00343
489	44519520851	1	2026-08-11	LIMEIRA	ACUMULO DE FUNCAO	69.15	2026-10-13 17:57:00.859604	465	\N	2026PD00402
490	44519520851	1	2026-08-12	LIMEIRA	ACUMULO DE FUNCAO	69.15	2026-10-13 17:57:00.859604	465	\N	2026PD00402
491	44519520851	1	2026-08-13	LIMEIRA	ACUMULO DE FUNCAO	69.15	2026-10-13 17:57:00.859604	465	\N	2026PD00402
492	44519520851	1	2026-08-14	LIMEIRA	ACUMULO DE FUNCAO	69.15	2026-10-13 17:57:00.859604	465	\N	2026PD00402
493	44519520851	1	2026-08-17	LIMEIRA	ACUMULO DE FUNCAO	69.15	2026-10-13 17:57:00.859604	465	\N	2026PD00402
494	44519520851	1	2026-08-18	LIMEIRA	ACUMULO DE FUNCAO	69.15	2026-10-13 17:57:00.859604	465	\N	2026PD00402
495	44519520851	1	2026-08-19	LIMEIRA	ACUMULO DE FUNCAO	69.15	2026-10-13 17:57:00.859604	465	\N	2026PD00402
496	44519520851	1	2026-08-20	LIMEIRA	ACUMULO DE FUNCAO	69.15	2026-10-13 17:57:00.859604	465	\N	2026PD00402
497	44519520851	1	2026-08-21	LIMEIRA	ACUMULO DE FUNCAO	69.15	2026-10-13 17:57:00.859604	465	\N	2026PD00402
498	44519520851	1	2026-08-24	LIMEIRA	ACUMULO DE FUNCAO	69.15	2026-10-13 17:57:00.859604	465	\N	2026PD00402
499	44519520851	1	2026-08-25	LIMEIRA	ACUMULO DE FUNCAO	69.15	2026-10-13 17:57:00.859604	465	\N	2026PD00402
500	44519520851	1	2026-08-26	LIMEIRA	ACUMULO DE FUNCAO	69.15	2026-10-13 17:57:00.859604	465	\N	2026PD00402
501	44519520851	1	2026-08-27	LIMEIRA	ACUMULO DE FUNCAO	69.15	2026-10-13 17:57:00.859604	465	\N	2026PD00402
502	44519520851	1	2026-08-28	LIMEIRA	ACUMULO DE FUNCAO	69.15	2026-10-13 17:57:00.859604	465	\N	2026PD00402
503	44519520851	1	2026-08-31	LIMEIRA	ACUMULO DE FUNCAO	69.15	2026-10-13 17:57:00.859604	465	\N	2026PD00402
\.


--
-- Data for Name: diarias_bkp_limpeza_duplicadas; Type: TABLE DATA; Schema: backup; Owner: postgres
--

COPY backup.diarias_bkp_limpeza_duplicadas (id_diaria, cpf_servidor, id_tipo, data_inicial, destino, motivo, valor_diaria, data_cadastro, id_processo, observacao, numero_pd) FROM stdin;
850	18208623806	2	2026-05-25	SAO PAULO	PALESTRA SISTEMA DE JUSTICA	248.96	2026-10-21 09:58:26.750297	450	\N	2026PD00220
834	85920356510	2	2026-09-26	PIRACICABA	CURSO MBA	103.73	2026-10-15 15:54:20.108825	583	\N	2026PD00418
835	10995999899	1	2026-09-01	LIMEIRA	ACUMULO DE FUNCAO	107.57	2026-10-15 15:55:55.417902	584	\N	2026PD00419
836	10995999899	1	2026-09-04	LIMEIRA	ACUMULO DE FUNCAO	107.57	2026-10-15 15:56:01.455005	584	\N	2026PD00419
837	10995999899	1	2026-09-07	LIMEIRA	ACUMULO DE FUNCAO	107.57	2026-10-15 15:56:06.780392	584	\N	2026PD00419
838	10995999899	1	2026-09-10	LIMEIRA	ACUMULO DE FUNCAO	107.57	2026-10-15 15:56:12.032533	584	\N	2026PD00419
839	10995999899	1	2026-09-13	LIMEIRA	ACUMULO DE FUNCAO	107.57	2026-10-15 15:56:20.680416	584	\N	2026PD00419
840	10995999899	1	2026-09-14	LIMEIRA	ACUMULO DE FUNCAO	107.57	2026-10-15 15:56:26.064817	584	\N	2026PD00419
841	10995999899	1	2026-09-16	LIMEIRA	ACUMULO DE FUNCAO	107.57	2026-10-15 15:56:32.12167	584	\N	2026PD00419
842	10995999899	1	2026-09-22	LIMEIRA	ACUMULO DE FUNCAO	107.57	2026-10-15 15:56:38.802749	584	\N	2026PD00419
843	10995999899	1	2026-09-25	LIMEIRA	ACUMULO DE FUNCAO	107.57	2026-10-15 15:56:43.449109	584	\N	2026PD00419
844	10995999899	1	2026-09-28	LIMEIRA	ACUMULO DE FUNCAO	107.57	2026-10-15 15:56:49.346365	584	\N	2026PD00419
845	09085540950	1	2026-09-25	SAO PAULO	SERVIÇO POLICIAL	124.48	2026-10-15 15:58:54.507043	585	\N	2026PD00420
847	13934950876	1	2026-09-26	LIMEIRA	ACUMULO DE FUNCAO	161.36	2026-10-15 16:01:12.186859	586	\N	2026PD00421
848	13934950876	1	2026-09-27	LIMEIRA	ACUMULO DE FUNCAO	161.36	2026-10-15 16:01:20.301849	586	\N	2026PD00421
849	13934950876	1	2026-09-28	LIMEIRA	ACUMULO DE FUNCAO	161.36	2026-10-15 16:01:27.748525	586	\N	2026PD00421
813	07902044792	1	2026-04-09	SAO PAULO	SERVICO POLICIAL	124.48	2026-10-14 15:20:48.32486	562	\N	2026PD00171
642	07902044792	1	2026-04-09	SAO PAULO	SERVIÇO POLICIAL	124.48	2026-10-13 17:57:00.859604	562	\N	2026PD00171
814	09595897833	1	2026-02-12	CAPIVARI	SERVICO POLICIAL	69.15	2026-10-14 15:23:19.777539	412	\N	2026PD00069
643	09595897833	1	2026-02-12	CAPIVARI	SERVIÇO POLICIAL	69.15	2026-10-13 17:57:00.859604	412	\N	2026PD00069
649	10410326682	1	2026-01-07	PIRACICABA	PLANTAO POLICIAL LIMEIRA	207.46	2026-10-13 17:57:00.859604	446	\N	2026PD00047
651	10410326682	1	2026-02-14	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	444	\N	2026PD00114
821	10410326682	1	2026-02-14	PIRASSUNUNGA	SERVICO POLICIAL	138.31	2026-10-14 15:47:02.602612	444	\N	2026PD00114
652	10410326682	1	2026-02-15	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	444	\N	2026PD00114
822	10410326682	1	2026-02-15	PIRASSUNUNGA	SERVICO POLICIAL	138.31	2026-10-14 15:47:17.322943	444	\N	2026PD00114
653	10410326682	1	2026-02-22	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	69.15	2026-10-13 17:57:00.859604	444	\N	2026PD00114
825	10410326682	1	2026-02-22	PIRASSUNUNGA	SERVICO POLICIAL	69.15	2026-10-14 15:47:48.416271	444	\N	2026PD00114
654	10410326682	1	2026-02-23	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	444	\N	2026PD00114
823	10410326682	1	2026-02-23	PIRASSUNUNGA	SERVICO POLICIAL	138.31	2026-10-14 15:47:26.244429	444	\N	2026PD00114
655	10410326682	1	2026-02-27	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	444	\N	2026PD00114
824	10410326682	1	2026-02-27	PIRASSUNUNGA	SERVICO POLICIAL	138.31	2026-10-14 15:47:32.122151	444	\N	2026PD00114
646	32968804880	1	2026-01-27	PIRACICABA	PLANTAO POLICIAL LIMEIRA	207.46	2026-10-13 17:57:00.859604	543	\N	2026PD00055
817	32968804880	1	2026-01-27	PIRACICABA	SERVICO POLICIAL	207.46	2026-10-14 15:33:21.063693	543	\N	2026PD00055
818	32968804880	1	2026-02-17	LIMEIRA	SERVICO POLICIAL	103.73	2026-10-14 15:36:06.032777	387	\N	2026PD00077
647	32968804880	1	2026-02-17	LIMEIRA	SERVIÇO POLICIAL	103.73	2026-10-13 17:57:00.859604	387	\N	2026PD00077
819	32968804880	1	2026-03-06	JAGARIUNA	SERVICO POLICIAL	69.15	2026-10-14 15:38:52.861027	512	\N	2026PD00123
648	32968804880	1	2026-03-06	JAGUARIUNA	SERVIÇO POLICIAL	69.15	2026-10-13 17:57:00.859604	512	\N	2026PD00123
645	35500297805	1	2026-06-19	RIO DE JANEIRO	SERVIÇO POLICIAL	822.94	2026-10-13 17:57:00.859604	399	\N	2026PD00291
521	04307176103	1	2026-02-10	SAO PAULO	SERVIÇO POLICIAL	248.96	2026-10-13 17:57:00.859604	505	\N	2026PD00068
627	09085540950	1	2026-08-05	CASA BRANCA	SERVIÇO POLICIAL	207.46	2026-10-13 17:57:00.859604	466	\N	2026PD00344
810	05484576709	1	2026-02-26	POCOS DE CALDAS	SERVICO POLICIAL	207.46	2026-10-14 14:52:38.767455	566	\N	2026PD00113
638	36750397816	1	2026-07-16	MOCOCA	SERVICO POLICIAL	69.15	2026-10-13 17:57:00.859604	530	\N	2026PD00315
815	26451064807	1	2026-06-19	RIO DE JANEIRO	SERVICO POLICIAL	822.94	2026-10-14 15:27:31.549516	487	\N	2026PD00287
820	10410326682	1	2026-02-25	PIRACICABA	SERVICO POLICIAL	207.46	2026-10-14 15:42:04.872453	446	\N	2026PD00047
808	19216935847	2	2026-09-30	SAO PAULO	CURSO COP	726.13	2026-10-14 10:40:15.851882	565	\N	\N
798	01110375816	2	2023-09-06	SAO PAULO	CURSO SSP	3360.96	2026-10-13 17:57:00.859604	381	\N	2026PD00408
775	01110375816	2	2026-04-01	SAO PAULO	CURSO SSP	871.36	2026-10-13 17:57:00.859604	409	\N	2026PD00161
776	01110375816	2	2026-04-05	SAO PAULO	CURSO SSP	3360.96	2026-10-13 17:57:00.859604	409	\N	2026PD00161
827	04307176103	2	2026-09-24	PIRACICABA	CURSO MBA	103.73	2026-10-15 15:41:17.369817	579	\N	2026PD00414
828	04307176103	2	2026-09-26	PIRACICABA	CURSO MBA	103.73	2026-10-15 15:44:46.548372	579	\N	2026PD00414
829	19203432884	2	2026-09-17	PIRACICABA	CURSO MBA	103.73	2026-10-15 15:45:38.180307	580	\N	2026PD00415
831	19216935847	2	2026-09-26	PIRACICABA	CURSO MBA	103.73	2026-10-15 15:47:48.448063	581	\N	2026PD00416
832	42610681844	2	2026-09-17	PIRACICABA	CURSO MBA	80.68	2026-10-15 15:49:17.328371	582	\N	2026PD00417
833	85920356510	2	2026-09-24	PIRACICABA	CURSO MBA	103.73	2026-10-15 15:53:44.745113	583	\N	2026PD00418
743	00496426850	2	2026-08-27	SAO PAULO	AGOSTO LILAS	248.96	2026-10-13 17:57:00.859604	377	\N	2026PD00367
777	01110375816	2	2026-04-12	SAO PAULO	CURSO SSP	3360.96	2026-10-13 17:57:00.859604	409	\N	2026PD00161
778	01110375816	2	2026-04-21	SAO PAULO	CURSO SSP	2116.16	2026-10-13 17:57:00.859604	409	\N	2026PD00161
779	01110375816	2	2026-04-26	SAO PAULO	CURSO SSP	3360.96	2026-10-13 17:57:00.859604	409	\N	2026PD00161
780	01110375816	2	2026-05-03	SAO PAULO	CURSO SSP	3360.96	2026-10-13 17:57:00.859604	423	\N	2026PD00218
781	01110375816	2	2026-05-10	SAO PAULO	CURSO SSP	3360.96	2026-10-13 17:57:00.859604	423	\N	2026PD00218
782	01110375816	2	2026-05-17	SAO PAULO	CURSO SSP	3360.96	2026-10-13 17:57:00.859604	423	\N	2026PD00218
783	01110375816	2	2026-05-24	SAO PAULO	CURSO SSP	3360.96	2026-10-13 17:57:00.859604	423	\N	2026PD00218
784	01110375816	2	2026-05-31	SAO PAULO	CURSO SSP	3112.00	2026-10-13 17:57:00.859604	472	\N	2026PD00260
785	01110375816	2	2026-06-07	SAO PAULO	CURSO SSP	3112.00	2026-10-13 17:57:00.859604	472	\N	2026PD00260
786	01110375816	2	2026-06-14	SAO PAULO	CURSO SSP	3112.00	2026-10-13 17:57:00.859604	472	\N	2026PD00260
787	01110375816	2	2026-06-21	SAO PAULO	CURSO SSP	3112.00	2026-10-13 17:57:00.859604	472	\N	2026PD00260
788	01110375816	2	2026-06-28	SAO PAULO	CURSO SSP	3112.00	2026-10-13 17:57:00.859604	516	\N	2026PD00304
789	01110375816	2	2026-07-05	SAO PAULO	CURSO SSP	3112.00	2026-10-13 17:57:00.859604	516	\N	2026PD00304
790	01110375816	2	2026-07-12	SAO PAULO	CURSO SSP	3112.00	2026-10-13 17:57:00.859604	516	\N	2026PD00304
791	01110375816	2	2026-07-19	SAO PAULO	CURSO SSP	3112.00	2026-10-13 17:57:00.859604	516	\N	2026PD00304
792	01110375816	2	2026-07-26	SAO PAULO	CURSO SSP	3112.00	2026-10-13 17:57:00.859604	516	\N	2026PD00304
793	01110375816	2	2026-08-02	SAO PAULO	CURSO SSP	3360.96	2026-10-13 17:57:00.859604	371	\N	2026PD00371
794	01110375816	2	2026-08-09	SAO PAULO	CURSO SSP	3360.96	2026-10-13 17:57:00.859604	371	\N	2026PD00371
795	01110375816	2	2026-08-16	SAO PAULO	CURSO SSP	3360.96	2026-10-13 17:57:00.859604	371	\N	2026PD00371
796	01110375816	2	2026-08-23	SAO PAULO	CURSO SSP	3360.96	2026-10-13 17:57:00.859604	371	\N	2026PD00371
797	01110375816	2	2026-08-30	SAO PAULO	CURSO SSP	3360.96	2026-10-13 17:57:00.859604	381	\N	2026PD00408
799	01110375816	2	2026-09-13	SAO PAULO	CURSO SSP	3360.96	2026-10-13 17:57:00.859604	381	\N	2026PD00408
800	01110375816	2	2026-09-20	SAO PAULO	CURSO SSP	3360.96	2026-10-13 17:57:00.859604	381	\N	2026PD00408
801	01110375816	2	2026-09-27	SAO PAULO	CURSO SSP	3360.96	2026-10-13 17:57:00.859604	381	\N	2026PD00408
522	04307176103	1	2026-04-16	LIMEIRA	SERVIÇO POLICIAL	103.73	2026-10-13 17:57:00.859604	492	\N	2026PD00169
565	04704982858	1	2026-06-09	SAO PAULO	SERVIÇO POLICIAL	248.96	2026-10-13 17:57:00.859604	384	\N	2026/PD00283
560	05484576709	1	2026-02-25	SAO PAULO	SERVIÇO POLICIAL	248.96	2026-10-13 17:57:00.859604	469	\N	2026PD00129
717	06762410855	2	2026-08-02	SAO PAULO	ENCONTRO UGES	622.40	2026-10-13 17:57:00.859604	538	\N	2026PD00340
558	06762410855	1	2026-08-06	ITU	SERVIÇO POLICIAL	103.73	2026-10-13 17:57:00.859604	547	\N	2026PD00341
542	07666429681	1	2026-04-28	PIRACICABA	SERVIÇO POLICIAL	69.15	2026-10-13 17:57:00.859604	372	\N	2026PD00170
566	08922377674	1	2026-08-10	SAO PAULO	SERVIÇO POLICIAL	248.96	2026-10-13 17:57:00.859604	560	\N	2026PD00332
650	10410326682	1	2026-02-07	PIRACICABA	PLANTAO POLICIAL LIMEIRA	207.46	2026-10-13 17:57:00.859604	408	\N	2026PD00070
656	10410326682	1	2026-03-03	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	386	\N	2026PD00130
657	10410326682	1	2026-03-05	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	386	\N	2026PD00130
658	10410326682	1	2026-03-09	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	386	\N	2026PD00130
659	10410326682	1	2026-03-11	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	386	\N	2026PD00130
660	10410326682	1	2026-03-14	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	69.15	2026-10-13 17:57:00.859604	386	\N	2026PD00130
661	10410326682	1	2026-03-15	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	386	\N	2026PD00130
662	10410326682	1	2026-03-19	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	386	\N	2026PD00130
663	10410326682	1	2026-03-21	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	386	\N	2026PD00130
664	10410326682	1	2026-03-23	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	386	\N	2026PD00130
665	10410326682	1	2026-03-27	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	386	\N	2026PD00130
666	10410326682	1	2026-03-31	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	386	\N	2026PD00130
667	10410326682	1	2026-04-06	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	422	\N	2026PD00172
668	10410326682	1	2026-04-09	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	422	\N	2026PD00172
738	05484576709	2	2026-03-16	SAO PAULO	CURSO OPERACIONAL PMSP	248.96	2026-10-13 17:57:00.859604	448	\N	2026PD00129
739	05484576709	2	2026-03-17	SAO PAULO	CURSO OPERACIONAL PMSP	248.96	2026-10-13 17:57:00.859604	448	\N	2026PD00129
740	05484576709	2	2026-03-18	SAO PAULO	CURSO OPERACIONAL PMSP	248.96	2026-10-13 17:57:00.859604	448	\N	2026PD00129
741	05484576709	2	2026-03-19	SAO PAULO	CURSO OPERACIONAL PMSP	248.96	2026-10-13 17:57:00.859604	448	\N	2026PD00129
742	05484576709	2	2026-03-20	SAO PAULO	CURSO OPERACIONAL PMSP	248.96	2026-10-13 17:57:00.859604	448	\N	2026PD00129
745	05484576709	2	2026-03-23	SAO PAULO	CURSO OPERACIONAL PMSP	248.96	2026-10-13 17:57:00.859604	448	\N	2026PD00129
750	05484576709	2	2026-03-24	SAO PAULO	CURSO OPERACIONAL PMSP	248.96	2026-10-13 17:57:00.859604	448	\N	2026PD00129
754	05484576709	2	2026-03-25	SAO PAULO	CURSO OPERACIONAL PMSP	248.96	2026-10-13 17:57:00.859604	448	\N	2026PD00129
755	05484576709	2	2026-03-26	SAO PAULO	CURSO OPERACIONAL PMSP	248.96	2026-10-13 17:57:00.859604	448	\N	2026PD00129
756	05484576709	2	2026-03-27	SAO PAULO	CURSO OPERACIONAL PMSP	248.96	2026-10-13 17:57:00.859604	448	\N	2026PD00129
669	10410326682	1	2026-04-11	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	422	\N	2026PD00172
670	10410326682	1	2026-04-13	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	422	\N	2026PD00172
671	10410326682	1	2026-04-15	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	422	\N	2026PD00172
672	10410326682	1	2026-04-17	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	422	\N	2026PD00172
673	10410326682	1	2026-04-19	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	422	\N	2026PD00172
674	10410326682	1	2026-04-21	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	422	\N	2026PD00172
675	10410326682	1	2026-04-23	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	422	\N	2026PD00172
676	10410326682	1	2026-04-27	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	422	\N	2026PD00172
677	10410326682	1	2026-04-29	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	422	\N	2026PD00172
678	10410326682	1	2026-05-01	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	391	\N	2026PD00237
679	10410326682	1	2026-05-03	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	69.15	2026-10-13 17:57:00.859604	391	\N	2026PD00237
680	10410326682	1	2026-05-05	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	391	\N	2026PD00237
681	10410326682	1	2026-05-11	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	391	\N	2026PD00237
682	10410326682	1	2026-05-14	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	391	\N	2026PD00237
683	10410326682	1	2026-05-16	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	391	\N	2026PD00237
684	10410326682	1	2026-05-17	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	391	\N	2026PD00237
685	10410326682	1	2026-05-20	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	391	\N	2026PD00237
686	10410326682	1	2026-05-23	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	69.15	2026-10-13 17:57:00.859604	391	\N	2026PD00237
687	10410326682	1	2026-05-24	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	69.15	2026-10-13 17:57:00.859604	391	\N	2026PD00237
688	10410326682	1	2026-05-26	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	391	\N	2026PD00237
446	10531583600	1	2026-01-27	PIRACICABA	PLANTAO POLICIAL LIMEIRA	207.46	2026-10-13 17:57:00.859604	389	\N	2026PD00048
567	10995999899	1	2026-03-01	LIMEIRA	ACUMULO DE FUNÇÃO	107.57	2026-10-13 17:57:00.859604	434	\N	2026PD00115
568	10995999899	1	2026-03-04	LIMEIRA	ACUMULO DE FUNÇÃO	107.57	2026-10-13 17:57:00.859604	434	\N	2026PD00115
569	10995999899	1	2026-03-06	LIMEIRA	ACUMULO DE FUNÇÃO	107.57	2026-10-13 17:57:00.859604	434	\N	2026PD00115
570	10995999899	1	2026-03-07	LIMEIRA	ACUMULO DE FUNÇÃO	107.57	2026-10-13 17:57:00.859604	434	\N	2026PD00115
571	10995999899	1	2026-03-10	LIMEIRA	ACUMULO DE FUNÇÃO	107.57	2026-10-13 17:57:00.859604	434	\N	2026PD00115
572	10995999899	1	2026-03-13	LIMEIRA	ACUMULO DE FUNÇÃO	107.57	2026-10-13 17:57:00.859604	434	\N	2026PD00115
573	10995999899	1	2026-03-17	LIMEIRA	ACUMULO DE FUNÇÃO	107.57	2026-10-13 17:57:00.859604	434	\N	2026PD00115
574	10995999899	1	2026-03-21	LIMEIRA	ACUMULO DE FUNÇÃO	107.57	2026-10-13 17:57:00.859604	434	\N	2026PD00115
575	10995999899	1	2026-03-25	LIMEIRA	ACUMULO DE FUNÇÃO	107.57	2026-10-13 17:57:00.859604	434	\N	2026PD00115
723	10995999899	2	2026-03-27	PIRACICABA	CURSO TIRO	80.68	2026-10-13 17:57:00.859604	460	\N	2026PD00131
576	10995999899	1	2026-04-02	LIMEIRA	ACUMULO DE FUNÇÃO	107.57	2026-10-13 17:57:00.859604	528	\N	2026PD00173
577	10995999899	1	2026-04-04	LIMEIRA	ACUMULO DE FUNÇÃO	107.57	2026-10-13 17:57:00.859604	528	\N	2026PD00173
578	10995999899	1	2026-04-05	LIMEIRA	ACUMULO DE FUNÇÃO	107.57	2026-10-13 17:57:00.859604	528	\N	2026PD00173
579	10995999899	1	2026-04-08	LIMEIRA	ACUMULO DE FUNÇÃO	107.57	2026-10-13 17:57:00.859604	528	\N	2026PD00173
580	10995999899	1	2026-04-10	LIMEIRA	ACUMULO DE FUNÇÃO	107.57	2026-10-13 17:57:00.859604	528	\N	2026PD00173
581	10995999899	1	2026-05-01	LIMEIRA	ACUMULO DE FUNÇÃO	107.57	2026-10-13 17:57:00.859604	523	\N	2026PD00238
582	10995999899	1	2026-05-05	LIMEIRA	ACUMULO DE FUNÇÃO	107.57	2026-10-13 17:57:00.859604	523	\N	2026PD00238
583	10995999899	1	2026-05-07	LIMEIRA	ACUMULO DE FUNÇÃO	107.57	2026-10-13 17:57:00.859604	523	\N	2026PD00238
584	10995999899	1	2026-05-09	LIMEIRA	ACUMULO DE FUNÇÃO	107.57	2026-10-13 17:57:00.859604	523	\N	2026PD00238
585	10995999899	1	2026-06-01	LIMEIRA	ACUMULO DE FUNÇÃO	107.57	2026-10-13 17:57:00.859604	542	\N	2026PD00282
586	10995999899	1	2026-06-02	LIMEIRA	ACUMULO DE FUNÇÃO	107.57	2026-10-13 17:57:00.859604	542	\N	2026PD00282
587	10995999899	1	2026-06-03	LIMEIRA	ACUMULO DE FUNÇÃO	107.57	2026-10-13 17:57:00.859604	542	\N	2026PD00282
588	10995999899	1	2026-06-14	LIMEIRA	ACUMULO DE FUNÇÃO	107.57	2026-10-13 17:57:00.859604	542	\N	2026PD00282
589	10995999899	1	2026-06-17	LIMEIRA	ACUMULO DE FUNÇÃO	107.57	2026-10-13 17:57:00.859604	542	\N	2026PD00282
590	10995999899	1	2026-06-18	LIMEIRA	ACUMULO DE FUNÇÃO	107.57	2026-10-13 17:57:00.859604	542	\N	2026PD00282
591	10995999899	1	2026-06-21	LIMEIRA	ACUMULO DE FUNÇÃO	107.57	2026-10-13 17:57:00.859604	542	\N	2026PD00282
592	10995999899	1	2026-06-22	LIMEIRA	ACUMULO DE FUNÇÃO	107.57	2026-10-13 17:57:00.859604	542	\N	2026PD00282
593	10995999899	1	2026-06-25	LIMEIRA	ACUMULO DE FUNÇÃO	107.57	2026-10-13 17:57:00.859604	542	\N	2026PD00282
594	10995999899	1	2026-06-26	LIMEIRA	ACUMULO DE FUNÇÃO	107.57	2026-10-13 17:57:00.859604	542	\N	2026PD00282
595	10995999899	1	2026-07-02	LIMEIRA	ACUMULO DE FUNÇÃO	107.57	2026-10-13 17:57:00.859604	440	\N	2026PD00306
596	10995999899	1	2026-07-05	LIMEIRA	ACUMULO DE FUNÇÃO	107.57	2026-10-13 17:57:00.859604	415	\N	2026PD00306
597	10995999899	1	2026-07-08	LIMEIRA	ACUMULO DE FUNÇÃO	107.57	2026-10-13 17:57:00.859604	405	\N	2026PD00306
598	10995999899	1	2026-07-11	LIMEIRA	ACUMULO DE FUNÇÃO	107.57	2026-10-13 17:57:00.859604	533	\N	2026PD00306
599	10995999899	1	2026-07-14	LIMEIRA	ACUMULO DE FUNÇÃO	107.57	2026-10-13 17:57:00.859604	458	\N	2026PD00306
600	10995999899	1	2026-07-17	LIMEIRA	ACUMULO DE FUNÇÃO	107.57	2026-10-13 17:57:00.859604	501	\N	2026PD00306
601	10995999899	1	2026-07-20	LIMEIRA	ACUMULO DE FUNÇÃO	107.57	2026-10-13 17:57:00.859604	404	\N	2026PD00306
602	10995999899	1	2026-07-21	LIMEIRA	ACUMULO DE FUNÇÃO	107.57	2026-10-13 17:57:00.859604	403	\N	2026PD00306
603	10995999899	1	2026-07-24	LIMEIRA	ACUMULO DE FUNÇÃO	107.57	2026-10-13 17:57:00.859604	484	\N	2026PD00306
604	10995999899	1	2026-07-25	LIMEIRA	ACUMULO DE FUNÇÃO	107.57	2026-10-13 17:57:00.859604	539	\N	2026PD00306
605	10995999899	1	2026-07-28	LIMEIRA	ACUMULO DE FUNÇÃO	107.57	2026-10-13 17:57:00.859604	479	\N	2026PD00306
606	10995999899	1	2026-07-29	LIMEIRA	ACUMULO DE FUNÇÃO	107.57	2026-10-13 17:57:00.859604	532	\N	2026PD00306
607	10995999899	1	2026-08-05	LIMEIRA	ACUMULO DE FUNÇÃO	107.57	2026-10-13 17:57:00.859604	461	\N	2026PD00402
608	10995999899	1	2026-08-09	LIMEIRA	ACUMULO DE FUNÇÃO	107.57	2026-10-13 17:57:00.859604	461	\N	2026PD00402
609	10995999899	1	2026-08-11	LIMEIRA	ACUMULO DE FUNÇÃO	107.57	2026-10-13 17:57:00.859604	461	\N	2026PD00402
610	10995999899	1	2026-08-14	LIMEIRA	ACUMULO DE FUNÇÃO	107.57	2026-10-13 17:57:00.859604	461	\N	2026PD00402
611	10995999899	1	2026-08-20	LIMEIRA	ACUMULO DE FUNÇÃO	107.57	2026-10-13 17:57:00.859604	461	\N	2026PD00402
612	10995999899	1	2026-08-21	LIMEIRA	ACUMULO DE FUNÇÃO	107.57	2026-10-13 17:57:00.859604	461	\N	2026PD00402
613	10995999899	1	2026-08-22	LIMEIRA	ACUMULO DE FUNÇÃO	107.57	2026-10-13 17:57:00.859604	461	\N	2026PD00402
614	10995999899	1	2026-08-23	LIMEIRA	ACUMULO DE FUNÇÃO	107.57	2026-10-13 17:57:00.859604	461	\N	2026PD00402
615	10995999899	1	2026-08-26	LIMEIRA	ACUMULO DE FUNÇÃO	107.57	2026-10-13 17:57:00.859604	461	\N	2026PD00402
616	10995999899	1	2026-08-29	LIMEIRA	ACUMULO DE FUNÇÃO	107.57	2026-10-13 17:57:00.859604	461	\N	2026PD00402
523	11374959600	1	2026-08-05	BARUERI	SERVIÇO POLICIAL	103.73	2026-10-13 17:57:00.859604	393	\N	2026PD00334
524	11374959600	1	2026-08-17	PIRACICABA	SERVIÇO POLICIAL	103.73	2026-10-13 17:57:00.859604	473	\N	2026PD00402
716	12328788807	2	2026-07-16	SAO PAULO	TREINAMENTO	193.63	2026-10-13 17:57:00.859604	459	\N	2026PD00136
725	12375581660	2	2026-03-27	RIO CLARO	CURSO TIRO	69.15	2026-10-13 17:57:00.859604	430	\N	2026PD00184
441	12794506730	1	2026-06-09	SAO PAULO	SERVIÇO POLICIAL	248.96	2026-10-13 17:57:00.859604	457	\N	2026PD00296
694	13934950876	1	2026-05-02	LIMEIRA	PLANTAO POLICIAL LIMEIRA	161.36	2026-10-13 17:57:00.859604	485	\N	2026PD00239
695	13934950876	1	2026-05-05	LIMEIRA	PLANTAO POLICIAL LIMEIRA	161.36	2026-10-13 17:57:00.859604	485	\N	2026PD00239
696	13934950876	1	2026-05-08	LIMEIRA	PLANTAO POLICIAL LIMEIRA	161.36	2026-10-13 17:57:00.859604	485	\N	2026PD00239
697	13934950876	1	2026-05-11	LIMEIRA	PLANTAO POLICIAL LIMEIRA	161.36	2026-10-13 17:57:00.859604	485	\N	2026PD00239
698	13934950876	1	2026-05-14	LIMEIRA	PLANTAO POLICIAL LIMEIRA	161.36	2026-10-13 17:57:00.859604	485	\N	2026PD00239
699	13934950876	1	2026-05-17	LIMEIRA	PLANTAO POLICIAL LIMEIRA	161.36	2026-10-13 17:57:00.859604	485	\N	2026PD00239
400	13934950876	1	2026-05-21	LIMEIRA	PLANTAO POLICIAL LIMEIRA	161.36	2026-10-13 17:57:00.859604	485	\N	2026PD00239
401	13934950876	1	2026-05-24	LIMEIRA	PLANTAO POLICIAL LIMEIRA	161.36	2026-10-13 17:57:00.859604	485	\N	2026PD00239
402	13934950876	1	2026-05-28	LIMEIRA	PLANTAO POLICIAL LIMEIRA	161.36	2026-10-13 17:57:00.859604	485	\N	2026PD00239
403	13934950876	1	2026-05-31	LIMEIRA	PLANTAO POLICIAL LIMEIRA	161.36	2026-10-13 17:57:00.859604	485	\N	2026PD00247
404	13934950876	1	2026-06-04	LIMEIRA	PLANTAO POLICIAL LIMEIRA	161.36	2026-10-13 17:57:00.859604	495	\N	2026PD00307
405	13934950876	1	2026-06-09	LIMEIRA	PLANTAO POLICIAL LIMEIRA	161.36	2026-10-13 17:57:00.859604	488	\N	2026PD00307
406	13934950876	1	2026-06-14	LIMEIRA	PLANTAO POLICIAL LIMEIRA	161.36	2026-10-13 17:57:00.859604	370	\N	2026PD00307
395	13934950876	1	2026-06-19	LIMEIRA	PLANTAO POLICIAL LIMEIRA	161.36	2026-10-13 17:57:00.859604	480	\N	2026PD00307
407	13934950876	1	2026-06-21	LIMEIRA	PLANTAO POLICIAL LIMEIRA	161.36	2026-10-13 17:57:00.859604	400	\N	2026PD00307
408	13934950876	1	2026-06-24	LIMEIRA	PLANTAO POLICIAL LIMEIRA	161.36	2026-10-13 17:57:00.859604	470	\N	2026PD00307
409	13934950876	1	2026-06-27	LIMEIRA	PLANTAO POLICIAL LIMEIRA	161.36	2026-10-13 17:57:00.859604	438	\N	2026PD00307
410	13934950876	1	2026-06-29	LIMEIRA	PLANTAO POLICIAL LIMEIRA	161.36	2026-10-13 17:57:00.859604	435	\N	2026PD00307
411	13934950876	1	2026-07-02	LIMEIRA	ACUMULO DE FUNÇÃO	161.36	2026-10-13 17:57:00.859604	494	\N	2026PD00335
412	13934950876	1	2026-07-04	LIMEIRA	ACUMULO DE FUNÇÃO	161.36	2026-10-13 17:57:00.859604	494	\N	2026PD00335
413	13934950876	1	2026-07-06	LIMEIRA	ACUMULO DE FUNÇÃO	161.36	2026-10-13 17:57:00.859604	494	\N	2026PD00335
414	13934950876	1	2026-07-09	LIMEIRA	ACUMULO DE FUNÇÃO	161.36	2026-10-13 17:57:00.859604	494	\N	2026PD00335
415	13934950876	1	2026-07-11	LIMEIRA	ACUMULO DE FUNÇÃO	161.36	2026-10-13 17:57:00.859604	494	\N	2026PD00335
416	13934950876	1	2026-07-12	LIMEIRA	ACUMULO DE FUNÇÃO	161.36	2026-10-13 17:57:00.859604	494	\N	2026PD00335
417	13934950876	1	2026-07-15	LIMEIRA	ACUMULO DE FUNÇÃO	161.36	2026-10-13 17:57:00.859604	494	\N	2026PD00335
418	13934950876	1	2026-07-18	LIMEIRA	ACUMULO DE FUNÇÃO	161.36	2026-10-13 17:57:00.859604	494	\N	2026PD00335
419	13934950876	1	2026-07-20	LIMEIRA	ACUMULO DE FUNÇÃO	161.36	2026-10-13 17:57:00.859604	494	\N	2026PD00335
420	13934950876	1	2026-07-23	LIMEIRA	ACUMULO DE FUNÇÃO	161.36	2026-10-13 17:57:00.859604	494	\N	2026PD00335
421	13934950876	1	2026-07-25	LIMEIRA	ACUMULO DE FUNÇÃO	161.36	2026-10-13 17:57:00.859604	494	\N	2026PD00335
422	13934950876	1	2026-07-27	LIMEIRA	ACUMULO DE FUNÇÃO	161.36	2026-10-13 17:57:00.859604	494	\N	2026PD00335
423	13934950876	1	2026-07-30	LIMEIRA	ACUMULO DE FUNÇÃO	161.36	2026-10-13 17:57:00.859604	494	\N	2026PD00335
424	13934950876	1	2026-08-02	LIMEIRA	ACUMULO DE FUNÇÃO	161.36	2026-10-13 17:57:00.859604	454	\N	2026PD00402
425	13934950876	1	2026-08-06	LIMEIRA	ACUMULO DE FUNÇÃO	161.36	2026-10-13 17:57:00.859604	454	\N	2026PD00402
426	13934950876	1	2026-08-09	LIMEIRA	ACUMULO DE FUNÇÃO	161.36	2026-10-13 17:57:00.859604	454	\N	2026PD00402
427	13934950876	1	2026-08-12	LIMEIRA	ACUMULO DE FUNÇÃO	161.36	2026-10-13 17:57:00.859604	454	\N	2026PD00402
428	13934950876	1	2026-08-15	LIMEIRA	ACUMULO DE FUNÇÃO	161.36	2026-10-13 17:57:00.859604	454	\N	2026PD00402
429	13934950876	1	2026-08-18	LIMEIRA	ACUMULO DE FUNÇÃO	161.36	2026-10-13 17:57:00.859604	454	\N	2026PD00402
430	13934950876	1	2026-08-22	LIMEIRA	ACUMULO DE FUNÇÃO	161.36	2026-10-13 17:57:00.859604	454	\N	2026PD00402
431	13934950876	1	2026-08-24	LIMEIRA	ACUMULO DE FUNÇÃO	161.36	2026-10-13 17:57:00.859604	454	\N	2026PD00402
432	13934950876	1	2026-08-28	LIMEIRA	ACUMULO DE FUNÇÃO	161.36	2026-10-13 17:57:00.859604	454	\N	2026PD00402
433	13934950876	1	2026-08-30	LIMEIRA	ACUMULO DE FUNÇÃO	161.36	2026-10-13 17:57:00.859604	454	\N	2026PD00402
625	14694180703	1	2026-06-09	SAO PAULO	SERVIÇO POLICIAL	248.96	2026-10-13 17:57:00.859604	519	\N	2026PD00284
626	14694180703	1	2026-08-05	BARUERI	SERVIÇO POLICIAL	103.73	2026-10-13 17:57:00.859604	436	\N	2026PD00402
744	15721307846	2	2026-07-16	SAO PAULO	TREINAMENTO	248.96	2026-10-13 17:57:00.859604	522	\N	2026PD00317
520	16791203870	1	2026-08-05	BARUERI	SERVIÇO POLICIAL	103.73	2026-10-13 17:57:00.859604	378	\N	2026PD00336
628	18208623806	1	2026-01-11	LIMEIRA	PLANTAO POLICIAL LIMEIRA	207.46	2026-10-13 17:57:00.859604	429	\N	2026PD00049
708	18208623806	2	2026-01-29	SAO PAULO	CURSO ACADEPOL APH	871.36	2026-10-13 17:57:00.859604	462	\N	2026PD00059
629	18208623806	1	2026-03-06	JAGUARIUNA	SERVIÇO POLICIAL	69.15	2026-10-13 17:57:00.859604	555	\N	2026PD00116
713	18208623806	2	2026-04-30	SALTINHO	CURSO ENTRADAS TATICAS	138.31	2026-10-13 17:57:00.859604	546	\N	2026PD00162
630	18208623806	1	2026-07-13	LIMEIRA	PLANTAO POLICIAL LIMEIRA	207.46	2026-10-13 17:57:00.859604	468	\N	2026PD00308
631	18208623806	1	2026-08-29	LIMEIRA	PLANTAO POLICIAL LIMEIRA	103.73	2026-10-13 17:57:00.859604	419	\N	2026PD00402
434	19163513870	1	2026-01-01	PIRACICABA	PLANTAO POLICIAL LIMEIRA	207.46	2026-10-13 17:57:00.859604	418	\N	2026PD00050
689	19174943863	1	2026-02-20	SAO PAULO	SERVIÇO POLICIAL	248.96	2026-10-13 17:57:00.859604	427	\N	2026PD00071
447	19203432884	1	2026-04-15	SAO PAULO	SERVIÇO POLICIAL	248.96	2026-10-13 17:57:00.859604	506	\N	2026PD00174
448	19203432884	1	2026-06-09	SAO PAULO	SERVIÇO POLICIAL	248.96	2026-10-13 17:57:00.859604	453	\N	2026PD00285
639	19216935847	1	2026-03-06	JAGUARIUNA	SERVIÇO POLICIAL	69.15	2026-10-13 17:57:00.859604	390	\N	2026PD00117
640	19216935847	1	2026-03-11	RIO CLARO	SERVIÇO POLICIAL	69.15	2026-10-13 17:57:00.859604	421	\N	\N
517	21360741801	1	2026-02-12	CAPIVARI	SERVIÇO POLICIAL	138.31	2026-10-13 17:57:00.859604	417	\N	2026PD00072
518	21360741801	1	2026-03-13	PIRACICABA	SERVIÇO POLICIAL	53.78	2026-10-13 17:57:00.859604	499	\N	2026PD00118
519	21360741801	1	2026-03-20	SAO PAULO	SERVIÇO POLICIAL	96.81	2026-10-13 17:57:00.859604	536	\N	2026PD00118
534	21675933847	1	2026-02-26	POÇOS DE CALDAS	SERVIÇO POLICIAL	207.46	2026-10-13 17:57:00.859604	545	\N	2026PD00119
559	22444646878	1	2026-02-19	PIRACICABA	PLANTAO POLICIAL LIMEIRA	207.46	2026-10-13 17:57:00.859604	449	\N	2026PD00073
533	24886549810	1	2026-04-15	SAO PAULO	SERVIÇO POLICIAL	248.96	2026-10-13 17:57:00.859604	525	\N	2026PD00175
435	24999284847	1	2026-01-19	PIRACICABA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	478	\N	2026PD00051
436	24999284847	1	2026-05-14	LIMEIRA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	398	\N	2026PD00240
437	24999284847	1	2026-06-15	LIMEIRA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	552	\N	2026PD00286
438	24999284847	1	2026-07-18	LIMEIRA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	535	\N	2026PD00309
439	24999284847	1	2026-07-24	LIMEIRA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	395	\N	2026PD00309
440	24999284847	1	2026-08-08	LIMEIRA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	517	\N	2026PD00342
511	27057183895	1	2026-01-10	LIMEIRA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	549	\N	2026PD00052
512	27057183895	1	2026-02-21	LIMEIRA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	475	\N	2026PD00083
513	27057183895	1	2026-05-17	LIMEIRA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	452	\N	2026PD00241
812	19216935847	1	2026-04-16	LIMEIRA	SERVICO POLICIAL	103.73	2026-10-14 15:17:54.234558	557	\N	2026PD00194
641	19216935847	1	2026-04-16	LIMEIRA	SERVIÇO POLICIAL	103.73	2026-10-13 17:57:00.859604	557	\N	2026PD00194
644	26451064807	1	2026-06-16	RIO DE JANEIRO	SERVIÇO POLICIAL	822.94	2026-10-13 17:57:00.859604	487	\N	2026PD00287
514	27057183895	1	2026-06-07	LIMEIRA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	368	\N	2026PD00288
515	27057183895	1	2026-06-21	LIMEIRA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	526	\N	2026PD00288
617	27206162819	1	2026-01-18	LIMEIRA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	486	\N	2026PD00053
618	27206162819	1	2026-03-22	LIMEIRA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	425	\N	2026PD00120
619	27206162819	1	2026-04-12	LIMEIRA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	447	\N	2026PD00176
620	27206162819	1	2026-05-04	LIMEIRA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	500	\N	2026PD00242
621	27206162819	1	2026-06-09	GUARULHOS	SERVIÇO POLICIAL	207.46	2026-10-13 17:57:00.859604	380	\N	2026PD00289
622	27206162819	1	2026-06-20	LIMEIRA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	531	\N	2026PD00289
623	27206162819	1	2026-07-09	LIMEIRA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	376	\N	2026PD00310
624	27206162819	1	2026-08-09	LIMEIRA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	388	\N	\N
690	27935713855	1	2026-05-12	SAO PAULO	SERVIÇO POLICIAL	124.48	2026-10-13 17:57:00.859604	483	\N	2026PD00243
691	27935713855	1	2026-05-20	SAO PAULO	SERVIÇO POLICIAL	124.48	2026-10-13 17:57:00.859604	396	\N	2026PD00243
692	27935713855	1	2026-06-09	SAO PAULO	SERVIÇO POLICIAL	248.96	2026-10-13 17:57:00.859604	508	\N	2026PD00243
693	29474854831	1	2026-08-05	BARUERI	SERVIÇO POLICIAL	80.68	2026-10-13 17:57:00.859604	455	\N	\N
536	30310116864	1	2026-02-20	SAO PAULO	SERVIÇO POLICIAL	248.96	2026-10-13 17:57:00.859604	451	\N	2026PD00074
751	30310116864	2	2026-02-25	SAO PAULO	CURSO ACADEPOL ACADEPOL	248.96	2026-10-13 17:57:00.859604	476	\N	2026PD00085
752	30310116864	2	2026-02-26	SAO PAULO	CURSO ACADEPOL ACADEPOL	248.96	2026-10-13 17:57:00.859604	476	\N	2026PD00085
753	30310116864	2	2026-02-27	SAO PAULO	CURSO ACADEPOL ACADEPOL	248.96	2026-10-13 17:57:00.859604	476	\N	2026PD00085
632	30841335818	1	2026-06-09	SAO PAULO	SERVIÇO POLICIAL	248.96	2026-10-13 17:57:00.859604	439	\N	\N
633	30841335818	1	2026-07-09	SAO PAULO	SERVIÇO POLICIAL	248.96	2026-10-13 17:57:00.859604	439	\N	\N
538	31082697800	1	2026-08-17	PIRACICABA	SERVIÇO POLICIAL	103.73	2026-10-13 17:57:00.859604	474	\N	2026PD00402
544	31239665857	1	2026-02-10	SAO PAULO	SERVIÇO POLICIAL	248.96	2026-10-13 17:57:00.859604	510	\N	2026PD00075
545	31239665857	1	2026-03-06	JAGUARIUNA	SERVIÇO POLICIAL	69.15	2026-10-13 17:57:00.859604	504	\N	2026PD00121
546	31239665857	1	2026-03-11	RIO CLARO	SERVIÇO POLICIAL	69.15	2026-10-13 17:57:00.859604	481	\N	2026PD00121
535	31892853817	1	2026-03-06	JAGUARIUNA	SERVIÇO POLICIAL	69.15	2026-10-13 17:57:00.859604	385	\N	2026PD00122
746	31892853817	2	2026-04-17	PIRACICABA	CURSO ACADEPOL TAT  I	103.73	2026-10-13 17:57:00.859604	432	\N	2026PD00163
747	31892853817	2	2026-04-19	CHARQUEADA	CURSO ACADEPOL TAT  I	138.31	2026-10-13 17:57:00.859604	432	\N	2026PD00163
748	31892853817	2	2026-04-23	CHARQUEADA	CURSO ACADEPOL TAT  I	69.15	2026-10-13 17:57:00.859604	432	\N	2026PD00163
749	31892853817	2	2026-04-26	PIRACICABA	CURSO ACADEPOL TAT  I	103.73	2026-10-13 17:57:00.859604	382	\N	2026PD00163
526	32540502822	1	2026-01-07	PIRACICABA	PLANTAO POLICIAL LIMEIRA	207.46	2026-10-13 17:57:00.859604	437	\N	2026PD00054
527	32540502822	1	2026-02-14	LIMEIRA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	402	\N	2026PD00076
735	32540502822	2	2026-03-05	SAO PAULO	CURSO APH	995.84	2026-10-13 17:57:00.859604	402	\N	2026PD00132
528	32540502822	1	2026-04-25	LIMEIRA	SERVIÇO POLICIAL	138.31	2026-10-13 17:57:00.859604	424	\N	2026PD00177
529	32540502822	1	2026-05-12	LIMEIRA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	521	\N	2026PD00244
530	32540502822	1	2026-06-08	LIMEIRA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	383	\N	206PD00290
531	32540502822	1	2026-07-20	LIMEIRA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	529	\N	2026PD00311
532	32540502822	1	2026-08-26	LIMEIRA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	414	\N	2026PD00402
772	32628691809	2	2026-04-14	PIRACICABA	CURSO ACADEPOL	69.15	2026-10-13 17:57:00.859604	413	\N	2026PD00164
773	32628691809	2	2026-05-04	PIRACICABA	CURSO ACADEPOL	69.15	2026-10-13 17:57:00.859604	561	\N	2026PD00221
774	32628691809	2	2026-05-05	PIRACICABA	CURSO ACADEPOL	69.15	2026-10-13 17:57:00.859604	550	\N	2026PD00221
803	32628691809	2	2026-05-06	PIRACICABA	CURSO ACADEPOL	69.15	2026-10-13 17:57:00.859604	428	\N	2026PD00221
769	32968804880	2	2026-08-27	SAO PAULO	AGOSTO LILAS	248.96	2026-10-13 17:57:00.859604	553	\N	2026PD00368
702	33648957830	2	2026-05-04	PIRACICABA	CURSO ACADEPOL	69.15	2026-10-13 17:57:00.859604	520	\N	2026PD00222
707	33648957830	2	2026-05-05	PIRACICABA	CURSO ACADEPOL	69.15	2026-10-13 17:57:00.859604	520	\N	2026PD00222
710	33648957830	2	2026-05-06	PIRACICABA	CURSO ACADEPOL	69.15	2026-10-13 17:57:00.859604	520	\N	2026PD00222
758	33648957830	2	2026-06-25	PIRACICABA	CURSO ACADEPOL	69.15	2026-10-13 17:57:00.859604	493	\N	2026PD00261
770	33648957830	2	2026-06-26	PIRACICABA	CURSO ACADEPOL	69.15	2026-10-13 17:57:00.859604	493	\N	2026PD00261
730	35313574841	2	2026-06-25	PIRACICABA	CURSO ACADEPOL	69.15	2026-10-13 17:57:00.859604	445	\N	2026PD00262
731	35313574841	2	2026-06-26	PIRACICABA	CURSO ACADEPOL	69.15	2026-10-13 17:57:00.859604	445	\N	2026PD00262
826	35500297805	2	2026-04-19	CHARQUEADA	CUSRO TAT I	69.15	2026-10-14 16:11:58.837708	374	\N	2026PD00165
705	35500297805	2	2026-04-23	CHARQUEADA	CURSO ACADEPOL TAT  I	69.15	2026-10-13 17:57:00.859604	374	\N	2026PD00165
706	35500297805	2	2026-04-26	CHARQUEADA	CURSO ACADEPOL TAT  I	69.15	2026-10-13 17:57:00.859604	374	\N	2026PD00165
771	35932472839	2	2026-03-27	PIRACICABA	CURSO TIRO	69.15	2026-10-13 17:57:00.859604	511	\N	2026PD00133
547	36025331820	1	2026-02-07	PIRACICABA	PLANTAO POLICIAL LIMEIRA	207.46	2026-10-13 17:57:00.859604	477	\N	2026PD00078
548	36025331820	1	2026-03-16	SAO PAULO	SERVIÇO POLICIAL	248.96	2026-10-13 17:57:00.859604	524	\N	2026PD00124
634	36750397816	1	2026-02-04	CAPIVARI	SERVIÇO POLICIAL	138.31	2026-10-13 17:57:00.859604	513	\N	2026PD00079
635	36750397816	1	2026-03-10	MONTE MOR	SERVIÇO POLICIAL	69.15	2026-10-13 17:57:00.859604	442	\N	2026PD00125
636	36750397816	1	2026-03-13	PIRACICABA	SERVIÇO POLICIAL	69.15	2026-10-13 17:57:00.859604	373	\N	2026PD00125
637	36750397816	1	2026-04-09	SAO PAULO	SERVIÇO POLICIAL	248.96	2026-10-13 17:57:00.859604	482	\N	2026PD00178
722	36819640846	2	2026-08-27	SAO PAULO	AGOSTO LILAS	248.96	2026-10-13 17:57:00.859604	515	\N	2026PD00369
543	38355373855	1	2026-08-05	PIRACICABA	SERVIÇO POLICIAL	103.73	2026-10-13 17:57:00.859604	507	\N	2026PD00402
549	39460172822	1	2026-01-27	PIRACICABA	PLANTAO POLICIAL LIMEIRA	207.46	2026-10-13 17:57:00.859604	544	\N	2026PD00056
550	39460172822	1	2026-02-10	SAO PAULO	SERVIÇO POLICIAL	248.96	2026-10-13 17:57:00.859604	548	\N	2026PD00080
551	39460172822	1	2026-02-22	LIMEIRA	PLANTAO POLICIAL LIMEIRA	207.46	2026-10-13 17:57:00.859604	394	\N	2026PD00080
552	39460172822	1	2026-03-06	JAGUARIUNA	SERVIÇO POLICIAL	69.15	2026-10-13 17:57:00.859604	554	\N	2026PD00126
553	39460172822	1	2026-04-26	LIMEIRA	SERVIÇO POLICIAL	207.45	2026-10-13 17:57:00.859604	551	\N	2026PD00179
554	39460172822	1	2026-06-12	LIMEIRA	PLANTAO POLICIAL LIMEIRA	207.46	2026-10-13 17:57:00.859604	497	\N	2026PD00292
555	39460172822	1	2026-06-25	LIMEIRA	PLANTAO POLICIAL LIMEIRA	207.46	2026-10-13 17:57:00.859604	401	\N	2026PD00292
712	39460172822	2	2026-06-25	SAO PAULO	SEMINARIO	248.96	2026-10-13 17:57:00.859604	401	\N	2026PD00292
556	39460172822	1	2026-07-03	LIMEIRA	PLANTAO POLICIAL LIMEIRA	207.46	2026-10-13 17:57:00.859604	540	\N	2026PD00313
557	39460172822	1	2026-08-22	LIMEIRA	PLANTAO POLICIAL LIMEIRA	207.46	2026-10-13 17:57:00.859604	426	\N	2026PD00402
539	40381911845	1	2026-02-25	SAO PAULO	SERVIÇO POLICIAL	248.96	2026-10-13 17:57:00.859604	498	\N	2026PD00081
540	40381911845	1	2026-02-26	POÇOS DE CALDAS	SERVIÇO POLICIAL	207.46	2026-10-13 17:57:00.859604	410	\N	2026PD00081
759	40381911845	2	2026-03-16	SAO PAULO	CURSO OPERACIONAL PMSP	248.96	2026-10-13 17:57:00.859604	509	\N	2026PD00134
760	40381911845	2	2026-03-17	SAO PAULO	CURSO OPERACIONAL PMSP	248.96	2026-10-13 17:57:00.859604	509	\N	2026PD00134
761	40381911845	2	2026-03-18	SAO PAULO	CURSO OPERACIONAL PMSP	248.96	2026-10-13 17:57:00.859604	509	\N	2026PD00134
762	40381911845	2	2026-03-19	SAO PAULO	CURSO OPERACIONAL PMSP	248.96	2026-10-13 17:57:00.859604	509	\N	2026PD00134
763	40381911845	2	2026-03-20	SAO PAULO	CURSO OPERACIONAL PMSP	248.96	2026-10-13 17:57:00.859604	509	\N	2026PD00134
764	40381911845	2	2026-03-23	SAO PAULO	CURSO OPERACIONAL PMSP	248.96	2026-10-13 17:57:00.859604	509	\N	2026PD00134
765	40381911845	2	2026-03-24	SAO PAULO	CURSO OPERACIONAL PMSP	248.96	2026-10-13 17:57:00.859604	509	\N	2026PD00134
766	40381911845	2	2026-03-25	SAO PAULO	CURSO OPERACIONAL PMSP	248.96	2026-10-13 17:57:00.859604	509	\N	2026PD00134
767	40381911845	2	2026-03-26	SAO PAULO	CURSO OPERACIONAL PMSP	248.96	2026-10-13 17:57:00.859604	509	\N	2026PD00134
768	40381911845	2	2026-03-27	SAO PAULO	CURSO OPERACIONAL PMSP	248.96	2026-10-13 17:57:00.859604	509	\N	2026PD00134
541	40381911845	1	2026-06-19	RIO DE JANEIRO	SERVIÇO POLICIAL	822.94	2026-10-13 17:57:00.859604	518	\N	2026PD00293
442	40952268892	1	2026-02-12	CAPIVARI	SERVIÇO POLICIAL	138.31	2026-10-13 17:57:00.859604	406	\N	2026PD00082
443	40952268892	1	2026-03-10	MONTE MOR	SERVIÇO POLICIAL	69.15	2026-10-13 17:57:00.859604	392	\N	2026PD00127
444	40952268892	1	2026-03-13	PIRACICABA	SERVIÇO POLICIAL	69.15	2026-10-13 17:57:00.859604	527	\N	2026PD00127
445	40952268892	1	2026-04-09	SAO PAULO	SERVIÇO POLICIAL	248.96	2026-10-13 17:57:00.859604	467	\N	2026PD00180
396	42582609838	1	2026-01-01	PIRACICABA	PLANTAO POLICIAL LIMEIRA	207.46	2026-10-13 17:57:00.859604	375	\N	2026PD00057
397	42582609838	1	2026-02-08	LIMEIRA	PLANTAO POLICIAL LIMEIRA	69.15	2026-10-13 17:57:00.859604	514	\N	2026PD00083
398	42582609838	1	2026-02-12	LIMEIRA	PLANTAO POLICIAL LIMEIRA	207.46	2026-10-13 17:57:00.859604	503	\N	2026PD00083
399	42582609838	1	2026-03-07	LIMEIRA	PLANTAO POLICIAL LIMEIRA	69.15	2026-10-13 17:57:00.859604	416	\N	2026PD00128
700	42582609838	2	2026-03-16	SAO PAULO	SEMINARIO FEMINICIDIO	248.96	2026-10-13 17:57:00.859604	464	\N	2026PD00135
701	42582609838	2	2026-03-26	RIO CLARO	CURSO TIRO	69.15	2026-10-13 17:57:00.859604	490	\N	2026PD00135
504	42582609838	1	2026-03-29	LIMEIRA	PLANTAO POLICIAL LIMEIRA	69.15	2026-10-13 17:57:00.859604	441	\N	2026PD00128
505	42582609838	1	2026-04-21	LIMEIRA	PLANTAO POLICIAL LIMEIRA	69.15	2026-10-13 17:57:00.859604	537	\N	2026PD00166
816	35500297805	1	2026-06-19	RIO DE JANEIRO	SERVICO POLICIAL	822.94	2026-10-14 15:30:36.609726	399	\N	2026PD00291
704	42582609838	2	2026-04-23	SAO PAULO	PALESTRA ACADEPOL	124.48	2026-10-13 17:57:00.859604	433	\N	2026PD00166
506	42582609838	1	2026-05-09	LIMEIRA	PLANTAO POLICIAL LIMEIRA	69.15	2026-10-13 17:57:00.859604	369	\N	2026PD00245
507	42582609838	1	2026-06-29	LIMEIRA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	397	\N	2026PD00128
508	42582609838	1	2026-07-11	LIMEIRA	PLANTAO POLICIAL LIMEIRA	69.15	2026-10-13 17:57:00.859604	563	\N	2026PD00314
509	42582609838	1	2026-07-28	LIMEIRA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	379	\N	2026PD00337
709	42582609838	2	2026-08-27	LIMEIRA	AGOSTO LILAS	248.96	2026-10-13 17:57:00.859604	431	\N	2026PD00370
510	42582609838	1	2026-08-28	LIMEIRA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	407	\N	2026PD00402
711	42582609838	2	2026-09-02	LIMEIRA	VIOLENCIA DE GENERO	248.96	2026-10-13 17:57:00.859604	456	\N	2026PD00370
757	42610681844	2	2026-03-26	RIO CLARO	CURSO TIRO	107.57	2026-10-13 17:57:00.859604	471	\N	2026PD00167
562	42610681844	1	2026-05-20	SAO PAULO	SERVIÇO POLICIAL	193.63	2026-10-13 17:57:00.859604	559	\N	2026PD00246
563	42610681844	1	2026-06-09	SAO PAULO	SERVIÇO POLICIAL	193.63	2026-10-13 17:57:00.859604	411	\N	2026PD00294
525	43992425827	1	2026-01-07	PIRACICABA	PLANTAO POLICIAL LIMEIRA	207.46	2026-10-13 17:57:00.859604	463	\N	2026PD00058
449	44519520851	1	2026-06-01	LIMEIRA	SERVIÇO POLICIAL	69.15	2026-10-13 17:57:00.859604	420	\N	2026PD00297
450	44519520851	1	2026-06-02	LIMEIRA	SERVIÇO POLICIAL	69.15	2026-10-13 17:57:00.859604	420	\N	2026PD00297
451	44519520851	1	2026-06-03	LIMEIRA	SERVIÇO POLICIAL	69.15	2026-10-13 17:57:00.859604	420	\N	2026PD00297
452	44519520851	1	2026-06-04	LIMEIRA	SERVIÇO POLICIAL	69.15	2026-10-13 17:57:00.859604	420	\N	2026PD00297
453	44519520851	1	2026-06-05	LIMEIRA	SERVIÇO POLICIAL	69.15	2026-10-13 17:57:00.859604	420	\N	2026PD00297
454	44519520851	1	2026-06-08	LIMEIRA	SERVIÇO POLICIAL	69.15	2026-10-13 17:57:00.859604	420	\N	2026PD00297
455	44519520851	1	2026-06-09	LIMEIRA	SERVIÇO POLICIAL	69.15	2026-10-13 17:57:00.859604	420	\N	2026PD00297
456	44519520851	1	2026-06-10	LIMEIRA	SERVIÇO POLICIAL	69.15	2026-10-13 17:57:00.859604	420	\N	2026PD00297
457	44519520851	1	2026-06-11	LIMEIRA	SERVIÇO POLICIAL	69.15	2026-10-13 17:57:00.859604	420	\N	2026PD00297
458	44519520851	1	2026-06-12	LIMEIRA	SERVIÇO POLICIAL	69.15	2026-10-13 17:57:00.859604	420	\N	2026PD00297
459	44519520851	1	2026-06-15	LIMEIRA	SERVIÇO POLICIAL	69.15	2026-10-13 17:57:00.859604	420	\N	2026PD00297
460	44519520851	1	2026-06-16	LIMEIRA	SERVIÇO POLICIAL	69.15	2026-10-13 17:57:00.859604	420	\N	2026PD00297
461	44519520851	1	2026-06-17	LIMEIRA	SERVIÇO POLICIAL	69.15	2026-10-13 17:57:00.859604	420	\N	2026PD00297
462	44519520851	1	2026-06-18	LIMEIRA	SERVIÇO POLICIAL	69.15	2026-10-13 17:57:00.859604	420	\N	2026PD00297
463	44519520851	1	2026-06-19	LIMEIRA	SERVIÇO POLICIAL	69.15	2026-10-13 17:57:00.859604	420	\N	2026PD00297
464	44519520851	1	2026-06-22	LIMEIRA	SERVIÇO POLICIAL	69.15	2026-10-13 17:57:00.859604	420	\N	2026PD00297
465	44519520851	1	2026-06-23	LIMEIRA	SERVIÇO POLICIAL	69.15	2026-10-13 17:57:00.859604	420	\N	2026PD00297
466	44519520851	1	2026-06-24	LIMEIRA	SERVIÇO POLICIAL	69.15	2026-10-13 17:57:00.859604	420	\N	2026PD00297
467	44519520851	1	2026-06-25	LIMEIRA	SERVIÇO POLICIAL	69.15	2026-10-13 17:57:00.859604	420	\N	2026PD00297
468	44519520851	1	2026-06-26	LIMEIRA	SERVIÇO POLICIAL	69.15	2026-10-13 17:57:00.859604	420	\N	2026PD00297
469	44519520851	1	2026-07-14	LIMEIRA	ACUMULO DE FUNÇÃO	69.15	2026-10-13 17:57:00.859604	496	\N	2026PD00338
470	44519520851	1	2026-07-15	LIMEIRA	ACUMULO DE FUNÇÃO	69.15	2026-10-13 17:57:00.859604	496	\N	2026PD00338
471	44519520851	1	2026-07-16	LIMEIRA	ACUMULO DE FUNÇÃO	69.15	2026-10-13 17:57:00.859604	496	\N	2026PD00338
472	44519520851	1	2026-07-17	LIMEIRA	ACUMULO DE FUNÇÃO	69.15	2026-10-13 17:57:00.859604	496	\N	2026PD00338
473	44519520851	1	2026-07-20	LIMEIRA	ACUMULO DE FUNÇÃO	69.15	2026-10-13 17:57:00.859604	496	\N	2026PD00338
474	44519520851	1	2026-07-21	LIMEIRA	ACUMULO DE FUNÇÃO	69.15	2026-10-13 17:57:00.859604	496	\N	2026PD00338
475	44519520851	1	2026-07-22	LIMEIRA	ACUMULO DE FUNÇÃO	69.15	2026-10-13 17:57:00.859604	496	\N	2026PD00338
476	44519520851	1	2026-07-23	LIMEIRA	ACUMULO DE FUNÇÃO	69.15	2026-10-13 17:57:00.859604	496	\N	2026PD00338
477	44519520851	1	2026-07-24	LIMEIRA	ACUMULO DE FUNÇÃO	69.15	2026-10-13 17:57:00.859604	496	\N	2026PD00338
478	44519520851	1	2026-07-27	LIMEIRA	ACUMULO DE FUNÇÃO	69.15	2026-10-13 17:57:00.859604	496	\N	2026PD00338
479	44519520851	1	2026-07-28	LIMEIRA	ACUMULO DE FUNÇÃO	69.15	2026-10-13 17:57:00.859604	496	\N	2026PD00338
480	44519520851	1	2026-07-29	LIMEIRA	ACUMULO DE FUNÇÃO	69.15	2026-10-13 17:57:00.859604	496	\N	2026PD00338
481	44519520851	1	2026-07-30	LIMEIRA	ACUMULO DE FUNÇÃO	69.15	2026-10-13 17:57:00.859604	496	\N	2026PD00338
482	44519520851	1	2026-07-31	LIMEIRA	ACUMULO DE FUNÇÃO	69.15	2026-10-13 17:57:00.859604	496	\N	2026PD00338
483	44519520851	1	2026-08-03	LIMEIRA	ACUMULO DE FUNÇÃO	69.15	2026-10-13 17:57:00.859604	465	\N	2026PD00402
484	44519520851	1	2026-08-04	LIMEIRA	ACUMULO DE FUNÇÃO	69.15	2026-10-13 17:57:00.859604	465	\N	2026PD00402
485	44519520851	1	2026-08-05	LIMEIRA	ACUMULO DE FUNÇÃO	69.15	2026-10-13 17:57:00.859604	465	\N	2026PD00402
486	44519520851	1	2026-08-06	LIMEIRA	ACUMULO DE FUNÇÃO	69.15	2026-10-13 17:57:00.859604	465	\N	2026PD00402
487	44519520851	1	2026-08-07	LIMEIRA	ACUMULO DE FUNÇÃO	69.15	2026-10-13 17:57:00.859604	465	\N	2026PD00402
488	44519520851	1	2026-08-10	LIMEIRA	ACUMULO DE FUNÇÃO	69.15	2026-10-13 17:57:00.859604	465	\N	2026PD00402
489	44519520851	1	2026-08-11	LIMEIRA	ACUMULO DE FUNÇÃO	69.15	2026-10-13 17:57:00.859604	465	\N	2026PD00402
490	44519520851	1	2026-08-12	LIMEIRA	ACUMULO DE FUNÇÃO	69.15	2026-10-13 17:57:00.859604	465	\N	2026PD00402
491	44519520851	1	2026-08-13	LIMEIRA	ACUMULO DE FUNÇÃO	69.15	2026-10-13 17:57:00.859604	465	\N	2026PD00402
492	44519520851	1	2026-08-14	LIMEIRA	ACUMULO DE FUNÇÃO	69.15	2026-10-13 17:57:00.859604	465	\N	2026PD00402
493	44519520851	1	2026-08-17	LIMEIRA	ACUMULO DE FUNÇÃO	69.15	2026-10-13 17:57:00.859604	465	\N	2026PD00402
494	44519520851	1	2026-08-18	LIMEIRA	ACUMULO DE FUNÇÃO	69.15	2026-10-13 17:57:00.859604	465	\N	2026PD00402
495	44519520851	1	2026-08-19	LIMEIRA	ACUMULO DE FUNÇÃO	69.15	2026-10-13 17:57:00.859604	465	\N	2026PD00402
496	44519520851	1	2026-08-20	LIMEIRA	ACUMULO DE FUNÇÃO	69.15	2026-10-13 17:57:00.859604	465	\N	2026PD00402
497	44519520851	1	2026-08-21	LIMEIRA	ACUMULO DE FUNÇÃO	69.15	2026-10-13 17:57:00.859604	465	\N	2026PD00402
498	44519520851	1	2026-08-24	LIMEIRA	ACUMULO DE FUNÇÃO	69.15	2026-10-13 17:57:00.859604	465	\N	2026PD00402
499	44519520851	1	2026-08-25	LIMEIRA	ACUMULO DE FUNÇÃO	69.15	2026-10-13 17:57:00.859604	465	\N	2026PD00402
500	44519520851	1	2026-08-26	LIMEIRA	ACUMULO DE FUNÇÃO	69.15	2026-10-13 17:57:00.859604	465	\N	2026PD00402
501	44519520851	1	2026-08-27	LIMEIRA	ACUMULO DE FUNÇÃO	69.15	2026-10-13 17:57:00.859604	465	\N	2026PD00402
502	44519520851	1	2026-08-28	LIMEIRA	ACUMULO DE FUNÇÃO	69.15	2026-10-13 17:57:00.859604	465	\N	2026PD00402
503	44519520851	1	2026-08-31	LIMEIRA	ACUMULO DE FUNÇÃO	69.15	2026-10-13 17:57:00.859604	465	\N	2026PD00402
516	46508753827	1	2026-04-09	SAO PAULO	SERVIÇO POLICIAL	248.96	2026-10-13 17:57:00.859604	502	\N	2026PD00183
718	46508753827	2	2026-05-04	PIRACICABA	CURSO ACADEPOL	69.15	2026-10-13 17:57:00.859604	541	\N	2026PD00223
719	46508753827	2	2026-05-05	PIRACICABA	CURSO ACADEPOL	69.15	2026-10-13 17:57:00.859604	489	\N	2026PD00223
720	46508753827	2	2026-05-06	PIRACICABA	CURSO ACADEPOL	69.15	2026-10-13 17:57:00.859604	491	\N	2026PD00223
564	47033640854	1	2026-06-19	RIO DE JANEIRO	SERVIÇO POLICIAL	822.94	2026-10-13 17:57:00.859604	558	\N	2026PD00295
537	80184782104	1	2026-08-05	BARUERI	SERVIÇO POLICIAL	103.73	2026-10-13 17:57:00.859604	534	\N	2026PD00343
802	82897123915	2	2026-04-23	SALTINHO	CURSO ACADEPOL	138.31	2026-10-13 17:57:00.859604	556	\N	2026PD00168
\.


--
-- Data for Name: pagamentos_processo_bkp_20261021; Type: TABLE DATA; Schema: backup; Owner: postgres
--

COPY backup.pagamentos_processo_bkp_20261021 (id_pagamento, id_processo, numero_pd, data_pagamento, valor_pagamento) FROM stdin;
188	566	2026PD00113	2026-04-08	207.42
189	567	2026PD00117	2026-04-08	69.15
190	557	2026PD00194	2026-05-12	69.15
191	562	2026PD00171	2026-05-08	124.48
192	412	2026PD00069	2026-03-06	69.15
193	487	2026PD00287	2026-07-30	822.94
194	399	2026PD00291	2026-07-30	822.94
195	543	2026PD00055	2026-02-25	207.46
196	387	2026PD00077	2026-03-06	103.73
197	512	2026PD00123	2026-04-08	69.15
198	446	2026PD00047	2026-02-25	204.46
199	444	2026PD00114	2026-04-08	622.39
202	448	2026PD00129	2026-04-08	248.96
203	579	2026PD00414	2026-10-14	207.46
204	580	2026PD00415	2026-10-14	103.73
205	581	2026PD00416	2026-10-14	207.46
206	582	2026PD00417	2026-10-14	80.68
207	583	2026PD00418	2026-10-14	207.46
208	584	2026PD00419	2026-10-14	1075.70
209	585	2026PD00420	2026-10-14	124.48
210	586	2026PD00421	2026-10-14	484.08
211	465	2026PD00403	2026-10-02	69.15
135	465	2026PD00402	2026-10-02	1383.00
180	402	2026PD00076	2026-03-06	138.31
109	405	2026PD00306	2026-08-10	107.57
152	475	2026PD00083	2026-03-06	138.31
90	473	2026PD00402	2026-10-02	103.73
97	419	2026PD00402	2026-10-02	103.73
37	442	2026PD00125	2026-04-08	69.15
175	554	2026PD00126	2026-04-08	69.15
36	492	2026PD00169	2026-05-08	103.73
92	411	2026PD00294	2026-07-30	193.63
59	491	2026PD00223	2026-06-12	69.15
136	482	2026PD00178	2026-05-08	248.96
102	459	2026PD00136	2026-08-10	193.63
72	385	2026PD00122	2026-04-08	69.15
123	423	2026PD00218	2026-06-12	13443.84
165	505	2026PD00068	2026-03-06	248.96
34	415	2026PD00306	2026-08-10	107.57
52	546	2026PD00162	2026-05-08	138.31
141	440	2026PD00306	2026-08-10	107.57
156	500	2026PD00242	2026-06-19	138.31
150	476	2026PD00085	2026-03-06	746.88
8	553	2026PD00368	2026-09-08	248.96
159	461	2026PD00402	2026-10-02	1075.70
11	477	2026PD00078	2026-03-06	207.46
76	402	2026PD00132	2026-04-08	995.84
33	511	2026PD00133	2026-04-08	69.15
186	471	2026PD00167	2026-05-08	107.57
137	481	2026PD00121	2026-04-08	69.15
104	474	2026PD00402	2026-10-02	103.73
19	478	2026PD00051	2026-02-25	138.31
17	449	2026PD00073	2026-03-06	207.46
18	496	2026PD00338	2026-08-13	968.10
81	506	2026PD00174	2026-05-08	248.96
172	441	2026PD00128	2026-04-08	69.15
70	409	2026PD00161	2026-05-08	13070.40
171	403	2026PD00306	2026-08-10	107.57
27	486	2026PD00053	2026-02-25	138.31
55	401	2026PD00292	2026-07-30	207.46
154	542	2026PD00282	2026-07-30	1075.70
87	422	2026PD00172	2026-05-08	1521.41
164	380	2026PD00289	2026-07-30	207.46
113	556	2026PD00168	2026-05-08	138.31
185	377	2026PD00367	2026-09-08	248.96
66	530	2026PD00315	2026-08-10	69.15
119	420	2026PD00297	2026-06-30	1383.00
47	432	2026PD00163	2026-05-08	311.19
100	398	2026PD00240	2026-06-19	138.31
148	485	2026PD00239	2026-06-19	1452.24
160	472	2026PD00260	2026-07-07	12448.00
182	401	2026PD00318	2026-08-10	248.96
110	456	2026PD00370	2026-10-02	248.96
166	517	2026PD00342	2026-08-14	138.31
21	552	2026PD00286	2026-07-30	138.31
58	503	2026PD00083	2026-03-06	207.46
46	437	2026PD00054	2026-02-25	207.46
117	537	2026PD00166	2026-05-08	69.15
12	514	2026PD00083	2026-03-06	69.15
24	414	2026PD00402	2026-10-02	138.31
28	529	2026PD00311	2026-08-10	138.31
179	526	2026PD00288	2026-07-30	138.31
129	527	2026PD00127	2026-04-08	69.15
74	534	2026PD00343	2026-08-14	103.73
153	563	2026PD00314	2026-08-10	69.15
85	485	2026PD00247	2026-06-19	161.36
115	408	2026PD00070	2026-03-06	207.46
45	382	2026PD00163	2026-05-08	103.73
146	531	2026PD00289	2026-07-30	138.31
1	428	2026PD00221	2026-06-12	69.15
9	389	2026PD00048	2026-02-25	207.46
57	513	2026PD00079	2026-03-06	138.31
158	544	2026PD00056	2026-02-24	207.46
35	434	2026PD00115	2026-04-08	968.13
118	498	2026PD00081	2026-03-06	248.96
43	532	2026PD00306	2026-08-10	107.57
2	507	2026PD00402	2026-10-02	103.73
181	371	2026PD00371	2026-09-08	13443.84
125	393	2026PD00334	2026-08-14	103.73
114	431	2026PD00370	2026-09-08	248.96
187	372	2026PD00170	2026-05-08	69.15
176	404	2026PD00306	2026-08-10	107.57
3	445	2026PD00262	2026-07-07	138.30
147	516	2026PD00304	2026-08-05	15560.00
103	467	2026PD00180	2026-05-08	248.96
89	407	2026PD00402	2026-10-02	138.31
79	383	206PD00290	2026-07-30	138.31
22	497	2026PD00292	2026-07-30	207.46
73	523	2026PD00238	2026-06-19	430.28
132	376	2026PD00310	2026-08-10	138.31
10	397	2026PD00128	2026-04-08	138.31
48	499	2026PD00118	2026-04-08	53.78
173	435	2026PD00307	2026-08-10	161.36
53	462	2026PD00059	2026-02-25	871.36
174	539	2026PD00306	2026-08-10	107.57
155	430	2026PD00184	2026-05-08	69.15
49	406	2026PD00082	2026-03-06	138.31
25	390	2026PD00117	2026-04-08	69.15
124	418	2026PD00050	2026-02-25	207.46
128	392	2026PD00127	2026-04-08	69.15
108	417	2026PD00072	2026-03-06	138.31
29	450	2026PD00319	2026-08-10	110.65
5	458	2026PD00306	2026-08-10	107.57
77	468	2026PD00402	2026-10-02	207.46
138	518	2026PD00293	2026-07-30	822.94
86	375	2026PD00057	2026-02-24	207.46
96	436	2026PD00402	2026-10-02	103.73
144	547	2026PD00341	2026-08-14	103.73
134	447	2026PD00176	2026-05-08	138.31
42	394	2026PD00080	2026-03-06	207.46
130	555	2026PD00116	2026-04-08	69.15
62	384	2026/PD00283	2026-07-30	248.96
169	410	2026PD00081	2026-03-06	207.46
7	519	2026PD00284	2026-07-30	248.96
184	548	2026PD00080	2026-03-06	248.96
60	489	2026PD00223	2026-06-12	69.15
84	493	2026PD00261	2026-07-07	138.30
50	538	2026PD00340	2026-08-14	622.40
64	413	2026PD00164	2026-05-08	69.15
131	469	2026PD00129	2026-04-08	248.96
106	504	2026PD00121	2026-04-08	69.15
116	535	2026PD00309	2026-08-10	138.31
162	515	2026PD00369	2026-09-08	248.96
82	560	2026PD00332	2026-08-14	248.96
65	540	2026PD00313	2026-08-10	207.46
30	483	2026PD00243	2026-06-19	124.48
91	490	2026PD00135	2026-04-08	69.15
16	561	2026PD00221	2026-06-12	69.15
112	460	2026PD00131	2026-04-08	80.68
140	495	2026PD00307	2026-08-10	161.36
142	484	2026PD00306	2026-08-10	107.57
157	533	2026PD00306	2026-08-10	107.57
170	454	2026PD00402	2026-10-02	1613.60
26	369	2026PD00245	2026-06-19	69.15
105	550	2026PD00221	2026-06-12	69.15
107	510	2026PD00075	2026-03-06	248.96
163	368	2026PD00288	2026-07-30	138.31
31	525	2026PD00175	2026-05-08	248.96
151	416	2026PD00128	2026-04-08	69.15
178	480	2026PD00307	2026-08-10	161.36
23	508	2026PD00243	0026-06-19	248.96
71	502	2026PD00183	2026-05-08	248.96
168	453	2026PD00285	2026-07-30	248.96
143	373	2026PD00125	2026-04-08	69.15
149	425	2026PD00120	2026-04-08	138.31
95	551	2026PD00179	2026-05-08	207.45
4	400	2026PD00307	2026-08-10	161.36
67	494	2026PD00335	2026-08-13	2097.68
139	433	2026PD00166	2026-05-08	124.48
44	520	2026PD00222	2026-06-12	207.45
40	479	2026PD00306	2026-08-10	107.57
54	438	2026PD00307	2026-08-10	161.36
161	468	2026PD00308	2026-08-10	207.46
177	501	2026PD00306	2026-08-10	107.57
120	559	2026PD00246	2026-06-19	193.63
127	522	2026PD00317	2026-08-10	248.96
32	429	2026PD00049	2026-02-25	207.46
83	396	2026PD00243	2026-06-19	124.48
41	509	2026PD00134	2026-04-08	2489.60
122	521	2026PD00244	2026-06-19	138.31
183	395	2026PD00309	2026-08-10	138.31
13	379	2026PD00337	2026-08-13	138.31
78	549	2026PD00052	2026-02-25	138.31
101	370	2026PD00307	2026-08-10	161.36
99	524	2026PD00124	2026-04-08	248.96
56	545	2026PD00119	2026-04-08	207.46
133	374	2026PD00165	2026-05-08	207.45
61	427	2026PD00071	2026-03-06	248.96
145	386	2026PD00130	2026-04-08	1452.25
15	450	2026PD00220	2026-06-12	138.31
93	378	2026PD00336	2026-08-13	103.73
38	424	2026PD00177	2026-05-08	138.31
68	470	2026PD00307	2026-08-10	161.36
126	391	2026PD00237	2026-06-19	1313.93
167	528	2026PD00173	2026-05-08	537.85
80	426	2026PD00402	2026-10-02	207.46
20	381	2026PD00408	2026-10-07	16804.80
88	463	2026PD00058	2026-02-24	207.46
75	464	2026PD00135	2026-04-08	248.96
39	457	2026PD00296	2026-07-30	248.96
6	541	2026PD00223	2026-06-12	69.15
14	488	2026PD00307	2026-08-10	161.36
94	452	2026PD00241	2026-06-19	138.31
111	558	2026PD00295	2026-07-30	822.94
121	536	2026PD00118	2026-04-08	96.81
98	451	2026PD00074	2026-03-06	248.96
51	466	2026PD00344	2026-08-14	207.46
\.


--
-- Data for Name: pagamentos_processo_bkp_20261021_v2; Type: TABLE DATA; Schema: backup; Owner: postgres
--

COPY backup.pagamentos_processo_bkp_20261021_v2 (id_pagamento, id_processo, numero_pd, data_pagamento, valor_pagamento) FROM stdin;
188	566	2026PD00113	2026-04-08	207.42
189	567	2026PD00117	2026-04-08	69.15
190	557	2026PD00194	2026-05-12	69.15
191	562	2026PD00171	2026-05-08	124.48
192	412	2026PD00069	2026-03-06	69.15
193	487	2026PD00287	2026-07-30	822.94
194	399	2026PD00291	2026-07-30	822.94
195	543	2026PD00055	2026-02-25	207.46
196	387	2026PD00077	2026-03-06	103.73
197	512	2026PD00123	2026-04-08	69.15
198	446	2026PD00047	2026-02-25	204.46
199	444	2026PD00114	2026-04-08	622.39
202	448	2026PD00129	2026-04-08	248.96
203	579	2026PD00414	2026-10-14	207.46
204	580	2026PD00415	2026-10-14	103.73
205	581	2026PD00416	2026-10-14	207.46
206	582	2026PD00417	2026-10-14	80.68
207	583	2026PD00418	2026-10-14	207.46
208	584	2026PD00419	2026-10-14	1075.70
209	585	2026PD00420	2026-10-14	124.48
210	586	2026PD00421	2026-10-14	484.08
211	465	2026PD00403	2026-10-02	69.15
135	465	2026PD00402	2026-10-02	1383.00
180	402	2026PD00076	2026-03-06	138.31
109	405	2026PD00306	2026-08-10	107.57
152	475	2026PD00083	2026-03-06	138.31
90	473	2026PD00402	2026-10-02	103.73
97	419	2026PD00402	2026-10-02	103.73
37	442	2026PD00125	2026-04-08	69.15
175	554	2026PD00126	2026-04-08	69.15
36	492	2026PD00169	2026-05-08	103.73
92	411	2026PD00294	2026-07-30	193.63
59	491	2026PD00223	2026-06-12	69.15
136	482	2026PD00178	2026-05-08	248.96
102	459	2026PD00136	2026-08-10	193.63
72	385	2026PD00122	2026-04-08	69.15
123	423	2026PD00218	2026-06-12	13443.84
165	505	2026PD00068	2026-03-06	248.96
34	415	2026PD00306	2026-08-10	107.57
52	546	2026PD00162	2026-05-08	138.31
141	440	2026PD00306	2026-08-10	107.57
156	500	2026PD00242	2026-06-19	138.31
150	476	2026PD00085	2026-03-06	746.88
8	553	2026PD00368	2026-09-08	248.96
159	461	2026PD00402	2026-10-02	1075.70
11	477	2026PD00078	2026-03-06	207.46
76	402	2026PD00132	2026-04-08	995.84
33	511	2026PD00133	2026-04-08	69.15
186	471	2026PD00167	2026-05-08	107.57
137	481	2026PD00121	2026-04-08	69.15
104	474	2026PD00402	2026-10-02	103.73
19	478	2026PD00051	2026-02-25	138.31
17	449	2026PD00073	2026-03-06	207.46
18	496	2026PD00338	2026-08-13	968.10
81	506	2026PD00174	2026-05-08	248.96
172	441	2026PD00128	2026-04-08	69.15
70	409	2026PD00161	2026-05-08	13070.40
171	403	2026PD00306	2026-08-10	107.57
27	486	2026PD00053	2026-02-25	138.31
55	401	2026PD00292	2026-07-30	207.46
154	542	2026PD00282	2026-07-30	1075.70
87	422	2026PD00172	2026-05-08	1521.41
164	380	2026PD00289	2026-07-30	207.46
113	556	2026PD00168	2026-05-08	138.31
185	377	2026PD00367	2026-09-08	248.96
66	530	2026PD00315	2026-08-10	69.15
119	420	2026PD00297	2026-06-30	1383.00
47	432	2026PD00163	2026-05-08	311.19
100	398	2026PD00240	2026-06-19	138.31
148	485	2026PD00239	2026-06-19	1452.24
160	472	2026PD00260	2026-07-07	12448.00
182	401	2026PD00318	2026-08-10	248.96
110	456	2026PD00370	2026-10-02	248.96
166	517	2026PD00342	2026-08-14	138.31
21	552	2026PD00286	2026-07-30	138.31
58	503	2026PD00083	2026-03-06	207.46
46	437	2026PD00054	2026-02-25	207.46
117	537	2026PD00166	2026-05-08	69.15
12	514	2026PD00083	2026-03-06	69.15
24	414	2026PD00402	2026-10-02	138.31
28	529	2026PD00311	2026-08-10	138.31
179	526	2026PD00288	2026-07-30	138.31
129	527	2026PD00127	2026-04-08	69.15
74	534	2026PD00343	2026-08-14	103.73
153	563	2026PD00314	2026-08-10	69.15
85	485	2026PD00247	2026-06-19	161.36
115	408	2026PD00070	2026-03-06	207.46
45	382	2026PD00163	2026-05-08	103.73
146	531	2026PD00289	2026-07-30	138.31
1	428	2026PD00221	2026-06-12	69.15
9	389	2026PD00048	2026-02-25	207.46
57	513	2026PD00079	2026-03-06	138.31
158	544	2026PD00056	2026-02-24	207.46
35	434	2026PD00115	2026-04-08	968.13
118	498	2026PD00081	2026-03-06	248.96
43	532	2026PD00306	2026-08-10	107.57
2	507	2026PD00402	2026-10-02	103.73
181	371	2026PD00371	2026-09-08	13443.84
125	393	2026PD00334	2026-08-14	103.73
114	431	2026PD00370	2026-09-08	248.96
187	372	2026PD00170	2026-05-08	69.15
176	404	2026PD00306	2026-08-10	107.57
3	445	2026PD00262	2026-07-07	138.30
147	516	2026PD00304	2026-08-05	15560.00
103	467	2026PD00180	2026-05-08	248.96
89	407	2026PD00402	2026-10-02	138.31
79	383	206PD00290	2026-07-30	138.31
22	497	2026PD00292	2026-07-30	207.46
73	523	2026PD00238	2026-06-19	430.28
132	376	2026PD00310	2026-08-10	138.31
10	397	2026PD00128	2026-04-08	138.31
48	499	2026PD00118	2026-04-08	53.78
173	435	2026PD00307	2026-08-10	161.36
53	462	2026PD00059	2026-02-25	871.36
174	539	2026PD00306	2026-08-10	107.57
155	430	2026PD00184	2026-05-08	69.15
49	406	2026PD00082	2026-03-06	138.31
25	390	2026PD00117	2026-04-08	69.15
124	418	2026PD00050	2026-02-25	207.46
128	392	2026PD00127	2026-04-08	69.15
108	417	2026PD00072	2026-03-06	138.31
5	458	2026PD00306	2026-08-10	107.57
77	468	2026PD00402	2026-10-02	207.46
138	518	2026PD00293	2026-07-30	822.94
86	375	2026PD00057	2026-02-24	207.46
96	436	2026PD00402	2026-10-02	103.73
144	547	2026PD00341	2026-08-14	103.73
134	447	2026PD00176	2026-05-08	138.31
42	394	2026PD00080	2026-03-06	207.46
130	555	2026PD00116	2026-04-08	69.15
62	384	2026/PD00283	2026-07-30	248.96
169	410	2026PD00081	2026-03-06	207.46
7	519	2026PD00284	2026-07-30	248.96
184	548	2026PD00080	2026-03-06	248.96
60	489	2026PD00223	2026-06-12	69.15
84	493	2026PD00261	2026-07-07	138.30
50	538	2026PD00340	2026-08-14	622.40
64	413	2026PD00164	2026-05-08	69.15
131	469	2026PD00129	2026-04-08	248.96
106	504	2026PD00121	2026-04-08	69.15
116	535	2026PD00309	2026-08-10	138.31
162	515	2026PD00369	2026-09-08	248.96
82	560	2026PD00332	2026-08-14	248.96
65	540	2026PD00313	2026-08-10	207.46
30	483	2026PD00243	2026-06-19	124.48
91	490	2026PD00135	2026-04-08	69.15
16	561	2026PD00221	2026-06-12	69.15
112	460	2026PD00131	2026-04-08	80.68
140	495	2026PD00307	2026-08-10	161.36
142	484	2026PD00306	2026-08-10	107.57
157	533	2026PD00306	2026-08-10	107.57
170	454	2026PD00402	2026-10-02	1613.60
26	369	2026PD00245	2026-06-19	69.15
105	550	2026PD00221	2026-06-12	69.15
107	510	2026PD00075	2026-03-06	248.96
163	368	2026PD00288	2026-07-30	138.31
31	525	2026PD00175	2026-05-08	248.96
151	416	2026PD00128	2026-04-08	69.15
178	480	2026PD00307	2026-08-10	161.36
23	508	2026PD00243	0026-06-19	248.96
71	502	2026PD00183	2026-05-08	248.96
168	453	2026PD00285	2026-07-30	248.96
143	373	2026PD00125	2026-04-08	69.15
149	425	2026PD00120	2026-04-08	138.31
95	551	2026PD00179	2026-05-08	207.45
4	400	2026PD00307	2026-08-10	161.36
67	494	2026PD00335	2026-08-13	2097.68
139	433	2026PD00166	2026-05-08	124.48
44	520	2026PD00222	2026-06-12	207.45
40	479	2026PD00306	2026-08-10	107.57
54	438	2026PD00307	2026-08-10	161.36
161	468	2026PD00308	2026-08-10	207.46
177	501	2026PD00306	2026-08-10	107.57
120	559	2026PD00246	2026-06-19	193.63
127	522	2026PD00317	2026-08-10	248.96
32	429	2026PD00049	2026-02-25	207.46
83	396	2026PD00243	2026-06-19	124.48
41	509	2026PD00134	2026-04-08	2489.60
122	521	2026PD00244	2026-06-19	138.31
183	395	2026PD00309	2026-08-10	138.31
13	379	2026PD00337	2026-08-13	138.31
78	549	2026PD00052	2026-02-25	138.31
101	370	2026PD00307	2026-08-10	161.36
99	524	2026PD00124	2026-04-08	248.96
56	545	2026PD00119	2026-04-08	207.46
133	374	2026PD00165	2026-05-08	207.45
61	427	2026PD00071	2026-03-06	248.96
145	386	2026PD00130	2026-04-08	1452.25
29	450	2026PD00319	2026-08-10	110.95
15	450	2026PD00220	2026-06-12	138.31
93	378	2026PD00336	2026-08-13	103.73
38	424	2026PD00177	2026-05-08	138.31
68	470	2026PD00307	2026-08-10	161.36
126	391	2026PD00237	2026-06-19	1313.93
167	528	2026PD00173	2026-05-08	537.85
80	426	2026PD00402	2026-10-02	207.46
20	381	2026PD00408	2026-10-07	16804.80
88	463	2026PD00058	2026-02-24	207.46
75	464	2026PD00135	2026-04-08	248.96
39	457	2026PD00296	2026-07-30	248.96
6	541	2026PD00223	2026-06-12	69.15
14	488	2026PD00307	2026-08-10	161.36
94	452	2026PD00241	2026-06-19	138.31
111	558	2026PD00295	2026-07-30	822.94
121	536	2026PD00118	2026-04-08	96.81
98	451	2026PD00074	2026-03-06	248.96
51	466	2026PD00344	2026-08-14	207.46
\.


--
-- Data for Name: pagamentos_processo_bkp_auditoria; Type: TABLE DATA; Schema: backup; Owner: postgres
--

COPY backup.pagamentos_processo_bkp_auditoria (id_pagamento, id_processo, numero_pd, data_pagamento, valor_pagamento, id_pd) FROM stdin;
188	566	2026PD00113	2026-04-08	207.42	1
189	567	2026PD00117	2026-04-08	69.15	118
190	557	2026PD00194	2026-05-12	69.15	3
191	562	2026PD00171	2026-05-08	124.48	4
192	412	2026PD00069	2026-03-06	69.15	5
193	487	2026PD00287	2026-07-30	822.94	6
194	399	2026PD00291	2026-07-30	822.94	7
195	543	2026PD00055	2026-02-25	207.46	8
196	387	2026PD00077	2026-03-06	103.73	9
197	512	2026PD00123	2026-04-08	69.15	10
198	446	2026PD00047	2026-02-25	204.46	11
199	444	2026PD00114	2026-04-08	622.39	12
202	448	2026PD00129	2026-04-08	248.96	140
163	368	2026PD00288	2026-07-30	138.31	157
31	525	2026PD00175	2026-05-08	248.96	158
151	416	2026PD00128	2026-04-08	69.15	159
178	480	2026PD00307	2026-08-10	161.36	202
23	508	2026PD00243	0026-06-19	248.96	178
71	502	2026PD00183	2026-05-08	248.96	162
168	453	2026PD00285	2026-07-30	248.96	163
143	373	2026PD00125	2026-04-08	69.15	164
149	425	2026PD00120	2026-04-08	138.31	165
95	551	2026PD00179	2026-05-08	207.45	166
4	400	2026PD00307	2026-08-10	161.36	202
67	494	2026PD00335	2026-08-13	2097.68	168
139	433	2026PD00166	2026-05-08	124.48	169
44	520	2026PD00222	2026-06-12	207.45	170
40	479	2026PD00306	2026-08-10	107.57	174
54	438	2026PD00307	2026-08-10	161.36	202
161	468	2026PD00308	2026-08-10	207.46	173
177	501	2026PD00306	2026-08-10	107.57	174
120	559	2026PD00246	2026-06-19	193.63	175
127	522	2026PD00317	2026-08-10	248.96	176
32	429	2026PD00049	2026-02-25	207.46	177
83	396	2026PD00243	2026-06-19	124.48	178
41	509	2026PD00134	2026-04-08	2489.60	179
122	521	2026PD00244	2026-06-19	138.31	180
183	395	2026PD00309	2026-08-10	138.31	181
13	379	2026PD00337	2026-08-13	138.31	182
78	549	2026PD00052	2026-02-25	138.31	183
101	370	2026PD00307	2026-08-10	161.36	202
99	524	2026PD00124	2026-04-08	248.96	185
56	545	2026PD00119	2026-04-08	207.46	186
133	374	2026PD00165	2026-05-08	207.45	187
61	427	2026PD00071	2026-03-06	248.96	188
145	386	2026PD00130	2026-04-08	1452.25	189
29	450	2026PD00319	2026-08-10	110.95	122
15	450	2026PD00220	2026-06-12	138.31	190
93	378	2026PD00336	2026-08-13	103.73	191
38	424	2026PD00177	2026-05-08	138.31	192
68	470	2026PD00307	2026-08-10	161.36	202
126	391	2026PD00237	2026-06-19	1313.93	194
167	528	2026PD00173	2026-05-08	537.85	195
80	426	2026PD00402	2026-10-02	207.46	196
20	381	2026PD00408	2026-10-07	16804.80	197
88	463	2026PD00058	2026-02-24	207.46	198
75	464	2026PD00135	2026-04-08	248.96	199
39	457	2026PD00296	2026-07-30	248.96	200
6	541	2026PD00223	2026-06-12	69.15	201
14	488	2026PD00307	2026-08-10	161.36	202
94	452	2026PD00241	2026-06-19	138.31	203
111	558	2026PD00295	2026-07-30	822.94	204
121	536	2026PD00118	2026-04-08	96.81	205
98	451	2026PD00074	2026-03-06	248.96	206
51	466	2026PD00344	2026-08-14	207.46	207
203	579	2026PD00414	2026-10-14	207.46	14
204	580	2026PD00415	2026-10-14	103.73	15
205	581	2026PD00416	2026-10-14	207.46	16
206	582	2026PD00417	2026-10-14	80.68	17
207	583	2026PD00418	2026-10-14	207.46	18
208	584	2026PD00419	2026-10-14	1075.70	19
209	585	2026PD00420	2026-10-14	124.48	20
210	586	2026PD00421	2026-10-14	484.08	21
211	465	2026PD00403	2026-10-02	69.15	22
135	465	2026PD00402	2026-10-02	1383.00	196
180	402	2026PD00076	2026-03-06	138.31	24
109	405	2026PD00306	2026-08-10	107.57	174
152	475	2026PD00083	2026-03-06	138.31	79
90	473	2026PD00402	2026-10-02	103.73	196
97	419	2026PD00402	2026-10-02	103.73	196
37	442	2026PD00125	2026-04-08	69.15	164
175	554	2026PD00126	2026-04-08	69.15	30
36	492	2026PD00169	2026-05-08	103.73	31
92	411	2026PD00294	2026-07-30	193.63	32
59	491	2026PD00223	2026-06-12	69.15	201
136	482	2026PD00178	2026-05-08	248.96	34
102	459	2026PD00136	2026-08-10	193.63	35
72	385	2026PD00122	2026-04-08	69.15	36
123	423	2026PD00218	2026-06-12	13443.84	37
165	505	2026PD00068	2026-03-06	248.96	38
34	415	2026PD00306	2026-08-10	107.57	174
52	546	2026PD00162	2026-05-08	138.31	40
141	440	2026PD00306	2026-08-10	107.57	174
156	500	2026PD00242	2026-06-19	138.31	42
150	476	2026PD00085	2026-03-06	746.88	43
8	553	2026PD00368	2026-09-08	248.96	44
159	461	2026PD00402	2026-10-02	1075.70	196
11	477	2026PD00078	2026-03-06	207.46	46
76	402	2026PD00132	2026-04-08	995.84	47
33	511	2026PD00133	2026-04-08	69.15	48
186	471	2026PD00167	2026-05-08	107.57	49
137	481	2026PD00121	2026-04-08	69.15	141
104	474	2026PD00402	2026-10-02	103.73	196
19	478	2026PD00051	2026-02-25	138.31	52
17	449	2026PD00073	2026-03-06	207.46	53
18	496	2026PD00338	2026-08-13	968.10	54
81	506	2026PD00174	2026-05-08	248.96	55
172	441	2026PD00128	2026-04-08	69.15	159
70	409	2026PD00161	2026-05-08	13070.40	57
171	403	2026PD00306	2026-08-10	107.57	174
27	486	2026PD00053	2026-02-25	138.31	59
55	401	2026PD00292	2026-07-30	207.46	108
154	542	2026PD00282	2026-07-30	1075.70	61
87	422	2026PD00172	2026-05-08	1521.41	62
164	380	2026PD00289	2026-07-30	207.46	89
110	456	2026PD00370	2026-10-02	248.96	100
113	556	2026PD00168	2026-05-08	138.31	64
185	377	2026PD00367	2026-09-08	248.96	65
66	530	2026PD00315	2026-08-10	69.15	66
119	420	2026PD00297	2026-06-30	1383.00	67
47	432	2026PD00163	2026-05-08	311.19	88
100	398	2026PD00240	2026-06-19	138.31	69
148	485	2026PD00239	2026-06-19	1452.24	70
160	472	2026PD00260	2026-07-07	12448.00	71
182	401	2026PD00318	2026-08-10	248.96	72
166	517	2026PD00342	2026-08-14	138.31	74
21	552	2026PD00286	2026-07-30	138.31	75
58	503	2026PD00083	2026-03-06	207.46	79
46	437	2026PD00054	2026-02-25	207.46	77
117	537	2026PD00166	2026-05-08	69.15	169
12	514	2026PD00083	2026-03-06	69.15	79
24	414	2026PD00402	2026-10-02	138.31	196
28	529	2026PD00311	2026-08-10	138.31	81
179	526	2026PD00288	2026-07-30	138.31	157
129	527	2026PD00127	2026-04-08	69.15	120
74	534	2026PD00343	2026-08-14	103.73	84
153	563	2026PD00314	2026-08-10	69.15	85
85	485	2026PD00247	2026-06-19	161.36	86
115	408	2026PD00070	2026-03-06	207.46	87
45	382	2026PD00163	2026-05-08	103.73	88
146	531	2026PD00289	2026-07-30	138.31	89
1	428	2026PD00221	2026-06-12	69.15	155
9	389	2026PD00048	2026-02-25	207.46	91
57	513	2026PD00079	2026-03-06	138.31	92
158	544	2026PD00056	2026-02-24	207.46	93
35	434	2026PD00115	2026-04-08	968.13	94
118	498	2026PD00081	2026-03-06	248.96	133
43	532	2026PD00306	2026-08-10	107.57	174
2	507	2026PD00402	2026-10-02	103.73	196
181	371	2026PD00371	2026-09-08	13443.84	98
125	393	2026PD00334	2026-08-14	103.73	99
114	431	2026PD00370	2026-09-08	248.96	100
187	372	2026PD00170	2026-05-08	69.15	101
176	404	2026PD00306	2026-08-10	107.57	174
3	445	2026PD00262	2026-07-07	138.30	103
147	516	2026PD00304	2026-08-05	15560.00	104
103	467	2026PD00180	2026-05-08	248.96	105
89	407	2026PD00402	2026-10-02	138.31	196
79	383	206PD00290	2026-07-30	138.31	107
22	497	2026PD00292	2026-07-30	207.46	108
73	523	2026PD00238	2026-06-19	430.28	109
132	376	2026PD00310	2026-08-10	138.31	110
10	397	2026PD00128	2026-04-08	138.31	159
48	499	2026PD00118	2026-04-08	53.78	205
173	435	2026PD00307	2026-08-10	161.36	202
53	462	2026PD00059	2026-02-25	871.36	114
174	539	2026PD00306	2026-08-10	107.57	174
155	430	2026PD00184	2026-05-08	69.15	116
49	406	2026PD00082	2026-03-06	138.31	117
25	390	2026PD00117	2026-04-08	69.15	118
124	418	2026PD00050	2026-02-25	207.46	119
128	392	2026PD00127	2026-04-08	69.15	120
108	417	2026PD00072	2026-03-06	138.31	121
5	458	2026PD00306	2026-08-10	107.57	174
77	468	2026PD00402	2026-10-02	207.46	196
138	518	2026PD00293	2026-07-30	822.94	125
86	375	2026PD00057	2026-02-24	207.46	126
96	436	2026PD00402	2026-10-02	103.73	196
144	547	2026PD00341	2026-08-14	103.73	128
134	447	2026PD00176	2026-05-08	138.31	129
42	394	2026PD00080	2026-03-06	207.46	135
130	555	2026PD00116	2026-04-08	69.15	131
62	384	2026/PD00283	2026-07-30	248.96	132
169	410	2026PD00081	2026-03-06	207.46	133
7	519	2026PD00284	2026-07-30	248.96	134
184	548	2026PD00080	2026-03-06	248.96	135
60	489	2026PD00223	2026-06-12	69.15	201
84	493	2026PD00261	2026-07-07	138.30	137
50	538	2026PD00340	2026-08-14	622.40	138
64	413	2026PD00164	2026-05-08	69.15	139
131	469	2026PD00129	2026-04-08	248.96	140
106	504	2026PD00121	2026-04-08	69.15	141
116	535	2026PD00309	2026-08-10	138.31	181
162	515	2026PD00369	2026-09-08	248.96	143
82	560	2026PD00332	2026-08-14	248.96	144
65	540	2026PD00313	2026-08-10	207.46	145
30	483	2026PD00243	2026-06-19	124.48	178
91	490	2026PD00135	2026-04-08	69.15	199
16	561	2026PD00221	2026-06-12	69.15	155
112	460	2026PD00131	2026-04-08	80.68	149
140	495	2026PD00307	2026-08-10	161.36	202
142	484	2026PD00306	2026-08-10	107.57	174
157	533	2026PD00306	2026-08-10	107.57	174
170	454	2026PD00402	2026-10-02	1613.60	196
26	369	2026PD00245	2026-06-19	69.15	154
105	550	2026PD00221	2026-06-12	69.15	155
107	510	2026PD00075	2026-03-06	248.96	156
\.


--
-- Data for Name: pds_bkp_20261021_v2; Type: TABLE DATA; Schema: backup; Owner: postgres
--

COPY backup.pds_bkp_20261021_v2 (id_pd, numero_pd, data_pagamento, valor_pagamento) FROM stdin;
1	2026PD00113	2026-04-08	207.42
2	2026PD00117	2026-04-08	69.15
3	2026PD00194	2026-05-12	69.15
4	2026PD00171	2026-05-08	124.48
5	2026PD00069	2026-03-06	69.15
6	2026PD00287	2026-07-30	822.94
7	2026PD00291	2026-07-30	822.94
8	2026PD00055	2026-02-25	207.46
9	2026PD00077	2026-03-06	103.73
10	2026PD00123	2026-04-08	69.15
11	2026PD00047	2026-02-25	204.46
12	2026PD00114	2026-04-08	622.39
13	2026PD00129	2026-04-08	248.96
14	2026PD00414	2026-10-14	207.46
15	2026PD00415	2026-10-14	103.73
16	2026PD00416	2026-10-14	207.46
17	2026PD00417	2026-10-14	80.68
18	2026PD00418	2026-10-14	207.46
19	2026PD00419	2026-10-14	1075.70
20	2026PD00420	2026-10-14	124.48
21	2026PD00421	2026-10-14	484.08
22	2026PD00403	2026-10-02	69.15
23	2026PD00402	2026-10-02	1383.00
24	2026PD00076	2026-03-06	138.31
25	2026PD00306	2026-08-10	107.57
26	2026PD00083	2026-03-06	138.31
27	2026PD00402	2026-10-02	103.73
28	2026PD00402	2026-10-02	103.73
29	2026PD00125	2026-04-08	69.15
30	2026PD00126	2026-04-08	69.15
31	2026PD00169	2026-05-08	103.73
32	2026PD00294	2026-07-30	193.63
33	2026PD00223	2026-06-12	69.15
34	2026PD00178	2026-05-08	248.96
35	2026PD00136	2026-08-10	193.63
36	2026PD00122	2026-04-08	69.15
37	2026PD00218	2026-06-12	13443.84
38	2026PD00068	2026-03-06	248.96
39	2026PD00306	2026-08-10	107.57
40	2026PD00162	2026-05-08	138.31
41	2026PD00306	2026-08-10	107.57
42	2026PD00242	2026-06-19	138.31
43	2026PD00085	2026-03-06	746.88
44	2026PD00368	2026-09-08	248.96
45	2026PD00402	2026-10-02	1075.70
46	2026PD00078	2026-03-06	207.46
47	2026PD00132	2026-04-08	995.84
48	2026PD00133	2026-04-08	69.15
49	2026PD00167	2026-05-08	107.57
50	2026PD00121	2026-04-08	69.15
51	2026PD00402	2026-10-02	103.73
52	2026PD00051	2026-02-25	138.31
53	2026PD00073	2026-03-06	207.46
54	2026PD00338	2026-08-13	968.10
55	2026PD00174	2026-05-08	248.96
56	2026PD00128	2026-04-08	69.15
57	2026PD00161	2026-05-08	13070.40
58	2026PD00306	2026-08-10	107.57
59	2026PD00053	2026-02-25	138.31
60	2026PD00292	2026-07-30	207.46
61	2026PD00282	2026-07-30	1075.70
62	2026PD00172	2026-05-08	1521.41
63	2026PD00289	2026-07-30	207.46
64	2026PD00168	2026-05-08	138.31
65	2026PD00367	2026-09-08	248.96
66	2026PD00315	2026-08-10	69.15
67	2026PD00297	2026-06-30	1383.00
68	2026PD00163	2026-05-08	311.19
69	2026PD00240	2026-06-19	138.31
70	2026PD00239	2026-06-19	1452.24
71	2026PD00260	2026-07-07	12448.00
72	2026PD00318	2026-08-10	248.96
73	2026PD00370	2026-10-02	248.96
74	2026PD00342	2026-08-14	138.31
75	2026PD00286	2026-07-30	138.31
76	2026PD00083	2026-03-06	207.46
77	2026PD00054	2026-02-25	207.46
78	2026PD00166	2026-05-08	69.15
79	2026PD00083	2026-03-06	69.15
80	2026PD00402	2026-10-02	138.31
81	2026PD00311	2026-08-10	138.31
82	2026PD00288	2026-07-30	138.31
83	2026PD00127	2026-04-08	69.15
84	2026PD00343	2026-08-14	103.73
85	2026PD00314	2026-08-10	69.15
86	2026PD00247	2026-06-19	161.36
87	2026PD00070	2026-03-06	207.46
88	2026PD00163	2026-05-08	103.73
89	2026PD00289	2026-07-30	138.31
90	2026PD00221	2026-06-12	69.15
91	2026PD00048	2026-02-25	207.46
92	2026PD00079	2026-03-06	138.31
93	2026PD00056	2026-02-24	207.46
94	2026PD00115	2026-04-08	968.13
95	2026PD00081	2026-03-06	248.96
96	2026PD00306	2026-08-10	107.57
97	2026PD00402	2026-10-02	103.73
98	2026PD00371	2026-09-08	13443.84
99	2026PD00334	2026-08-14	103.73
100	2026PD00370	2026-09-08	248.96
101	2026PD00170	2026-05-08	69.15
102	2026PD00306	2026-08-10	107.57
103	2026PD00262	2026-07-07	138.30
104	2026PD00304	2026-08-05	15560.00
105	2026PD00180	2026-05-08	248.96
106	2026PD00402	2026-10-02	138.31
107	206PD00290	2026-07-30	138.31
108	2026PD00292	2026-07-30	207.46
109	2026PD00238	2026-06-19	430.28
110	2026PD00310	2026-08-10	138.31
111	2026PD00128	2026-04-08	138.31
112	2026PD00118	2026-04-08	53.78
113	2026PD00307	2026-08-10	161.36
114	2026PD00059	2026-02-25	871.36
115	2026PD00306	2026-08-10	107.57
116	2026PD00184	2026-05-08	69.15
117	2026PD00082	2026-03-06	138.31
118	2026PD00117	2026-04-08	69.15
119	2026PD00050	2026-02-25	207.46
120	2026PD00127	2026-04-08	69.15
121	2026PD00072	2026-03-06	138.31
122	2026PD00319	2026-08-10	110.65
123	2026PD00306	2026-08-10	107.57
124	2026PD00402	2026-10-02	207.46
125	2026PD00293	2026-07-30	822.94
126	2026PD00057	2026-02-24	207.46
127	2026PD00402	2026-10-02	103.73
128	2026PD00341	2026-08-14	103.73
129	2026PD00176	2026-05-08	138.31
130	2026PD00080	2026-03-06	207.46
131	2026PD00116	2026-04-08	69.15
132	2026/PD00283	2026-07-30	248.96
133	2026PD00081	2026-03-06	207.46
134	2026PD00284	2026-07-30	248.96
135	2026PD00080	2026-03-06	248.96
136	2026PD00223	2026-06-12	69.15
137	2026PD00261	2026-07-07	138.30
138	2026PD00340	2026-08-14	622.40
139	2026PD00164	2026-05-08	69.15
140	2026PD00129	2026-04-08	248.96
141	2026PD00121	2026-04-08	69.15
142	2026PD00309	2026-08-10	138.31
143	2026PD00369	2026-09-08	248.96
144	2026PD00332	2026-08-14	248.96
145	2026PD00313	2026-08-10	207.46
146	2026PD00243	2026-06-19	124.48
147	2026PD00135	2026-04-08	69.15
148	2026PD00221	2026-06-12	69.15
149	2026PD00131	2026-04-08	80.68
150	2026PD00307	2026-08-10	161.36
151	2026PD00306	2026-08-10	107.57
152	2026PD00306	2026-08-10	107.57
153	2026PD00402	2026-10-02	1613.60
154	2026PD00245	2026-06-19	69.15
155	2026PD00221	2026-06-12	69.15
156	2026PD00075	2026-03-06	248.96
157	2026PD00288	2026-07-30	138.31
158	2026PD00175	2026-05-08	248.96
159	2026PD00128	2026-04-08	69.15
160	2026PD00307	2026-08-10	161.36
161	2026PD00243	0026-06-19	248.96
162	2026PD00183	2026-05-08	248.96
163	2026PD00285	2026-07-30	248.96
164	2026PD00125	2026-04-08	69.15
165	2026PD00120	2026-04-08	138.31
166	2026PD00179	2026-05-08	207.45
167	2026PD00307	2026-08-10	161.36
168	2026PD00335	2026-08-13	2097.68
169	2026PD00166	2026-05-08	124.48
170	2026PD00222	2026-06-12	207.45
171	2026PD00306	2026-08-10	107.57
172	2026PD00307	2026-08-10	161.36
173	2026PD00308	2026-08-10	207.46
174	2026PD00306	2026-08-10	107.57
175	2026PD00246	2026-06-19	193.63
176	2026PD00317	2026-08-10	248.96
177	2026PD00049	2026-02-25	207.46
178	2026PD00243	2026-06-19	124.48
179	2026PD00134	2026-04-08	2489.60
180	2026PD00244	2026-06-19	138.31
181	2026PD00309	2026-08-10	138.31
182	2026PD00337	2026-08-13	138.31
183	2026PD00052	2026-02-25	138.31
184	2026PD00307	2026-08-10	161.36
185	2026PD00124	2026-04-08	248.96
186	2026PD00119	2026-04-08	207.46
187	2026PD00165	2026-05-08	207.45
188	2026PD00071	2026-03-06	248.96
189	2026PD00130	2026-04-08	1452.25
190	2026PD00220	2026-06-12	138.31
191	2026PD00336	2026-08-13	103.73
192	2026PD00177	2026-05-08	138.31
193	2026PD00307	2026-08-10	161.36
194	2026PD00237	2026-06-19	1313.93
195	2026PD00173	2026-05-08	537.85
196	2026PD00402	2026-10-02	207.46
197	2026PD00408	2026-10-07	16804.80
198	2026PD00058	2026-02-24	207.46
199	2026PD00135	2026-04-08	248.96
200	2026PD00296	2026-07-30	248.96
201	2026PD00223	2026-06-12	69.15
202	2026PD00307	2026-08-10	161.36
203	2026PD00241	2026-06-19	138.31
204	2026PD00295	2026-07-30	822.94
205	2026PD00118	2026-04-08	96.81
206	2026PD00074	2026-03-06	248.96
207	2026PD00344	2026-08-14	207.46
\.


--
-- Data for Name: pds_bkp_antes_limpeza; Type: TABLE DATA; Schema: backup; Owner: postgres
--

COPY backup.pds_bkp_antes_limpeza (id_pd, numero_pd, data_pagamento, valor_pagamento) FROM stdin;
1	2026PD00113	2026-04-08	207.42
2	2026PD00117	2026-04-08	69.15
3	2026PD00194	2026-05-12	69.15
4	2026PD00171	2026-05-08	124.48
5	2026PD00069	2026-03-06	69.15
6	2026PD00287	2026-07-30	822.94
7	2026PD00291	2026-07-30	822.94
8	2026PD00055	2026-02-25	207.46
9	2026PD00077	2026-03-06	103.73
10	2026PD00123	2026-04-08	69.15
11	2026PD00047	2026-02-25	204.46
12	2026PD00114	2026-04-08	622.39
13	2026PD00129	2026-04-08	248.96
14	2026PD00414	2026-10-14	207.46
15	2026PD00415	2026-10-14	103.73
16	2026PD00416	2026-10-14	207.46
17	2026PD00417	2026-10-14	80.68
18	2026PD00418	2026-10-14	207.46
19	2026PD00419	2026-10-14	1075.70
20	2026PD00420	2026-10-14	124.48
21	2026PD00421	2026-10-14	484.08
22	2026PD00403	2026-10-02	69.15
23	2026PD00402	2026-10-02	1383.00
24	2026PD00076	2026-03-06	138.31
25	2026PD00306	2026-08-10	107.57
26	2026PD00083	2026-03-06	138.31
27	2026PD00402	2026-10-02	103.73
28	2026PD00402	2026-10-02	103.73
29	2026PD00125	2026-04-08	69.15
30	2026PD00126	2026-04-08	69.15
31	2026PD00169	2026-05-08	103.73
32	2026PD00294	2026-07-30	193.63
33	2026PD00223	2026-06-12	69.15
34	2026PD00178	2026-05-08	248.96
35	2026PD00136	2026-08-10	193.63
36	2026PD00122	2026-04-08	69.15
37	2026PD00218	2026-06-12	13443.84
38	2026PD00068	2026-03-06	248.96
39	2026PD00306	2026-08-10	107.57
40	2026PD00162	2026-05-08	138.31
41	2026PD00306	2026-08-10	107.57
42	2026PD00242	2026-06-19	138.31
43	2026PD00085	2026-03-06	746.88
44	2026PD00368	2026-09-08	248.96
45	2026PD00402	2026-10-02	1075.70
46	2026PD00078	2026-03-06	207.46
47	2026PD00132	2026-04-08	995.84
48	2026PD00133	2026-04-08	69.15
49	2026PD00167	2026-05-08	107.57
50	2026PD00121	2026-04-08	69.15
51	2026PD00402	2026-10-02	103.73
52	2026PD00051	2026-02-25	138.31
53	2026PD00073	2026-03-06	207.46
54	2026PD00338	2026-08-13	968.10
55	2026PD00174	2026-05-08	248.96
56	2026PD00128	2026-04-08	69.15
57	2026PD00161	2026-05-08	13070.40
58	2026PD00306	2026-08-10	107.57
59	2026PD00053	2026-02-25	138.31
60	2026PD00292	2026-07-30	207.46
61	2026PD00282	2026-07-30	1075.70
62	2026PD00172	2026-05-08	1521.41
63	2026PD00289	2026-07-30	207.46
64	2026PD00168	2026-05-08	138.31
65	2026PD00367	2026-09-08	248.96
66	2026PD00315	2026-08-10	69.15
67	2026PD00297	2026-06-30	1383.00
68	2026PD00163	2026-05-08	311.19
69	2026PD00240	2026-06-19	138.31
70	2026PD00239	2026-06-19	1452.24
71	2026PD00260	2026-07-07	12448.00
72	2026PD00318	2026-08-10	248.96
74	2026PD00342	2026-08-14	138.31
75	2026PD00286	2026-07-30	138.31
76	2026PD00083	2026-03-06	207.46
77	2026PD00054	2026-02-25	207.46
78	2026PD00166	2026-05-08	69.15
79	2026PD00083	2026-03-06	69.15
80	2026PD00402	2026-10-02	138.31
81	2026PD00311	2026-08-10	138.31
82	2026PD00288	2026-07-30	138.31
83	2026PD00127	2026-04-08	69.15
84	2026PD00343	2026-08-14	103.73
85	2026PD00314	2026-08-10	69.15
86	2026PD00247	2026-06-19	161.36
87	2026PD00070	2026-03-06	207.46
88	2026PD00163	2026-05-08	103.73
89	2026PD00289	2026-07-30	138.31
90	2026PD00221	2026-06-12	69.15
91	2026PD00048	2026-02-25	207.46
92	2026PD00079	2026-03-06	138.31
93	2026PD00056	2026-02-24	207.46
94	2026PD00115	2026-04-08	968.13
95	2026PD00081	2026-03-06	248.96
96	2026PD00306	2026-08-10	107.57
97	2026PD00402	2026-10-02	103.73
98	2026PD00371	2026-09-08	13443.84
99	2026PD00334	2026-08-14	103.73
100	2026PD00370	2026-09-08	248.96
101	2026PD00170	2026-05-08	69.15
102	2026PD00306	2026-08-10	107.57
103	2026PD00262	2026-07-07	138.30
104	2026PD00304	2026-08-05	15560.00
105	2026PD00180	2026-05-08	248.96
106	2026PD00402	2026-10-02	138.31
108	2026PD00292	2026-07-30	207.46
109	2026PD00238	2026-06-19	430.28
110	2026PD00310	2026-08-10	138.31
111	2026PD00128	2026-04-08	138.31
112	2026PD00118	2026-04-08	53.78
113	2026PD00307	2026-08-10	161.36
114	2026PD00059	2026-02-25	871.36
115	2026PD00306	2026-08-10	107.57
116	2026PD00184	2026-05-08	69.15
117	2026PD00082	2026-03-06	138.31
118	2026PD00117	2026-04-08	69.15
119	2026PD00050	2026-02-25	207.46
120	2026PD00127	2026-04-08	69.15
121	2026PD00072	2026-03-06	138.31
122	2026PD00319	2026-08-10	110.65
123	2026PD00306	2026-08-10	107.57
124	2026PD00402	2026-10-02	207.46
125	2026PD00293	2026-07-30	822.94
126	2026PD00057	2026-02-24	207.46
127	2026PD00402	2026-10-02	103.73
128	2026PD00341	2026-08-14	103.73
129	2026PD00176	2026-05-08	138.31
130	2026PD00080	2026-03-06	207.46
131	2026PD00116	2026-04-08	69.15
133	2026PD00081	2026-03-06	207.46
134	2026PD00284	2026-07-30	248.96
135	2026PD00080	2026-03-06	248.96
132	2026PD00283	2026-07-30	248.96
136	2026PD00223	2026-06-12	69.15
137	2026PD00261	2026-07-07	138.30
138	2026PD00340	2026-08-14	622.40
139	2026PD00164	2026-05-08	69.15
140	2026PD00129	2026-04-08	248.96
141	2026PD00121	2026-04-08	69.15
142	2026PD00309	2026-08-10	138.31
143	2026PD00369	2026-09-08	248.96
144	2026PD00332	2026-08-14	248.96
145	2026PD00313	2026-08-10	207.46
146	2026PD00243	2026-06-19	124.48
147	2026PD00135	2026-04-08	69.15
148	2026PD00221	2026-06-12	69.15
149	2026PD00131	2026-04-08	80.68
150	2026PD00307	2026-08-10	161.36
151	2026PD00306	2026-08-10	107.57
152	2026PD00306	2026-08-10	107.57
153	2026PD00402	2026-10-02	1613.60
154	2026PD00245	2026-06-19	69.15
155	2026PD00221	2026-06-12	69.15
156	2026PD00075	2026-03-06	248.96
157	2026PD00288	2026-07-30	138.31
158	2026PD00175	2026-05-08	248.96
159	2026PD00128	2026-04-08	69.15
160	2026PD00307	2026-08-10	161.36
162	2026PD00183	2026-05-08	248.96
163	2026PD00285	2026-07-30	248.96
164	2026PD00125	2026-04-08	69.15
165	2026PD00120	2026-04-08	138.31
166	2026PD00179	2026-05-08	207.45
167	2026PD00307	2026-08-10	161.36
168	2026PD00335	2026-08-13	2097.68
169	2026PD00166	2026-05-08	124.48
170	2026PD00222	2026-06-12	207.45
171	2026PD00306	2026-08-10	107.57
172	2026PD00307	2026-08-10	161.36
173	2026PD00308	2026-08-10	207.46
174	2026PD00306	2026-08-10	107.57
175	2026PD00246	2026-06-19	193.63
176	2026PD00317	2026-08-10	248.96
177	2026PD00049	2026-02-25	207.46
178	2026PD00243	2026-06-19	124.48
179	2026PD00134	2026-04-08	2489.60
180	2026PD00244	2026-06-19	138.31
181	2026PD00309	2026-08-10	138.31
182	2026PD00337	2026-08-13	138.31
183	2026PD00052	2026-02-25	138.31
184	2026PD00307	2026-08-10	161.36
185	2026PD00124	2026-04-08	248.96
186	2026PD00119	2026-04-08	207.46
187	2026PD00165	2026-05-08	207.45
188	2026PD00071	2026-03-06	248.96
189	2026PD00130	2026-04-08	1452.25
190	2026PD00220	2026-06-12	138.31
191	2026PD00336	2026-08-13	103.73
192	2026PD00177	2026-05-08	138.31
193	2026PD00307	2026-08-10	161.36
194	2026PD00237	2026-06-19	1313.93
195	2026PD00173	2026-05-08	537.85
196	2026PD00402	2026-10-02	207.46
197	2026PD00408	2026-10-07	16804.80
198	2026PD00058	2026-02-24	207.46
199	2026PD00135	2026-04-08	248.96
200	2026PD00296	2026-07-30	248.96
201	2026PD00223	2026-06-12	69.15
202	2026PD00307	2026-08-10	161.36
203	2026PD00241	2026-06-19	138.31
204	2026PD00295	2026-07-30	822.94
205	2026PD00118	2026-04-08	96.81
206	2026PD00074	2026-03-06	248.96
207	2026PD00344	2026-08-14	207.46
107	2026PD00290	2026-07-30	138.31
161	2026PD00243	2026-06-19	248.96
\.


--
-- Data for Name: pds_bkp_auditoria; Type: TABLE DATA; Schema: backup; Owner: postgres
--

COPY backup.pds_bkp_auditoria (id_pd, numero_pd, data_pagamento) FROM stdin;
1	2026PD00113	2026-04-08
2	2026PD00117	2026-04-08
3	2026PD00194	2026-05-12
4	2026PD00171	2026-05-08
5	2026PD00069	2026-03-06
6	2026PD00287	2026-07-30
7	2026PD00291	2026-07-30
8	2026PD00055	2026-02-25
9	2026PD00077	2026-03-06
10	2026PD00123	2026-04-08
11	2026PD00047	2026-02-25
12	2026PD00114	2026-04-08
13	2026PD00129	2026-04-08
14	2026PD00414	2026-10-14
15	2026PD00415	2026-10-14
16	2026PD00416	2026-10-14
17	2026PD00417	2026-10-14
18	2026PD00418	2026-10-14
19	2026PD00419	2026-10-14
20	2026PD00420	2026-10-14
21	2026PD00421	2026-10-14
22	2026PD00403	2026-10-02
23	2026PD00402	2026-10-02
24	2026PD00076	2026-03-06
25	2026PD00306	2026-08-10
26	2026PD00083	2026-03-06
27	2026PD00402	2026-10-02
28	2026PD00402	2026-10-02
29	2026PD00125	2026-04-08
30	2026PD00126	2026-04-08
31	2026PD00169	2026-05-08
32	2026PD00294	2026-07-30
33	2026PD00223	2026-06-12
34	2026PD00178	2026-05-08
35	2026PD00136	2026-08-10
36	2026PD00122	2026-04-08
37	2026PD00218	2026-06-12
38	2026PD00068	2026-03-06
39	2026PD00306	2026-08-10
40	2026PD00162	2026-05-08
41	2026PD00306	2026-08-10
42	2026PD00242	2026-06-19
43	2026PD00085	2026-03-06
44	2026PD00368	2026-09-08
45	2026PD00402	2026-10-02
46	2026PD00078	2026-03-06
47	2026PD00132	2026-04-08
48	2026PD00133	2026-04-08
49	2026PD00167	2026-05-08
50	2026PD00121	2026-04-08
51	2026PD00402	2026-10-02
52	2026PD00051	2026-02-25
53	2026PD00073	2026-03-06
54	2026PD00338	2026-08-13
55	2026PD00174	2026-05-08
56	2026PD00128	2026-04-08
57	2026PD00161	2026-05-08
58	2026PD00306	2026-08-10
59	2026PD00053	2026-02-25
60	2026PD00292	2026-07-30
61	2026PD00282	2026-07-30
62	2026PD00172	2026-05-08
63	2026PD00289	2026-07-30
64	2026PD00168	2026-05-08
65	2026PD00367	2026-09-08
66	2026PD00315	2026-08-10
67	2026PD00297	2026-06-30
68	2026PD00163	2026-05-08
69	2026PD00240	2026-06-19
70	2026PD00239	2026-06-19
71	2026PD00260	2026-07-07
72	2026PD00318	2026-08-10
74	2026PD00342	2026-08-14
75	2026PD00286	2026-07-30
76	2026PD00083	2026-03-06
77	2026PD00054	2026-02-25
78	2026PD00166	2026-05-08
79	2026PD00083	2026-03-06
80	2026PD00402	2026-10-02
81	2026PD00311	2026-08-10
82	2026PD00288	2026-07-30
83	2026PD00127	2026-04-08
84	2026PD00343	2026-08-14
85	2026PD00314	2026-08-10
86	2026PD00247	2026-06-19
87	2026PD00070	2026-03-06
88	2026PD00163	2026-05-08
89	2026PD00289	2026-07-30
90	2026PD00221	2026-06-12
91	2026PD00048	2026-02-25
92	2026PD00079	2026-03-06
93	2026PD00056	2026-02-24
94	2026PD00115	2026-04-08
95	2026PD00081	2026-03-06
96	2026PD00306	2026-08-10
97	2026PD00402	2026-10-02
98	2026PD00371	2026-09-08
99	2026PD00334	2026-08-14
100	2026PD00370	2026-09-08
101	2026PD00170	2026-05-08
102	2026PD00306	2026-08-10
103	2026PD00262	2026-07-07
104	2026PD00304	2026-08-05
105	2026PD00180	2026-05-08
106	2026PD00402	2026-10-02
108	2026PD00292	2026-07-30
109	2026PD00238	2026-06-19
110	2026PD00310	2026-08-10
111	2026PD00128	2026-04-08
112	2026PD00118	2026-04-08
113	2026PD00307	2026-08-10
114	2026PD00059	2026-02-25
115	2026PD00306	2026-08-10
116	2026PD00184	2026-05-08
117	2026PD00082	2026-03-06
118	2026PD00117	2026-04-08
119	2026PD00050	2026-02-25
120	2026PD00127	2026-04-08
121	2026PD00072	2026-03-06
122	2026PD00319	2026-08-10
123	2026PD00306	2026-08-10
124	2026PD00402	2026-10-02
125	2026PD00293	2026-07-30
126	2026PD00057	2026-02-24
127	2026PD00402	2026-10-02
128	2026PD00341	2026-08-14
129	2026PD00176	2026-05-08
130	2026PD00080	2026-03-06
131	2026PD00116	2026-04-08
133	2026PD00081	2026-03-06
134	2026PD00284	2026-07-30
135	2026PD00080	2026-03-06
132	2026PD00283	2026-07-30
136	2026PD00223	2026-06-12
137	2026PD00261	2026-07-07
138	2026PD00340	2026-08-14
139	2026PD00164	2026-05-08
140	2026PD00129	2026-04-08
141	2026PD00121	2026-04-08
142	2026PD00309	2026-08-10
143	2026PD00369	2026-09-08
144	2026PD00332	2026-08-14
145	2026PD00313	2026-08-10
146	2026PD00243	2026-06-19
147	2026PD00135	2026-04-08
148	2026PD00221	2026-06-12
149	2026PD00131	2026-04-08
150	2026PD00307	2026-08-10
151	2026PD00306	2026-08-10
152	2026PD00306	2026-08-10
153	2026PD00402	2026-10-02
154	2026PD00245	2026-06-19
155	2026PD00221	2026-06-12
156	2026PD00075	2026-03-06
157	2026PD00288	2026-07-30
158	2026PD00175	2026-05-08
159	2026PD00128	2026-04-08
160	2026PD00307	2026-08-10
162	2026PD00183	2026-05-08
163	2026PD00285	2026-07-30
164	2026PD00125	2026-04-08
165	2026PD00120	2026-04-08
166	2026PD00179	2026-05-08
167	2026PD00307	2026-08-10
168	2026PD00335	2026-08-13
169	2026PD00166	2026-05-08
170	2026PD00222	2026-06-12
171	2026PD00306	2026-08-10
172	2026PD00307	2026-08-10
173	2026PD00308	2026-08-10
174	2026PD00306	2026-08-10
175	2026PD00246	2026-06-19
176	2026PD00317	2026-08-10
177	2026PD00049	2026-02-25
178	2026PD00243	2026-06-19
179	2026PD00134	2026-04-08
180	2026PD00244	2026-06-19
181	2026PD00309	2026-08-10
182	2026PD00337	2026-08-13
183	2026PD00052	2026-02-25
184	2026PD00307	2026-08-10
185	2026PD00124	2026-04-08
186	2026PD00119	2026-04-08
187	2026PD00165	2026-05-08
188	2026PD00071	2026-03-06
189	2026PD00130	2026-04-08
190	2026PD00220	2026-06-12
191	2026PD00336	2026-08-13
192	2026PD00177	2026-05-08
193	2026PD00307	2026-08-10
194	2026PD00237	2026-06-19
195	2026PD00173	2026-05-08
196	2026PD00402	2026-10-02
197	2026PD00408	2026-10-07
198	2026PD00058	2026-02-24
199	2026PD00135	2026-04-08
200	2026PD00296	2026-07-30
201	2026PD00223	2026-06-12
202	2026PD00307	2026-08-10
203	2026PD00241	2026-06-19
204	2026PD00295	2026-07-30
205	2026PD00118	2026-04-08
206	2026PD00074	2026-03-06
207	2026PD00344	2026-08-14
107	2026PD00290	2026-07-30
161	2026PD00243	2026-06-19
\.


--
-- Data for Name: pds_bkp_consolidacao; Type: TABLE DATA; Schema: backup; Owner: postgres
--

COPY backup.pds_bkp_consolidacao (id_pd, numero_pd, data_pagamento, valor_pagamento) FROM stdin;
1	2026PD00113	2026-04-08	207.42
2	2026PD00117	2026-04-08	69.15
3	2026PD00194	2026-05-12	69.15
4	2026PD00171	2026-05-08	124.48
5	2026PD00069	2026-03-06	69.15
6	2026PD00287	2026-07-30	822.94
7	2026PD00291	2026-07-30	822.94
8	2026PD00055	2026-02-25	207.46
9	2026PD00077	2026-03-06	103.73
10	2026PD00123	2026-04-08	69.15
11	2026PD00047	2026-02-25	204.46
12	2026PD00114	2026-04-08	622.39
13	2026PD00129	2026-04-08	248.96
14	2026PD00414	2026-10-14	207.46
15	2026PD00415	2026-10-14	103.73
16	2026PD00416	2026-10-14	207.46
17	2026PD00417	2026-10-14	80.68
18	2026PD00418	2026-10-14	207.46
19	2026PD00419	2026-10-14	1075.70
20	2026PD00420	2026-10-14	124.48
21	2026PD00421	2026-10-14	484.08
22	2026PD00403	2026-10-02	69.15
23	2026PD00402	2026-10-02	1383.00
24	2026PD00076	2026-03-06	138.31
25	2026PD00306	2026-08-10	107.57
26	2026PD00083	2026-03-06	138.31
27	2026PD00402	2026-10-02	103.73
28	2026PD00402	2026-10-02	103.73
29	2026PD00125	2026-04-08	69.15
30	2026PD00126	2026-04-08	69.15
31	2026PD00169	2026-05-08	103.73
32	2026PD00294	2026-07-30	193.63
33	2026PD00223	2026-06-12	69.15
34	2026PD00178	2026-05-08	248.96
35	2026PD00136	2026-08-10	193.63
36	2026PD00122	2026-04-08	69.15
37	2026PD00218	2026-06-12	13443.84
38	2026PD00068	2026-03-06	248.96
39	2026PD00306	2026-08-10	107.57
40	2026PD00162	2026-05-08	138.31
41	2026PD00306	2026-08-10	107.57
42	2026PD00242	2026-06-19	138.31
43	2026PD00085	2026-03-06	746.88
44	2026PD00368	2026-09-08	248.96
45	2026PD00402	2026-10-02	1075.70
46	2026PD00078	2026-03-06	207.46
47	2026PD00132	2026-04-08	995.84
48	2026PD00133	2026-04-08	69.15
49	2026PD00167	2026-05-08	107.57
50	2026PD00121	2026-04-08	69.15
51	2026PD00402	2026-10-02	103.73
52	2026PD00051	2026-02-25	138.31
53	2026PD00073	2026-03-06	207.46
54	2026PD00338	2026-08-13	968.10
55	2026PD00174	2026-05-08	248.96
56	2026PD00128	2026-04-08	69.15
57	2026PD00161	2026-05-08	13070.40
58	2026PD00306	2026-08-10	107.57
59	2026PD00053	2026-02-25	138.31
60	2026PD00292	2026-07-30	207.46
61	2026PD00282	2026-07-30	1075.70
62	2026PD00172	2026-05-08	1521.41
63	2026PD00289	2026-07-30	207.46
64	2026PD00168	2026-05-08	138.31
65	2026PD00367	2026-09-08	248.96
66	2026PD00315	2026-08-10	69.15
67	2026PD00297	2026-06-30	1383.00
68	2026PD00163	2026-05-08	311.19
69	2026PD00240	2026-06-19	138.31
70	2026PD00239	2026-06-19	1452.24
71	2026PD00260	2026-07-07	12448.00
72	2026PD00318	2026-08-10	248.96
74	2026PD00342	2026-08-14	138.31
75	2026PD00286	2026-07-30	138.31
76	2026PD00083	2026-03-06	207.46
77	2026PD00054	2026-02-25	207.46
78	2026PD00166	2026-05-08	69.15
79	2026PD00083	2026-03-06	69.15
80	2026PD00402	2026-10-02	138.31
81	2026PD00311	2026-08-10	138.31
82	2026PD00288	2026-07-30	138.31
83	2026PD00127	2026-04-08	69.15
84	2026PD00343	2026-08-14	103.73
85	2026PD00314	2026-08-10	69.15
86	2026PD00247	2026-06-19	161.36
87	2026PD00070	2026-03-06	207.46
88	2026PD00163	2026-05-08	103.73
89	2026PD00289	2026-07-30	138.31
90	2026PD00221	2026-06-12	69.15
91	2026PD00048	2026-02-25	207.46
92	2026PD00079	2026-03-06	138.31
93	2026PD00056	2026-02-24	207.46
94	2026PD00115	2026-04-08	968.13
95	2026PD00081	2026-03-06	248.96
96	2026PD00306	2026-08-10	107.57
97	2026PD00402	2026-10-02	103.73
98	2026PD00371	2026-09-08	13443.84
99	2026PD00334	2026-08-14	103.73
100	2026PD00370	2026-09-08	248.96
101	2026PD00170	2026-05-08	69.15
102	2026PD00306	2026-08-10	107.57
103	2026PD00262	2026-07-07	138.30
104	2026PD00304	2026-08-05	15560.00
105	2026PD00180	2026-05-08	248.96
106	2026PD00402	2026-10-02	138.31
108	2026PD00292	2026-07-30	207.46
109	2026PD00238	2026-06-19	430.28
110	2026PD00310	2026-08-10	138.31
111	2026PD00128	2026-04-08	138.31
112	2026PD00118	2026-04-08	53.78
113	2026PD00307	2026-08-10	161.36
114	2026PD00059	2026-02-25	871.36
115	2026PD00306	2026-08-10	107.57
116	2026PD00184	2026-05-08	69.15
117	2026PD00082	2026-03-06	138.31
118	2026PD00117	2026-04-08	69.15
119	2026PD00050	2026-02-25	207.46
120	2026PD00127	2026-04-08	69.15
121	2026PD00072	2026-03-06	138.31
122	2026PD00319	2026-08-10	110.65
123	2026PD00306	2026-08-10	107.57
124	2026PD00402	2026-10-02	207.46
125	2026PD00293	2026-07-30	822.94
126	2026PD00057	2026-02-24	207.46
127	2026PD00402	2026-10-02	103.73
128	2026PD00341	2026-08-14	103.73
129	2026PD00176	2026-05-08	138.31
130	2026PD00080	2026-03-06	207.46
131	2026PD00116	2026-04-08	69.15
133	2026PD00081	2026-03-06	207.46
134	2026PD00284	2026-07-30	248.96
135	2026PD00080	2026-03-06	248.96
132	2026PD00283	2026-07-30	248.96
136	2026PD00223	2026-06-12	69.15
137	2026PD00261	2026-07-07	138.30
138	2026PD00340	2026-08-14	622.40
139	2026PD00164	2026-05-08	69.15
140	2026PD00129	2026-04-08	248.96
141	2026PD00121	2026-04-08	69.15
142	2026PD00309	2026-08-10	138.31
143	2026PD00369	2026-09-08	248.96
144	2026PD00332	2026-08-14	248.96
145	2026PD00313	2026-08-10	207.46
146	2026PD00243	2026-06-19	124.48
147	2026PD00135	2026-04-08	69.15
148	2026PD00221	2026-06-12	69.15
149	2026PD00131	2026-04-08	80.68
150	2026PD00307	2026-08-10	161.36
151	2026PD00306	2026-08-10	107.57
152	2026PD00306	2026-08-10	107.57
153	2026PD00402	2026-10-02	1613.60
154	2026PD00245	2026-06-19	69.15
155	2026PD00221	2026-06-12	69.15
156	2026PD00075	2026-03-06	248.96
157	2026PD00288	2026-07-30	138.31
158	2026PD00175	2026-05-08	248.96
159	2026PD00128	2026-04-08	69.15
160	2026PD00307	2026-08-10	161.36
162	2026PD00183	2026-05-08	248.96
163	2026PD00285	2026-07-30	248.96
164	2026PD00125	2026-04-08	69.15
165	2026PD00120	2026-04-08	138.31
166	2026PD00179	2026-05-08	207.45
167	2026PD00307	2026-08-10	161.36
168	2026PD00335	2026-08-13	2097.68
169	2026PD00166	2026-05-08	124.48
170	2026PD00222	2026-06-12	207.45
171	2026PD00306	2026-08-10	107.57
172	2026PD00307	2026-08-10	161.36
173	2026PD00308	2026-08-10	207.46
174	2026PD00306	2026-08-10	107.57
175	2026PD00246	2026-06-19	193.63
176	2026PD00317	2026-08-10	248.96
177	2026PD00049	2026-02-25	207.46
178	2026PD00243	2026-06-19	124.48
179	2026PD00134	2026-04-08	2489.60
180	2026PD00244	2026-06-19	138.31
181	2026PD00309	2026-08-10	138.31
182	2026PD00337	2026-08-13	138.31
183	2026PD00052	2026-02-25	138.31
184	2026PD00307	2026-08-10	161.36
185	2026PD00124	2026-04-08	248.96
186	2026PD00119	2026-04-08	207.46
187	2026PD00165	2026-05-08	207.45
188	2026PD00071	2026-03-06	248.96
189	2026PD00130	2026-04-08	1452.25
190	2026PD00220	2026-06-12	138.31
191	2026PD00336	2026-08-13	103.73
192	2026PD00177	2026-05-08	138.31
193	2026PD00307	2026-08-10	161.36
194	2026PD00237	2026-06-19	1313.93
195	2026PD00173	2026-05-08	537.85
196	2026PD00402	2026-10-02	207.46
197	2026PD00408	2026-10-07	16804.80
198	2026PD00058	2026-02-24	207.46
199	2026PD00135	2026-04-08	248.96
200	2026PD00296	2026-07-30	248.96
201	2026PD00223	2026-06-12	69.15
202	2026PD00307	2026-08-10	161.36
203	2026PD00241	2026-06-19	138.31
204	2026PD00295	2026-07-30	822.94
205	2026PD00118	2026-04-08	96.81
206	2026PD00074	2026-03-06	248.96
207	2026PD00344	2026-08-14	207.46
107	2026PD00290	2026-07-30	138.31
161	2026PD00243	2026-06-19	248.96
\.


--
-- Data for Name: processos_bkp_20261021; Type: TABLE DATA; Schema: backup; Owner: postgres
--

COPY backup.processos_bkp_20261021 (id_processo, numero_processo) FROM stdin;
368	058.00068481/202604
369	058.00057813/202617
370	058.00083398/202659
371	058.00102235/202681
372	058.00052997/202629
373	058.00035638/202615
374	058.00051312/202627
375	058.00001037/202609
376	058.00082688/202683
377	05800104239/202601
378	058.00093837/202630
379	058.00090988/202636
380	058.00070478/202642
381	058.00115646/202636
382	058.00052028/202678
383	058.00069566/202600
384	058.00070439/202645
385	058.00031519/202685
386	058.00041351/202616
387	058.00022386/202656
388	058.00095060/202648
389	058.00012724/202641
390	058.00031520/202618
391	058.00066721/202628
392	058.00033157/202667
393	058.00093477/202676
394	058.00023999/202619
395	058.00087987/202612
396	058.00062241/202698
397	058.00081687/202611
398	058.00059627/202612
399	058.00074727/202679
400	058.00083398/202661
401	058.00077762/202640
402	058.00021611/202637
403	058.00091579/202664
404	058.00091579/202663
405	058.00091579/202659
406	058.00020923/202623
407	058.00102726/202621
408	058.00018719/202642
409	058.00055684/202622
410	058.00027352/202658
411	058.00070670/202639
412	058.00021373/202660
413	058.00048528/202613
414	058.00101723/202671
415	058.00091579/202658
416	058.00031765/202637
417	058.00021480/202698
418	058.00001044/202601
419	058.00104642/202622
420	058.00080283/202619
421	058.00033318/202612
422	058.00054445/202655
423	05800067369/202648
424	058.00052142/202606
425	058.00037432/202611
426	058.00099842/202656
427	058.00024388/202680
428	058.00056002/202607
429	058.00004380/202605
430	058.00044639/202642
431	058.00102757/202682
432	058.00040442/202642
433	058.00052548/202681
434	058.00040508/202696
435	058.00083398/202664
436	058.00093806/202689
437	058.00003397/202637
438	058.00083398/202663
439	058.00070660/202601
440	058.00091579/202657
441	058.00040310/202611
442	058.00033148/202676
444	058.00031378/202609
445	058.00078470/202624
446	058.00003690/202602
447	058.00047214/202695
448	058.00040676/202681
449	058.00024300/202620
450	058.00064004/202661
451	058.00023698/202687
452	058.00059942/202640
453	058.00070445/202601
454	058.00103897/202678
455	058.00094473/202613
456	058.00105727/202628
457	058.00070656/202635
458	058.00091579/202661
459	058.00085150/202621
460	058.00040479/202662
461	058.00104889/202649
462	058.00014312/202646
463	058.00003563/202603
464	058.00036561/202692
465	058.00103808/202693
466	058.00094808/202695
467	058.00045723/202683
468	058.00083424/202647
469	058.00029861/202615
470	058.00083398/202662
471	058.00040956/202690
472	058.00079231/202691
473	058.00098581/202657
474	058.00098567/202653
475	058.00023653/202611
476	058.00027233/202603
477	058.00018728/202633
478	058.00007397/202614
479	058.00091579/202667
480	058.00083398/202660
481	058.00034447/202628
482	058.00045732/202674
483	058.00059047/202625
484	058.00091579/202665
485	058.00067125/202665
486	058.00010411/202659
487	058.00074761/202643
488	058.00083398/202658
489	058.00056379/202658
490	058.00040322/202637
491	058.00056381/202627
492	058.00049520/202666
493	058.00078792/202673
494	058.00092056/202628
495	058.00083398/202657
496	058.00092795/202610
497	058.00074738/202659
498	058.00027335/202611
499	058.00035389/202650
500	058.00055452/202674
501	058.00091579/202662
502	058.00045929/202611
503	058.00024277/202673
504	058.00031514/202652
505	058.00020984/202691
506	058.00048533/202618
507	058.00094564/202641
508	058.00070443/202611
509	058.00041483/202648
510	058.00020995/202671
511	058.00041533/202668
512	058.00031510/202674
513	058.00020892/202619
514	058.00018050/202699
515	058.00101929/202609
516	058.00088428/202611
517	058.00094899/202669
518	058.00074738/2026-59
519	058.00070662/202692
520	058.00056878/202645
521	058.00059213/202693
522	058.00085156/202606
523	058.00057022/202697
524	058.00036565/202671
525	058.00048535/202615
526	058.00074673/202641
527	058.00035649/202697
528	058.00047272/202619
529	058.00086330/202620
530	058.00085732/202615
531	058.00074505/202656
532	058.00091579/202668
533	058.00091579/202660
534	058.00094690/202603
535	058.00085564/202650
536	058.00037136/202611
537	058.00052538/202645
538	058.00091820/202648
539	058.00091579/202666
540	058.00080648/202605
541	058.00056375/202670
542	058.00077592/202601
543	058.00012728/202620
544	058.00012100/202624
545	058.00028495/202687
546	058.00053438/202639
547	058.00094014/202621
548	058.00020495/202639
549	058.00004579/202625
550	058.00055999/202670
551	058.00051656/202636
552	058.00071344/202649
553	058.00102590/202650
554	058.00031184/202603
555	058.00031183/202651
556	058.00052368/202607
557	058.00048851/202689
558	058.00074730/202692
559	058.00063384/202617
560	058.00095143/202637
561	058.00055990/202669
562	058.00046220/202625
563	058.00084233/202601
566	058.00010202/202616
567	058.00033315/202612
579	058.00113983/202699
580	058.00111491/202669
581	058.00113978/202686
582	058.00111029/202661
583	058.00114776/202651
584	058.00116234/202613
585	058.00116140/202644
586	058.00116200/202629
565	058.00116811/202677
\.


--
-- Data for Name: processos_bkp_20261021_v2; Type: TABLE DATA; Schema: backup; Owner: postgres
--

COPY backup.processos_bkp_20261021_v2 (id_processo, numero_processo) FROM stdin;
368	058.00068481/202604
369	058.00057813/202617
370	058.00083398/202659
371	058.00102235/202681
372	058.00052997/202629
373	058.00035638/202615
374	058.00051312/202627
375	058.00001037/202609
376	058.00082688/202683
377	05800104239/202601
378	058.00093837/202630
379	058.00090988/202636
380	058.00070478/202642
381	058.00115646/202636
382	058.00052028/202678
383	058.00069566/202600
384	058.00070439/202645
385	058.00031519/202685
386	058.00041351/202616
387	058.00022386/202656
388	058.00095060/202648
389	058.00012724/202641
390	058.00031520/202618
391	058.00066721/202628
392	058.00033157/202667
393	058.00093477/202676
394	058.00023999/202619
395	058.00087987/202612
396	058.00062241/202698
397	058.00081687/202611
398	058.00059627/202612
399	058.00074727/202679
400	058.00083398/202661
401	058.00077762/202640
402	058.00021611/202637
403	058.00091579/202664
404	058.00091579/202663
405	058.00091579/202659
406	058.00020923/202623
407	058.00102726/202621
408	058.00018719/202642
409	058.00055684/202622
410	058.00027352/202658
411	058.00070670/202639
412	058.00021373/202660
413	058.00048528/202613
414	058.00101723/202671
415	058.00091579/202658
416	058.00031765/202637
417	058.00021480/202698
418	058.00001044/202601
419	058.00104642/202622
420	058.00080283/202619
421	058.00033318/202612
422	058.00054445/202655
423	05800067369/202648
424	058.00052142/202606
425	058.00037432/202611
426	058.00099842/202656
427	058.00024388/202680
428	058.00056002/202607
429	058.00004380/202605
430	058.00044639/202642
431	058.00102757/202682
432	058.00040442/202642
433	058.00052548/202681
434	058.00040508/202696
435	058.00083398/202664
436	058.00093806/202689
437	058.00003397/202637
438	058.00083398/202663
439	058.00070660/202601
440	058.00091579/202657
441	058.00040310/202611
442	058.00033148/202676
444	058.00031378/202609
445	058.00078470/202624
446	058.00003690/202602
447	058.00047214/202695
448	058.00040676/202681
449	058.00024300/202620
450	058.00064004/202661
451	058.00023698/202687
452	058.00059942/202640
453	058.00070445/202601
454	058.00103897/202678
455	058.00094473/202613
456	058.00105727/202628
457	058.00070656/202635
458	058.00091579/202661
459	058.00085150/202621
460	058.00040479/202662
461	058.00104889/202649
462	058.00014312/202646
463	058.00003563/202603
464	058.00036561/202692
465	058.00103808/202693
466	058.00094808/202695
467	058.00045723/202683
468	058.00083424/202647
469	058.00029861/202615
470	058.00083398/202662
471	058.00040956/202690
472	058.00079231/202691
473	058.00098581/202657
474	058.00098567/202653
475	058.00023653/202611
476	058.00027233/202603
477	058.00018728/202633
478	058.00007397/202614
479	058.00091579/202667
480	058.00083398/202660
481	058.00034447/202628
482	058.00045732/202674
483	058.00059047/202625
484	058.00091579/202665
485	058.00067125/202665
486	058.00010411/202659
487	058.00074761/202643
488	058.00083398/202658
489	058.00056379/202658
490	058.00040322/202637
491	058.00056381/202627
492	058.00049520/202666
493	058.00078792/202673
494	058.00092056/202628
495	058.00083398/202657
496	058.00092795/202610
497	058.00074738/202659
498	058.00027335/202611
499	058.00035389/202650
500	058.00055452/202674
501	058.00091579/202662
502	058.00045929/202611
503	058.00024277/202673
504	058.00031514/202652
505	058.00020984/202691
506	058.00048533/202618
507	058.00094564/202641
508	058.00070443/202611
509	058.00041483/202648
510	058.00020995/202671
511	058.00041533/202668
512	058.00031510/202674
513	058.00020892/202619
514	058.00018050/202699
515	058.00101929/202609
516	058.00088428/202611
517	058.00094899/202669
518	058.00074738/2026-59
519	058.00070662/202692
520	058.00056878/202645
521	058.00059213/202693
522	058.00085156/202606
523	058.00057022/202697
524	058.00036565/202671
525	058.00048535/202615
526	058.00074673/202641
527	058.00035649/202697
528	058.00047272/202619
529	058.00086330/202620
530	058.00085732/202615
531	058.00074505/202656
532	058.00091579/202668
533	058.00091579/202660
534	058.00094690/202603
535	058.00085564/202650
536	058.00037136/202611
537	058.00052538/202645
538	058.00091820/202648
539	058.00091579/202666
540	058.00080648/202605
541	058.00056375/202670
542	058.00077592/202601
543	058.00012728/202620
544	058.00012100/202624
545	058.00028495/202687
546	058.00053438/202639
547	058.00094014/202621
548	058.00020495/202639
549	058.00004579/202625
550	058.00055999/202670
551	058.00051656/202636
552	058.00071344/202649
553	058.00102590/202650
554	058.00031184/202603
555	058.00031183/202651
556	058.00052368/202607
557	058.00048851/202689
558	058.00074730/202692
559	058.00063384/202617
560	058.00095143/202637
561	058.00055990/202669
562	058.00046220/202625
563	058.00084233/202601
566	058.00010202/202616
567	058.00033315/202612
579	058.00113983/202699
580	058.00111491/202669
581	058.00113978/202686
582	058.00111029/202661
583	058.00114776/202651
584	058.00116234/202613
585	058.00116140/202644
586	058.00116200/202629
565	058.00116811/202677
\.


--
-- Data for Name: processos_bkp_auditoria; Type: TABLE DATA; Schema: backup; Owner: postgres
--

COPY backup.processos_bkp_auditoria (id_processo, numero_processo) FROM stdin;
368	058.00068481/202604
369	058.00057813/202617
370	058.00083398/202659
371	058.00102235/202681
372	058.00052997/202629
373	058.00035638/202615
374	058.00051312/202627
375	058.00001037/202609
376	058.00082688/202683
377	05800104239/202601
378	058.00093837/202630
379	058.00090988/202636
380	058.00070478/202642
381	058.00115646/202636
382	058.00052028/202678
383	058.00069566/202600
384	058.00070439/202645
385	058.00031519/202685
386	058.00041351/202616
387	058.00022386/202656
388	058.00095060/202648
389	058.00012724/202641
390	058.00031520/202618
391	058.00066721/202628
392	058.00033157/202667
393	058.00093477/202676
394	058.00023999/202619
395	058.00087987/202612
396	058.00062241/202698
397	058.00081687/202611
398	058.00059627/202612
399	058.00074727/202679
400	058.00083398/202661
401	058.00077762/202640
402	058.00021611/202637
403	058.00091579/202664
404	058.00091579/202663
405	058.00091579/202659
406	058.00020923/202623
407	058.00102726/202621
408	058.00018719/202642
409	058.00055684/202622
410	058.00027352/202658
411	058.00070670/202639
412	058.00021373/202660
413	058.00048528/202613
414	058.00101723/202671
415	058.00091579/202658
416	058.00031765/202637
417	058.00021480/202698
418	058.00001044/202601
419	058.00104642/202622
420	058.00080283/202619
421	058.00033318/202612
422	058.00054445/202655
423	05800067369/202648
424	058.00052142/202606
425	058.00037432/202611
426	058.00099842/202656
427	058.00024388/202680
428	058.00056002/202607
429	058.00004380/202605
430	058.00044639/202642
431	058.00102757/202682
432	058.00040442/202642
433	058.00052548/202681
434	058.00040508/202696
435	058.00083398/202664
436	058.00093806/202689
437	058.00003397/202637
438	058.00083398/202663
439	058.00070660/202601
440	058.00091579/202657
441	058.00040310/202611
442	058.00033148/202676
444	058.00031378/202609
445	058.00078470/202624
446	058.00003690/202602
447	058.00047214/202695
448	058.00040676/202681
449	058.00024300/202620
450	058.00064004/202661
451	058.00023698/202687
452	058.00059942/202640
453	058.00070445/202601
454	058.00103897/202678
455	058.00094473/202613
456	058.00105727/202628
457	058.00070656/202635
458	058.00091579/202661
459	058.00085150/202621
460	058.00040479/202662
461	058.00104889/202649
462	058.00014312/202646
463	058.00003563/202603
464	058.00036561/202692
465	058.00103808/202693
466	058.00094808/202695
467	058.00045723/202683
468	058.00083424/202647
469	058.00029861/202615
470	058.00083398/202662
471	058.00040956/202690
472	058.00079231/202691
473	058.00098581/202657
474	058.00098567/202653
475	058.00023653/202611
476	058.00027233/202603
477	058.00018728/202633
478	058.00007397/202614
479	058.00091579/202667
480	058.00083398/202660
481	058.00034447/202628
482	058.00045732/202674
483	058.00059047/202625
484	058.00091579/202665
485	058.00067125/202665
486	058.00010411/202659
487	058.00074761/202643
488	058.00083398/202658
489	058.00056379/202658
490	058.00040322/202637
491	058.00056381/202627
492	058.00049520/202666
493	058.00078792/202673
494	058.00092056/202628
495	058.00083398/202657
496	058.00092795/202610
497	058.00074738/202659
498	058.00027335/202611
499	058.00035389/202650
500	058.00055452/202674
501	058.00091579/202662
502	058.00045929/202611
503	058.00024277/202673
504	058.00031514/202652
505	058.00020984/202691
506	058.00048533/202618
507	058.00094564/202641
508	058.00070443/202611
509	058.00041483/202648
510	058.00020995/202671
511	058.00041533/202668
512	058.00031510/202674
513	058.00020892/202619
514	058.00018050/202699
515	058.00101929/202609
516	058.00088428/202611
517	058.00094899/202669
518	058.00074738/2026-59
519	058.00070662/202692
520	058.00056878/202645
521	058.00059213/202693
522	058.00085156/202606
523	058.00057022/202697
524	058.00036565/202671
525	058.00048535/202615
526	058.00074673/202641
527	058.00035649/202697
528	058.00047272/202619
529	058.00086330/202620
530	058.00085732/202615
531	058.00074505/202656
532	058.00091579/202668
533	058.00091579/202660
534	058.00094690/202603
535	058.00085564/202650
536	058.00037136/202611
537	058.00052538/202645
538	058.00091820/202648
539	058.00091579/202666
540	058.00080648/202605
541	058.00056375/202670
542	058.00077592/202601
543	058.00012728/202620
544	058.00012100/202624
545	058.00028495/202687
546	058.00053438/202639
547	058.00094014/202621
548	058.00020495/202639
549	058.00004579/202625
550	058.00055999/202670
551	058.00051656/202636
552	058.00071344/202649
553	058.00102590/202650
554	058.00031184/202603
555	058.00031183/202651
556	058.00052368/202607
557	058.00048851/202689
558	058.00074730/202692
559	058.00063384/202617
560	058.00095143/202637
561	058.00055990/202669
562	058.00046220/202625
563	058.00084233/202601
566	058.00010202/202616
567	058.00033315/202612
579	058.00113983/202699
580	058.00111491/202669
581	058.00113978/202686
582	058.00111029/202661
583	058.00114776/202651
584	058.00116234/202613
585	058.00116140/202644
586	058.00116200/202629
565	058.00116811/202677
587	058.00116811/2026-77
\.


--
-- Data for Name: servidores_bkp_20261021; Type: TABLE DATA; Schema: backup; Owner: postgres
--

COPY backup.servidores_bkp_20261021 (cpf_servidor, nome_servidor, id_cargo) FROM stdin;
05733151838	ADALBERTO JORGE RODRIGUES	7
06346558501	ADALTO ALVES ROCHA NETO	7
14042095739	ADVAIR VASCONCELOS VELOSO DA SILVA	7
30379558807	ALBERTO RAHAL NETO	7
31156936802	ALESSANDRO ROGERIO DOS SANTOS	1
17162481833	ALEXANDRE SIMÃ•ES SILVA	3
84922001891	AMERICO SIDNEI RISSATO	5
17559994881	ANDRE LUIS DA SILVA	6
35981258870	ANDRE LUIS FABRES	6
40300050801	ANDREA DANTAS LEVY	5
39510249840	ANGELA DE LIMA DALTIN	6
17764814881	ANTONIO LUIS FIOR	7
60115700978	ANTONIO ONOFRE	7
17416608821	ARAGAO XAVIER DA SILVA	7
09433315952	BIANCA CRISTINA DA SILVA RITTER	6
39259259886	BRUNO AZZINI TIOSSO	1
21819139867	BRUNO RODRIGUES JACON	7
30158768809	CARLOS ADRIANO BERTTO CABRINI	2
07884129817	CARLOS ALBERTO LIBARDI	2
37550429839	CARLOS EDUARDO STRABELLI	6
11548143863	CARLOS EDUARDO ZURITA LEONI	7
06851660660	CHRISTIANO GONÃ‡ALVES VIDAL	7
38672275861	CINTIA APARECIDA VENANCIO FABRIS	6
05733042893	CLAUDINEI FERREIRA	4
43646474890	CLEBER MEIRA JUNIOR	6
19214657866	CRISTIANO EDUARDO PENTEADO	6
04611267881	DALTON EDUARDO METZNER	1
31111293813	DANIELE APARECIDA VIELLI	6
06432966620	DIOGO FRANCISCO DE BRITO	7
39101020854	DOMINIC ALVES FERREIRA	6
13600008790	DOUGLAS GUIMARAES PINA BASTOS	7
06292282805	EDINELSON APARECIDO OLICHESCKI	6
12382786639	EDUARDO SUEIT JUNIOR	7
16079405822	EITHEL DINAEL STRABELLI	7
25180228808	EJEFERSON ARRAEZ LOPES	6
14743987822	ELAINE CRISTINA RODRIGUES	6
06730855894	ELIANE MARIA CAMOLESI	6
02788546807	ELIAS DE OLIVEIRA	3
40764409867	ELIAS GABRIEL DE OLIVEIRA PISSE	6
85920356510	EMILLE BORBUREMA DE OLIVEIRA MACHADO	7
00985216328	EVELYN KAFA LOIOLA DOMIATE	5
14716979830	EVERTON DE OLIVEIRA CARDOSO	6
41059752859	EWERTON REINALDO PEREIRA LOPES	6
36822427830	FABIANA SINIBALDI BARBOSA	6
10096636823	FABIO CORREA DE SOUZA	6
30835229831	FABIO LOUREIRO MARTINS	6
27386967837	FABIO VALERIANO MACARENKO	7
03150578825	FATIMA APARECIDA AFONSO	9
30215534867	FRANCIS JONAS BUENO TOL	6
53165659249	GUILHERME FABIANO RAPOSO DA CAMARA GOMES	6
09538794613	GUSTAVO RODRIGO LOPES COELHO	5
35583094800	HELIO BRUNO DE CARVALHO GUTIERRE	6
32867795800	HELOISA LIMA DE SOUZA SYLLOS	7
40112878814	HENRIQUE GIRAO DE SOUZA	6
39086002862	IGOR CARITA GAGLIARDI	7
77116704272	IGOR CONTENTE PESSOA E SILVA	6
11524772690	IGOR RUAN BATISTA DE ARAUJO	5
26014480838	ILIAN ORIAS SIMAO MELLO	7
13949690824	ISAIAS SANTOS OSSAIN	7
01605509809	ISILDA APARECIDA DA COSTA BRIGATO	7
26139264812	ISMAEL FERREIRA DOS SANTOS	7
28532413862	IVAN BARBOSA DE CASTRO	7
45410986873	JESSICA FERNANDA GOMES DE OLIVEIRA	6
90201140853	JOAO BATISTA VASCONCELOS	5
22787421830	JOAO PAULO LOURENÃ‡O	7
32056299810	JOAO ROBERTO MENDES JUNIOR	9
12361525810	JOENIL APARECIDO VARUZZA	6
13619462100	JORGE APARECIDO FRANCO DE MORAIS	7
19162934848	JOSE AUGUSTO GOMES DA SILVA JUNIOR	6
21417124830	JOSE ROBERTO JACON JUNIOR	6
08169010829	JULIO CESAR FABBRI	7
38195846840	LAIS CAROLINE LONGO	6
45646950880	LARISSA DE MATOS BEZERRA	1
09256969866	LAURO MARCELLO BASSETTO	3
12423786778	LEONARDO ARGON BARROS	6
02052915621	LETICIA RIBEIRO DE VASCONCELOS	6
32439162833	LIVIA MARIA FERRAZ HERNANDES	6
01543222293	LUCAS MELO LIMA	6
44580937833	LUCAS PUERTAS GORONOSKI MARTINS	7
11374958638	LUCAS VINICIUS DE AQUINO	6
16068082814	LUCIANA CRISTINA BARBIERI	2
15328001850	LUCIANA CRISTINA DA SILVA CORTEZ	6
13933597870	LUCIMEIRE LABACI	7
07469562826	LUIZ FERNANDO VIEIRA	6
06587581609	LUIZ GUILHERME SALLES BARBOSA	5
54283108804	LUIZ SERGIO ANTUNES	7
15476249818	MAGDA PECCIN	6
06121749563	MARCOS ANTONIO SILVA DOS SANTOS	6
01717301860	MARCOS LUIZ DA CRUZ	7
08786765892	MARCOS ROBERTO TROTTMANN	7
05567298625	MARCUS VINICIUS CHAVES MATEUS	6
19031748803	MARIO DA CONCEIÃ‡ÃƒO	4
06281790812	MAURO CESAR MARTINATI	7
20089232828	MAXIMILIANO ZANIRATO	7
27192816892	MICHELLE DE GUSMAO SANA	2
06766970898	NILSON ORSI	1
32241919888	ORLANDO SILVA DO NASCIMENTO	6
31980964807	OTAVIO AUGUSTO SANTOS	6
42539612822	OTAVIO VOLPINI SILVA	5
29285851843	RAFAEL DE LIMA CAETANO COSTA	7
38446914808	RAFAEL DE OLIVEIRA LOPES	9
33507725878	RAFAEL HENRIQUE ESCAME	7
03331373885	RAQUEL DE FATIMA CATTAI DE MILHÃƒ	7
13950556885	RAQUEL WICHMANN	6
08481279862	REGINALDO JOSE DE GODOY PONCE	7
43018515854	RENAN CUSTODIO FLORES	7
25259367871	RICARDO ALFREDO COELHO	7
19696591810	RICARDO ALLEONI SILVA MORAES	6
27737321896	RICARDO DA CONCEICAO LOURENCO	1
27704968831	RICARDO LUIS DA FONSECA	6
20536048835	ROBERTO DE SOUZA	6
25104507866	RODRIGO CYPRIANO	7
42798376866	RODRIGO FERNANDES LEAO	7
40946122890	RODRIGO HERRERO MACEDO	6
26767691895	RODRIGO RODRIGUES	5
10743962869	ROGERIO MARCIO DE OLIVEIRA	7
65025822904	ROGERIO SARACINO	6
40401229840	RONIEL THALLES FIERS	6
07385667805	SEBASTIAO MARIO CAMBI	6
09591720840	SERGIO LUIZ DIAS RAMOS	1
69788146872	SIDNEI CAMARGO PERRONI	7
36508856898	STEVAN RICARDO BORDIGNON	9
40147397839	TALITA NAVARRO FIORINI DE ARAÃšJO	5
30819714895	TATIANE CRISTINA PARIZOTTO	5
28727655814	TELMA PATRICIA BARBOZA	6
10914036602	THAMIRIS RODRIGUES LEMES PEREIRA	6
42709193884	THIAGO VINICIUS GONÃ‡ALVES	7
38407577898	TIAGO MARCELINO ALVES	7
39262187890	VALERIA ANTONIA DOS SANTOS	6
01610216890	VALMIR VICENTE DE SOUZA	4
43148543831	VICTOR SCHIAVELLI SARAN	6
36190735894	VINICIUS GRAF MEGIATO	6
33074022850	VITOR AMADEU LANDO DE CARVALHO	1
26997560830	WAGNER CESAR DA SILVA	2
10595150837	WILLIAN RICARDO DE ALMEIDA MARCHI	5
12328788807	ADRIANA CRISTINA DE MORAES	8
42582609838	ADRIELY VALERIA DE SOUZA	5
27057183895	ALEXANDRE FERRACIOLLI PEREIRA	5
46508753827	ALISSON DE AZEVEDO FEITOSA	6
21360741801	ANDERSON ADRIANO FORTI BUENO	1
16791203870	ARLEI ANTONIO BALDIN	6
04307176103	BRENO MUNIZ MAJADAS	7
12375581660	BRUNA LOES DE AVILA	6
11374959600	BRUNA LUISA DE AQUINO	7
35313574841	BRUNO DE OLIVEIRA THOMAZ BERTANHA	7
43992425827	BRUNO HENRIQUE MARTINIANO DE OLIVEIRA	6
32540502822	CARLOS EDUARDO MALAMAN	5
24886549810	DANILO GUIGUER DE OLIVEIRA	7
21675933847	DIEGO GONÇALVES DE ALCANTARA	7
00496426850	EDGAR ALBANEZ	5
15721307846	EDNEIA REBERTI ESCAME	6
31892853817	EDUARDA PIGATO CISCATO	7
30310116864	ELTON LUCCAS TUCKUMANTEL	1
80184782104	ELY ALVES SILVA	7
31082697800	ERIC DE OLIVEIRA MOTTA	7
40381911845	EVERTON AGUILLAR BURATTO	7
07666429681	FABRICIO ANDRE DA SILVA	6
38355373855	FERNANDA SALCIOTTO	6
35932472839	FLAVIA CLAUDIANO CORDIDO	6
31239665857	FLAVIO HENRIQUE SUMAIO CALDEIRAO	7
01110375816	FRANCISCO PAULO OLIVEIRA LIMA	5
82897123915	GLADISON FRANCISCO DA SILVA	6
36025331820	GRACE LIE HAMADA	6
39460172822	ICARO JOSE RIBEIRO GOMES	5
06762410855	JERUSO ALVES NASCIMENTO	7
22444646878	JOAO PINHEIRO NETO	5
36819640846	KARINA MIZUNO KANNO	6
05484576709	LEONARDO DE OLIVEIRA BURGER MONTEIRO LUIZ	5
42610681844	LETICIA LEONOR RIBEIRO MENDES	9
32628691809	LETICIA ROSALES BATISTA	6
47033640854	LUCCA MENCHINELLI E SILVA	7
04704982858	LUIS FERNANDO CORADINI	1
08922377674	LUIS HENRIQUE LIMA PEREIRA	5
10995999899	LUSMARINA ZULMIRA GOMES	1
27206162819	MARCELO MARQUES DE OLIVEIRA	5
14694180703	MATEUS BRINATI MACHADO	7
09085540950	MATHEUS KLEPARDE	7
18208623806	MAURICIO MIRANDA DE QUEIROZ	5
30841335818	MAURO LEMOS DA SILVA	6
36750397816	OLIVER TOBIAS KLEIBER	7
19216935847	PAULO CESAR OLIVATO	7
07902044792	PAULO RICARDO DE AGUIAR LIMA	6
09595897833	PAULO SERGIO MISSANO	7
26451064807	RAFAEL SILVA VARUZZA	7
35500297805	RAFAEL SIQUEIRA	7
32968804880	RAONI MACHADO	7
10410326682	RENAN CHAMONE SILVA	7
19174943863	RICARDO ALEXANDRE DA SILVA	3
27935713855	RODRIGO PADOAN ALBANEZ	7
29474854831	RODRIGO VALERIANO MACARENKO	1
13934950876	ROGERIO NASCIMENTO SANTOS	4
19163513870	RONALDO VALERIO GENTIL	6
24999284847	TABAJARA ZULIANI DOS SANTOS	5
12794506730	THAIANE CAROLINE DA SILVA MAROTO VENTURA	6
40952268892	TIAGO ANDRADE PUCCI	7
10531583600	VALERIA GONÇALVES BATISTA FARIA	6
19203432884	VANDER APARECIDO MARCELINO CAPRIOGLIO	7
44519520851	VICTOR ALVITI DE CARVALHO	6
33648957830	VITOR XONE BUENO DA SILVA	6
\.


--
-- Data for Name: servidores_bkp_20261021_v2; Type: TABLE DATA; Schema: backup; Owner: postgres
--

COPY backup.servidores_bkp_20261021_v2 (cpf_servidor, nome_servidor, id_cargo) FROM stdin;
05733151838	ADALBERTO JORGE RODRIGUES	7
06346558501	ADALTO ALVES ROCHA NETO	7
14042095739	ADVAIR VASCONCELOS VELOSO DA SILVA	7
30379558807	ALBERTO RAHAL NETO	7
31156936802	ALESSANDRO ROGERIO DOS SANTOS	1
17162481833	ALEXANDRE SIMÃ•ES SILVA	3
84922001891	AMERICO SIDNEI RISSATO	5
17559994881	ANDRE LUIS DA SILVA	6
35981258870	ANDRE LUIS FABRES	6
40300050801	ANDREA DANTAS LEVY	5
39510249840	ANGELA DE LIMA DALTIN	6
17764814881	ANTONIO LUIS FIOR	7
60115700978	ANTONIO ONOFRE	7
17416608821	ARAGAO XAVIER DA SILVA	7
09433315952	BIANCA CRISTINA DA SILVA RITTER	6
39259259886	BRUNO AZZINI TIOSSO	1
21819139867	BRUNO RODRIGUES JACON	7
30158768809	CARLOS ADRIANO BERTTO CABRINI	2
07884129817	CARLOS ALBERTO LIBARDI	2
37550429839	CARLOS EDUARDO STRABELLI	6
11548143863	CARLOS EDUARDO ZURITA LEONI	7
06851660660	CHRISTIANO GONÃ‡ALVES VIDAL	7
38672275861	CINTIA APARECIDA VENANCIO FABRIS	6
05733042893	CLAUDINEI FERREIRA	4
43646474890	CLEBER MEIRA JUNIOR	6
19214657866	CRISTIANO EDUARDO PENTEADO	6
04611267881	DALTON EDUARDO METZNER	1
31111293813	DANIELE APARECIDA VIELLI	6
06432966620	DIOGO FRANCISCO DE BRITO	7
39101020854	DOMINIC ALVES FERREIRA	6
13600008790	DOUGLAS GUIMARAES PINA BASTOS	7
06292282805	EDINELSON APARECIDO OLICHESCKI	6
12382786639	EDUARDO SUEIT JUNIOR	7
16079405822	EITHEL DINAEL STRABELLI	7
25180228808	EJEFERSON ARRAEZ LOPES	6
14743987822	ELAINE CRISTINA RODRIGUES	6
06730855894	ELIANE MARIA CAMOLESI	6
02788546807	ELIAS DE OLIVEIRA	3
40764409867	ELIAS GABRIEL DE OLIVEIRA PISSE	6
85920356510	EMILLE BORBUREMA DE OLIVEIRA MACHADO	7
00985216328	EVELYN KAFA LOIOLA DOMIATE	5
14716979830	EVERTON DE OLIVEIRA CARDOSO	6
41059752859	EWERTON REINALDO PEREIRA LOPES	6
36822427830	FABIANA SINIBALDI BARBOSA	6
10096636823	FABIO CORREA DE SOUZA	6
30835229831	FABIO LOUREIRO MARTINS	6
27386967837	FABIO VALERIANO MACARENKO	7
03150578825	FATIMA APARECIDA AFONSO	9
30215534867	FRANCIS JONAS BUENO TOL	6
53165659249	GUILHERME FABIANO RAPOSO DA CAMARA GOMES	6
09538794613	GUSTAVO RODRIGO LOPES COELHO	5
35583094800	HELIO BRUNO DE CARVALHO GUTIERRE	6
32867795800	HELOISA LIMA DE SOUZA SYLLOS	7
40112878814	HENRIQUE GIRAO DE SOUZA	6
39086002862	IGOR CARITA GAGLIARDI	7
77116704272	IGOR CONTENTE PESSOA E SILVA	6
11524772690	IGOR RUAN BATISTA DE ARAUJO	5
26014480838	ILIAN ORIAS SIMAO MELLO	7
13949690824	ISAIAS SANTOS OSSAIN	7
01605509809	ISILDA APARECIDA DA COSTA BRIGATO	7
26139264812	ISMAEL FERREIRA DOS SANTOS	7
28532413862	IVAN BARBOSA DE CASTRO	7
45410986873	JESSICA FERNANDA GOMES DE OLIVEIRA	6
90201140853	JOAO BATISTA VASCONCELOS	5
22787421830	JOAO PAULO LOURENÃ‡O	7
32056299810	JOAO ROBERTO MENDES JUNIOR	9
12361525810	JOENIL APARECIDO VARUZZA	6
13619462100	JORGE APARECIDO FRANCO DE MORAIS	7
19162934848	JOSE AUGUSTO GOMES DA SILVA JUNIOR	6
21417124830	JOSE ROBERTO JACON JUNIOR	6
08169010829	JULIO CESAR FABBRI	7
38195846840	LAIS CAROLINE LONGO	6
45646950880	LARISSA DE MATOS BEZERRA	1
09256969866	LAURO MARCELLO BASSETTO	3
12423786778	LEONARDO ARGON BARROS	6
02052915621	LETICIA RIBEIRO DE VASCONCELOS	6
32439162833	LIVIA MARIA FERRAZ HERNANDES	6
01543222293	LUCAS MELO LIMA	6
44580937833	LUCAS PUERTAS GORONOSKI MARTINS	7
11374958638	LUCAS VINICIUS DE AQUINO	6
16068082814	LUCIANA CRISTINA BARBIERI	2
15328001850	LUCIANA CRISTINA DA SILVA CORTEZ	6
13933597870	LUCIMEIRE LABACI	7
07469562826	LUIZ FERNANDO VIEIRA	6
06587581609	LUIZ GUILHERME SALLES BARBOSA	5
54283108804	LUIZ SERGIO ANTUNES	7
15476249818	MAGDA PECCIN	6
06121749563	MARCOS ANTONIO SILVA DOS SANTOS	6
01717301860	MARCOS LUIZ DA CRUZ	7
08786765892	MARCOS ROBERTO TROTTMANN	7
05567298625	MARCUS VINICIUS CHAVES MATEUS	6
19031748803	MARIO DA CONCEIÃ‡ÃƒO	4
06281790812	MAURO CESAR MARTINATI	7
20089232828	MAXIMILIANO ZANIRATO	7
27192816892	MICHELLE DE GUSMAO SANA	2
06766970898	NILSON ORSI	1
32241919888	ORLANDO SILVA DO NASCIMENTO	6
31980964807	OTAVIO AUGUSTO SANTOS	6
42539612822	OTAVIO VOLPINI SILVA	5
29285851843	RAFAEL DE LIMA CAETANO COSTA	7
38446914808	RAFAEL DE OLIVEIRA LOPES	9
33507725878	RAFAEL HENRIQUE ESCAME	7
03331373885	RAQUEL DE FATIMA CATTAI DE MILHÃƒ	7
13950556885	RAQUEL WICHMANN	6
08481279862	REGINALDO JOSE DE GODOY PONCE	7
43018515854	RENAN CUSTODIO FLORES	7
25259367871	RICARDO ALFREDO COELHO	7
19696591810	RICARDO ALLEONI SILVA MORAES	6
27737321896	RICARDO DA CONCEICAO LOURENCO	1
27704968831	RICARDO LUIS DA FONSECA	6
20536048835	ROBERTO DE SOUZA	6
25104507866	RODRIGO CYPRIANO	7
42798376866	RODRIGO FERNANDES LEAO	7
40946122890	RODRIGO HERRERO MACEDO	6
26767691895	RODRIGO RODRIGUES	5
10743962869	ROGERIO MARCIO DE OLIVEIRA	7
65025822904	ROGERIO SARACINO	6
40401229840	RONIEL THALLES FIERS	6
07385667805	SEBASTIAO MARIO CAMBI	6
09591720840	SERGIO LUIZ DIAS RAMOS	1
69788146872	SIDNEI CAMARGO PERRONI	7
36508856898	STEVAN RICARDO BORDIGNON	9
40147397839	TALITA NAVARRO FIORINI DE ARAÃšJO	5
30819714895	TATIANE CRISTINA PARIZOTTO	5
28727655814	TELMA PATRICIA BARBOZA	6
10914036602	THAMIRIS RODRIGUES LEMES PEREIRA	6
42709193884	THIAGO VINICIUS GONÃ‡ALVES	7
38407577898	TIAGO MARCELINO ALVES	7
39262187890	VALERIA ANTONIA DOS SANTOS	6
01610216890	VALMIR VICENTE DE SOUZA	4
43148543831	VICTOR SCHIAVELLI SARAN	6
36190735894	VINICIUS GRAF MEGIATO	6
33074022850	VITOR AMADEU LANDO DE CARVALHO	1
26997560830	WAGNER CESAR DA SILVA	2
10595150837	WILLIAN RICARDO DE ALMEIDA MARCHI	5
12328788807	ADRIANA CRISTINA DE MORAES	8
42582609838	ADRIELY VALERIA DE SOUZA	5
27057183895	ALEXANDRE FERRACIOLLI PEREIRA	5
46508753827	ALISSON DE AZEVEDO FEITOSA	6
21360741801	ANDERSON ADRIANO FORTI BUENO	1
16791203870	ARLEI ANTONIO BALDIN	6
04307176103	BRENO MUNIZ MAJADAS	7
12375581660	BRUNA LOES DE AVILA	6
11374959600	BRUNA LUISA DE AQUINO	7
35313574841	BRUNO DE OLIVEIRA THOMAZ BERTANHA	7
43992425827	BRUNO HENRIQUE MARTINIANO DE OLIVEIRA	6
32540502822	CARLOS EDUARDO MALAMAN	5
24886549810	DANILO GUIGUER DE OLIVEIRA	7
21675933847	DIEGO GONÇALVES DE ALCANTARA	7
00496426850	EDGAR ALBANEZ	5
15721307846	EDNEIA REBERTI ESCAME	6
31892853817	EDUARDA PIGATO CISCATO	7
30310116864	ELTON LUCCAS TUCKUMANTEL	1
80184782104	ELY ALVES SILVA	7
31082697800	ERIC DE OLIVEIRA MOTTA	7
40381911845	EVERTON AGUILLAR BURATTO	7
07666429681	FABRICIO ANDRE DA SILVA	6
38355373855	FERNANDA SALCIOTTO	6
35932472839	FLAVIA CLAUDIANO CORDIDO	6
31239665857	FLAVIO HENRIQUE SUMAIO CALDEIRAO	7
01110375816	FRANCISCO PAULO OLIVEIRA LIMA	5
82897123915	GLADISON FRANCISCO DA SILVA	6
36025331820	GRACE LIE HAMADA	6
39460172822	ICARO JOSE RIBEIRO GOMES	5
06762410855	JERUSO ALVES NASCIMENTO	7
22444646878	JOAO PINHEIRO NETO	5
36819640846	KARINA MIZUNO KANNO	6
05484576709	LEONARDO DE OLIVEIRA BURGER MONTEIRO LUIZ	5
42610681844	LETICIA LEONOR RIBEIRO MENDES	9
32628691809	LETICIA ROSALES BATISTA	6
47033640854	LUCCA MENCHINELLI E SILVA	7
04704982858	LUIS FERNANDO CORADINI	1
08922377674	LUIS HENRIQUE LIMA PEREIRA	5
10995999899	LUSMARINA ZULMIRA GOMES	1
27206162819	MARCELO MARQUES DE OLIVEIRA	5
14694180703	MATEUS BRINATI MACHADO	7
09085540950	MATHEUS KLEPARDE	7
18208623806	MAURICIO MIRANDA DE QUEIROZ	5
30841335818	MAURO LEMOS DA SILVA	6
36750397816	OLIVER TOBIAS KLEIBER	7
19216935847	PAULO CESAR OLIVATO	7
07902044792	PAULO RICARDO DE AGUIAR LIMA	6
09595897833	PAULO SERGIO MISSANO	7
26451064807	RAFAEL SILVA VARUZZA	7
35500297805	RAFAEL SIQUEIRA	7
32968804880	RAONI MACHADO	7
10410326682	RENAN CHAMONE SILVA	7
19174943863	RICARDO ALEXANDRE DA SILVA	3
27935713855	RODRIGO PADOAN ALBANEZ	7
29474854831	RODRIGO VALERIANO MACARENKO	1
13934950876	ROGERIO NASCIMENTO SANTOS	4
19163513870	RONALDO VALERIO GENTIL	6
24999284847	TABAJARA ZULIANI DOS SANTOS	5
12794506730	THAIANE CAROLINE DA SILVA MAROTO VENTURA	6
40952268892	TIAGO ANDRADE PUCCI	7
10531583600	VALERIA GONÇALVES BATISTA FARIA	6
19203432884	VANDER APARECIDO MARCELINO CAPRIOGLIO	7
44519520851	VICTOR ALVITI DE CARVALHO	6
33648957830	VITOR XONE BUENO DA SILVA	6
\.


--
-- Data for Name: auditoria_log; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.auditoria_log (id_log, tabela, operacao, usuario_bd, data_evento, chave_registro, dados_anteriores, dados_novos) FROM stdin;
\.


--
-- Data for Name: auditoria_migracao; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.auditoria_migracao (id, data_execucao, etapa, status, observacao) FROM stdin;
1	2026-10-21 15:01:03.01434	SCHEMA BACKUP	OK	Schema criado
\.


--
-- Data for Name: cargo; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.cargo (id_cargo, nome_cargo) FROM stdin;
1	AGEPOL
2	AGETEL
3	CARCEIREIRO
4	CARCEREIRO
5	DELEGADO
7	INVESTIGADOR
8	OFICIAL ADMINISTRATIVO
9	PAPILOSCOPISTA
6	ESCRIVAO
\.


--
-- Data for Name: diarias; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.diarias (id_diaria, cpf_servidor, id_tipo, data_inicial, destino, motivo, valor_diaria, data_cadastro, id_processo, observacao, numero_pd) FROM stdin;
521	04307176103	1	2026-02-10	SAO PAULO	SERVICO POLICIAL	248.96	2026-10-13 17:57:00.859604	505	\N	2026PD00068
523	11374959600	1	2026-08-05	BARUERI	SERVICO POLICIAL	103.73	2026-10-13 17:57:00.859604	393	\N	2026PD00334
524	11374959600	1	2026-08-17	PIRACICABA	SERVICO POLICIAL	103.73	2026-10-13 17:57:00.859604	473	\N	2026PD00402
850	18208623806	2	2026-05-25	SAO PAULO	PALESTRA SISTEMA DE JUSTICA	248.96	2026-10-21 09:58:26.750297	450	\N	2026PD00220
441	12794506730	1	2026-06-09	SAO PAULO	SERVICO POLICIAL	248.96	2026-10-13 17:57:00.859604	457	\N	2026PD00296
689	19174943863	1	2026-02-20	SAO PAULO	SERVICO POLICIAL	248.96	2026-10-13 17:57:00.859604	427	\N	2026PD00071
447	19203432884	1	2026-04-15	SAO PAULO	SERVICO POLICIAL	248.96	2026-10-13 17:57:00.859604	506	\N	2026PD00174
448	19203432884	1	2026-06-09	SAO PAULO	SERVICO POLICIAL	248.96	2026-10-13 17:57:00.859604	453	\N	2026PD00285
639	19216935847	1	2026-03-06	JAGUARIUNA	SERVICO POLICIAL	69.15	2026-10-13 17:57:00.859604	390	\N	2026PD00117
517	21360741801	1	2026-02-12	CAPIVARI	SERVICO POLICIAL	138.31	2026-10-13 17:57:00.859604	417	\N	2026PD00072
518	21360741801	1	2026-03-13	PIRACICABA	SERVICO POLICIAL	53.78	2026-10-13 17:57:00.859604	499	\N	2026PD00118
519	21360741801	1	2026-03-20	SAO PAULO	SERVICO POLICIAL	96.81	2026-10-13 17:57:00.859604	536	\N	2026PD00118
534	21675933847	1	2026-02-26	POÇOS DE CALDAS	SERVICO POLICIAL	207.46	2026-10-13 17:57:00.859604	545	\N	2026PD00119
533	24886549810	1	2026-04-15	SAO PAULO	SERVICO POLICIAL	248.96	2026-10-13 17:57:00.859604	525	\N	2026PD00175
812	19216935847	1	2026-04-16	LIMEIRA	SERVICO POLICIAL	103.73	2026-10-14 15:17:54.234558	557	\N	2026PD00194
632	30841335818	1	2026-06-09	SAO PAULO	SERVICO POLICIAL	248.96	2026-10-13 17:57:00.859604	439	\N	\N
633	30841335818	1	2026-07-09	SAO PAULO	SERVICO POLICIAL	248.96	2026-10-13 17:57:00.859604	439	\N	\N
538	31082697800	1	2026-08-17	PIRACICABA	SERVICO POLICIAL	103.73	2026-10-13 17:57:00.859604	474	\N	2026PD00402
544	31239665857	1	2026-02-10	SAO PAULO	SERVICO POLICIAL	248.96	2026-10-13 17:57:00.859604	510	\N	2026PD00075
545	31239665857	1	2026-03-06	JAGUARIUNA	SERVICO POLICIAL	69.15	2026-10-13 17:57:00.859604	504	\N	2026PD00121
546	31239665857	1	2026-03-11	RIO CLARO	SERVICO POLICIAL	69.15	2026-10-13 17:57:00.859604	481	\N	2026PD00121
535	31892853817	1	2026-03-06	JAGUARIUNA	SERVICO POLICIAL	69.15	2026-10-13 17:57:00.859604	385	\N	2026PD00122
528	32540502822	1	2026-04-25	LIMEIRA	SERVICO POLICIAL	138.31	2026-10-13 17:57:00.859604	424	\N	2026PD00177
635	36750397816	1	2026-03-10	MONTE MOR	SERVICO POLICIAL	69.15	2026-10-13 17:57:00.859604	442	\N	2026PD00125
636	36750397816	1	2026-03-13	PIRACICABA	SERVICO POLICIAL	69.15	2026-10-13 17:57:00.859604	373	\N	2026PD00125
637	36750397816	1	2026-04-09	SAO PAULO	SERVICO POLICIAL	248.96	2026-10-13 17:57:00.859604	482	\N	2026PD00178
543	38355373855	1	2026-08-05	PIRACICABA	SERVICO POLICIAL	103.73	2026-10-13 17:57:00.859604	507	\N	2026PD00402
550	39460172822	1	2026-02-10	SAO PAULO	SERVICO POLICIAL	248.96	2026-10-13 17:57:00.859604	548	\N	2026PD00080
552	39460172822	1	2026-03-06	JAGUARIUNA	SERVICO POLICIAL	69.15	2026-10-13 17:57:00.859604	554	\N	2026PD00126
553	39460172822	1	2026-04-26	LIMEIRA	SERVICO POLICIAL	207.45	2026-10-13 17:57:00.859604	551	\N	2026PD00179
539	40381911845	1	2026-02-25	SAO PAULO	SERVICO POLICIAL	248.96	2026-10-13 17:57:00.859604	498	\N	2026PD00081
540	40381911845	1	2026-02-26	POÇOS DE CALDAS	SERVICO POLICIAL	207.46	2026-10-13 17:57:00.859604	410	\N	2026PD00081
541	40381911845	1	2026-06-19	RIO DE JANEIRO	SERVICO POLICIAL	822.94	2026-10-13 17:57:00.859604	518	\N	2026PD00293
442	40952268892	1	2026-02-12	CAPIVARI	SERVICO POLICIAL	138.31	2026-10-13 17:57:00.859604	406	\N	2026PD00082
443	40952268892	1	2026-03-10	MONTE MOR	SERVICO POLICIAL	69.15	2026-10-13 17:57:00.859604	392	\N	2026PD00127
444	40952268892	1	2026-03-13	PIRACICABA	SERVICO POLICIAL	69.15	2026-10-13 17:57:00.859604	527	\N	2026PD00127
445	40952268892	1	2026-04-09	SAO PAULO	SERVICO POLICIAL	248.96	2026-10-13 17:57:00.859604	467	\N	2026PD00180
816	35500297805	1	2026-06-19	RIO DE JANEIRO	SERVICO POLICIAL	822.94	2026-10-14 15:30:36.609726	399	\N	2026PD00291
562	42610681844	1	2026-05-20	SAO PAULO	SERVICO POLICIAL	193.63	2026-10-13 17:57:00.859604	559	\N	2026PD00246
563	42610681844	1	2026-06-09	SAO PAULO	SERVICO POLICIAL	193.63	2026-10-13 17:57:00.859604	411	\N	2026PD00294
449	44519520851	1	2026-06-01	LIMEIRA	SERVICO POLICIAL	69.15	2026-10-13 17:57:00.859604	420	\N	2026PD00297
450	44519520851	1	2026-06-02	LIMEIRA	SERVICO POLICIAL	69.15	2026-10-13 17:57:00.859604	420	\N	2026PD00297
451	44519520851	1	2026-06-03	LIMEIRA	SERVICO POLICIAL	69.15	2026-10-13 17:57:00.859604	420	\N	2026PD00297
452	44519520851	1	2026-06-04	LIMEIRA	SERVICO POLICIAL	69.15	2026-10-13 17:57:00.859604	420	\N	2026PD00297
453	44519520851	1	2026-06-05	LIMEIRA	SERVICO POLICIAL	69.15	2026-10-13 17:57:00.859604	420	\N	2026PD00297
454	44519520851	1	2026-06-08	LIMEIRA	SERVICO POLICIAL	69.15	2026-10-13 17:57:00.859604	420	\N	2026PD00297
455	44519520851	1	2026-06-09	LIMEIRA	SERVICO POLICIAL	69.15	2026-10-13 17:57:00.859604	420	\N	2026PD00297
456	44519520851	1	2026-06-10	LIMEIRA	SERVICO POLICIAL	69.15	2026-10-13 17:57:00.859604	420	\N	2026PD00297
457	44519520851	1	2026-06-11	LIMEIRA	SERVICO POLICIAL	69.15	2026-10-13 17:57:00.859604	420	\N	2026PD00297
458	44519520851	1	2026-06-12	LIMEIRA	SERVICO POLICIAL	69.15	2026-10-13 17:57:00.859604	420	\N	2026PD00297
459	44519520851	1	2026-06-15	LIMEIRA	SERVICO POLICIAL	69.15	2026-10-13 17:57:00.859604	420	\N	2026PD00297
460	44519520851	1	2026-06-16	LIMEIRA	SERVICO POLICIAL	69.15	2026-10-13 17:57:00.859604	420	\N	2026PD00297
461	44519520851	1	2026-06-17	LIMEIRA	SERVICO POLICIAL	69.15	2026-10-13 17:57:00.859604	420	\N	2026PD00297
462	44519520851	1	2026-06-18	LIMEIRA	SERVICO POLICIAL	69.15	2026-10-13 17:57:00.859604	420	\N	2026PD00297
463	44519520851	1	2026-06-19	LIMEIRA	SERVICO POLICIAL	69.15	2026-10-13 17:57:00.859604	420	\N	2026PD00297
464	44519520851	1	2026-06-22	LIMEIRA	SERVICO POLICIAL	69.15	2026-10-13 17:57:00.859604	420	\N	2026PD00297
465	44519520851	1	2026-06-23	LIMEIRA	SERVICO POLICIAL	69.15	2026-10-13 17:57:00.859604	420	\N	2026PD00297
466	44519520851	1	2026-06-24	LIMEIRA	SERVICO POLICIAL	69.15	2026-10-13 17:57:00.859604	420	\N	2026PD00297
467	44519520851	1	2026-06-25	LIMEIRA	SERVICO POLICIAL	69.15	2026-10-13 17:57:00.859604	420	\N	2026PD00297
468	44519520851	1	2026-06-26	LIMEIRA	SERVICO POLICIAL	69.15	2026-10-13 17:57:00.859604	420	\N	2026PD00297
834	85920356510	2	2026-09-26	PIRACICABA	CURSO MBA	103.73	2026-10-15 15:54:20.108825	583	\N	2026PD00418
845	09085540950	1	2026-09-25	SAO PAULO	SERVICO POLICIAL	124.48	2026-10-15 15:58:54.507043	585	\N	2026PD00420
813	07902044792	1	2026-04-09	SAO PAULO	SERVICO POLICIAL	124.48	2026-10-14 15:20:48.32486	562	\N	2026PD00171
814	09595897833	1	2026-02-12	CAPIVARI	SERVICO POLICIAL	69.15	2026-10-14 15:23:19.777539	412	\N	2026PD00069
649	10410326682	1	2026-01-07	PIRACICABA	PLANTAO POLICIAL LIMEIRA	207.46	2026-10-13 17:57:00.859604	446	\N	2026PD00047
821	10410326682	1	2026-02-14	PIRASSUNUNGA	SERVICO POLICIAL	138.31	2026-10-14 15:47:02.602612	444	\N	2026PD00114
822	10410326682	1	2026-02-15	PIRASSUNUNGA	SERVICO POLICIAL	138.31	2026-10-14 15:47:17.322943	444	\N	2026PD00114
825	10410326682	1	2026-02-22	PIRASSUNUNGA	SERVICO POLICIAL	69.15	2026-10-14 15:47:48.416271	444	\N	2026PD00114
823	10410326682	1	2026-02-23	PIRASSUNUNGA	SERVICO POLICIAL	138.31	2026-10-14 15:47:26.244429	444	\N	2026PD00114
824	10410326682	1	2026-02-27	PIRASSUNUNGA	SERVICO POLICIAL	138.31	2026-10-14 15:47:32.122151	444	\N	2026PD00114
817	32968804880	1	2026-01-27	PIRACICABA	SERVICO POLICIAL	207.46	2026-10-14 15:33:21.063693	543	\N	2026PD00055
818	32968804880	1	2026-02-17	LIMEIRA	SERVICO POLICIAL	103.73	2026-10-14 15:36:06.032777	387	\N	2026PD00077
648	32968804880	1	2026-03-06	JAGUARIUNA	SERVICO POLICIAL	69.15	2026-10-13 17:57:00.859604	512	\N	2026PD00123
852	01110375816	2	2026-09-06	SAO PAULO	CURSO SUPERIOR DE POLICIA	3112.00	2026-10-23 16:07:44.875214	589	Lançamento manual	2026PD00408
835	10995999899	1	2026-09-01	LIMEIRA	ACUMULO DE FUNCAO	107.57	2026-10-15 15:55:55.417902	584	\N	2026PD00419
836	10995999899	1	2026-09-04	LIMEIRA	ACUMULO DE FUNCAO	107.57	2026-10-15 15:56:01.455005	584	\N	2026PD00419
837	10995999899	1	2026-09-07	LIMEIRA	ACUMULO DE FUNCAO	107.57	2026-10-15 15:56:06.780392	584	\N	2026PD00419
838	10995999899	1	2026-09-10	LIMEIRA	ACUMULO DE FUNCAO	107.57	2026-10-15 15:56:12.032533	584	\N	2026PD00419
839	10995999899	1	2026-09-13	LIMEIRA	ACUMULO DE FUNCAO	107.57	2026-10-15 15:56:20.680416	584	\N	2026PD00419
840	10995999899	1	2026-09-14	LIMEIRA	ACUMULO DE FUNCAO	107.57	2026-10-15 15:56:26.064817	584	\N	2026PD00419
841	10995999899	1	2026-09-16	LIMEIRA	ACUMULO DE FUNCAO	107.57	2026-10-15 15:56:32.12167	584	\N	2026PD00419
842	10995999899	1	2026-09-22	LIMEIRA	ACUMULO DE FUNCAO	107.57	2026-10-15 15:56:38.802749	584	\N	2026PD00419
843	10995999899	1	2026-09-25	LIMEIRA	ACUMULO DE FUNCAO	107.57	2026-10-15 15:56:43.449109	584	\N	2026PD00419
844	10995999899	1	2026-09-28	LIMEIRA	ACUMULO DE FUNCAO	107.57	2026-10-15 15:56:49.346365	584	\N	2026PD00419
847	13934950876	1	2026-09-26	LIMEIRA	ACUMULO DE FUNCAO	161.36	2026-10-15 16:01:12.186859	586	\N	2026PD00421
848	13934950876	1	2026-09-27	LIMEIRA	ACUMULO DE FUNCAO	161.36	2026-10-15 16:01:20.301849	586	\N	2026PD00421
849	13934950876	1	2026-09-28	LIMEIRA	ACUMULO DE FUNCAO	161.36	2026-10-15 16:01:27.748525	586	\N	2026PD00421
574	10995999899	1	2026-03-21	LIMEIRA	ACUMULO DE FUNCAO	107.57	2026-10-13 17:57:00.859604	434	\N	2026PD00115
575	10995999899	1	2026-03-25	LIMEIRA	ACUMULO DE FUNCAO	107.57	2026-10-13 17:57:00.859604	434	\N	2026PD00115
576	10995999899	1	2026-04-02	LIMEIRA	ACUMULO DE FUNCAO	107.57	2026-10-13 17:57:00.859604	528	\N	2026PD00173
577	10995999899	1	2026-04-04	LIMEIRA	ACUMULO DE FUNCAO	107.57	2026-10-13 17:57:00.859604	528	\N	2026PD00173
578	10995999899	1	2026-04-05	LIMEIRA	ACUMULO DE FUNCAO	107.57	2026-10-13 17:57:00.859604	528	\N	2026PD00173
579	10995999899	1	2026-04-08	LIMEIRA	ACUMULO DE FUNCAO	107.57	2026-10-13 17:57:00.859604	528	\N	2026PD00173
580	10995999899	1	2026-04-10	LIMEIRA	ACUMULO DE FUNCAO	107.57	2026-10-13 17:57:00.859604	528	\N	2026PD00173
581	10995999899	1	2026-05-01	LIMEIRA	ACUMULO DE FUNCAO	107.57	2026-10-13 17:57:00.859604	523	\N	2026PD00238
567	10995999899	1	2026-03-01	LIMEIRA	ACUMULO DE FUNCAO	107.57	2026-10-13 17:57:00.859604	434	\N	2026PD00115
853	05484576709	2	2026-05-04	SAO PAULO	CURSO APH	248.96	2026-10-26 09:07:50.987737	590	Lançamento manual	2026PD00219
854	05484576709	2	2026-05-05	SAO PAULO	CURSO APH	248.96	2026-10-26 09:07:50.987737	590	Lançamento manual	2026PD00219
855	05484576709	2	2026-05-06	SAO PAULO	CURSO APH	248.96	2026-10-26 09:07:50.987737	590	Lançamento manual	2026PD00219
856	05484576709	2	2026-05-07	SAO PAULO	CURSO APH	248.96	2026-10-26 09:07:50.987737	590	Lançamento manual	2026PD00219
857	05484576709	2	2026-05-08	SAO PAULO	CURSO APH	248.96	2026-10-26 09:07:50.987737	590	Lançamento manual	2026PD00219
858	05484576709	2	2026-05-11	SAO PAULO	CURSO APH	248.96	2026-10-26 09:07:50.987737	590	Lançamento manual	2026PD00219
859	05484576709	2	2026-05-12	SAO PAULO	CURSO APH	248.96	2026-10-26 09:07:50.987737	590	Lançamento manual	2026PD00219
860	05484576709	2	2026-05-13	SAO PAULO	CURSO APH	248.96	2026-10-26 09:07:50.987737	590	Lançamento manual	2026PD00219
861	05484576709	2	2026-05-14	SAO PAULO	CURSO APH	248.96	2026-10-26 09:07:50.987737	590	Lançamento manual	2026PD00219
862	05484576709	2	2026-05-15	SAO PAULO	CURSO APH	248.96	2026-10-26 09:07:50.987737	590	Lançamento manual	2026PD00219
627	09085540950	1	2026-08-05	CASA BRANCA	SERVICO POLICIAL	207.46	2026-10-13 17:57:00.859604	466	\N	2026PD00344
568	10995999899	1	2026-03-04	LIMEIRA	ACUMULO DE FUNCAO	107.57	2026-10-13 17:57:00.859604	434	\N	2026PD00115
569	10995999899	1	2026-03-06	LIMEIRA	ACUMULO DE FUNCAO	107.57	2026-10-13 17:57:00.859604	434	\N	2026PD00115
570	10995999899	1	2026-03-07	LIMEIRA	ACUMULO DE FUNCAO	107.57	2026-10-13 17:57:00.859604	434	\N	2026PD00115
571	10995999899	1	2026-03-10	LIMEIRA	ACUMULO DE FUNCAO	107.57	2026-10-13 17:57:00.859604	434	\N	2026PD00115
572	10995999899	1	2026-03-13	LIMEIRA	ACUMULO DE FUNCAO	107.57	2026-10-13 17:57:00.859604	434	\N	2026PD00115
573	10995999899	1	2026-03-17	LIMEIRA	ACUMULO DE FUNCAO	107.57	2026-10-13 17:57:00.859604	434	\N	2026PD00115
582	10995999899	1	2026-05-05	LIMEIRA	ACUMULO DE FUNCAO	107.57	2026-10-13 17:57:00.859604	523	\N	2026PD00238
583	10995999899	1	2026-05-07	LIMEIRA	ACUMULO DE FUNCAO	107.57	2026-10-13 17:57:00.859604	523	\N	2026PD00238
584	10995999899	1	2026-05-09	LIMEIRA	ACUMULO DE FUNCAO	107.57	2026-10-13 17:57:00.859604	523	\N	2026PD00238
585	10995999899	1	2026-06-01	LIMEIRA	ACUMULO DE FUNCAO	107.57	2026-10-13 17:57:00.859604	542	\N	2026PD00282
586	10995999899	1	2026-06-02	LIMEIRA	ACUMULO DE FUNCAO	107.57	2026-10-13 17:57:00.859604	542	\N	2026PD00282
587	10995999899	1	2026-06-03	LIMEIRA	ACUMULO DE FUNCAO	107.57	2026-10-13 17:57:00.859604	542	\N	2026PD00282
588	10995999899	1	2026-06-14	LIMEIRA	ACUMULO DE FUNCAO	107.57	2026-10-13 17:57:00.859604	542	\N	2026PD00282
589	10995999899	1	2026-06-17	LIMEIRA	ACUMULO DE FUNCAO	107.57	2026-10-13 17:57:00.859604	542	\N	2026PD00282
590	10995999899	1	2026-06-18	LIMEIRA	ACUMULO DE FUNCAO	107.57	2026-10-13 17:57:00.859604	542	\N	2026PD00282
591	10995999899	1	2026-06-21	LIMEIRA	ACUMULO DE FUNCAO	107.57	2026-10-13 17:57:00.859604	542	\N	2026PD00282
592	10995999899	1	2026-06-22	LIMEIRA	ACUMULO DE FUNCAO	107.57	2026-10-13 17:57:00.859604	542	\N	2026PD00282
593	10995999899	1	2026-06-25	LIMEIRA	ACUMULO DE FUNCAO	107.57	2026-10-13 17:57:00.859604	542	\N	2026PD00282
594	10995999899	1	2026-06-26	LIMEIRA	ACUMULO DE FUNCAO	107.57	2026-10-13 17:57:00.859604	542	\N	2026PD00282
595	10995999899	1	2026-07-02	LIMEIRA	ACUMULO DE FUNCAO	107.57	2026-10-13 17:57:00.859604	440	\N	2026PD00306
600	10995999899	1	2026-07-17	LIMEIRA	ACUMULO DE FUNCAO	107.57	2026-10-13 17:57:00.859604	501	\N	2026PD00306
601	10995999899	1	2026-07-20	LIMEIRA	ACUMULO DE FUNCAO	107.57	2026-10-13 17:57:00.859604	404	\N	2026PD00306
602	10995999899	1	2026-07-21	LIMEIRA	ACUMULO DE FUNCAO	107.57	2026-10-13 17:57:00.859604	403	\N	2026PD00306
603	10995999899	1	2026-07-24	LIMEIRA	ACUMULO DE FUNCAO	107.57	2026-10-13 17:57:00.859604	484	\N	2026PD00306
604	10995999899	1	2026-07-25	LIMEIRA	ACUMULO DE FUNCAO	107.57	2026-10-13 17:57:00.859604	539	\N	2026PD00306
605	10995999899	1	2026-07-28	LIMEIRA	ACUMULO DE FUNCAO	107.57	2026-10-13 17:57:00.859604	479	\N	2026PD00306
606	10995999899	1	2026-07-29	LIMEIRA	ACUMULO DE FUNCAO	107.57	2026-10-13 17:57:00.859604	532	\N	2026PD00306
607	10995999899	1	2026-08-05	LIMEIRA	ACUMULO DE FUNCAO	107.57	2026-10-13 17:57:00.859604	461	\N	2026PD00402
608	10995999899	1	2026-08-09	LIMEIRA	ACUMULO DE FUNCAO	107.57	2026-10-13 17:57:00.859604	461	\N	2026PD00402
609	10995999899	1	2026-08-11	LIMEIRA	ACUMULO DE FUNCAO	107.57	2026-10-13 17:57:00.859604	461	\N	2026PD00402
610	10995999899	1	2026-08-14	LIMEIRA	ACUMULO DE FUNCAO	107.57	2026-10-13 17:57:00.859604	461	\N	2026PD00402
611	10995999899	1	2026-08-20	LIMEIRA	ACUMULO DE FUNCAO	107.57	2026-10-13 17:57:00.859604	461	\N	2026PD00402
612	10995999899	1	2026-08-21	LIMEIRA	ACUMULO DE FUNCAO	107.57	2026-10-13 17:57:00.859604	461	\N	2026PD00402
613	10995999899	1	2026-08-22	LIMEIRA	ACUMULO DE FUNCAO	107.57	2026-10-13 17:57:00.859604	461	\N	2026PD00402
614	10995999899	1	2026-08-23	LIMEIRA	ACUMULO DE FUNCAO	107.57	2026-10-13 17:57:00.859604	461	\N	2026PD00402
615	10995999899	1	2026-08-26	LIMEIRA	ACUMULO DE FUNCAO	107.57	2026-10-13 17:57:00.859604	461	\N	2026PD00402
616	10995999899	1	2026-08-29	LIMEIRA	ACUMULO DE FUNCAO	107.57	2026-10-13 17:57:00.859604	461	\N	2026PD00402
411	13934950876	1	2026-07-02	LIMEIRA	ACUMULO DE FUNCAO	161.36	2026-10-13 17:57:00.859604	494	\N	2026PD00335
412	13934950876	1	2026-07-04	LIMEIRA	ACUMULO DE FUNCAO	161.36	2026-10-13 17:57:00.859604	494	\N	2026PD00335
413	13934950876	1	2026-07-06	LIMEIRA	ACUMULO DE FUNCAO	161.36	2026-10-13 17:57:00.859604	494	\N	2026PD00335
414	13934950876	1	2026-07-09	LIMEIRA	ACUMULO DE FUNCAO	161.36	2026-10-13 17:57:00.859604	494	\N	2026PD00335
415	13934950876	1	2026-07-11	LIMEIRA	ACUMULO DE FUNCAO	161.36	2026-10-13 17:57:00.859604	494	\N	2026PD00335
416	13934950876	1	2026-07-12	LIMEIRA	ACUMULO DE FUNCAO	161.36	2026-10-13 17:57:00.859604	494	\N	2026PD00335
417	13934950876	1	2026-07-15	LIMEIRA	ACUMULO DE FUNCAO	161.36	2026-10-13 17:57:00.859604	494	\N	2026PD00335
418	13934950876	1	2026-07-18	LIMEIRA	ACUMULO DE FUNCAO	161.36	2026-10-13 17:57:00.859604	494	\N	2026PD00335
409	13934950876	1	2026-06-27	LIMEIRA	ACUMULO DE FUNCAO	161.36	2026-10-13 17:57:00.859604	438	\N	2026PD00307
410	13934950876	1	2026-06-29	LIMEIRA	ACUMULO DE FUNCAO	161.36	2026-10-13 17:57:00.859604	435	\N	2026PD00307
596	10995999899	1	2026-07-05	LIMEIRA	ACUMULO DE FUNCAO	107.57	2026-10-13 17:57:00.859604	415	\N	2026PD00306
597	10995999899	1	2026-07-08	LIMEIRA	ACUMULO DE FUNCAO	107.57	2026-10-13 17:57:00.859604	405	\N	2026PD00306
598	10995999899	1	2026-07-11	LIMEIRA	ACUMULO DE FUNCAO	107.57	2026-10-13 17:57:00.859604	533	\N	2026PD00306
599	10995999899	1	2026-07-14	LIMEIRA	ACUMULO DE FUNCAO	107.57	2026-10-13 17:57:00.859604	458	\N	2026PD00306
810	05484576709	1	2026-02-26	POCOS DE CALDAS	SERVICO POLICIAL	207.46	2026-10-14 14:52:38.767455	566	\N	2026PD00113
638	36750397816	1	2026-07-16	MOCOCA	SERVICO POLICIAL	69.15	2026-10-13 17:57:00.859604	530	\N	2026PD00315
815	26451064807	1	2026-06-19	RIO DE JANEIRO	SERVICO POLICIAL	822.94	2026-10-14 15:27:31.549516	487	\N	2026PD00287
798	01110375816	2	2023-09-06	SAO PAULO	CURSO SSP	3360.96	2026-10-13 17:57:00.859604	381	\N	2026PD00408
775	01110375816	2	2026-04-01	SAO PAULO	CURSO SSP	871.36	2026-10-13 17:57:00.859604	409	\N	2026PD00161
776	01110375816	2	2026-04-05	SAO PAULO	CURSO SSP	3360.96	2026-10-13 17:57:00.859604	409	\N	2026PD00161
827	04307176103	2	2026-09-24	PIRACICABA	CURSO MBA	103.73	2026-10-15 15:41:17.369817	579	\N	2026PD00414
828	04307176103	2	2026-09-26	PIRACICABA	CURSO MBA	103.73	2026-10-15 15:44:46.548372	579	\N	2026PD00414
829	19203432884	2	2026-09-17	PIRACICABA	CURSO MBA	103.73	2026-10-15 15:45:38.180307	580	\N	2026PD00415
831	19216935847	2	2026-09-26	PIRACICABA	CURSO MBA	103.73	2026-10-15 15:47:48.448063	581	\N	2026PD00416
832	42610681844	2	2026-09-17	PIRACICABA	CURSO MBA	80.68	2026-10-15 15:49:17.328371	582	\N	2026PD00417
833	85920356510	2	2026-09-24	PIRACICABA	CURSO MBA	103.73	2026-10-15 15:53:44.745113	583	\N	2026PD00418
522	04307176103	1	2026-04-16	LIMEIRA	SERVICO POLICIAL	103.73	2026-10-13 17:57:00.859604	492	\N	2026PD00169
565	04704982858	1	2026-06-09	SAO PAULO	SERVICO POLICIAL	248.96	2026-10-13 17:57:00.859604	384	\N	2026/PD00283
560	05484576709	1	2026-02-25	SAO PAULO	SERVICO POLICIAL	248.96	2026-10-13 17:57:00.859604	469	\N	2026PD00129
743	00496426850	2	2026-08-27	SAO PAULO	AGOSTO LILAS	248.96	2026-10-13 17:57:00.859604	377	\N	2026PD00367
777	01110375816	2	2026-04-12	SAO PAULO	CURSO SSP	3360.96	2026-10-13 17:57:00.859604	409	\N	2026PD00161
778	01110375816	2	2026-04-21	SAO PAULO	CURSO SSP	2116.16	2026-10-13 17:57:00.859604	409	\N	2026PD00161
779	01110375816	2	2026-04-26	SAO PAULO	CURSO SSP	3360.96	2026-10-13 17:57:00.859604	409	\N	2026PD00161
780	01110375816	2	2026-05-03	SAO PAULO	CURSO SSP	3360.96	2026-10-13 17:57:00.859604	423	\N	2026PD00218
781	01110375816	2	2026-05-10	SAO PAULO	CURSO SSP	3360.96	2026-10-13 17:57:00.859604	423	\N	2026PD00218
782	01110375816	2	2026-05-17	SAO PAULO	CURSO SSP	3360.96	2026-10-13 17:57:00.859604	423	\N	2026PD00218
783	01110375816	2	2026-05-24	SAO PAULO	CURSO SSP	3360.96	2026-10-13 17:57:00.859604	423	\N	2026PD00218
784	01110375816	2	2026-05-31	SAO PAULO	CURSO SSP	3112.00	2026-10-13 17:57:00.859604	472	\N	2026PD00260
785	01110375816	2	2026-06-07	SAO PAULO	CURSO SSP	3112.00	2026-10-13 17:57:00.859604	472	\N	2026PD00260
786	01110375816	2	2026-06-14	SAO PAULO	CURSO SSP	3112.00	2026-10-13 17:57:00.859604	472	\N	2026PD00260
787	01110375816	2	2026-06-21	SAO PAULO	CURSO SSP	3112.00	2026-10-13 17:57:00.859604	472	\N	2026PD00260
788	01110375816	2	2026-06-28	SAO PAULO	CURSO SSP	3112.00	2026-10-13 17:57:00.859604	516	\N	2026PD00304
789	01110375816	2	2026-07-05	SAO PAULO	CURSO SSP	3112.00	2026-10-13 17:57:00.859604	516	\N	2026PD00304
790	01110375816	2	2026-07-12	SAO PAULO	CURSO SSP	3112.00	2026-10-13 17:57:00.859604	516	\N	2026PD00304
791	01110375816	2	2026-07-19	SAO PAULO	CURSO SSP	3112.00	2026-10-13 17:57:00.859604	516	\N	2026PD00304
792	01110375816	2	2026-07-26	SAO PAULO	CURSO SSP	3112.00	2026-10-13 17:57:00.859604	516	\N	2026PD00304
793	01110375816	2	2026-08-02	SAO PAULO	CURSO SSP	3360.96	2026-10-13 17:57:00.859604	371	\N	2026PD00371
794	01110375816	2	2026-08-09	SAO PAULO	CURSO SSP	3360.96	2026-10-13 17:57:00.859604	371	\N	2026PD00371
795	01110375816	2	2026-08-16	SAO PAULO	CURSO SSP	3360.96	2026-10-13 17:57:00.859604	371	\N	2026PD00371
796	01110375816	2	2026-08-23	SAO PAULO	CURSO SSP	3360.96	2026-10-13 17:57:00.859604	371	\N	2026PD00371
797	01110375816	2	2026-08-30	SAO PAULO	CURSO SSP	3360.96	2026-10-13 17:57:00.859604	381	\N	2026PD00408
799	01110375816	2	2026-09-13	SAO PAULO	CURSO SSP	3360.96	2026-10-13 17:57:00.859604	381	\N	2026PD00408
800	01110375816	2	2026-09-20	SAO PAULO	CURSO SSP	3360.96	2026-10-13 17:57:00.859604	381	\N	2026PD00408
801	01110375816	2	2026-09-27	SAO PAULO	CURSO SSP	3360.96	2026-10-13 17:57:00.859604	381	\N	2026PD00408
558	06762410855	1	2026-08-06	ITU	SERVICO POLICIAL	103.73	2026-10-13 17:57:00.859604	547	\N	2026PD00341
542	07666429681	1	2026-04-28	PIRACICABA	SERVICO POLICIAL	69.15	2026-10-13 17:57:00.859604	372	\N	2026PD00170
566	08922377674	1	2026-08-10	SAO PAULO	SERVICO POLICIAL	248.96	2026-10-13 17:57:00.859604	560	\N	2026PD00332
717	06762410855	2	2026-08-02	SAO PAULO	ENCONTRO UGES	622.40	2026-10-13 17:57:00.859604	538	\N	2026PD00340
650	10410326682	1	2026-02-07	PIRACICABA	PLANTAO POLICIAL LIMEIRA	207.46	2026-10-13 17:57:00.859604	408	\N	2026PD00070
656	10410326682	1	2026-03-03	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	386	\N	2026PD00130
657	10410326682	1	2026-03-05	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	386	\N	2026PD00130
658	10410326682	1	2026-03-09	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	386	\N	2026PD00130
659	10410326682	1	2026-03-11	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	386	\N	2026PD00130
660	10410326682	1	2026-03-14	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	69.15	2026-10-13 17:57:00.859604	386	\N	2026PD00130
661	10410326682	1	2026-03-15	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	386	\N	2026PD00130
662	10410326682	1	2026-03-19	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	386	\N	2026PD00130
663	10410326682	1	2026-03-21	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	386	\N	2026PD00130
664	10410326682	1	2026-03-23	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	386	\N	2026PD00130
665	10410326682	1	2026-03-27	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	386	\N	2026PD00130
666	10410326682	1	2026-03-31	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	386	\N	2026PD00130
667	10410326682	1	2026-04-06	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	422	\N	2026PD00172
668	10410326682	1	2026-04-09	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	422	\N	2026PD00172
669	10410326682	1	2026-04-11	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	422	\N	2026PD00172
670	10410326682	1	2026-04-13	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	422	\N	2026PD00172
671	10410326682	1	2026-04-15	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	422	\N	2026PD00172
672	10410326682	1	2026-04-17	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	422	\N	2026PD00172
673	10410326682	1	2026-04-19	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	422	\N	2026PD00172
674	10410326682	1	2026-04-21	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	422	\N	2026PD00172
675	10410326682	1	2026-04-23	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	422	\N	2026PD00172
676	10410326682	1	2026-04-27	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	422	\N	2026PD00172
677	10410326682	1	2026-04-29	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	422	\N	2026PD00172
678	10410326682	1	2026-05-01	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	391	\N	2026PD00237
679	10410326682	1	2026-05-03	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	69.15	2026-10-13 17:57:00.859604	391	\N	2026PD00237
680	10410326682	1	2026-05-05	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	391	\N	2026PD00237
681	10410326682	1	2026-05-11	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	391	\N	2026PD00237
682	10410326682	1	2026-05-14	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	391	\N	2026PD00237
683	10410326682	1	2026-05-16	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	391	\N	2026PD00237
684	10410326682	1	2026-05-17	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	391	\N	2026PD00237
685	10410326682	1	2026-05-20	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	391	\N	2026PD00237
686	10410326682	1	2026-05-23	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	69.15	2026-10-13 17:57:00.859604	391	\N	2026PD00237
687	10410326682	1	2026-05-24	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	69.15	2026-10-13 17:57:00.859604	391	\N	2026PD00237
688	10410326682	1	2026-05-26	PIRASSUNUNGA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	391	\N	2026PD00237
446	10531583600	1	2026-01-27	PIRACICABA	PLANTAO POLICIAL LIMEIRA	207.46	2026-10-13 17:57:00.859604	389	\N	2026PD00048
723	10995999899	2	2026-03-27	PIRACICABA	CURSO TIRO	80.68	2026-10-13 17:57:00.859604	460	\N	2026PD00131
694	13934950876	1	2026-05-02	LIMEIRA	ACUMULO DE FUNCAO	161.36	2026-10-13 17:57:00.859604	485	\N	2026PD00239
695	13934950876	1	2026-05-05	LIMEIRA	ACUMULO DE FUNCAO	161.36	2026-10-13 17:57:00.859604	485	\N	2026PD00239
696	13934950876	1	2026-05-08	LIMEIRA	ACUMULO DE FUNCAO	161.36	2026-10-13 17:57:00.859604	485	\N	2026PD00239
697	13934950876	1	2026-05-11	LIMEIRA	ACUMULO DE FUNCAO	161.36	2026-10-13 17:57:00.859604	485	\N	2026PD00239
698	13934950876	1	2026-05-14	LIMEIRA	ACUMULO DE FUNCAO	161.36	2026-10-13 17:57:00.859604	485	\N	2026PD00239
716	12328788807	2	2026-07-16	SAO PAULO	TREINAMENTO	193.63	2026-10-13 17:57:00.859604	459	\N	2026PD00136
725	12375581660	2	2026-03-27	RIO CLARO	CURSO TIRO	69.15	2026-10-13 17:57:00.859604	430	\N	2026PD00184
699	13934950876	1	2026-05-17	LIMEIRA	ACUMULO DE FUNCAO	161.36	2026-10-13 17:57:00.859604	485	\N	2026PD00239
400	13934950876	1	2026-05-21	LIMEIRA	ACUMULO DE FUNCAO	161.36	2026-10-13 17:57:00.859604	485	\N	2026PD00239
401	13934950876	1	2026-05-24	LIMEIRA	ACUMULO DE FUNCAO	161.36	2026-10-13 17:57:00.859604	485	\N	2026PD00239
402	13934950876	1	2026-05-28	LIMEIRA	ACUMULO DE FUNCAO	161.36	2026-10-13 17:57:00.859604	485	\N	2026PD00239
403	13934950876	1	2026-05-31	LIMEIRA	ACUMULO DE FUNCAO	161.36	2026-10-13 17:57:00.859604	485	\N	2026PD00247
404	13934950876	1	2026-06-04	LIMEIRA	ACUMULO DE FUNCAO	161.36	2026-10-13 17:57:00.859604	495	\N	2026PD00307
405	13934950876	1	2026-06-09	LIMEIRA	ACUMULO DE FUNCAO	161.36	2026-10-13 17:57:00.859604	488	\N	2026PD00307
406	13934950876	1	2026-06-14	LIMEIRA	ACUMULO DE FUNCAO	161.36	2026-10-13 17:57:00.859604	370	\N	2026PD00307
395	13934950876	1	2026-06-19	LIMEIRA	ACUMULO DE FUNCAO	161.36	2026-10-13 17:57:00.859604	480	\N	2026PD00307
407	13934950876	1	2026-06-21	LIMEIRA	ACUMULO DE FUNCAO	161.36	2026-10-13 17:57:00.859604	400	\N	2026PD00307
408	13934950876	1	2026-06-24	LIMEIRA	ACUMULO DE FUNCAO	161.36	2026-10-13 17:57:00.859604	470	\N	2026PD00307
625	14694180703	1	2026-06-09	SAO PAULO	SERVICO POLICIAL	248.96	2026-10-13 17:57:00.859604	519	\N	2026PD00284
626	14694180703	1	2026-08-05	BARUERI	SERVICO POLICIAL	103.73	2026-10-13 17:57:00.859604	436	\N	2026PD00402
520	16791203870	1	2026-08-05	BARUERI	SERVICO POLICIAL	103.73	2026-10-13 17:57:00.859604	378	\N	2026PD00336
629	18208623806	1	2026-03-06	JAGUARIUNA	SERVICO POLICIAL	69.15	2026-10-13 17:57:00.859604	555	\N	2026PD00116
640	19216935847	1	2026-03-11	RIO CLARO	SERVICO POLICIAL	69.15	2026-10-13 17:57:00.859604	421	\N	\N
419	13934950876	1	2026-07-20	LIMEIRA	ACUMULO DE FUNCAO	161.36	2026-10-13 17:57:00.859604	494	\N	2026PD00335
420	13934950876	1	2026-07-23	LIMEIRA	ACUMULO DE FUNCAO	161.36	2026-10-13 17:57:00.859604	494	\N	2026PD00335
421	13934950876	1	2026-07-25	LIMEIRA	ACUMULO DE FUNCAO	161.36	2026-10-13 17:57:00.859604	494	\N	2026PD00335
422	13934950876	1	2026-07-27	LIMEIRA	ACUMULO DE FUNCAO	161.36	2026-10-13 17:57:00.859604	494	\N	2026PD00335
423	13934950876	1	2026-07-30	LIMEIRA	ACUMULO DE FUNCAO	161.36	2026-10-13 17:57:00.859604	494	\N	2026PD00335
424	13934950876	1	2026-08-02	LIMEIRA	ACUMULO DE FUNCAO	161.36	2026-10-13 17:57:00.859604	454	\N	2026PD00402
425	13934950876	1	2026-08-06	LIMEIRA	ACUMULO DE FUNCAO	161.36	2026-10-13 17:57:00.859604	454	\N	2026PD00402
426	13934950876	1	2026-08-09	LIMEIRA	ACUMULO DE FUNCAO	161.36	2026-10-13 17:57:00.859604	454	\N	2026PD00402
427	13934950876	1	2026-08-12	LIMEIRA	ACUMULO DE FUNCAO	161.36	2026-10-13 17:57:00.859604	454	\N	2026PD00402
428	13934950876	1	2026-08-15	LIMEIRA	ACUMULO DE FUNCAO	161.36	2026-10-13 17:57:00.859604	454	\N	2026PD00402
429	13934950876	1	2026-08-18	LIMEIRA	ACUMULO DE FUNCAO	161.36	2026-10-13 17:57:00.859604	454	\N	2026PD00402
430	13934950876	1	2026-08-22	LIMEIRA	ACUMULO DE FUNCAO	161.36	2026-10-13 17:57:00.859604	454	\N	2026PD00402
744	15721307846	2	2026-07-16	SAO PAULO	TREINAMENTO	248.96	2026-10-13 17:57:00.859604	522	\N	2026PD00317
431	13934950876	1	2026-08-24	LIMEIRA	ACUMULO DE FUNCAO	161.36	2026-10-13 17:57:00.859604	454	\N	2026PD00402
628	18208623806	1	2026-01-11	LIMEIRA	PLANTAO POLICIAL LIMEIRA	207.46	2026-10-13 17:57:00.859604	429	\N	2026PD00049
708	18208623806	2	2026-01-29	SAO PAULO	CURSO ACADEPOL APH	871.36	2026-10-13 17:57:00.859604	462	\N	2026PD00059
432	13934950876	1	2026-08-28	LIMEIRA	ACUMULO DE FUNCAO	161.36	2026-10-13 17:57:00.859604	454	\N	2026PD00402
713	18208623806	2	2026-04-30	SALTINHO	CURSO ENTRADAS TATICAS	138.31	2026-10-13 17:57:00.859604	546	\N	2026PD00162
433	13934950876	1	2026-08-30	LIMEIRA	ACUMULO DE FUNCAO	161.36	2026-10-13 17:57:00.859604	454	\N	2026PD00402
630	18208623806	1	2026-07-13	LIMEIRA	PLANTAO POLICIAL LIMEIRA	207.46	2026-10-13 17:57:00.859604	468	\N	2026PD00308
631	18208623806	1	2026-08-29	LIMEIRA	PLANTAO POLICIAL LIMEIRA	103.73	2026-10-13 17:57:00.859604	419	\N	2026PD00402
434	19163513870	1	2026-01-01	PIRACICABA	PLANTAO POLICIAL LIMEIRA	207.46	2026-10-13 17:57:00.859604	418	\N	2026PD00050
559	22444646878	1	2026-02-19	PIRACICABA	PLANTAO POLICIAL LIMEIRA	207.46	2026-10-13 17:57:00.859604	449	\N	2026PD00073
435	24999284847	1	2026-01-19	PIRACICABA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	478	\N	2026PD00051
436	24999284847	1	2026-05-14	LIMEIRA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	398	\N	2026PD00240
437	24999284847	1	2026-06-15	LIMEIRA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	552	\N	2026PD00286
438	24999284847	1	2026-07-18	LIMEIRA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	535	\N	2026PD00309
439	24999284847	1	2026-07-24	LIMEIRA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	395	\N	2026PD00309
440	24999284847	1	2026-08-08	LIMEIRA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	517	\N	2026PD00342
511	27057183895	1	2026-01-10	LIMEIRA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	549	\N	2026PD00052
512	27057183895	1	2026-02-21	LIMEIRA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	475	\N	2026PD00083
513	27057183895	1	2026-05-17	LIMEIRA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	452	\N	2026PD00241
514	27057183895	1	2026-06-07	LIMEIRA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	368	\N	2026PD00288
515	27057183895	1	2026-06-21	LIMEIRA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	526	\N	2026PD00288
617	27206162819	1	2026-01-18	LIMEIRA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	486	\N	2026PD00053
618	27206162819	1	2026-03-22	LIMEIRA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	425	\N	2026PD00120
619	27206162819	1	2026-04-12	LIMEIRA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	447	\N	2026PD00176
620	27206162819	1	2026-05-04	LIMEIRA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	500	\N	2026PD00242
621	27206162819	1	2026-06-09	GUARULHOS	SERVICO POLICIAL	207.46	2026-10-13 17:57:00.859604	380	\N	2026PD00289
622	27206162819	1	2026-06-20	LIMEIRA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	531	\N	2026PD00289
623	27206162819	1	2026-07-09	LIMEIRA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	376	\N	2026PD00310
624	27206162819	1	2026-08-09	LIMEIRA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	388	\N	\N
690	27935713855	1	2026-05-12	SAO PAULO	SERVICO POLICIAL	124.48	2026-10-13 17:57:00.859604	483	\N	2026PD00243
691	27935713855	1	2026-05-20	SAO PAULO	SERVICO POLICIAL	124.48	2026-10-13 17:57:00.859604	396	\N	2026PD00243
692	27935713855	1	2026-06-09	SAO PAULO	SERVICO POLICIAL	248.96	2026-10-13 17:57:00.859604	508	\N	2026PD00243
693	29474854831	1	2026-08-05	BARUERI	SERVICO POLICIAL	80.68	2026-10-13 17:57:00.859604	455	\N	\N
536	30310116864	1	2026-02-20	SAO PAULO	SERVICO POLICIAL	248.96	2026-10-13 17:57:00.859604	451	\N	2026PD00074
751	30310116864	2	2026-02-25	SAO PAULO	CURSO ACADEPOL ACADEPOL	248.96	2026-10-13 17:57:00.859604	476	\N	2026PD00085
752	30310116864	2	2026-02-26	SAO PAULO	CURSO ACADEPOL ACADEPOL	248.96	2026-10-13 17:57:00.859604	476	\N	2026PD00085
753	30310116864	2	2026-02-27	SAO PAULO	CURSO ACADEPOL ACADEPOL	248.96	2026-10-13 17:57:00.859604	476	\N	2026PD00085
526	32540502822	1	2026-01-07	PIRACICABA	PLANTAO POLICIAL LIMEIRA	207.46	2026-10-13 17:57:00.859604	437	\N	2026PD00054
527	32540502822	1	2026-02-14	LIMEIRA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	402	\N	2026PD00076
735	32540502822	2	2026-03-05	SAO PAULO	CURSO APH	995.84	2026-10-13 17:57:00.859604	402	\N	2026PD00132
529	32540502822	1	2026-05-12	LIMEIRA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	521	\N	2026PD00244
530	32540502822	1	2026-06-08	LIMEIRA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	383	\N	206PD00290
531	32540502822	1	2026-07-20	LIMEIRA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	529	\N	2026PD00311
532	32540502822	1	2026-08-26	LIMEIRA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	414	\N	2026PD00402
772	32628691809	2	2026-04-14	PIRACICABA	CURSO ACADEPOL	69.15	2026-10-13 17:57:00.859604	413	\N	2026PD00164
773	32628691809	2	2026-05-04	PIRACICABA	CURSO ACADEPOL	69.15	2026-10-13 17:57:00.859604	561	\N	2026PD00221
774	32628691809	2	2026-05-05	PIRACICABA	CURSO ACADEPOL	69.15	2026-10-13 17:57:00.859604	550	\N	2026PD00221
803	32628691809	2	2026-05-06	PIRACICABA	CURSO ACADEPOL	69.15	2026-10-13 17:57:00.859604	428	\N	2026PD00221
769	32968804880	2	2026-08-27	SAO PAULO	AGOSTO LILAS	248.96	2026-10-13 17:57:00.859604	553	\N	2026PD00368
702	33648957830	2	2026-05-04	PIRACICABA	CURSO ACADEPOL	69.15	2026-10-13 17:57:00.859604	520	\N	2026PD00222
707	33648957830	2	2026-05-05	PIRACICABA	CURSO ACADEPOL	69.15	2026-10-13 17:57:00.859604	520	\N	2026PD00222
710	33648957830	2	2026-05-06	PIRACICABA	CURSO ACADEPOL	69.15	2026-10-13 17:57:00.859604	520	\N	2026PD00222
758	33648957830	2	2026-06-25	PIRACICABA	CURSO ACADEPOL	69.15	2026-10-13 17:57:00.859604	493	\N	2026PD00261
770	33648957830	2	2026-06-26	PIRACICABA	CURSO ACADEPOL	69.15	2026-10-13 17:57:00.859604	493	\N	2026PD00261
746	31892853817	2	2026-04-17	PIRACICABA	CURSO ACADEPOL TAT I	103.73	2026-10-13 17:57:00.859604	432	\N	2026PD00163
747	31892853817	2	2026-04-19	CHARQUEADA	CURSO ACADEPOL TAT I	138.31	2026-10-13 17:57:00.859604	432	\N	2026PD00163
748	31892853817	2	2026-04-23	CHARQUEADA	CURSO ACADEPOL TAT I	69.15	2026-10-13 17:57:00.859604	432	\N	2026PD00163
749	31892853817	2	2026-04-26	PIRACICABA	CURSO ACADEPOL TAT I	103.73	2026-10-13 17:57:00.859604	382	\N	2026PD00163
730	35313574841	2	2026-06-25	PIRACICABA	CURSO ACADEPOL	69.15	2026-10-13 17:57:00.859604	445	\N	2026PD00262
731	35313574841	2	2026-06-26	PIRACICABA	CURSO ACADEPOL	69.15	2026-10-13 17:57:00.859604	445	\N	2026PD00262
548	36025331820	1	2026-03-16	SAO PAULO	SERVICO POLICIAL	248.96	2026-10-13 17:57:00.859604	524	\N	2026PD00124
634	36750397816	1	2026-02-04	CAPIVARI	SERVICO POLICIAL	138.31	2026-10-13 17:57:00.859604	513	\N	2026PD00079
771	35932472839	2	2026-03-27	PIRACICABA	CURSO TIRO	69.15	2026-10-13 17:57:00.859604	511	\N	2026PD00133
547	36025331820	1	2026-02-07	PIRACICABA	PLANTAO POLICIAL LIMEIRA	207.46	2026-10-13 17:57:00.859604	477	\N	2026PD00078
722	36819640846	2	2026-08-27	SAO PAULO	AGOSTO LILAS	248.96	2026-10-13 17:57:00.859604	515	\N	2026PD00369
549	39460172822	1	2026-01-27	PIRACICABA	PLANTAO POLICIAL LIMEIRA	207.46	2026-10-13 17:57:00.859604	544	\N	2026PD00056
551	39460172822	1	2026-02-22	LIMEIRA	PLANTAO POLICIAL LIMEIRA	207.46	2026-10-13 17:57:00.859604	394	\N	2026PD00080
554	39460172822	1	2026-06-12	LIMEIRA	PLANTAO POLICIAL LIMEIRA	207.46	2026-10-13 17:57:00.859604	497	\N	2026PD00292
555	39460172822	1	2026-06-25	LIMEIRA	PLANTAO POLICIAL LIMEIRA	207.46	2026-10-13 17:57:00.859604	401	\N	2026PD00292
712	39460172822	2	2026-06-25	SAO PAULO	SEMINARIO	248.96	2026-10-13 17:57:00.859604	401	\N	2026PD00292
556	39460172822	1	2026-07-03	LIMEIRA	PLANTAO POLICIAL LIMEIRA	207.46	2026-10-13 17:57:00.859604	540	\N	2026PD00313
557	39460172822	1	2026-08-22	LIMEIRA	PLANTAO POLICIAL LIMEIRA	207.46	2026-10-13 17:57:00.859604	426	\N	2026PD00402
759	40381911845	2	2026-03-16	SAO PAULO	CURSO OPERACIONAL PMSP	248.96	2026-10-13 17:57:00.859604	509	\N	2026PD00134
760	40381911845	2	2026-03-17	SAO PAULO	CURSO OPERACIONAL PMSP	248.96	2026-10-13 17:57:00.859604	509	\N	2026PD00134
761	40381911845	2	2026-03-18	SAO PAULO	CURSO OPERACIONAL PMSP	248.96	2026-10-13 17:57:00.859604	509	\N	2026PD00134
762	40381911845	2	2026-03-19	SAO PAULO	CURSO OPERACIONAL PMSP	248.96	2026-10-13 17:57:00.859604	509	\N	2026PD00134
763	40381911845	2	2026-03-20	SAO PAULO	CURSO OPERACIONAL PMSP	248.96	2026-10-13 17:57:00.859604	509	\N	2026PD00134
764	40381911845	2	2026-03-23	SAO PAULO	CURSO OPERACIONAL PMSP	248.96	2026-10-13 17:57:00.859604	509	\N	2026PD00134
765	40381911845	2	2026-03-24	SAO PAULO	CURSO OPERACIONAL PMSP	248.96	2026-10-13 17:57:00.859604	509	\N	2026PD00134
766	40381911845	2	2026-03-25	SAO PAULO	CURSO OPERACIONAL PMSP	248.96	2026-10-13 17:57:00.859604	509	\N	2026PD00134
767	40381911845	2	2026-03-26	SAO PAULO	CURSO OPERACIONAL PMSP	248.96	2026-10-13 17:57:00.859604	509	\N	2026PD00134
768	40381911845	2	2026-03-27	SAO PAULO	CURSO OPERACIONAL PMSP	248.96	2026-10-13 17:57:00.859604	509	\N	2026PD00134
396	42582609838	1	2026-01-01	PIRACICABA	PLANTAO POLICIAL LIMEIRA	207.46	2026-10-13 17:57:00.859604	375	\N	2026PD00057
397	42582609838	1	2026-02-08	LIMEIRA	PLANTAO POLICIAL LIMEIRA	69.15	2026-10-13 17:57:00.859604	514	\N	2026PD00083
398	42582609838	1	2026-02-12	LIMEIRA	PLANTAO POLICIAL LIMEIRA	207.46	2026-10-13 17:57:00.859604	503	\N	2026PD00083
399	42582609838	1	2026-03-07	LIMEIRA	PLANTAO POLICIAL LIMEIRA	69.15	2026-10-13 17:57:00.859604	416	\N	2026PD00128
700	42582609838	2	2026-03-16	SAO PAULO	SEMINARIO FEMINICIDIO	248.96	2026-10-13 17:57:00.859604	464	\N	2026PD00135
701	42582609838	2	2026-03-26	RIO CLARO	CURSO TIRO	69.15	2026-10-13 17:57:00.859604	490	\N	2026PD00135
504	42582609838	1	2026-03-29	LIMEIRA	PLANTAO POLICIAL LIMEIRA	69.15	2026-10-13 17:57:00.859604	441	\N	2026PD00128
505	42582609838	1	2026-04-21	LIMEIRA	PLANTAO POLICIAL LIMEIRA	69.15	2026-10-13 17:57:00.859604	537	\N	2026PD00166
826	35500297805	2	2026-04-19	CHARQUEADA	CURSO ACADEPOL TAT I	69.15	2026-10-14 16:11:58.837708	374	\N	2026PD00165
705	35500297805	2	2026-04-23	CHARQUEADA	CURSO ACADEPOL TAT I	69.15	2026-10-13 17:57:00.859604	374	\N	2026PD00165
706	35500297805	2	2026-04-26	CHARQUEADA	CURSO ACADEPOL TAT I	69.15	2026-10-13 17:57:00.859604	374	\N	2026PD00165
704	42582609838	2	2026-04-23	SAO PAULO	PALESTRA ACADEPOL	124.48	2026-10-13 17:57:00.859604	433	\N	2026PD00166
506	42582609838	1	2026-05-09	LIMEIRA	PLANTAO POLICIAL LIMEIRA	69.15	2026-10-13 17:57:00.859604	369	\N	2026PD00245
507	42582609838	1	2026-06-29	LIMEIRA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	397	\N	2026PD00128
508	42582609838	1	2026-07-11	LIMEIRA	PLANTAO POLICIAL LIMEIRA	69.15	2026-10-13 17:57:00.859604	563	\N	2026PD00314
509	42582609838	1	2026-07-28	LIMEIRA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	379	\N	2026PD00337
709	42582609838	2	2026-08-27	LIMEIRA	AGOSTO LILAS	248.96	2026-10-13 17:57:00.859604	431	\N	2026PD00370
510	42582609838	1	2026-08-28	LIMEIRA	PLANTAO POLICIAL LIMEIRA	138.31	2026-10-13 17:57:00.859604	407	\N	2026PD00402
711	42582609838	2	2026-09-02	LIMEIRA	VIOLENCIA DE GENERO	248.96	2026-10-13 17:57:00.859604	456	\N	2026PD00370
757	42610681844	2	2026-03-26	RIO CLARO	CURSO TIRO	107.57	2026-10-13 17:57:00.859604	471	\N	2026PD00167
469	44519520851	1	2026-07-14	LIMEIRA	ACUMULO DE FUNCAO	69.15	2026-10-13 17:57:00.859604	496	\N	2026PD00338
470	44519520851	1	2026-07-15	LIMEIRA	ACUMULO DE FUNCAO	69.15	2026-10-13 17:57:00.859604	496	\N	2026PD00338
525	43992425827	1	2026-01-07	PIRACICABA	PLANTAO POLICIAL LIMEIRA	207.46	2026-10-13 17:57:00.859604	463	\N	2026PD00058
471	44519520851	1	2026-07-16	LIMEIRA	ACUMULO DE FUNCAO	69.15	2026-10-13 17:57:00.859604	496	\N	2026PD00338
472	44519520851	1	2026-07-17	LIMEIRA	ACUMULO DE FUNCAO	69.15	2026-10-13 17:57:00.859604	496	\N	2026PD00338
473	44519520851	1	2026-07-20	LIMEIRA	ACUMULO DE FUNCAO	69.15	2026-10-13 17:57:00.859604	496	\N	2026PD00338
474	44519520851	1	2026-07-21	LIMEIRA	ACUMULO DE FUNCAO	69.15	2026-10-13 17:57:00.859604	496	\N	2026PD00338
475	44519520851	1	2026-07-22	LIMEIRA	ACUMULO DE FUNCAO	69.15	2026-10-13 17:57:00.859604	496	\N	2026PD00338
476	44519520851	1	2026-07-23	LIMEIRA	ACUMULO DE FUNCAO	69.15	2026-10-13 17:57:00.859604	496	\N	2026PD00338
477	44519520851	1	2026-07-24	LIMEIRA	ACUMULO DE FUNCAO	69.15	2026-10-13 17:57:00.859604	496	\N	2026PD00338
478	44519520851	1	2026-07-27	LIMEIRA	ACUMULO DE FUNCAO	69.15	2026-10-13 17:57:00.859604	496	\N	2026PD00338
479	44519520851	1	2026-07-28	LIMEIRA	ACUMULO DE FUNCAO	69.15	2026-10-13 17:57:00.859604	496	\N	2026PD00338
480	44519520851	1	2026-07-29	LIMEIRA	ACUMULO DE FUNCAO	69.15	2026-10-13 17:57:00.859604	496	\N	2026PD00338
481	44519520851	1	2026-07-30	LIMEIRA	ACUMULO DE FUNCAO	69.15	2026-10-13 17:57:00.859604	496	\N	2026PD00338
482	44519520851	1	2026-07-31	LIMEIRA	ACUMULO DE FUNCAO	69.15	2026-10-13 17:57:00.859604	496	\N	2026PD00338
483	44519520851	1	2026-08-03	LIMEIRA	ACUMULO DE FUNCAO	69.15	2026-10-13 17:57:00.859604	465	\N	2026PD00402
484	44519520851	1	2026-08-04	LIMEIRA	ACUMULO DE FUNCAO	69.15	2026-10-13 17:57:00.859604	465	\N	2026PD00402
485	44519520851	1	2026-08-05	LIMEIRA	ACUMULO DE FUNCAO	69.15	2026-10-13 17:57:00.859604	465	\N	2026PD00402
486	44519520851	1	2026-08-06	LIMEIRA	ACUMULO DE FUNCAO	69.15	2026-10-13 17:57:00.859604	465	\N	2026PD00402
487	44519520851	1	2026-08-07	LIMEIRA	ACUMULO DE FUNCAO	69.15	2026-10-13 17:57:00.859604	465	\N	2026PD00402
488	44519520851	1	2026-08-10	LIMEIRA	ACUMULO DE FUNCAO	69.15	2026-10-13 17:57:00.859604	465	\N	2026PD00402
516	46508753827	1	2026-04-09	SAO PAULO	SERVICO POLICIAL	248.96	2026-10-13 17:57:00.859604	502	\N	2026PD00183
564	47033640854	1	2026-06-19	RIO DE JANEIRO	SERVICO POLICIAL	822.94	2026-10-13 17:57:00.859604	558	\N	2026PD00295
537	80184782104	1	2026-08-05	BARUERI	SERVICO POLICIAL	103.73	2026-10-13 17:57:00.859604	534	\N	2026PD00343
489	44519520851	1	2026-08-11	LIMEIRA	ACUMULO DE FUNCAO	69.15	2026-10-13 17:57:00.859604	465	\N	2026PD00402
490	44519520851	1	2026-08-12	LIMEIRA	ACUMULO DE FUNCAO	69.15	2026-10-13 17:57:00.859604	465	\N	2026PD00402
491	44519520851	1	2026-08-13	LIMEIRA	ACUMULO DE FUNCAO	69.15	2026-10-13 17:57:00.859604	465	\N	2026PD00402
492	44519520851	1	2026-08-14	LIMEIRA	ACUMULO DE FUNCAO	69.15	2026-10-13 17:57:00.859604	465	\N	2026PD00402
493	44519520851	1	2026-08-17	LIMEIRA	ACUMULO DE FUNCAO	69.15	2026-10-13 17:57:00.859604	465	\N	2026PD00402
494	44519520851	1	2026-08-18	LIMEIRA	ACUMULO DE FUNCAO	69.15	2026-10-13 17:57:00.859604	465	\N	2026PD00402
495	44519520851	1	2026-08-19	LIMEIRA	ACUMULO DE FUNCAO	69.15	2026-10-13 17:57:00.859604	465	\N	2026PD00402
496	44519520851	1	2026-08-20	LIMEIRA	ACUMULO DE FUNCAO	69.15	2026-10-13 17:57:00.859604	465	\N	2026PD00402
497	44519520851	1	2026-08-21	LIMEIRA	ACUMULO DE FUNCAO	69.15	2026-10-13 17:57:00.859604	465	\N	2026PD00402
498	44519520851	1	2026-08-24	LIMEIRA	ACUMULO DE FUNCAO	69.15	2026-10-13 17:57:00.859604	465	\N	2026PD00402
499	44519520851	1	2026-08-25	LIMEIRA	ACUMULO DE FUNCAO	69.15	2026-10-13 17:57:00.859604	465	\N	2026PD00402
500	44519520851	1	2026-08-26	LIMEIRA	ACUMULO DE FUNCAO	69.15	2026-10-13 17:57:00.859604	465	\N	2026PD00402
501	44519520851	1	2026-08-27	LIMEIRA	ACUMULO DE FUNCAO	69.15	2026-10-13 17:57:00.859604	465	\N	2026PD00402
718	46508753827	2	2026-05-04	PIRACICABA	CURSO ACADEPOL	69.15	2026-10-13 17:57:00.859604	541	\N	2026PD00223
719	46508753827	2	2026-05-05	PIRACICABA	CURSO ACADEPOL	69.15	2026-10-13 17:57:00.859604	489	\N	2026PD00223
720	46508753827	2	2026-05-06	PIRACICABA	CURSO ACADEPOL	69.15	2026-10-13 17:57:00.859604	491	\N	2026PD00223
502	44519520851	1	2026-08-28	LIMEIRA	ACUMULO DE FUNCAO	69.15	2026-10-13 17:57:00.859604	465	\N	2026PD00402
503	44519520851	1	2026-08-31	LIMEIRA	ACUMULO DE FUNCAO	69.15	2026-10-13 17:57:00.859604	465	\N	2026PD00402
802	82897123915	2	2026-04-23	SALTINHO	CURSO ACADEPOL	138.31	2026-10-13 17:57:00.859604	556	\N	2026PD00168
\.


--
-- Data for Name: lancamentos; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.lancamentos (id_lancamento, cpf_servidor, id_tipo, data_inicial, destino, motivo, valor_diaria, processo, numero_pd, data_pagamento, processado) FROM stdin;
\.


--
-- Data for Name: pagamentos_processo; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.pagamentos_processo (id_pagamento, id_processo, numero_pd, data_pagamento, valor_pagamento, id_pd) FROM stdin;
188	566	2026PD00113	2026-04-08	207.42	1
190	557	2026PD00194	2026-05-12	69.15	3
191	562	2026PD00171	2026-05-08	124.48	4
192	412	2026PD00069	2026-03-06	69.15	5
193	487	2026PD00287	2026-07-30	822.94	6
194	399	2026PD00291	2026-07-30	822.94	7
195	543	2026PD00055	2026-02-25	207.46	8
196	387	2026PD00077	2026-03-06	103.73	9
197	512	2026PD00123	2026-04-08	69.15	10
198	446	2026PD00047	2026-02-25	204.46	11
199	444	2026PD00114	2026-04-08	622.39	12
163	368	2026PD00288	2026-07-30	138.31	157
31	525	2026PD00175	2026-05-08	248.96	158
151	416	2026PD00128	2026-04-08	69.15	159
178	480	2026PD00307	2026-08-10	161.36	202
23	508	2026PD00243	0026-06-19	248.96	178
71	502	2026PD00183	2026-05-08	248.96	162
168	453	2026PD00285	2026-07-30	248.96	163
143	373	2026PD00125	2026-04-08	69.15	164
149	425	2026PD00120	2026-04-08	138.31	165
95	551	2026PD00179	2026-05-08	207.45	166
4	400	2026PD00307	2026-08-10	161.36	202
67	494	2026PD00335	2026-08-13	2097.68	168
139	433	2026PD00166	2026-05-08	124.48	169
44	520	2026PD00222	2026-06-12	207.45	170
40	479	2026PD00306	2026-08-10	107.57	174
54	438	2026PD00307	2026-08-10	161.36	202
161	468	2026PD00308	2026-08-10	207.46	173
177	501	2026PD00306	2026-08-10	107.57	174
120	559	2026PD00246	2026-06-19	193.63	175
127	522	2026PD00317	2026-08-10	248.96	176
32	429	2026PD00049	2026-02-25	207.46	177
83	396	2026PD00243	2026-06-19	124.48	178
41	509	2026PD00134	2026-04-08	2489.60	179
122	521	2026PD00244	2026-06-19	138.31	180
183	395	2026PD00309	2026-08-10	138.31	181
13	379	2026PD00337	2026-08-13	138.31	182
78	549	2026PD00052	2026-02-25	138.31	183
101	370	2026PD00307	2026-08-10	161.36	202
99	524	2026PD00124	2026-04-08	248.96	185
56	545	2026PD00119	2026-04-08	207.46	186
133	374	2026PD00165	2026-05-08	207.45	187
61	427	2026PD00071	2026-03-06	248.96	188
145	386	2026PD00130	2026-04-08	1452.25	189
29	450	2026PD00319	2026-08-10	110.95	122
15	450	2026PD00220	2026-06-12	138.31	190
93	378	2026PD00336	2026-08-13	103.73	191
38	424	2026PD00177	2026-05-08	138.31	192
68	470	2026PD00307	2026-08-10	161.36	202
126	391	2026PD00237	2026-06-19	1313.93	194
167	528	2026PD00173	2026-05-08	537.85	195
80	426	2026PD00402	2026-10-02	207.46	196
20	381	2026PD00408	2026-10-07	16804.80	197
88	463	2026PD00058	2026-02-24	207.46	198
75	464	2026PD00135	2026-04-08	248.96	199
39	457	2026PD00296	2026-07-30	248.96	200
6	541	2026PD00223	2026-06-12	69.15	201
14	488	2026PD00307	2026-08-10	161.36	202
94	452	2026PD00241	2026-06-19	138.31	203
111	558	2026PD00295	2026-07-30	822.94	204
121	536	2026PD00118	2026-04-08	96.81	205
98	451	2026PD00074	2026-03-06	248.96	206
51	466	2026PD00344	2026-08-14	207.46	207
214	590	2026PD00219	2026-06-11	2489.60	211
203	579	2026PD00414	2026-10-14	207.46	14
204	580	2026PD00415	2026-10-14	103.73	15
205	581	2026PD00416	2026-10-14	207.46	16
206	582	2026PD00417	2026-10-14	80.68	17
207	583	2026PD00418	2026-10-14	207.46	18
208	584	2026PD00419	2026-10-14	1075.70	19
209	585	2026PD00420	2026-10-14	124.48	20
210	586	2026PD00421	2026-10-14	484.08	21
211	465	2026PD00403	2026-10-02	69.15	22
135	465	2026PD00402	2026-10-02	1383.00	196
180	402	2026PD00076	2026-03-06	138.31	24
109	405	2026PD00306	2026-08-10	107.57	174
152	475	2026PD00083	2026-03-06	138.31	79
90	473	2026PD00402	2026-10-02	103.73	196
97	419	2026PD00402	2026-10-02	103.73	196
37	442	2026PD00125	2026-04-08	69.15	164
175	554	2026PD00126	2026-04-08	69.15	30
36	492	2026PD00169	2026-05-08	103.73	31
92	411	2026PD00294	2026-07-30	193.63	32
59	491	2026PD00223	2026-06-12	69.15	201
136	482	2026PD00178	2026-05-08	248.96	34
102	459	2026PD00136	2026-08-10	193.63	35
72	385	2026PD00122	2026-04-08	69.15	36
123	423	2026PD00218	2026-06-12	13443.84	37
165	505	2026PD00068	2026-03-06	248.96	38
34	415	2026PD00306	2026-08-10	107.57	174
52	546	2026PD00162	2026-05-08	138.31	40
141	440	2026PD00306	2026-08-10	107.57	174
156	500	2026PD00242	2026-06-19	138.31	42
150	476	2026PD00085	2026-03-06	746.88	43
8	553	2026PD00368	2026-09-08	248.96	44
159	461	2026PD00402	2026-10-02	1075.70	196
11	477	2026PD00078	2026-03-06	207.46	46
76	402	2026PD00132	2026-04-08	995.84	47
33	511	2026PD00133	2026-04-08	69.15	48
186	471	2026PD00167	2026-05-08	107.57	49
137	481	2026PD00121	2026-04-08	69.15	141
104	474	2026PD00402	2026-10-02	103.73	196
19	478	2026PD00051	2026-02-25	138.31	52
17	449	2026PD00073	2026-03-06	207.46	53
18	496	2026PD00338	2026-08-13	968.10	54
81	506	2026PD00174	2026-05-08	248.96	55
172	441	2026PD00128	2026-04-08	69.15	159
70	409	2026PD00161	2026-05-08	13070.40	57
171	403	2026PD00306	2026-08-10	107.57	174
27	486	2026PD00053	2026-02-25	138.31	59
55	401	2026PD00292	2026-07-30	207.46	108
154	542	2026PD00282	2026-07-30	1075.70	61
87	422	2026PD00172	2026-05-08	1521.41	62
164	380	2026PD00289	2026-07-30	207.46	89
110	456	2026PD00370	2026-10-02	248.96	100
113	556	2026PD00168	2026-05-08	138.31	64
185	377	2026PD00367	2026-09-08	248.96	65
66	530	2026PD00315	2026-08-10	69.15	66
119	420	2026PD00297	2026-06-30	1383.00	67
47	432	2026PD00163	2026-05-08	311.19	88
100	398	2026PD00240	2026-06-19	138.31	69
148	485	2026PD00239	2026-06-19	1452.24	70
160	472	2026PD00260	2026-07-07	12448.00	71
182	401	2026PD00318	2026-08-10	248.96	72
166	517	2026PD00342	2026-08-14	138.31	74
21	552	2026PD00286	2026-07-30	138.31	75
58	503	2026PD00083	2026-03-06	207.46	79
46	437	2026PD00054	2026-02-25	207.46	77
117	537	2026PD00166	2026-05-08	69.15	169
12	514	2026PD00083	2026-03-06	69.15	79
24	414	2026PD00402	2026-10-02	138.31	196
28	529	2026PD00311	2026-08-10	138.31	81
179	526	2026PD00288	2026-07-30	138.31	157
129	527	2026PD00127	2026-04-08	69.15	120
74	534	2026PD00343	2026-08-14	103.73	84
153	563	2026PD00314	2026-08-10	69.15	85
85	485	2026PD00247	2026-06-19	161.36	86
115	408	2026PD00070	2026-03-06	207.46	87
45	382	2026PD00163	2026-05-08	103.73	88
146	531	2026PD00289	2026-07-30	138.31	89
1	428	2026PD00221	2026-06-12	69.15	155
9	389	2026PD00048	2026-02-25	207.46	91
57	513	2026PD00079	2026-03-06	138.31	92
158	544	2026PD00056	2026-02-24	207.46	93
35	434	2026PD00115	2026-04-08	968.13	94
118	498	2026PD00081	2026-03-06	248.96	133
43	532	2026PD00306	2026-08-10	107.57	174
2	507	2026PD00402	2026-10-02	103.73	196
181	371	2026PD00371	2026-09-08	13443.84	98
125	393	2026PD00334	2026-08-14	103.73	99
114	431	2026PD00370	2026-09-08	248.96	100
187	372	2026PD00170	2026-05-08	69.15	101
176	404	2026PD00306	2026-08-10	107.57	174
3	445	2026PD00262	2026-07-07	138.30	103
147	516	2026PD00304	2026-08-05	15560.00	104
103	467	2026PD00180	2026-05-08	248.96	105
89	407	2026PD00402	2026-10-02	138.31	196
79	383	206PD00290	2026-07-30	138.31	107
22	497	2026PD00292	2026-07-30	207.46	108
73	523	2026PD00238	2026-06-19	430.28	109
132	376	2026PD00310	2026-08-10	138.31	110
10	397	2026PD00128	2026-04-08	138.31	159
48	499	2026PD00118	2026-04-08	53.78	205
173	435	2026PD00307	2026-08-10	161.36	202
53	462	2026PD00059	2026-02-25	871.36	114
174	539	2026PD00306	2026-08-10	107.57	174
155	430	2026PD00184	2026-05-08	69.15	116
49	406	2026PD00082	2026-03-06	138.31	117
25	390	2026PD00117	2026-04-08	69.15	118
124	418	2026PD00050	2026-02-25	207.46	119
128	392	2026PD00127	2026-04-08	69.15	120
108	417	2026PD00072	2026-03-06	138.31	121
5	458	2026PD00306	2026-08-10	107.57	174
77	468	2026PD00402	2026-10-02	207.46	196
138	518	2026PD00293	2026-07-30	822.94	125
86	375	2026PD00057	2026-02-24	207.46	126
96	436	2026PD00402	2026-10-02	103.73	196
144	547	2026PD00341	2026-08-14	103.73	128
134	447	2026PD00176	2026-05-08	138.31	129
42	394	2026PD00080	2026-03-06	207.46	135
130	555	2026PD00116	2026-04-08	69.15	131
62	384	2026/PD00283	2026-07-30	248.96	132
169	410	2026PD00081	2026-03-06	207.46	133
7	519	2026PD00284	2026-07-30	248.96	134
184	548	2026PD00080	2026-03-06	248.96	135
60	489	2026PD00223	2026-06-12	69.15	201
84	493	2026PD00261	2026-07-07	138.30	137
50	538	2026PD00340	2026-08-14	622.40	138
64	413	2026PD00164	2026-05-08	69.15	139
131	469	2026PD00129	2026-04-08	248.96	140
106	504	2026PD00121	2026-04-08	69.15	141
116	535	2026PD00309	2026-08-10	138.31	181
162	515	2026PD00369	2026-09-08	248.96	143
82	560	2026PD00332	2026-08-14	248.96	144
65	540	2026PD00313	2026-08-10	207.46	145
30	483	2026PD00243	2026-06-19	124.48	178
91	490	2026PD00135	2026-04-08	69.15	199
16	561	2026PD00221	2026-06-12	69.15	155
112	460	2026PD00131	2026-04-08	80.68	149
140	495	2026PD00307	2026-08-10	161.36	202
142	484	2026PD00306	2026-08-10	107.57	174
157	533	2026PD00306	2026-08-10	107.57	174
170	454	2026PD00402	2026-10-02	1613.60	196
26	369	2026PD00245	2026-06-19	69.15	154
105	550	2026PD00221	2026-06-12	69.15	155
107	510	2026PD00075	2026-03-06	248.96	156
\.


--
-- Data for Name: pds; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.pds (id_pd, numero_pd, data_pagamento, valor_total) FROM stdin;
1	2026PD00113	2026-04-08	207.42
3	2026PD00194	2026-05-12	69.15
4	2026PD00171	2026-05-08	124.48
5	2026PD00069	2026-03-06	69.15
6	2026PD00287	2026-07-30	822.94
7	2026PD00291	2026-07-30	822.94
8	2026PD00055	2026-02-25	207.46
9	2026PD00077	2026-03-06	103.73
10	2026PD00123	2026-04-08	69.15
11	2026PD00047	2026-02-25	204.46
12	2026PD00114	2026-04-08	622.39
14	2026PD00414	2026-10-14	207.46
15	2026PD00415	2026-10-14	103.73
16	2026PD00416	2026-10-14	207.46
17	2026PD00417	2026-10-14	80.68
18	2026PD00418	2026-10-14	207.46
19	2026PD00419	2026-10-14	1075.70
20	2026PD00420	2026-10-14	124.48
21	2026PD00421	2026-10-14	484.08
22	2026PD00403	2026-10-02	69.15
24	2026PD00076	2026-03-06	138.31
30	2026PD00126	2026-04-08	69.15
31	2026PD00169	2026-05-08	103.73
32	2026PD00294	2026-07-30	193.63
34	2026PD00178	2026-05-08	248.96
35	2026PD00136	2026-08-10	193.63
36	2026PD00122	2026-04-08	69.15
37	2026PD00218	2026-06-12	13443.84
38	2026PD00068	2026-03-06	248.96
40	2026PD00162	2026-05-08	138.31
42	2026PD00242	2026-06-19	138.31
43	2026PD00085	2026-03-06	746.88
44	2026PD00368	2026-09-08	248.96
46	2026PD00078	2026-03-06	207.46
47	2026PD00132	2026-04-08	995.84
48	2026PD00133	2026-04-08	69.15
49	2026PD00167	2026-05-08	107.57
135	2026PD00080	2026-03-06	456.42
132	2026PD00283	2026-07-30	248.96
138	2026PD00340	2026-08-14	622.40
139	2026PD00164	2026-05-08	69.15
140	2026PD00129	2026-04-08	497.92
141	2026PD00121	2026-04-08	138.30
143	2026PD00369	2026-09-08	248.96
144	2026PD00332	2026-08-14	248.96
145	2026PD00313	2026-08-10	207.46
149	2026PD00131	2026-04-08	80.68
154	2026PD00245	2026-06-19	69.15
155	2026PD00221	2026-06-12	207.45
156	2026PD00075	2026-03-06	248.96
157	2026PD00288	2026-07-30	276.62
158	2026PD00175	2026-05-08	248.96
159	2026PD00128	2026-04-08	276.61
162	2026PD00183	2026-05-08	248.96
163	2026PD00285	2026-07-30	248.96
164	2026PD00125	2026-04-08	138.30
165	2026PD00120	2026-04-08	138.31
137	2026PD00261	2026-07-07	138.30
211	2026PD00219	2026-06-11	\N
52	2026PD00051	2026-02-25	138.31
53	2026PD00073	2026-03-06	207.46
54	2026PD00338	2026-08-13	968.10
55	2026PD00174	2026-05-08	248.96
57	2026PD00161	2026-05-08	13070.40
59	2026PD00053	2026-02-25	138.31
61	2026PD00282	2026-07-30	1075.70
62	2026PD00172	2026-05-08	1521.41
64	2026PD00168	2026-05-08	138.31
65	2026PD00367	2026-09-08	248.96
66	2026PD00315	2026-08-10	69.15
67	2026PD00297	2026-06-30	1383.00
69	2026PD00240	2026-06-19	138.31
70	2026PD00239	2026-06-19	1452.24
71	2026PD00260	2026-07-07	12448.00
72	2026PD00318	2026-08-10	248.96
74	2026PD00342	2026-08-14	138.31
75	2026PD00286	2026-07-30	138.31
77	2026PD00054	2026-02-25	207.46
79	2026PD00083	2026-03-06	414.92
81	2026PD00311	2026-08-10	138.31
84	2026PD00343	2026-08-14	103.73
85	2026PD00314	2026-08-10	69.15
86	2026PD00247	2026-06-19	161.36
87	2026PD00070	2026-03-06	207.46
88	2026PD00163	2026-05-08	414.92
89	2026PD00289	2026-07-30	345.77
91	2026PD00048	2026-02-25	207.46
92	2026PD00079	2026-03-06	138.31
93	2026PD00056	2026-02-24	207.46
94	2026PD00115	2026-04-08	968.13
98	2026PD00371	2026-09-08	13443.84
99	2026PD00334	2026-08-14	103.73
100	2026PD00370	2026-09-08	497.92
101	2026PD00170	2026-05-08	69.15
103	2026PD00262	2026-07-07	138.30
104	2026PD00304	2026-08-05	15560.00
105	2026PD00180	2026-05-08	248.96
108	2026PD00292	2026-07-30	414.92
109	2026PD00238	2026-06-19	430.28
110	2026PD00310	2026-08-10	138.31
114	2026PD00059	2026-02-25	871.36
116	2026PD00184	2026-05-08	69.15
117	2026PD00082	2026-03-06	138.31
118	2026PD00117	2026-04-08	138.30
119	2026PD00050	2026-02-25	207.46
120	2026PD00127	2026-04-08	138.30
121	2026PD00072	2026-03-06	138.31
122	2026PD00319	2026-08-10	110.95
125	2026PD00293	2026-07-30	822.94
126	2026PD00057	2026-02-24	207.46
128	2026PD00341	2026-08-14	103.73
129	2026PD00176	2026-05-08	138.31
131	2026PD00116	2026-04-08	69.15
133	2026PD00081	2026-03-06	456.42
134	2026PD00284	2026-07-30	248.96
166	2026PD00179	2026-05-08	207.45
168	2026PD00335	2026-08-13	2097.68
169	2026PD00166	2026-05-08	193.63
170	2026PD00222	2026-06-12	207.45
173	2026PD00308	2026-08-10	207.46
174	2026PD00306	2026-08-10	1290.84
175	2026PD00246	2026-06-19	193.63
176	2026PD00317	2026-08-10	248.96
177	2026PD00049	2026-02-25	207.46
178	2026PD00243	2026-06-19	497.92
179	2026PD00134	2026-04-08	2489.60
180	2026PD00244	2026-06-19	138.31
181	2026PD00309	2026-08-10	276.62
182	2026PD00337	2026-08-13	138.31
183	2026PD00052	2026-02-25	138.31
185	2026PD00124	2026-04-08	248.96
186	2026PD00119	2026-04-08	207.46
187	2026PD00165	2026-05-08	207.45
188	2026PD00071	2026-03-06	248.96
189	2026PD00130	2026-04-08	1452.25
190	2026PD00220	2026-06-12	138.31
191	2026PD00336	2026-08-13	103.73
192	2026PD00177	2026-05-08	138.31
194	2026PD00237	2026-06-19	1313.93
195	2026PD00173	2026-05-08	537.85
196	2026PD00402	2026-10-02	5282.49
197	2026PD00408	2026-10-07	16804.80
198	2026PD00058	2026-02-24	207.46
199	2026PD00135	2026-04-08	318.11
200	2026PD00296	2026-07-30	248.96
201	2026PD00223	2026-06-12	207.45
202	2026PD00307	2026-08-10	1290.88
203	2026PD00241	2026-06-19	138.31
204	2026PD00295	2026-07-30	822.94
205	2026PD00118	2026-04-08	150.59
206	2026PD00074	2026-03-06	248.96
207	2026PD00344	2026-08-14	207.46
107	2026PD00290	2026-07-30	138.31
\.


--
-- Data for Name: processos; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.processos (id_processo, numero_processo, situacao, data_cadastro) FROM stdin;
377	05800104239/202601	PAGO	2026-08-27 00:00:00
388	058.00095060/202648	ABERTO	2026-08-09 00:00:00
421	058.00033318/202612	ABERTO	2026-03-11 00:00:00
439	058.00070660/202601	ABERTO	2026-06-09 00:00:00
455	058.00094473/202613	ABERTO	2026-08-05 00:00:00
504	058.00031514/202652	PAGO	2026-03-06 00:00:00
505	058.00020984/202691	PAGO	2026-02-10 00:00:00
565	058.00116811/202677	ABERTO	2026-09-30 00:00:00
425	058.00037432/202611	PAGO	2026-03-22 00:00:00
426	058.00099842/202656	PAGO	2026-08-22 00:00:00
427	058.00024388/202680	PAGO	2026-02-20 00:00:00
428	058.00056002/202607	PAGO	2026-05-06 00:00:00
429	058.00004380/202605	PAGO	2026-01-11 00:00:00
430	058.00044639/202642	PAGO	2026-03-27 00:00:00
431	058.00102757/202682	PAGO	2026-08-27 00:00:00
432	058.00040442/202642	PAGO	2026-04-17 00:00:00
433	058.00052548/202681	PAGO	2026-04-23 00:00:00
434	058.00040508/202696	PAGO	2026-03-01 00:00:00
435	058.00083398/202664	PAGO	2026-06-29 00:00:00
436	058.00093806/202689	PAGO	2026-08-05 00:00:00
437	058.00003397/202637	PAGO	2026-01-07 00:00:00
438	058.00083398/202663	PAGO	2026-06-27 00:00:00
440	058.00091579/202657	PAGO	2026-07-02 00:00:00
441	058.00040310/202611	PAGO	2026-03-29 00:00:00
442	058.00033148/202676	PAGO	2026-03-10 00:00:00
444	058.00031378/202609	PAGO	2026-02-14 00:00:00
445	058.00078470/202624	PAGO	2026-06-25 00:00:00
446	058.00003690/202602	PAGO	2026-01-07 00:00:00
447	058.00047214/202695	PAGO	2026-04-12 00:00:00
449	058.00024300/202620	PAGO	2026-02-19 00:00:00
450	058.00064004/202661	PAGO	2026-05-25 00:00:00
451	058.00023698/202687	PAGO	2026-02-20 00:00:00
452	058.00059942/202640	PAGO	2026-05-17 00:00:00
453	058.00070445/202601	PAGO	2026-06-09 00:00:00
454	058.00103897/202678	PAGO	2026-08-02 00:00:00
456	058.00105727/202628	PAGO	2026-09-02 00:00:00
457	058.00070656/202635	PAGO	2026-06-09 00:00:00
458	058.00091579/202661	PAGO	2026-07-14 00:00:00
459	058.00085150/202621	PAGO	2026-07-16 00:00:00
460	058.00040479/202662	PAGO	2026-03-27 00:00:00
461	058.00104889/202649	PAGO	2026-08-05 00:00:00
462	058.00014312/202646	PAGO	2026-01-29 00:00:00
463	058.00003563/202603	PAGO	2026-01-07 00:00:00
464	058.00036561/202692	PAGO	2026-03-16 00:00:00
465	058.00103808/202693	PAGO	2026-08-03 00:00:00
466	058.00094808/202695	PAGO	2026-08-05 00:00:00
467	058.00045723/202683	PAGO	2026-04-09 00:00:00
468	058.00083424/202647	PAGO	2026-07-13 00:00:00
469	058.00029861/202615	PAGO	2026-02-25 00:00:00
470	058.00083398/202662	PAGO	2026-06-24 00:00:00
471	058.00040956/202690	PAGO	2026-03-26 00:00:00
472	058.00079231/202691	PAGO	2026-05-31 00:00:00
473	058.00098581/202657	PAGO	2026-08-17 00:00:00
474	058.00098567/202653	PAGO	2026-08-17 00:00:00
475	058.00023653/202611	PAGO	2026-02-21 00:00:00
476	058.00027233/202603	PAGO	2026-02-25 00:00:00
477	058.00018728/202633	PAGO	2026-02-07 00:00:00
478	058.00007397/202614	PAGO	2026-01-19 00:00:00
479	058.00091579/202667	PAGO	2026-07-28 00:00:00
480	058.00083398/202660	PAGO	2026-06-19 00:00:00
481	058.00034447/202628	PAGO	2026-03-11 00:00:00
482	058.00045732/202674	PAGO	2026-04-09 00:00:00
483	058.00059047/202625	PAGO	2026-05-12 00:00:00
484	058.00091579/202665	PAGO	2026-07-24 00:00:00
485	058.00067125/202665	PAGO	2026-05-02 00:00:00
486	058.00010411/202659	PAGO	2026-01-18 00:00:00
487	058.00074761/202643	PAGO	2026-06-16 00:00:00
488	058.00083398/202658	PAGO	2026-06-09 00:00:00
489	058.00056379/202658	PAGO	2026-05-05 00:00:00
490	058.00040322/202637	PAGO	2026-03-26 00:00:00
491	058.00056381/202627	PAGO	2026-05-06 00:00:00
492	058.00049520/202666	PAGO	2026-04-16 00:00:00
493	058.00078792/202673	PAGO	2026-06-25 00:00:00
494	058.00092056/202628	PAGO	2026-07-02 00:00:00
495	058.00083398/202657	PAGO	2026-06-04 00:00:00
496	058.00092795/202610	PAGO	2026-07-14 00:00:00
497	058.00074738/202659	PAGO	2026-06-12 00:00:00
498	058.00027335/202611	PAGO	2026-02-25 00:00:00
499	058.00035389/202650	PAGO	2026-03-13 00:00:00
500	058.00055452/202674	PAGO	2026-05-04 00:00:00
501	058.00091579/202662	PAGO	2026-07-17 00:00:00
502	058.00045929/202611	PAGO	2026-04-09 00:00:00
503	058.00024277/202673	PAGO	2026-02-12 00:00:00
506	058.00048533/202618	PAGO	2026-04-15 00:00:00
507	058.00094564/202641	PAGO	2026-08-05 00:00:00
508	058.00070443/202611	PAGO	2026-06-09 00:00:00
509	058.00041483/202648	PAGO	2026-03-16 00:00:00
510	058.00020995/202671	PAGO	2026-02-10 00:00:00
511	058.00041533/202668	PAGO	2026-03-27 00:00:00
512	058.00031510/202674	PAGO	2026-03-06 00:00:00
513	058.00020892/202619	PAGO	2026-02-04 00:00:00
514	058.00018050/202699	PAGO	2026-02-08 00:00:00
515	058.00101929/202609	PAGO	2026-08-27 00:00:00
516	058.00088428/202611	PAGO	2026-06-28 00:00:00
517	058.00094899/202669	PAGO	2026-08-08 00:00:00
518	058.00074738/2026-59	PAGO	2026-06-19 00:00:00
519	058.00070662/202692	PAGO	2026-06-09 00:00:00
520	058.00056878/202645	PAGO	2026-05-04 00:00:00
521	058.00059213/202693	PAGO	2026-05-12 00:00:00
522	058.00085156/202606	PAGO	2026-07-16 00:00:00
589	058.00115464/202636	ABERTO	2026-10-23 16:05:32.689521
423	058.00067369/202648	PAGO	2026-05-03 00:00:00
590	058.00061715/202684	ABERTO	2026-10-26 09:00:58.028531
368	058.00068481/202604	PAGO	2026-06-07 00:00:00
369	058.00057813/202617	PAGO	2026-05-09 00:00:00
370	058.00083398/202659	PAGO	2026-06-14 00:00:00
371	058.00102235/202681	PAGO	2026-08-02 00:00:00
372	058.00052997/202629	PAGO	2026-04-28 00:00:00
373	058.00035638/202615	PAGO	2026-03-13 00:00:00
374	058.00051312/202627	PAGO	2026-04-19 00:00:00
375	058.00001037/202609	PAGO	2026-01-01 00:00:00
376	058.00082688/202683	PAGO	2026-07-09 00:00:00
378	058.00093837/202630	PAGO	2026-08-05 00:00:00
379	058.00090988/202636	PAGO	2026-07-28 00:00:00
380	058.00070478/202642	PAGO	2026-06-09 00:00:00
381	058.00115646/202636	PAGO	2023-09-06 00:00:00
382	058.00052028/202678	PAGO	2026-04-26 00:00:00
383	058.00069566/202600	PAGO	2026-06-08 00:00:00
384	058.00070439/202645	PAGO	2026-06-09 00:00:00
385	058.00031519/202685	PAGO	2026-03-06 00:00:00
386	058.00041351/202616	PAGO	2026-03-03 00:00:00
387	058.00022386/202656	PAGO	2026-02-17 00:00:00
389	058.00012724/202641	PAGO	2026-01-27 00:00:00
390	058.00031520/202618	PAGO	2026-03-06 00:00:00
391	058.00066721/202628	PAGO	2026-05-01 00:00:00
392	058.00033157/202667	PAGO	2026-03-10 00:00:00
393	058.00093477/202676	PAGO	2026-08-05 00:00:00
394	058.00023999/202619	PAGO	2026-02-22 00:00:00
395	058.00087987/202612	PAGO	2026-07-24 00:00:00
396	058.00062241/202698	PAGO	2026-05-20 00:00:00
397	058.00081687/202611	PAGO	2026-06-29 00:00:00
398	058.00059627/202612	PAGO	2026-05-14 00:00:00
399	058.00074727/202679	PAGO	2026-06-19 00:00:00
400	058.00083398/202661	PAGO	2026-06-21 00:00:00
401	058.00077762/202640	PAGO	2026-06-25 00:00:00
402	058.00021611/202637	PAGO	2026-02-14 00:00:00
403	058.00091579/202664	PAGO	2026-07-21 00:00:00
404	058.00091579/202663	PAGO	2026-07-20 00:00:00
405	058.00091579/202659	PAGO	2026-07-08 00:00:00
406	058.00020923/202623	PAGO	2026-02-12 00:00:00
407	058.00102726/202621	PAGO	2026-08-28 00:00:00
408	058.00018719/202642	PAGO	2026-02-07 00:00:00
409	058.00055684/202622	PAGO	2026-04-01 00:00:00
410	058.00027352/202658	PAGO	2026-02-26 00:00:00
411	058.00070670/202639	PAGO	2026-06-09 00:00:00
412	058.00021373/202660	PAGO	2026-02-12 00:00:00
413	058.00048528/202613	PAGO	2026-04-14 00:00:00
414	058.00101723/202671	PAGO	2026-08-26 00:00:00
415	058.00091579/202658	PAGO	2026-07-05 00:00:00
416	058.00031765/202637	PAGO	2026-03-07 00:00:00
417	058.00021480/202698	PAGO	2026-02-12 00:00:00
418	058.00001044/202601	PAGO	2026-01-01 00:00:00
419	058.00104642/202622	PAGO	2026-08-29 00:00:00
420	058.00080283/202619	PAGO	2026-06-01 00:00:00
422	058.00054445/202655	PAGO	2026-04-06 00:00:00
424	058.00052142/202606	PAGO	2026-04-25 00:00:00
523	058.00057022/202697	PAGO	2026-05-01 00:00:00
524	058.00036565/202671	PAGO	2026-03-16 00:00:00
525	058.00048535/202615	PAGO	2026-04-15 00:00:00
526	058.00074673/202641	PAGO	2026-06-21 00:00:00
527	058.00035649/202697	PAGO	2026-03-13 00:00:00
528	058.00047272/202619	PAGO	2026-04-02 00:00:00
529	058.00086330/202620	PAGO	2026-07-20 00:00:00
530	058.00085732/202615	PAGO	2026-07-16 00:00:00
531	058.00074505/202656	PAGO	2026-06-20 00:00:00
532	058.00091579/202668	PAGO	2026-07-29 00:00:00
533	058.00091579/202660	PAGO	2026-07-11 00:00:00
534	058.00094690/202603	PAGO	2026-08-05 00:00:00
535	058.00085564/202650	PAGO	2026-07-18 00:00:00
536	058.00037136/202611	PAGO	2026-03-20 00:00:00
537	058.00052538/202645	PAGO	2026-04-21 00:00:00
538	058.00091820/202648	PAGO	2026-08-02 00:00:00
539	058.00091579/202666	PAGO	2026-07-25 00:00:00
540	058.00080648/202605	PAGO	2026-07-03 00:00:00
541	058.00056375/202670	PAGO	2026-05-04 00:00:00
542	058.00077592/202601	PAGO	2026-06-01 00:00:00
543	058.00012728/202620	PAGO	2026-01-27 00:00:00
544	058.00012100/202624	PAGO	2026-01-27 00:00:00
545	058.00028495/202687	PAGO	2026-02-26 00:00:00
546	058.00053438/202639	PAGO	2026-04-30 00:00:00
547	058.00094014/202621	PAGO	2026-08-06 00:00:00
548	058.00020495/202639	PAGO	2026-02-10 00:00:00
549	058.00004579/202625	PAGO	2026-01-10 00:00:00
550	058.00055999/202670	PAGO	2026-05-05 00:00:00
551	058.00051656/202636	PAGO	2026-04-26 00:00:00
552	058.00071344/202649	PAGO	2026-06-15 00:00:00
553	058.00102590/202650	PAGO	2026-08-27 00:00:00
554	058.00031184/202603	PAGO	2026-03-06 00:00:00
555	058.00031183/202651	PAGO	2026-03-06 00:00:00
556	058.00052368/202607	PAGO	2026-04-23 00:00:00
557	058.00048851/202689	PAGO	2026-04-16 00:00:00
558	058.00074730/202692	PAGO	2026-06-19 00:00:00
559	058.00063384/202617	PAGO	2026-05-20 00:00:00
560	058.00095143/202637	PAGO	2026-08-10 00:00:00
561	058.00055990/202669	PAGO	2026-05-04 00:00:00
562	058.00046220/202625	PAGO	2026-04-09 00:00:00
563	058.00084233/202601	PAGO	2026-07-11 00:00:00
566	058.00010202/202616	PAGO	2026-02-26 00:00:00
579	058.00113983/202699	PAGO	2026-09-24 00:00:00
580	058.00111491/202669	PAGO	2026-09-17 00:00:00
581	058.00113978/202686	PAGO	2026-09-26 00:00:00
582	058.00111029/202661	PAGO	2026-09-17 00:00:00
583	058.00114776/202651	PAGO	2026-09-24 00:00:00
584	058.00116234/202613	PAGO	2026-09-01 00:00:00
585	058.00116140/202644	PAGO	2026-09-25 00:00:00
586	058.00116200/202629	PAGO	2026-09-26 00:00:00
\.


--
-- Data for Name: servidores; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.servidores (cpf_servidor, nome_servidor, id_cargo, ativo) FROM stdin;
05733151838	ADALBERTO JORGE RODRIGUES	7	t
06346558501	ADALTO ALVES ROCHA NETO	7	t
14042095739	ADVAIR VASCONCELOS VELOSO DA SILVA	7	t
30379558807	ALBERTO RAHAL NETO	7	t
31156936802	ALESSANDRO ROGERIO DOS SANTOS	1	t
17162481833	ALEXANDRE SIMÃ•ES SILVA	3	t
84922001891	AMERICO SIDNEI RISSATO	5	t
17559994881	ANDRE LUIS DA SILVA	6	t
35981258870	ANDRE LUIS FABRES	6	t
40300050801	ANDREA DANTAS LEVY	5	t
39510249840	ANGELA DE LIMA DALTIN	6	t
17764814881	ANTONIO LUIS FIOR	7	t
60115700978	ANTONIO ONOFRE	7	t
17416608821	ARAGAO XAVIER DA SILVA	7	t
09433315952	BIANCA CRISTINA DA SILVA RITTER	6	t
39259259886	BRUNO AZZINI TIOSSO	1	t
21819139867	BRUNO RODRIGUES JACON	7	t
30158768809	CARLOS ADRIANO BERTTO CABRINI	2	t
07884129817	CARLOS ALBERTO LIBARDI	2	t
37550429839	CARLOS EDUARDO STRABELLI	6	t
11548143863	CARLOS EDUARDO ZURITA LEONI	7	t
06851660660	CHRISTIANO GONÃ‡ALVES VIDAL	7	t
38672275861	CINTIA APARECIDA VENANCIO FABRIS	6	t
05733042893	CLAUDINEI FERREIRA	4	t
43646474890	CLEBER MEIRA JUNIOR	6	t
19214657866	CRISTIANO EDUARDO PENTEADO	6	t
04611267881	DALTON EDUARDO METZNER	1	t
31111293813	DANIELE APARECIDA VIELLI	6	t
06432966620	DIOGO FRANCISCO DE BRITO	7	t
39101020854	DOMINIC ALVES FERREIRA	6	t
13600008790	DOUGLAS GUIMARAES PINA BASTOS	7	t
06292282805	EDINELSON APARECIDO OLICHESCKI	6	t
12382786639	EDUARDO SUEIT JUNIOR	7	t
16079405822	EITHEL DINAEL STRABELLI	7	t
25180228808	EJEFERSON ARRAEZ LOPES	6	t
14743987822	ELAINE CRISTINA RODRIGUES	6	t
06730855894	ELIANE MARIA CAMOLESI	6	t
02788546807	ELIAS DE OLIVEIRA	3	t
40764409867	ELIAS GABRIEL DE OLIVEIRA PISSE	6	t
85920356510	EMILLE BORBUREMA DE OLIVEIRA MACHADO	7	t
00985216328	EVELYN KAFA LOIOLA DOMIATE	5	t
14716979830	EVERTON DE OLIVEIRA CARDOSO	6	t
41059752859	EWERTON REINALDO PEREIRA LOPES	6	t
36822427830	FABIANA SINIBALDI BARBOSA	6	t
10096636823	FABIO CORREA DE SOUZA	6	t
30835229831	FABIO LOUREIRO MARTINS	6	t
27386967837	FABIO VALERIANO MACARENKO	7	t
03150578825	FATIMA APARECIDA AFONSO	9	t
30215534867	FRANCIS JONAS BUENO TOL	6	t
53165659249	GUILHERME FABIANO RAPOSO DA CAMARA GOMES	6	t
09538794613	GUSTAVO RODRIGO LOPES COELHO	5	t
35583094800	HELIO BRUNO DE CARVALHO GUTIERRE	6	t
32867795800	HELOISA LIMA DE SOUZA SYLLOS	7	t
40112878814	HENRIQUE GIRAO DE SOUZA	6	t
39086002862	IGOR CARITA GAGLIARDI	7	t
77116704272	IGOR CONTENTE PESSOA E SILVA	6	t
11524772690	IGOR RUAN BATISTA DE ARAUJO	5	t
26014480838	ILIAN ORIAS SIMAO MELLO	7	t
13949690824	ISAIAS SANTOS OSSAIN	7	t
01605509809	ISILDA APARECIDA DA COSTA BRIGATO	7	t
26139264812	ISMAEL FERREIRA DOS SANTOS	7	t
28532413862	IVAN BARBOSA DE CASTRO	7	t
45410986873	JESSICA FERNANDA GOMES DE OLIVEIRA	6	t
90201140853	JOAO BATISTA VASCONCELOS	5	t
22787421830	JOAO PAULO LOURENÃ‡O	7	t
32056299810	JOAO ROBERTO MENDES JUNIOR	9	t
12361525810	JOENIL APARECIDO VARUZZA	6	t
13619462100	JORGE APARECIDO FRANCO DE MORAIS	7	t
19162934848	JOSE AUGUSTO GOMES DA SILVA JUNIOR	6	t
21417124830	JOSE ROBERTO JACON JUNIOR	6	t
08169010829	JULIO CESAR FABBRI	7	t
38195846840	LAIS CAROLINE LONGO	6	t
45646950880	LARISSA DE MATOS BEZERRA	1	t
09256969866	LAURO MARCELLO BASSETTO	3	t
12423786778	LEONARDO ARGON BARROS	6	t
02052915621	LETICIA RIBEIRO DE VASCONCELOS	6	t
32439162833	LIVIA MARIA FERRAZ HERNANDES	6	t
01543222293	LUCAS MELO LIMA	6	t
44580937833	LUCAS PUERTAS GORONOSKI MARTINS	7	t
11374958638	LUCAS VINICIUS DE AQUINO	6	t
16068082814	LUCIANA CRISTINA BARBIERI	2	t
15328001850	LUCIANA CRISTINA DA SILVA CORTEZ	6	t
13933597870	LUCIMEIRE LABACI	7	t
07469562826	LUIZ FERNANDO VIEIRA	6	t
06587581609	LUIZ GUILHERME SALLES BARBOSA	5	t
54283108804	LUIZ SERGIO ANTUNES	7	t
15476249818	MAGDA PECCIN	6	t
06121749563	MARCOS ANTONIO SILVA DOS SANTOS	6	t
01717301860	MARCOS LUIZ DA CRUZ	7	t
08786765892	MARCOS ROBERTO TROTTMANN	7	t
05567298625	MARCUS VINICIUS CHAVES MATEUS	6	t
19031748803	MARIO DA CONCEIÃ‡ÃƒO	4	t
06281790812	MAURO CESAR MARTINATI	7	t
20089232828	MAXIMILIANO ZANIRATO	7	t
27192816892	MICHELLE DE GUSMAO SANA	2	t
06766970898	NILSON ORSI	1	t
32241919888	ORLANDO SILVA DO NASCIMENTO	6	t
31980964807	OTAVIO AUGUSTO SANTOS	6	t
42539612822	OTAVIO VOLPINI SILVA	5	t
29285851843	RAFAEL DE LIMA CAETANO COSTA	7	t
38446914808	RAFAEL DE OLIVEIRA LOPES	9	t
33507725878	RAFAEL HENRIQUE ESCAME	7	t
03331373885	RAQUEL DE FATIMA CATTAI DE MILHÃƒ	7	t
13950556885	RAQUEL WICHMANN	6	t
08481279862	REGINALDO JOSE DE GODOY PONCE	7	t
43018515854	RENAN CUSTODIO FLORES	7	t
25259367871	RICARDO ALFREDO COELHO	7	t
19696591810	RICARDO ALLEONI SILVA MORAES	6	t
27737321896	RICARDO DA CONCEICAO LOURENCO	1	t
27704968831	RICARDO LUIS DA FONSECA	6	t
20536048835	ROBERTO DE SOUZA	6	t
25104507866	RODRIGO CYPRIANO	7	t
42798376866	RODRIGO FERNANDES LEAO	7	t
40946122890	RODRIGO HERRERO MACEDO	6	t
26767691895	RODRIGO RODRIGUES	5	t
10743962869	ROGERIO MARCIO DE OLIVEIRA	7	t
65025822904	ROGERIO SARACINO	6	t
40401229840	RONIEL THALLES FIERS	6	t
07385667805	SEBASTIAO MARIO CAMBI	6	t
09591720840	SERGIO LUIZ DIAS RAMOS	1	t
69788146872	SIDNEI CAMARGO PERRONI	7	t
36508856898	STEVAN RICARDO BORDIGNON	9	t
40147397839	TALITA NAVARRO FIORINI DE ARAÃšJO	5	t
30819714895	TATIANE CRISTINA PARIZOTTO	5	t
28727655814	TELMA PATRICIA BARBOZA	6	t
10914036602	THAMIRIS RODRIGUES LEMES PEREIRA	6	t
42709193884	THIAGO VINICIUS GONÃ‡ALVES	7	t
38407577898	TIAGO MARCELINO ALVES	7	t
39262187890	VALERIA ANTONIA DOS SANTOS	6	t
01610216890	VALMIR VICENTE DE SOUZA	4	t
43148543831	VICTOR SCHIAVELLI SARAN	6	t
36190735894	VINICIUS GRAF MEGIATO	6	t
33074022850	VITOR AMADEU LANDO DE CARVALHO	1	t
26997560830	WAGNER CESAR DA SILVA	2	t
10595150837	WILLIAN RICARDO DE ALMEIDA MARCHI	5	t
12328788807	ADRIANA CRISTINA DE MORAES	8	t
42582609838	ADRIELY VALERIA DE SOUZA	5	t
27057183895	ALEXANDRE FERRACIOLLI PEREIRA	5	t
46508753827	ALISSON DE AZEVEDO FEITOSA	6	t
21360741801	ANDERSON ADRIANO FORTI BUENO	1	t
16791203870	ARLEI ANTONIO BALDIN	6	t
04307176103	BRENO MUNIZ MAJADAS	7	t
12375581660	BRUNA LOES DE AVILA	6	t
11374959600	BRUNA LUISA DE AQUINO	7	t
35313574841	BRUNO DE OLIVEIRA THOMAZ BERTANHA	7	t
43992425827	BRUNO HENRIQUE MARTINIANO DE OLIVEIRA	6	t
32540502822	CARLOS EDUARDO MALAMAN	5	t
24886549810	DANILO GUIGUER DE OLIVEIRA	7	t
21675933847	DIEGO GONÇALVES DE ALCANTARA	7	t
00496426850	EDGAR ALBANEZ	5	t
15721307846	EDNEIA REBERTI ESCAME	6	t
31892853817	EDUARDA PIGATO CISCATO	7	t
30310116864	ELTON LUCCAS TUCKUMANTEL	1	t
80184782104	ELY ALVES SILVA	7	t
31082697800	ERIC DE OLIVEIRA MOTTA	7	t
40381911845	EVERTON AGUILLAR BURATTO	7	t
07666429681	FABRICIO ANDRE DA SILVA	6	t
38355373855	FERNANDA SALCIOTTO	6	t
35932472839	FLAVIA CLAUDIANO CORDIDO	6	t
31239665857	FLAVIO HENRIQUE SUMAIO CALDEIRAO	7	t
01110375816	FRANCISCO PAULO OLIVEIRA LIMA	5	t
82897123915	GLADISON FRANCISCO DA SILVA	6	t
36025331820	GRACE LIE HAMADA	6	t
39460172822	ICARO JOSE RIBEIRO GOMES	5	t
06762410855	JERUSO ALVES NASCIMENTO	7	t
22444646878	JOAO PINHEIRO NETO	5	t
36819640846	KARINA MIZUNO KANNO	6	t
05484576709	LEONARDO DE OLIVEIRA BURGER MONTEIRO LUIZ	5	t
42610681844	LETICIA LEONOR RIBEIRO MENDES	9	t
32628691809	LETICIA ROSALES BATISTA	6	t
47033640854	LUCCA MENCHINELLI E SILVA	7	t
04704982858	LUIS FERNANDO CORADINI	1	t
08922377674	LUIS HENRIQUE LIMA PEREIRA	5	t
10995999899	LUSMARINA ZULMIRA GOMES	1	t
27206162819	MARCELO MARQUES DE OLIVEIRA	5	t
14694180703	MATEUS BRINATI MACHADO	7	t
09085540950	MATHEUS KLEPARDE	7	t
18208623806	MAURICIO MIRANDA DE QUEIROZ	5	t
30841335818	MAURO LEMOS DA SILVA	6	t
36750397816	OLIVER TOBIAS KLEIBER	7	t
19216935847	PAULO CESAR OLIVATO	7	t
07902044792	PAULO RICARDO DE AGUIAR LIMA	6	t
09595897833	PAULO SERGIO MISSANO	7	t
26451064807	RAFAEL SILVA VARUZZA	7	t
35500297805	RAFAEL SIQUEIRA	7	t
32968804880	RAONI MACHADO	7	t
10410326682	RENAN CHAMONE SILVA	7	t
19174943863	RICARDO ALEXANDRE DA SILVA	3	t
27935713855	RODRIGO PADOAN ALBANEZ	7	t
29474854831	RODRIGO VALERIANO MACARENKO	1	t
13934950876	ROGERIO NASCIMENTO SANTOS	4	t
19163513870	RONALDO VALERIO GENTIL	6	t
24999284847	TABAJARA ZULIANI DOS SANTOS	5	t
12794506730	THAIANE CAROLINE DA SILVA MAROTO VENTURA	6	t
40952268892	TIAGO ANDRADE PUCCI	7	t
10531583600	VALERIA GONÇALVES BATISTA FARIA	6	t
19203432884	VANDER APARECIDO MARCELINO CAPRIOGLIO	7	t
44519520851	VICTOR ALVITI DE CARVALHO	6	t
33648957830	VITOR XONE BUENO DA SILVA	6	t
\.


--
-- Data for Name: tipos_diaria; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.tipos_diaria (id_tipo, descricao) FROM stdin;
1	SERVICO POLICIAL
2	TREINAMENTO
\.


--
-- Name: auditoria_log_id_log_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.auditoria_log_id_log_seq', 1, false);


--
-- Name: auditoria_migracao_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.auditoria_migracao_id_seq', 1, true);


--
-- Name: cargos_id_cargo_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.cargos_id_cargo_seq', 9, true);


--
-- Name: diarias_id_diaria_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.diarias_id_diaria_seq', 862, true);


--
-- Name: lancamentos_id_lancamento_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.lancamentos_id_lancamento_seq', 1, false);


--
-- Name: pagamentos_processo_id_pagamento_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.pagamentos_processo_id_pagamento_seq', 214, true);


--
-- Name: pds_id_pd_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.pds_id_pd_seq', 211, true);


--
-- Name: processos_id_processo_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.processos_id_processo_seq', 590, true);


--
-- Name: tipos_diaria_id_tipo_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.tipos_diaria_id_tipo_seq', 2, true);


--
-- Name: auditoria_log auditoria_log_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.auditoria_log
    ADD CONSTRAINT auditoria_log_pkey PRIMARY KEY (id_log);


--
-- Name: auditoria_migracao auditoria_migracao_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.auditoria_migracao
    ADD CONSTRAINT auditoria_migracao_pkey PRIMARY KEY (id);


--
-- Name: cargo cargos_descricao_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cargo
    ADD CONSTRAINT cargos_descricao_key UNIQUE (nome_cargo);


--
-- Name: cargo cargos_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cargo
    ADD CONSTRAINT cargos_pkey PRIMARY KEY (id_cargo);


--
-- Name: diarias diarias_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.diarias
    ADD CONSTRAINT diarias_pkey PRIMARY KEY (id_diaria);


--
-- Name: lancamentos lancamentos_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lancamentos
    ADD CONSTRAINT lancamentos_pkey PRIMARY KEY (id_lancamento);


--
-- Name: pagamentos_processo pagamentos_processo_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pagamentos_processo
    ADD CONSTRAINT pagamentos_processo_pkey PRIMARY KEY (id_pagamento);


--
-- Name: pds pds_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pds
    ADD CONSTRAINT pds_pkey PRIMARY KEY (id_pd);


--
-- Name: processos processos_numero_processo_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.processos
    ADD CONSTRAINT processos_numero_processo_key UNIQUE (numero_processo);


--
-- Name: processos processos_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.processos
    ADD CONSTRAINT processos_pkey PRIMARY KEY (id_processo);


--
-- Name: servidores servidores_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.servidores
    ADD CONSTRAINT servidores_pkey PRIMARY KEY (cpf_servidor);


--
-- Name: tipos_diaria tipos_diaria_descricao_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tipos_diaria
    ADD CONSTRAINT tipos_diaria_descricao_key UNIQUE (descricao);


--
-- Name: tipos_diaria tipos_diaria_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tipos_diaria
    ADD CONSTRAINT tipos_diaria_pkey PRIMARY KEY (id_tipo);


--
-- Name: diarias uq_diaria_unica; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.diarias
    ADD CONSTRAINT uq_diaria_unica UNIQUE (cpf_servidor, data_inicial, destino, motivo, valor_diaria, id_processo);


--
-- Name: pds uq_numero_pd_novo; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pds
    ADD CONSTRAINT uq_numero_pd_novo UNIQUE (numero_pd);


--
-- Name: processos uq_numero_processo_novo; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.processos
    ADD CONSTRAINT uq_numero_processo_novo UNIQUE (numero_processo);


--
-- Name: pagamentos_processo uq_pagamento_processo_pd; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pagamentos_processo
    ADD CONSTRAINT uq_pagamento_processo_pd UNIQUE (id_processo, numero_pd);


--
-- Name: pds uq_pds_numero; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pds
    ADD CONSTRAINT uq_pds_numero UNIQUE (numero_pd);


--
-- Name: processos uq_processo; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.processos
    ADD CONSTRAINT uq_processo UNIQUE (numero_processo);


--
-- Name: idx_diarias_cpf; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_diarias_cpf ON public.diarias USING btree (cpf_servidor);


--
-- Name: idx_diarias_data; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_diarias_data ON public.diarias USING btree (data_inicial);


--
-- Name: idx_diarias_destino; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_diarias_destino ON public.diarias USING btree (destino);


--
-- Name: idx_diarias_id_processo; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_diarias_id_processo ON public.diarias USING btree (id_processo);


--
-- Name: idx_diarias_processo; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_diarias_processo ON public.diarias USING btree (id_processo);


--
-- Name: idx_lancamentos_cpf; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_lancamentos_cpf ON public.lancamentos USING btree (cpf_servidor);


--
-- Name: idx_lancamentos_id_tipo; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_lancamentos_id_tipo ON public.lancamentos USING btree (id_tipo);


--
-- Name: idx_pagamentos_data; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_pagamentos_data ON public.pagamentos_processo USING btree (data_pagamento);


--
-- Name: idx_pagamentos_id_processo; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_pagamentos_id_processo ON public.pagamentos_processo USING btree (id_processo);


--
-- Name: idx_pagamentos_pd; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_pagamentos_pd ON public.pagamentos_processo USING btree (id_pd);


--
-- Name: idx_pagamentos_processo; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_pagamentos_processo ON public.pagamentos_processo USING btree (id_processo);


--
-- Name: idx_pds_numero; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_pds_numero ON public.pds USING btree (numero_pd);


--
-- Name: idx_processos_numero; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_processos_numero ON public.processos USING btree (numero_processo);


--
-- Name: idx_servidores_id_cargo; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_servidores_id_cargo ON public.servidores USING btree (id_cargo);


--
-- Name: diarias fk_diaria_servidor; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.diarias
    ADD CONSTRAINT fk_diaria_servidor FOREIGN KEY (cpf_servidor) REFERENCES public.servidores(cpf_servidor);


--
-- Name: diarias fk_diaria_tipo; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.diarias
    ADD CONSTRAINT fk_diaria_tipo FOREIGN KEY (id_tipo) REFERENCES public.tipos_diaria(id_tipo);


--
-- Name: diarias fk_diarias_processo; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.diarias
    ADD CONSTRAINT fk_diarias_processo FOREIGN KEY (id_processo) REFERENCES public.processos(id_processo);


--
-- Name: lancamentos fk_lancamento_servidor; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lancamentos
    ADD CONSTRAINT fk_lancamento_servidor FOREIGN KEY (cpf_servidor) REFERENCES public.servidores(cpf_servidor);


--
-- Name: lancamentos fk_lancamento_tipo; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lancamentos
    ADD CONSTRAINT fk_lancamento_tipo FOREIGN KEY (id_tipo) REFERENCES public.tipos_diaria(id_tipo);


--
-- Name: pagamentos_processo fk_pagamento_pd; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pagamentos_processo
    ADD CONSTRAINT fk_pagamento_pd FOREIGN KEY (id_pd) REFERENCES public.pds(id_pd);


--
-- Name: pagamentos_processo fk_pagamento_processo; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pagamentos_processo
    ADD CONSTRAINT fk_pagamento_processo FOREIGN KEY (id_processo) REFERENCES public.processos(id_processo);


--
-- Name: servidores fk_servidor_cargo; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.servidores
    ADD CONSTRAINT fk_servidor_cargo FOREIGN KEY (id_cargo) REFERENCES public.cargo(id_cargo);


--
-- PostgreSQL database dump complete
--

\unrestrict p8iEfsY6Mh0EJtdRReRSvbdyFiX5uEqLd5tDfz0qQi3LnDJeLvhtlhWsoHrRSnI

