# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
import Config

config :ex_membership,
  ecto_repo: nil,
  primary_key_type: :uuid

if File.exists?(Path.join(Path.dirname(__ENV__.file), "#{Mix.env()}.exs")) do
  import_config "#{Mix.env()}.exs"
end
