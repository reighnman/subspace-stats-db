-- Table: league.season_game_team

-- DROP TABLE IF EXISTS league.season_game_team;

CREATE TABLE IF NOT EXISTS league.season_game_team
(
    season_game_id bigint NOT NULL,
    team_id bigint NOT NULL,
    freq smallint,
    is_winner boolean,
    score integer
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS league.season_game_team
    OWNER to ss_developer;