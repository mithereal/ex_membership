defmodule Mix.Tasks.Membership do
  use Mix.Task

  @spec run(any()) :: any()
  def run(_) do
    {:ok, _} = Application.ensure_all_started(:membership)
    Mix.shell().info("Membership v#{Application.spec(:membership, :vsn)}")
    Mix.shell().info("A toolkit for granular membership plan management.")
    Mix.shell().info("\nAvailable tasks:\n")
    Mix.Tasks.Help.run(["--search", "membership.", "setup"])
  end
end
