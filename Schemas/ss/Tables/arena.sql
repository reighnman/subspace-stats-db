-- Table: ss.arena

-- DROP TABLE IF EXISTS ss.arena;

CREATE TABLE IF NOT EXISTS ss.arena
(
    arena_id bigint NOT NULL GENERATED ALWAYS AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 9223372036854775807 CACHE 1 ),
    arena_name character varying(15) COLLATE ss.case_insensitive NOT NULL,
    arena_group character varying(15) COLLATE ss.case_insensitive NOT NULL GENERATED ALWAYS AS (COALESCE(NULLIF(TRIM(TRAILING '0123456789'::text FROM arena_name), ''::text), '(public)'::text)) STORED,
    arena_number integer NOT NULL GENERATED ALWAYS AS ((COALESCE(NULLIF("right"((arena_name)::text, (length((arena_name)::text) - length(TRIM(TRAILING '0123456789'::text FROM arena_name)))), ''::text), '0'::text))::integer) STORED,
    CONSTRAINT arena_pkey PRIMARY KEY (arena_id),
    CONSTRAINT arena_arena_name_key UNIQUE (arena_name)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS ss.arena
    OWNER to postgres;