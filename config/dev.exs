import Config

config :ex_membership, Membership.Repo,
  username: "postgres",
  password: "postgres",
  database: "ex_membership",
  hostname: "localhost",
  primary_key_type: :uuid,
  port: 5432

config :mix_test_watch,
  clear: true
