defmodule Membership.PlanTest do
  use Membership.EctoCase
  alias Membership.Plan

  describe "Membership.Plan.changeset/2" do
    test "changeset is invalid" do
      changeset = Plan.changeset(%Plan{}, %{})

      refute changeset.valid?
    end

    test "changeset is valid" do
      changeset = Plan.changeset(%Plan{}, %{identifier: "gold", name: "gold"})

      assert changeset.valid?
    end
  end

  describe "Membership.Plan.build/2" do
    test "builds correct changeset" do
      classic_changeset =
        Plan.changeset(%Plan{}, %{
          identifier: "delete_accounts",
          name: "Can delete accounts",
          features: []
        })

      built_changeset = Plan.build("delete_accounts", "Can delete accounts")

      assert built_changeset == classic_changeset
    end
  end
end
