defmodule Mix.Tasks.Membership.Kaffy do
  @moduledoc """
    Run mix membership.kaffy to generates a `kaffy` components.
  """

  @shortdoc "Generate kaffy Components"

  def run([args]) do
    [
      "feature_admin.ex",
      "member_admin.ex",
      "role_admin.ex",
      "plan_admin.ex",
      "member_feature_admin.ex",
      "member_plan_admin.ex",
      "member_role_admin.ex",
      "plan_feature_admin.ex",
      "role_feature_admin.ex"
    ]
    |> Enum.each(fn x ->
      source =
        Path.join(
          Application.app_dir(:ex_membership, "/priv/kaffy"),
          "/#{x}"
        )

      target =
        Path.join(
          File.cwd!(),
          ["/lib/#{args}/kaffy", "/#{x}"]
        )

      Mix.Generator.copy_file(source, target)
    end)
  end
end
