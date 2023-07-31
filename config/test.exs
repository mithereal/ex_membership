# Since configuration is shared in umbrella projects, this file
# should only configure the :api application itself
# and only for organization purposes. All other config goes to
# the umbrella root.
use Mix.Config

# Configure your database
config :ex_membership, Membership.Repo,
  username: "postgres",
  password: "postgres",
  database: "ex_membership",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox,
port: 55432

config :logger,
  level: :info
