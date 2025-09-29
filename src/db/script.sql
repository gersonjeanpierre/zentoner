create table customers (
  id uuid primary key,
  type_person varchar(32),
  type_client varchar(32),
  phone varchar(20),
  full_name varchar(140),
  social_reason varchar(150),
  dni varchar(8),
  ruc varchar(11),
  ce varchar(16),
  email varchar(140),
  is_active boolean default true
);
