-- Table: ss.game_type

-- DROP TABLE IF EXISTS ss.game_type;

CREATE TABLE IF NOT EXISTS ss.game_type
(
    game_type_id bigint NOT NULL GENERATED ALWAYS AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 9223372036854775807 CACHE 1 ),
    game_type_name character varying(128) COLLATE pg_catalog."default" NOT NULL,
    game_mode_id bigint,
    CONSTRAINT game_type_pkey PRIMARY KEY (game_type_id),
    CONSTRAINT game_type_game_type_name_game_type_id_game_mode_id_key UNIQUE (game_type_name)
        INCLUDE(game_type_id, game_mode_id),
    CONSTRAINT game_type_game_mode_id_fkey FOREIGN KEY (game_mode_id)
        REFERENCES ss.game_mode (game_mode_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS ss.game_type
    OWNER to ss_developer;