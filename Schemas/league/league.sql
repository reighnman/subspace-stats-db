-- SCHEMA: league

-- DROP SCHEMA IF EXISTS league ;

CREATE SCHEMA IF NOT EXISTS league
    AUTHORIZATION ss_developer;

GRANT ALL ON SCHEMA league TO ss_developer;

GRANT USAGE ON SCHEMA league TO ss_web_server;

GRANT USAGE ON SCHEMA league TO ss_zone_server;