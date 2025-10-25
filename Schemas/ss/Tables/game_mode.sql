-- Table: ss.game_mode

-- DROP TABLE IF EXISTS ss.game_mode;

CREATE TABLE IF NOT EXISTS ss.game_mode
(
    game_mode_id bigint NOT NULL,
    game_mode_name character varying(128) COLLATE pg_catalog."default" NOT NULL,
    CONSTRAINT game_mode_pkey PRIMARY KEY (game_mode_id),
    CONSTRAINT game_mode_game_mode_name_key UNIQUE (game_mode_name)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS ss.game_mode
    OWNER to ss_developer;