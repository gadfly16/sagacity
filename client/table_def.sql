CREATE TABLE asset (
    code VARCHAR(8) PRIMARY KEY,
    name TEXT,
    fractions SMALLINT
);

INSERT INTO asset (name, code, fractions) VALUES
    ('Ada', 'ADA', 6),
    ('Euro', 'EUR', 2),
    ('USA Dollar', 'USD', 2),
    ('Dogecoin', 'DOGE', 4);

CREATE TABLE partner (
    name TEXT PRIMARY KEY
);

INSERT INTO partner (name) VALUES
    ('Moric'),
    ('Mate');

CREATE TABLE market (
    name VARCHAR(8) PRIMARY KEY
);

INSERT INTO market (name) VALUES
    ('Kraken'),
    ('Binance');

CREATE TABLE slot (
    market VARCHAR(8) REFERENCES market,
    asset VARCHAR(8) REFERENCES asset,
    PRIMARY KEY (market, asset)
);

INSERT INTO slot (market, asset) VALUES
    ('Kraken', 'EUR'),
    ('Kraken', 'ADA'),
    ('Kraken', 'DOGE');

CREATE TABLE holding (
    owner TEXT REFERENCES partner,
    market VARCHAR(8),
    asset VARCHAR(8),
    volume BIGINT,
    FOREIGN KEY (market, asset) REFERENCES slot,
    PRIMARY KEY (owner, market, asset)
);

INSERT INTO holding (owner, market, asset, volume) VALUES
    ('Moric', 'Kraken', 'DOGE', 270000),
    ('Mate', 'Kraken', 'ADA', 2000000000),
    ('Mate', 'Kraken', 'EUR', 50000);