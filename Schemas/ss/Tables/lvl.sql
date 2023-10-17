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
    OWNER to postgres;