defmodule Membership.MemberPlansTest do
  use Membership.EctoCase
  alias Membership.MemberPlans

  describe "Membership.MemberPlans.create/3" do
    test "creates entity relation for member" do
      member = insert(:member)
      struct = insert(:role)
      abilities = ["test_ability"]

      MemberPlans.create(member, struct, abilities)

      member = member |> Repo.preload([:Plans])

      assert 1 == length(member.Plans)
      assert "elixir_membership_role" == Enum.at(member.Plans, 0).assoc_type
    end

    test "creates entity relation for member without abilities" do
      member = insert(:member)
      struct = insert(:role)

      MemberPlans.create(member, struct)

      member = member |> Repo.preload([:Plans])

      assert 1 == length(member.Plans)
      assert "elixir_membership_role" == Enum.at(member.Plans, 0).assoc_type
    end
  end
end
