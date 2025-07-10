-- Table: league.franchise

-- DROP TABLE IF EXISTS league.franchise;

CREATE TABLE IF NOT EXISTS league.franchise
(
    franchise_id bigint NOT NULL,
    franchise_name character varying(64) COLLATE pg_catalog."default" NOT NULL,
    CONSTRAINT franchise_pkey PRIMARY KEY (franchise_id),
    CONSTRAINT franchise_franchise_name_key UNIQUE (franchise_name)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS league.franchise
    OWNER to ss_developer;