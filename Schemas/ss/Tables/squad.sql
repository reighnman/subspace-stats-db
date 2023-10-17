-- Table: ss.squad

-- DROP TABLE IF EXISTS ss.squad;

CREATE TABLE IF NOT EXISTS ss.squad
(
    squad_id bigint NOT NULL GENERATED ALWAYS AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 9223372036854775807 CACHE 1 ),
    squad_name character varying(20) COLLATE ss.case_insensitive NOT NULL,
    CONSTRAINT squad_pkey PRIMARY KEY (squad_id),
    CONSTRAINT squad_squad_name_key UNIQUE (squad_name)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS ss.squad
    OWNER to postgres;