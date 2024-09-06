-- Table: ss.game_event_type

-- DROP TABLE IF EXISTS ss.game_event_type;

CREATE TABLE IF NOT EXISTS ss.game_event_type
(
    game_event_type_id bigint NOT NULL,
    game_event_type_description character varying COLLATE pg_catalog."default" NOT NULL,
    CONSTRAINT game_event_type_pkey PRIMARY KEY (game_event_type_id)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS ss.game_event_type
    OWNER to ss_developer;