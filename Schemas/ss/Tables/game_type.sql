-- Table: ss.game_type

-- DROP TABLE IF EXISTS ss.game_type;

CREATE TABLE IF NOT EXISTS ss.game_type
(
    game_type_id bigint NOT NULL,
    game_type_description character varying COLLATE pg_catalog."default" NOT NULL,
    is_solo boolean NOT NULL,
    is_team_versus boolean NOT NULL,
    is_pb boolean NOT NULL,
    CONSTRAINT game_type_pkey PRIMARY KEY (game_type_id),
    CONSTRAINT game_type_game_type_name_key UNIQUE (game_type_description)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS ss.game_type
    OWNER to ss_developer;