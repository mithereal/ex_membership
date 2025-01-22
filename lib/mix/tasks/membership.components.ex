defmodule Mix.Tasks.Membership.Components do
  @moduledoc """
    After configuring your default ecto repo in `:ecto_repos`
    Run mix membership.components to generates a `membership_components` component,
    which has basic phoenix membership components.
  """

  def run([args]) do
    source =
      Path.join(
        Application.app_dir(:ex_membership, "/priv"),
        "/phoenix_components.ex"
      )

    target =
      Path.join(
        File.cwd!(),
        ["/lib/#{args}_web/components", "/membership_components.ex"]
      )

    Mix.Generator.copy_file(source, target)
  end
end
