defmodule Mix.Tasks.Membership.Install do
  @moduledoc """
    Run mix membership.install to generates a `setup_membership_tables` migration,
    which Membership tables, as well as required indexes.
  """

  def run(_args) do
    source = Path.join(Application.app_dir(:ex_membership, "/priv/"), "setup_tables.exs")

    target =
      Path.join(
        File.cwd!(),
        "/priv/repo/migrations/#{timestamp()}_setup_membership_tables.exs"
      )

    if !File.dir?(target) do
      File.mkdir_p("priv/repo/migrations/")
    end

    Mix.Generator.create_file(target, EEx.eval_file(source))
  end

  defp timestamp do
    {{y, m, d}, {hh, mm, ss}} = :calendar.universal_time()
    "#{y}#{pad(m)}#{pad(d)}#{pad(hh)}#{pad(mm)}#{pad(ss)}"
  end

  defp pad(i) when i < 10, do: <<?0, ?0 + i>>
  defp pad(i), do: to_string(i)
end
