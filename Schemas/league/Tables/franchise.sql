-- Table: league.franchise

-- DROP TABLE IF EXISTS league.franchise;

CREATE TABLE IF NOT EXISTS league.franchise
(
    franchise_id bigint NOT NULL GENERATED ALWAYS AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 9223372036854775807 CACHE 1 ),
    franchise_name character varying(64) COLLATE pg_catalog."default" NOT NULL,
    CONSTRAINT franchise_pkey PRIMARY KEY (franchise_id),
    CONSTRAINT franchise_franchise_name_franchise_id_key UNIQUE (franchise_name)
        INCLUDE(franchise_id)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS league.franchise
    OWNER to ss_developer;