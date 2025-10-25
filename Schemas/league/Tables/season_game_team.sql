-- Table: league.season_game_team

-- DROP TABLE IF EXISTS league.season_game_team;

CREATE TABLE IF NOT EXISTS league.season_game_team
(
    season_game_id bigint NOT NULL,
    team_id bigint NOT NULL,
    freq smallint NOT NULL,
    is_winner boolean NOT NULL DEFAULT false,
    score integer,
    CONSTRAINT season_game_team_pkey PRIMARY KEY (season_game_id, team_id),
    CONSTRAINT season_game_team_season_game_id_freq_key UNIQUE (season_game_id, freq)
        DEFERRABLE INITIALLY DEFERRED,
    CONSTRAINT season_game_team_season_game_id_fkey FOREIGN KEY (season_game_id)
        REFERENCES league.season_game (season_game_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT season_game_team_team_id_fkey FOREIGN KEY (team_id)
        REFERENCES league.team (team_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS league.season_game_team
    OWNER to ss_developer;
-- Index: season_game_team_team_id_idx

-- DROP INDEX IF EXISTS league.season_game_team_team_id_idx;

CREATE INDEX IF NOT EXISTS season_game_team_team_id_idx
    ON league.season_game_team USING btree
    (team_id ASC NULLS LAST)
    WITH (fillfactor=100, deduplicate_items=True)
    TABLESPACE pg_default;