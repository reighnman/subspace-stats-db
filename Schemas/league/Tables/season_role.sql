-- Table: league.season_role

-- DROP TABLE IF EXISTS league.season_role;

CREATE TABLE IF NOT EXISTS league.season_role
(
    season_role_id bigint NOT NULL,
    season_role_name character varying(32) COLLATE pg_catalog."default" NOT NULL,
    CONSTRAINT season_role_pkey PRIMARY KEY (season_role_id),
    CONSTRAINT season_role_season_role_name_key UNIQUE (season_role_name)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS league.season_role
    OWNER to ss_developer;