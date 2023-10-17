-- Table: ss.game

-- DROP TABLE IF EXISTS ss.game;

CREATE TABLE IF NOT EXISTS ss.game
(
    game_id bigint NOT NULL GENERATED ALWAYS AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 9223372036854775807 CACHE 1 ),
    game_type_id bigint NOT NULL,
    zone_server_id bigint NOT NULL,
    arena_id bigint NOT NULL,
    box_number integer,
    time_played tstzrange NOT NULL,
    replay_path character varying COLLATE pg_catalog."default",
    lvl_id bigint NOT NULL,
    CONSTRAINT game_pkey PRIMARY KEY (game_id),
    CONSTRAINT game_arena_id_fkey FOREIGN KEY (arena_id)
        REFERENCES ss.arena (arena_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT game_game_type_id_fkey FOREIGN KEY (game_type_id)
        REFERENCES ss.game_type (game_type_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT game_lvl_id_fkey FOREIGN KEY (lvl_id)
        REFERENCES ss.lvl (lvl_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT game_zone_server_id_fkey FOREIGN KEY (zone_server_id)
        REFERENCES ss.zone_server (zone_server_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS ss.game
    OWNER to postgres;
-- Index: game_time_played_game_type_id_game_id_idx

-- DROP INDEX IF EXISTS ss.game_time_played_game_type_id_game_id_idx;

CREATE INDEX IF NOT EXISTS game_time_played_game_type_id_game_id_idx
    ON ss.game USING gist
    (time_played)
    INCLUDE(game_type_id, game_id)
    WITH (buffering=auto)
    TABLESPACE pg_default;