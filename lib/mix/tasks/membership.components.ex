defmodule Mix.Tasks.Membership.Components do
  @moduledoc """
    After configuring your default ecto repo in `:ecto_repos`
    Run mix membership.components to generates a `membership_components` component,
    which has basic phoenix membership components.
  """

  def run([args]) do
    source =
      Path.join(
        Application.app_dir(:ex_membership, "/lib/membership"),
        "phoenix_components.ex"
      )

    app = String.to_atom(args)

    target =
      Path.join(
        File.cwd!(),
        ["/lib/#{app}_web/components", "/membership_components.ex"]
      )

    Mix.Generator.create_file(target, source)
  end
end
