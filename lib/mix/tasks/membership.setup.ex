defmodule Mix.Tasks.Membership.Setup do
  use Mix.Task

  @shortdoc "Setup membership tables"

  def run(_argv) do
    Mix.Tasks.Ecto.Migrate.run(["-r", "Membership.Repo"])
  end
end
