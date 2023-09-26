# Since configuration is shared in umbrella projects, this file
# should only configure the :api application itself
# and only for organization purposes. All other config goes to
# the umbrella root.
import Config

config :logger, :console, format: "[$level] $message\n"

# Configure your database
config :ex_membership, Membership.Repo,
  username: "postgres",
  password: "postgres",
  database: "ex_membership",
  hostname: "localhost",
  adapter: Ecto.Adapters.Postgres,
  port: 5432,
  primary_key_type: :uuid

config :logger,
  level: :info
