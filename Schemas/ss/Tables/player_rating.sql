-- Table: ss.player_rating

-- DROP TABLE IF EXISTS ss.player_rating;

CREATE TABLE IF NOT EXISTS ss.player_rating
(
    player_id bigint NOT NULL,
    stat_period_id bigint NOT NULL,
    rating integer NOT NULL,
    CONSTRAINT player_rating_pkey PRIMARY KEY (player_id, stat_period_id),
    CONSTRAINT player_rating_player_id_fkey FOREIGN KEY (player_id)
        REFERENCES ss.player (player_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT player_rating_stat_period_id_fkey FOREIGN KEY (stat_period_id)
        REFERENCES ss.stat_period (stat_period_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS ss.player_rating
    OWNER to postgres;
-- Index: player_rating_stat_period_id_rating_player_id_idx

-- DROP INDEX IF EXISTS ss.player_rating_stat_period_id_rating_player_id_idx;

CREATE INDEX IF NOT EXISTS player_rating_stat_period_id_rating_player_id_idx
    ON ss.player_rating USING btree
    (stat_period_id ASC NULLS LAST, rating ASC NULLS LAST)
    INCLUDE(player_id)
    WITH (deduplicate_items=True)
    TABLESPACE pg_default;