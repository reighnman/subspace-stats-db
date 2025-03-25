-- This script creates the full set of database objects from scratch.
-- It assumes you've already created the database:
--
--CREATE DATABASE subspacestats
--    WITH
--    OWNER = ss_developer
--    ENCODING = 'UTF8'
--    LOCALE_PROVIDER = 'libc';
--
--ALTER DATABASE subspacestats
--    SET search_path TO ss;
--
-- And that you've connected to the database:
-- \connect subspacestats

-- SCHEMA: migration

-- DROP SCHEMA IF EXISTS migration ;

CREATE SCHEMA IF NOT EXISTS migration
    AUTHORIZATION ss_developer;

-- Table: migration.db_change_log

-- DROP TABLE IF EXISTS migration.db_change_log;

CREATE TABLE IF NOT EXISTS migration.db_change_log
(
    db_change_log_id bigint NOT NULL GENERATED ALWAYS AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 9223372036854775807 CACHE 1 ),
    applied_timestamp timestamp with time zone NOT NULL,
    major integer NOT NULL,
    minor integer NOT NULL,
    patch integer NOT NULL,
    script_file_name character varying COLLATE pg_catalog."default" NOT NULL,
    CONSTRAINT db_change_log_pkey PRIMARY KEY (db_change_log_id),
    CONSTRAINT db_change_log_major_minor_patch_key UNIQUE (major, minor, patch)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS migration.db_change_log
    OWNER to postgres;

-- SCHEMA: ss

-- DROP SCHEMA IF EXISTS ss ;

CREATE SCHEMA IF NOT EXISTS ss
    AUTHORIZATION ss_developer;

GRANT ALL ON SCHEMA ss TO ss_developer;

GRANT USAGE ON SCHEMA ss TO ss_web_server;

GRANT USAGE ON SCHEMA ss TO ss_zone_server;

-- Collation: case_insensitive;

-- DROP COLLATION IF EXISTS ss.case_insensitive;

CREATE COLLATION IF NOT EXISTS ss.case_insensitive (provider = icu, locale = 'und-u-ks-level2', deterministic = false);

ALTER COLLATION ss.case_insensitive
    OWNER TO ss_developer;

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

-- Table: ss.ship_item

-- DROP TABLE IF EXISTS ss.ship_item;

