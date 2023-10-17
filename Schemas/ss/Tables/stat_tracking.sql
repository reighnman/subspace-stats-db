-- Table: ss.stat_tracking

-- DROP TABLE IF EXISTS ss.stat_tracking;

CREATE TABLE IF NOT EXISTS ss.stat_tracking
(
    stat_tracking_id bigint NOT NULL,
    game_type_id bigint NOT NULL,
    stat_period_type_id bigint NOT NULL,
    is_auto_generate_period boolean NOT NULL,
    is_rating_enabled boolean NOT NULL,
    initial_rating integer,
    minimum_rating integer,
    CONSTRAINT stat_tracking_pkey PRIMARY KEY (stat_tracking_id),
    CONSTRAINT stat_tracking_game_type_id_stat_period_type_id_key UNIQUE (game_type_id, stat_period_type_id),
    CONSTRAINT stat_tracking_game_type_id_fkey FOREIGN KEY (game_type_id)
        REFERENCES ss.game_type (game_type_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT stat_tracking_stat_period_type_id_fkey FOREIGN KEY (stat_period_type_id)
        REFERENCES ss.stat_period_type (stat_period_type_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS ss.stat_tracking
    OWNER to postgres;