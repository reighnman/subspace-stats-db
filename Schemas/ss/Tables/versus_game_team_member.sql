-- Table: ss.versus_game_team_member

-- DROP TABLE IF EXISTS ss.versus_game_team_member;

CREATE TABLE IF NOT EXISTS ss.versus_game_team_member
(
    game_id bigint NOT NULL,
    freq smallint NOT NULL,
    slot_idx smallint NOT NULL,
    member_idx smallint NOT NULL,
    player_id bigint NOT NULL,
	premade_group smallint,
    play_duration interval NOT NULL,
    ship_mask smallint NOT NULL,
    lag_outs smallint NOT NULL,
    kills smallint NOT NULL,
    deaths smallint NOT NULL,
    knockouts smallint NOT NULL,
    team_kills smallint NOT NULL,
    solo_kills smallint NOT NULL,
    assists smallint NOT NULL,
    forced_reps smallint NOT NULL,
    gun_damage_dealt integer NOT NULL,
    bomb_damage_dealt integer NOT NULL,
    team_damage_dealt integer NOT NULL,
    gun_damage_taken integer NOT NULL,
    bomb_damage_taken integer NOT NULL,
    team_damage_taken integer NOT NULL,
    self_damage integer NOT NULL,
    kill_damage integer NOT NULL,
    team_kill_damage integer NOT NULL,
    forced_rep_damage integer NOT NULL,
    bullet_fire_count integer NOT NULL,
    bomb_fire_count integer NOT NULL,
    mine_fire_count integer NOT NULL,
    bullet_hit_count integer NOT NULL,
    bomb_hit_count integer NOT NULL,
    mine_hit_count integer NOT NULL,
    first_out smallint NOT NULL,
    wasted_energy integer NOT NULL,
    wasted_repel smallint NOT NULL,
    wasted_rocket smallint NOT NULL,
    wasted_thor smallint NOT NULL,
    wasted_burst smallint NOT NULL,
    wasted_decoy smallint NOT NULL,
    wasted_portal smallint NOT NULL,
    wasted_brick smallint NOT NULL,
    rating_change integer NOT NULL,
    enemy_distance_sum bigint,
    enemy_distance_samples integer,
    team_distance_sum bigint,
    team_distance_samples integer,
    CONSTRAINT versus_game_team_member_pkey PRIMARY KEY (game_id, freq, slot_idx, member_idx),
    CONSTRAINT versus_game_team_member_game_id_freq_fkey FOREIGN KEY (game_id, freq)
        REFERENCES ss.versus_game_team (game_id, freq) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT versus_game_team_member_player_id_fkey FOREIGN KEY (player_id)
        REFERENCES ss.player (player_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT versus_game_team_member_ship_mask_check CHECK (ship_mask >= 0 AND ship_mask <= 255)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS ss.versus_game_team_member
    OWNER to ss_developer;
-- Index: versus_game_team_member_player_id_game_id_freq_idx

-- DROP INDEX IF EXISTS ss.versus_game_team_member_player_id_game_id_freq_idx;

CREATE INDEX IF NOT EXISTS versus_game_team_member_player_id_game_id_freq_idx
    ON ss.versus_game_team_member USING btree
    (player_id ASC NULLS LAST)
    INCLUDE(game_id, freq)
    WITH (deduplicate_items=True)
    TABLESPACE pg_default;