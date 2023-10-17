-- Table: ss.pb_game_score

-- DROP TABLE IF EXISTS ss.pb_game_score;

CREATE TABLE IF NOT EXISTS ss.pb_game_score
(
    game_id bigint NOT NULL,
    freq smallint NOT NULL,
    score smallint NOT NULL,
    is_winner boolean NOT NULL,
    CONSTRAINT pb_game_score_pkey PRIMARY KEY (game_id, freq),
    CONSTRAINT pb_game_score_game_id_fkey FOREIGN KEY (game_id)
        REFERENCES ss.game (game_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS ss.pb_game_score
    OWNER to postgres;