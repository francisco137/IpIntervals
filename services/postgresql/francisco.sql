BEGIN TRANSACTION;

CREATE TABLE ranges (
  ipFr VARCHAR,
  ipTo VARCHAR
);

CREATE INDEX ranges_idx_01 ON ranges (ipFr);
CREATE INDEX ranges_idx_02 ON ranges (ipTo);

COMMIT;
