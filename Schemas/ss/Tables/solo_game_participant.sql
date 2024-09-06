-- Table: ss.solo_game_participant

-- DROP TABLE IF EXISTS ss.solo_game_participant;

CREATE TABLE IF NOT EXISTS ss.solo_game_participant
(
    game_id bigint NOT NULL,
    player_id bigint NOT NULL,
    play_duration interval NOT NULL,
    ship_mask smallint NOT NULL,
    is_winner boolean NOT NULL,
    score integer NOT NULL,
    kills smallint NOT NULL,
    deaths smallint NOT NULL,
    end_energy smallint,
    gun_damage_dealt integer NOT NULL,
    bomb_damage_dealt integer NOT NULL,
    gun_damage_taken integer NOT NULL,
    bomb_damage_taken integer NOT NULL,
    self_damage integer NOT NULL,
    gun_fire_count integer NOT NULL,
    bomb_fire_count integer NOT NULL,
    mine_fire_count integer NOT NULL,
    gun_hit_count integer NOT NULL,
    bomb_hit_count integer NOT NULL,
    mine_hit_count integer NOT NULL,
    CONSTRAINT solo_game_participant_pkey PRIMARY KEY (game_id, player_id),
    CONSTRAINT solo_game_participant_game_id_fkey FOREIGN KEY (game_id)
        REFERENCES ss.game (game_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT solo_game_participant_player_id_fkey FOREIGN KEY (player_id)
        REFERENCES ss.player (player_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS ss.solo_game_participant
    OWNER to ss_developer;
-- Index: solo_game_participant_player_id_game_id_idx

-- DROP INDEX IF EXISTS ss.solo_game_participant_player_id_game_id_idx;

CREATE INDEX IF NOT EXISTS solo_game_participant_player_id_game_id_idx
    ON ss.solo_game_participant USING btree
    (player_id ASC NULLS LAST, game_id ASC NULLS LAST)
    WITH (deduplicate_items=True)
    TABLESPACE pg_default;