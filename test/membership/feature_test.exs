defmodule Membership.FeatureTest do
  use Membership.EctoCase
  alias Membership.Feature

  setup do
    Membership.load_membership_plans()
    :ok
  end

  describe "Membership.Feature.changeset/2" do
    test "changeset is invalid" do
      changeset = Feature.changeset(%Feature{}, %{})

      refute changeset.valid?
    end

    test "changeset is valid" do
      changeset = Feature.changeset(%Feature{identifier: "admin", name: "Global administrator"})

      assert changeset.valid?
    end
  end

  describe "Membership.Feature.build/3" do
    test "builds changeset" do
      classic_changeset =
        Feature.changeset(%Feature{}, %{
          identifier: "admin",
          name: "Global administrator"
        })

      built_changeset = Feature.build("admin", [], "Global administrator")

      assert built_changeset == classic_changeset
    end
  end

  describe "Membership.Feature.grant/2" do
    test "rejects invalid grant" do
      assert_raise ArgumentError, fn ->
        Feature.grant(nil, nil)
      end
    end

    test "grant Feature to Plan" do
      plan = insert(:plan, identifier: "gold", name: "Gold Plan")
      feature = insert(:feature, identifier: "admin_feature")

      Plan.grant(Feature, feature)

      feature = Repo.get(Feature, Feature.id())

      assert 1 == length(plan.features())
      assert feature.identifier == Enum.at(plan.features(), 0)
    end

    test "grant unique abilities to Feature" do
      Feature = insert(:Feature, identifier: "admin", name: "Global Administrator")
      ability = insert(:ability, identifier: "delete_accounts")

      Feature.grant(Feature, ability)
      Feature.grant(Feature, ability)

      Feature = Repo.get(Feature, Feature.id())

      assert 1 == length(Feature.abilities())
      assert ability.identifier == Enum.at(Feature.abilities(), 0)
    end

    test "grants multiple abilities to Feature" do
      Feature = insert(:Feature, identifier: "admin", name: "Global Administrator")
      ability_delete = insert(:ability, identifier: "delete_accounts")
      ability_ban = insert(:ability, identifier: "ban_accounts")

      Feature = Feature.grant(Feature, ability_delete)
      Feature.grant(Feature, ability_ban)

      Feature = Repo.get(Feature, Feature.id())

      assert 2 == length(Feature.abilities())
      assert assert ["delete_accounts", "ban_accounts"] == Feature.abilities()
    end
  end

  describe "Membership.Feature.revoke/2" do
    test "rejects invalid grant" do
      assert_raise ArgumentError, fn ->
        Feature.revoke(nil, nil)
      end
    end

    test "revokes correct ability from Feature" do
      Feature = insert(:Feature, identifier: "admin", name: "Global Administrator")
      ability = insert(:ability, identifier: "delete_accounts")
      ability_ban = insert(:ability, identifier: "ban_accounts")

      Feature = Feature.grant(Feature, ability)
      Feature = Feature.grant(Feature, ability_ban)

      assert 2 == length(Feature.abilities())

      Feature = Feature.revoke(Feature, ability)

      assert "ban_accounts" == Enum.at(Feature.abilities(), 0)
    end
  end
end
