import Config

config :ex_membership, Membership.TestRepo,
  username: "postgres",
  password: "postgres",
  database: "ex_membership",
  hostname: "localhost",
  primary_key_type: :uuid,
  port: 5432

config :ex_membership, repo: Membership.TestRepo

config :mix_test_watch,
  clear: true
