CREATE TABLE users (
  ID SERIAL PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  wallet VARCHAR(255) NOT NULL,
  stamper boolean
);
