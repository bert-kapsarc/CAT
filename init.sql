CREATE TABLE users (
  ID SERIAL PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  wallet VARCHAR(255) NOT NULL
);

INSERT INTO users (name, wallet)
VALUES  ('foo', '0xfb645a584cb19d7d3f1dbe77feade85c76388bc3');
