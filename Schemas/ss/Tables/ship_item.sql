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