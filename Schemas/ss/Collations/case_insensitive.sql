-- Collation: case_insensitive;

-- DROP COLLATION IF EXISTS ss.case_insensitive;

CREATE COLLATION IF NOT EXISTS ss.case_insensitive (provider = icu, locale = 'und-u-ks-level2', deterministic = false);

ALTER COLLATION ss.case_insensitive
    OWNER TO ss_developer;