-- Table: league.team

-- DROP TABLE IF EXISTS league.team;

CREATE TABLE IF NOT EXISTS league.team
(
    team_id bigint NOT NULL GENERATED ALWAYS AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 9223372036854775807 CACHE 1 ),
    team_name character varying(20) COLLATE ss.case_insensitive NOT NULL,
    season_id bigint NOT NULL,
    banner_small character varying(255) COLLATE pg_catalog."default",
    banner_large character varying(255) COLLATE pg_catalog."default",
    wins integer NOT NULL DEFAULT 0,
    losses integer NOT NULL DEFAULT 0,
    draws integer NOT NULL DEFAULT 0,
    is_enabled boolean NOT NULL DEFAULT true,
    franchise_id bigint,
    CONSTRAINT team_pkey PRIMARY KEY (team_id),
    CONSTRAINT team_team_name_season_id_key UNIQUE (team_name, season_id),
    CONSTRAINT team_franchise_id_fkey FOREIGN KEY (franchise_id)
        REFERENCES league.franchise (franchise_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT team_season_id_fkey FOREIGN KEY (season_id)
        REFERENCES league.season (season_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS league.team
    OWNER to ss_developer;
-- Index: team_season_id_team_name_team_id_idx

-- DROP INDEX IF EXISTS league.team_season_id_team_name_team_id_idx;

CREATE INDEX IF NOT EXISTS team_season_id_team_name_team_id_idx
    ON league.team USING btree
    (season_id ASC NULLS LAST, team_name COLLATE ss.case_insensitive ASC NULLS LAST)
    INCLUDE(team_id)
    WITH (fillfactor=100, deduplicate_items=True)
    TABLESPACE pg_default;