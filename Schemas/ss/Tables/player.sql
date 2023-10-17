-- Table: ss.player

-- DROP TABLE IF EXISTS ss.player;

CREATE TABLE IF NOT EXISTS ss.player
(
    player_id bigint NOT NULL GENERATED ALWAYS AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 9223372036854775807 CACHE 1 ),
    player_name character varying(20) COLLATE ss.case_insensitive NOT NULL,
    squad_id bigint,
    x_res smallint,
    y_res smallint,
    CONSTRAINT player_pkey PRIMARY KEY (player_id),
    CONSTRAINT player_player_name_key UNIQUE (player_name),
    CONSTRAINT player_squad_id_fkey FOREIGN KEY (squad_id)
        REFERENCES ss.squad (squad_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS ss.player
    OWNER to postgres;