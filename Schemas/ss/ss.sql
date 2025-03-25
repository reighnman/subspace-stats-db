-- SCHEMA: ss

-- DROP SCHEMA IF EXISTS ss ;

CREATE SCHEMA IF NOT EXISTS ss
    AUTHORIZATION ss_developer;

GRANT ALL ON SCHEMA ss TO ss_developer;

GRANT USAGE ON SCHEMA ss TO ss_web_server;

GRANT USAGE ON SCHEMA ss TO ss_zone_server;