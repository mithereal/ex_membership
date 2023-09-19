# defmodule Post do
#  use Membership
#
#  alias Membership.Repo
#
#  def delete(id \\ 1, member_id \\ 1) do
#    member = load_and_authorize_member(%Membership.Member{id: member_id})
#
#    member_permissions do
#      # or
#      has_plan("gold", "delete_post")
#      # or
#      has_plan("bronze", "delete_post")
#      # or
#      has_feature("delete_posts", "delete_post")
#
#      #      calculated_member(fn member ->
#      #        member.email_confirmed?
#      #      end)
#    end
#
#    as_member(member, "delete_post") do
#      :ok
#    end
#
#    # Notice that you can use both macros or functions
#
#    case member_authorized?() do
#      :ok -> :ok
#      {:error, message} -> "Raise error"
#      _ -> "Raise error"
#    end
#  end
# end
