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