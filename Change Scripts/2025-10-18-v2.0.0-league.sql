-- This script upgrades v1.0.0 to v2.0.0

-- So that the functions don't need to be scripted in the proper order.
SET check_function_bodies = false;

insert into migration.db_change_log(
	 applied_timestamp
	,major
	,minor
	,patch
	,script_file_name
)
values(
	 CURRENT_TIMESTAMP
	,2
	,0
	,0
	,'v2.0.0-league.sql'
);


--
-- ss.game_mode
--

-- Create the new table
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

-- Populate the ss.game_mode lookup table with data
merge into ss.game_mode as gm
using(
	values
		 (1, '1v1')
		,(2, 'Team Versus')
		,(3, 'PowerBall')
) as v(game_mode_id, game_mode_name)
	on gm.game_mode_id = v.game_mode_id
when matched then
	update set game_mode_name = v.game_mode_name
when not matched then
	insert(
		 game_mode_id
		,game_mode_name
	)
	values(
		 v.game_mode_id
		,v.game_mode_name
	);

--
-- ss.stat_tracking
--

-- Set stat_tracking_id to be an identity column
ALTER TABLE IF EXISTS ss.stat_tracking
    ALTER COLUMN stat_tracking_id ADD GENERATED ALWAYS AS IDENTITY;

-- Update the next identity column sequence #
select setval(pg_get_serial_sequence('ss.stat_tracking', 'stat_tracking_id'), dt.next_stat_tracking_id)
from(
	select max(stat_tracking_id)+1 as next_stat_tracking_id from ss.stat_tracking
) as dt;

--
-- ss.game_type
--

-- Add the game_mode_id column (nullable)
ALTER TABLE IF EXISTS ss.game_type ADD COLUMN game_mode_id bigint;

-- Add the foreign key constraint for game_mode_id
ALTER TABLE IF EXISTS ss.game_type ADD CONSTRAINT game_type_game_mode_id_fkey FOREIGN KEY (game_mode_id)
	REFERENCES ss.game_mode (game_mode_id) MATCH SIMPLE
	ON UPDATE NO ACTION
	ON DELETE NO ACTION;

-- Populate game_mode_id column based on the existing data
update ss.game_type
set game_mode_id = 
	case
		when is_solo then 1 -- 1v1
		when is_team_versus then 2 -- Team Versus
		when is_pb then 3 -- Powerball
		else 2 -- assume it's Team Versus
	end;

-- Set the game_mode_id column to be not nullable
ALTER TABLE IF EXISTS ss.game_type
    ALTER COLUMN game_mode_id SET NOT NULL;

-- Drop the old columns that game_mode_id is replacing.
ALTER TABLE IF EXISTS ss.game_type DROP COLUMN IF EXISTS is_solo;
ALTER TABLE IF EXISTS ss.game_type DROP COLUMN IF EXISTS is_team_versus;
ALTER TABLE IF EXISTS ss.game_type DROP COLUMN IF EXISTS is_pb;

-- Drop the old constraint before renaming column
ALTER TABLE IF EXISTS ss.game_type DROP CONSTRAINT IF EXISTS game_type_game_type_name_key;

-- Rename game_type_description column to game_type_name
ALTER TABLE IF EXISTS ss.game_type RENAME COLUMN game_type_description TO game_type_name;

-- Change the game_type_name column from character varying to character varying(128)
ALTER TABLE IF EXISTS ss.game_type ALTER COLUMN game_type_name SET DATA TYPE character varying(128) COLLATE pg_catalog."default";

-- Add a unique constraint on game_type_name, with included columns so that it's a covering index
ALTER TABLE IF EXISTS ss.game_type
    ADD UNIQUE (game_type_name)
    INCLUDE (game_type_id, game_mode_id);

--
-- ss.game
--

-- Add the stat_period_id column (nullable), and its foreign key constraint
ALTER TABLE IF EXISTS ss.game
    ADD COLUMN stat_period_id bigint;
ALTER TABLE IF EXISTS ss.game
    ADD FOREIGN KEY (stat_period_id)
    REFERENCES ss.stat_period (stat_period_id) MATCH SIMPLE
    ON UPDATE NO ACTION
    ON DELETE NO ACTION;

-- Add a covering index on stat_period_id with included column game_id
CREATE INDEX IF NOT EXISTS game_stat_period_id_game_type_id_game_id_idx
    ON ss.game USING btree
    (stat_period_id ASC NULLS LAST)
    INCLUDE(game_id)
    WITH (fillfactor=100, deduplicate_items=True)
    TABLESPACE pg_default
    WHERE stat_period_id IS NOT NULL;

--
-- ss.stat_period_type
--

