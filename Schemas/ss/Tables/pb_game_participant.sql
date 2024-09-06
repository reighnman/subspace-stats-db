-- Table: ss.pb_game_participant

-- DROP TABLE IF EXISTS ss.pb_game_participant;

CREATE TABLE IF NOT EXISTS ss.pb_game_participant
(
    game_id bigint NOT NULL,
    freq smallint NOT NULL,
    player_id bigint NOT NULL,
    play_duration interval NOT NULL,
    goals smallint NOT NULL,
    assists smallint NOT NULL,
    kills smallint NOT NULL,
    deaths smallint NOT NULL,
    ball_kills smallint NOT NULL,
    ball_deaths smallint NOT NULL,
    team_kills smallint NOT NULL,
    steals smallint NOT NULL,
    turnovers smallint NOT NULL,
    ball_spawns smallint NOT NULL,
    saves smallint NOT NULL,
    ball_carries smallint NOT NULL,
    rating smallint NOT NULL,
    CONSTRAINT pb_game_participant_pkey PRIMARY KEY (game_id, freq, player_id),
    CONSTRAINT pb_game_participant_game_id_fkey FOREIGN KEY (game_id)
        REFERENCES ss.game (game_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT pb_game_participant_player_id_fkey FOREIGN KEY (player_id)
        REFERENCES ss.player (player_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT pb_game_participant_freq_check CHECK (freq >= 0 AND freq <= 3)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS ss.pb_game_participant
    OWNER to ss_developer;