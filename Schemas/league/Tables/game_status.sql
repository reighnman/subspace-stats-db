-- Table: league.game_status

-- DROP TABLE IF EXISTS league.game_status;

CREATE TABLE IF NOT EXISTS league.game_status
(
    game_status_id bigint NOT NULL,
    game_status_name character varying(128) COLLATE pg_catalog."default" NOT NULL,
    game_status_description text COLLATE pg_catalog."default" NOT NULL,
    CONSTRAINT game_status_pkey PRIMARY KEY (game_status_id),
    CONSTRAINT game_status_game_status_name_key UNIQUE (game_status_name)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS league.game_status
    OWNER to ss_developer;