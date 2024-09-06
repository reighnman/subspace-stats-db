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