defmodule Post do
  use Membership, registry: :test

  def update(_id \\ 1, member_id \\ nil, function_name \\ "update_post") do
    member = load_and_authorize_member(%{member_id: member_id})
    # member = nil

    permissions do
      # or check 1st arg for being an atom vs string
      has_plan(:gold, function_name)
      # or
      has_plan(:bronze, function_name)
      # or
      has_feature(:delete_posts, function_name)
    end

    case authorized?(member, function_name) do
      :ok -> {:ok, "Post was Updated"}
      {:error, message} -> {:error, message}
      _ -> "Raise error"
    end
  end

  def delete_post(id \\ 1, member_id \\ 1, function_name \\ :delete_post) do
    member =
      load_and_authorize_member(%Membership.Member{id: member_id})

    permissions do
      # or check 1st arg for being an atom vs string
      has_plan(:gold, function_name)
      # or
      has_plan(:bronze, function_name)
      # or
      has_feature(:delete_posts, function_name)

      #      calculated(fn member ->
      #        member.email_confirmed?
      #      end)
    end

    #    as_authorized(function_name) do
    #      :ok
    #    end

    # Notice that you can use both macros or functions

    case authorized?(member, function_name) do
      :ok -> {:ok, "Post #{id} was Deleted"}
      {:error, message} -> {:error, message}
      _ -> "Raise error"
    end
  end
end
