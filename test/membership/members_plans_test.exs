defmodule Membership.MemberPlansTest do
  use Membership.EctoCase
  alias Membership.MemberPlans

  describe "Membership.MemberPlans.create/3" do
    test "creates entity relation for member" do
      member = insert(:member)
      struct = insert(:plan)
      features = ["test_feature"]

      MemberPlans.create(member, struct, features)
      repo = Membership.Repo.repo()
      member = member |> repo.preload([:plans])

      assert 1 == length(member.plans)
    end

    test "creates entity relation for member without features" do
      member = insert(:member)
      struct = insert(:plan)

      MemberPlans.create(member, struct)
      repo = Membership.Repo.repo()
      member = member |> repo.preload([:plans])

      assert 1 == length(member.plans)
    end
  end
end
