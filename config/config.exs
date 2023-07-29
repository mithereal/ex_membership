# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

config :membership,
  ecto_repos: [Membership.Repo]

config :membership, Membership.Repo,
  username: "postgres",
  password: "postgres",
  database: "ex_membership_dev",
  hostname: "localhost"

if File.exists?(Path.join(Path.dirname(__ENV__.file), "#{Mix.env()}.exs")) do
  import_config "#{Mix.env()}.exs"
end
