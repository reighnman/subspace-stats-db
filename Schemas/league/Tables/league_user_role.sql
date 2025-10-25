-- Table: league.league_user_role

-- DROP TABLE IF EXISTS league.league_user_role;

CREATE TABLE IF NOT EXISTS league.league_user_role
(
    user_id text COLLATE pg_catalog."default" NOT NULL,
    league_id bigint NOT NULL,
    league_role_id bigint NOT NULL,
    CONSTRAINT league_user_role_pkey PRIMARY KEY (user_id, league_id, league_role_id),
    CONSTRAINT league_user_role_league_id_fkey FOREIGN KEY (league_id)
        REFERENCES league.league (league_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT league_user_role_league_role_id_fkey FOREIGN KEY (league_role_id)
        REFERENCES league.league_role (league_role_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS league.league_user_role
    OWNER to ss_developer;
-- Index: league_user_role_league_id_user_id_league_role_id_idx

-- DROP INDEX IF EXISTS league.league_user_role_league_id_user_id_league_role_id_idx;

CREATE INDEX IF NOT EXISTS league_user_role_league_id_user_id_league_role_id_idx
    ON league.league_user_role USING btree
    (league_id ASC NULLS LAST)
    INCLUDE(user_id, league_role_id)
    WITH (fillfactor=100, deduplicate_items=True)
    TABLESPACE pg_default;