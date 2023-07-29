defmodule Membership.MembersEntitiesTest do
  use Membership.EctoCase
  alias Membership.MembersEntities

  describe "Membership.MembersEntities.create/3" do
    test "creates entity relation for member" do
      member = insert(:member)
      struct = insert(:role)
      abilities = ["test_ability"]

      MembersEntities.create(member, struct, abilities)

      member = member |> Repo.preload([:entities])

      assert 1 == length(member.entities)
      assert "elixir_membership_role" == Enum.at(member.entities, 0).assoc_type
    end

    test "creates entity relation for member without abilities" do
      member = insert(:member)
      struct = insert(:role)

      MembersEntities.create(member, struct)

      member = member |> Repo.preload([:entities])

      assert 1 == length(member.entities)
      assert "elixir_membership_role" == Enum.at(member.entities, 0).assoc_type
    end
  end
end
