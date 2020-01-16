ALTER TABLE users ADD stamper boolean;
ALTER TABLE users ADD UNIQUE (wallet);

INSERT INTO users (name, wallet)
VALUES  ('seller', '0xf3af07fda6f11b55e60ab3574b3947e54debadf7');
INSERT INTO users (name, wallet)
VALUES  ('buyer', '0xfb645a584cb19d7d3f1dbe77feade85c76388bc3');
