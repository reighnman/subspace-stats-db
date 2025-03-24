-- Table: ss.versus_game_team

-- DROP TABLE IF EXISTS ss.versus_game_team;

CREATE TABLE IF NOT EXISTS ss.versus_game_team
(
    game_id bigint NOT NULL,
    freq smallint NOT NULL,
    is_winner boolean NOT NULL,
    score integer NOT NULL,
    CONSTRAINT versus_game_team_pkey PRIMARY KEY (game_id, freq),
    CONSTRAINT versus_game_team_game_id_fkey FOREIGN KEY (game_id)
        REFERENCES ss.game (game_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT versus_game_team_freq_check CHECK (freq >= 0 AND freq <= 9999)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS ss.versus_game_team
    OWNER to ss_developer;