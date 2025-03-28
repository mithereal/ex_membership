defmodule Membership.FeatureTest do
  use Membership.EctoCase
  alias Membership.Feature
  alias Membership.Plan

  @config Membership.Config.new()

  setup do
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
        |> Ecto.Changeset.apply_changes()

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

      ## return feature with plans preload
      {_, feature} = Feature.grant(feature, plan)
      feature = Repo.get(@config, Feature, feature.id) |> Repo.preload(:plans)
      plan = List.first(feature.plans)
      plan = Repo.get(@config, Membership.Plan, plan.id) |> Repo.preload(:features)

      assert 1 == length(plan.features)
      assert feature.identifier == Enum.at(plan.features, 0).identifier
    end

    test "grants multiple abilities to Feature" do
      plan = insert(:plan, identifier: "bronze", name: "bronze Plan")
      feature_1 = insert(:feature, identifier: "first_feature")
      feature_2 = insert(:feature, identifier: "second_feature")

      Feature.grant(plan, feature_1)
      Feature.grant(plan, feature_2)

      plan = Repo.get(@config, Plan, plan.id) |> Repo.preload(:features)

      identifiers =
        Enum.map(plan.features, fn x ->
          x.identifier
        end)

      assert 2 == length(plan.features)
      assert assert ["first_feature", "second_feature"] == identifiers
    end
  end

  describe "Membership.Feature.revoke/2" do
    test "rejects invalid grant" do
      assert_raise ArgumentError, fn ->
        Feature.revoke(nil, nil)
      end
    end

    test "revokes correct ability from Feature" do
      feature = insert(:feature)
      plan = insert(:plan)
      ban_feature = insert(:feature, identifier: "ban_accounts")

      Feature.grant(feature, plan)
      Feature.grant(plan, ban_feature)

      plan = Repo.get(@config, Plan, plan.id) |> Repo.preload(:features)

      assert 2 == length(plan.features)

      Feature.revoke(plan, ban_feature)

      plan = Repo.get(@config, Plan, plan.id) |> Repo.preload(:features)
      refute Enum.member?(plan.features, "ban_accounts")
    end
  end
end
