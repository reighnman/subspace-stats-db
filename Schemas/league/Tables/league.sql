-- Table: league.league

-- DROP TABLE IF EXISTS league.league;

CREATE TABLE IF NOT EXISTS league.league
(
    league_id bigint NOT NULL,
    league_name character varying(128) COLLATE pg_catalog."default" NOT NULL,
    game_type_id bigint NOT NULL,
    CONSTRAINT league_pkey PRIMARY KEY (league_id),
    CONSTRAINT league_league_name_key UNIQUE (league_name),
    CONSTRAINT league_game_type_id_fkey FOREIGN KEY (game_type_id)
        REFERENCES ss.game_type (game_type_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
        NOT VALID
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS league.league
    OWNER to ss_developer;