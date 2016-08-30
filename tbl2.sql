connect mkt1;


CREATE TABLE IF NOT EXISTS market (
idx  INT UNSIGNED NOT NULL AUTO_INCREMENT,
symbol CHAR(10) NOT NULL UNIQUE,
name CHAR(64),
about VARCHAR(255),
exchange CHAR(24),
cap decimal(15,2),
PRIMARY KEY (idx),
INDEX sym (symbol)
);

CREATE TABLE IF NOT EXISTS daily (
idx INT unsigned NOT NULL AUTO_INCREMENT,
market_idx INT UNSIGNED,
open decimal(10, 2),
hi decimal(10, 2),
lo decimal(10, 2),
close decimal(10, 2),
vol INT unsigned,
oi INT unsigned,
dstamp date,
split decimal(10,6) DEFAULT 1.0,
PRIMARY KEY(idx),
KEY date_key_1 (market_idx, dstamp),
KEY date_key_2 (dstamp, market_idx) 
);

CREATE TABLE IF NOT EXISTS split (
idx INT unsigned NOT NULL AUTO_INCREMENT,
midx INT UNSIGNED,
effdate date,
factor decimal(10,6),
done tinyint default 1,
PRIMARY KEY(idx),
KEY mkt_key_1 (midx),
KEY dte_key_1 (effdate)
);
