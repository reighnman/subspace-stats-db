-- Table: ss.versus_game_assign_slot_event

-- DROP TABLE IF EXISTS ss.versus_game_assign_slot_event;

CREATE TABLE IF NOT EXISTS ss.versus_game_assign_slot_event
(
    game_event_id bigint NOT NULL,
    freq smallint NOT NULL,
    slot_idx smallint NOT NULL,
    player_id bigint NOT NULL,
    CONSTRAINT versus_game_assign_slot_event_pkey PRIMARY KEY (game_event_id),
    CONSTRAINT versus_game_assign_slot_event_game_event_id_fkey FOREIGN KEY (game_event_id)
        REFERENCES ss.game_event (game_event_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT versus_game_assign_slot_event_player_id_fkey FOREIGN KEY (player_id)
        REFERENCES ss.player (player_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS ss.versus_game_assign_slot_event
    OWNER to ss_developer;