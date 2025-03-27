# Since configuration is shared in umbrella projects, this file
# should only configure the :api application itself
# and only for organization purposes. All other config goes to
# the umbrella root.
import Config

# Configure your database
config :ex_membership, Membership.TestRepo,
  username: "postgres",
  password: "postgres",
  database: "ex_membership",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox,
  primary_key_type: :uuid

config :ex_membership, repo: Membership.TestRepo

config :logger,
  level: :info
