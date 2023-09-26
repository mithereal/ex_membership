# Since configuration is shared in umbrella projects, this file
# should only configure the :api application itself
# and only for organization purposes. All other config goes to
# the umbrella root.
import Config

config :logger, :console, format: "[$level] $message\n"

# Configure your database
config :ex_membership, Membership.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "ex_membership",
  hostname: "localhost",
  port: 5432,
  pool_size: 10,
  primary_key_type: :uuid

config :logger,
  level: :info
