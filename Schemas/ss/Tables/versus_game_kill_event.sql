-- Table: ss.versus_game_kill_event

-- DROP TABLE IF EXISTS ss.versus_game_kill_event;

CREATE TABLE IF NOT EXISTS ss.versus_game_kill_event
(
    game_event_id bigint NOT NULL,
    killed_player_id bigint NOT NULL,
    killer_player_id bigint NOT NULL,
    is_knockout boolean NOT NULL,
    is_team_kill boolean NOT NULL,
    x_coord smallint NOT NULL,
    y_coord smallint NOT NULL,
    killed_ship smallint NOT NULL,
    killer_ship smallint NOT NULL,
    score integer[] NOT NULL,
    remaining_slots integer[] NOT NULL,
    CONSTRAINT versus_game_kill_event_pkey PRIMARY KEY (game_event_id),
    CONSTRAINT versus_game_kill_event_game_event_id_fkey FOREIGN KEY (game_event_id)
        REFERENCES ss.game_event (game_event_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT versus_game_kill_event_killed_player_id_fkey FOREIGN KEY (killed_player_id)
        REFERENCES ss.player (player_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT versus_game_kill_event_killer_player_id_fkey FOREIGN KEY (killer_player_id)
        REFERENCES ss.player (player_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT versus_game_kill_event_x_coord_check CHECK (x_coord >= 0 AND x_coord <= 16384),
    CONSTRAINT versus_game_kill_event_y_coord_check CHECK (y_coord >= 0 AND y_coord <= 16384),
    CONSTRAINT versus_game_kill_event_killed_ship_check CHECK (killed_ship >= 0 AND killed_ship <= 7),
    CONSTRAINT versus_game_kill_event_killer_ship_check CHECK (killer_ship >= 0 AND killer_ship <= 7)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS ss.versus_game_kill_event
    OWNER to postgres;