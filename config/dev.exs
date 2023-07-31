use Mix.Config

config :ex_membership, Membership.Repo,
  username: "postgres",
  password: "postgres",
  database: "ex_membership_dev",
  hostname: "localhost",
  primary_key_type: :uuid
