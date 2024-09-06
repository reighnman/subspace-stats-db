-- Table: ss.player_ship_usage

-- DROP TABLE IF EXISTS ss.player_ship_usage;

CREATE TABLE IF NOT EXISTS ss.player_ship_usage
(
    player_id bigint NOT NULL,
    stat_period_id bigint NOT NULL,
    warbird_use integer NOT NULL,
    javelin_use integer NOT NULL,
    spider_use integer NOT NULL,
    leviathan_use integer NOT NULL,
    terrier_use integer NOT NULL,
    weasel_use integer NOT NULL,
    lancaster_use integer NOT NULL,
    shark_use integer NOT NULL,
    warbird_duration interval NOT NULL,
    javelin_duration interval NOT NULL,
    spider_duration interval NOT NULL,
    leviathan_duration interval NOT NULL,
    terrier_duration interval NOT NULL,
    weasel_duration interval NOT NULL,
    lancaster_duration interval NOT NULL,
    shark_duration interval NOT NULL,
    CONSTRAINT player_ship_usage_pkey PRIMARY KEY (player_id, stat_period_id),
    CONSTRAINT player_ship_usage_player_id_fkey FOREIGN KEY (player_id)
        REFERENCES ss.player (player_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT player_ship_usage_stat_period_id_fkey FOREIGN KEY (stat_period_id)
        REFERENCES ss.stat_period (stat_period_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS ss.player_ship_usage
    OWNER to ss_developer;