-- Add 2, League Season 
merge into stat_period_type as rpt
using(
	values
		 (0, 'Forever')
		,(1, 'Monthly')
		,(2, 'League Season')
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


-- SCHEMA: league

-- DROP SCHEMA IF EXISTS league ;

CREATE SCHEMA IF NOT EXISTS league
    AUTHORIZATION ss_developer;

GRANT ALL ON SCHEMA league TO ss_developer;

GRANT USAGE ON SCHEMA league TO ss_web_server;

GRANT USAGE ON SCHEMA league TO ss_zone_server;

-- Table: league.game_status

-- DROP TABLE IF EXISTS league.game_status;

CREATE TABLE IF NOT EXISTS league.game_status
(
    game_status_id bigint NOT NULL,
    game_status_name character varying(128) COLLATE pg_catalog."default" NOT NULL,
    game_status_description text COLLATE pg_catalog."default" NOT NULL,
    CONSTRAINT game_status_pkey PRIMARY KEY (game_status_id),
    CONSTRAINT game_status_game_status_name_game_status_id_key UNIQUE (game_status_name)
        INCLUDE(game_status_id)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS league.game_status
    OWNER to ss_developer;
	
-- Table: league.league_role

-- DROP TABLE IF EXISTS league.league_role;

CREATE TABLE IF NOT EXISTS league.league_role
(
    league_role_id bigint NOT NULL,
    league_role_name character varying(32) COLLATE pg_catalog."default" NOT NULL,
    CONSTRAINT league_role_pkey PRIMARY KEY (league_role_id),
    CONSTRAINT league_role_league_role_name_league_role_id_key UNIQUE (league_role_name)
        INCLUDE(league_role_id)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS league.league_role
    OWNER to ss_developer;
	
-- Table: league.season_role

-- DROP TABLE IF EXISTS league.season_role;

CREATE TABLE IF NOT EXISTS league.season_role
(
    season_role_id bigint NOT NULL,
    season_role_name character varying(32) COLLATE pg_catalog."default" NOT NULL,
    CONSTRAINT season_role_pkey PRIMARY KEY (season_role_id),
    CONSTRAINT season_role_season_role_name_season_role_id_key UNIQUE (season_role_name)
        INCLUDE(season_role_id)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS league.season_role
    OWNER to ss_developer;
	
-- Table: league.franchise

-- DROP TABLE IF EXISTS league.franchise;

CREATE TABLE IF NOT EXISTS league.franchise
(
    franchise_id bigint NOT NULL GENERATED ALWAYS AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 9223372036854775807 CACHE 1 ),
    franchise_name character varying(64) COLLATE pg_catalog."default" NOT NULL,
    CONSTRAINT franchise_pkey PRIMARY KEY (franchise_id),
    CONSTRAINT franchise_franchise_name_franchise_id_key UNIQUE (franchise_name)
        INCLUDE(franchise_id)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS league.franchise
    OWNER to ss_developer;
	
-- Table: league.league

-- DROP TABLE IF EXISTS league.league;

CREATE TABLE IF NOT EXISTS league.league
(
    league_id bigint NOT NULL GENERATED ALWAYS AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 9223372036854775807 CACHE 1 ),
    league_name character varying(128) COLLATE pg_catalog."default" NOT NULL,
    game_type_id bigint NOT NULL,
    min_teams_per_game smallint NOT NULL DEFAULT 2,
    max_teams_per_game smallint NOT NULL DEFAULT 2,
    freq_start smallint NOT NULL DEFAULT 10,
    freq_increment smallint NOT NULL DEFAULT 10,
    CONSTRAINT league_pkey PRIMARY KEY (league_id),
    CONSTRAINT league_league_name_key UNIQUE (league_name),
    CONSTRAINT league_game_type_id_fkey FOREIGN KEY (game_type_id)
        REFERENCES ss.game_type (game_type_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT league_min_teams_per_game_check CHECK (min_teams_per_game >= 2),
    CONSTRAINT league_teams_per_game_check CHECK (max_teams_per_game >= min_teams_per_game),
    CONSTRAINT league_max_freq_check CHECK ((freq_start + (max_teams_per_game - 1) * freq_increment) <= 9999)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS league.league
    OWNER to ss_developer;
-- Index: league_game_type_id_idx

-- DROP INDEX IF EXISTS league.league_game_type_id_idx;

CREATE INDEX IF NOT EXISTS league_game_type_id_idx
    ON league.league USING btree
    (game_type_id ASC NULLS LAST)
    WITH (fillfactor=100, deduplicate_items=True)
    TABLESPACE pg_default;
	
-- Table: league.league_user_role

-- DROP TABLE IF EXISTS league.league_user_role;

CREATE TABLE IF NOT EXISTS league.league_user_role
(
    user_id text COLLATE pg_catalog."default" NOT NULL,
    league_id bigint NOT NULL,
    league_role_id bigint NOT NULL,
    CONSTRAINT league_user_role_pkey PRIMARY KEY (user_id, league_id, league_role_id),
    CONSTRAINT league_user_role_league_id_fkey FOREIGN KEY (league_id)
        REFERENCES league.league (league_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT league_user_role_league_role_id_fkey FOREIGN KEY (league_role_id)
        REFERENCES league.league_role (league_role_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS league.league_user_role
    OWNER to ss_developer;
-- Index: league_user_role_league_id_user_id_league_role_id_idx

-- DROP INDEX IF EXISTS league.league_user_role_league_id_user_id_league_role_id_idx;

CREATE INDEX IF NOT EXISTS league_user_role_league_id_user_id_league_role_id_idx
    ON league.league_user_role USING btree
    (league_id ASC NULLS LAST)
    INCLUDE(user_id, league_role_id)
    WITH (fillfactor=100, deduplicate_items=True)
    TABLESPACE pg_default;
	
-- Table: league.season

-- DROP TABLE IF EXISTS league.season;

CREATE TABLE IF NOT EXISTS league.season
(
    season_id bigint NOT NULL GENERATED ALWAYS AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 9223372036854775807 CACHE 1 ),
    season_name character varying(128) COLLATE pg_catalog."default" NOT NULL,
    league_id bigint NOT NULL,
    created_timestamp timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    start_date date,
    end_date date,
    stat_period_id bigint,
    CONSTRAINT season_pkey PRIMARY KEY (season_id),
    CONSTRAINT season_season_name_league_id_key UNIQUE (season_name, league_id),
    CONSTRAINT season_stat_period_id_key UNIQUE (stat_period_id),
    CONSTRAINT season_league_id_fkey FOREIGN KEY (league_id)
        REFERENCES league.league (league_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT season_stat_period_id_fkey FOREIGN KEY (stat_period_id)
        REFERENCES ss.stat_period (stat_period_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS league.season
    OWNER to ss_developer;
-- Index: season_league_id_created_timestamp_season_id_idx

-- DROP INDEX IF EXISTS league.season_league_id_created_timestamp_season_id_idx;

CREATE INDEX IF NOT EXISTS season_league_id_created_timestamp_season_id_idx
    ON league.season USING btree
    (league_id ASC NULLS LAST, created_timestamp DESC NULLS FIRST)
    INCLUDE(season_id)
    WITH (fillfactor=100, deduplicate_items=True)
    TABLESPACE pg_default;
	
-- Table: league.team

-- DROP TABLE IF EXISTS league.team;

CREATE TABLE IF NOT EXISTS league.team
(
    team_id bigint NOT NULL GENERATED ALWAYS AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 9223372036854775807 CACHE 1 ),
    team_name character varying(20) COLLATE ss.case_insensitive NOT NULL,
    season_id bigint NOT NULL,
    banner_small character varying(255) COLLATE pg_catalog."default",
    banner_large character varying(255) COLLATE pg_catalog."default",
    wins integer NOT NULL DEFAULT 0,
    losses integer NOT NULL DEFAULT 0,
    draws integer NOT NULL DEFAULT 0,
    is_enabled boolean NOT NULL DEFAULT true,
    franchise_id bigint,
    CONSTRAINT team_pkey PRIMARY KEY (team_id),
    CONSTRAINT team_team_name_season_id_key UNIQUE (team_name, season_id),
    CONSTRAINT team_franchise_id_fkey FOREIGN KEY (franchise_id)
        REFERENCES league.franchise (franchise_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT team_season_id_fkey FOREIGN KEY (season_id)
        REFERENCES league.season (season_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS league.team
    OWNER to ss_developer;
-- Index: team_season_id_team_name_team_id_idx

-- DROP INDEX IF EXISTS league.team_season_id_team_name_team_id_idx;

CREATE INDEX IF NOT EXISTS team_season_id_team_name_team_id_idx
    ON league.team USING btree
    (season_id ASC NULLS LAST, team_name COLLATE ss.case_insensitive ASC NULLS LAST)
    INCLUDE(team_id)
    WITH (fillfactor=100, deduplicate_items=True)
    TABLESPACE pg_default;
	
-- Table: league.roster

-- DROP TABLE IF EXISTS league.roster;

CREATE TABLE IF NOT EXISTS league.roster
(
    season_id bigint NOT NULL,
    player_id bigint NOT NULL,
    signup_timestamp timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    team_id bigint,
    enroll_timestamp timestamp with time zone,
    is_captain boolean NOT NULL DEFAULT false,
    is_suspended boolean NOT NULL DEFAULT false,
    CONSTRAINT roster_pkey PRIMARY KEY (season_id, player_id),
    CONSTRAINT roster_player_id_fkey FOREIGN KEY (player_id)
        REFERENCES ss.player (player_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT roster_season_id_fkey FOREIGN KEY (season_id)
        REFERENCES league.season (season_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT roster_team_id_fkey FOREIGN KEY (team_id)
        REFERENCES league.team (team_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS league.roster
    OWNER to ss_developer;
-- Index: roster_player_id_idx

-- DROP INDEX IF EXISTS league.roster_player_id_idx;

CREATE INDEX IF NOT EXISTS roster_player_id_idx
    ON league.roster USING btree
    (player_id ASC NULLS LAST)
    WITH (fillfactor=100, deduplicate_items=True)
    TABLESPACE pg_default;
-- Index: roster_team_id_idx

-- DROP INDEX IF EXISTS league.roster_team_id_idx;

CREATE INDEX IF NOT EXISTS roster_team_id_idx
    ON league.roster USING btree
    (team_id ASC NULLS LAST)
    WITH (fillfactor=100, deduplicate_items=True)
    TABLESPACE pg_default;
	
-- Table: league.season_game

-- DROP TABLE IF EXISTS league.season_game;

CREATE TABLE IF NOT EXISTS league.season_game
(
    season_game_id bigint NOT NULL GENERATED ALWAYS AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 9223372036854775807 CACHE 1 ),
    season_id bigint NOT NULL,
    round_number integer,
    game_timestamp timestamp with time zone,
    game_id bigint,
    game_status_id bigint NOT NULL,
    CONSTRAINT season_game_pkey PRIMARY KEY (season_game_id),
    CONSTRAINT season_game_game_id_key UNIQUE (game_id),
    CONSTRAINT season_game_game_id_fkey FOREIGN KEY (game_id)
        REFERENCES ss.game (game_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT season_game_game_status_id_fkey FOREIGN KEY (game_status_id)
        REFERENCES league.game_status (game_status_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT season_game_season_id_fkey FOREIGN KEY (season_id)
        REFERENCES league.season (season_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS league.season_game
    OWNER to ss_developer;
-- Index: season_game_season_id_idx

-- DROP INDEX IF EXISTS league.season_game_season_id_idx;

CREATE INDEX IF NOT EXISTS season_game_season_id_idx
    ON league.season_game USING btree
    (season_id ASC NULLS LAST)
    WITH (fillfactor=100, deduplicate_items=True)
    TABLESPACE pg_default;
	
-- Table: league.season_game_team

-- DROP TABLE IF EXISTS league.season_game_team;

CREATE TABLE IF NOT EXISTS league.season_game_team
(
    season_game_id bigint NOT NULL,
    team_id bigint NOT NULL,
    freq smallint NOT NULL,
    is_winner boolean NOT NULL DEFAULT false,
    score integer,
    CONSTRAINT season_game_team_pkey PRIMARY KEY (season_game_id, team_id),
    CONSTRAINT season_game_team_season_game_id_freq_key UNIQUE (season_game_id, freq)
        DEFERRABLE INITIALLY DEFERRED,
    CONSTRAINT season_game_team_season_game_id_fkey FOREIGN KEY (season_game_id)
        REFERENCES league.season_game (season_game_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT season_game_team_team_id_fkey FOREIGN KEY (team_id)
        REFERENCES league.team (team_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS league.season_game_team
    OWNER to ss_developer;
-- Index: season_game_team_team_id_idx

-- DROP INDEX IF EXISTS league.season_game_team_team_id_idx;

CREATE INDEX IF NOT EXISTS season_game_team_team_id_idx
    ON league.season_game_team USING btree
    (team_id ASC NULLS LAST)
    WITH (fillfactor=100, deduplicate_items=True)
    TABLESPACE pg_default;
	
-- Table: league.season_round

-- DROP TABLE IF EXISTS league.season_round;

CREATE TABLE IF NOT EXISTS league.season_round
(
    season_id bigint NOT NULL,
    round_number integer NOT NULL,
    round_name character varying(128) COLLATE pg_catalog."default" NOT NULL,
    round_description text COLLATE pg_catalog."default",
    CONSTRAINT season_round_pkey PRIMARY KEY (season_id, round_number),
    CONSTRAINT season_round_season_id_fkey FOREIGN KEY (season_id)
        REFERENCES league.season (season_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS league.season_round
    OWNER to ss_developer;
	
-- Table: league.season_user_role

-- DROP TABLE IF EXISTS league.season_user_role;

CREATE TABLE IF NOT EXISTS league.season_user_role
(
    user_id text COLLATE pg_catalog."default" NOT NULL,
    season_id bigint NOT NULL,
    season_role_id bigint NOT NULL,
    CONSTRAINT season_user_role_pkey PRIMARY KEY (user_id, season_id, season_role_id),
    CONSTRAINT season_user_role_season_id_fkey FOREIGN KEY (season_id)
        REFERENCES league.season (season_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT season_user_role_season_role_id_fkey FOREIGN KEY (season_role_id)
        REFERENCES league.season_role (season_role_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS league.season_user_role
    OWNER to ss_developer;
-- Index: season_user_role_season_id_user_id_season_role_id_idx

-- DROP INDEX IF EXISTS league.season_user_role_season_id_user_id_season_role_id_idx;

CREATE INDEX IF NOT EXISTS season_user_role_season_id_user_id_season_role_id_idx
    ON league.season_user_role USING btree
    (season_id ASC NULLS LAST)
    INCLUDE(user_id, season_role_id)
    WITH (fillfactor=100, deduplicate_items=True)
    TABLESPACE pg_default;

merge into league.game_status as gs
using(
	values
		 (1, 'Pending', 'Represents a newly created game that has not yet been played.')
		,(2, 'In Progress', 'Represents a game that is currently being played. A game will be set to this when it is announced.')
		,(3, 'Complete', 'Represents a game that has been completed. This includes if a game''s result is manually entered in (e.g. historic game data, or other games played outside of this system).')
) as v(game_status_id, game_status_name, game_status_description)
	on gs.game_status_id = v.game_status_id
when matched then
	update set
		 game_status_name = v.game_status_name
		,game_status_description = v.game_status_description
when not matched then
	insert(
		 game_status_id
		,game_status_name
		,game_status_description
	)
	values(
		 v.game_status_id
		,v.game_status_name
		,v.game_status_description
	);

merge into league.league_role as lr
using(
	values
		(1, 'Manager')
) as v(league_role_id, league_role_name)
	on lr.league_role_id = v.league_role_id
when matched and v.league_role_name <> lr.league_role_name then
	update set
		league_role_name = v.league_role_name
when not matched then
	insert(
		 league_role_id
		,league_role_name
	)
	values(
		 v.league_role_id
		,v.league_role_name
	);

merge into league.season_role as lr
using(
	values
		(1, 'Manager')
) as v(season_role_id, season_role_name)
	on lr.season_role_id = v.season_role_id
when matched and v.season_role_name <> lr.season_role_name then
	update set
		season_role_name = v.season_role_name
when not matched then
	insert(
		 season_role_id
		,season_role_name
	)
	values(
		 v.season_role_id
		,v.season_role_name
	);

create or replace function ss.delete_game_type(
	 p_game_type_id ss.game_type.game_type_id%type
)
returns void
language sql
security definer
set search_path = ss, pg_temp
as
$$

/*
*/

delete from ss.game_type
where game_type_id = p_game_type_id;

$$;

alter function ss.delete_game_type owner to ss_developer;

revoke all on function ss.delete_game_type from public;

grant execute on function ss.delete_game_type to ss_web_server;

create or replace function ss.get_game(
	p_game_id ss.game.game_id%type
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
		,(lower(g.time_played) at time zone 'UTC') as start_time
		,(upper(g.time_played) at time zone 'UTC') as end_time
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
									,(ge.event_timestamp at time zone 'UTC') as timestamp
									,ase.freq
									,ase.slot_idx
									,p.player_name as player
								from ss.versus_game_assign_slot_event as ase
								inner join ss.player as p
									on ase.player_id = p.player_id
								where ase.game_event_id = ge.game_event_id
							) as dt
						)
						when 2 then( -- Versus - Player kill
							select to_json(dt.*)
							from(
								select
									 ge.game_event_type_id as event_type_id
									,(ge.event_timestamp at time zone 'UTC') as timestamp
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
										from ss.game_event_damage as ged
										inner join ss.player as p3
											on ged.player_id = p3.player_id
										where ged.game_event_id = ge.game_event_id
									 ) as damage_stats
									,(	select json_object_agg(p4.player_name, ger.rating)
										from ss.game_event_rating as ger
										inner join ss.player as p4
											on ger.player_id = p4.player_id
										where ger.game_event_id = ge.game_event_id
									) as rating_changes
								from ss.versus_game_kill_event as ke
								inner join ss.player as p1
									on ke.killed_player_id = p1.player_id
								inner join ss.player as p2
									on ke.killer_player_id = p2.player_id
								where ke.game_event_id = ge.game_event_id
							) as dt
						)
						when 3 then( -- Ship change
							select to_json(dt.*)
							from(
								select
									 ge.game_event_type_id as event_type_id
									,(ge.event_timestamp at time zone 'UTC') as timestamp
									,p.player_name as player
									,sce.ship
								from ss.game_ship_change_event as sce
								inner join ss.player as p
									on sce.player_id = p.player_id
								where sce.game_event_id = ge.game_event_id
							) as dt
						)
						when 4 then( -- Use item
							select to_json(dt.*)
							from(
								select
									 ge.game_event_type_id as event_type_id
									,(ge.event_timestamp at time zone 'UTC') as timestamp
									,p.player_name as player
									,uie.ship_item_id
									,(	select json_object_agg(p3.player_name, ged.damage)
										from ss.game_event_damage as ged
										inner join ss.player as p3
											on ged.player_id = p3.player_id
										where ged.game_event_id = ge.game_event_id
									 ) as damage_stats
								from ss.game_use_item_event as uie
								inner join ss.player as p
									on uie.player_id = p.player_id
								where uie.game_event_id = ge.game_event_id
							) as dt
						)
						else null
					end as event_json
				from ss.game_event as ge
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
							from ss.versus_game_team_member as vgtm
							inner join ss.player as p
								on vgtm.player_id = p.player_id
							left outer join ss.squad as s
								on p.squad_id = s.squad_id
							where vgtm.game_id = vgt.game_id
								and vgtm.freq = vgt.freq
							order by
								 vgtm.slot_idx
								,vgtm.member_idx
						) as mdt
					 ) as members
				from ss.versus_game_team as vgt
				where gt.game_mode_id = 2 -- Team Versus
					and vgt.game_id = g.game_id
				order by vgt.freq
			) as tdt
		 ) as team_stats
	from ss.game as g
	inner join ss.game_type as gt
		on g.game_type_id = gt.game_type_id
	inner join ss.zone_server as zs
		on g.zone_server_id = zs.zone_server_id
	inner join ss.arena as a
		on g.arena_id = a.arena_id
	inner join ss.lvl as l
		on g.lvl_id = l.lvl_id
	where g.game_id = p_game_id
) as dt;

$$;

alter function ss.get_game owner to ss_developer;

revoke all on function ss.get_game from public;

grant execute on function ss.get_game to ss_web_server;

create or replace function ss.get_game_types()
returns table(
	 game_type_id ss.game_type.game_type_id%type
	,game_type_name ss.game_type.game_type_name%type
	,game_mode_id ss.game_type.game_mode_id%type
)
language sql
security definer
set search_path = ss, pg_temp
as
$$

/*
Usage:
select * from ss.get_game_types();
*/

select
	 gt.game_type_id
	,gt.game_type_name
	,gt.game_mode_id
from ss.game_type as gt
order by gt.game_type_name;
$$;

alter function ss.get_game_types owner to ss_developer;

revoke all on function ss.get_game_types from public;

grant execute on function ss.get_game_types to ss_web_server;

create or replace function ss.get_or_insert_arena(
	p_arena_name ss.arena.arena_name%type
)
returns ss.arena.arena_id%type
language plpgsql
as
$$

/*
Usage:
select ss.get_or_insert_arena('turf');
select ss.get_or_insert_arena('TURF2');
select ss.get_or_insert_arena('turf1');
select ss.get_or_insert_arena('turf2');
select ss.get_or_insert_arena('0');
select ss.get_or_insert_arena('1');
select ss.get_or_insert_arena('4v4pub');
select ss.get_or_insert_arena('4v4pub1');
select ss.get_or_insert_arena('4v4pub2');
select ss.get_or_insert_arena('pb');

select * from ss.arena;
*/

declare
	l_arena_id arena.arena_id%type;
begin
	-- no matter what, arena names should always be lowercase
	p_arena_name := lower(p_arena_name);

	select a.arena_id
	into l_arena_id
	from ss.arena as a
	where a.arena_name = p_arena_name;
	
	if l_arena_id is null then
		insert into ss.arena(arena_name)
		values(p_arena_name)
		returning arena_id
		into l_arena_id;
	end if;
	
	return l_arena_id;
end;
$$;

alter function ss.get_game owner to ss_developer;

revoke all on function ss.get_game from public;

create or replace function ss.get_or_insert_lifetime_stat_tracking(
	p_game_type_id ss.game_type.game_type_id%type
)
returns ss.stat_period.stat_period_id%type
language sql
security definer
set search_path = ss, pg_temp
as
$$

/*
Gets the lifetime stat tracking period for a game type.
If it does not yet exist yet, the ss.stat_tracking record and the ss.stat_period record will be inserted.

Usage:
select ss.get_or_insert_lifetime_stat_tracking(3);

select * 
from ss.stat_tracking as st
left outer join ss.stat_period as sp
	on st.stat_tracking_id = sp.stat_tracking_id
where st.stat_period_type_id = 0;
*/

with cte_insert_stat_tracking as(
	insert into ss.stat_tracking(
		 game_type_id
		,stat_period_type_id
		,is_auto_generate_period
		,is_rating_enabled
		,initial_rating
		,minimum_rating
	)
	select
		 p_game_type_id
		,0 -- lifetime / forever
		,true
		,false
		,null
		,null
	where not exists(
			select *
			from ss.stat_tracking as st
			where st.game_type_id = p_game_type_id
				and st.stat_period_type_id = 0 -- lifetime / forever
		)
	returning stat_tracking_id
)
,cte_insert_stat_period as(
	insert into ss.stat_period(
		 stat_tracking_id
		,period_range
	)
	select
		 cist.stat_tracking_id
		,tstzrange(null, null) -- the lifetime / forever period is unbounded
	from cte_insert_stat_tracking as cist
	returning stat_period_id
)
select cisp.stat_period_id
from cte_insert_stat_period as cisp
union
select sp.stat_period_id
from ss.stat_tracking as st
inner join ss.stat_period as sp
	on st.stat_tracking_id = sp.stat_tracking_id
where st.game_type_id = p_game_type_id
	and stat_period_type_id = 0; -- lifetime / forever

$$;

alter function ss.get_or_insert_lifetime_stat_tracking owner to ss_developer;

revoke all on function ss.get_or_insert_lifetime_stat_tracking from public;

grant execute on function ss.get_or_insert_lifetime_stat_tracking to ss_web_server;

create or replace function ss.get_or_insert_lvl(
	 p_lvl_file_name ss.lvl.lvl_file_name%type
	,p_lvl_checksum ss.lvl.lvl_checksum%type
)
returns ss.lvl.lvl_id%type
language plpgsql
as
$$

/*
Usage:
select ss.get_or_insert_lvl('foo.lvl', 123);
select ss.get_or_insert_lvl('foo.lvl', 1515);
select ss.get_or_insert_lvl('bar.lvl', 61261);

select * from ss.lvl
*/

declare
	l_lvl_id lvl.lvl_id%type;
begin
	select lvl_id
	into l_lvl_id
	from ss.lvl
	where lvl_file_name = p_lvl_file_name
		and lvl_checksum = p_lvl_checksum;
		
	if l_lvl_id is null then
		insert into ss.lvl(
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

alter function ss.get_or_insert_lvl owner to ss_developer;

revoke all on function ss.get_or_insert_lvl from public;

create or replace function ss.get_or_insert_player(
	 p_player_name ss.player.player_name%type
)
returns ss.player.player_id%type
language plpgsql
as
$$

/*
Gets the player_id of a player by name.
If there is no record, INSERT one.
Player names are compared in a case-insensitive manner.

Usage:
select ss.get_or_insert_player('foo');
select ss.get_or_insert_player('bar');

select * from ss.player;
select * from ss.squad;
*/

declare
	l_player_id ss.player.player_id%type;
begin
	p_player_name := trim(p_player_name);
	if p_player_name is null or p_player_name = '' then
		return null;
	end if;

	insert into ss.player(player_name)
	select p_player_name
	where not exists(
			select *
			from ss.player as p
			where p.player_name = p_player_name
		);
		
	select player_id
	into l_player_id
	from ss.player
	where player_name = p_player_name;

	return l_player_id;
end;
$$;

alter function ss.get_or_insert_player owner to ss_developer;

revoke all on function ss.get_or_insert_player from public;

create or replace function ss.get_or_insert_stat_periods(
	 p_game_type_id ss.game_type.game_type_id%type
	,p_as_of timestamptz
)
returns table(
	 stat_period_id ss.stat_period.stat_period_id%type
	,stat_tracking_id ss.stat_tracking.stat_tracking_id%type
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
select * from ss.get_or_insert_stat_periods(4, current_timestamp);

select * from ss.stat_period;
*/

with cte_all_periods as(
	select
		 st.stat_tracking_id
		,st.stat_period_type_id
		,sp.stat_period_id
	from ss.stat_tracking as st
	left outer join ss.stat_period as sp
		on st.stat_tracking_id = sp.stat_tracking_id
			and sp.period_range @> p_as_of
	where st.game_type_id = p_game_type_id
		and (sp.stat_period_id is not null
			or (sp.stat_period_id is null and st.is_auto_generate_period = true)
		)
)
,cte_insert_stat_period as(
	insert into ss.stat_period(
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

alter function ss.get_or_insert_stat_periods owner to ss_developer;

revoke all on function ss.get_or_insert_stat_periods from public;

create or replace function ss.get_or_insert_zone_server(
	p_zone_server_name ss.zone_server.zone_server_name%type
)
returns ss.zone_server.zone_server_id%type
language plpgsql
as
$$
declare
	l_zone_server_id ss.zone_server.zone_server_id%type;
begin
	select zs.zone_server_id
	into l_zone_server_id
	from ss.zone_server as zs
	where zs.zone_server_name = p_zone_server_name;
	
	if l_zone_server_id is null then
		insert into ss.zone_server(zone_server_name)
		values(p_zone_server_name)
		returning zone_server_id
		into l_zone_server_id;
	end if;
	
	return l_zone_server_id;
end;
$$;

alter function ss.get_or_insert_zone_server owner to ss_developer;

revoke all on function ss.get_or_insert_zone_server from public;

create or replace function ss.get_or_upsert_player(
	 p_player_name ss.player.player_name%type
	,p_squad_name ss.squad.squad_name%type
	,p_x_res ss.player.x_res%type
	,p_y_res ss.player.y_res%type
)
returns ss.player.player_id%type
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
select ss.get_or_upsert_player('foo', null, 1024::smallint, 768::smallint);
select ss.get_or_upsert_player('foo', 'test', 1024::smallint, 768::smallint);
select ss.get_or_upsert_player('foo', 'the best squad', 1024::smallint, 768::smallint);
select ss.get_or_upsert_player('foo', null, 1920::smallint, 1080::smallint);
select ss.get_or_upsert_player('FOO', null, 1024::smallint, 768::smallint);
select ss.get_or_upsert_player(' ', null, 1024::smallint, 768::smallint);

select * from ss.player;
select * from ss.squad;
*/

declare
	l_player_id ss.player.player_id%type;
	l_squad_id ss.squad.squad_id%type;
begin
	p_player_name := trim(p_player_name);
	if p_player_name is null or p_player_name = '' then
		return null;
	end if;

	l_squad_id := ss.get_or_upsert_squad(p_squad_name);
	
	merge into ss.player as p
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
	from ss.player
	where player_name = p_player_name; -- case insensitive

	return l_player_id;
end;
$$;

alter function ss.get_or_upsert_player owner to ss_developer;

revoke all on function ss.get_or_upsert_player from public;

create or replace function ss.get_or_upsert_squad(
	p_squad_name ss.squad.squad_name%type
)
returns ss.squad.squad_id%type
language plpgsql
as
$$

/*
select ss.get_or_upsert_squad('foo squad');
select ss.get_or_upsert_squad('foo squad');
select ss.get_or_upsert_squad('FOO squad');
select ss.get_or_upsert_squad('test');
select ss.get_or_upsert_squad('');
select ss.get_or_upsert_squad(' ');
select ss.get_or_upsert_squad(null);

select * from ss.squad;
*/

declare
	l_squad_id ss.squad.squad_id%type;
begin
	p_squad_name := trim(p_squad_name);
	if p_squad_name is null or trim(p_squad_name) = '' then
		return null;
	end if;

	select s.squad_id
	into l_squad_id
	from ss.squad as s
	where s.squad_name = p_squad_name; -- case insensitive
	
	if l_squad_id is null then
		insert into ss.squad(squad_name)
		values(p_squad_name)
		returning squad_id
		into l_squad_id;
	else
		update ss.squad
		set squad_name = p_squad_name
		where squad_id = l_squad_id
			and squad_name collate "default" <> p_squad_name collate "default"; -- case sensitive
	end if;
	
	return l_squad_id;
end;
$$;

alter function ss.get_or_upsert_squad owner to ss_developer;

revoke all on function ss.get_or_upsert_squad from public;

create or replace function ss.get_player_info(
	p_player_name ss.player.player_name%type
)
returns table(
	 squad_name ss.squad.squad_name%type
	,x_res ss.player.x_res%type
	,y_res ss.player.y_res%type
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
from ss.player as p
left outer join ss.squad as s
	on p.squad_id = s.squad_id
where p.player_name = p_player_name;

$$;

alter function ss.get_player_info owner to ss_developer;

revoke all on function ss.get_player_info from public;

grant execute on function ss.get_player_info to ss_web_server;

drop function ss.get_player_participation_overview;
create or replace function ss.get_player_participation_overview(
	 p_player_name ss.player.player_name%type
	,p_period_cutoff interval
)
returns table(
	 stat_period_id ss.stat_period.stat_period_id%type
	,game_type_id ss.game_type.game_type_id%type
	,stat_period_type_id ss.stat_period_type.stat_period_type_id%type
	,period_range ss.stat_period.period_range%type
	,period_extra_name character varying
	,rating ss.player_rating.rating%type
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
select * from ss.get_player_participation_overview('foo', interval '1 year');
*/

declare
	l_start timestamptz;
	l_player_id ss.player.player_id%type;
begin
	l_start := current_timestamp - coalesce(p_period_cutoff, interval '1 year');
	
	select p.player_id
	into l_player_id
	from ss.player as p
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
			from ss.player_versus_stats as pvs
			inner join ss.stat_period as sp
				on pvs.stat_period_id = sp.stat_period_id
			where pvs.player_id = l_player_id
				and lower(sp.period_range) >= l_start
		)
		select
			  dt2.stat_period_id
			 ,st.game_type_id
			 ,st.stat_period_type_id
			 ,sp.period_range
			 ,ss.get_stat_period_extra_name(sp.stat_period_id) as period_extra_name
			 ,pr.rating
			 ,case when gt.game_mode_id = 2 then( -- Team Versus
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
										from ss.versus_game_team as vgt2
										where vgt2.game_id = vgt.game_id
											and vgt2.freq <> vgt.freq
											and vgt2.is_winner = true
									)
									then 1
									else 0
								end
							) as losses
						from ss.game as g
						inner join ss.versus_game_team_member as vgtm
							on g.game_id = vgtm.game_id
								and vgtm.player_id = l_player_id
						inner join ss.versus_game_team as vgt
							on g.game_id = vgt.game_id
								and vgtm.freq = vgt.freq
						where sp.period_range @> g.time_played
							and g.game_type_id = st.game_type_id
						group by vgtm.player_id
					) as dt
				)
				when gt.game_mode_id = 1 then( -- 1v1
					select to_json(dt.*)
				 	from(
						select
							 count(*) as games_played
							,sum(case when sgp.is_winner then 1 else 0 end) as wins
						from ss.game as g
						inner join ss.solo_game_participant as sgp
							on g.game_id = sgp.game_id
								and sgp.player_id = l_player_id
						where sp.period_range @> g.time_played
							and g.game_type_id = st.game_type_id
					) as dt
				)
-- 				when gt.game_mode_id = 3 then( -- Powerball
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
		inner join ss.stat_tracking as st
			on dt2.stat_tracking_id = st.stat_tracking_id
		inner join ss.game_type as gt
			on st.game_type_id = gt.game_type_id
		inner join ss.stat_period as sp
			on dt2.stat_period_id = sp.stat_period_id
		left outer join ss.player_rating as pr
			on pr.player_id = l_player_id
				and sp.stat_period_id = pr.stat_period_id
		order by sp.period_range desc;
end;
$$;

alter function ss.get_player_participation_overview owner to ss_developer;

revoke all on function ss.get_player_participation_overview from public;

grant execute on function ss.get_player_participation_overview to ss_web_server;

create or replace function ss.get_player_rating(
	 p_game_type_id ss.game_type.game_type_id%type
	,p_player_names character varying(20)[]
)
returns table(
	 player_name ss.player.player_name%type
	,rating ss.player_rating.rating%type
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
	from ss.stat_tracking as st
	inner join ss.stat_period as sp
		on st.stat_tracking_id = sp.stat_tracking_id
	where st.game_type_id = p_game_type_id
		and st.is_rating_enabled = true
	order by
		 st.is_auto_generate_period desc
		,sp.period_range desc -- compares by lower bound first, then upper bound
	limit 1
) as dt
cross join unnest(p_player_names) as t(player_name)
left outer join ss.player as p
	on t.player_name = p.player_name
left outer  join ss.player_rating as pr
	on p.player_id = pr.player_id
		and dt.stat_period_id = pr.stat_period_id;

$$;

alter function ss.get_player_rating owner to ss_developer;

revoke all on function ss.get_player_rating from public;

grant execute on function ss.get_player_rating to ss_zone_server;

drop function ss.get_player_stat_periods;
create or replace function ss.get_player_stat_periods(
	 p_player_name ss.player.player_name%type
	,p_period_cutoff interval
)
returns table(
	 stat_period_id ss.stat_period.stat_period_id%type
	,game_type_id ss.game_type.game_type_id%type
	,stat_period_type_id ss.stat_period_type.stat_period_type_id%type
	,period_range ss.stat_period.period_range%type
	,period_extra_name character varying
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
select * from ss.get_player_stat_periods('asdf', null);
select * from ss.get_player_stat_periods('asdf', interval '1 months');
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
			,ss.get_stat_period_extra_name(sp.stat_period_id) as period_extra_name
		from ss.player as p
		inner join ss.player_versus_stats as pvs -- TODO: add support for other game types (solo, pb)
			on p.player_id = pvs.player_id
		inner join ss.stat_period as sp
			on pvs.stat_period_id = sp.stat_period_id
		inner join ss.stat_tracking as st
			on sp.stat_tracking_id = st.stat_tracking_id
		where p.player_name = p_player_name
			and lower(sp.period_range) >= l_start
			and st.stat_period_type_id <> 0 -- Not the 'Forever' period type
		order by
			 st.game_type_id
			,sp.period_range desc;
end;	
$$;

alter function ss.get_player_stat_periods owner to ss_developer;

revoke all on function ss.get_player_stat_periods from public;

grant execute on function ss.get_player_stat_periods to ss_web_server;

create or replace function ss.get_player_versus_game_stats(
	 p_player_name ss.player.player_name%type
	,p_stat_period_id ss.stat_period.stat_period_id%type
	,p_limit integer
	,p_offset integer
)
returns table(
	 game_id ss.game.game_id%type
	,time_played ss.game.time_played%type
	,score integer[]
	,result integer
	,play_duration ss.versus_game_team_member.play_duration%type
	,ship_mask ss.versus_game_team_member.ship_mask%type
	,lag_outs ss.versus_game_team_member.lag_outs%type
	,kills ss.versus_game_team_member.kills%type
	,deaths ss.versus_game_team_member.deaths%type
	,knockouts ss.versus_game_team_member.knockouts%type
	,team_kills ss.versus_game_team_member.team_kills%type
	,solo_kills ss.versus_game_team_member.solo_kills%type
	,assists ss.versus_game_team_member.assists%type
	,forced_reps ss.versus_game_team_member.forced_reps%type
	,gun_damage_dealt ss.versus_game_team_member.gun_damage_dealt%type
	,bomb_damage_dealt ss.versus_game_team_member.bomb_damage_dealt%type
	,team_damage_dealt ss.versus_game_team_member.team_damage_dealt%type
	,gun_damage_taken ss.versus_game_team_member.gun_damage_taken%type
	,bomb_damage_taken ss.versus_game_team_member.bomb_damage_taken%type
	,team_damage_taken ss.versus_game_team_member.team_damage_taken%type
	,self_damage ss.versus_game_team_member.self_damage%type
	,kill_damage ss.versus_game_team_member.kill_damage%type
	,team_kill_damage ss.versus_game_team_member.team_kill_damage%type
	,forced_rep_damage ss.versus_game_team_member.forced_rep_damage%type
	,bullet_fire_count ss.versus_game_team_member.bullet_fire_count%type
	,bomb_fire_count ss.versus_game_team_member.bomb_fire_count%type
	,mine_fire_count ss.versus_game_team_member.mine_fire_count%type
	,bullet_hit_count ss.versus_game_team_member.bullet_hit_count%type
	,bomb_hit_count ss.versus_game_team_member.bomb_hit_count%type
	,mine_hit_count ss.versus_game_team_member.mine_hit_count%type
	,first_out ss.versus_game_team_member.first_out%type
	,wasted_energy ss.versus_game_team_member.wasted_energy%type
	,wasted_repel ss.versus_game_team_member.wasted_repel%type
	,wasted_rocket ss.versus_game_team_member.wasted_rocket%type
	,wasted_thor ss.versus_game_team_member.wasted_thor%type
	,wasted_burst ss.versus_game_team_member.wasted_burst%type
	,wasted_decoy ss.versus_game_team_member.wasted_decoy%type
	,wasted_portal ss.versus_game_team_member.wasted_portal%type
	,wasted_brick ss.versus_game_team_member.wasted_brick%type
	,rating_change ss.versus_game_team_member.rating_change%type
	,enemy_distance_sum ss.versus_game_team_member.enemy_distance_sum%type
	,enemy_distance_samples ss.versus_game_team_member.enemy_distance_samples%type
	,team_distance_sum ss.versus_game_team_member.team_distance_sum%type
	,team_distance_samples ss.versus_game_team_member.team_distance_samples%type
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
select * from ss.get_player_versus_game_stats('foo', 16, 100, 0);
select * from ss.get_player_versus_game_stats('foo', 16, 2, 2);

select * from ss.stat_period
*/

declare
	l_player_id ss.player.player_id%type;
	l_game_type_id ss.game_type.game_type_id%type;
	l_period_range ss.stat_period.period_range%type;
begin
	select p.player_id
	into l_player_id
	from ss.player as p
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
	from ss.stat_period as sp
	inner join ss.stat_tracking as st
		on sp.stat_tracking_id = st.stat_tracking_id
	inner join ss.game_type as gt
		on st.game_type_id = gt.game_type_id
	where sp.stat_period_id = p_stat_period_id
		and gt.game_mode_id = 2; -- Team Versus
	
	if l_period_range is null then
		raise exception 'Invalid stat period specified. (%)', p_stat_period_id;
	end if;
	
	return query
		select
			 g.game_id
			,g.time_played
			,array(
				select vgt.score
				from ss.versus_game_team as vgt
				where vgt.game_id = vgtm.game_id
				order by freq
			) as score
			,case when exists(
					select *
					from ss.versus_game_team as vgt
					where vgt.game_id = vgtm.game_id
						and vgt.freq = vgtm.freq
						and vgt.is_winner
				)
				then 1 -- win
				else case when exists(
						select *
						from ss.versus_game_team as vgt
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
		from ss.game as g
		inner join ss.versus_game_team_member as vgtm
			on g.game_id = vgtm.game_id
				and player_id = l_player_id
		where g.game_type_id = l_game_type_id
			and l_period_range @> g.time_played
		order by g.time_played desc
		limit p_limit offset p_offset;
end;
$$;

alter function ss.get_player_versus_game_stats owner to ss_developer;

revoke all on function ss.get_player_versus_game_stats from public;

grant execute on function ss.get_player_versus_game_stats to ss_web_server;

create or replace function ss.get_player_versus_kill_stats(
	 p_player_name ss.player.player_name%type
	,p_stat_period_id ss.stat_period.stat_period_id%type
	,p_limit integer
)
returns table(
	 player_name ss.player.player_name%type
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
select * from ss.get_player_versus_kill_stats('foo', 16, 50);
select * from ss.get_player_versus_kill_stats('bar', 16, 50);
select * from ss.get_player_versus_kill_stats('G', 16, 50);
select * from ss.get_player_versus_kill_stats('asdf', 16, 50);

select * from ss.player;
select * from ss.stat_period;
*/

declare
	l_player_id ss.player.player_id%type;
	l_game_type_id ss.game_type.game_type_id%type;
	l_period_range ss.stat_period.period_range%type;
begin
	select p.player_id
	into l_player_id
	from ss.player as p
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
	from ss.stat_period as sp
	inner join ss.stat_tracking as st
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
			from ss.game as g
			inner join ss.game_event as ge
				on g.game_id = ge.game_id
			inner join ss.versus_game_kill_event as ke
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
		inner join ss.player as p
			on dt3.player_id = p.player_id
		order by 
			 dt3.kills desc
			,dt3.deaths desc
			,p.player_name
		limit p_limit;
end;
$$;

alter function ss.get_player_versus_kill_stats owner to ss_developer;

revoke all on function ss.get_player_versus_kill_stats from public;

grant execute on function ss.get_player_versus_kill_stats to ss_web_server;

create or replace function ss.get_player_versus_period_stats(
	 p_player_name ss.player.player_name%type
	,p_stat_period_ids bigint[]
)
returns table(
	 stat_period_id ss.stat_period.stat_period_id%type
	,period_rank integer
	,rating ss.player_rating.rating%type
	,games_played ss.player_versus_stats.games_played%type
	,play_duration ss.player_versus_stats.play_duration%type
	,wins ss.player_versus_stats.wins%type
	,losses ss.player_versus_stats.losses%type
	,lag_outs ss.player_versus_stats.lag_outs%type
	,kills ss.player_versus_stats.kills%type
	,deaths ss.player_versus_stats.deaths%type
	,knockouts ss.player_versus_stats.knockouts%type
	,team_kills ss.player_versus_stats.team_kills%type
	,solo_kills ss.player_versus_stats.solo_kills%type
	,assists ss.player_versus_stats.assists%type
	,forced_reps ss.player_versus_stats.forced_reps%type
	,gun_damage_dealt ss.player_versus_stats.gun_damage_dealt%type
	,bomb_damage_dealt ss.player_versus_stats.bomb_damage_dealt%type
	,team_damage_dealt ss.player_versus_stats.team_damage_dealt%type
	,gun_damage_taken ss.player_versus_stats.gun_damage_taken%type
	,bomb_damage_taken ss.player_versus_stats.bomb_damage_taken%type
	,team_damage_taken ss.player_versus_stats.team_damage_taken%type
	,self_damage ss.player_versus_stats.self_damage%type
	,kill_damage ss.player_versus_stats.kill_damage%type
	,team_kill_damage ss.player_versus_stats.team_kill_damage%type
	,forced_rep_damage ss.player_versus_stats.forced_rep_damage%type
	,bullet_fire_count ss.player_versus_stats.bullet_fire_count%type
	,bomb_fire_count ss.player_versus_stats.bomb_fire_count%type
	,mine_fire_count ss.player_versus_stats.mine_fire_count%type
	,bullet_hit_count ss.player_versus_stats.bullet_hit_count%type
	,bomb_hit_count ss.player_versus_stats.bomb_hit_count%type
	,mine_hit_count ss.player_versus_stats.mine_hit_count%type
	,first_out_regular ss.player_versus_stats.first_out_regular%type
	,first_out_critical ss.player_versus_stats.first_out_critical%type
	,wasted_energy ss.player_versus_stats.wasted_energy%type
	,wasted_repel ss.player_versus_stats.wasted_repel%type
	,wasted_rocket ss.player_versus_stats.wasted_rocket%type
	,wasted_thor ss.player_versus_stats.wasted_thor%type
	,wasted_burst ss.player_versus_stats.wasted_burst%type
	,wasted_decoy ss.player_versus_stats.wasted_decoy%type
	,wasted_portal ss.player_versus_stats.wasted_portal%type
	,wasted_brick ss.player_versus_stats.wasted_brick%type
	,enemy_distance_sum ss.player_versus_stats.enemy_distance_sum%type
	,enemy_distance_samples ss.player_versus_stats.enemy_distance_samples%type
	,team_distance_sum ss.player_versus_stats.team_distance_sum%type
	,team_distance_samples ss.player_versus_stats.team_distance_samples%type
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
select * from ss.get_player_versus_period_stats('foo', '{17,3}');
*/

select
	 pvs.stat_period_id
	,(	select dt.rating_rank
		from(
			select
				 dense_rank() over(order by pr.rating desc)::integer as rating_rank
				,pr.player_id
			from ss.player_rating as pr
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
	from ss.player as p
	where p.player_name = p_player_name
) as dt
cross join unnest(p_stat_period_ids) with ordinality as pspi(stat_period_id, ordinality)
inner join ss.player_versus_stats as pvs
	on dt.player_id = pvs.player_id
		and pspi.stat_period_id = pvs.stat_period_id
left outer join ss.player_rating as pr -- not all stat periods include rating (e.g. forever)
	on pvs.player_id = pr.player_id
		and pvs.stat_period_id = pr.stat_period_id
order by pspi.ordinality;
		
$$;

alter function ss.get_player_versus_period_stats owner to ss_developer;

revoke all on function ss.get_player_versus_period_stats from public;

grant execute on function ss.get_player_versus_period_stats to ss_web_server;

create or replace function ss.get_player_versus_ship_stats(
	 p_player_name ss.player.player_name%type
	,p_stat_period_id ss.stat_period.stat_period_id%type
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
select * from ss.get_player_versus_ship_stats('foo', 16);
select * from ss.get_player_versus_ship_stats('bar', 16);
select * from ss.get_player_versus_ship_stats('bar', 17);
select * from ss.get_player_versus_ship_stats('asdf', 16);
*/

declare
	l_player_id ss.player.player_id%type;
	l_game_type_id ss.game_type.game_type_id%type;
	l_period_range ss.stat_period.period_range%type;
begin
	select p.player_id
	into l_player_id
	from ss.player as p
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
	from ss.stat_period as sp
	inner join ss.stat_tracking as st
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
			from ss.game as g
			inner join ss.game_event as ge
				on g.game_id = ge.game_id
			inner join ss.versus_game_kill_event as ke
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
			from ss.player_ship_usage as u
			where u.player_id = l_player_id
				and u.stat_period_id = p_stat_period_id
			union
			select
				 1::smallint -- javelin
				,u.javelin_use as game_use_count
				,u.javelin_duration as use_duration
			from ss.player_ship_usage as u
			where u.player_id = l_player_id
				and u.stat_period_id = p_stat_period_id
			union
			select
				 2::smallint -- spider
				,u.spider_use as game_use_count
				,u.spider_duration as use_duration
			from ss.player_ship_usage as u
			where u.player_id = l_player_id
				and u.stat_period_id = p_stat_period_id
			union
			select
				 3::smallint -- leviathan
				,u.leviathan_use as game_use_count
				,u.leviathan_duration as use_duration
			from ss.player_ship_usage as u
			where u.player_id = l_player_id
				and u.stat_period_id = p_stat_period_id
			union
			select
				 4::smallint -- terrier
				,u.terrier_use as game_use_count
				,u.terrier_duration as use_duration
			from ss.player_ship_usage as u
			where u.player_id = l_player_id
				and u.stat_period_id = p_stat_period_id
			union
			select
				 5::smallint -- weasel
				,u.weasel_use as game_use_count
				,u.weasel_duration as use_duration
			from ss.player_ship_usage as u
			where u.player_id = l_player_id
				and u.stat_period_id = p_stat_period_id
			union
			select
				 6::smallint -- lancaster
				,u.lancaster_use as game_use_count
				,u.lancaster_duration as use_duration
			from ss.player_ship_usage as u
			where u.player_id = l_player_id
				and u.stat_period_id = p_stat_period_id
			union
			select
				 7::smallint -- shark
				,u.shark_use as game_use_count
				,u.shark_duration as use_duration
			from ss.player_ship_usage as u
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
							from ss.game_event_damage as d
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

alter function ss.get_player_versus_ship_stats owner to ss_developer;

revoke all on function ss.get_player_versus_ship_stats from public;

grant execute on function ss.get_player_versus_ship_stats to ss_web_server;

create or replace function ss.get_stat_period_extra_name(
	p_stat_period_id ss.stat_period.stat_period_id%type
)
returns character varying
language sql
as
$$

/*
select ss.get_stat_period_extra_name(38);
*/

select
	case when st.stat_period_type_id = 2 -- League Season
		then(
			select s.season_name
			from league.season as s
			where s.stat_period_id = sp.stat_period_id
			limit 1
		)
		else null
	 end as extra_name
from ss.stat_period as sp
inner join ss.stat_tracking as st
	on sp.stat_tracking_id = st.stat_tracking_id
where sp.stat_period_id = p_stat_period_id;

$$;

alter function ss.get_stat_period_extra_name owner to ss_developer;

revoke all on function ss.get_stat_period_extra_name from public;

grant execute on function ss.get_stat_period_extra_name to ss_web_server;
grant execute on function ss.get_stat_period_extra_name to ss_zone_server;

drop function ss.get_stat_periods;
create or replace function ss.get_stat_periods(
	 p_game_type_id ss.game_type.game_type_id%type
	,p_stat_period_type_id ss.stat_period_type.stat_period_type_id%type
	,p_limit integer
	,p_offset integer
)
returns table(
	 stat_period_id ss.stat_period.stat_period_id%type
	,period_range ss.stat_period.period_range%type
	,stat_period_type_id ss.stat_period_type.stat_period_type_id%type
	,period_extra_name character varying
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
select * from ss.get_stat_periods(2, 1, 12, 0) -- 2v2pub, monthly, limit 12 (1 year), offset 0
select * from ss.get_stat_periods(2, 0, 1, 0) -- 2v2pub, forever, limit 1, offset 0
*/

select
	 sp.stat_period_id
	,sp.period_range
	,st.stat_period_type_id
	,ss.get_stat_period_extra_name(sp.stat_period_id) as period_extra_name
from ss.stat_tracking as st
inner join ss.stat_period as sp
	on st.stat_tracking_id = sp.stat_tracking_id
where st.game_type_id = p_game_type_id
	and st.stat_period_type_id = coalesce(p_stat_period_type_id, st.stat_period_type_id)
	and (p_stat_period_type_id is not null or st.stat_period_type_id <> 0) -- don't send 'forever' stat periods when no period type is passed in
order by sp.period_range desc
limit p_limit offset p_offset;

$$;

alter function ss.get_stat_periods owner to ss_developer;

revoke all on function ss.get_stat_periods from public;

grant execute on function ss.get_stat_periods to ss_web_server;

create or replace function ss.get_team_versus_leaderboard(
	 p_stat_period_id ss.stat_period.stat_period_id%type
	,p_limit integer
	,p_offset integer
)
returns table(
	 rating_rank bigint
	,player_name ss.player.player_name%type
	,squad_name ss.squad.squad_name%type
	,rating ss.player_rating.rating%type
	,games_played ss.player_versus_stats.games_played%type
	,play_duration ss.player_versus_stats.play_duration%type
	,wins ss.player_versus_stats.wins%type
	,losses ss.player_versus_stats.losses%type
	,kills ss.player_versus_stats.kills%type
	,deaths ss.player_versus_stats.deaths%type
	,damage_dealt bigint
	,damage_taken bigint
	,kill_damage ss.player_versus_stats.kill_damage%type
	,forced_reps ss.player_versus_stats.forced_reps%type
	,forced_rep_damage ss.player_versus_stats.forced_rep_damage%type
	,assists ss.player_versus_stats.assists%type
	,wasted_energy ss.player_versus_stats.wasted_energy%type
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

select * from ss.player_versus_stats;
select * from ss.stat_period;
select * from ss.stat_tracking;
select * from ss.game_type;
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
	,pvs.first_out_regular as first_out
from ss.player_versus_stats as pvs
inner join ss.player as p
	on pvs.player_id = p.player_id
left outer join ss.squad as s
	on p.squad_id = s.squad_id
left outer join ss.player_rating as pr
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

alter function ss.get_team_versus_leaderboard owner to ss_developer;

revoke all on function ss.get_team_versus_leaderboard from public;

grant execute on function ss.get_team_versus_leaderboard to ss_web_server;

create or replace function ss.get_top_players_by_rating(
	 p_stat_period_id ss.stat_period.stat_period_id%type
	,p_top integer
)
returns table(
	 top_rank integer
	,player_name ss.player.player_name%type
	,rating ss.player_rating.rating%type
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
select * from ss.get_top_players_by_rating(16, 5);
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
	from ss.player_rating as pr
	where pr.stat_period_id = p_stat_period_id
) as dt
inner join ss.player as p
	on dt.player_id = p.player_id
where dt.top_rank <= p_top
order by
	 dt.top_rank
	,p.player_name;

$$;

alter function ss.get_top_players_by_rating owner to ss_developer;

revoke all on function ss.get_top_players_by_rating from public;

grant execute on function ss.get_top_players_by_rating to ss_web_server;

create or replace function ss.get_top_versus_players_by_avg_rating(
	 p_stat_period_id ss.stat_period.stat_period_id%type
	,p_top integer
	,p_min_games_played integer = 1
)
returns table(
	 top_rank bigint
	,player_name ss.player.player_name%type
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
select * from ss.get_top_versus_players_by_avg_rating(17, 5, 3);
select * from ss.get_top_versus_players_by_avg_rating(17, 5);
*/

declare
	l_initial_rating ss.stat_tracking.initial_rating%type;
begin
	if p_min_games_played < 1 then
		p_min_games_played := 1;
	end if;

	select st.initial_rating
	into l_initial_rating
	from ss.stat_period as sp
	inner join ss.stat_tracking as st
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
				from ss.player_versus_stats as pvs
				left outer join ss.player_rating as pr
					on pvs.player_id = pr.player_id
						and pvs.stat_period_id = pr.stat_period_id
				where pvs.stat_period_id = p_stat_period_id
					and pvs.games_played >= coalesce(p_min_games_played, 1)
			) as dt
		) as dt2
		inner join ss.player as p
			on dt2.player_id = p.player_id
		where dt2.top_rank <= p_top
		order by
			 dt2.top_rank
			,p.player_name;
end;
$$;

alter function ss.get_top_versus_players_by_avg_rating owner to ss_developer;

revoke all on function ss.get_top_versus_players_by_avg_rating from public;

grant execute on function ss.get_top_versus_players_by_avg_rating to ss_web_server;

create or replace function ss.get_top_versus_players_by_kills_per_minute(
	 p_stat_period_id ss.stat_period.stat_period_id%type
	,p_top integer
	,p_min_games_played integer = 1
)
returns table(
	 top_rank bigint
	,player_name ss.player.player_name%type
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
select * from ss.get_top_versus_players_by_kills_per_minute(17, 5, 3);
select * from ss.get_top_versus_players_by_kills_per_minute(17, 5);
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
		from ss.player_versus_stats as pvs
		where pvs.stat_period_id = p_stat_period_id
			and pvs.kills > 0 -- has at least one kill
			and pvs.games_played >= greatest(coalesce(p_min_games_played, 1), 1)
	) as dt
) as dt2
inner join ss.player as p
	on dt2.player_id = p.player_id
where dt2.top_rank <= p_top
order by
	 dt2.top_rank
	,p.player_name;

$$;

alter function ss.get_top_versus_players_by_kills_per_minute owner to ss_developer;

revoke all on function ss.get_top_versus_players_by_kills_per_minute from public;

grant execute on function ss.get_top_versus_players_by_kills_per_minute to ss_web_server;

create or replace function ss.insert_game_type(
	 p_game_type_name ss.game_type.game_type_name%type
	,p_game_mode_id ss.game_type.game_mode_id%type
)
returns ss.game_type.game_type_id%type
language sql
security definer
set search_path = ss, pg_temp
as
$$

/*
*/

insert into ss.game_type(
	 game_type_name
	,game_mode_id
)
values(
	 p_game_type_name
	,p_game_mode_id
)
returning
	 game_type_id;

$$;

alter function ss.insert_game_type owner to ss_developer;

revoke all on function ss.insert_game_type from public;

grant execute on function ss.insert_game_type to ss_web_server;

create or replace function ss.refresh_player_versus_stats(
	p_stat_period_id ss.stat_period.stat_period_id%type
)
returns void
language plpgsql
security definer
set search_path = ss, pg_temp
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

select * from ss.game_mode;
select * from ss.stat_period;
select * from ss.stat_period_type;
select * from ss.stat_tracking;
select * from ss.player_rating;
*/

declare
	l_game_type_id ss.game_type.game_type_id%type;
	l_stat_period_type_id ss.stat_period_type.stat_period_type_id%type;
	l_period_range ss.stat_period.period_range%type;
	l_is_rating_enabled ss.stat_tracking.is_rating_enabled%type;
	l_initial_rating ss.stat_tracking.initial_rating%type;
	l_minimum_rating ss.stat_tracking.minimum_rating%type;
begin
	select
		 st.game_type_id
		,st.stat_period_type_id
		,sp.period_range
		,st.is_rating_enabled
		,st.initial_rating
		,st.minimum_rating
	into
		 l_game_type_id
		,l_stat_period_type_id
		,l_period_range
		,l_is_rating_enabled
		,l_initial_rating
		,l_minimum_rating
	from ss.stat_period as sp
	inner join ss.stat_tracking as st
		on sp.stat_tracking_id = st.stat_tracking_id
	inner join ss.game_type as gt
		on st.game_type_id = gt.game_type_id
	where sp.stat_period_id = p_stat_period_id
		and gt.game_mode_id = 2; -- Team Versus
	
	if l_game_type_id is null or l_period_range is null then
		raise exception 'Invalid stat period specified. (%)', p_stat_period_id;
	end if;
	
	delete from ss.player_versus_stats
	where stat_period_id = p_stat_period_id;

	if l_is_rating_enabled = true then
		delete from ss.player_rating
		where stat_period_id = p_stat_period_id;
	end if;

	with cte_games as( -- NOTE: This purposely targets specific covering indexes on the ss.game table.
		-- non-league games
		select g.game_id
		from ss.game as g
		where l_stat_period_type_id <> 2 -- not a League Season stat period
			and l_period_range @> g.time_played -- match by time_played
			and g.game_type_id = l_game_type_id -- and game type
		union
		-- league games
		select g.game_id
		from ss.game as g
		where l_stat_period_type_id = 2 -- is a League Season stat period
			and g.stat_period_id = p_stat_period_id -- match on the specific stat period for the season
	)
	,cte_insert_player_rating as(
		insert into ss.player_rating(
			 player_id
			,stat_period_id
			,rating
		)
		select
			 vgtm.player_id
			,p_stat_period_id
			,greatest(l_initial_rating + sum(vgtm.rating_change), l_minimum_rating) as rating
		from cte_games as c
		inner join ss.versus_game_team_member as vgtm
			on c.game_id = vgtm.game_id
		where l_is_rating_enabled = true
		group by vgtm.player_id
	)
	insert into ss.player_versus_stats(
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
		,enemy_distance_sum
		,enemy_distance_samples
		,team_distance_sum
		,team_distance_samples
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
		,sum(enemy_distance_sum) as enemy_distance_sum
		,sum(enemy_distance_samples) as enemy_distance_samples
		,sum(team_distance_sum) as team_distance_sum
		,sum(team_distance_samples) as team_distance_samples
	from(
		select
			 vgtm.game_id
			,vgtm.player_id
			,vgt.is_winner
			,case when exists(
					select *
					from ss.versus_game_team as vgt2
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
			,vgtm.first_out & 1 <> 0 as first_out_regular
			,vgtm.first_out & 2 <> 0 as first_out_critical
			,vgtm.wasted_energy
			,vgtm.wasted_repel
			,vgtm.wasted_rocket
			,vgtm.wasted_thor
			,vgtm.wasted_burst
			,vgtm.wasted_decoy
			,vgtm.wasted_portal
			,vgtm.wasted_brick
			,enemy_distance_sum
			,enemy_distance_samples
			,team_distance_sum
			,team_distance_samples
		from cte_games as c
		inner join ss.game as g
			on c.game_id = g.game_id
		inner join ss.versus_game_team_member as vgtm
			on g.game_id = vgtm.game_id
		inner join ss.versus_game_team as vgt
			on vgtm.game_id = vgt.game_id
				and vgtm.freq = vgt.freq
	) as dt
	group by dt.player_id;
end;
$$;

alter function ss.refresh_player_versus_stats owner to ss_developer;

revoke all on function ss.refresh_player_versus_stats from public;

grant execute on function ss.refresh_player_versus_stats to ss_web_server;

drop function ss.save_game(p_game_json jsonb);
create or replace function ss.save_game(
	 p_game_json jsonb
	,p_stat_period_id ss.stat_period.stat_period_id%type = null
)
returns ss.game.game_id%type
language sql
security definer
set search_path = ss, pg_temp
as
$$

/*
Saves data for a completed game into the database.

Parameters:
p_stat_period_id - An optional, stat period that limits which stat periods the game should be saved for.
	For regular games, no period is passed. The game's stats will be applied to all of the stat periods that match the game's game type and game time.
	For league matches, the season's stat period is passed. This is so that if there are multiple active seasons with the same game type, the game's stats
	can be applied to only the season's stat period and lifetime/forever period.

p_game_json - JSON that represents the game data to save.

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
		,ss.get_or_insert_zone_server(gr.zone_server_name) as zone_server_id
		,ss.get_or_insert_arena(gr.arena) as arena_id
		,gr.box_number
		,ss.get_or_insert_lvl(gr.lvl_file_name, gr.lvl_checksum) as lvl_id
		,tstzrange(gr.start_timestamp, gr.end_timestamp, '[)') as time_played
		,gr.replay_path
		,gr.players
		,gr.solo_stats
		,gr.team_stats
		,gr.pb_stats
		,gr.events
	from jsonb_to_record(p_game_json) as gr(
		 game_type_id bigint
		,zone_server_name character varying
		,arena character varying
		,box_number int
		,lvl_file_name character varying(16)
		,lvl_checksum integer
		,start_timestamp timestamptz
		,end_timestamp timestamptz
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
		 ss.get_or_upsert_player(pe.key, pi.squad, pi.x_res, pi.y_res) as player_id
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
	insert into ss.game(
		 game_type_id
		,zone_server_id
		,arena_id
		,box_number
		,time_played
		,replay_path
		,lvl_id
		,stat_period_id
	)
	select
		 game_type_id
		,zone_server_id
		,arena_id
		,box_number
		,time_played
		,replay_path
		,lvl_id
		,p_stat_period_id
	from cte_data
	returning game.game_id
)
,cte_solo_stats as(
	select
		 par.player as player_name
		,s.value as participant_json
	from cte_data as cd
	inner join ss.game_type as gt
		on cd.game_type_id = gt.game_type_id
	cross join jsonb_array_elements(cd.solo_stats) as s
	cross join jsonb_to_record(s.value) as par(
		player character varying
	)
	where gt.game_mode_id = 1 -- 1v1
)
,cte_team_stats as(
	select
		 t.freq
		,t.is_winner
		,t.score
		,t.player_slots
	from cte_data as cd
	inner join ss.game_type as gt
		on cd.game_type_id = gt.game_type_id
	cross join jsonb_array_elements(cd.team_stats) as j
	cross join jsonb_to_record(j.value) as t(
		 freq smallint
		,is_winner boolean
		,score integer
		,player_slots jsonb
	)
	where gt.game_mode_id = 2 -- Team Versus
)
,cte_versus_team as(
	insert into ss.versus_game_team(
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
	inner join ss.game_type as gt
		on cd.game_type_id = gt.game_type_id
	cross join jsonb_array_elements(cd.pb_stats) as s
	cross join jsonb_to_record(s.value) as t(
		 freq smallint
	)
	where gt.game_mode_id = 3 -- Powerball
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
	insert into ss.solo_game_participant(
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
	insert into ss.pb_game_participant(
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
	insert into ss.pb_game_score(
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
	insert into ss.versus_game_team_member(
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
	insert into ss.game_event(
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
	insert into ss.versus_game_assign_slot_event(
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
	insert into ss.versus_game_kill_event(
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
	insert into ss.game_event_damage(
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
	insert into ss.game_ship_change_event(
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
	insert into ss.game_use_item_event(
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
	insert into ss.game_event_rating(
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
	-- regular games (p_stat_period_id is null) - apply to all stat periods that match by game_type_id and time_played
	select
		 sp.stat_period_id
		,st.is_rating_enabled
		,st.initial_rating
		,st.minimum_rating
	from cte_data as cd
	cross join ss.get_or_insert_stat_periods(cd.game_type_id, lower(cd.time_played)) as sp
	inner join stat_tracking as st
		on sp.stat_tracking_id = st.stat_tracking_id
	where p_stat_period_id is null
	union
	-- league matches (p_stat_period_id is not null) - apply to only the specified stat period and the lifetime/forever stat period
	select
		 sp.stat_period_id
		,st.is_rating_enabled
		,st.initial_rating
		,st.minimum_rating
	from cte_data as cd
	inner join ss.stat_tracking as st
		on cd.game_type_id = st.game_type_id
	inner join ss.stat_period as sp
		on st.stat_tracking_id = sp.stat_tracking_id
	where p_stat_period_id is not null
		and (sp.stat_period_id = p_stat_period_id
			or st.stat_period_type_id = 0 -- lifetime/forever
		)
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
	cross join cte_solo_game_participant as csgp
	cross join cte_stat_periods as csp
)
,cte_insert_player_solo_stats as(
	insert into ss.player_solo_stats(
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
	update ss.player_solo_stats as p
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
			,cvtm.first_out & 1 <> 0 as first_out_regular
			,cvtm.first_out & 2 <> 0 as first_out_critical
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
		cross join cte_versus_team_member as cvtm
		inner join cte_versus_team as cvt
			on cvtm.freq = cvt.freq
		cross join cte_stat_periods as csp
	) as dt
	group by -- in case the player played on multiple teams
		 dt.player_id
		,dt.stat_period_id
)
,cte_insert_player_versus_stats as(
	insert into ss.player_versus_stats(
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
			from ss.player_versus_stats as pvs
			where pvs.player_id = cpvs.player_id
				and pvs.stat_period_id = cpvs.stat_period_id
		)
	returning
		 player_id
		,stat_period_id
)
,cte_update_player_versus_stats as(
	update ss.player_versus_stats as pvs
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
	insert into ss.player_rating(
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
			from ss.player_rating as pr
			where pr.player_id = dt.player_id
				and pr.stat_period_id = csp.stat_period_id
		)
	returning
		 player_id
		,stat_period_id
)
,cte_update_player_rating as(
	update ss.player_rating as pr
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
		and pr.stat_period_id = csp.stat_period_id
		and not exists( -- TODO: this might not be needed since this cte can't see the rows inserted by cte_insert_player_rating?
			select *
			from cte_insert_player_rating as i
			where i.player_id = dt.player_id
				and i.stat_period_id = csp.stat_period_id
		)
)
,cte_update_player_ship_usage as(
	update ss.player_ship_usage as psu
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
	insert into ss.player_ship_usage(
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
			from ss.player_ship_usage as psu
			where psu.player_id = c.player_id
				and psu.stat_period_id = csp.stat_period_id
		)
)
select cm.game_id
from cte_game as cm;

$$;

alter function ss.save_game(
	 p_game_json jsonb
	,p_stat_period_id ss.stat_period.stat_period_id%type
) owner to ss_developer;

revoke all on function ss.save_game(
	 p_game_json jsonb
	,p_stat_period_id ss.stat_period.stat_period_id%type
) from public;

grant execute on function ss.save_game(
	 p_game_json jsonb
	,p_stat_period_id ss.stat_period.stat_period_id%type
) to ss_zone_server;

drop function ss.save_game_bytea(p_game_json_utf8_bytes bytea);
create or replace function ss.save_game_bytea(
	 p_game_json_utf8_bytes bytea
	,p_stat_period_id ss.stat_period.stat_period_id%type = null
)
returns ss.game.game_id%type
language sql
as
$$

/*
This function wraps the save_game function so that data can be streamed to the database server.
At the moment npgsql only supports streaming of parameters using the bytea data type.
*/

select ss.save_game(convert_from(p_game_json_utf8_bytes, 'UTF8')::jsonb, p_stat_period_id);

$$;

ALTER FUNCTION ss.save_game_bytea(bytea, ss.stat_period.stat_period_id%type)
    OWNER TO ss_developer;
	
revoke all on function ss.save_game_bytea(
	 p_game_json_utf8_bytes bytea
	,p_stat_period_id ss.stat_period.stat_period_id%type
) from public;

grant execute on function ss.save_game_bytea(
	 p_game_json_utf8_bytes bytea
	,p_stat_period_id ss.stat_period.stat_period_id%type
) to ss_zone_server;

create or replace function ss.update_game_type(
	 p_game_type_id ss.game_type.game_type_id%type
	,p_game_type_name ss.game_type.game_type_name%type
	,p_game_mode_id ss.game_type.game_mode_id%type
)
returns void
language sql
security definer
set search_path = ss, pg_temp
as
$$

/*
*/

update ss.game_type
set	 game_type_name = p_game_type_name
	,game_mode_id = p_game_mode_id
where game_type_id = p_game_type_id;

$$;

alter function ss.update_game_type owner to ss_developer;

revoke all on function ss.update_game_type from public;

grant execute on function ss.update_game_type to ss_web_server;

create or replace function league.copy_season(
	 p_season_id league.season.season_id%type
	,p_season_name league.season.season_name%type
	,p_include_players boolean
	,p_include_teams boolean
	,p_include_games boolean
	,p_include_rounds boolean
)
returns league.season.season_id%type
language sql
security definer
set search_path = league, pg_temp
as
$$

/*
Parameters:
p_season_id - The existing season to copy from.
p_season_name - The name of the new season.
p_include_teams - Whether to copy teams.
p_include_players - Whether to copy players.
p_include_games - Whether to copy games (p_include_teams must must be true).

Usage:
select league.copy_season(2, 'my copy', true, true, true, true);
*/

with cte_season as(
	insert into league.season(
		 season_name
		,league_id
	)
	select
		 p_season_name
		,s.league_id
	from league.season as s
	where s.season_id = p_season_id
	returning season_id
)
,cte_team as(
	insert into league.team(
		 team_name
		,season_id
		,banner_small
		,banner_large
		,franchise_id
	)
	select
		 t.team_name
		,cs.season_id
		,t.banner_small
		,t.banner_large
		,t.franchise_id
	from league.team as t
	cross join cte_season as cs
	where t.season_id = p_season_id
		and p_include_teams
	returning
		 team_id
		,team_name
)
,cte_team_with_old as(
	select
		 ct.team_id
		,ct.team_name
		,t.team_id as old_team_id
	from cte_team as ct
	inner join league.team as t
		on ct.team_name = t.team_name
	where t.season_id = p_season_id
)
,cte_games as(
	select
		 sg.season_game_id as old_season_game_id
		,row_number() over(order by season_game_id) as game_idx -- for matching up when inserting related records (e.g. season_game_team)
	from league.season_game as sg
	where sg.season_id = p_season_id
		and p_include_games
		and p_include_teams -- can't insert games without teams also
)
,cte_season_game as(
	insert into league.season_game(
		 season_id
		,round_number
		,game_status_id
	)
	select
		 cs.season_id
		,sg.round_number
		,1 -- Pending
	from cte_games as cg
	inner join league.season_game as sg
		on cg.old_season_game_id = sg.season_game_id
	cross join cte_season as cs
	returning season_game_id
)
,cte_season_game_with_idx as(
	select
		 season_game_id -- newly inserted id
		,row_number() over(order by season_game_id) as game_idx
	from cte_season_game
)
,cte_season_game_team as(
	insert into league.season_game_team(
		 season_game_id
		,team_id
		,freq
	)
	select
		 csg.season_game_id
		,ct.team_id
		,sgt.freq
	from cte_season_game_with_idx as csg
	inner join cte_games as cg
		on csg.game_idx = cg.game_idx
	inner join league.season_game_team as sgt
		on cg.old_season_game_id = sgt.season_game_id
	inner join cte_team_with_old as ct
		on sgt.team_id = ct.old_team_id
)
,cte_season_round as(
	insert into league.season_round(
		 season_id
		,round_number
		,round_name
		,round_description
	)
	select
		 cs.season_id
		,sr.round_number
		,sr.round_name
		,sr.round_description
	from league.season_round as sr
	cross join cte_season as cs
	where sr.season_id = p_season_id
		and p_include_rounds
)
,cte_roster as(
	insert into league.roster(
		 season_id
		,player_id
		,signup_timestamp
		,team_id
		,enroll_timestamp
		,is_captain
		,is_suspended
	)
	select
		 cs.season_id
		,r.player_id
		,r.signup_timestamp
		,ct.team_id
		,r.enroll_timestamp
		,r.is_captain
		,r.is_suspended
	from league.roster as r
	inner join cte_team_with_old as ct
		on r.team_id = ct.old_team_id
	cross join cte_season as cs
	where r.season_id = p_season_id
		and p_include_players
)
select cs.season_id
from cte_season as cs;

$$;

alter function league.copy_season owner to ss_developer;

revoke all on function league.copy_season from public;

grant execute on function league.copy_season to ss_web_server;

create or replace function league.delete_franchise(
	p_franchise_id league.franchise.franchise_id%type
)
returns void
language sql
security definer
set search_path = league, pg_temp
as
$$

/*
*/

delete from league.franchise
where franchise_id = p_franchise_id;

$$;

alter function league.delete_franchise owner to ss_developer;

revoke all on function league.delete_franchise from public;

grant execute on function league.delete_franchise to ss_web_server;

create or replace function league.delete_league(
	p_league_id league.league.league_id%type
)
returns void
language sql
security definer
set search_path = league, ss, pg_temp
as
$$

/*
select league.delete_league()

select * from league.league
*/

delete from league.league where league_id = p_league_id;

$$;

alter function league.delete_league owner to ss_developer;

revoke all on function league.delete_league from public;

grant execute on function league.delete_league to ss_web_server;

create or replace function league.delete_league_user_role(
	 p_league_id league.league.league_id%type
	,p_user_id league.league_user_role.user_id%type
	,p_league_role_id league.league_user_role.league_role_id%type
)
returns void
language sql
security definer
set search_path = league, pg_temp
as
$$

/*
Delete a record from the league.league_user_role table.
*/

delete from league.league_user_role
where league_id = p_league_id
	and user_id = p_user_id
	and league_role_id = p_league_role_id;

$$;

alter function league.delete_league_user_role owner to ss_developer;

revoke all on function league.delete_league_user_role from public;

grant execute on function league.delete_league_user_role to ss_web_server;

create or replace function league.delete_season(
	p_season_id league.season.season_id%type
)
returns void
language sql
security definer
set search_path = league, pg_temp
as
$$

/*
Usage:
select league.delete_season(123);

select * from league.season;
*/

delete from league.season where season_id = p_season_id;

$$;

alter function league.delete_season owner to ss_developer;

revoke all on function league.delete_season from public;

grant execute on function league.delete_season to ss_web_server;

create or replace function league.delete_season_game(
	p_season_game_id league.season_game.season_game_id%type
)
returns void
language sql
as
$$

/*
*/

delete from league.season_game_team
where season_game_id = p_season_game_id;

delete from league.season_game
where season_game_id = p_season_game_id;

$$;

alter function league.delete_season_game owner to ss_developer;

revoke all on function league.delete_season_game from public;

grant execute on function league.delete_season_game to ss_web_server;

create or replace function league.delete_season_player(
	 p_season_id league.season.season_id%type
	,p_player_id ss.player.player_id%type
)
returns void
language sql
security definer
set search_path = league, pg_temp
as
$$

/*

Usage:
select * from league.delete_season_player(2, 78);
select * 
from league.roster as r
inner join ss.player as p
	on r.player_id = p.player_id
where r.season_id = 4
*/

delete from league.roster as r
where r.season_id = p_season_id
	and r.player_id = p_player_id;

$$;

alter function league.delete_season_player owner to ss_developer;

revoke all on function league.delete_season_player from public;

grant execute on function league.delete_season_player to ss_web_server;

create or replace function league.delete_season_round(
	 p_season_id league.season_round.season_id%type
	,p_round_number league.season_round.round_number%type
)
returns void
language sql
security definer
set search_path = league, pg_temp
as
$$

/*
Usage:
select league.delete_season_round(2, 1);
*/

delete from league.season_round as sr
where sr.season_id = p_season_id
	and sr.round_number = p_round_number;

$$;

alter function league.delete_season_round owner to ss_developer;

revoke all on function league.delete_season_round from public;

grant execute on function league.delete_season_round to ss_web_server;

create or replace function league.delete_season_user_role(
	 p_season_id league.season.season_id%type
	,p_user_id league.season_user_role.user_id%type
	,p_season_role_id league.season_user_role.season_role_id%type
)
returns void
language sql
security definer
set search_path = league, pg_temp
as
$$

/*
Delete a record from the league.season_user_role table.
*/

delete from league.season_user_role
where season_id = p_season_id
	and user_id = p_user_id
	and season_role_id = p_season_role_id;

$$;

alter function league.delete_season_user_role owner to ss_developer;

revoke all on function league.delete_season_user_role from public;

grant execute on function league.delete_season_user_role to ss_web_server;

create or replace function league.delete_team(
	p_team_id league.team.team_id%type
)
returns void
language sql
security definer
set search_path = league, pg_temp
as
$$

/*
*/

delete from league.team
where team_id = p_team_id;

$$;

alter function league.delete_team owner to ss_developer;

revoke all on function league.delete_team from public;

grant execute on function league.delete_team to ss_web_server;

create or replace function league.end_season(
	 p_season_id league.season.season_id%type
)
returns void
language plpgsql
security definer
set search_path = league, pg_temp
as
$$

declare
	l_end_timestamp timestamptz;
begin
	l_end_timestamp :=
		coalesce(
			 (
				select max(dt.game_timestamp)
				from(
					select sg.game_timestamp
					from league.season_game as sg
					union 
					select upper(g.time_played)
					from league.season_game as sg2
					inner join ss.game as g
						on sg2.game_id = g.game_id
				) as dt
			 )
			,current_timestamp
		);
	
	update ss.stat_period as sp
	set period_range = tstzrange(lower(sp.period_range), l_end_timestamp, '[]')
	where sp.stat_period_id = (
			select s.stat_period_id
			from league.season as s
			where s.season_id = p_season_id
		)
		and upper_inf(sp.period_range); -- no upper bound yet (this is expected)
	
	update league.season
	set end_date = l_end_timestamp
	where season_id = p_season_id;
end;
$$;

alter function league.end_season owner to ss_developer;

revoke all on function league.end_season from public;

grant execute on function league.end_season to ss_web_server;

create or replace function league.get_completed_games(
	 p_season_id league.season.season_id%type
)
returns json
language sql
security definer
set search_path = league, pg_temp
as
$$

/*
Usage:
select league.get_completed_games(2);
select league.get_completed_games(4);
*/

select json_agg(row_to_json(dg) order by dg.round_number desc, dg.game_timestamp desc, dg.season_game_id)
from(
	select
		 sg.season_game_id
		,sg.round_number
		,sr.round_name
		,(coalesce(upper(g.time_played), sg.game_timestamp) at time zone 'UTC') as game_timestamp
		,(	select json_agg(row_to_json(dt))
			from(
				select
					 sgt.team_id
					,t.team_name
					,sgt.freq
					,sgt.is_winner
					,sgt.score
				from league.season_game_team as sgt
				inner join league.team as t
					on sgt.team_id = t.team_id
				where sgt.season_game_id = sg.season_game_id
				order by sgt.freq
			) as dt
		 ) as teams
		,sg.game_id
	from league.season_game as sg
	left outer join league.season_round as sr
		on sg.season_id = sr.season_id
			and sg.round_number = sr.round_number
	left outer join ss.game as g
		on sg.game_id = g.game_id
	where sg.season_id = p_season_id
		and sg.game_status_id = 3 -- Complete
) as dg


$$;

alter function league.get_completed_games owner to ss_developer;

revoke all on function league.get_completed_games from public;

grant execute on function league.get_completed_games to ss_web_server;

create or replace function league.get_franchise(
	p_franchise_id league.franchise.franchise_id%type
)
returns table(
	franchise_name league.franchise.franchise_name%type
)
language sql
security definer
set search_path = league, pg_temp
as
$$

/*
Usage:
select * from league.get_franchise(3);
*/

select f.franchise_name
from league.franchise as f
where f.franchise_id = p_franchise_id;

$$;

alter function league.get_franchise owner to ss_developer;

revoke all on function league.get_franchise from public;

grant execute on function league.get_franchise to ss_web_server;

create or replace function league.get_franchise_teams(
	 p_franchise_id league.franchise.franchise_id%type
)
returns table(
	 team_id league.team.team_id%type
	,team_name league.team.team_name%type
	,season_id league.season.season_id%type
	,season_name league.season.season_name%type
	,league_id league.league.league_id%type
	,league_name league.league.league_name%type
)
language sql
security definer
set search_path = league, pg_temp
as
$$

/*
Gets the teams that a franchise has participated as.

Usage:
select * from league.get_franchise_teams(3);

select * from league.franchise;
*/

select
	 t.team_id
	,t.team_name
	,s.season_id
	,s.season_name
	,l.league_id
	,l.league_name
from league.team as t
inner join league.season as s
	on t.season_id = s.season_id
inner join league.league as l
	on s.league_id = l.league_id
where t.franchise_id = p_franchise_id
order by coalesce(s.start_date, s.created_timestamp);

$$;

alter function league.get_franchise_teams owner to ss_developer;

revoke all on function league.get_franchise_teams from public;

grant execute on function league.get_franchise_teams to ss_web_server;

create or replace function league.get_franchises()
returns table(
	 franchise_id league.franchise.franchise_id%type
	,franchise_name league.franchise.franchise_name%type
)
language sql
security definer
set search_path = league, pg_temp
as
$$

/*
Gets all franchises.
For choosing a franchise when creating or editing a team.

Usage:
select * from league.get_franchises();
*/

select
	 franchise_id
	,franchise_name
from league.franchise
order by franchise_name;

$$;

alter function league.get_franchises owner to ss_developer;

revoke all on function league.get_franchises from public;

grant execute on function league.get_franchises to ss_web_server;

create or replace function league.get_franchises_with_teams()
returns table(
	 franchise_id league.franchise.franchise_id%type
	,franchise_name league.franchise.franchise_name%type
	,teams text[]
)
language sql
security definer
set search_path = league, pg_temp
as
$$

/*
Gets all franchises with comma delimited teams.
For viewing the full list of franchises.

Usage:
select * from league.get_franchises_with_teams();
*/

select
	 f.franchise_id
	,f.franchise_name
	,(	select array_agg(dt.team_name order by dt.last_used desc nulls last)
		from(
			select
				 t.team_name
				,max(s.start_date) as last_used
			from league.team as t
			inner join league.season as s
				on t.season_id = s.season_id
			where t.franchise_id = f.franchise_id
			group by t.team_name
		) as dt
	 ) as teams
from league.franchise as f
group by f.franchise_id
order by f.franchise_name;

$$;

alter function league.get_franchises_with_teams owner to ss_developer;

revoke all on function league.get_franchises_with_teams from public;

grant execute on function league.get_franchises_with_teams to ss_web_server;

create or replace function league.get_league(
	 p_league_id league.league.league_id%type
)
returns table(
	 league_name league.league.league_name%type
	,game_type_id ss.game_type.game_type_id%type
	,min_teams_per_game league.league.min_teams_per_game%type
	,max_teams_per_game league.league.max_teams_per_game%type
	,freq_start league.league.freq_start%type
	,freq_increment league.league.freq_increment%type
)
language sql
security definer
set search_path = league, ss, pg_temp
as
$$

/*
Usage:
select * from league.get_league(13);
*/

select
	 l.league_name
	,l.game_type_id
	,min_teams_per_game
	,max_teams_per_game
	,freq_start
	,freq_increment
from league.league as l
where l.league_id = p_league_id;

$$;

alter function league.get_league owner to ss_developer;

revoke all on function league.get_league from public;

grant execute on function league.get_league to ss_web_server;

create or replace function league.get_league_user_roles(
	 p_league_id league.league.league_id%type
)
returns table(
	 user_id league.league_user_role.user_id%type
	,league_role_id league.league_user_role.league_role_id%type
)
language sql
security definer
set search_path = league, pg_temp
as
$$

/*
Usage:
select * from league.get_league_user_roles(13);
*/

select
	 user_id
	,league_role_id
from league.league_user_role
where league_id = p_league_id

$$;

alter function league.get_league_user_roles owner to ss_developer;

revoke all on function league.get_league_user_roles from public;

grant execute on function league.get_league_user_roles to ss_web_server;

create or replace function league.get_leagues()
returns table(
	 league_id league.league.league_id%type
	,league_name league.league.league_name%type
	,game_type_id ss.game_type.game_type_id%type
)
language sql
security definer
set search_path = league, ss, pg_temp
as
$$

/*
select * from league.get_leagues();
*/

select
	 l.league_id
	,l.league_name
	,l.game_type_id
from league.league as l;

$$;

alter function league.get_leagues owner to ss_developer;

revoke all on function league.get_leagues from public;

grant execute on function league.get_leagues to ss_web_server;

create or replace function league.get_leagues_with_seasons()
returns json
language sql
security definer
set search_path = league, pg_temp
as
$$

/*
Gets the available leagues and their seasons.

Usage:
select league.get_leagues_with_seasons();
*/

select json_agg(row_to_json(dt2))
from(
	select
		 dt.league_id
		,dt.league_name
		,(	select json_agg(row_to_json(sdt))
			from(
				select
					 s.season_id
					,s.season_name
				from league.season as s
				where s.league_id = dt.league_id
				order by
					 s.start_date desc nulls last
					,s.season_name 
			) as sdt
		 ) as seasons
	from(
		select
			 l.league_id
			,l.league_name
			,(	select max(s2.start_date)
				from league.season as s2
				where s2.league_id = l.league_id
					and s2.start_date is not null
				limit 1
			) as latest_season_start_date
		from league.league as l
		where exists(
				select *
				from league.season as s
				where s.league_id = l.league_id
			)
	) as dt
	order by
		 dt.latest_season_start_date desc nulls last
		,dt.league_name
) as dt2

$$;

alter function league.get_leagues_with_seasons owner to ss_developer;

revoke all on function league.get_leagues_with_seasons from public;

grant execute on function league.get_leagues_with_seasons to ss_web_server;

create or replace function league.get_scheduled_games(
	 p_season_id league.season.season_id%type
)
returns table(
	 league_id league.league.league_id%type
	,league_name league.league.league_name%type
	,season_id league.season.season_id%type
	,season_name league.season.season_name%type
	,season_game_id league.season_game.season_game_id%type
	,round_number league.season_round.round_number%type
	,round_name league.season_round.round_name%type
	,game_timestamp league.season_game.game_timestamp%type
	,teams text
	,game_status_id league.season_game.game_status_id%type
)
language sql
security definer
set search_path = league, pg_temp
as
$$

/*
Usage:
select * from league.get_scheduled_games(null);
select * from league.get_scheduled_games(2);
--select * from league.season;
*/

select 
	 l.league_id
	,l.league_name
	,s.season_id
	,s.season_name
	,sg.season_game_id
	,sg.round_number
	,sr.round_name
	,sg.game_timestamp
	,(	select string_agg(t.team_name, ' vs ' order by freq)
		from league.season_game_team as sgt
		inner join league.team as t
			on sgt.team_id = t.team_id
		where sgt.season_game_id = sg.season_game_id
		group by sgt.season_game_id
	 ) as teams
	,sg.game_status_id
from league.season as s
inner join league.season_game as sg
	on s.season_id = sg.season_id
inner join league.league as l
	on s.league_id = l.league_id
left outer join league.season_round as sr
	on sg.season_id = sr.season_id
		and sg.round_number = sr.round_number
where s.season_id = coalesce(p_season_id, s.season_id)
	and s.start_date is not null -- season has started
	and s.end_date is null -- season is still ongoing
	and sg.game_status_id <> 3 -- not complete
order by
	 l.league_id
	,s.season_id
	,sg.game_timestamp
	,sg.game_status_id
	,sg.season_game_id;

$$;

alter function league.get_scheduled_games owner to ss_developer;

revoke all on function league.get_scheduled_games from public;

grant execute on function league.get_scheduled_games to ss_web_server;
grant execute on function league.get_scheduled_games to ss_zone_server;

create or replace function league.get_season(
	 p_season_id league.season.season_id%type
)
returns table(
	 season_name league.season.season_name%type
	,league_id league.league.league_id%type
)
language sql
security definer
set search_path = league, pg_temp
as
$$

/*
Usage:
select * from league.get_season(2);
*/

select
	 s.season_name
	,s.league_id
from league.season as s
where s.season_id = p_season_id;

$$;

alter function league.get_season owner to ss_developer;

revoke all on function league.get_season from public;

grant execute on function league.get_season to ss_web_server;

create or replace function league.get_season_details(
	p_season_id league.season.season_id%type
)
returns table(
	 season_name league.season.season_name%type
	,league_id league.league.league_id%type
	,league_name league.league.league_name%type
	,created_timestamp league.season.created_timestamp%type
	,start_date league.season.start_date%type
	,end_date league.season.end_date%type
	,stat_period_id league.season.stat_period_id%type
	,stat_period_range ss.stat_period.period_range%type
	,league_game_type_id ss.game_type.game_type_id%type
	,league_game_type_name ss.game_type.game_type_name%type
	,league_game_mode_id ss.game_mode.game_mode_id%type
	,stats_game_type_id ss.game_type.game_type_id%type
	,stats_game_type_name ss.game_type.game_type_name%type
	,stats_game_mode_id ss.game_mode.game_mode_id%type
)
language sql
security definer
set search_path = league, pg_temp
as
$$

/*
Usage:
select * from league.get_season_details(2);
*/

select
	 s.season_name
	,l.league_id
	,l.league_name
	,s.created_timestamp
	,s.start_date
	,s.end_date
	,sp.stat_period_id
	,sp.period_range
	,l.game_type_id as league_game_type_id
	,lgt.game_type_name as league_game_type_name
	,lgt.game_mode_id as league_game_mode_id
	,st.game_type_id as stats_game_type_id
	,sgt.game_type_name as stats_game_type_name
	,sgt.game_mode_id as stats_game_mode_id
from league.season as s
inner join league.league as l
	on s.league_id = l.league_id
inner join ss.game_type as lgt
	on l.game_type_id = lgt.game_type_id
left outer join ss.stat_period as sp
	on s.stat_period_id = sp.stat_period_id
left outer join ss.stat_tracking as st
	on sp.stat_tracking_id = st.stat_tracking_id
left outer join ss.game_type as sgt
	on st.game_type_id = sgt.game_type_id
where s.season_id = p_season_id;

$$;

alter function league.get_season_details owner to ss_developer;

revoke all on function league.get_season_details from public;

grant execute on function league.get_season_details to ss_web_server;

create or replace function league.get_season_game(
	p_season_game_id league.season_game.season_game_id%type
)
returns json
language sql
security definer
set search_path = league, pg_temp
as
$$

/*
Gets details about a season's game.

Parameters:
p_season_game_id - ID of the game to get info about.

Returns: 
json containing information about the game.
This includes the teams that in the match and their rosters.

Example:
{
  "game_type_id": 15,
  "game_mode_id": 2,
  "league_name": "Test 2v2 league",
  "season_name": "2v2 - Season 1",
  "round_number": 1,
  "game_timestamp": null,
  "teams": [
    {
      "freq": 10,
      "team_id": 1,
      "team_name": "ONE",
      "roster": {
        "foo": false,
        "bar": false
      }
    },
    {
      "freq": 20,
      "team_id": 2,
      "team_name": "Team 2",
      "roster": {
        "G": false,
        "asdf": false
      }
    }
  ]
}

Usage:
select league.get_season_game(23);
*/

select to_json(dg.*)
from(
	select
		 sg.season_game_id
		,sg.season_id
		,sg.round_number
		,sg.game_timestamp AT TIME ZONE 'UTC' as game_timestamp
		,sg.game_id
		,sg.game_status_id
		,(	select json_agg(to_json(dt))
			from(
				select
					 sgt.team_id
					,sgt.freq
					,sgt.score
					,sgt.is_winner
				from league.season_game_team as sgt
				where sgt.season_game_id = sg.season_game_id
				order by sgt.freq
			) as dt
		) as teams
	from league.season_game as sg
	where sg.season_game_id = p_season_game_id
) as dg;

$$;

alter function league.get_season_game owner to ss_developer;

revoke all on function league.get_season_game from public;

grant execute on function league.get_season_game to ss_web_server;

create or replace function league.get_season_game_start_info(
	p_season_game_id league.season_game.season_game_id%type
)
returns json
language sql
as
$$

/*
Gets details about a season's game.

Parameters:
p_season_game_id - ID of the game to get info about.

Returns: 
json containing information about the game.
This includes the teams that in the match and their rosters.

Example:
{
  "game_type_id": 15,
  "game_mode_id": 2,
  "league_name": "Test 2v2 league",
  "season_name": "2v2 - Season 1",
  "round_number": 1,
  "game_timestamp": null,
  "teams": [
    {
      "freq": 10,
      "team_id": 1,
      "team_name": "ONE",
      "roster": {
        "foo": false,
        "bar": false
      }
    },
    {
      "freq": 20,
      "team_id": 2,
      "team_name": "Team 2",
      "roster": {
        "G": false,
        "asdf": false
      }
    }
  ]
}

Usage:
select league.get_season_game_start_info(23);
*/

select to_json(dt.*)
from(
	select
		 sg.season_game_id
		,l.game_type_id
		,l.league_id
		,l.league_name
		,s.season_id
		,s.season_name
		,sg.round_number
		,sr.round_name
		,sg.game_timestamp
		,(	select json_object_agg(dt2.freq, json_build_object('team_id', dt2.team_id, 'team_name', dt2.team_name, 'roster', dt2.roster))
			from(
				select
					 sgt.freq
					,sgt.team_id
					,t.team_name
					,(	select json_object_agg(p.player_name, r.is_captain)
						from league.roster as r
						inner join ss.player as p
							on r.player_id = p.player_id
						where r.team_id = sgt.team_id
							and r.is_suspended = false
					 ) as roster
				from league.season_game_team as sgt
				inner join league.team as t
					on sgt.team_id = t.team_id
				where sgt.season_game_id = sg.season_game_id
				order by sgt.freq
			) as dt2
		 ) as teams
	from league.season_game as sg
	inner join league.season as s
		on sg.season_id = s.season_id
	inner join league.league as l
		on s.league_id = l.league_id
	left outer join league.season_round as sr
		on sg.season_id = sr.season_id
			and sg.round_number = sr.round_number
	where sg.season_game_id = p_season_game_id
) as dt;

$$;

alter function league.get_season_game_start_info owner to ss_developer;

revoke all on function league.get_season_game_start_info from public;

grant execute on function league.get_season_game_start_info to ss_zone_server;

create or replace function league.get_season_games(
	p_season_id league.season.season_id%type
)
returns json
language sql
security definer
set search_path = league, pg_temp
as
$$

/*
Gets the games for a season.

Parameters:
p_season_id - ID of the season to get.

Returns: 
JSON representing the games in the season

Usage:
select * from league.get_season_games(2);
select * from league.get_season_games(4);
*/

select coalesce(json_agg(to_json(dg)))
from(
	select
		 sg.season_game_id
		,sg.season_id
		,sg.round_number
		,(coalesce(upper(g.time_played), sg.game_timestamp) at time zone 'UTC') as game_timestamp
		,sg.game_id
		,sg.game_status_id
		,(	select json_agg(to_json(dt))
			from(
				select
					 sgt.team_id
					,sgt.freq
					,sgt.score
					,sgt.is_winner
				from league.season_game_team as sgt
				where sgt.season_game_id = sg.season_game_id
				order by sgt.freq
			) as dt
		) as teams
	from league.season_game as sg
	left outer join ss.game as g
		on sg.game_id = g.game_id
	where sg.season_id = p_season_id
	order by
		 (coalesce(upper(g.time_played), sg.game_timestamp) at time zone 'UTC') desc nulls first
		,sg.round_number desc
		,sg.season_game_id
) as dg

$$;

alter function league.get_season_games owner to ss_developer;

revoke all on function league.get_season_games from public;

grant execute on function league.get_season_games to ss_web_server;

create or replace function league.get_season_player(
	 p_season_id league.season.season_id%type
	,p_player_name ss.player.player_name%type
)
returns table(
	 player_id ss.player.player_id%type
	,player_name ss.player.player_name%type
	,team_id league.roster.team_id%type
	,is_captain league.roster.is_captain%type
	,is_suspended league.roster.is_suspended%type
)
language sql
security definer
set search_path = league, pg_temp
as
$$

/*

Usage:
select * from league.get_season_player(2, 'foo');
*/

select
	 p.player_id
	,p.player_name -- sending this back so that the any case differences will be seen
	,r.team_id
	,r.is_captain
	,r.is_suspended
from league.roster as r
inner join ss.player as p
	on r.player_id = p.player_id
where r.season_id = p_season_id
	and p.player_name = p_player_name;

$$;

alter function league.get_season_player owner to ss_developer;

revoke all on function league.get_season_player from public;

grant execute on function league.get_season_player to ss_web_server;

create or replace function league.get_season_players(
	p_season_id league.season.season_id%type
)
returns table(
	 player_id ss.player.player_id%type
	,player_name ss.player.player_name%type
	,signup_timestamp league.roster.signup_timestamp%type
	,team_id league.roster.team_id%type
	,enroll_timestamp league.roster.enroll_timestamp%type
	,is_captain league.roster.is_captain%type
	,is_suspended league.roster.is_suspended%type
)
language sql
security definer
set search_path = league, pg_temp
as
$$

/*
Usage:
select * from league.get_season_players(2);
*/

select
	 r.player_id
	,p.player_name
	,r.signup_timestamp
	,r.team_id
	,r.enroll_timestamp
	,r.is_captain
	,r.is_suspended
from league.roster as r
inner join ss.player as p
	on r.player_id = p.player_id
where r.season_id = p_season_id;

$$;

alter function league.get_season_players owner to ss_developer;

revoke all on function league.get_season_players from public;

grant execute on function league.get_season_players to ss_web_server;

create or replace function league.get_season_round(
	 p_season_id league.season_round.season_id%type
	,p_round_number league.season_round.round_number%type
)
returns table(
	 round_name league.season_round.round_name%type
	,round_description league.season_round.round_description%type
)
language sql
security definer
set search_path = league, pg_temp
as
$$

/*
Usage:
select * from league.get_season_round(2, 1);
*/

select
	 sr.round_name
	,sr.round_description
from league.season_round as sr
where sr.season_id = p_season_id
	and sr.round_number = p_round_number;

$$;

alter function league.get_season_round owner to ss_developer;

revoke all on function league.get_season_round from public;

grant execute on function league.get_season_round to ss_web_server;

create or replace function league.get_season_rounds(
	p_season_id league.season.season_id%type
)
returns table(
	 round_number league.season_round.round_number%type
	,round_name league.season_round.round_name%type
	,round_description league.season_round.round_description%type
)
language sql
security definer
set search_path = league, pg_temp
as
$$

/*
Usage:
select * from league.get_season_rounds(2);
*/

select
	 sr.round_number
	,sr.round_name
	,sr.round_description
from league.season_round as sr
where sr.season_id = p_season_id
order by sr.round_number;

$$;

alter function league.get_season_rounds owner to ss_developer;

revoke all on function league.get_season_rounds from public;

grant execute on function league.get_season_rounds to ss_web_server;

create or replace function league.get_season_teams(
	p_season_id league.season.season_id%type
)
returns table(
	 team_id league.team.team_id%type
	,team_name league.team.team_name%type
	,banner_small league.team.banner_small%type
	,banner_large league.team.banner_large%type
	,is_enabled league.team.is_enabled%type
	,franchise_id league.team.franchise_id%type
)
language sql
security definer
set search_path = league, pg_temp
as
$$

/*
Usage:
select * from league.get_season_teams(2);
*/

select
	 t.team_id
	,t.team_name
	,t.banner_small
	,t.banner_large
	,t.is_enabled
	,t.franchise_id
from league.team as t
where t.season_id = p_season_id
order by t.team_name;

$$;

alter function league.get_season_teams owner to ss_developer;

revoke all on function league.get_season_teams from public;

grant execute on function league.get_season_teams to ss_web_server;

create or replace function league.get_season_user_roles(
	 p_season_id league.season.season_id%type
)
returns table(
	 user_id league.season_user_role.user_id%type
	,season_role_id league.season_user_role.season_role_id%type
)
language sql
security definer
set search_path = league, pg_temp
as
$$

/*
Usage:
select * from league.get_season_user_roles(2);
*/

select
	 user_id
	,season_role_id
from league.season_user_role
where season_id = p_season_id

$$;

alter function league.get_season_user_roles owner to ss_developer;

revoke all on function league.get_season_user_roles from public;

grant execute on function league.get_season_user_roles to ss_web_server;

create or replace function league.get_seasons(
	 p_league_id league.league.league_id%type
)
returns table(
	 season_id league.season.season_id%type
	,season_name league.season.season_name%type
	,created_timestamp league.season.created_timestamp%type
)
language sql
security definer
set search_path = league, pg_temp
as
$$

/*
Usage:
select * from league.get_seasons(13);
select * from league.league;
*/

select
	 s.season_id
	,s.season_name
	,s.created_timestamp
from league.season as s
where s.league_id = p_league_id
order by s.created_timestamp desc;

$$;

alter function league.get_seasons owner to ss_developer;

revoke all on function league.get_seasons from public;

grant execute on function league.get_seasons to ss_web_server;

create or replace function league.get_standings(
	p_season_id league.season.season_id%type
)
returns table(
	 team_id league.team.team_id%type
	,team_name league.team.team_name%type
	,wins league.team.wins%type
	,losses league.team.losses%type
	,draws league.team.draws%type
	-- TODO: Strength of Schedule (SOS)
)
language sql
security definer
set search_path = league, pg_temp
as
$$

/*
select * from league.get_standings(2);
*/

select
	 t.team_id
	,t.team_name
	,t.wins
	,t.losses
	,t.draws
from league.team as t
where t.season_id = p_season_id
order by 
	 (wins-losses) desc
	,draws desc
	,team_name

$$;

alter function league.get_standings owner to ss_developer;

revoke all on function league.get_standings from public;

grant execute on function league.get_standings to ss_web_server;
grant execute on function league.get_standings to ss_zone_server;

create or replace function league.get_team(
	p_team_id league.team.team_id%type
)
returns table(
	 team_name league.team.team_name%type
	,season_id league.team.season_id%type
	,banner_small league.team.banner_small%type
	,banner_large league.team.banner_large%type
	,is_enabled league.team.is_enabled%type
	,franchise_id league.team.franchise_id%type
)
language sql
security definer
set search_path = league, pg_temp
as
$$

/*
Usage:
select * from league.get_team(1);
*/

select
	 t.team_name
	,t.season_id
	,t.banner_small
	,t.banner_large
	,t.is_enabled
	,t.franchise_id
from league.team as t
where t.team_id = p_team_id;

$$;

alter function league.get_team owner to ss_developer;

revoke all on function league.get_team from public;

grant execute on function league.get_team to ss_web_server;

create or replace function league.get_team_games(
	 p_team_id league.team.team_id%type
)
returns table(
	 season_game_id league.season_game.season_game_id%type
	,round_number league.season_game.round_number%type
	,round_name league.season_round.round_name%type
	,game_timestamp timestamp with time zone
	,game_id league.season_game.game_id%type
	,teams text
	,win_lose_draw char(1)
	,scores text
)
language sql
security definer
set search_path = league, pg_temp
as
$$

/*
Gets league games for a team. This includes both, games that have been played and games that have not yet been played.
Games that have been played will have a game_id.

Usage:
select * from league.get_team_games(1);

select * from league.team;
select * from league.season_game_team where team_id = 1
select * from league.season_game
*/

select
	 sg.season_game_id
	,sg.round_number
	,sr.round_name
	,coalesce(upper(g.time_played), sg.game_timestamp) as game_timestamp
	,sg.game_id
	,(	select string_agg(t.team_name, ' vs ' order by freq)
		from league.season_game_team as sgt2
		inner join league.team as t
			on sgt2.team_id = t.team_id
		where sgt2.season_game_id = sg.season_game_id
	 ) as teams -- TODO: maybe send back a json array of strings instead and let the UI decide how to format it
 	,case when exists(
		 	select *
			from ss.game as g
			inner join ss.game_type as gt
				on g.game_type_id = gt.game_type_id
			where g.game_id = sg.game_id
				and gt.game_mode_id = 2 -- Team Versus
		)
		then( -- Team Versus
			case when exists(
					select *
					from ss.versus_game_team as vgt
					where vgt.game_id = sg.game_id
						and vgt.freq = sgt.freq
						and vgt.is_winner
				)
				then 'W' -- win
				else case when exists(
						select *
						from ss.versus_game_team as vgt
						where vgt.game_id = sg.game_id
							and vgt.freq <> sgt.freq
							and vgt.is_winner
					)
					then 'L' -- lose
					else 'D' -- draw
				end
			end
		)
	 end as win_lose_draw
	,(	select string_agg(cast(sgt2.score as text), ' - ' order by freq)
		from league.season_game_team as sgt2
		where sgt2.season_game_id = sgt.season_game_id
	 ) as scores
from league.season_game_team as sgt
inner join league.season_game as sg
	on sgt.season_game_id = sg.season_game_id
left outer join league.season_round as sr
	on sg.season_id = sr.season_id
		and sg.round_number = sr.round_number
left outer join ss.game as g
	on sg.game_id = g.game_id
where sgt.team_id = p_team_id
order by
	 sg.round_number desc
	,coalesce(upper(g.time_played), sg.game_timestamp)desc nulls first
	,sg.season_game_id

$$;

alter function league.get_team_games owner to ss_developer;

revoke all on function league.get_team_games from public;

grant execute on function league.get_team_games to ss_web_server;
grant execute on function league.get_team_games to ss_zone_server;

create or replace function league.get_team_id(
	 p_season_id league.team.season_id%type
	,p_team_name league.team.team_name%type
)
returns league.team.team_id%type
language sql
security definer
set search_path = league, pg_temp
as
$$

/*
Gets the ID of a team by name.

Usage:
select league.get_team_id(2, 'one');
select league.get_team_id(2, 'ONE');
select league.get_team_id(2, 'Team 2');
select league.get_team_id(2, 'blah');
*/

select t.team_id
from league.team as t
where t.season_id = p_season_id
	and t.team_name = p_team_name;

$$;

alter function league.get_team_id owner to ss_developer;

revoke all on function league.get_team_id from public;

grant execute on function league.get_team_id to ss_web_server;
grant execute on function league.get_team_id to ss_zone_server;

create or replace function league.get_team_roster(
	p_team_id league.team.team_id%type
)
returns table(
	 player_id league.roster.player_id%type
	,player_name ss.player.player_name%type
	,is_captain league.roster.is_captain%type
	,is_suspended league.roster.is_suspended%type
	,enroll_timestamp league.roster.enroll_timestamp%type
)
language sql
security definer
set search_path = league, pg_temp
as
$$

/*
Usage:
select * from league.get_team_roster(1);
select * from league.get_team_roster(2);
select * from league.get_team_roster(3);
select * from league.get_team_roster(4);
*/

select
	 r.player_id
	,p.player_name
	,r.is_captain
	,r.is_suspended
	,r.enroll_timestamp
from league.roster as r
inner join ss.player as p
	on r.player_id = p.player_id
where r.team_id = p_team_id
order by
	 r.is_captain desc
	,p.player_name;

$$;

alter function league.get_team_roster owner to ss_developer;

revoke all on function league.get_team_roster from public;

grant execute on function league.get_team_roster to ss_web_server;
grant execute on function league.get_team_roster to ss_zone_server;

create or replace function league.get_team_with_season_info(
	p_team_id league.team.team_id%type
)
returns table(
	 team_name league.team.team_name%type
	,banner_small league.team.banner_small%type
	,banner_large league.team.banner_large%type
	,is_enabled league.team.is_enabled%type
	,franchise_id league.team.franchise_id%type
	,franchise_name league.franchise.franchise_name%type
	,league_id league.league.league_id%type
	,league_name league.league.league_name%type
	,season_id league.season.season_id%type
	,season_name league.season.season_name%type
	,wins league.team.wins%type
	,losses league.team.losses%type
	,draws league.team.draws%type
)
language sql
security definer
set search_path = league, pg_temp
as
$$

/*
Usage:
select * from league.get_team_with_season_info(1);
*/

select
	 t.team_name
	,t.banner_small
	,t.banner_large
	,t.is_enabled
	,t.franchise_id
	,f.franchise_name
	,l.league_id
	,l.league_name
	,s.season_id
	,s.season_name
	,t.wins
	,t.losses
	,t.draws
from league.team as t
inner join league.season as s
	on t.season_id = s.season_id
inner join league.league as l
	on s.league_id = l.league_id
left outer join league.franchise as f
	on t.franchise_id = f.franchise_id
where t.team_id = p_team_id;

$$;

alter function league.get_team_with_season_info owner to ss_developer;

revoke all on function league.get_team_with_season_info from public;

grant execute on function league.get_team_with_season_info to ss_web_server;

create or replace function league.get_latest_seasons_with_standings(
	p_league_ids bigint[]
)
returns json
language sql
security definer
set search_path = league, pg_temp
as
$$

/*
Usage:
select league.get_latest_seasons_with_standings(ARRAY[13, 12]);
select league.get_latest_seasons_with_standings(ARRAY[13133, 3112]);
*/

select json_agg(dt2)
from(
	select
		 dt.league_id
		,l.league_name
		,dt.season_id
		,s.season_name
		,(select coalesce(json_agg(get_standings), '[]'::json) from league.get_standings(dt.season_id)) as standings
	from(
		select
			 p.league_id
			,p.league_order
			,(	select s.season_id
				from league.season as s
				where s.league_id = p.league_id
					and s.start_date is not null
				order by start_date desc
				limit 1
			) as season_id
		from unnest(p_league_ids) with ordinality as p(league_id, league_order)
	) as dt
	inner join league.league as l
		on dt.league_id = l.league_id
	inner join league.season as s
		on dt.season_id = s.season_id
	order by league_order
) as dt2;

$$;

alter function league.get_latest_seasons_with_standings owner to ss_developer;

revoke all on function league.get_latest_seasons_with_standings from public;

grant execute on function league.get_latest_seasons_with_standings to ss_web_server;

create or replace function league.get_season_rosters(
	p_season_id league.season.season_id%type
)
returns json
language sql
security definer
set search_path = league, pg_temp
as
$$

/*
Usage
select league.get_season_rosters(2);
*/

select json_agg(dt)
from(
	select
		 t.team_id
		,t.team_name
		,t.banner_small
		,t.banner_large
		,(select coalesce(json_agg(get_team_roster), '[]'::json) from league.get_team_roster(t.team_id)) as roster
	from league.team as t
	where t.season_id = p_season_id
		and t.is_enabled
	order by t.team_name
) as dt;

$$;

alter function league.get_season_rosters owner to ss_developer;

revoke all on function league.get_season_rosters from public;

grant execute on function league.get_season_rosters to ss_web_server;

create or replace function league.insert_franchise(
	p_franchise_name league.franchise.franchise_name%type
)
returns league.franchise.franchise_id%type
language sql
security definer
set search_path = league, pg_temp
as

$$

/*
Usage:
select * from league.insert_franchise('testing 123');

select * from league.franchise
*/

insert into league.franchise(franchise_name)
values(p_franchise_name)
returning franchise_id;

$$;

alter function league.insert_franchise owner to ss_developer;

revoke all on function league.insert_franchise from public;

grant execute on function league.insert_franchise to ss_web_server;

create or replace function league.insert_league(
	 p_league_name league.league.league_name%type
	,p_game_type_id league.league.game_type_id%type
	,p_min_teams_per_game league.league.min_teams_per_game%type
	,p_max_teams_per_game league.league.max_teams_per_game%type
	,p_freq_start league.league.freq_start%type
	,p_freq_increment league.league.freq_increment%type
)
returns league.league.league_id%type
language sql
security definer
set search_path = league, ss, pg_temp
as
$$

/*
Usage:
select * from league.insert_league('SVS Pro League', 12, 2, 2, 10, 10);
select * from league.insert_league('SVS Intermediate League', 12, 2, 2, 10, 10);
select * from league.insert_league('SVS Amateur League', 12, 2, 2, 10, 10);
select * from league.insert_league('SVS United League', 12, 2, 2, 10, 10);
select * from league.insert_league('SVS Draft League', 12, 2, 2, 10, 10);
select * from league.insert_league('Test 2v2 league', 2, 2, 2, 10, 10);

select * from league.league;
*/

insert into league.league(
	 league_name
	,game_type_id
	,min_teams_per_game
	,max_teams_per_game
	,freq_start
	,freq_increment
)
values(
	 p_league_name
	,p_game_type_id
	,p_min_teams_per_game
	,p_max_teams_per_game
	,p_freq_start
	,p_freq_increment
)
returning
	 league_id;

$$;

alter function league.insert_league owner to ss_developer;

revoke all on function league.insert_league from public;

grant execute on function league.insert_league to ss_web_server;

create or replace function league.insert_league_user_role(
	 p_league_id league.league.league_id%type
	,p_user_id league.league_user_role.user_id%type
	,p_league_role_id league.league_user_role.league_role_id%type
)
returns void
language sql
security definer
set search_path = league, pg_temp
as
$$

/*
Inserts a record into the league.league_user_role table.
*/

insert into league.league_user_role(
	 league_id
	,user_id
	,league_role_id
)
values(
	 p_league_id
	,p_user_id
	,p_league_role_id
);

$$;

alter function league.insert_league_user_role owner to ss_developer;

revoke all on function league.insert_league_user_role from public;

grant execute on function league.insert_league_user_role to ss_web_server;

create or replace function league.insert_season(
	 p_season_name league.season.season_name%type
	,p_league_id league.season.league_id%type
)
returns league.season.season_id%type
language sql
security definer
set search_path = league, pg_temp
as
$$

/*
Usage:
select * from league.insert_season('2v2 - Season 1', 13);

select * from league.season;
*/

insert into league.season(season_name, league_id)
values(p_season_name, p_league_id)
returning season_id;

$$;

alter function league.insert_season owner to ss_developer;

revoke all on function league.insert_season from public;

grant execute on function league.insert_season to ss_web_server;

create or replace function league.insert_season_game(
	 p_season_id league.season_game.season_id%type
	,p_round_number league.season_game.round_number%type
	,p_game_timestamp league.season_game.game_timestamp%type
	,p_game_status_id league.season_game.game_status_id%type
	,p_team_json jsonb
)
returns league.season_game.season_game_id%type
language sql
security definer
set search_path = league, pg_temp
as
$$

/*
Inserts a season game.

team_json: json describing the season_game_team data

Example of inserting a new match (when p_game_status_id = 1)
[
	{
		"team_id" : 123,
		"freq" : 10,
	},
	{
		"team_id" : 456,
		"freq" : 20,
	}
]

Example of inserting an completed match (when p_game_status_id = 3):
[
	{
		"team_id" : 123,
		"freq" : 10,
		"is_winner" : true,
		"score" : 6
	},
	{
		"team_id" : 456,
		"freq" : 20,
		"is_winner" : false,
		"score" : 2
	}
]

Usage:
select * from league.insert_season_game(2, 2, '2025-08-28', '{3, 1}');
select * from league.insert_season_game(2, 2, '2025-08-28', '{2, 4}');

select * from league.season_game;
select * from league.team;

select * from league.team;
select * from league.season_game where season_game_id = 38;
select * from league.season_game_team where season_game_id = 38;

select * from league.delete_season_game(38);
*/

with cte_season_game as(
	insert into league.season_game(
		 season_id
		,round_number
		,game_timestamp
		,game_status_id
	)
	values(
		 p_season_id
		,p_round_number
		,p_game_timestamp
		,p_game_status_id
	)
	returning season_game_id
)
,cte_season_game_team as(
	insert into league.season_game_team(
		 season_game_id
		,team_id
		,freq
		,is_winner
		,score
	)
	select
		 csg.season_game_id
		,t.team_id
		,t.freq
		,t.is_winner
		,t.score
	from cte_season_game as csg
	cross join jsonb_array_elements(p_team_json) as a
	cross join jsonb_to_record(a.value) as t(
		 team_id bigint
		,freq int
		,is_winner boolean
		,score int
	)
)
select season_game_id 
from cte_season_game;

$$;

alter function league.insert_season_game owner to ss_developer;

revoke all on function league.insert_season_game from public;

grant execute on function league.insert_season_game to ss_web_server;

create or replace function league.insert_season_games_for_round_with_2_teams(
	 p_season_id league.season.season_id%type
	,p_permutations boolean
)
returns table(
	season_game_id league.season_game.season_game_id%type
)
language sql
security definer
set search_path = league, pg_temp
as
$$

/*
Usage:
select * from league.insert_season_games_for_round_with_2_teams(2, false);
select * from league.insert_season_games_for_round_with_2_teams(2, true);

-- delete from league.season_game_team;
-- delete from league.season_game;
select * from league.season_game;
select * from league.season_game_team;
*/

-- TODO: add a column to ss.game_type to tell how many teams play in a match, for now assuming 2

with cte_team as(
	select st.team_id
	from league.team as st
	where st.season_id = p_season_id
		and st.is_enabled = true -- excludes teams that have been eliminated
)
,cte_game_team as(
	select
		 row_number() over(order by t1.team_id, t2.team_id) as game_idx
		,t1.team_id as team1_id
		,t2.team_id as team2_id
	from cte_team as t1
	cross join cte_team as t2
	where t1.team_id <> t2.team_id -- teams don't play against themselves
		and (p_permutations = true -- permutations: order matters (T1 vs T2, T2 vs T1) - home and away games
			or t1.team_id < t2.team_id -- combinations: order does not matter (T1 vs T2)
		)
)
,cte_season_game as(
	insert into league.season_game(
		 season_id
		,round_number
		,game_status_id
	)
	select
		 p_season_id
		,coalesce(
			 (	select max(round_number) + 1
				from league.season_game as sg
				where sg.season_id = p_season_id
			 )
			,1
		 ) as round_number
		,1 as game_status_id -- Pending
	from cte_game_team as cgt
	returning
		 season_game.season_game_id
)
,cte_season_game_with_idx as(
	select
		 csg.season_game_id
		,row_number() over(order by season_game_id) as game_idx
	from cte_season_game as csg
)
,cte_league_setting as(
	select
		 l.freq_start
		,l.freq_increment
	from league.season as s
	inner join league.league as l
		on s.league_id = l.league_id
	where s.season_id = p_season_id
	
)
,cte_season_game_team as(
	insert into league.season_game_team(
		 season_game_id
		,team_id
		,freq
		,is_winner
		,score
	)
	select
		 dt2.season_game_id
		,dt2.team_id
		,dt2.freq
		,false
		,null
	from(
		select
			 dt.season_game_id
			,dt.team_id
			,ls.freq_start + (team_idx * ls.freq_increment) as freq
		from(
			select
				 csg.season_game_id
				,cgt.team1_id as team_id
				,0 as team_idx
			from cte_season_game_with_idx as csg
			inner join cte_game_team as cgt
				on csg.game_idx = cgt.game_idx
			union
			select
				 csg.season_game_id
				,cgt.team2_id as team_id
				,1 as team_idx
			from cte_season_game_with_idx as csg
			inner join cte_game_team as cgt
				on csg.game_idx = cgt.game_idx
		) as dt
		cross join cte_league_setting as ls
	) as dt2
)
select csg.season_game_id
from cte_season_game as csg;

$$;

alter function league.insert_season_games_for_round_with_2_teams owner to ss_developer;

revoke all on function league.insert_season_games_for_round_with_2_teams from public;

grant execute on function league.insert_season_games_for_round_with_2_teams to ss_web_server;

create or replace function league.insert_season_players(
	 p_season_id league.season.season_id%type
	,p_player_names character varying(20)[]
	,p_team_id league.team.team_id%type
)
returns void
language sql
security definer
set search_path = league, pg_temp
as
$$

/*
Signs up players for a season. Optionally, with a team specified.

This is only an insert. It is not an upsert.
If a player is already signed up, that record is not updated (even if team differs).

Usage:
select league.insert_season_players(2, ARRAY['foo', 'bar'], null);
*/

with cte_players as(
	select ss.get_or_insert_player(dt.player_name) as player_id
	from(
		select distinct t.player_name collate ss.case_insensitive
		from unnest(p_player_names) as t(player_name)
	) as dt
)
insert into league.roster(
	 season_id
	,player_id
	,team_id
	,enroll_timestamp
)
select
	 p_season_id
	,c.player_id
	,p_team_id
	,case when p_team_id is null then null else current_timestamp end as enroll_timestamp
from cte_players as c
where not exists(
		select *
		from league.roster as r
		where r.season_id = p_season_id
			and r.player_id = c.player_id
	);

$$;

alter function league.insert_season_players owner to ss_developer;

revoke all on function league.insert_season_players from public;

grant execute on function league.insert_season_players to ss_web_server;

create or replace function league.insert_season_round(
	 p_season_id league.season_round.season_id%type
	,p_round_number league.season_round.round_number%type
	,p_round_name league.season_round.round_name%type
	,p_round_description league.season_round.round_description%type
)
returns void
language sql
security definer
set search_path = league, pg_temp
as
$$

/*
Usage:
select league.insert_season_round(2, 1, 'Round 1', null);
*/

insert into league.season_round(
	 season_id
	,round_number
	,round_name
	,round_description
)
values(
	 p_season_id
	,p_round_number
	,p_round_name
	,p_round_description
);

$$;

alter function league.insert_season_round owner to ss_developer;

revoke all on function league.insert_season_round from public;

grant execute on function league.insert_season_round to ss_web_server;

create or replace function league.insert_season_user_role(
	 p_season_id league.season.season_id%type
	,p_user_id league.season_user_role.user_id%type
	,p_season_role_id league.season_user_role.season_role_id%type
)
returns void
language sql
security definer
set search_path = league, pg_temp
as
$$

/*
Inserts a record into the league.season_user_role table.
*/

insert into league.season_user_role(
	 season_id
	,user_id
	,season_role_id
)
values(
	 p_season_id
	,p_user_id
	,p_season_role_id
);

$$;

alter function league.insert_season_user_role owner to ss_developer;

revoke all on function league.insert_season_user_role from public;

grant execute on function league.insert_season_user_role to ss_web_server;

create or replace function league.insert_team(
	 p_team_name league.team.team_name%type
	,p_season_id league.team.season_id%type
	,p_banner_small league.team.banner_small%type
	,p_banner_large league.team.banner_large%type
	,p_franchise_id league.team.franchise_id%type
)
returns league.team.team_id%type
language sql
security definer
set search_path = league, pg_temp
as
$$

/*
select * from league.insert_team('ONE', 2, null, null);
select * from league.insert_team('Team 2', 2, null, null);
select * from league.insert_team('Team Three', 2, null, null);
select * from league.insert_team('4our', 2, null, null);

select * from league.team;
*/

insert into league.team(
	 team_name
	,season_id
	,banner_small
	,banner_large
	,franchise_id
)
values(
	 p_team_name
	,p_season_id
	,p_banner_small
	,p_banner_large
	,p_franchise_id
)
returning
	team_id;
	
$$;

alter function league.insert_team owner to ss_developer;

revoke all on function league.insert_team from public;

grant execute on function league.insert_team to ss_web_server;

create or replace function league.is_league_manager(
	 p_user_id text
	,p_league_id league.league.league_id%type
)
returns boolean
language sql
security definer
set search_path = league, pg_temp
as
$$

select
	exists(
		select *
		from league.league_user_role
		where user_id = p_user_id
			and league_id = p_league_id
			and league_role_id = 1 -- Manager
	);

$$;

alter function league.is_league_manager owner to ss_developer;

revoke all on function league.is_league_manager from public;

grant execute on function league.is_league_manager to ss_web_server;

create or replace function league.is_league_or_season_manager(
	 p_user_id text
	,p_season_id league.season.season_id%type
)
returns boolean
language sql
security definer
set search_path = league, pg_temp
as
$$

select
	exists(
		select *
		from league.season_user_role as sur
		where sur.user_id = p_user_id
			and sur.season_id = p_season_id
			and sur.season_role_id = 1 -- Manager
	)
	or exists(
		select *
		from league.season as s
		inner join league.league_user_role as lur
			on s.league_id = lur.league_id
		where s.season_id = p_season_id
			and lur.user_id = p_user_id
			and lur.league_role_id = 1 -- Manager
	);

$$;

alter function league.is_league_or_season_manager owner to ss_developer;

revoke all on function league.is_league_or_season_manager from public;

grant execute on function league.is_league_or_season_manager to ss_web_server;

create or replace function league.refresh_team_stats(
	p_team_id league.team.team_id%type
)
returns void
language sql
security definer
set search_path = league, pg_temp
as
$$

/*
Refreshes a team's stats (wins/losses/draws).
*/

update league.team as t
set  wins = dt2.wins
	,losses = dt2.losses
	,draws = dt2.draws
from(
	select
		 count(*) filter(where dt.win_lose_draw = 'W') as wins
		,count(*) filter(where dt.win_lose_draw = 'L') as losses
		,count(*) filter(where dt.win_lose_draw = 'D') as draws
	from(
		select
			case 
				when sgt.is_winner then 'W'
				when exists(
						select *
						from league.season_game_team as sgt2
						where sgt2.season_game_id = sgt.season_game_id
							and sgt2.team_id <> p_team_id
							and sgt2.is_winner
					)
					then 'L'
				else 'D'
			 end win_lose_draw
		from league.season_game_team as sgt
		inner join league.season_game as sg
			on sgt.season_game_id = sg.season_game_id
		where sgt.team_id = p_team_id
			and sg.game_status_id = 3 -- Complete
	) as dt
) as dt2
where t.team_id = p_team_id;

$$;

alter function league.refresh_team_stats owner to ss_developer;

revoke all on function league.refresh_team_stats from public;

grant execute on function league.refresh_team_stats to ss_web_server;
grant execute on function league.refresh_team_stats to ss_zone_server;

create or replace function league.refresh_season_team_stats(
	p_season_id league.season.season_id%type
)
returns void
language sql
security definer
set search_path = league, pg_temp
as
$$

/*
Refreshes the team stats (wins/losses/draws) of all teams in a season.
This is useful if a match is added or edited as complete with manually entered scores, or if a previously completed match is deleted.
*/

select league.refresh_team_stats(t.team_id)
from league.team as t
where t.season_id = p_season_id;

$$;

alter function league.refresh_season_team_stats owner to ss_developer;

revoke all on function league.refresh_season_team_stats from public;

grant execute on function league.refresh_season_team_stats to ss_web_server;

create or replace function league.save_game(
	 p_season_game_id league.season_game.season_game_id%type
	,p_game_json jsonb
)
returns game.game_id%type
language plpgsql
security definer
set search_path = league, pg_temp
as
$$

/*
Saves a league game.
*/

declare
	l_game_id ss.game.game_id%type;
begin
	-- Save the game data and store resulting game_id in the season_game record.
	update league.season_game as sg
	set  game_id = ss.save_game(p_game_json, s.stat_period_id)
		,game_status_id = 3 -- Complete
	from league.season as s
	where sg.season_game_id = p_season_game_id
		and sg.season_id = s.season_id
	returning game_id
	into l_game_id;

	-- Update season_game_team with the results for each participating team.
	if exists(
		select *
		from ss.game as g
		inner join ss.game_type as gt
			on g.game_type_id = gt.game_type_id
		where g.game_id = l_game_id
			and gt.game_mode_id = 2 -- Team Versus
	) then
		-- Team Versus
		update league.season_game_team as sgt
		set  is_winner = dt.is_winner
			,score = dt.score
		from(
			select
				 vgt.freq
				,vgt.is_winner
				,vgt.score
			from ss.versus_game_team as vgt
			where vgt.game_id = l_game_id
		) as dt
		where sgt.season_game_id = p_season_game_id
			and sgt.freq = dt.freq;
	end if;

	-- Refresh team stats (wins, losses, draws) for all the teams that particpated.
	perform league.refresh_team_stats(sgt.team_id)
	from league.season_game_team as sgt
	where sgt.season_game_id = p_season_game_id;

	return l_game_id;
end;

$$;

alter function league.save_game owner to ss_developer;

revoke all on function league.save_game from public;

grant execute on function league.save_game to ss_zone_server;

create or replace function league.save_game_bytea(
	 p_season_game_id league.season_game.season_game_id%type
	,p_game_json_utf8_bytes bytea
)
returns ss.game.game_id%type
language sql
as
$$

/*
This function wraps the save_game function so that data can be streamed to the database server.
At the moment npgsql only supports streaming of parameters using the bytea data type.
*/

select league.save_game(p_season_game_id, convert_from(p_game_json_utf8_bytes, 'UTF8')::jsonb);

$$;

alter function league.save_game_bytea owner to ss_developer;

revoke all on function league.save_game_bytea from public;

grant execute on function league.save_game_bytea to ss_zone_server;

create or replace function league.start_game(
	 p_season_game_id league.season_game.season_game_id%type
	,p_force boolean
)
returns table(
	 code integer
	,game_json json
)
language plpgsql
security definer
set search_path = league, pg_temp
as
$$

/*
Starts a league game.
This is intended to be called by a zone server when announcing a game.
This could happen by an automated process based on league.season_game.game_timestamp, 
or manually by an league referee (perhaps a command like: ?startleaguegame <season game id>).
The return value tells the zone if it should continue or abort.

TODO: If we want to allow captains to start a game, then we'll have to also check the game_timestamp too.

Normally, the game will be in the "In Progress" state when this is called.
Alternatively, if the game already is "In Progress", it can be overriden with the p_force parameter.
This might be useful if the game was rescheduled or there was a problem such as the zone server crashing.
The idea is that a league referee could force restart a match (perhaps a command like: ?startleaguegame -f <season game id>).

Parmeters:
p_season_game_id - The season game to start.
p_force - True to force the update (when already "In Progress")

Returns: a single record
code: 
	200 - success 
	404 - not found (invalid p_season_game_id)
	409 - failed (p_season_game_id was valid, but it could not be updated due to being in the wrong state and/or p_force not being true)
(based on http status codes)

game_json:
	When code = 200 (success), json containing information about the game.
	See the league.get_season_game function for details.
	The league game mode logic uses this to control which players can join each freq and play.

Usage:
select * from league.start_game(23, false);
select * from league.start_game(999999999, false); -- test 404
--select * from league.season_game;
--update league.season_game set game_status_id = 1 where season_game_id = 23
*/

begin
	update league.season_game as sg
	set game_status_id = 2 -- in progress
	where sg.season_game_id = p_season_game_id
		and exists(
			select *
			from league.season as s
			where s.season_id = sg.season_id
				and s.start_date is not null -- season is started
				and s.end_date is null -- season has not ended
		)
		and(sg.game_status_id = 1 -- pending
			or (sg.game_status_id = 2 -- in progress
				and p_force = true
			)
		);

	if FOUND then
		return query
			select 
				 200 as code -- success
				,league.get_season_game_start_info(p_season_game_id) as game_json;
	elsif not exists(select * from league.season_game where season_game_id = p_season_game_id) then
		return query
			select 
				 404 as code -- not found (invalid p_season_game_id)
				,null::json as teams_json;
	else
		return query
			select 
				 409 as code -- failed (p_season_game_id was valid, but it could not be updated due to being in the wrong state and/or p_force not being true)
				,null::json as teams_json;
	end if;
end;

$$;

alter function league.start_game owner to ss_developer;

revoke all on function league.start_game from public;

grant execute on function league.start_game to ss_zone_server;

create or replace function league.start_season(
	 p_season_id league.season.season_id%type
	,p_start_date league.season.start_date%type
)
returns void
language plpgsql
security definer
set search_path = league, pg_temp
as
$$

/*
Starts a season.
This creates:
- the lifetime/forever stat tracking records for the league's game type
- the stat tracking records for the season
The season is updated with a start date and the stat period.

Parameters:
p_season_id - The season to start.
p_start_date - The start date. null means use the current date.

Usage:
select league.start_season(2, '2025-09-13');
select league.start_season(3, '2020-01-24');
select league.start_season(4, '2025-09-20');

select * from league.season;
select * from ss.stat_tracking;
select * from ss.stat_period;
*/

declare
	l_game_type_id ss.game_type.game_type_id%type;
	l_stat_tracking_id ss.stat_tracking.stat_tracking_id%type;
	l_stat_period_id ss.stat_period.stat_period_id%type;
begin
	if p_start_date is null then
		p_start_date := current_date;
	end if;

	if not exists(
		select * from league.season where season_id = p_season_id
	) then
		raise exception 'Invalid season_id specified. (%)', p_season_id;
	end if;

	if exists(
		select * from league.season where season_id = p_season_id and (start_date is not null or stat_period_id is not null)
	) then
		raise exception 'The season was already started previously. (%)', p_season_id;
	end if;

	--
	-- Create the lifetime/forever stat tracking records for the game type if they doesn't already exist.
	--
	
	perform ss.get_or_insert_lifetime_stat_tracking(l.game_type_id)
	from league.season as s
	inner join league.league as l
		 on s.league_id = l.league_id
	where s.season_id = p_season_id;

	--
	-- Create the stat tracking records for the season.
	--
	
	select st.stat_tracking_id
	into l_stat_tracking_id
	from league.season as s
	inner join league.league as l
		 on s.league_id = l.league_id
	inner join ss.stat_tracking as st
		on l.game_type_id = st.game_type_id
			and st.stat_period_type_id = 2 -- league season
	where s.season_id = p_season_id;

	if l_stat_tracking_id is null then
		insert into ss.stat_tracking(
			 game_type_id
			,stat_period_type_id
			,is_auto_generate_period
			,is_rating_enabled
			,initial_rating
			,minimum_rating
		)
		select
			 dt.game_type_id
			,2 -- league season
			,false
			,true
			,500
			,100
		from(
			select l.game_type_id
			from league.season as s
			inner join league.league as l
				on s.league_id = l.league_id
			where s.season_id = p_season_id
		) as dt
		returning stat_tracking_id
		into strict l_stat_tracking_id;
	end if;

	insert into ss.stat_period(
		 stat_tracking_id
		,period_range
	)
	values(
		 l_stat_tracking_id
		,tstzrange(p_start_date, null, '[)')
	)
	returning stat_period_id
	into strict l_stat_period_id;

	--
	-- Update the season as being started
	--
	
	update league.season as s
	set start_date = p_start_date
		,stat_period_id = l_stat_period_id
	where s.season_id = p_season_id
		and s.start_date is null 
		and s.stat_period_id is null;
end;

$$;

alter function league.start_season owner to ss_developer;

revoke all on function league.start_season from public;

grant execute on function league.start_season to ss_web_server;

create or replace function league.undo_end_season(
	 p_season_id league.season.season_id%type
)
returns void
language plpgsql
security definer
set search_path = league, pg_temp
as
$$

begin
	update ss.stat_period as sp
	set period_range = tstzrange(lower(sp.period_range), null, '[)')
	where sp.stat_period_id = (
			select s.stat_period_id
			from league.season as s
			where s.season_id = p_season_id
		);
	
	update league.season
	set end_date = null
	where season_id = p_season_id;
end;
$$;

alter function league.undo_end_season owner to ss_developer;

revoke all on function league.undo_end_season from public;

grant execute on function league.undo_end_season to ss_web_server;

create or replace function league.update_franchise(
	 p_franchise_id league.franchise.franchise_id%type
	,p_franchise_name league.franchise.franchise_name%type
)
returns void
language sql
security definer
set search_path = league, pg_temp
as
$$

/*
*/

update league.franchise
set franchise_name = p_franchise_name
where franchise_id = p_franchise_id;

$$;

alter function league.update_franchise owner to ss_developer;

revoke all on function league.update_franchise from public;

grant execute on function league.update_franchise to ss_web_server;

create or replace function league.update_league(
	 p_league_id league.league.league_id%type
	,p_league_name league.league.league_name%type
	,p_game_type_id league.league.game_type_id%type
	,p_min_teams_per_game league.league.min_teams_per_game%type
	,p_max_teams_per_game league.league.max_teams_per_game%type
	,p_freq_start league.league.freq_start%type
	,p_freq_increment league.league.freq_increment%type
)
returns void
language sql
security definer
set search_path = league, pg_temp
as
$$

/*
*/

update league.league
set  league_name = p_league_name
	,game_type_id = p_game_type_id
	,min_teams_per_game = p_min_teams_per_game
	,max_teams_per_game = p_max_teams_per_game
	,freq_start = p_freq_start
	,freq_increment = p_freq_increment
where league_id = p_league_id;

$$;

alter function league.update_league owner to ss_developer;

revoke all on function league.update_league from public;

grant execute on function league.update_league to ss_web_server;

create or replace function league.update_season(
	 p_season_id league.season.season_id%type
	,p_season_name league.season.season_name%type
)
returns void
language sql
security definer
set search_path = league, pg_temp
as
$$

/*
Usage:
select league.update_season(2, '2v2 Season 1')
select * from league.season;
*/

update league.season
set  season_name = p_season_name
where season_id = p_season_id;

$$;

alter function league.update_season owner to ss_developer;

revoke all on function league.update_season from public;

grant execute on function league.update_season to ss_web_server;

create or replace function league.update_season_game(
	 p_game_json jsonb
)
returns void
language sql
security definer
set search_path = league, pg_temp
as
$$

/*
select * from league.season_game_team where season_game_id = 134;
select * from league.season_game where season_game_id = 134;
--delete from league.season_game;
--delete from league.season_game_team;
*/

with cte_game as(
	select
		 season_game_id
		,round_number
		,game_timestamp
		,game_status_id
		,teams
	from jsonb_to_record(p_game_json) as(
		 season_game_id bigint
		,round_number int
		,game_timestamp timestamptz
		,game_status_id bigint
		,teams jsonb
	)
)
,cte_team as(
	select
		 team_id
		,freq
		,is_winner
		,score
	from cte_game as cg
	cross join jsonb_to_recordset(cg.teams) as(
		 team_id bigint
		,freq smallint
		,is_winner boolean
		,score integer
	)
)
,cte_update_season_game as(
	update league.season_game as sg
	set  round_number = cg.round_number
		,game_timestamp = cg.game_timestamp
		,game_status_id = cg.game_status_id
	from cte_game as cg
	where sg.season_game_id = cg.season_game_id
)
,cte_delete_season_game_team as(
	delete from league.season_game_team as sgt
	where sgt.season_game_id = (select season_game_id from cte_game)
		and sgt.team_id not in(
			select team_id
			from cte_team
		)
)
,cte_update_season_game_team as(
	update league.season_game_team as sgt
	set  freq = ct.freq
		,is_winner = ct.is_winner
		,score = ct.score
	from cte_team as ct
	where sgt.season_game_id = (select season_game_id from cte_game)
		and sgt.team_id = ct.team_id
)
insert into league.season_game_team(
	 season_game_id
	,team_id
	,freq
	,is_winner
	,score
)
select
	 cg.season_game_id
	,ct.team_id
	,ct.freq
	,ct.is_winner
	,ct.score
from cte_game as cg
cross join cte_team as ct
where not exists(
		select *
		from league.season_game_team as sgt
		where sgt.season_game_id = cg.season_game_id
			and sgt.team_id = ct.team_id
	);
$$;

alter function league.update_season_game owner to ss_developer;

revoke all on function league.update_season_game from public;

grant execute on function league.update_season_game to ss_web_server;

create or replace function league.update_season_player(
	 p_season_id league.season.season_id%type
	,p_player_id ss.player.player_id%type
	,p_team_id league.roster.team_id%type
	,p_is_captain league.roster.is_captain%type
	,p_is_suspended league.roster.is_suspended%type
)
returns void
language sql
security definer
set search_path = league, pg_temp
as
$$

/*

Usage:
select * from league.update_season_player(2, 78, null, true, false);
*/

update league.roster as r
set  team_id = p_team_id
	,enroll_timestamp = 
		case when p_team_id is null then null
			when p_team_id = r.team_id then r.enroll_timestamp
			else current_timestamp
		end
	,is_captain = p_is_captain
	,is_suspended = p_is_suspended
where r.season_id = p_season_id
	and r.player_id = p_player_id;

$$;

alter function league.update_season_player owner to ss_developer;

revoke all on function league.update_season_player from public;

grant execute on function league.update_season_player to ss_web_server;

create or replace function league.update_season_round(
	 p_season_id league.season_round.season_id%type
	,p_round_number league.season_round.round_number%type
	,p_round_name league.season_round.round_name%type
	,p_round_description league.season_round.round_description%type
)
returns void
language sql
security definer
set search_path = league, pg_temp
as
$$

/*
Usage:
select league.update_season_round(2, 1, 'Round One', null);
*/

update league.season_round
set
	 round_name = p_round_name
	,round_description = p_round_description
where season_id = p_season_id
	and round_number = p_round_number;

$$;

alter function league.update_season_round owner to ss_developer;

revoke all on function league.update_season_round from public;

grant execute on function league.update_season_round to ss_web_server;

create or replace function league.update_team(
	 p_team_id league.team.team_id%type
	,p_team_name league.team.team_name%type
	,p_banner_small league.team.banner_small%type
	,p_banner_large league.team.banner_large%type
	,p_franchise_id league.team.franchise_id%type
)
returns void
language sql
security definer
set search_path = league, pg_temp
as
$$

/*
*/

update league.team
set  team_name = p_team_name
	,banner_small = p_banner_small
	,banner_large = p_banner_large
	,franchise_id = p_franchise_id
where team_id = p_team_id;

$$;

alter function league.update_team owner to ss_developer;

revoke all on function league.update_team from public;

grant execute on function league.update_team to ss_web_server;
