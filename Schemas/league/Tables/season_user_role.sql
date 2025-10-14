-- Table: league.season_user_role

-- DROP TABLE IF EXISTS league.season_user_role;

CREATE TABLE IF NOT EXISTS league.season_user_role
(
    user_id text COLLATE pg_catalog."default" NOT NULL,
    season_id bigint NOT NULL,
    season_role_id bigint NOT NULL,
    CONSTRAINT season_user_role_pkey PRIMARY KEY (user_id, season_id, season_role_id),
    CONSTRAINT season_user_role_season_id_fkey FOREIGN KEY (season_id)
        REFERENCES league.season (season_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT season_user_role_season_role_id_fkey FOREIGN KEY (season_role_id)
        REFERENCES league.season_role (season_role_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS league.season_user_role
    OWNER to ss_developer;
-- Index: season_user_role_season_id_user_id_season_role_id_idx

-- DROP INDEX IF EXISTS league.season_user_role_season_id_user_id_season_role_id_idx;

CREATE INDEX IF NOT EXISTS season_user_role_season_id_user_id_season_role_id_idx
    ON league.season_user_role USING btree
    (season_id ASC NULLS LAST)
    INCLUDE(user_id, season_role_id)
    WITH (fillfactor=100, deduplicate_items=True)
    TABLESPACE pg_default;