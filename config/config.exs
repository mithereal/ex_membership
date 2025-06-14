# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
import Config

config :ex_membership,
  ecto_repos: [Membership.TestRepo],
  primary_key_type: :uuid

config :ex_membership, Membership.TestRepo,
  username: "postgres",
  password: "postgres",
  database: "ex_membership",
  hostname: "localhost"

if File.exists?(Path.join(Path.dirname(__ENV__.file), "#{Mix.env()}.exs")) do
  import_config "#{Mix.env()}.exs"
end
