-- Table: league.roster

-- DROP TABLE IF EXISTS league.roster;

CREATE TABLE IF NOT EXISTS league.roster
(
    season_id bigint NOT NULL,
    player_id bigint NOT NULL,
    signup_timestamp timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    team_id bigint,
    enroll_timestamp timestamp with time zone,
    is_captain boolean NOT NULL DEFAULT false,
    is_suspended boolean NOT NULL DEFAULT false,
    CONSTRAINT roster_pkey PRIMARY KEY (season_id, player_id),
    CONSTRAINT roster_player_id_fkey FOREIGN KEY (player_id)
        REFERENCES ss.player (player_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT roster_season_id_fkey FOREIGN KEY (season_id)
        REFERENCES league.season (season_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT roster_team_id_fkey FOREIGN KEY (team_id)
        REFERENCES league.team (team_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS league.roster
    OWNER to ss_developer;
-- Index: roster_player_id_idx

-- DROP INDEX IF EXISTS league.roster_player_id_idx;

CREATE INDEX IF NOT EXISTS roster_player_id_idx
    ON league.roster USING btree
    (player_id ASC NULLS LAST)
    WITH (fillfactor=100, deduplicate_items=True)
    TABLESPACE pg_default;
-- Index: roster_team_id_idx

-- DROP INDEX IF EXISTS league.roster_team_id_idx;

CREATE INDEX IF NOT EXISTS roster_team_id_idx
    ON league.roster USING btree
    (team_id ASC NULLS LAST)
    WITH (fillfactor=100, deduplicate_items=True)
    TABLESPACE pg_default;