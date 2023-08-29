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

      built_changeset = Feature.build("admin", "Global administrator")

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

      grant = Feature.grant(feature, plan)
      IO.inspect(grant, label: "grant")
      feature = Repo.get(Feature, feature.id()) |> Repo.preload(:plans)
      IO.inspect(feature, label: "fetched feature")
      assert 1 == length(plan.features())
      assert feature.identifier == Enum.at(plan.features(), 0)
    end

    #
    #    test "grant unique abilities to Feature" do
    #      plan = insert(:plan, identifier: "silver", name: "silver Plan")
    #      feature = insert(:feature, identifier: "admin_feature")
    #      Feature.grant(feature, plan)
    #      Feature.grant(feature, plan)
    #
    #      feature = Repo.get(Feature, feature.id())
    #      IO.inspect(feature)
    #      assert 1 == length(feature.abilities())
    #      assert feature.identifier == Enum.at(plan.features(), 0)
    #    end
    #
    #    test "grants multiple abilities to Feature" do
    #      plan = insert(:plan, identifier: "bronze", name: "bronze Plan")
    #      feature_1 = insert(:feature, identifier: "first_feature")
    #      feature_2 = insert(:feature, identifier: "second_feature")
    #
    #      plan = Feature.grant(plan, feature_1)
    #      Feature.grant(plan, feature_2)
    #
    #      plan = Repo.get(Plan, feature_1.id())
    #
    #      assert 2 == length(plan.features())
    #      assert assert ["first_feature", "second_feature"] == plan.features()
    #    end
  end

  #
  #  describe "Membership.Feature.revoke/2" do
  #    test "rejects invalid grant" do
  #      assert_raise ArgumentError, fn ->
  #        Feature.revoke(nil, nil)
  #      end
  #    end
  #
  #    test "revokes correct ability from Feature" do
  #      feature = insert(:feature, id: 1)
  #      plan = insert(:plan, id: 1)
  #      ban_feature = insert(:feature, identifier: "ban_accounts")
  #
  #      _feature_1 = Feature.grant(feature, plan)
  #      _feature_2 = Feature.grant(plan, feature)
  #
  #      assert 2 == length(plan.features())
  #
  #      plan = Feature.revoke(plan, ban_feature)
  #
  #      assert "ban_accounts" == Enum.at(plan.features(), 0)
  #    end
  #  end
end
