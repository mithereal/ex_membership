defmodule Post do
  use Membership, registry: :test

  alias Membership.Repo

  def delete_post(id \\ 1, member_id \\ 1, function_name \\ :delete_post) do
    member = load_and_authorize_member(%Membership.Member{id: member_id})
    IO.puts("delete u fuck")
    IO.inspect(member)

    permissions do
      # or
      has_plan("gold", function_name)
      # or
      has_plan("bronze", function_name)
      # or
      has_feature("delete_posts", function_name)

      #      calculated(fn member ->
      #        member.email_confirmed?
      #      end)
    end

    #    as_authorized(function_name) do
    #      :ok
    #    end

    # Notice that you can use both macros or functions

    case authorized?() do
      :ok -> :ok
      {:error, _message} -> {:error, "Member is not granted to perform this action"}
      _ -> "Raise error"
    end
  end
end
