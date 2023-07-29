defmodule Membership.AbilityTest do
  use Membership.EctoCase
  alias Membership.Ability

  describe "Membership.Ability.changeset/2" do
    test "changeset is invalid" do
      changeset = Ability.changeset(%Ability{}, %{})

      refute changeset.valid?
    end

    test "changeset is valid" do
      changeset =
        Ability.changeset(%Ability{}, %{identifier: "delete_acconts", name: "Can delete accounts"})

      assert changeset.valid?
    end
  end

  describe "Membership.Ability.build/2" do
    test "builds correct changeset" do
      classic_changeset =
        Ability.changeset(%Ability{}, %{
          identifier: "delete_accounts",
          name: "Can delete accounts"
        })

      built_changeset = Ability.build("delete_accounts", "Can delete accounts")

      assert built_changeset == classic_changeset
    end
  end
end
