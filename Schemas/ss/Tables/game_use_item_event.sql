-- Table: ss.game_use_item_event

-- DROP TABLE IF EXISTS ss.game_use_item_event;

CREATE TABLE IF NOT EXISTS ss.game_use_item_event
(
    game_event_id bigint NOT NULL,
    player_id bigint NOT NULL,
    ship_item_id smallint NOT NULL,
    CONSTRAINT game_use_item_event_pkey PRIMARY KEY (game_event_id),
    CONSTRAINT game_use_item_event_game_event_id_fkey FOREIGN KEY (game_event_id)
        REFERENCES ss.game_event (game_event_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT game_use_item_event_player_id_fkey FOREIGN KEY (player_id)
        REFERENCES ss.player (player_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT game_use_item_event_ship_item_id_fkey FOREIGN KEY (ship_item_id)
        REFERENCES ss.ship_item (ship_item_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS ss.game_use_item_event
    OWNER to ss_developer;