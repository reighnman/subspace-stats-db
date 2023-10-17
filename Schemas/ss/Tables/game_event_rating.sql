-- Table: ss.game_event_rating

-- DROP TABLE IF EXISTS ss.game_event_rating;

CREATE TABLE IF NOT EXISTS ss.game_event_rating
(
    game_event_id bigint NOT NULL,
    player_id bigint NOT NULL,
    rating real NOT NULL,
    CONSTRAINT game_event_rating_pkey PRIMARY KEY (game_event_id, player_id),
    CONSTRAINT game_event_rating_game_event_id_fkey FOREIGN KEY (game_event_id)
        REFERENCES ss.game_event (game_event_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT game_event_rating_player_id_fkey FOREIGN KEY (player_id)
        REFERENCES ss.player (player_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS ss.game_event_rating
    OWNER to postgres;