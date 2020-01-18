CREATE TABLE users (
  ID SERIAL PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  wallet VARCHAR(255) NOT NULL UNIQUE,
  stamper boolean
);
DELETE from users;
INSERT INTO users (name, wallet)
VALUES  ('seller', '0xf3af07fda6f11b55e60ab3574b3947e54debadf7');
INSERT INTO users (name, wallet)
VALUES  ('buyer', '0xfb645a584cb19d7d3f1dbe77feade85c76388bc3');