CREATE TABLE IF NOT EXISTS ss.ship_item
(
    ship_item_id smallint NOT NULL,
    ship_item_name character varying(10) COLLATE pg_catalog."default" NOT NULL,
    CONSTRAINT ship_item_pkey PRIMARY KEY (ship_item_id),
    CONSTRAINT ship_item_ship_item_name_key UNIQUE (ship_item_name)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS ss.ship_item
    OWNER to ss_developer;

-- Table: ss.stat_period_type

-- DROP TABLE IF EXISTS ss.stat_period_type;

CREATE TABLE IF NOT EXISTS ss.stat_period_type
(
    stat_period_type_id bigint NOT NULL,
    stat_period_type_name character varying COLLATE pg_catalog."default" NOT NULL,
    CONSTRAINT stat_period_type_pkey PRIMARY KEY (stat_period_type_id),
    CONSTRAINT stat_period_type_stat_period_type_name_key UNIQUE (stat_period_type_name)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS ss.stat_period_type
    OWNER to ss_developer;

-- Table: ss.stat_tracking

-- DROP TABLE IF EXISTS ss.stat_tracking;

CREATE TABLE IF NOT EXISTS ss.stat_tracking
(
    stat_tracking_id bigint NOT NULL,
    game_type_id bigint NOT NULL,
    stat_period_type_id bigint NOT NULL,
    is_auto_generate_period boolean NOT NULL,
    is_rating_enabled boolean NOT NULL,
    initial_rating integer,
    minimum_rating integer,
    CONSTRAINT stat_tracking_pkey PRIMARY KEY (stat_tracking_id),
    CONSTRAINT stat_tracking_game_type_id_stat_period_type_id_key UNIQUE (game_type_id, stat_period_type_id),
    CONSTRAINT stat_tracking_game_type_id_fkey FOREIGN KEY (game_type_id)
        REFERENCES ss.game_type (game_type_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT stat_tracking_stat_period_type_id_fkey FOREIGN KEY (stat_period_type_id)
        REFERENCES ss.stat_period_type (stat_period_type_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS ss.stat_tracking
    OWNER to ss_developer;

-- Table: ss.arena

-- DROP TABLE IF EXISTS ss.arena;

CREATE TABLE IF NOT EXISTS ss.arena
(
    arena_id bigint NOT NULL GENERATED ALWAYS AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 9223372036854775807 CACHE 1 ),
    arena_name character varying(15) COLLATE ss.case_insensitive NOT NULL,
    arena_group character varying(15) COLLATE ss.case_insensitive NOT NULL GENERATED ALWAYS AS (COALESCE(NULLIF(TRIM(TRAILING '0123456789'::text FROM arena_name), ''::text), '(public)'::text)) STORED,
    arena_number integer NOT NULL GENERATED ALWAYS AS ((COALESCE(NULLIF("right"((arena_name)::text, (length((arena_name)::text) - length(TRIM(TRAILING '0123456789'::text FROM arena_name)))), ''::text), '0'::text))::integer) STORED,
    CONSTRAINT arena_pkey PRIMARY KEY (arena_id),
    CONSTRAINT arena_arena_name_key UNIQUE (arena_name)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS ss.arena
    OWNER to ss_developer;

-- Table: ss.lvl

-- DROP TABLE IF EXISTS ss.lvl;

CREATE TABLE IF NOT EXISTS ss.lvl
(
    lvl_id bigint NOT NULL GENERATED ALWAYS AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 9223372036854775807 CACHE 1 ),
    lvl_file_name character varying(16) COLLATE ss.case_insensitive NOT NULL,
    lvl_checksum integer NOT NULL,
    CONSTRAINT lvl_pkey PRIMARY KEY (lvl_id),
    CONSTRAINT lvl_lvl_file_name_lvl_checksum_key UNIQUE (lvl_file_name, lvl_checksum)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS ss.lvl
    OWNER to ss_developer;

-- Table: ss.squad

-- DROP TABLE IF EXISTS ss.squad;

CREATE TABLE IF NOT EXISTS ss.squad
(
    squad_id bigint NOT NULL GENERATED ALWAYS AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 9223372036854775807 CACHE 1 ),
    squad_name character varying(20) COLLATE ss.case_insensitive NOT NULL,
    CONSTRAINT squad_pkey PRIMARY KEY (squad_id),
    CONSTRAINT squad_squad_name_key UNIQUE (squad_name)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS ss.squad
    OWNER to ss_developer;

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
    OWNER to ss_developer;

-- Table: ss.zone_server

-- DROP TABLE IF EXISTS ss.zone_server;

CREATE TABLE IF NOT EXISTS ss.zone_server
(
    zone_server_id bigint NOT NULL GENERATED ALWAYS AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 9223372036854775807 CACHE 1 ),
    zone_server_name character varying COLLATE pg_catalog."default" NOT NULL,
    CONSTRAINT zone_server_pkey PRIMARY KEY (zone_server_id),
    CONSTRAINT zone_server_zone_server_name_key UNIQUE (zone_server_name)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS ss.zone_server
    OWNER to ss_developer;

-- Table: ss.stat_period

-- DROP TABLE IF EXISTS ss.stat_period;

CREATE TABLE IF NOT EXISTS ss.stat_period
(
    stat_period_id bigint NOT NULL GENERATED ALWAYS AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 9223372036854775807 CACHE 1 ),
    stat_tracking_id bigint NOT NULL,
    period_range tstzrange NOT NULL,
    CONSTRAINT stat_period_pkey PRIMARY KEY (stat_period_id),
    CONSTRAINT stat_period_stat_tracking_id_period_range_key UNIQUE (stat_tracking_id, period_range),
    CONSTRAINT stat_period_stat_tracking_id_fkey FOREIGN KEY (stat_tracking_id)
        REFERENCES ss.stat_tracking (stat_tracking_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS ss.stat_period
    OWNER to ss_developer;

-- Table: ss.player_rating

-- DROP TABLE IF EXISTS ss.player_rating;

CREATE TABLE IF NOT EXISTS ss.player_rating
(
    player_id bigint NOT NULL,
    stat_period_id bigint NOT NULL,
    rating integer NOT NULL,
    CONSTRAINT player_rating_pkey PRIMARY KEY (player_id, stat_period_id),
    CONSTRAINT player_rating_player_id_fkey FOREIGN KEY (player_id)
        REFERENCES ss.player (player_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT player_rating_stat_period_id_fkey FOREIGN KEY (stat_period_id)
        REFERENCES ss.stat_period (stat_period_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS ss.player_rating
    OWNER to ss_developer;
-- Index: player_rating_stat_period_id_rating_player_id_idx

-- DROP INDEX IF EXISTS ss.player_rating_stat_period_id_rating_player_id_idx;

CREATE INDEX IF NOT EXISTS player_rating_stat_period_id_rating_player_id_idx
    ON ss.player_rating USING btree
    (stat_period_id ASC NULLS LAST, rating ASC NULLS LAST)
    INCLUDE(player_id)
    WITH (deduplicate_items=True)
    TABLESPACE pg_default;

-- Table: ss.player_ship_usage

-- DROP TABLE IF EXISTS ss.player_ship_usage;

CREATE TABLE IF NOT EXISTS ss.player_ship_usage
(
    player_id bigint NOT NULL,
    stat_period_id bigint NOT NULL,
    warbird_use integer NOT NULL,
    javelin_use integer NOT NULL,
    spider_use integer NOT NULL,
    leviathan_use integer NOT NULL,
    terrier_use integer NOT NULL,
    weasel_use integer NOT NULL,
    lancaster_use integer NOT NULL,
    shark_use integer NOT NULL,
    warbird_duration interval NOT NULL,
    javelin_duration interval NOT NULL,
    spider_duration interval NOT NULL,
    leviathan_duration interval NOT NULL,
    terrier_duration interval NOT NULL,
    weasel_duration interval NOT NULL,
    lancaster_duration interval NOT NULL,
    shark_duration interval NOT NULL,
    CONSTRAINT player_ship_usage_pkey PRIMARY KEY (player_id, stat_period_id),
    CONSTRAINT player_ship_usage_player_id_fkey FOREIGN KEY (player_id)
        REFERENCES ss.player (player_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT player_ship_usage_stat_period_id_fkey FOREIGN KEY (stat_period_id)
        REFERENCES ss.stat_period (stat_period_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS ss.player_ship_usage
    OWNER to ss_developer;

-- Table: ss.player_solo_stats

-- DROP TABLE IF EXISTS ss.player_solo_stats;

CREATE TABLE IF NOT EXISTS ss.player_solo_stats
(
    player_id bigint NOT NULL,
    stat_period_id bigint NOT NULL,
    games_played bigint NOT NULL,
    play_duration interval NOT NULL,
    score bigint NOT NULL,
    wins bigint NOT NULL,
    losses bigint NOT NULL,
    kills bigint NOT NULL,
    deaths bigint NOT NULL,
    gun_damage_dealt bigint NOT NULL,
    bomb_damage_dealt bigint NOT NULL,
    gun_damage_taken bigint NOT NULL,
    bomb_damage_taken bigint NOT NULL,
    self_damage bigint NOT NULL,
    gun_fire_count bigint NOT NULL,
    bomb_fire_count bigint NOT NULL,
    mine_fire_count bigint NOT NULL,
    gun_hit_count bigint NOT NULL,
    bomb_hit_count bigint NOT NULL,
    mine_hit_count bigint NOT NULL,
    CONSTRAINT player_solo_stats_pkey PRIMARY KEY (player_id, stat_period_id),
    CONSTRAINT player_solo_stats_player_id_fkey FOREIGN KEY (player_id)
        REFERENCES ss.player (player_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT player_solo_stats_stat_period_id_fkey FOREIGN KEY (stat_period_id)
        REFERENCES ss.stat_period (stat_period_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS ss.player_solo_stats
    OWNER to ss_developer;
-- Index: player_solo_stats_stat_period_id_player_id_idx

-- DROP INDEX IF EXISTS ss.player_solo_stats_stat_period_id_player_id_idx;

CREATE INDEX IF NOT EXISTS player_solo_stats_stat_period_id_player_id_idx
    ON ss.player_solo_stats USING btree
    (stat_period_id ASC NULLS LAST, player_id ASC NULLS LAST)
    WITH (deduplicate_items=True)
    TABLESPACE pg_default;

-- Table: ss.player_versus_stats

-- DROP TABLE IF EXISTS ss.player_versus_stats;

CREATE TABLE IF NOT EXISTS ss.player_versus_stats
(
    player_id bigint NOT NULL,
    stat_period_id bigint NOT NULL,
    games_played bigint NOT NULL,
    play_duration interval NOT NULL,
    wins bigint NOT NULL,
    losses bigint NOT NULL,
    lag_outs bigint NOT NULL,
    kills bigint NOT NULL,
    deaths bigint NOT NULL,
    knockouts bigint NOT NULL,
    team_kills bigint NOT NULL,
    solo_kills bigint NOT NULL,
    assists bigint NOT NULL,
    forced_reps bigint NOT NULL,
    gun_damage_dealt bigint NOT NULL,
    bomb_damage_dealt bigint NOT NULL,
    team_damage_dealt bigint NOT NULL,
    gun_damage_taken bigint NOT NULL,
    bomb_damage_taken bigint NOT NULL,
    team_damage_taken bigint NOT NULL,
    self_damage bigint NOT NULL,
    kill_damage bigint NOT NULL,
    team_kill_damage bigint NOT NULL,
    forced_rep_damage bigint NOT NULL,
    bullet_fire_count bigint NOT NULL,
    bomb_fire_count bigint NOT NULL,
    mine_fire_count bigint NOT NULL,
    bullet_hit_count bigint NOT NULL,
    bomb_hit_count bigint NOT NULL,
    mine_hit_count bigint NOT NULL,
    first_out_regular bigint NOT NULL,
    first_out_critical bigint NOT NULL,
    wasted_energy bigint NOT NULL,
    wasted_repel bigint NOT NULL,
    wasted_rocket bigint NOT NULL,
    wasted_thor bigint NOT NULL,
    wasted_burst bigint NOT NULL,
    wasted_decoy bigint NOT NULL,
    wasted_portal bigint NOT NULL,
    wasted_brick bigint NOT NULL,
    enemy_distance_sum bigint,
    enemy_distance_samples bigint,
    team_distance_sum bigint,
    team_distance_samples bigint,
    CONSTRAINT player_versus_stats_pkey PRIMARY KEY (player_id, stat_period_id),
    CONSTRAINT player_versus_stats_player_id_fkey FOREIGN KEY (player_id)
        REFERENCES ss.player (player_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT player_versus_stats_stat_period_id_fkey FOREIGN KEY (stat_period_id)
        REFERENCES ss.stat_period (stat_period_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS ss.player_versus_stats
    OWNER to ss_developer;
-- Index: player_versus_stats_stat_period_id_player_id_idx

-- DROP INDEX IF EXISTS ss.player_versus_stats_stat_period_id_player_id_idx;

CREATE INDEX IF NOT EXISTS player_versus_stats_stat_period_id_player_id_idx
    ON ss.player_versus_stats USING btree
    (stat_period_id ASC NULLS LAST, player_id ASC NULLS LAST)
    WITH (deduplicate_items=True)
    TABLESPACE pg_default;

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
    OWNER to ss_developer;
-- Index: game_time_played_game_type_id_game_id_idx

-- DROP INDEX IF EXISTS ss.game_time_played_game_type_id_game_id_idx;

CREATE INDEX IF NOT EXISTS game_time_played_game_type_id_game_id_idx
    ON ss.game USING gist
    (time_played)
    INCLUDE(game_type_id, game_id)
    WITH (buffering=auto)
    TABLESPACE pg_default;

-- Table: ss.game_event

-- DROP TABLE IF EXISTS ss.game_event;

CREATE TABLE IF NOT EXISTS ss.game_event
(
    game_event_id bigint NOT NULL GENERATED BY DEFAULT AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 9223372036854775807 CACHE 1 ),
    game_id bigint NOT NULL,
    event_idx integer NOT NULL,
    game_event_type_id bigint NOT NULL,
    event_timestamp timestamp with time zone NOT NULL,
    CONSTRAINT game_event_pkey PRIMARY KEY (game_event_id),
    CONSTRAINT game_event_game_id_event_idx_key UNIQUE (game_id, event_idx),
    CONSTRAINT game_event_event_type_id_fkey FOREIGN KEY (game_event_type_id)
        REFERENCES ss.game_event_type (game_event_type_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT game_event_game_id_fkey FOREIGN KEY (game_id)
        REFERENCES ss.game (game_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS ss.game_event
    OWNER to ss_developer;

-- Table: ss.game_event_damage

-- DROP TABLE IF EXISTS ss.game_event_damage;

CREATE TABLE IF NOT EXISTS ss.game_event_damage
(
    game_event_id bigint NOT NULL,
    player_id bigint NOT NULL,
    damage smallint NOT NULL,
    CONSTRAINT game_event_damage_pkey PRIMARY KEY (game_event_id, player_id),
    CONSTRAINT game_event_damage_game_event_id_fkey FOREIGN KEY (game_event_id)
        REFERENCES ss.game_event (game_event_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT game_event_damage_player_id_fkey FOREIGN KEY (player_id)
        REFERENCES ss.player (player_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT game_event_damage_damage_check CHECK (damage > 0)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS ss.game_event_damage
    OWNER to ss_developer;

-- Table: ss.game_event_rating

-- DROP TABLE IF EXISTS ss.game_event_rating;

CREATE TABLE IF NOT EXISTS ss.game_event_rating
(
    game_event_id bigint NOT NULL,
    player_id bigint NOT NULL,
    rating real NOT NULL,
    CONSTRAINT game_event_rating_pkey PRIMARY KEY (game_event_id, player_id),
    CONSTRAINT game_event_rating_game_event_id_fkey FOREIGN KEY (game_event_id)
        REFERENCES ss.game_event (game_event_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT game_event_rating_player_id_fkey FOREIGN KEY (player_id)
        REFERENCES ss.player (player_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS ss.game_event_rating
    OWNER to ss_developer;

-- Table: ss.game_ship_change_event

-- DROP TABLE IF EXISTS ss.game_ship_change_event;

CREATE TABLE IF NOT EXISTS ss.game_ship_change_event
(
    game_event_id bigint NOT NULL,
    player_id bigint NOT NULL,
    ship smallint NOT NULL,
    CONSTRAINT game_ship_change_event_pkey PRIMARY KEY (game_event_id),
    CONSTRAINT game_ship_change_event_game_event_id_fkey FOREIGN KEY (game_event_id)
        REFERENCES ss.game_event (game_event_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT game_ship_change_event_player_id_fkey FOREIGN KEY (player_id)
        REFERENCES ss.player (player_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT game_ship_change_event_ship_check CHECK (ship >= 0 AND ship <= 7)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS ss.game_ship_change_event
    OWNER to ss_developer;

-- Table: ss.game_use_item_event

-- DROP TABLE IF EXISTS ss.game_use_item_event;

CREATE TABLE IF NOT EXISTS ss.game_use_item_event
(
    game_event_id bigint NOT NULL,
    player_id bigint NOT NULL,
    ship_item_id smallint NOT NULL,
    CONSTRAINT game_use_item_event_pkey PRIMARY KEY (game_event_id),
    CONSTRAINT game_use_item_event_game_event_id_fkey FOREIGN KEY (game_event_id)
        REFERENCES ss.game_event (game_event_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT game_use_item_event_player_id_fkey FOREIGN KEY (player_id)
        REFERENCES ss.player (player_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT game_use_item_event_ship_item_id_fkey FOREIGN KEY (ship_item_id)
        REFERENCES ss.ship_item (ship_item_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS ss.game_use_item_event
    OWNER to ss_developer;

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
    OWNER to ss_developer;

-- Table: ss.solo_game_participant

-- DROP TABLE IF EXISTS ss.solo_game_participant;

CREATE TABLE IF NOT EXISTS ss.solo_game_participant
(
    game_id bigint NOT NULL,
    player_id bigint NOT NULL,
    play_duration interval NOT NULL,
    ship_mask smallint NOT NULL,
    is_winner boolean NOT NULL,
    score integer NOT NULL,
    kills smallint NOT NULL,
    deaths smallint NOT NULL,
    end_energy smallint,
    gun_damage_dealt integer NOT NULL,
    bomb_damage_dealt integer NOT NULL,
    gun_damage_taken integer NOT NULL,
    bomb_damage_taken integer NOT NULL,
    self_damage integer NOT NULL,
    gun_fire_count integer NOT NULL,
    bomb_fire_count integer NOT NULL,
    mine_fire_count integer NOT NULL,
    gun_hit_count integer NOT NULL,
    bomb_hit_count integer NOT NULL,
    mine_hit_count integer NOT NULL,
    CONSTRAINT solo_game_participant_pkey PRIMARY KEY (game_id, player_id),
    CONSTRAINT solo_game_participant_game_id_fkey FOREIGN KEY (game_id)
        REFERENCES ss.game (game_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT solo_game_participant_player_id_fkey FOREIGN KEY (player_id)
        REFERENCES ss.player (player_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS ss.solo_game_participant
    OWNER to ss_developer;
-- Index: solo_game_participant_player_id_game_id_idx

-- DROP INDEX IF EXISTS ss.solo_game_participant_player_id_game_id_idx;

CREATE INDEX IF NOT EXISTS solo_game_participant_player_id_game_id_idx
    ON ss.solo_game_participant USING btree
    (player_id ASC NULLS LAST, game_id ASC NULLS LAST)
    WITH (deduplicate_items=True)
    TABLESPACE pg_default;

-- Table: ss.versus_game_assign_slot_event

-- DROP TABLE IF EXISTS ss.versus_game_assign_slot_event;

CREATE TABLE IF NOT EXISTS ss.versus_game_assign_slot_event
(
    game_event_id bigint NOT NULL,
    freq smallint NOT NULL,
    slot_idx smallint NOT NULL,
    player_id bigint NOT NULL,
    CONSTRAINT versus_game_assign_slot_event_pkey PRIMARY KEY (game_event_id),
    CONSTRAINT versus_game_assign_slot_event_game_event_id_fkey FOREIGN KEY (game_event_id)
        REFERENCES ss.game_event (game_event_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT versus_game_assign_slot_event_player_id_fkey FOREIGN KEY (player_id)
        REFERENCES ss.player (player_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS ss.versus_game_assign_slot_event
    OWNER to ss_developer;

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
    CONSTRAINT versus_game_kill_event_killed_ship_check CHECK (killed_ship >= 0 AND killed_ship <= 7),
    CONSTRAINT versus_game_kill_event_killer_ship_check CHECK (killer_ship >= 0 AND killer_ship <= 7),
    CONSTRAINT versus_game_kill_event_x_coord_check CHECK (x_coord >= 0 AND x_coord <= 16384),
    CONSTRAINT versus_game_kill_event_y_coord_check CHECK (y_coord >= 0 AND y_coord <= 16384)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS ss.versus_game_kill_event
    OWNER to ss_developer;

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

-- Table: ss.versus_game_team_member

-- DROP TABLE IF EXISTS ss.versus_game_team_member;

CREATE TABLE IF NOT EXISTS ss.versus_game_team_member
(
    game_id bigint NOT NULL,
    freq smallint NOT NULL,
    slot_idx smallint NOT NULL,
    member_idx smallint NOT NULL,
    player_id bigint NOT NULL,
	premade_group smallint,
    play_duration interval NOT NULL,
    ship_mask smallint NOT NULL,
    lag_outs smallint NOT NULL,
    kills smallint NOT NULL,
    deaths smallint NOT NULL,
    knockouts smallint NOT NULL,
    team_kills smallint NOT NULL,
    solo_kills smallint NOT NULL,
    assists smallint NOT NULL,
    forced_reps smallint NOT NULL,
    gun_damage_dealt integer NOT NULL,
    bomb_damage_dealt integer NOT NULL,
    team_damage_dealt integer NOT NULL,
    gun_damage_taken integer NOT NULL,
    bomb_damage_taken integer NOT NULL,
    team_damage_taken integer NOT NULL,
    self_damage integer NOT NULL,
    kill_damage integer NOT NULL,
    team_kill_damage integer NOT NULL,
    forced_rep_damage integer NOT NULL,
    bullet_fire_count integer NOT NULL,
    bomb_fire_count integer NOT NULL,
    mine_fire_count integer NOT NULL,
    bullet_hit_count integer NOT NULL,
    bomb_hit_count integer NOT NULL,
    mine_hit_count integer NOT NULL,
    first_out smallint NOT NULL,
    wasted_energy integer NOT NULL,
    wasted_repel smallint NOT NULL,
    wasted_rocket smallint NOT NULL,
    wasted_thor smallint NOT NULL,
    wasted_burst smallint NOT NULL,
    wasted_decoy smallint NOT NULL,
    wasted_portal smallint NOT NULL,
    wasted_brick smallint NOT NULL,
    rating_change integer NOT NULL,
    enemy_distance_sum bigint,
    enemy_distance_samples integer,
    team_distance_sum bigint,
    team_distance_samples integer,
    CONSTRAINT versus_game_team_member_pkey PRIMARY KEY (game_id, freq, slot_idx, member_idx),
    CONSTRAINT versus_game_team_member_game_id_freq_fkey FOREIGN KEY (game_id, freq)
        REFERENCES ss.versus_game_team (game_id, freq) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT versus_game_team_member_player_id_fkey FOREIGN KEY (player_id)
        REFERENCES ss.player (player_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT versus_game_team_member_ship_mask_check CHECK (ship_mask >= 0 AND ship_mask <= 255)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS ss.versus_game_team_member
    OWNER to ss_developer;
-- Index: versus_game_team_member_player_id_game_id_freq_idx

-- DROP INDEX IF EXISTS ss.versus_game_team_member_player_id_game_id_freq_idx;

CREATE INDEX IF NOT EXISTS versus_game_team_member_player_id_game_id_freq_idx
    ON ss.versus_game_team_member USING btree
    (player_id ASC NULLS LAST)
    INCLUDE(game_id, freq)
    WITH (deduplicate_items=True)
    TABLESPACE pg_default;

-- select * from game_event_type;

merge into game_event_type as et
using(
	values
		 (1, 'Versus - Assign slot')
		,(2, 'Versus - Player kill')
		,(3, 'Versus - Player ship change')
		,(4, 'Versus - Player use item')
		,(100, 'PowerBall - Goal')
		,(101, 'PowerBall - Steal')
		,(102, 'PowerBall - Save')
) as v(game_event_type_id, game_event_type_description)
	on et.game_event_type_id = v.game_event_type_id
when matched then
	update set
		 game_event_type_description = v.game_event_type_description
when not matched then
	insert(
		 game_event_type_id
		,game_event_type_description
	)
	values(
		 v.game_event_type_id
		,v.game_event_type_description
	);

-- select * from game_type;

merge into game_type as gt
using(
	values
		 (1,'SVS - Duel (1v1)',true,false,false)
		,(2,'SVS - 2v2 public', false, true, false)
		,(3,'SVS - 3v3 public', false, true, false)
		,(4,'SVS - 4v4 public', false, true, false)
		,(5,'PowerBall - Traditional', false, false, true)
		,(6,'PowerBall - Proball', false, false, true)
		,(7,'PowerBall - Smallpub', false, false, true)
		,(8,'PowerBall - 3h', false, false, true)
		,(9,'PowerBall - small4tmpb', false, false, true)
		,(10,'PowerBall - minipub', false, false, true)
		,(11,'PowerBall - mediumpub', false, false, true)
		,(12,'SVS - 4v4 league', false, true, false)
		,(13,'SVS - Solo FFA - 1 player/team', true, false, false)
		,(14,'SVS - Team FFA - 2 players/team', false, true, false)
) as v(game_type_id, game_type_description, is_solo, is_team_versus, is_pb)
	on gt.game_type_id = v.game_type_id
when matched then
	update set
		 game_type_description = v.game_type_description
		,is_solo = v.is_solo
		,is_team_versus = v.is_team_versus
		,is_pb = v.is_pb
when not matched then
	insert(
		 game_type_id
		,game_type_description
		,is_solo
		,is_team_versus
		,is_pb
	)
	values(
		 v.game_type_id
		,v.game_type_description
		,v.is_solo
		,v.is_team_versus
		,v.is_pb
	);

-- select * from ss.ship_item

merge into ss.ship_item as se
using(
	values
		 (1, 'Repel')
		,(2, 'Rocket')
		,(3, 'Thor')
		,(4, 'Burst')
		,(5, 'Decoy')
		,(6, 'Portal')
		,(7, 'Brick')
) as v(ship_item_id, ship_item_name)
	on se.ship_item_id = v.ship_item_id
when matched then
	update set
		 ship_item_name = v.ship_item_name
when not matched then
	insert(
		 ship_item_id
		,ship_item_name
	)
	values(
		 v.ship_item_id
		,v.ship_item_name
	);

--select * from stat_period_type;

merge into stat_period_type as rpt
using(
	values
		 (0, 'Forever')
		,(1, 'Monthly')
) as v(stat_period_type_id, stat_period_type_name)
	on rpt.stat_period_type_id = v.stat_period_type_id
when matched then
	update set
		stat_period_type_name = v.stat_period_type_name
when not matched then
	insert(
		 stat_period_type_id
		,stat_period_type_name
	)
	values(
		 v.stat_period_type_id
		,v.stat_period_type_name
	);

--select * from ss.stat_tracking

merge into ss.stat_tracking as st
using(
	select
		 v.stat_tracking_id
		,v.game_type_id
		,v.stat_period_type_id
		,v.is_auto_generate_period
		,v.is_rating_enabled
		,v.initial_rating
		,v.minimum_rating
		,case when exists(
				select *
				from ss.stat_period as sp
				where sp.stat_tracking_id = v.stat_tracking_id
			)
			then true
			else false
		 end as IsInUse
	from(
		values
			 (1, 4, 1, true, true, 500, 100) -- 4v4 Monthly
			,(2, 2, 1, true, true, 500, 100) -- 2v2 Monthly
			,(3, 2, 0, true, false, null, null) -- 2v2 Forever
			,(4, 4, 0, true, false, null, null) -- 4v4 Forever
			,(5, 1, 0, true, false, null, null) -- 1v1 Forever
			,(6, 3, 0, true, false, null, null) -- 3v3 Forever
			,(7, 3, 1, true, true, 500, 100) -- 3v3 Monthly
	) as v(stat_tracking_id, game_type_id, stat_period_type_id, is_auto_generate_period, is_rating_enabled, initial_rating, minimum_rating)
) as dv
	on st.stat_tracking_id = dv.stat_tracking_id
when matched and dv.IsInUse = false then
	update set
		 game_type_id = dv.game_type_id
		,stat_period_type_id = dv.stat_period_type_id
		,is_auto_generate_period = dv.is_auto_generate_period
		,is_rating_enabled = dv.is_rating_enabled
		,initial_rating = dv.initial_rating
		,minimum_rating = dv.minimum_rating
when not matched then
	insert(
		 stat_tracking_id
		,game_type_id
		,stat_period_type_id
		,is_auto_generate_period
		,is_rating_enabled
		,initial_rating
		,minimum_rating
	)
	values(
		 dv.stat_tracking_id
		,dv.game_type_id
		,dv.stat_period_type_id
		,dv.is_auto_generate_period
		,dv.is_rating_enabled
		,dv.initial_rating
		,dv.minimum_rating
	);

create or replace function ss.get_or_insert_arena(
	p_arena_name arena.arena_name%type
)
returns arena.arena_id%type
language plpgsql
as
$$

/*
Usage:
select get_or_insert_arena('turf');
select get_or_insert_arena('TURF2');
select get_or_insert_arena('turf1');
select get_or_insert_arena('turf2');
select get_or_insert_arena('0');
select get_or_insert_arena('1');
select get_or_insert_arena('4v4pub');
select get_or_insert_arena('4v4pub1');
select get_or_insert_arena('4v4pub2');
select get_or_insert_arena('pb');

select * from arena;
*/

declare
	l_arena_id arena.arena_id%type;
begin
	-- no matter what, arena names should always be lowercase
	p_arena_name := lower(p_arena_name);

	select a.arena_id
	into l_arena_id
	from arena as a
	where a.arena_name = p_arena_name;
	
	if l_arena_id is null then
		insert into arena(arena_name)
		values(p_arena_name)
		returning arena_id
		into l_arena_id;
	end if;
	
	return l_arena_id;
end;
$$;

create or replace function ss.get_or_insert_lvl(
	 p_lvl_file_name lvl.lvl_file_name%type
	,p_lvl_checksum lvl.lvl_checksum%type
)
returns lvl.lvl_id%type
language plpgsql
as
$$

/*
Usage:
select get_or_insert_lvl('foo.lvl', 123);
select get_or_insert_lvl('foo.lvl', 1515);
select get_or_insert_lvl('bar.lvl', 61261);

select * from lvl
*/

declare
	l_lvl_id lvl.lvl_id%type;
begin
	select lvl_id
	into l_lvl_id
	from lvl
	where lvl_file_name = p_lvl_file_name
		and lvl_checksum = p_lvl_checksum;
		
	if l_lvl_id is null then
		insert into lvl(
			 lvl_file_name
			,lvl_checksum
		)
		values(
			 p_lvl_file_name
			,p_lvl_checksum
		)
		returning lvl_id
		into l_lvl_id;
	end if;
	
	return l_lvl_id;
end;
$$;

create or replace function ss.get_or_insert_stat_periods(
	 p_game_type_id game_type.game_type_id%type
	,p_as_of timestamptz
)
returns table(
	 stat_period_id stat_period.stat_period_id%type
	,stat_tracking_id stat_tracking.stat_tracking_id%type
)
language sql
as
$$

/*
Gets the stat periods for a given game type and timestamp.
Stat periods that do not exist yet are inserted if it is configured in the stat_tracking table to auto generate.

Parameters:
p_game_type_id - The game type to get stat periods for.
p_as_of - The timestamp to get stat periods for.

Usage:
select * from get_or_insert_stat_periods(4, current_timestamp);

select * from stat_period;
*/

with cte_all_periods as(
	select
		 st.stat_tracking_id
		,st.stat_period_type_id
		,sp.stat_period_id
	from stat_tracking as st
	left outer join stat_period as sp
		on st.stat_tracking_id = sp.stat_tracking_id
			and sp.period_range @> p_as_of
	where st.game_type_id = p_game_type_id
		and (sp.stat_period_id is not null
			or (sp.stat_period_id is null and st.is_auto_generate_period = true)
		)
)
,cte_insert_stat_period as(
	insert into stat_period(
		 stat_tracking_id
		,period_range
	)
	select
		 dt2.stat_tracking_id
		,dt2.period_range
	from(
		select
			 cap.stat_tracking_id
			,case cap.stat_period_type_id
				when 0 then( -- Forever
					select tstzrange(null, null)
				)
				when 1 then( -- Monthly
					select tstzrange(dt.start, dt.start + '1 month'::interval, '[)')
					from(
						select date_trunc('month', p_as_of) as start
					) as dt
				)
			 end as period_range
		from cte_all_periods as cap
		where cap.stat_period_id is null -- any that are null must have is_auto_generate_period = true
	) as dt2
	where dt2.period_range is not null -- only if we know how to generate a new range for the stat_period_type_id
	returning
		 stat_period_id
		,stat_tracking_id
)
select
	 cap.stat_period_id
	,cap.stat_tracking_id
from cte_all_periods as cap
where cap.stat_period_id is not null
union
select
	 cisp.stat_period_id
	,cisp.stat_tracking_id
from cte_insert_stat_period as cisp;

$$;

create or replace function ss.get_or_insert_zone_server(
	p_zone_server_name character varying
)
returns bigint
language plpgsql
as
$$
declare
	l_zone_server_id bigint;
begin
	select zs.zone_server_id
	into l_zone_server_id
	from zone_server as zs
	where zs.zone_server_name = p_zone_server_name;
	
	if l_zone_server_id is null then
		insert into zone_server(zone_server_name)
		values(p_zone_server_name)
		returning zone_server_id
		into l_zone_server_id;
	end if;
	
	return l_zone_server_id;
end;
$$;

create or replace function ss.get_or_upsert_squad(
	p_squad_name squad.squad_name%type
)
returns squad.squad_id%type
language plpgsql
as
$$

/*
select get_or_upsert_squad('foo squad');
select get_or_upsert_squad('foo squad');
select get_or_upsert_squad('FOO squad');
select get_or_upsert_squad('test');
select get_or_upsert_squad('');
select get_or_upsert_squad(' ');
select get_or_upsert_squad(null);

select * from squad;
*/

declare
	l_squad_id squad.squad_id%type;
begin
	p_squad_name := trim(p_squad_name);
	if p_squad_name is null or trim(p_squad_name) = '' then
		return null;
	end if;

	select s.squad_id
	into l_squad_id
	from squad as s
	where s.squad_name = p_squad_name; -- case insensitive
	
	if l_squad_id is null then
		insert into squad(squad_name)
		values(p_squad_name)
		returning squad_id
		into l_squad_id;
	else
		update squad
		set squad_name = p_squad_name
		where squad_id = l_squad_id
			and squad_name collate "default" <> p_squad_name collate "default"; -- case sensitive
	end if;
	
	return l_squad_id;
end;
$$;

create or replace function ss.get_or_upsert_player(
	 p_player_name player.player_name%type
	,p_squad_name squad.squad_name%type
	,p_x_res player.x_res%type
	,p_y_res player.y_res%type
)
returns player.player_id%type
language plpgsql
as
$$

/*
Gets the player_id of a player by name.
If there is no record, INSERT one.

Player names are compared in a case-insensitive manner.
If there is a record, UPDATE the name to match if there is a difference in upper/lower case.
This way, we remember the name in the form it was last used.

Usage:
select get_or_upsert_player('foo', null, 1024::smallint, 768::smallint);
select get_or_upsert_player('foo', 'test', 1024::smallint, 768::smallint);
select get_or_upsert_player('foo', 'the best squad', 1024::smallint, 768::smallint);
select get_or_upsert_player('foo', null, 1920::smallint, 1080::smallint);
select get_or_upsert_player('FOO', null, 1024::smallint, 768::smallint);
select get_or_upsert_player(' ', null, 1024::smallint, 768::smallint);

select * from player;
select * from squad;
*/

declare
	l_player_id player.player_id%type;
	l_squad_id squad.squad_id%type;
begin
	p_player_name := trim(p_player_name);
	if p_player_name is null or p_player_name = '' then
		return null;
	end if;

	l_squad_id := get_or_upsert_squad(p_squad_name);
	
	merge into player as p
	using(
		select
			 p_player_name as player_name
			,l_squad_id as squad_id
			,p_x_res as x_res
			,p_y_res as y_res
	) as t on p.player_name = t.player_name -- case insensitive
	when not matched then
		insert(
			 player_name
			,squad_id
			,x_res
			,y_res
		)
		values(
			 t.player_name
			,t.squad_id
			,t.x_res
			,t.y_res
		)
	when matched 
		and(   p.player_name collate "default" <> t.player_name collate "default" -- case sensitive
			or not(nullif(p.squad_id, t.squad_id) is null and nullif(t.squad_id, p.squad_id) is null)
			or not(nullif(p.x_res, t.x_res) is null and nullif(t.x_res, p.x_res) is null)
			or not(nullif(p.y_res, t.y_res) is null and nullif(t.y_res, p.y_res) is null)
		) 
		then
		update set
			 player_name = t.player_name
			,squad_id = t.squad_id
			,x_res = t.x_res
			,y_res = t.y_res;
		
	select player_id
	into l_player_id
	from player
	where player_name = p_player_name; -- case insensitive

	return l_player_id;
end;
$$;

create or replace function ss.get_game(
	p_game_id game.game_id%type
)
returns json
language sql
security definer
set search_path = ss, pg_temp
as
$$

/*
Gets details about a single game as json.
Note: json is used instead of jsonb since the attribute order matters for deserializing polymorphic types.

Parameters:
p_game_id - Id of the game to get data for.

Usage:
select ss.get_game(155);
*/

select to_json(dt.*)
from(
	select
		 g.game_id
		,g.game_type_id
		,zs.zone_server_name
		,a.arena_name
		,g.box_number
		,lower(g.time_played) as start_time
		,upper(g.time_played) as end_time
		,g.replay_path
		,l.lvl_file_name
		,l.lvl_checksum
		,(	select json_agg(edt.event_json)
		  	from(
				select
					case ge.game_event_type_id
						when 1 then( -- Versus - Assign slot
							select to_json(dt.*)
							from(
								select 
									 ge.game_event_type_id as event_type_id
									,ge.event_timestamp as timestamp
									,ase.freq
									,ase.slot_idx
									,p.player_name as player
								from versus_game_assign_slot_event as ase
								inner join player as p
									on ase.player_id = p.player_id
								where ase.game_event_id = ge.game_event_id
							) as dt
						)
						when 2 then( -- Versus - Player kill
							select to_json(dt.*)
							from(
								select
									 ge.game_event_type_id as event_type_id
									,ge.event_timestamp as timestamp
									,p1.player_name as killed_player
									,p2.player_name as killer_player
									,ke.is_knockout
									,ke.is_team_kill
									,ke.x_coord
									,ke.y_coord
									,ke.killed_ship
									,ke.killer_ship
									,ke.score
									,ke.remaining_slots
									,(	select json_object_agg(p3.player_name, ged.damage)
										from game_event_damage as ged
										inner join player as p3
											on ged.player_id = p3.player_id
										where ged.game_event_id = ge.game_event_id
									 ) as damage_stats
									,(	select json_object_agg(p4.player_name, ger.rating)
										from game_event_rating as ger
										inner join player as p4
											on ger.player_id = p4.player_id
										where ger.game_event_id = ge.game_event_id
									) as rating_changes
								from versus_game_kill_event as ke
								inner join player as p1
									on ke.killed_player_id = p1.player_id
								inner join player as p2
									on ke.killer_player_id = p2.player_id
								where ke.game_event_id = ge.game_event_id
							) as dt
						)
						when 3 then( -- Ship change
							select to_json(dt.*)
							from(
								select
									 ge.game_event_type_id as event_type_id
									,ge.event_timestamp as timestamp
									,p.player_name as player
									,sce.ship
								from game_ship_change_event as sce
								inner join player as p
									on sce.player_id = p.player_id
								where sce.game_event_id = ge.game_event_id
							) as dt
						)
						when 4 then( -- Use item
							select to_json(dt.*)
							from(
								select
									 ge.game_event_type_id as event_type_id
									,ge.event_timestamp as timestamp
									,p.player_name as player
									,uie.ship_item_id
									,(	select json_object_agg(p3.player_name, ged.damage)
										from game_event_damage as ged
										inner join player as p3
											on ged.player_id = p3.player_id
										where ged.game_event_id = ge.game_event_id
									 ) as damage_stats
								from game_use_item_event as uie
								inner join player as p
									on uie.player_id = p.player_id
								where uie.game_event_id = ge.game_event_id
							) as dt
						)
						else null
					end as event_json
				from game_event as ge
				where ge.game_id = g.game_id
				order by ge.event_idx
			) as edt
		 ) as events
		,(	select json_agg(tdt)
		  	from(
				select
					 vgt.freq
					,vgt.is_winner
					,vgt.score
					,(	select json_agg(mdt)
						from(
							select
								 vgtm.slot_idx
								,vgtm.member_idx
								,p.player_name as player
								,s.squad_name as squad
								,vgtm.premade_group
								,vgtm.play_duration
								,vgtm.ship_mask
								,vgtm.lag_outs
								,vgtm.kills
								,vgtm.deaths
								,vgtm.knockouts
								,vgtm.team_kills
								,vgtm.solo_kills
								,vgtm.assists
								,vgtm.forced_reps
								,vgtm.gun_damage_dealt
								,vgtm.bomb_damage_dealt
								,vgtm.team_damage_dealt
								,vgtm.gun_damage_taken
								,vgtm.bomb_damage_taken
								,vgtm.team_damage_taken
								,vgtm.self_damage
								,vgtm.kill_damage
								,vgtm.team_kill_damage
								,vgtm.forced_rep_damage
								,vgtm.bullet_fire_count
								,vgtm.bomb_fire_count
								,vgtm.mine_fire_count
								,vgtm.bullet_hit_count
								,vgtm.bomb_hit_count
								,vgtm.mine_hit_count
								,vgtm.first_out
								,vgtm.wasted_energy
								,vgtm.wasted_repel
								,vgtm.wasted_rocket
								,vgtm.wasted_thor
								,vgtm.wasted_burst
								,vgtm.wasted_decoy
								,vgtm.wasted_portal
								,vgtm.wasted_brick
								,vgtm.rating_change
								,vgtm.enemy_distance_sum
								,vgtm.enemy_distance_samples
								,vgtm.team_distance_sum
								,vgtm.team_distance_samples
							from versus_game_team_member as vgtm
							inner join player as p
								on vgtm.player_id = p.player_id
							left outer join squad as s
								on p.squad_id = s.squad_id
							where vgtm.game_id = vgt.game_id
								and vgtm.freq = vgt.freq
							order by
								 vgtm.slot_idx
								,vgtm.member_idx
						) as mdt
					 ) as members
				from versus_game_team as vgt
				where gt.is_team_versus = true
					and vgt.game_id = g.game_id
				order by vgt.freq
			) as tdt
		 ) as team_stats
	from game as g
	inner join game_type as gt
		on g.game_type_id = gt.game_type_id
	inner join zone_server as zs
		on g.zone_server_id = zs.zone_server_id
	inner join arena as a
		on g.arena_id = a.arena_id
	inner join lvl as l
		on g.lvl_id = l.lvl_id
	where g.game_id = p_game_id
) as dt;

$$;

revoke all on function ss.get_game(
	p_game_id game.game_id%type
) from public;

grant execute on function ss.get_game(
	p_game_id game.game_id%type
) to ss_web_server;

create or replace function ss.get_player_info(
	p_player_name character varying(20)
)
returns table(
	 squad_name squad.squad_name%type
	,x_res player.x_res%type
	,y_res player.y_res%type
)
language sql
security definer
set search_path = ss, pg_temp
as
$$

/*
Gets information about a player.

Parameters:
p_player_name - The name of the player to get data about.

Usage:
select * from get_player_info('foo');
*/

select 
	 s.squad_name
	,p.x_res
	,p.y_res
from player as p
left outer join squad as s
	on p.squad_id = s.squad_id
where p.player_name = p_player_name;

$$;

revoke all on function ss.get_player_info(
	p_player_name character varying(20)
) from public;

grant execute on function ss.get_player_info(
	p_player_name character varying(20)
) to ss_web_server;

create or replace function ss.get_player_participation_overview(
	 p_player_name player.player_name%type
	,p_period_cutoff interval
)
returns table(
	 stat_period_id stat_period.stat_period_id%type
	,game_type_id game_type.game_type_id%type
	,stat_period_type_id stat_period_type.stat_period_type_id%type
	,period_range stat_period.period_range%type
	,rating player_rating.rating%type
	,details_json json
)
language plpgsql
security definer
set search_path = ss, pg_temp
as
$$

/*
Gets a player's recent participation across game types.

Parameters:
p_player_name - The name of the player to get data for.
p_period_cutoff - How far back in time to look for data.

Usage:
select * from get_player_participation_overview('foo', interval '1 year');
*/

declare
	l_start timestamptz;
	l_player_id player.player_id%type;
begin
	l_start := current_timestamp - coalesce(p_period_cutoff, interval '1 year');
	
	select p.player_id
	into l_player_id
	from player as p
	where p.player_name = p_player_name;

	if l_player_id is null then
		raise exception 'Invalid player name specified (%)', p_player_name;
	end if;

	return query
		with cte_stat_periods as( -- TODO: add support for other game types (solo, pb)
			select
				 sp.stat_period_id
				,sp.stat_tracking_id
				,sp.period_range
			from player_versus_stats as pvs
			inner join stat_period as sp
				on pvs.stat_period_id = sp.stat_period_id
			where pvs.player_id = l_player_id
				and lower(sp.period_range) >= l_start
		)
		select
			  dt2.stat_period_id
			 ,st.game_type_id
			 ,st.stat_period_type_id
			 ,sp.period_range
			 ,pr.rating
			 ,case when gt.is_team_versus = true then(
				 	select to_json(dt.*)
				 	from(
						select
							 count(*) as games_played
							,sum(case when vgt.is_winner then 1 else 0 end) as wins
							,sum(
								case when vgt.is_winner = false
									and exists(
										-- another team that won (distinguishes from a draw, no winner)
										select *
										from versus_game_team as vgt2
										where vgt2.game_id = vgt.game_id
											and vgt2.freq <> vgt.freq
											and vgt2.is_winner = true
									)
									then 1
									else 0
								end
							) as losses
						from game as g
						inner join versus_game_team_member as vgtm
							on g.game_id = vgtm.game_id
								and vgtm.player_id = l_player_id
						inner join versus_game_team as vgt
							on g.game_id = vgt.game_id
								and vgtm.freq = vgt.freq
						where sp.period_range @> g.time_played
							and g.game_type_id = st.game_type_id
						group by vgtm.player_id
					) as dt
				)
				when gt.is_solo then(
					select to_json(dt.*)
				 	from(
						select
							 count(*) as games_played
							,sum(case when sgp.is_winner then 1 else 0 end) as wins
						from game as g
						inner join solo_game_participant as sgp
							on g.game_id = sgp.game_id
								and sgp.player_id = l_player_id
						where sp.period_range @> g.time_played
							and g.game_type_id = st.game_type_id
					) as dt
				)
-- 				when gt.is_pb then(
-- 				)
			  end as details_json
		from(
			select
				 dt.stat_tracking_id
				,(	select crp2.stat_period_id
					from cte_stat_periods as crp2
					where crp2.stat_tracking_id = dt.stat_tracking_id
					order by crp2.period_range desc
					limit 1
				 ) as stat_period_id -- the last stat period the player particpated in
			from(
				select csp.stat_tracking_id
				from cte_stat_periods as csp
				group by csp.stat_tracking_id
			) as dt
		) as dt2
		inner join stat_tracking as st
			on dt2.stat_tracking_id = st.stat_tracking_id
		inner join game_type as gt
			on st.game_type_id = gt.game_type_id
		inner join stat_period as sp
			on dt2.stat_period_id = sp.stat_period_id
		left outer join player_rating as pr
			on pr.player_id = l_player_id
				and sp.stat_period_id = pr.stat_period_id
		order by sp.period_range desc;
end;
$$;

revoke all on function ss.get_player_participation_overview(
	 p_player_name player.player_name%type
	,p_period_cutoff interval
) from public;

grant execute on function ss.get_player_participation_overview(
	 p_player_name player.player_name%type
	,p_period_cutoff interval
) to ss_web_server;

create or replace function ss.get_player_rating(
	 p_game_type_id game_type.game_type_id%type
	,p_player_names character varying(20)[]
)
returns table(
	 player_name player.player_name%type
	,rating player_rating.rating%type
)
language sql
security definer
set search_path = ss, pg_temp
as
$$

/*
Gets the rating of a specified list of players for a the latest available stat period of a game type.

Parameters:
p_game_type_id - The type of game to get ratings for.
p_player_names - The names of the players to get data for.

Usage:
select * from ss.get_player_rating(2, '{"foo", "bar", "baz", "asdf"}');

select * from player_rating
*/

select
	 t.player_name
 	,coalesce(pr.rating, dt.initial_rating) as rating
from(
	select
		 sp.stat_period_id
		,st.initial_rating
	from stat_tracking as st
	inner join stat_period as sp
		on st.stat_tracking_id = sp.stat_tracking_id
	where st.game_type_id = p_game_type_id
		and st.is_rating_enabled = true
	order by
		 st.is_auto_generate_period desc
		,sp.period_range desc -- compares by lower bound first, then upper bound
	limit 1
) as dt
cross join unnest(p_player_names) as t(player_name)
left outer join player as p
	on t.player_name = p.player_name
left outer  join player_rating as pr
	on p.player_id = pr.player_id
		and dt.stat_period_id = pr.stat_period_id;

$$;

revoke all on function ss.get_player_rating(
	 p_game_type_id game_type.game_type_id%type
	,p_player_names character varying(20)[]
) from public;

grant execute on function ss.get_player_rating(
	 p_game_type_id game_type.game_type_id%type
	,p_player_names character varying(20)[]
) to ss_zone_server;

create or replace function ss.get_player_stat_periods(
	 p_player_name player.player_name%type
	,p_period_cutoff interval
)
returns table(
	 stat_period_id stat_period.stat_period_id%type
	,game_type_id game_type.game_type_id%type
	,stat_period_type_id stat_period_type.stat_period_type_id%type
	,period_range stat_period.period_range%type
)
language plpgsql
security definer
set search_path = ss, pg_temp
as
$$

/*
Gets the stat periods that a player has participated in.

Parameters:
p_player_name - The name of the player to get data for.
p_period_cutoff - How far back in time to look for periods.

Usage:
select * from get_player_stat_periods('asdf', null);
select * from get_player_stat_periods('asdf', interval '1 months');
*/

declare
	l_start timestamptz;
begin
	l_start := current_timestamp - coalesce(p_period_cutoff, interval '1 year');

	return query
		select
			 sp.stat_period_id
			,st.game_type_id
			,st.stat_period_type_id
			,sp.period_range
		from player as p
		inner join player_versus_stats as pvs -- TODO: add support for other game types (solo, pb)
			on p.player_id = pvs.player_id
		inner join stat_period as sp
			on pvs.stat_period_id = sp.stat_period_id
		inner join stat_tracking as st
			on sp.stat_tracking_id = st.stat_tracking_id
		where p.player_name = p_player_name
			and lower(sp.period_range) >= l_start
			and st.stat_period_type_id <> 0 -- Not the 'Forever' period type
		order by
			 st.game_type_id
			,sp.period_range desc;
end;	
$$;

revoke all on function ss.get_player_stat_periods(
	 p_player_name player.player_name%type
	,p_period_cutoff interval
) from public;

grant execute on function ss.get_player_stat_periods(
	 p_player_name player.player_name%type
	,p_period_cutoff interval
) to ss_web_server;

create or replace function ss.get_player_versus_game_stats(
	 p_player_name character varying(20)
	,p_stat_period_id stat_period.stat_period_id%type
	,p_limit integer
	,p_offset integer
)
returns table(
	 game_id game.game_id%type
	,time_played game.time_played%type
	,score integer[]
	,result integer
	,play_duration versus_game_team_member.play_duration%type
	,ship_mask versus_game_team_member.ship_mask%type
	,lag_outs versus_game_team_member.lag_outs%type
	,kills versus_game_team_member.kills%type
	,deaths versus_game_team_member.deaths%type
	,knockouts versus_game_team_member.knockouts%type
	,team_kills versus_game_team_member.team_kills%type
	,solo_kills versus_game_team_member.solo_kills%type
	,assists versus_game_team_member.assists%type
	,forced_reps versus_game_team_member.forced_reps%type
	,gun_damage_dealt versus_game_team_member.gun_damage_dealt%type
	,bomb_damage_dealt versus_game_team_member.bomb_damage_dealt%type
	,team_damage_dealt versus_game_team_member.team_damage_dealt%type
	,gun_damage_taken versus_game_team_member.gun_damage_taken%type
	,bomb_damage_taken versus_game_team_member.bomb_damage_taken%type
	,team_damage_taken versus_game_team_member.team_damage_taken%type
	,self_damage versus_game_team_member.self_damage%type
	,kill_damage versus_game_team_member.kill_damage%type
	,team_kill_damage versus_game_team_member.team_kill_damage%type
	,forced_rep_damage versus_game_team_member.forced_rep_damage%type
	,bullet_fire_count versus_game_team_member.bullet_fire_count%type
	,bomb_fire_count versus_game_team_member.bomb_fire_count%type
	,mine_fire_count versus_game_team_member.mine_fire_count%type
	,bullet_hit_count versus_game_team_member.bullet_hit_count%type
	,bomb_hit_count versus_game_team_member.bomb_hit_count%type
	,mine_hit_count versus_game_team_member.mine_hit_count%type
	,first_out versus_game_team_member.first_out%type
	,wasted_energy versus_game_team_member.wasted_energy%type
	,wasted_repel versus_game_team_member.wasted_repel%type
	,wasted_rocket versus_game_team_member.wasted_rocket%type
	,wasted_thor versus_game_team_member.wasted_thor%type
	,wasted_burst versus_game_team_member.wasted_burst%type
	,wasted_decoy versus_game_team_member.wasted_decoy%type
	,wasted_portal versus_game_team_member.wasted_portal%type
	,wasted_brick versus_game_team_member.wasted_brick%type
	,rating_change versus_game_team_member.rating_change%type
	,enemy_distance_sum versus_game_team_member.enemy_distance_sum%type
	,enemy_distance_samples versus_game_team_member.enemy_distance_samples%type
	,team_distance_sum versus_game_team_member.team_distance_sum%type
	,team_distance_samples versus_game_team_member.team_distance_samples%type
)
language plpgsql
security definer
set search_path = ss, pg_temp
as
$$

/*
Gets a player's team versus game stats for a specified stat period.

Parameters:
p_player_name - The name of the player to get data for.
p_stat_period_id - The period to get data for.
p_limit - The maximum # of game records to return.
p_offset - The offset of the game records to return.

Usage:
select * from get_player_versus_game_stats('foo', 16, 100, 0);
select * from get_player_versus_game_stats('foo', 16, 2, 2);

select * from stat_period
*/

declare
	l_player_id player.player_id%type;
	l_game_type_id game_type.game_type_id%type;
	l_period_range stat_period.period_range%type;
begin
	select p.player_id
	into l_player_id
	from player as p
	where p.player_name = p_player_name;

	if l_player_id is null then
		raise exception 'Invalid player name specified. (%)', p_player_name;
	end if;

	select
		 st.game_type_id
		,sp.period_range
	into
		 l_game_type_id
		,l_period_range
	from stat_period as sp
	inner join stat_tracking as st
		on sp.stat_tracking_id = st.stat_tracking_id
	inner join game_type as gt
		on st.game_type_id = gt.game_type_id
	where sp.stat_period_id = p_stat_period_id
		and gt.is_team_versus = true;
	
	if l_period_range is null then
		raise exception 'Invalid stat period specified. (%)', p_stat_period_id;
	end if;
	
	return query
		select
			 g.game_id
			,g.time_played
			,array(
				select vgt.score
				from versus_game_team as vgt
				where vgt.game_id = vgtm.game_id
				order by freq
			) as score
			,case when exists(
					select *
					from versus_game_team as vgt
					where vgt.game_id = vgtm.game_id
						and vgt.freq = vgtm.freq
						and vgt.is_winner
				)
				then 1 -- win
				else case when exists(
						select *
						from versus_game_team as vgt
						where vgt.game_id = vgtm.game_id
							and vgt.freq <> vgtm.freq
							and vgt.is_winner
					)
					then -1 -- lose
					else 0 -- draw
				end
			 end as result
			,vgtm.play_duration
			,vgtm.ship_mask
			,vgtm.lag_outs
			,vgtm.kills
			,vgtm.deaths
			,vgtm.knockouts
			,vgtm.team_kills
			,vgtm.solo_kills
			,vgtm.assists
			,vgtm.forced_reps
			,vgtm.gun_damage_dealt
			,vgtm.bomb_damage_dealt
			,vgtm.team_damage_dealt
			,vgtm.gun_damage_taken
			,vgtm.bomb_damage_taken
			,vgtm.team_damage_taken
			,vgtm.self_damage
			,vgtm.kill_damage
			,vgtm.team_kill_damage
			,vgtm.forced_rep_damage
			,vgtm.bullet_fire_count
			,vgtm.bomb_fire_count
			,vgtm.mine_fire_count
			,vgtm.bullet_hit_count
			,vgtm.bomb_hit_count
			,vgtm.mine_hit_count
			,vgtm.first_out
			,vgtm.wasted_energy
			,vgtm.wasted_repel
			,vgtm.wasted_rocket
			,vgtm.wasted_thor
			,vgtm.wasted_burst
			,vgtm.wasted_decoy
			,vgtm.wasted_portal
			,vgtm.wasted_brick
			,vgtm.rating_change
			,vgtm.enemy_distance_sum
			,vgtm.enemy_distance_samples
			,vgtm.team_distance_sum
			,vgtm.team_distance_samples
		from game as g
		inner join versus_game_team_member as vgtm
			on g.game_id = vgtm.game_id
				and player_id = l_player_id
		where g.game_type_id = l_game_type_id
			and l_period_range @> g.time_played
		order by g.time_played desc
		limit p_limit offset p_offset;
end;
$$;

revoke all on function ss.get_player_versus_game_stats(
	 p_player_name character varying(20)
	,p_stat_period_id stat_period.stat_period_id%type
	,p_limit integer
	,p_offset integer
) from public;

grant execute on function ss.get_player_versus_game_stats(
	 p_player_name character varying(20)
	,p_stat_period_id stat_period.stat_period_id%type
	,p_limit integer
	,p_offset integer
) to ss_web_server;

create or replace function ss.get_player_versus_kill_stats(
	 p_player_name player.player_name%type
	,p_stat_period_id stat_period.stat_period_id%type
	,p_limit integer
)
returns table(
	 player_name player.player_name%type
	,kills bigint
	,deaths bigint
)
language plpgsql
security definer
set search_path = ss, pg_temp
as
$$

/*
Gets a player's team versus kill stats for a specified stat period.

Parameters:
p_player_name - The name of the player to get stats for.
p_stat_period_id - Id of the period to get stats for.
p_limit - The maximum # of records to return.

Usage:
select * from get_player_versus_kill_stats('foo', 16, 50);
select * from get_player_versus_kill_stats('bar', 16, 50);
select * from get_player_versus_kill_stats('G', 16, 50);
select * from get_player_versus_kill_stats('asdf', 16, 50);

select * from player;
select * from stat_period;
*/

declare
	l_player_id player.player_id%type;
	l_game_type_id game_type.game_type_id%type;
	l_period_range stat_period.period_range%type;
begin
	select p.player_id
	into l_player_id
	from player as p
	where p.player_name = p_player_name;
	
	if l_player_id is null then
		raise exception 'Invalid player name specified. (%)', p_player_name;
	end if;

	select
		 st.game_type_id
		,sp.period_range
	into
		 l_game_type_id
		,l_period_range
	from stat_period as sp
	inner join stat_tracking as st
		on sp.stat_tracking_id = st.stat_tracking_id
	where sp.stat_period_id = p_stat_period_id;
	
	if l_game_type_id is null or l_period_range is null then
		raise exception 'Invalid stat period specified. (%)', p_stat_period_id;
	end if;

	return query
		with cte_kill_history as (
			select
				 ke.killed_player_id
				,ke.killer_player_id
			from game as g
			inner join game_event as ge
				on g.game_id = ge.game_id
			inner join versus_game_kill_event as ke
				on ge.game_event_id = ke.game_event_id
			where g.game_type_id = l_game_type_id
				and g.time_played && l_period_range
				and ge.game_Event_type_id = 2 -- kill
				and (ke.killed_player_id = l_player_id or ke.killer_player_id = l_player_id)
				and ke.is_team_kill = false
		)
		select
			 p.player_name
			,dt3.kills
			,dt3.deaths
		from(
			select
				 coalesce(dt.player_id, dt2.player_id) as player_id
				,coalesce(dt.kills, 0) as kills
				,coalesce(dt2.deaths, 0) as deaths
			from(
				select
					 killed_player_id as player_id
					,count(*) as kills
				from cte_kill_history as h
				where killed_player_id <> l_player_id
				group by killed_player_id
			) as dt
			full join(
				select
					 killer_player_id as player_id
					,count(*) as deaths
				from cte_kill_history as h
				where killed_player_id = l_player_id
				group by killer_player_id
			) as dt2
				on dt.player_id = dt2.player_id
		) as dt3
		inner join player as p
			on dt3.player_id = p.player_id
		order by 
			 dt3.kills desc
			,dt3.deaths desc
			,p.player_name
		limit p_limit;
end;
$$;

revoke all on function ss.get_player_versus_kill_stats(
	 p_player_name player.player_name%type
	,p_stat_period_id stat_period.stat_period_id%type
	,p_limit integer
) from public;

grant execute on function ss.get_player_versus_kill_stats(
	 p_player_name player.player_name%type
	,p_stat_period_id stat_period.stat_period_id%type
	,p_limit integer
) to ss_web_server;

create or replace function ss.get_player_versus_period_stats(
	 p_player_name character varying(20)
	,p_stat_period_ids bigint[]
)
returns table(
	 stat_period_id stat_period.stat_period_id%type
	,period_rank integer
	,rating player_rating.rating%type
	,games_played player_versus_stats.games_played%type
	,play_duration player_versus_stats.play_duration%type
	,wins player_versus_stats.wins%type
	,losses player_versus_stats.losses%type
	,lag_outs player_versus_stats.lag_outs%type
	,kills player_versus_stats.kills%type
	,deaths player_versus_stats.deaths%type
	,knockouts player_versus_stats.knockouts%type
	,team_kills player_versus_stats.team_kills%type
	,solo_kills player_versus_stats.solo_kills%type
	,assists player_versus_stats.assists%type
	,forced_reps player_versus_stats.forced_reps%type
	,gun_damage_dealt player_versus_stats.gun_damage_dealt%type
	,bomb_damage_dealt player_versus_stats.bomb_damage_dealt%type
	,team_damage_dealt player_versus_stats.team_damage_dealt%type
	,gun_damage_taken player_versus_stats.gun_damage_taken%type
	,bomb_damage_taken player_versus_stats.bomb_damage_taken%type
	,team_damage_taken player_versus_stats.team_damage_taken%type
	,self_damage player_versus_stats.self_damage%type
	,kill_damage player_versus_stats.kill_damage%type
	,team_kill_damage player_versus_stats.team_kill_damage%type
	,forced_rep_damage player_versus_stats.forced_rep_damage%type
	,bullet_fire_count player_versus_stats.bullet_fire_count%type
	,bomb_fire_count player_versus_stats.bomb_fire_count%type
	,mine_fire_count player_versus_stats.mine_fire_count%type
	,bullet_hit_count player_versus_stats.bullet_hit_count%type
	,bomb_hit_count player_versus_stats.bomb_hit_count%type
	,mine_hit_count player_versus_stats.mine_hit_count%type
	,first_out_regular player_versus_stats.first_out_regular%type
	,first_out_critical player_versus_stats.first_out_critical%type
	,wasted_energy player_versus_stats.wasted_energy%type
	,wasted_repel player_versus_stats.wasted_repel%type
	,wasted_rocket player_versus_stats.wasted_rocket%type
	,wasted_thor player_versus_stats.wasted_thor%type
	,wasted_burst player_versus_stats.wasted_burst%type
	,wasted_decoy player_versus_stats.wasted_decoy%type
	,wasted_portal player_versus_stats.wasted_portal%type
	,wasted_brick player_versus_stats.wasted_brick%type
	,enemy_distance_sum player_versus_stats.enemy_distance_sum%type
	,enemy_distance_samples player_versus_stats.enemy_distance_samples%type
	,team_distance_sum player_versus_stats.team_distance_sum%type
	,team_distance_samples player_versus_stats.team_distance_samples%type
)
language sql
security definer
set search_path = ss, pg_temp
as
$$

/*
Gets a player's team versus stats for a specified set of stat periods.

Parameters:
p_player_name - The name of player to get stats for.
p_stat_period_ids - The stat periods to get data for.

Usage:
select * from get_player_versus_period_stats('foo', '{17,3}');
*/

select
	 pvs.stat_period_id
	,(	select dt.rating_rank
		from(
			select
				 dense_rank() over(order by pr.rating desc)::integer as rating_rank
				,pr.player_id
			from player_rating as pr
			where pr.stat_period_id = pvs.stat_period_id
		) as dt
		where dt.player_id = pvs.player_id
	 ) as period_rank
	,pr.rating
	,pvs.games_played
	,pvs.play_duration
	,pvs.wins
	,pvs.losses
	,pvs.lag_outs
	,pvs.kills
	,pvs.deaths
	,pvs.knockouts
	,pvs.team_kills
	,pvs.solo_kills
	,pvs.assists
	,pvs.forced_reps
	,pvs.gun_damage_dealt
	,pvs.bomb_damage_dealt
	,pvs.team_damage_dealt
	,pvs.gun_damage_taken
	,pvs.bomb_damage_taken
	,pvs.team_damage_taken
	,pvs.self_damage
	,pvs.kill_damage
	,pvs.team_kill_damage
	,pvs.forced_rep_damage
	,pvs.bullet_fire_count
	,pvs.bomb_fire_count
	,pvs.mine_fire_count
	,pvs.bullet_hit_count
	,pvs.bomb_hit_count
	,pvs.mine_hit_count
	,pvs.first_out_regular
	,pvs.first_out_critical
	,pvs.wasted_energy
	,pvs.wasted_repel
	,pvs.wasted_rocket
	,pvs.wasted_thor
	,pvs.wasted_burst
	,pvs.wasted_decoy
	,pvs.wasted_portal
	,pvs.wasted_brick
	,pvs.enemy_distance_sum
	,pvs.enemy_distance_samples
	,pvs.team_distance_sum
	,pvs.team_distance_samples
from(
	select p.player_id
	from player as p
	where p.player_name = p_player_name
) as dt
cross join unnest(p_stat_period_ids) with ordinality as pspi(stat_period_id, ordinality)
inner join player_versus_stats as pvs
	on dt.player_id = pvs.player_id
		and pspi.stat_period_id = pvs.stat_period_id
left outer join player_rating as pr -- not all stat periods include rating (e.g. forever)
	on pvs.player_id = pr.player_id
		and pvs.stat_period_id = pr.stat_period_id
order by pspi.ordinality;
		
$$;

revoke all on function ss.get_player_versus_period_stats(
	 p_player_name character varying(20)
	,p_stat_period_ids bigint[]
) from public;

grant execute on function ss.get_player_versus_period_stats(
	 p_player_name character varying(20)
	,p_stat_period_ids bigint[]
) to ss_web_server;

create or replace function ss.get_player_versus_ship_stats(
	 p_player_name player.player_name%type
	,p_stat_period_id stat_period.stat_period_id%type
)
returns table(
	 ship_type smallint
	,game_use_count integer
	,use_duration interval
	,kills bigint
	,deaths bigint
	,knockouts bigint
	,solo_kills bigint
)
language plpgsql
security definer
set search_path = ss, pg_temp
as
$$

/*
Gets a player's versus game ship stats for a specified stat period.

Parameters:
p_player_name - The name of the player to get stats for.
p_stat_period_id - Id of the stat period to get data for.

Usage:
select * from get_player_versus_ship_stats('foo', 16);
select * from get_player_versus_ship_stats('bar', 16);
select * from get_player_versus_ship_stats('bar', 17);
select * from get_player_versus_ship_stats('asdf', 16);
*/

declare
	l_player_id player.player_id%type;
	l_game_type_id game_type.game_type_id%type;
	l_period_range stat_period.period_range%type;
begin
	select p.player_id
	into l_player_id
	from player as p
	where p.player_name = p_player_name;
	
	if l_player_id is null then
		raise exception 'Invalid player name specified. (%)', p_player_name;
	end if;
	
	select
		 st.game_type_id
		,sp.period_range
	into
		 l_game_type_id
		,l_period_range
	from stat_period as sp
	inner join stat_tracking as st
		on sp.stat_tracking_id = st.stat_tracking_id
	where sp.stat_period_id = p_stat_period_id;

	if l_game_type_id is null or l_period_range is null then
		raise exception 'Invalid stat period specified. (%)', p_stat_period_id;
	end if;

	return query
		with cte_kill_history as(
			select
				 ke.game_event_id
				,ke.killed_player_id
				,ke.killer_player_id
				,ke.is_knockout
				,ke.is_team_kill
				,killed_ship
				,killer_ship
			from game as g
			inner join game_event as ge
					on g.game_id = ge.game_id
				inner join versus_game_kill_event as ke
					on ge.game_event_id = ke.game_event_id
			where g.game_type_id = l_game_type_id
				and g.time_played && l_period_range
				and ge.game_Event_type_id = 2 -- kill
				and (ke.killed_player_id = l_player_id or ke.killer_player_id = l_player_id)
		)
		select
			 dt.ship
			,dt.game_use_count
			,dt.use_duration
			,coalesce(dt3.kills, 0) as kills
			,coalesce(dt2.deaths, 0) as deaths
			,coalesce(dt3.knockouts, 0) as knockouts
			,coalesce(dt3.solo_kills, 0) as solo_kills
		from(
			select
				 0::smallint as ship -- warbird
				,u.warbird_use as game_use_count
				,u.warbird_duration as use_duration
			from player_ship_usage as u
			where u.player_id = l_player_id
				and u.stat_period_id = p_stat_period_id
			union
			select
				 1::smallint -- javelin
				,u.javelin_use as game_use_count
				,u.javelin_duration as use_duration
			from player_ship_usage as u
			where u.player_id = l_player_id
				and u.stat_period_id = p_stat_period_id
			union
			select
				 2::smallint -- spider
				,u.spider_use as game_use_count
				,u.spider_duration as use_duration
			from player_ship_usage as u
			where u.player_id = l_player_id
				and u.stat_period_id = p_stat_period_id
			union
			select
				 3::smallint -- leviathan
				,u.leviathan_use as game_use_count
				,u.leviathan_duration as use_duration
			from player_ship_usage as u
			where u.player_id = l_player_id
				and u.stat_period_id = p_stat_period_id
			union
			select
				 4::smallint -- terrier
				,u.terrier_use as game_use_count
				,u.terrier_duration as use_duration
			from player_ship_usage as u
			where u.player_id = l_player_id
				and u.stat_period_id = p_stat_period_id
			union
			select
				 5::smallint -- weasel
				,u.weasel_use as game_use_count
				,u.weasel_duration as use_duration
			from player_ship_usage as u
			where u.player_id = l_player_id
				and u.stat_period_id = p_stat_period_id
			union
			select
				 6::smallint -- lancaster
				,u.lancaster_use as game_use_count
				,u.lancaster_duration as use_duration
			from player_ship_usage as u
			where u.player_id = l_player_id
				and u.stat_period_id = p_stat_period_id
			union
			select
				 7::smallint -- shark
				,u.shark_use as game_use_count
				,u.shark_duration as use_duration
			from player_ship_usage as u
			where u.player_id = l_player_id
				and u.stat_period_id = p_stat_period_id
		) as dt
		left outer join(
			select
				 h.killed_ship as ship
				,count(*) as deaths
			from cte_kill_history as h
			where killed_player_id = l_player_id
				-- purposely including deaths that were team kills
			group by h.killed_ship
		) as dt2
			on dt.ship = dt2.ship
		left outer join(
			select
				 h.killer_ship as ship
				,count(*) as kills
				,sum(case when h.is_knockout = true then 1 else 0 end) as knockouts
				,sum(
					case when exists(
							select * 
							from game_event_damage as d
							where d.game_event_id = h.game_event_id
								and player_id <> l_player_id
						)
						then 0
						else 1
					end
				) as solo_kills
			from cte_kill_history as h
			where h.killer_player_id = l_player_id
				and h.is_team_kill = false -- not including team kills
			group by h.killer_ship
		) as dt3
			on dt.ship = dt3.ship
		order by dt.ship;
end;
$$;

revoke all on function ss.get_player_versus_ship_stats(
	 p_player_name player.player_name%type
	,p_stat_period_id stat_period.stat_period_id%type
) from public;

grant execute on function ss.get_player_versus_ship_stats(
	 p_player_name player.player_name%type
	,p_stat_period_id stat_period.stat_period_id%type
) to ss_web_server;

create or replace function ss.get_stat_periods(
	 p_game_type_id game_type.game_type_id%type
	,p_stat_period_type_id stat_period_type.stat_period_type_id%type
	,p_limit integer
	,p_offset integer
)
returns table(
	 stat_period_id stat_period.stat_period_id%type
	,period_range stat_period.period_range%type
)
language sql
security definer
set search_path = ss, pg_temp
as
$$

/*
Gets the available stats periods for a specified game type and period type.

Parameters:
p_game_type_id - The game type to get stat periods for.
p_stat_period_type_id - The type of stat period to get.
p_limit - The maximum # of stat periods to return.
p_offset - The offset of the stat periods to return.

Usage:
select * from get_stat_periods(2, 1, 12, 0) -- 2v2pub, monthly, limit 12 (1 year), offset 0
select * from get_stat_periods(2, 0, 1, 0) -- 2v2pub, forever, limit 1, offset 0
*/

select
	 sp.stat_period_id
	,sp.period_range
from stat_tracking as st
inner join stat_period as sp
	on st.stat_tracking_id = sp.stat_tracking_id
where st.game_type_id = p_game_type_id
	and st.stat_period_type_id = p_stat_period_type_id
order by sp.period_range desc
limit p_limit offset p_offset;

$$;

revoke all on function ss.get_stat_periods(
	 p_game_type_id game_type.game_type_id%type
	,p_stat_period_type_id stat_period_type.stat_period_type_id%type
	,p_limit integer
	,p_offset integer
) from public;

grant execute on function ss.get_stat_periods(
	 p_game_type_id game_type.game_type_id%type
	,p_stat_period_type_id stat_period_type.stat_period_type_id%type
	,p_limit integer
	,p_offset integer
) to ss_web_server;

create or replace function ss.get_team_versus_leaderboard(
	 p_stat_period_id stat_period.stat_period_id%type
	,p_limit integer
	,p_offset integer
)
returns table(
	 rating_rank bigint
	,player_name player.player_name%type
	,squad_name squad.squad_name%type
	,rating player_rating.rating%type
	,games_played player_versus_stats.games_played%type
	,play_duration player_versus_stats.play_duration%type
	,wins player_versus_stats.wins%type
	,losses player_versus_stats.losses%type
	,kills player_versus_stats.kills%type
	,deaths player_versus_stats.deaths%type
	,damage_dealt bigint
	,damage_taken bigint
	,kill_damage player_versus_stats.kill_damage%type
	,forced_reps player_versus_stats.forced_reps%type
	,forced_rep_damage player_versus_stats.forced_rep_damage%type
	,assists player_versus_stats.assists%type
	,wasted_energy player_versus_stats.wasted_energy%type
	,first_out bigint
)
language sql
security definer
set search_path = ss, pg_temp
as
$$

/*
Gets the leaderboard for a team versus stat period.

Parameters:
p_stat_period_id - Id of the stat period to get the leaderboard for. This identifies both the game type and period range.
p_limit - The maximum # of records to return (for pagination).
p_offset - The offset of the records to return (for pagination).

Usage:
select * from ss.get_team_versus_leaderboard(17, 100, 0); -- 2v2pub, monthly
select * from ss.get_team_versus_leaderboard(17, 2, 2); -- 2v2pub, monthly

select * from player_versus_stats;
select * from stat_period;
select * from stat_tracking;
select * from game_type;
*/

select
	 dense_rank() over(order by pr.rating desc) as rating_rank
	,p.player_name
	,s.squad_name
	,pr.rating
	,pvs.games_played
	,pvs.play_duration
	,pvs.wins
	,pvs.losses
	,pvs.kills
	,pvs.deaths
	,pvs.gun_damage_dealt + pvs.bomb_damage_dealt as damage_dealt
	,pvs.gun_damage_taken + pvs.bomb_damage_taken + pvs.team_damage_taken + pvs.self_damage as damage_taken
	,pvs.kill_damage
	,pvs.forced_reps
	,pvs.forced_rep_damage
	,pvs.assists
	,pvs.wasted_energy
	,pvs.first_out_regular + pvs.first_out_critical as first_out
from player_versus_stats as pvs
inner join player as p
	on pvs.player_id = p.player_id
left outer join squad as s
	on p.squad_id = s.squad_id
left outer join player_rating as pr
	on pvs.player_id = pr.player_id
		and pvs.stat_period_id = pr.stat_period_id
where pvs.stat_period_id = p_stat_period_id
order by
	 pr.rating desc
	,pvs.play_duration desc
	,pvs.games_played desc
	,pvs.wins desc
	,p.player_name
limit p_limit offset p_offset;

$$;

revoke all on function ss.get_team_versus_leaderboard(
	 p_stat_period_id stat_period.stat_period_id%type
	,p_limit integer
	,p_offset integer
) from public;

grant execute on function ss.get_team_versus_leaderboard(
	 p_stat_period_id stat_period.stat_period_id%type
	,p_limit integer
	,p_offset integer
) to ss_web_server;

create or replace function ss.get_top_players_by_rating(
	 p_stat_period_id stat_period.stat_period_id%type
	,p_top integer
)
returns table(
	 top_rank integer
	,player_name player.player_name%type
	,rating player_rating.rating%type
)
language sql
security definer
set search_path = ss, pg_temp
as
$$

/*
Gets the top players by rating for a specified stat period.

Parameters:
p_stat_period_id - Id of the stat period to get data for.
p_top - The rank limit results. 
	E.g. specify 5 to get players with rank [1 - 5].
	This is not the limit of the # of players to return.
	If multiple players share the same rank, they will all be returned.

Usage:
select * from get_top_players_by_rating(16, 5);
*/

select
	 dt.top_rank
	,p.player_name
	,dt.rating
from(
	select
		 dense_rank() over(order by pr.rating desc)::integer as top_rank
		,pr.player_id
		,pr.rating
	from player_rating as pr
	where pr.stat_period_id = p_stat_period_id
) as dt
inner join player as p
	on dt.player_id = p.player_id
where dt.top_rank <= p_top
order by
	 dt.top_rank
	,p.player_name;

$$;

revoke all on function ss.get_top_players_by_rating(
	 p_stat_period_id stat_period.stat_period_id%type
	,p_top integer
) from public;

grant execute on function ss.get_top_players_by_rating(
	 p_stat_period_id stat_period.stat_period_id%type
	,p_top integer
) to ss_web_server;

create or replace function ss.get_top_versus_players_by_avg_rating(
	 p_stat_period_id stat_period.stat_period_id%type
	,p_top integer
	,p_min_games_played integer = 1
)
returns table(
	 top_rank bigint
	,player_name player.player_name%type
	,avg_rating real
)
language plpgsql
security definer
set search_path = ss, pg_temp
as
$$

/*
Gets the top players by average rating for a specified stat period.

Parameters:
p_stat_period_id - Id of the stat period to get data for.
p_top - The rank limit results. 
	E.g. specify 5 to get players with rank [1 - 5].
	This is not the limit of the # of players to return.
	If multiple players share the same rank, they will all be returned.
p_min_games_played - The minimum # of games a player must have played to be included in the result.

Usage:
select * from get_top_versus_players_by_avg_rating(17, 5, 3);
select * from get_top_versus_players_by_avg_rating(17, 5);
*/

declare
	l_initial_rating stat_tracking.initial_rating%type;
begin
	if p_min_games_played < 1 then
		p_min_games_played := 1;
	end if;

	select st.initial_rating
	into l_initial_rating
	from stat_period as sp
	inner join stat_tracking as st
		on sp.stat_tracking_id = st.stat_tracking_id
	where sp.stat_period_id = p_stat_period_id;

	if l_initial_rating is null then
		raise exception 'Invalid stat period specified. (%)', p_stat_period_id;
	end if;

	return query
		select
			 dt2.top_rank
			,p.player_name
			,dt2.avg_rating
		from(
			select
				 dense_rank() over(order by dt.avg_rating desc) as top_rank
				,dt.player_id
				,dt.avg_rating
			from(
				select
					 pr.player_id
					,(pr.rating - l_initial_rating)::real / pvs.games_played::real as avg_rating
				from player_versus_stats as pvs
				left outer join player_rating as pr
					on pvs.player_id = pr.player_id
						and pvs.stat_period_id = pr.stat_period_id
				where pvs.stat_period_id = p_stat_period_id
					and pvs.games_played >= coalesce(p_min_games_played, 1)
			) as dt
		) as dt2
		inner join player as p
			on dt2.player_id = p.player_id
		where dt2.top_rank <= p_top
		order by
			 dt2.top_rank
			,p.player_name;
end;
$$;

revoke all on function ss.get_top_versus_players_by_avg_rating(
	 p_stat_period_id stat_period.stat_period_id%type
	,p_top integer
	,p_min_games_played integer
) from public;

grant execute on function ss.get_top_versus_players_by_avg_rating(
	 p_stat_period_id stat_period.stat_period_id%type
	,p_top integer
	,p_min_games_played integer
) to ss_web_server;

create or replace function ss.get_top_versus_players_by_kills_per_minute(
	 p_stat_period_id stat_period.stat_period_id%type
	,p_top integer
	,p_min_games_played integer = 1
)
returns table(
	 top_rank bigint
	,player_name player.player_name%type
	,kills_per_minute real
)
language sql
security definer
set search_path = ss, pg_temp
as
$$

/*
Gets the top players by kills per minute for a specified stat period.

Parameters:
p_stat_period_id - Id of the stat period to get data for.
p_top - The rank limit results. 
	E.g. specify 5 to get players with rank [1 - 5].
	This is not the limit of the # of players to return.
	If multiple players share the same rank, they will all be returned.
p_min_games_played - The minimum # of games a player must have played to be included in the result.

Usage:
select * from get_top_versus_players_by_kills_per_minute(17, 5, 3);
select * from get_top_versus_players_by_kills_per_minute(17, 5);
*/

select
	 dt2.top_rank
	,p.player_name
	,dt2.kills_per_minute
from(
	select
		 dense_rank() over(order by dt.kills_per_minute desc) as top_rank
		,dt.player_id
		,dt.kills_per_minute
	from(
		select
			 pvs.player_id
			,(pvs.kills::real / (extract(epoch from pvs.play_duration) / 60))::real as kills_per_minute
		from player_versus_stats as pvs
		where pvs.stat_period_id = p_stat_period_id
			and pvs.kills > 0 -- has at least one kill
			and pvs.games_played >= greatest(coalesce(p_min_games_played, 1), 1)
	) as dt
) as dt2
inner join player as p
	on dt2.player_id = p.player_id
where dt2.top_rank <= p_top
order by
	 dt2.top_rank
	,p.player_name;

$$;

revoke all on function ss.get_top_versus_players_by_kills_per_minute(
	 p_stat_period_id stat_period.stat_period_id%type
	,p_top integer
	,p_min_games_played integer
) from public;

grant execute on function ss.get_top_versus_players_by_kills_per_minute(
	 p_stat_period_id stat_period.stat_period_id%type
	,p_top integer
	,p_min_games_played integer
) to ss_web_server;

create or replace function ss.refresh_player_versus_stats(
	p_stat_period_id stat_period.stat_period_id%type
)
returns void
language plpgsql
as
$$

/*
Refreshes the stats of players for a specified team versus stat period from game data.
Through normal operation, the save_game function will automatically record to the player_versus_stats table.
This function can be used to manually refresh the data if needed.
For example, if you were to add a stat period for a period_range that includes past games.
Or, if for some reason you suspect player_versus_stat data is out of sync with game data.

Use this with caution, as it can result in a long running operation.
For example, if you specify a 'forever' period it will need to read every game record 
matching the stat period's game type, which will likely be very large # of records to process.

Parameters:
p_stat_period_id - Id of the stat period to refresh player stat data for.

Usage:
select ss.refresh_player_versus_stats(18);

select * from stat_period;
select * from stat_tracking;
select * from player_rating;
*/

declare
	l_game_type_id game_type.game_type_id%type;
	l_period_range tstzrange;
begin
	select
		 st.game_type_id
		,sp.period_range
	into
		 l_game_type_id
		,l_period_range
	from stat_period as sp
	inner join stat_tracking as st
		on sp.stat_tracking_id = st.stat_tracking_id
	where sp.stat_period_id = p_stat_period_id;
	
	if l_game_type_id is null or l_period_range is null then
		raise exception 'Invalid stat period specified. (%)', p_stat_period_id;
	end if;
	
	delete from player_versus_stats
	where stat_period_id = p_stat_period_id;
	
	insert into player_versus_stats(
		 player_id
		,stat_period_id
		,games_played
		,play_duration
		,wins
		,losses
		,lag_outs
		,kills
		,deaths
		,knockouts
		,team_kills
		,solo_kills
		,assists
		,forced_reps
		,gun_damage_dealt
		,bomb_damage_dealt
		,team_damage_dealt
		,gun_damage_taken
		,bomb_damage_taken
		,team_damage_taken
		,self_damage
		,kill_damage
		,team_kill_damage
		,forced_rep_damage
		,bullet_fire_count
		,bomb_fire_count
		,mine_fire_count
		,bullet_hit_count
		,bomb_hit_count
		,mine_hit_count
		,first_out_regular
		,first_out_critical
		,wasted_energy
		,wasted_repel
		,wasted_rocket
		,wasted_thor
		,wasted_burst
		,wasted_decoy
		,wasted_portal
		,wasted_brick
	)
	select
		 dt.player_id
		,p_stat_period_id
		,count(distinct dt.game_id) as games_played
		,sum(dt.play_duration) as play_duration
		,count(*) filter(where dt.is_winner) as wins
		,count(*) filter(where dt.is_loser) as losses
		,sum(dt.lag_outs) as lag_outs
		,sum(dt.kills) as kills
		,sum(dt.deaths) as deaths
		,sum(dt.knockouts) as knockouts
		,sum(dt.team_kills) as team_kills
		,sum(dt.solo_kills) as solo_kills
		,sum(dt.assists) as assists
		,sum(dt.forced_reps) as forced_reps
		,sum(dt.gun_damage_dealt) as gun_damage_dealt
		,sum(dt.bomb_damage_dealt) as bomb_damage_dealt
		,sum(dt.team_damage_dealt) as team_damage_dealt
		,sum(dt.gun_damage_taken) as gun_damage_taken
		,sum(dt.bomb_damage_taken) as bomb_damage_taken
		,sum(dt.team_damage_taken) as team_damage_taken
		,sum(dt.self_damage) as self_damage
		,sum(dt.kill_damage) as kill_damage
		,sum(dt.team_kill_damage) as team_kill_damage
		,sum(dt.forced_rep_damage) as forced_rep_damage
		,sum(dt.bullet_fire_count) as bullet_fire_count
		,sum(dt.bomb_fire_count) as bomb_fire_count
		,sum(dt.mine_fire_count) as mine_fire_count
		,sum(dt.bullet_hit_count) as bullet_hit_count
		,sum(dt.bomb_hit_count) as bomb_hit_count
		,sum(dt.mine_hit_count) as mine_hit_count
		,count(*) filter(where dt.first_out_regular) as first_out_regular
		,count(*) filter(where dt.first_out_critical) as first_out_critical
		,sum(dt.wasted_energy) as wasted_energy
		,sum(dt.wasted_repel) as wasted_repel
		,sum(dt.wasted_rocket) as wasted_rocket
		,sum(dt.wasted_thor) as wasted_thor
		,sum(dt.wasted_burst) as wasted_burst
		,sum(dt.wasted_decoy) as wasted_decoy
		,sum(dt.wasted_portal) as wasted_portal
		,sum(dt.wasted_brick) as wasted_brick
	from(
		select
			 vgtm.game_id
			,vgtm.player_id
			,vgt.is_winner
			,case when exists(
					select *
					from versus_game_team as vgt2
					where vgt2.game_id = vgtm.game_id
						and vgt2.freq <> vgt.freq
						and vgt2.is_winner = true
				 )
				 then true
				 else false
			 end as is_loser
			,vgtm.play_duration
			,vgtm.lag_outs
			,vgtm.kills
			,vgtm.deaths
			,vgtm.knockouts
			,vgtm.team_kills
			,vgtm.solo_kills
			,vgtm.assists
			,vgtm.forced_reps
			,vgtm.gun_damage_dealt
			,vgtm.bomb_damage_dealt
			,vgtm.team_damage_dealt
			,vgtm.gun_damage_taken
			,vgtm.bomb_damage_taken
			,vgtm.team_damage_taken
			,vgtm.self_damage
			,vgtm.kill_damage
			,vgtm.team_kill_damage
			,vgtm.forced_rep_damage
			,vgtm.bullet_fire_count
			,vgtm.bomb_fire_count
			,vgtm.mine_fire_count
			,vgtm.bullet_hit_count
			,vgtm.bomb_hit_count
			,vgtm.mine_hit_count
			,case when vgtm.first_out = 1 then true else false end as first_out_regular
			,case when vgtm.first_out = 2 then true else false end as first_out_critical
			,vgtm.wasted_energy
			,vgtm.wasted_repel
			,vgtm.wasted_rocket
			,vgtm.wasted_thor
			,vgtm.wasted_burst
			,vgtm.wasted_decoy
			,vgtm.wasted_portal
			,vgtm.wasted_brick
		from game as g	
		inner join versus_game_team_member as vgtm
			on g.game_id = vgtm.game_id
		inner join versus_game_team as vgt
			on vgtm.game_id = vgt.game_id
				and vgtm.freq = vgt.freq
		where g.game_type_id = l_game_type_id
			and l_period_range @> g.time_played
	) as dt
	group by dt.player_id;
end;
$$;

create or replace function ss.save_game(
	game_json jsonb
)
returns game.game_id%type
language sql
security definer
set search_path = ss, pg_temp
as
$$

/*
Saves data for a completed game into the database.

Parameters:
game_json - JSON that represents the game data to save.

	The JSON differs based on game_type:
	- "solo_stats" for solo game modes (e.g. 1v1, 1v1v1, FFA 1 player/team, ...)
	- "team_stats" for team game modes (e.g. 2v2, 3v3, 4v4, 2v2v2, FFA, 2 players/team, ...) where each team has a fixed # of slots
	- "pb_stats" for powerball game modes

	"events" - Array of events, such as a player "kill"

Usage (team versus):
select ss.save_game('
{
	"game_type_id" : "4",
	"zone_server_name" : "Test Server",
	"arena" : "4v4pub",
	"box_number" : 1,
	"lvl_file_name" : "teamversus.lvl",
	"lvl_checksum" : 12345,
	"start_timestamp" : "2023-08-16 12:00",
	"end_timestamp" : "2023-08-16 12:30",
	"replay_path" : null,
	"players" : {
		"foo" : {
			"squad" : "awesome squad",
			"x_res" : 1920,
			"y_res" : 1080
		},
		"bar" : {
			"squad" : "",
			"x_res" : 1024,
			"y_res" : 768
		}
	},
	"team_stats" : [
		{
			"freq" : 100,
			"is_winner" : true,
			"score" : 1,
			"player_slots" : [
				{
					"player_stats" : [
						{
							"player" : "foo",
							"play_duration" : "PT00:15:06.789",
							"lag_outs" : 0,
							"kills" : 0,
							"deaths" : 0,
							"knockouts" : 0,
							"team_kills" : 0,
							"solo_kills" : 0,
							"assists" : 0,
							"forced_reps" : 0,
							"gun_damage_dealt" : 4000,
							"bomb_damage_dealt" : 6000,
							"team_damage_dealt" : 1000,
							"gun_damage_taken" : 3636,
							"bomb_damage_taken" : 7222,
							"team_damage_taken" : 1234,
							"self_damage" : 400,
							"kill_damage" : 1000,
							"team_kill_damage" : 0,
							"forced_rep_damage" : 0,
							"bullet_fire_count" : 100,
							"bomb_fire_count" : 20,
							"mine_fire_count" : 1,
							"bullet_hit_count" : 10,
							"bomb_hit_count" : 10,
							"mine_hit_count" : 0,
							"first_out" : 0,
							"wasted_energy" : 1234,
							"wasted_repel" : 2,
							"wasted_rocket" : 2,
							"wasted_thor" : 0,
							"wasted_burst" : 0,
							"wasted_decoy" : 0,
							"wasted_portal" : 0,
							"wasted_brick" : 0,
							"ship_usage" : {
								"warbird" : "PT00:10:05.789",
								"spider" : "PT00:5:01"
							},
							"rating_change" : -4
						}
					]
				}
			]
		},
		{
			"freq" : 200,
			"is_winner" : false,
			"score" : 0,
			"player_slots" : [
				{
					"player_stats" : [
						{
							"player" : "bar",
							"play_duration" : "PT00:15:06.789",
							"lag_outs" : 0,
							"kills" : 0,
							"deaths" : 0,
							"knockouts" : 1,
							"team_kills" : 0,
							"solo_kills" : 0,
							"assists" : 0,
							"forced_reps" : 0,
							"gun_damage_dealt" : 4000,
							"bomb_damage_dealt" : 6000,
							"team_damage_dealt" : 1000,
							"gun_damage_taken" : 3636,
							"bomb_damage_taken" : 7222,
							"team_damage_taken" : 1234,
							"self_damage" : 400,
							"kill_damage" : 1000,
							"team_kill_damage" : 0,
							"forced_rep_damage" : 0,
							"bullet_fire_count" : 100,
							"bomb_fire_count" : 20,
							"mine_fire_count" : 1,
							"bullet_hit_count" : 10,
							"bomb_hit_count" : 10,
							"mine_hit_count" : 0,
							"first_out" : 3,
							"wasted_energy" : 1212,
							"wasted_repel" : 2,
							"wasted_rocket" : 2,
							"wasted_thor" : 0,
							"wasted_burst" : 0,
							"wasted_decoy" : 0,
							"wasted_portal" : 0,
							"wasted_brick" : 0,
							"ship_usage" : {
								"warbird" : "PT00:15:06.789"
							},
							"rating_change" : 4
						}
					]
				}
			]
		}
	],
	"events" : [
		{
			"event_type_id" : 1,
			"timestamp" : "2023-08-16 12:00",
			"freq" : 100,
			"slot_idx" : 1,
			"player" : "foo"
		},
		{
			"event_type_id" : 1,
			"timestamp" : "2023-08-16 12:00",
			"freq" : 200,
			"slot_idx" : 1,
			"player" : "bar"
		},
		{
			"event_type_id" : 3,
			"timestamp" : "2023-08-16 12:00",
			"player" : "foo",
			"ship" : 0
		},
		{
			"event_type_id" : 3,
			"timestamp" : "2023-08-16 12:00",
			"player" : "bar",
			"ship" : 6
		},
		{
			"event_type_id" : 2,
			"timestamp" : "2023-08-16 12:03",
			"killed_player" : "foo",
			"killer_player" : "bar",
			"is_knockout" : true,
			"is_team_kill" : false,
			"x_coord" : 8192,
			"y_coord": 8192,
			"killed_ship" : 0,
			"killer_ship" : 0,
			"score" : [0, 1],
			"remaining_slots" : [1, 1],
			"damage_stats" : {
				"bar" : 1000
			},
			"rating_changes" : {
				"foo" : -4,
				"bar" : 4
			}
		}
	]
}');

Usage (pb):
select ss.save_game('
{
	"game_type_id" : "10",
	"zone_server_name" : "Test Server",
	"arena" : "0",
	"box_number" : null,
	"lvl_file_name" : "pb.lvl",
	"lvl_checksum" : 12345,
	"start_timestamp" : "2023-08-17 15:04",
	"end_timestamp" : "2023-08-17 15:31",
	"replay_path" : null,
	"players" : {
		"foo" : {
			"squad" : "awesome squad",
			"x_res" : 1920,
			"y_res" : 1080
		},
		"bar" : {
			"squad" : "",
			"x_res" : 1024,
			"y_res" : 768
		},
		"baz" : {
			"squad" : "",
			"x_res" : 640,
			"y_res" : 480
		},
		"asdf" : {
			"squad" : "",
			"x_res" : 2560,
			"y_res" : 1440
		}
	},
	"pb_stats" : [
		{
			"freq" : 0,
			"score" : 6,
			"is_winner" : 1,
			"participants" : [
				{
					"player" : "foo",
					"play_duration" : "PT00:04:21.251",
					"goals" : 2,
					"assists" : 3,
					"kills" : 20,
					"deaths" : 25,
					"ball_kills" : 3,
					"ball_deaths" : 5,
					"team_kills" : 0,
					"steals" : 4,
					"turnovers" : 2,
					"ball_spawns" : 3,
					"saves" : 3,
					"ball_carries" : 35,
					"rating" : 123
				},
				{
					"player" : "baz",
					"play_duration" : "PT00:04:21.251",
					"goals" : 2,
					"assists" : 3,
					"kills" : 20,
					"deaths" : 25,
					"ball_kills" : 3,
					"ball_deaths" : 5,
					"team_kills" : 0,
					"steals" : 4,
					"turnovers" : 2,
					"ball_spawns" : 3,
					"saves" : 3,
					"ball_carries" : 35,
					"rating" : 123
				}
			]
		},
		{
			"freq" : 1,
			"score" : 4,
			"is_winner" : 0,
			"participants" : [
				{
					"player" : "bar",
					"play_duration" : "PT00:04:21.251",
					"goals" : 2,
					"assists" : 3,
					"kills" : 20,
					"deaths" : 25,
					"ball_kills" : 3,
					"ball_deaths" : 5,
					"team_kills" : 0,
					"steals" : 4,
					"turnovers" : 2,
					"ball_spawns" : 3,
					"saves" : 3,
					"ball_carries" : 35,
					"rating" : 123
				},
				{
					"player" : "asdf",
					"play_duration" : "PT00:04:21.251",
					"goals" : 2,
					"assists" : 3,
					"kills" : 20,
					"deaths" : 25,
					"ball_kills" : 3,
					"ball_deaths" : 5,
					"team_kills" : 0,
					"steals" : 4,
					"turnovers" : 2,
					"ball_spawns" : 3,
					"saves" : 3,
					"ball_carries" : 35,
					"rating" : 123
				}
			]
		}
	],
	"events" : [
		{
			"event_type_id" : 4,
			"timestamp" : "2023-08-16 12:01",
			"freq" : 100,
			"player" : "foo",
			"from_player" : "bar"
		},
		{
			"event_type_id" : 5,
			"timestamp" : "2023-08-16 12:04",
			"freq" : 200,
			"player" : "foo",
			"from_player" : "bar"
		},
		{
			"event_type_id" : 3,
			"timestamp" : "2023-08-16 12:05",
			"freq" : 100,
			"player" : "foo",
			"assists" : [ "baz" ]
		}
	]
}');

Usage (solo):
select ss.save_game('
{
	"game_type_id" : "1",
	"zone_server_name" : "Test Server",
	"arena" : "4v4pub",
	"box_number" : 1,
	"lvl_file_name" : "duel.lvl",
	"lvl_checksum" : 12345,
	"start_timestamp" : "2023-08-16 12:00",
	"end_timestamp" : "2023-08-16 12:30",
	"replay_path" : null,
	"players" : {
		"foo" : {
			"squad" : "awesome squad",
			"x_res" : 1920,
			"y_res" : 1080
		},
		"bar" : {
			"squad" : "",
			"x_res" : 1024,
			"y_res" : 768
		}
	},
	"solo_stats" : [
		{
			"player" : "foo",
			"play_duration" : "PT00:15:06.789",
			"ship_usage" : {
				"warbird" : "PT00:10:05.789",
				"spider" : "PT00:5:01"
			},
			"is_winner" : false,
			"score" : 0,
			"kills" : 0,
			"deaths" : 1,
			"end_energy" : 0,
			"gun_damage_dealt" : 1234,
			"bomb_damage_dealt" : 1234,
			"gun_damage_taken" : 1234,
			"bomb_damage_taken" : 1234,
			"self_damage" : 1234,
			"gun_fire_count" : 50,
			"bomb_fire_count" : 10,
			"mine_fire_count" : 1,
			"gun_hit_count" : 12,
			"bomb_hit_count" : 5,
			"mine_hit_count" : 1
		},
		{
			"player" : "bar",
			"play_duration" : "PT00:15:06.789",
			"ship_usage" : {
				"warbird" : "PT00:10:05.789"
			},
			"is_winner" : true,
			"score" : 1,
			"kills" : 1,
			"deaths" : 0,
			"end_energy" : 622,
			"gun_damage_dealt" : 1234,
			"bomb_damage_dealt" : 1234,
			"gun_damage_taken" : 1234,
			"bomb_damage_taken" : 1234,
			"self_damage" : 1234,
			"gun_fire_count" : 50,
			"bomb_fire_count" : 10,
			"mine_fire_count" : 1,
			"gun_hit_count" : 12,
			"bomb_hit_count" : 5,
			"mine_hit_count" : 1
		}
	],
	"events" : null
}');
*/

with cte_data as(
	select
		 gr.game_type_id
		,get_or_insert_zone_server(gr.zone_server_name) as zone_server_id
		,get_or_insert_arena(gr.arena) as arena_id
		,gr.box_number
		,get_or_insert_lvl(gr.lvl_file_name, gr.lvl_checksum) as lvl_id
		,tstzrange(gr.start_timestamp, gr.end_timestamp, '[)') as time_played
		,gr.replay_path
		,gr.players
		,gr.solo_stats
		,gr.team_stats
		,gr.pb_stats
		,gr.events
	from jsonb_to_record(game_json) as gr(
		 game_type_id bigint
		,zone_server_name character varying
		,arena character varying
		,box_number int
		,lvl_file_name character varying(16)
		,lvl_checksum integer
		,start_timestamp timestamp
		,end_timestamp timestamp
		,replay_path character varying
		,players jsonb
		,solo_stats jsonb
		,team_stats jsonb
		,pb_stats jsonb
		,events jsonb
	)		
)
,cte_player as(	
	select
		 get_or_upsert_player(pe.key, pi.squad, pi.x_res, pi.y_res) as player_id
		,pe.key as player_name
	from cte_data as cd
	cross join jsonb_each(cd.players) as pe
	cross join jsonb_to_record(pe.value) as pi(
		 squad character varying(20)
		,x_res smallint
		,y_res smallint
	)
)
,cte_game as(
	insert into game(
		 game_type_id
		,zone_server_id
		,arena_id
		,box_number
		,time_played
		,replay_path
		,lvl_id
	)
	select
		 game_type_id
		,zone_server_id
		,arena_id
		,box_number
		,time_played
		,replay_path
		,lvl_id
	from cte_data
	returning game.game_id
)
,cte_solo_stats as(
	select
		 par.player as player_name
		,s.value as participant_json
	from cte_data as cd
	inner join game_type as gt
		on cd.game_type_id = gt.game_type_id
	cross join jsonb_array_elements(cd.solo_stats) as s
	cross join jsonb_to_record(s.value) as par(
		player character varying
	)
	where gt.is_solo = true
)
,cte_team_stats as(
	select
		 t.freq
		,t.is_winner
		,t.score
		,t.player_slots
	from cte_data as cd
	inner join game_type as gt
		on cd.game_type_id = gt.game_type_id
	cross join jsonb_array_elements(cd.team_stats) as j
	cross join jsonb_to_record(j.value) as t(
		 freq smallint
		,is_winner boolean
		,score integer
		,player_slots jsonb
	)
	where gt.is_team_versus = true
)
,cte_versus_team as(
	insert into versus_game_team(
		 game_id
		,freq
		,is_winner
		,score
	)
	select
		 (select g.game_id from cte_game as g) as game_id
		,ct.freq
		,ct.is_winner
		,ct.score
	from cte_team_stats as ct
	returning
		 freq
		,is_winner
)
,cte_team_members as(
	select
		 ct.freq
		,s.ordinality as slot_idx
		,tm.ordinality as member_idx
		,m.player as player_name
		,tm.value as team_member_json
	from cte_team_stats as ct
	cross join jsonb_array_elements(ct.player_slots) with ordinality as s
	cross join jsonb_array_elements(s.value->'player_stats') with ordinality as tm
	cross join jsonb_to_record(tm.value) as m(
		 player character varying(20)
	)
)
,cte_pb_teams as(
	select
		 t.freq
		,s.value as team_json
	from cte_data as cd
	inner join game_type as gt
		on cd.game_type_id = gt.game_type_id
	cross join jsonb_array_elements(cd.pb_stats) as s
	cross join jsonb_to_record(s.value) as t(
		 freq smallint
	)
	where gt.is_pb = true
)
,cte_pb_participants as(
	select
		 ct.freq
		,par.player as player_name
		,ap.value as participant_json
	from cte_pb_teams as ct
	cross join jsonb_array_elements(ct.team_json->'participants') as ap
	cross join jsonb_to_record(ap.value) as par(
		 player character varying(20)
	)
)
,cte_solo_game_participant as(
	insert into solo_game_participant(
		 game_id
		,player_id
		,play_duration
		,ship_mask
		,is_winner
		,score
		,kills
		,deaths
		,end_energy
		,gun_damage_dealt
		,bomb_damage_dealt
		,gun_damage_taken
		,bomb_damage_taken
		,self_damage
		,gun_fire_count
		,bomb_fire_count
		,mine_fire_count
		,gun_hit_count
		,bomb_hit_count
		,mine_hit_count
	)
	select
		 (select g.game_id from cte_game as g) as game_id
		,p.player_id
		,par.play_duration
		,cast(( 
			  case when su.warbird > cast('0' as interval) then 1 else 0 end
			| case when su.javelin > cast('0' as interval) then 2 else 0 end
			| case when su.spider > cast('0' as interval) then 4 else 0 end
			| case when su.leviathan > cast('0' as interval) then 8 else 0 end
			| case when su.terrier > cast('0' as interval) then 16 else 0 end
			| case when su.weasel > cast('0' as interval) then 32 else 0 end
			| case when su.lancaster > cast('0' as interval) then 64 else 0 end
			| case when su.shark > cast('0' as interval) then 128 else 0 end) as smallint
		 ) as ship_mask
		,par.is_winner
		,par.score
		,par.kills
		,par.deaths
		,par.end_energy
		,par.gun_damage_dealt
		,par.bomb_damage_dealt
		,par.gun_damage_taken
		,par.bomb_damage_taken
		,par.self_damage
		,par.gun_fire_count
		,par.bomb_fire_count
		,par.mine_fire_count
		,par.gun_hit_count
		,par.bomb_hit_count
		,par.mine_hit_count
	from cte_solo_stats as cs
	inner join cte_player as p
		on cs.player_name = p.player_name
	cross join jsonb_to_record(cs.participant_json) as par(
		 play_duration interval
		,ship_mask smallint
		,is_winner boolean
		,score integer
		,kills smallint
		,deaths smallint
		,end_energy smallint
		,gun_damage_dealt integer
		,bomb_damage_dealt integer
		,gun_damage_taken integer
		,bomb_damage_taken integer
		,self_damage integer
		,gun_fire_count integer
		,bomb_fire_count integer
		,mine_fire_count integer
		,gun_hit_count integer
		,bomb_hit_count integer
		,mine_hit_count integer
	)
	cross join jsonb_to_record(cs.participant_json->'ship_usage') as su(
		 warbird interval
		,javelin interval
		,spider interval
		,leviathan interval
		,terrier interval
		,weasel interval
		,lancaster interval
		,shark interval
	)
	returning
		 player_id
		,play_duration
		,ship_mask
		,is_winner
		,score
		,kills
		,deaths
		,end_energy
		,gun_damage_dealt
		,bomb_damage_dealt
		,gun_damage_taken
		,bomb_damage_taken
		,self_damage
		,gun_fire_count
		,bomb_fire_count
		,mine_fire_count
		,gun_hit_count
		,bomb_hit_count
		,mine_hit_count
)
,cte_pb_game_participant as(
	insert into pb_game_participant(
		 game_id
		,freq
		,player_id
		,play_duration
		,goals
		,assists
		,kills
		,deaths
		,ball_kills
		,ball_deaths
		,team_kills
		,steals
		,turnovers
		,ball_spawns
		,saves
		,ball_carries
		,rating
	)
	select
		 (select g.game_id from cte_game as g) as game_id
		,cp.freq
		,p.player_id
		,par.play_duration
		,par.goals
		,par.assists
		,par.kills
		,par.deaths
		,par.ball_kills
		,par.ball_deaths
		,par.team_kills
		,par.steals
		,par.turnovers
		,par.ball_spawns
		,par.saves
		,par.ball_carries
		,par.rating
	from cte_pb_participants as cp
	inner join cte_player as p
		on cp.player_name = p.player_name
	cross join jsonb_to_record(cp.participant_json) as par(
		 play_duration interval
		,goals smallint
		,assists smallint
		,kills smallint
		,deaths smallint
		,ball_kills smallint
		,ball_deaths smallint
		,team_kills smallint
		,steals smallint
		,turnovers smallint
		,ball_spawns smallint
		,saves smallint
		,ball_carries smallint
		,rating smallint
	)
)
,cte_pb_game_score as(
	insert into pb_game_score(
		 game_id
		,freq
		,score
		,is_winner
	)
	select
		 (select g.game_id from cte_game as g) as game_id
		,ct.freq
		,t.score
		,t.is_winner
	from cte_pb_teams as ct
	cross join jsonb_to_record(ct.team_json) as t(
		 score smallint
		,is_winner boolean
	)
)
,cte_player_ship_usage_data as(
	select
		 dt.player_id
		,(select game_type_id from cte_data) as game_type_id
		,sum(dt.warbird) as warbird_duration
		,sum(dt.javelin) as javelin_duration
		,sum(dt.spider) as spider_duration
		,sum(dt.leviathan) as leviathan_duration
		,sum(dt.terrier) as terrier_duration
		,sum(dt.weasel) as weasel_duration
		,sum(dt.lancaster) as lancaster_duration
		,sum(dt.shark) as shark_duration
	from(
		-- ship usage from solo stats
		select
			 p.player_id
			,su.warbird
			,su.javelin
			,su.spider
			,su.leviathan
			,su.terrier
			,su.weasel
			,su.lancaster
			,su.shark
		from cte_solo_stats as cs
		inner join cte_player as p
			on cs.player_name = p.player_name
		cross join jsonb_to_record(cs.participant_json->'ship_usage') as su(
			 warbird interval
			,javelin interval
			,spider interval
			,leviathan interval
			,terrier interval
			,weasel interval
			,lancaster interval
			,shark interval
		)
		union all
		-- ships usage from team stats
		select
			 p.player_id
			,su.warbird
			,su.javelin
			,su.spider
			,su.leviathan
			,su.terrier
			,su.weasel
			,su.lancaster
			,su.shark
		from cte_team_members as tm
		inner join cte_player as p
			on tm.player_name = p.player_name
		cross join jsonb_to_record(tm.team_member_json->'ship_usage') as su(
			 warbird interval
			,javelin interval
			,spider interval
			,leviathan interval
			,terrier interval
			,weasel interval
			,lancaster interval
			,shark interval
		)
	) as dt
	group by dt.player_id
)
,cte_versus_team_member as(
	insert into versus_game_team_member(
		 game_id
		,freq
		,slot_idx
		,member_idx
		,player_id
		,premade_group
		,play_duration
		,ship_mask
		,lag_outs
		,kills
		,deaths
		,knockouts
		,team_kills
		,solo_kills
		,assists
		,forced_reps
		,gun_damage_dealt
		,bomb_damage_dealt
		,team_damage_dealt
		,gun_damage_taken
		,bomb_damage_taken
		,team_damage_taken
		,self_damage
		,kill_damage
		,team_kill_damage
		,forced_rep_damage
		,bullet_fire_count
		,bomb_fire_count
		,mine_fire_count
		,bullet_hit_count
		,bomb_hit_count
		,mine_hit_count
		,first_out
		,wasted_energy
		,wasted_repel
		,wasted_rocket
		,wasted_thor
		,wasted_burst
		,wasted_decoy
		,wasted_portal
		,wasted_brick
		,rating_change
		,enemy_distance_sum
		,enemy_distance_samples
		,team_distance_sum
		,team_distance_samples
	)
	select
		 (select g.game_id from cte_game as g) as game_id
		,ctm.freq
		,ctm.slot_idx
		,ctm.member_idx
		,p.player_id
		,premade_group
		,m.play_duration
		,cast(( 
			  case when su.warbird > cast('0' as interval) then 1 else 0 end
			| case when su.javelin > cast('0' as interval) then 2 else 0 end
			| case when su.spider > cast('0' as interval) then 4 else 0 end
			| case when su.leviathan > cast('0' as interval) then 8 else 0 end
			| case when su.terrier > cast('0' as interval) then 16 else 0 end
			| case when su.weasel > cast('0' as interval) then 32 else 0 end
			| case when su.lancaster > cast('0' as interval) then 64 else 0 end
			| case when su.shark > cast('0' as interval) then 128 else 0 end) as smallint
		 ) as ship_mask
		,m.lag_outs
		,m.kills
		,m.deaths
		,m.knockouts
		,m.team_kills
		,m.solo_kills
		,m.assists
		,m.forced_reps
		,m.gun_damage_dealt
		,m.bomb_damage_dealt
		,m.team_damage_dealt
		,m.gun_damage_taken
		,m.bomb_damage_taken
		,m.team_damage_taken
		,m.self_damage
		,m.kill_damage
		,m.team_kill_damage
		,m.forced_rep_damage
		,m.bullet_fire_count
		,m.bomb_fire_count
		,m.mine_fire_count
		,m.bullet_hit_count
		,m.bomb_hit_count
		,m.mine_hit_count
		,coalesce(m.first_out, 0)
		,m.wasted_energy
		,coalesce(m.wasted_repel, 0)
		,coalesce(m.wasted_rocket, 0)
		,coalesce(m.wasted_thor, 0)
		,coalesce(m.wasted_burst, 0)
		,coalesce(m.wasted_decoy, 0)
		,coalesce(m.wasted_portal, 0)
		,coalesce(m.wasted_brick, 0)
		,m.rating_change
		,m.enemy_distance_sum
		,m.enemy_distance_samples
		,m.team_distance_sum
		,m.team_distance_samples
	from cte_team_members as ctm
	cross join jsonb_to_record(ctm.team_member_json) as m(
		 premade_group smallint
		,play_duration interval
		,lag_outs smallint
		,kills smallint
		,deaths smallint
		,knockouts smallint
		,team_kills smallint
		,solo_kills smallint
		,assists smallint
		,forced_reps smallint
		,gun_damage_dealt integer
		,bomb_damage_dealt integer
		,team_damage_dealt integer
		,gun_damage_taken integer
		,bomb_damage_taken integer
		,team_damage_taken integer
		,self_damage integer
		,kill_damage integer
		,team_kill_damage integer
		,forced_rep_damage integer
		,bullet_fire_count integer
		,bomb_fire_count integer
		,mine_fire_count integer
		,bullet_hit_count integer
		,bomb_hit_count integer
		,mine_hit_count integer
		,first_out smallint
		,wasted_energy integer
		,wasted_repel smallint
		,wasted_rocket smallint
		,wasted_thor smallint
		,wasted_burst smallint
		,wasted_decoy smallint
		,wasted_portal smallint
		,wasted_brick smallint
		,rating_change integer
		,enemy_distance_sum bigint
		,enemy_distance_samples int
		,team_distance_sum bigint
		,team_distance_samples int
	)
	cross join jsonb_to_record(ctm.team_member_json->'ship_usage') as su(
		 warbird interval
		,javelin interval
		,spider interval
		,leviathan interval
		,terrier interval
		,weasel interval
		,lancaster interval
		,shark interval
	)
	inner join cte_player as p
		on ctm.player_name = p.player_name
	returning
		 freq
		,player_id
		,play_duration
		,lag_outs
		,kills
		,deaths
		,knockouts
		,team_kills
		,solo_kills
		,assists
		,forced_reps
		,gun_damage_dealt
		,bomb_damage_dealt
		,team_damage_dealt
		,gun_damage_taken
		,bomb_damage_taken
		,team_damage_taken
		,self_damage
		,kill_damage
		,team_kill_damage
		,forced_rep_damage
		,bullet_fire_count
		,bomb_fire_count
		,mine_fire_count
		,bullet_hit_count
		,bomb_hit_count
		,mine_hit_count
		,first_out
		,wasted_energy
		,wasted_repel
		,wasted_rocket
		,wasted_thor
		,wasted_burst
		,wasted_decoy
		,wasted_portal
		,wasted_brick
		,rating_change
		,enemy_distance_sum
		,enemy_distance_samples
		,team_distance_sum
		,team_distance_samples
)
,cte_events as(
	select
		 nextval('game_event_game_event_id_seq') as game_event_id
		,je.ordinality as event_idx
		,je.value as event_json
	from cte_data as cd
	cross join jsonb_array_elements(cd.events) with ordinality je
)
,cte_game_event as(
	insert into game_event(
		 game_event_id
		,game_id
		,event_idx
		,game_event_type_id
		,event_timestamp
	)
	select
		 ce.game_event_id
		,(select g.game_id from cte_game as g) as game_id
		,ce.event_idx
		,e.event_type_id
		,e.timestamp
	from cte_events as ce
	cross join jsonb_to_record(ce.event_json) as e(
		 event_type_id bigint
		,timestamp timestamp
	)
	returning
		 game_event.game_event_id
		,game_event.game_event_type_id
)
,cte_versus_game_assign_slot_event as(
	insert into versus_game_assign_slot_event(
		 game_event_id
		,freq
		,slot_idx
		,player_id
	)
	select
		 ce.game_event_id
		,e.freq
		,e.slot_idx
		,p.player_id
	from cte_game_event as cme -- to ensure the game_event record was written before the current cte
	inner join cte_events as ce
		on cme.game_event_id = ce.game_event_id
	cross join jsonb_to_record(ce.event_json) as e(
		 freq smallint
		,slot_idx smallint
		,player character varying(20)
	)
	inner join cte_player as p
		on e.player = p.player_name
	where cme.game_event_type_id = 1 -- Assign Slot
)
,cte_versus_game_kill_event as(
	insert into versus_game_kill_event(
		 game_event_id
		,killed_player_id
		,killer_player_id
		,is_knockout
		,is_team_kill
		,x_coord
		,y_coord
		,killed_ship
		,killer_ship
		,score
		,remaining_slots
	)
	select
		 ce.game_event_id
		,cp1.player_id
		,cp2.player_id
		,e.is_knockout
		,e.is_team_kill
		,e.x_coord
		,e.y_coord
		,e.killed_ship
		,e.killer_ship
		,e.score
		,e.remaining_slots
	from cte_game_event as cme -- to ensure the game_event record was written before the current cte
	inner join cte_events as ce
		on cme.game_event_id = ce.game_event_id
	cross join jsonb_to_record(ce.event_json) as e(
		 killed_player character varying(20)
		,killer_player character varying(20)
		,is_knockout boolean
		,is_team_kill boolean
		,x_coord smallint
		,y_coord smallint
		,killed_ship smallint
		,killer_ship smallint
		,score integer[]
		,remaining_slots integer[]
	)
	inner join cte_player as cp1
		on e.killed_player = cp1.player_name
	inner join cte_player as cp2
		on e.killer_player = cp2.player_name
	where cme.game_event_type_id = 2 -- Kill
)
,cte_game_event_damage as(
	insert into game_event_damage(
		 game_event_id
		,player_id
		,damage
	)
	select
		 cme.game_event_id
		,p.player_id
		,ds.value::integer as damage
	from cte_game_event as cme -- to ensure the game_event record was written before the current cte
	inner join cte_events as ce
		on cme.game_event_id = ce.game_event_id
	cross join jsonb_each(ce.event_json->'damage_stats') as ds
	inner join cte_player as p
		on ds.key = p.player_name
)
,cte_game_ship_change_event as(
	insert into game_ship_change_event(
		 game_event_id
		,player_id
		,ship
	)
	select
		 cge.game_event_id
		,p.player_id
		,sc.ship
	from cte_game_event as cge -- to ensure the game_event record was written before the current cte
	inner join cte_events as ce
		on cge.game_event_id = ce.game_event_id
	cross join jsonb_to_record(ce.event_json) as sc(
		 player character varying(20)
		,ship smallint
	)
	inner join cte_player as p
		on sc.player = p.player_name
	where cge.game_event_type_id = 3 -- ship change
)
,cte_game_use_item_event as(
	insert into game_use_item_event(
		 game_event_id
		,player_id
		,ship_item_id
	)
	select
		 cge.game_event_id
		,p.player_id
		,uie.ship_item_id
	from cte_game_event as cge
	inner join cte_events as ce
		on cge.game_event_id = ce.game_event_id
	cross join jsonb_to_record(ce.event_json) as uie(
		 player character varying(20)
		,ship_item_id smallint
	)
	inner join cte_player as p
		on uie.player = p.player_name
	where cge.game_event_type_id = 4 -- use item

)
,cte_game_event_rating as(
	insert into game_event_rating(
		 game_event_id
		,player_id
		,rating
	)
	select
		 ce.game_event_id
		,cp.player_id
		,r.value::real as rating
	from cte_game_event as cme -- to ensure the game_event record was written before the current cte
	inner join cte_events as ce
		on cme.game_event_id = ce.game_event_id
	cross join jsonb_each(ce.event_json->'rating_changes') as r
	inner join cte_player as cp
		on r.key = cp.player_name
)
,cte_stat_periods as(
	select
		 sp.stat_period_id
		,st.initial_rating
		,st.minimum_rating
		,st.is_rating_enabled
	from cte_data as cd
	cross join get_or_insert_stat_periods(cd.game_type_id, lower(cd.time_played)) as sp
	inner join stat_tracking as st
		on sp.stat_tracking_id = st.stat_tracking_id
)
,cte_player_solo_stats as(
	select
		 csgp.player_id
		,csp.stat_period_id
		,csgp.play_duration
		,csgp.is_winner
		,case when csgp.is_winner is false
			and exists( -- Another player is the winner
				select *
				from cte_solo_game_participant csgp2
				where csgp2.player_id <> csgp.player_id
					and csgp2.is_winner = true
			)
			then true
			else false
		 end is_loser
		,csgp.score
		,csgp.kills
		,csgp.deaths
		,csgp.gun_damage_dealt
		,csgp.bomb_damage_dealt
		,csgp.gun_damage_taken
		,csgp.bomb_damage_taken
		,csgp.self_damage
		,csgp.gun_fire_count
		,csgp.bomb_fire_count
		,csgp.mine_fire_count
		,csgp.gun_hit_count
		,csgp.bomb_hit_count
		,csgp.mine_hit_count
	from cte_data as cd
	inner join game_type as gt
		on cd.game_type_id = gt.game_type_id
	cross join cte_solo_game_participant as csgp
	cross join cte_stat_periods as csp
	where gt.is_solo = true
)
,cte_insert_player_solo_stats as(
	insert into player_solo_stats(
		 player_id
		,stat_period_id
		,games_played
		,play_duration
		,score
		,wins
		,losses
		,kills
		,deaths
		,gun_damage_dealt
		,bomb_damage_dealt
		,gun_damage_taken
		,bomb_damage_taken
		,self_damage
		,gun_fire_count
		,bomb_fire_count
		,mine_fire_count
		,gun_hit_count
		,bomb_hit_count
		,mine_hit_count
	)
	select
		 cs1.player_id
		,cs1.stat_period_id
		,1 as games_played
		,cs1.play_duration
		,cs1.score
		,case when is_winner = true then 1 else 0 end as wins
		,case when is_loser = true then 1 else 0 end as losses
		,cs1.kills
		,cs1.deaths
		,cs1.gun_damage_dealt
		,cs1.bomb_damage_dealt
		,cs1.gun_damage_taken
		,cs1.bomb_damage_taken
		,cs1.self_damage
		,cs1.gun_fire_count
		,cs1.bomb_fire_count
		,cs1.mine_fire_count
		,cs1.gun_hit_count
		,cs1.bomb_hit_count
		,cs1.mine_hit_count
	from cte_player_solo_stats cs1
	where not exists(
			select *
			from player_solo_stats as pss
			where pss.player_id = cs1.player_id
				and pss.stat_period_id = cs1.stat_period_id
		)
	returning
		 player_id
		,stat_period_id
)
,cte_update_player_solo_stats as(
	update player_solo_stats as p
	set
		 games_played = p.games_played + 1
		,play_duration = p.play_duration + c.play_duration
		,score = p.score + c.score
		,wins = p.wins + case when c.is_winner = true then 1 else 0 end
		,losses = p.losses + case when c.is_loser = true then 1 else 0 end
		,kills = p.kills + c.kills
		,deaths = p.deaths + c.deaths
		,gun_damage_dealt = p.gun_damage_dealt + c.gun_damage_dealt
		,bomb_damage_dealt = p.bomb_damage_dealt + c.bomb_damage_dealt
		,gun_damage_taken = p.gun_damage_taken + c.gun_damage_taken
		,bomb_damage_taken = p.bomb_damage_taken + c.bomb_damage_taken
		,self_damage = p.self_damage + c.self_damage
		,gun_fire_count = p.gun_fire_count + c.gun_fire_count
		,bomb_fire_count = p.bomb_fire_count + c.bomb_fire_count
		,mine_fire_count = p.mine_fire_count + c.mine_fire_count
		,gun_hit_count = p.gun_hit_count + c.gun_hit_count
		,bomb_hit_count = p.bomb_hit_count + c.bomb_hit_count
		,mine_hit_count = p.mine_hit_count + c.mine_hit_count
	from cte_player_solo_stats c
	where p.player_id = c.player_id
		and p.stat_period_id = c.stat_period_id
		and not exists( -- not inserted
			select *
			from cte_insert_player_solo_stats as i
			where i.player_id = p.player_id
				and i.stat_period_id = p.stat_period_id
		)
)
,cte_player_versus_stats as(
	select
		 dt.player_id
		,dt.stat_period_id
		,count(*) filter(where dt.is_winner) as wins
		,count(*) filter(where dt.is_loser) as losses
		,sum(dt.play_duration) as play_duration
		,sum(dt.lag_outs) as lag_outs
		,sum(dt.kills) as kills
		,sum(dt.deaths) as deaths
		,sum(dt.knockouts) as knockouts
		,sum(dt.team_kills) as team_kills
		,sum(dt.solo_kills) as solo_kills
		,sum(dt.assists) as assists
		,sum(dt.forced_reps) as forced_reps
		,sum(dt.gun_damage_dealt) as gun_damage_dealt
		,sum(dt.bomb_damage_dealt) as bomb_damage_dealt
		,sum(dt.team_damage_dealt) as team_damage_dealt
		,sum(dt.gun_damage_taken) as gun_damage_taken
		,sum(dt.bomb_damage_taken) as bomb_damage_taken
		,sum(dt.team_damage_taken) as team_damage_taken
		,sum(dt.self_damage) as self_damage
		,sum(dt.kill_damage) as kill_damage
		,sum(dt.team_kill_damage) as team_kill_damage
		,sum(dt.forced_rep_damage) as forced_rep_damage
		,sum(dt.bullet_fire_count) as bullet_fire_count
		,sum(dt.bomb_fire_count) as bomb_fire_count
		,sum(dt.mine_fire_count) as mine_fire_count
		,sum(dt.bullet_hit_count) as bullet_hit_count
		,sum(dt.bomb_hit_count) as bomb_hit_count
		,sum(dt.mine_hit_count) as mine_hit_count
		,count(*) filter(where dt.first_out_regular) as first_out_regular
		,count(*) filter(where dt.first_out_critical) as first_out_critical
		,sum(dt.wasted_energy) as wasted_energy
		,sum(dt.wasted_repel) as wasted_repel
		,sum(dt.wasted_rocket) as wasted_rocket
		,sum(dt.wasted_thor) as wasted_thor
		,sum(dt.wasted_burst) as wasted_burst
		,sum(dt.wasted_decoy) as wasted_decoy
		,sum(dt.wasted_portal) as wasted_portal
		,sum(dt.wasted_brick) as wasted_brick
		,sum(dt.enemy_distance_sum) as enemy_distance_sum
		,sum(dt.enemy_distance_samples) as enemy_distance_samples
		,sum(dt.team_distance_sum) as team_distance_sum
		,sum(dt.team_distance_samples) as team_distance_samples
	from(
		select
			 cvtm.player_id
			,csp.stat_period_id
			,cvt.is_winner
			,(	case when cvt.is_winner = false
						and exists( -- another team got a win (possible there's no winner, for a draw)
							select *
							from cte_versus_team as cvt2
							where cvt2.freq <> cvtm.freq
								and cvt2.is_winner = true
						)
					then true
					else false
				end
			 ) as is_loser
			,cvtm.play_duration
			,cvtm.lag_outs
			,cvtm.kills
			,cvtm.deaths
			,cvtm.knockouts
			,cvtm.team_kills
			,cvtm.solo_kills
			,cvtm.assists
			,cvtm.forced_reps
			,cvtm.gun_damage_dealt
			,cvtm.bomb_damage_dealt
			,cvtm.team_damage_dealt
			,cvtm.gun_damage_taken
			,cvtm.bomb_damage_taken
			,cvtm.team_damage_taken
			,cvtm.self_damage
			,cvtm.kill_damage
			,cvtm.team_kill_damage
			,cvtm.forced_rep_damage
			,cvtm.bullet_fire_count
			,cvtm.bomb_fire_count
			,cvtm.mine_fire_count
			,cvtm.bullet_hit_count
			,cvtm.bomb_hit_count
			,cvtm.mine_hit_count
			,case when cvtm.first_out = 1 then true else false end as first_out_regular
			,case when cvtm.first_out = 2 then true else false end as first_out_critical
			,cvtm.wasted_energy
			,cvtm.wasted_repel
			,cvtm.wasted_rocket
			,cvtm.wasted_thor
			,cvtm.wasted_burst
			,cvtm.wasted_decoy
			,cvtm.wasted_portal
			,cvtm.wasted_brick
			,cvtm.enemy_distance_sum
			,cvtm.enemy_distance_samples
			,cvtm.team_distance_sum
			,cvtm.team_distance_samples
		from cte_data as cd
		inner join game_type as gt
			on cd.game_type_id = gt.game_type_id
		cross join cte_versus_team_member as cvtm
		inner join cte_versus_team as cvt
			on cvtm.freq = cvt.freq
		cross join cte_stat_periods as csp
		where gt.is_team_versus = true
	) as dt
	group by -- in case the player played on multiple teams
		 dt.player_id
		,dt.stat_period_id
)
,cte_insert_player_versus_stats as(
	insert into player_versus_stats(
		 player_id
		,stat_period_id
		,wins
		,losses
		,games_played
		,play_duration
		,lag_outs
		,kills
		,deaths
		,knockouts
		,team_kills
		,solo_kills
		,assists
		,forced_reps
		,gun_damage_dealt
		,bomb_damage_dealt
		,team_damage_dealt
		,gun_damage_taken
		,bomb_damage_taken
		,team_damage_taken
		,self_damage
		,kill_damage
		,team_kill_damage
		,forced_rep_damage
		,bullet_fire_count
		,bomb_fire_count
		,mine_fire_count
		,bullet_hit_count
		,bomb_hit_count
		,mine_hit_count
		,first_out_regular
		,first_out_critical
		,wasted_energy
		,wasted_repel
		,wasted_rocket
		,wasted_thor
		,wasted_burst
		,wasted_decoy
		,wasted_portal
		,wasted_brick
		,enemy_distance_sum
		,enemy_distance_samples
		,team_distance_sum
		,team_distance_samples
	)
	select
		 cpvs.player_id
		,cpvs.stat_period_id
		,cpvs.wins
		,cpvs.losses
		,1 -- if we're inserting, this is the first game
		,cpvs.play_duration
		,cpvs.lag_outs
		,cpvs.kills
		,cpvs.deaths
		,cpvs.knockouts
		,cpvs.team_kills
		,cpvs.solo_kills
		,cpvs.assists
		,cpvs.forced_reps
		,cpvs.gun_damage_dealt
		,cpvs.bomb_damage_dealt
		,cpvs.team_damage_dealt
		,cpvs.gun_damage_taken
		,cpvs.bomb_damage_taken
		,cpvs.team_damage_taken
		,cpvs.self_damage
		,cpvs.kill_damage
		,cpvs.team_kill_damage
		,cpvs.forced_rep_damage
		,cpvs.bullet_fire_count
		,cpvs.bomb_fire_count
		,cpvs.mine_fire_count
		,cpvs.bullet_hit_count
		,cpvs.bomb_hit_count
		,cpvs.mine_hit_count
		,cpvs.first_out_regular
		,cpvs.first_out_critical
		,cpvs.wasted_energy
		,cpvs.wasted_repel
		,cpvs.wasted_rocket
		,cpvs.wasted_thor
		,cpvs.wasted_burst
		,cpvs.wasted_decoy
		,cpvs.wasted_portal
		,cpvs.wasted_brick
		,cpvs.enemy_distance_sum
		,cpvs.enemy_distance_samples
		,cpvs.team_distance_sum
		,cpvs.team_distance_samples
	from cte_player_versus_stats as cpvs
	where not exists(
			select *
			from player_versus_stats as pvs
			where pvs.player_id = cpvs.player_id
				and pvs.stat_period_id = cpvs.stat_period_id
		)
	returning
		 player_id
		,stat_period_id
)
,cte_update_player_versus_stats as(
	update player_versus_stats as pvs
	set  wins = pvs.wins + cpvs.wins
		,losses = pvs.losses + cpvs.losses
		,games_played = pvs.games_played + 1
		,play_duration = pvs.play_duration + cpvs.play_duration
		,lag_outs = pvs.lag_outs + cpvs.lag_outs
		,kills = pvs.kills + cpvs.kills
		,deaths = pvs.deaths + cpvs.deaths
		,knockouts = pvs.knockouts + cpvs.knockouts
		,team_kills = pvs.team_kills + cpvs.team_kills
		,solo_kills = pvs.solo_kills + cpvs.solo_kills
		,assists = pvs.assists + cpvs.assists
		,forced_reps = pvs.forced_reps + cpvs.forced_reps
		,gun_damage_dealt = pvs.gun_damage_dealt + cpvs.gun_damage_dealt
		,bomb_damage_dealt = pvs.bomb_damage_dealt + cpvs.bomb_damage_dealt
		,team_damage_dealt = pvs.team_damage_dealt + cpvs.team_damage_dealt
		,gun_damage_taken = pvs.gun_damage_taken + cpvs.gun_damage_taken
		,bomb_damage_taken = pvs.bomb_damage_taken + cpvs.bomb_damage_taken
		,team_damage_taken = pvs.team_damage_taken + cpvs.team_damage_taken
		,self_damage = pvs.self_damage + cpvs.self_damage
		,kill_damage = pvs.kill_damage + cpvs.kill_damage
		,team_kill_damage = pvs.team_kill_damage + cpvs.team_kill_damage
		,forced_rep_damage = pvs.forced_rep_damage + cpvs.forced_rep_damage
		,bullet_fire_count = pvs.bullet_fire_count + cpvs.bullet_fire_count
		,bomb_fire_count = pvs.bomb_fire_count + cpvs.bomb_fire_count
		,mine_fire_count = pvs.mine_fire_count + cpvs.mine_fire_count
		,bullet_hit_count = pvs.bullet_hit_count + cpvs.bullet_hit_count
		,bomb_hit_count = pvs.bomb_hit_count + cpvs.bomb_hit_count
		,mine_hit_count = pvs.mine_hit_count + cpvs.mine_hit_count
		,first_out_regular = pvs.first_out_regular + cpvs.first_out_regular
		,first_out_critical = pvs.first_out_critical + cpvs.first_out_critical
		,wasted_energy = pvs.wasted_energy + cpvs.wasted_energy
		,wasted_repel = pvs.wasted_repel + cpvs.wasted_repel
		,wasted_rocket = pvs.wasted_rocket + cpvs.wasted_rocket
		,wasted_thor = pvs.wasted_thor + cpvs.wasted_thor
		,wasted_burst = pvs.wasted_burst + cpvs.wasted_burst
		,wasted_decoy = pvs.wasted_decoy + cpvs.wasted_decoy
		,wasted_portal = pvs.wasted_portal + cpvs.wasted_portal
		,wasted_brick = pvs.wasted_brick + cpvs.wasted_brick
		,enemy_distance_sum = 
			case when pvs.enemy_distance_sum is null and cpvs.enemy_distance_sum is null
				then null
				else coalesce(pvs.enemy_distance_sum, 0) + coalesce(cpvs.enemy_distance_sum, 0)
			end
		,enemy_distance_samples = 
			case when pvs.enemy_distance_samples is null and cpvs.enemy_distance_samples is null
				then null
				else coalesce(pvs.enemy_distance_samples, 0) + coalesce(cpvs.enemy_distance_samples, 0)
			end
		,team_distance_sum = 
			case when pvs.team_distance_sum is null and cpvs.team_distance_sum is null
				then null
				else coalesce(pvs.team_distance_sum, 0) + coalesce(cpvs.team_distance_sum, 0)
			end
		,team_distance_samples = 
			case when pvs.team_distance_samples is null and cpvs.team_distance_samples is null
				then null
				else coalesce(pvs.team_distance_samples, 0) + coalesce(cpvs.team_distance_samples, 0)
			end
	from cte_player_versus_stats as cpvs
	where pvs.player_id = cpvs.player_id
		and pvs.stat_period_id = cpvs.stat_period_id
		and not exists( -- TODO: this might not be needed since this cte can't see the rows inserted by cte_insert_player_versus_stats?
			select *
			from cte_insert_player_versus_stats as i
			where i.player_id = cpvs.player_id
				and i.stat_period_id = cpvs.stat_period_id
		)
)
-- TODO: pb
--,cte_insert_player_pb_stats as(
--)
--,cte_update_player_pb_stats as(
--)
,cte_insert_player_rating as(
	insert into player_rating(
		 player_id
		,stat_period_id
		,rating
	)
	select
		 dt.player_id
		,csp.stat_period_id
		,greatest(csp.initial_rating + dt.rating_change, csp.minimum_rating)
	from cte_stat_periods as csp
	cross join(
		select
			 cvtm.player_id
			,sum(cvtm.rating_change) as rating_change
		from cte_versus_team_member as cvtm
		group by cvtm.player_id
	) as dt
	where csp.is_rating_enabled = true
		and not exists(
			select *
			from player_rating as pr
			where pr.player_id = dt.player_id
				and pr.stat_period_id = csp.stat_period_id
		)
	returning
		stat_period_id
)
,cte_update_player_rating as(
	update player_rating as pr
	set rating = greatest(pr.rating + dt.rating_change, csp.minimum_rating)
	from cte_stat_periods as csp
	cross join(
		select
			 cvtm.player_id
			,sum(cvtm.rating_change) as rating_change
		from cte_versus_team_member as cvtm
		group by cvtm.player_id
	) as dt
	where csp.is_rating_enabled = true
		and pr.player_id = dt.player_id
		and not exists( -- TODO: this might not be needed since this cte can't see the rows inserted by cte_insert_player_rating?
			select *
			from cte_insert_player_rating as i
			where i.stat_period_id = csp.stat_period_id
		)
)
,cte_update_player_ship_usage as(
	update player_ship_usage as psu
	set
		 warbird_use = psu.warbird_use + case when c.warbird_duration > cast('0' as interval) then 1 else 0 end
		,javelin_use = psu.javelin_use + case when c.javelin_duration > cast('0' as interval) then 1 else 0 end
		,spider_use = psu.spider_use + case when c.spider_duration > cast('0' as interval) then 1 else 0 end
		,leviathan_use = psu.leviathan_use + case when c.leviathan_duration > cast('0' as interval) then 1 else 0 end
		,terrier_use = psu.terrier_use + case when c.terrier_duration > cast('0' as interval) then 1 else 0 end
		,weasel_use = psu.weasel_use + case when c.weasel_duration > cast('0' as interval) then 1 else 0 end
		,lancaster_use = psu.lancaster_use + case when c.lancaster_duration > cast('0' as interval) then 1 else 0 end
		,shark_use = psu.shark_use + case when c.shark_duration > cast('0' as interval) then 1 else 0 end
		,warbird_duration = psu.warbird_duration + coalesce(c.warbird_duration, cast('0' as interval))
		,javelin_duration = psu.javelin_duration + coalesce(c.javelin_duration, cast('0' as interval))
		,spider_duration = psu.spider_duration + coalesce(c.spider_duration, cast('0' as interval))
		,leviathan_duration = psu.leviathan_duration + coalesce(c.leviathan_duration, cast('0' as interval))
		,terrier_duration = psu.terrier_duration + coalesce(c.terrier_duration, cast('0' as interval))
		,weasel_duration = psu.weasel_duration + coalesce(c.weasel_duration, cast('0' as interval))
		,lancaster_duration = psu.lancaster_duration + coalesce(c.lancaster_duration, cast('0' as interval))
		,shark_duration = psu.shark_duration + coalesce(c.shark_duration, cast('0' as interval))
	from cte_player_ship_usage_data as c
	cross join cte_stat_periods as csp
	where psu.player_id = c.player_id
		and psu.stat_period_id = csp.stat_period_id
)
,cte_insert_player_ship_usage as(
	insert into player_ship_usage(
		 player_id
		,stat_period_id
		,warbird_use
		,javelin_use
		,spider_use
		,leviathan_use
		,terrier_use
		,weasel_use
		,lancaster_use
		,shark_use
		,warbird_duration
		,javelin_duration
		,spider_duration
		,leviathan_duration
		,terrier_duration
		,weasel_duration
		,lancaster_duration
		,shark_duration
	)
	select
		 c.player_id
		,csp.stat_period_id
		,case when c.warbird_duration > cast('0' as interval) then 1 else 0 end
		,case when c.javelin_duration > cast('0' as interval) then 1 else 0 end
		,case when c.spider_duration > cast('0' as interval) then 1 else 0 end
		,case when c.leviathan_duration > cast('0' as interval) then 1 else 0 end
		,case when c.terrier_duration > cast('0' as interval) then 1 else 0 end
		,case when c.weasel_duration > cast('0' as interval) then 1 else 0 end
		,case when c.lancaster_duration > cast('0' as interval) then 1 else 0 end
		,case when c.shark_duration > cast('0' as interval) then 1 else 0 end
		,coalesce(c.warbird_duration, cast('0' as interval))
		,coalesce(c.javelin_duration, cast('0' as interval))
		,coalesce(c.spider_duration, cast('0' as interval))
		,coalesce(c.leviathan_duration, cast('0' as interval))
		,coalesce(c.terrier_duration, cast('0' as interval))
		,coalesce(c.weasel_duration, cast('0' as interval))
		,coalesce(c.lancaster_duration, cast('0' as interval))
		,coalesce(c.shark_duration, cast('0' as interval))
	from cte_player_ship_usage_data as c
	cross join cte_stat_periods as csp
	where not exists(
			select *
			from player_ship_usage as psu
			where psu.player_id = c.player_id
				and psu.stat_period_id = csp.stat_period_id
		)
)
select cm.game_id
from cte_game as cm;

$$;

revoke all on function ss.save_game(
	game_json jsonb
) from public;

grant execute on function ss.save_game(
	game_json jsonb
) to ss_zone_server;

create or replace function ss.save_game_bytea(
	p_game_json_utf8_bytes bytea
)
returns game.game_id%type
language sql
as
$$

/*
This function wraps the save_game function so that data can be streamed to the database server.
At the moment npgsql only supports streaming of parameters using the bytea data type.
*/

select save_game(convert_from(p_game_json_utf8_bytes, 'UTF8')::jsonb);

$$;

revoke all on function ss.save_game_bytea(
	p_game_json_utf8_bytes bytea
) from public;

grant execute on function ss.save_game_bytea(
	p_game_json_utf8_bytes bytea
) to ss_zone_server;

insert into migration.db_change_log(
	 applied_timestamp
	,major
	,minor
	,patch
	,script_file_name
)
values(
	 CURRENT_TIMESTAMP
	,1
	,0
	,0
	,'v1.0.0-full.sql'
);
