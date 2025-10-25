-- Table: league.league

-- DROP TABLE IF EXISTS league.league;

CREATE TABLE IF NOT EXISTS league.league
(
    league_id bigint NOT NULL GENERATED ALWAYS AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 9223372036854775807 CACHE 1 ),
    league_name character varying(128) COLLATE pg_catalog."default" NOT NULL,
    game_type_id bigint NOT NULL,
    min_teams_per_game smallint NOT NULL DEFAULT 2,
    max_teams_per_game smallint NOT NULL DEFAULT 2,
    freq_start smallint NOT NULL DEFAULT 10,
    freq_increment smallint NOT NULL DEFAULT 10,
    CONSTRAINT league_pkey PRIMARY KEY (league_id),
    CONSTRAINT league_league_name_key UNIQUE (league_name),
    CONSTRAINT league_game_type_id_fkey FOREIGN KEY (game_type_id)
        REFERENCES ss.game_type (game_type_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT league_min_teams_per_game_check CHECK (min_teams_per_game >= 2),
    CONSTRAINT league_teams_per_game_check CHECK (max_teams_per_game >= min_teams_per_game),
    CONSTRAINT league_max_freq_check CHECK ((freq_start + (max_teams_per_game - 1) * freq_increment) <= 9999)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS league.league
    OWNER to ss_developer;
-- Index: league_game_type_id_idx

-- DROP INDEX IF EXISTS league.league_game_type_id_idx;

CREATE INDEX IF NOT EXISTS league_game_type_id_idx
    ON league.league USING btree
    (game_type_id ASC NULLS LAST)
    WITH (fillfactor=100, deduplicate_items=True)
    TABLESPACE pg_default;