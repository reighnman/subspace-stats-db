-- Table: league.season

-- DROP TABLE IF EXISTS league.season;

CREATE TABLE IF NOT EXISTS league.season
(
    season_id bigint NOT NULL GENERATED ALWAYS AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 9223372036854775807 CACHE 1 ),
    season_name character varying(128) COLLATE pg_catalog."default" NOT NULL,
    league_id bigint NOT NULL,
    created_timestamp timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    start_date date,
    end_date date,
    stat_period_id bigint,
    CONSTRAINT season_pkey PRIMARY KEY (season_id),
    CONSTRAINT season_season_name_league_id_key UNIQUE (season_name, league_id),
    CONSTRAINT season_stat_period_id_key UNIQUE (stat_period_id),
    CONSTRAINT season_league_id_fkey FOREIGN KEY (league_id)
        REFERENCES league.league (league_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT season_stat_period_id_fkey FOREIGN KEY (stat_period_id)
        REFERENCES ss.stat_period (stat_period_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS league.season
    OWNER to ss_developer;
-- Index: season_league_id_created_timestamp_season_id_idx

-- DROP INDEX IF EXISTS league.season_league_id_created_timestamp_season_id_idx;

CREATE INDEX IF NOT EXISTS season_league_id_created_timestamp_season_id_idx
    ON league.season USING btree
    (league_id ASC NULLS LAST, created_timestamp DESC NULLS FIRST)
    INCLUDE(season_id)
    WITH (fillfactor=100, deduplicate_items=True)
    TABLESPACE pg_default;