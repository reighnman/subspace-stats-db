-- Table: ss.game_event_damage

-- DROP TABLE IF EXISTS ss.game_event_damage;

CREATE TABLE IF NOT EXISTS ss.game_event_damage
(
    game_event_id bigint NOT NULL,
    player_id bigint NOT NULL,
    damage smallint NOT NULL,
    CONSTRAINT game_event_damage_pkey PRIMARY KEY (game_event_id, player_id),
    CONSTRAINT game_event_damage_game_event_id_fkey FOREIGN KEY (game_event_id)
        REFERENCES ss.game_event (game_event_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT game_event_damage_player_id_fkey FOREIGN KEY (player_id)
        REFERENCES ss.player (player_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT game_event_damage_damage_check CHECK (damage > 0)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS ss.game_event_damage
    OWNER to ss_developer;