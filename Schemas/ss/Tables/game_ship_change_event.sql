-- Table: ss.game_ship_change_event

-- DROP TABLE IF EXISTS ss.game_ship_change_event;

CREATE TABLE IF NOT EXISTS ss.game_ship_change_event
(
    game_event_id bigint NOT NULL,
    player_id bigint NOT NULL,
    ship smallint NOT NULL,
    CONSTRAINT game_ship_change_event_pkey PRIMARY KEY (game_event_id),
    CONSTRAINT game_ship_change_event_game_event_id_fkey FOREIGN KEY (game_event_id)
        REFERENCES ss.game_event (game_event_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT game_ship_change_event_player_id_fkey FOREIGN KEY (player_id)
        REFERENCES ss.player (player_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT game_ship_change_event_ship_check CHECK (ship >= 0 AND ship <= 7)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS ss.game_ship_change_event
    OWNER to ss_developer;