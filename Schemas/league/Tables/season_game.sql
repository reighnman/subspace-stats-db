-- Table: league.season_game

-- DROP TABLE IF EXISTS league.season_game;

CREATE TABLE IF NOT EXISTS league.season_game
(
    season_game_id bigint NOT NULL GENERATED ALWAYS AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 9223372036854775807 CACHE 1 ),
    season_id bigint NOT NULL,
    round_number integer,
    game_timestamp timestamp with time zone,
    game_id bigint,
    game_status_id bigint NOT NULL,
    CONSTRAINT season_game_pkey PRIMARY KEY (season_game_id),
    CONSTRAINT season_game_game_id_key UNIQUE (game_id),
    CONSTRAINT season_game_game_id_fkey FOREIGN KEY (game_id)
        REFERENCES ss.game (game_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT season_game_game_status_id_fkey FOREIGN KEY (game_status_id)
        REFERENCES league.game_status (game_status_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT season_game_season_id_fkey FOREIGN KEY (season_id)
        REFERENCES league.season (season_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS league.season_game
    OWNER to ss_developer;