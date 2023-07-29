# For tasks/generators testing
Mix.start()
Mix.shell(Mix.Shell.Process)

ExUnit.start()

Ecto.Adapters.SQL.Sandbox.mode(Membership.Repo, :manual)

{:ok, _} = Application.ensure_all_started(:ex_machina)
