-- Table: ss.player_solo_stats

-- DROP TABLE IF EXISTS ss.player_solo_stats;

CREATE TABLE IF NOT EXISTS ss.player_solo_stats
(
    player_id bigint NOT NULL,
    stat_period_id bigint NOT NULL,
    games_played bigint NOT NULL,
    play_duration interval NOT NULL,
    score bigint NOT NULL,
    wins bigint NOT NULL,
    losses bigint NOT NULL,
    kills bigint NOT NULL,
    deaths bigint NOT NULL,
    gun_damage_dealt bigint NOT NULL,
    bomb_damage_dealt bigint NOT NULL,
    gun_damage_taken bigint NOT NULL,
    bomb_damage_taken bigint NOT NULL,
    self_damage bigint NOT NULL,
    gun_fire_count bigint NOT NULL,
    bomb_fire_count bigint NOT NULL,
    mine_fire_count bigint NOT NULL,
    gun_hit_count bigint NOT NULL,
    bomb_hit_count bigint NOT NULL,
    mine_hit_count bigint NOT NULL,
    CONSTRAINT player_solo_stats_pkey PRIMARY KEY (player_id, stat_period_id),
    CONSTRAINT player_solo_stats_player_id_fkey FOREIGN KEY (player_id)
        REFERENCES ss.player (player_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT player_solo_stats_stat_period_id_fkey FOREIGN KEY (stat_period_id)
        REFERENCES ss.stat_period (stat_period_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS ss.player_solo_stats
    OWNER to ss_developer;
-- Index: player_solo_stats_stat_period_id_player_id_idx

-- DROP INDEX IF EXISTS ss.player_solo_stats_stat_period_id_player_id_idx;

CREATE INDEX IF NOT EXISTS player_solo_stats_stat_period_id_player_id_idx
    ON ss.player_solo_stats USING btree
    (stat_period_id ASC NULLS LAST, player_id ASC NULLS LAST)
    WITH (deduplicate_items=True)
    TABLESPACE pg_default;