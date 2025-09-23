-- Table: league.season_round

-- DROP TABLE IF EXISTS league.season_round;

CREATE TABLE IF NOT EXISTS league.season_round
(
    season_id bigint NOT NULL,
    round_number integer NOT NULL,
    round_name character varying(128) COLLATE pg_catalog."default" NOT NULL,
    round_description text COLLATE pg_catalog."default",
    CONSTRAINT season_round_pkey PRIMARY KEY (season_id, round_number),
    CONSTRAINT season_round_season_id_fkey FOREIGN KEY (season_id)
        REFERENCES league.season (season_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS league.season_round
    OWNER to ss_developer;