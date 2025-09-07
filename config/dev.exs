import Config

config :ex_membership,
  ecto_repos: [Membership.TestRepo],
  ecto_repo: Membership.TestRepo,
  primary_key_type: :uuid

config :ex_membership, Membership.TestRepo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "ex_membership",
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  pool_size: 10,
  port: 55432

config :mix_test_watch,
  clear: true
