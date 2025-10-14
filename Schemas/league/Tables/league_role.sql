-- Table: league.league_role

-- DROP TABLE IF EXISTS league.league_role;

CREATE TABLE IF NOT EXISTS league.league_role
(
    league_role_id bigint NOT NULL,
    league_role_name character varying(32) COLLATE pg_catalog."default" NOT NULL,
    CONSTRAINT league_role_pkey PRIMARY KEY (league_role_id),
    CONSTRAINT league_role_league_role_name_key UNIQUE (league_role_name)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS league.league_role
    OWNER to ss_developer;