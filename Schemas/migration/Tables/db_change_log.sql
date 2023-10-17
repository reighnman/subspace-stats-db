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