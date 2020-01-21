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
INSERT INTO users (name, wallet)
VALUES  ('polluter', '0x2b9957466bc9e6b220ff3071925e5d3faef0b119');
INSERT INTO users (name, wallet)
VALUES  ('environmentalist', '0x889e90447cd5657283c35ec559587e16c779995e');
INSERT INTO users (name, wallet)
VALUES  ('stamper', '0x58eedbae12e5000de5d4500c07e6032edaa2c8a6');
INSERT INTO users (name, wallet)
VALUES  ('HeavyEmitter', '0xbC6D52c51C74B6C3A85a6357eB9822dE0D550Cf2');