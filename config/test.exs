# Since configuration is shared in umbrella projects, this file
# should only configure the :api application itself
# and only for organization purposes. All other config goes to
# the umbrella root.
import Config

# Configure your database
config :ex_membership,
  ecto_repos: [Membership.TestRepo],
  ecto_repo: Membership.TestRepo,
  primary_key_type: :uuid

config :ex_membership, Membership.TestRepo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "ex_membership",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

config :logger,
  level: :info
