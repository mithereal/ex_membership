defmodule Membership.FeatureTest do
  use Membership.EctoCase
  alias Membership.Feature
  alias Membership.Plan

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

      {_, feature} = Feature.grant(feature, plan)
      feature = Repo.get(Feature, feature.id()) |> Repo.preload(:plans)
      plan = List.first(feature.plans)
      plan = Repo.get(Membership.Plan, plan.id()) |> Repo.preload(:features)

      assert 1 == length(plan.features())
      assert feature.identifier == Enum.at(plan.features(), 0).identifier
    end

    test "grants multiple abilities to Feature" do
      plan = insert(:plan, identifier: "bronze", name: "bronze Plan")
      feature_1 = insert(:feature, identifier: "first_feature")
      feature_2 = insert(:feature, identifier: "second_feature")
      Feature.grant(plan, feature_1)
      Feature.grant(plan, feature_2)

      plan = Repo.get(Plan, plan.id()) |> Repo.preload(:features)

      identifiers =
        Enum.map(plan.features(), fn x ->
          x.identifier
        end)

      assert 2 == length(plan.features())
      assert assert ["first_feature", "second_feature"] == identifiers
    end
  end

  #
  describe "Membership.Feature.revoke/2" do
    test "rejects invalid grant" do
      assert_raise ArgumentError, fn ->
        Feature.revoke(nil, nil)
      end
    end

    test "revokes correct ability from Feature" do
      feature = insert(:feature, id: 1)
      plan = insert(:plan, id: 1)
      ban_feature = insert(:feature, identifier: "ban_accounts")

      feature_1 = Feature.grant(feature, plan)
      feature_2 = Feature.grant(plan, ban_feature)

      plan = Repo.get(Plan, plan.id()) |> Repo.preload(:features)

      assert 2 == length(plan.features())

      plan = Feature.revoke(plan, ban_feature)

      refute Enum.member?(plan.features(), "ban_accounts")
    end
  end
end
