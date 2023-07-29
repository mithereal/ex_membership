defmodule Membership.MemberTest do
  use Membership.EctoCase
  alias Membership.Member

  setup do
    Membership.reset_session()
    :ok
  end

  describe "Membership.Member.changeset/2" do
    test "changeset is valid" do
      changeset = Member.changeset(%Member{}, %{})

      assert changeset.valid?
    end
  end

  describe "Membership.Member.grant/2" do
    test "rejects invalid grant" do
      assert_raise ArgumentError, fn ->
        Member.grant(nil, nil)
      end
    end

    test "grant ability to member" do
      member = insert(:member)
      ability = insert(:ability, identifier: "delete_accounts")

      Member.grant(member, ability)

      member = Repo.get(Member, member.id)

      assert 1 == length(member.abilities)
      assert "delete_accounts" == Enum.at(member.abilities, 0)
    end

    test "grant ability to inherited member" do
      member = insert(:member)
      ability = insert(:ability, identifier: "delete_accounts")

      Member.grant(%{member: member}, ability)

      member = Repo.get(Member, member.id)

      assert 1 == length(member.abilities)
      assert "delete_accounts" == Enum.at(member.abilities, 0)
    end

    test "grant ability to inherited member from id" do
      member = insert(:member)
      ability = insert(:ability, identifier: "delete_accounts")

      Member.grant(%{member_id: member.id}, ability)

      member = Repo.get(Member, member.id)

      assert 1 == length(member.abilities)
      assert "delete_accounts" == Enum.at(member.abilities, 0)
    end

    test "grant only unique abilities to member" do
      member = insert(:member)
      ability = insert(:ability, identifier: "delete_accounts")

      Member.grant(member, ability)
      Member.grant(member, ability)

      member = Repo.get(Member, member.id)

      assert 1 == length(member.abilities)
      assert "delete_accounts" == Enum.at(member.abilities, 0)
    end

    test "grant different abilities to member" do
      member = insert(:member)
      ability_delete = insert(:ability, identifier: "delete_accounts")
      ability_ban = insert(:ability, identifier: "ban_accounts")

      Member.grant(member, ability_delete)
      Member.grant(member, ability_ban)

      member = Repo.get(Member, member.id)
      assert 2 == length(member.abilities)
      assert [ability_delete.identifier] ++ [ability_ban.identifier] == member.abilities
    end

    test "grant role to member" do
      member = insert(:member)
      role = insert(:role, identifier: "admin")

      Member.grant(member, role)

      member = Repo.get(Member, member.id) |> Repo.preload([:roles])

      assert 1 == length(member.roles)
      assert role == Enum.at(member.roles, 0)
    end

    test "grant role to inherited member" do
      member = insert(:member)
      role = insert(:role, identifier: "admin")

      Member.grant(%{member: member}, role)

      member = Repo.get(Member, member.id) |> Repo.preload([:roles])

      assert 1 == length(member.roles)
      assert role == Enum.at(member.roles, 0)
    end

    test "grant role to inherited member from id" do
      member = insert(:member)
      role = insert(:role, identifier: "admin")

      Member.grant(%{member_id: member.id}, role)

      member = Repo.get(Member, member.id) |> Repo.preload([:roles])

      assert 1 == length(member.roles)
      assert role == Enum.at(member.roles, 0)
    end

    test "grant only unique roles to member" do
      member = insert(:member)
      role = insert(:role, identifier: "admin")

      Member.grant(member, role)
      Member.grant(member, role)

      member = Repo.get(Member, member.id) |> Repo.preload([:roles])

      assert 1 == length(member.roles)
      assert role == Enum.at(member.roles, 0)
    end

    test "grant different roles to member" do
      member = insert(:member)
      role_admin = insert(:role, identifier: "admin")
      role_editor = insert(:role, identifier: "editor")

      Member.grant(member, role_admin)
      Member.grant(member, role_editor)

      member = Repo.get(Member, member.id) |> Repo.preload([:roles])

      assert 2 == length(member.roles)
      assert [role_admin] ++ [role_editor] == member.roles
    end
  end

  describe "Membership.Member.revoke/2" do
    test "rejects invalid grant" do
      assert_raise ArgumentError, fn ->
        Member.revoke(nil, nil)
      end
    end

    test "revokes correct ability from member" do
      member = insert(:member)
      ability = insert(:ability, identifier: "delete_accounts")
      ability_ban = insert(:ability, identifier: "ban_accounts")

      Member.grant(member, ability)
      Member.grant(member, ability_ban)
      member = Repo.get(Member, member.id)
      assert 2 == length(member.abilities)

      Member.revoke(member, ability)
      member = Repo.get(Member, member.id)
      assert 1 == length(member.abilities)
      assert "ban_accounts" == Enum.at(member.abilities, 0)
    end

    test "revokes correct ability from inherited member" do
      member = insert(:member)
      ability = insert(:ability, identifier: "delete_accounts")
      ability_ban = insert(:ability, identifier: "ban_accounts")

      Member.grant(member, ability)
      Member.grant(member, ability_ban)
      member = Repo.get(Member, member.id)
      assert 2 == length(member.abilities)

      Member.revoke(%{member: member}, ability)
      member = Repo.get(Member, member.id)
      assert 1 == length(member.abilities)
      assert "ban_accounts" == Enum.at(member.abilities, 0)
    end

    test "revokes correct ability from inherited member from id" do
      member = insert(:member)
      ability = insert(:ability, identifier: "delete_accounts")
      ability_ban = insert(:ability, identifier: "ban_accounts")

      Member.grant(member, ability)
      Member.grant(member, ability_ban)
      member = Repo.get(Member, member.id)
      assert 2 == length(member.abilities)

      Member.revoke(%{member_id: member.id}, ability)
      member = Repo.get(Member, member.id)
      assert 1 == length(member.abilities)
      assert "ban_accounts" == Enum.at(member.abilities, 0)
    end

    test "revokes correct role from member" do
      member = insert(:member)
      role_admin = insert(:role, identifier: "admin")
      role_editor = insert(:role, identifier: "editor")

      Member.grant(member, role_admin)
      Member.grant(member, role_editor)
      member = Repo.get(Member, member.id) |> Repo.preload([:roles])
      assert 2 == length(member.roles)

      Member.revoke(member, role_admin)
      member = Repo.get(Member, member.id) |> Repo.preload([:roles])
      assert 1 == length(member.roles)
      assert role_editor == Enum.at(member.roles, 0)
    end

    test "revokes correct role from inherited member" do
      member = insert(:member)
      role_admin = insert(:role, identifier: "admin")
      role_editor = insert(:role, identifier: "editor")

      Member.grant(member, role_admin)
      Member.grant(member, role_editor)
      member = Repo.get(Member, member.id) |> Repo.preload([:roles])
      assert 2 == length(member.roles)

      Member.revoke(%{member: member}, role_admin)
      member = Repo.get(Member, member.id) |> Repo.preload([:roles])
      assert 1 == length(member.roles)
      assert role_editor == Enum.at(member.roles, 0)
    end

    test "revokes correct role from inherited member from id" do
      member = insert(:member)
      role_admin = insert(:role, identifier: "admin")
      role_editor = insert(:role, identifier: "editor")

      Member.grant(member, role_admin)
      Member.grant(member, role_editor)
      member = Repo.get(Member, member.id) |> Repo.preload([:roles])
      assert 2 == length(member.roles)

      Member.revoke(%{member_id: member.id}, role_admin)
      member = Repo.get(Member, member.id) |> Repo.preload([:roles])
      assert 1 == length(member.roles)
      assert role_editor == Enum.at(member.roles, 0)
    end
  end

  describe "Membership.Member.revoke/3" do
    test "rejects invalid revoke" do
      assert_raise ArgumentError, fn ->
        Member.grant(nil, nil, nil)
      end
    end

    test "revokes ability from member on struct" do
      struct = insert(:role)
      member = insert(:member)
      ability = insert(:ability, identifier: "view_role")

      Member.grant(member, ability, struct)
      member = Repo.get(Member, member.id) |> Repo.preload([:entities])

      assert 1 == length(member.entities)
      assert Membership.has_ability?(member, :view_role, struct)

      member = Member.revoke(member, ability, struct)
      refute Membership.has_ability?(member, :view_role, struct)
    end

    test "revokes ability from inherited member on struct" do
      struct = insert(:role)
      member = insert(:member)
      ability = insert(:ability, identifier: "view_role")

      Member.grant(member, ability, struct)
      member = Repo.get(Member, member.id) |> Repo.preload([:entities])

      assert 1 == length(member.entities)
      assert Membership.has_ability?(member, :view_role, struct)

      member = Member.revoke(%{member: member}, ability, struct)
      refute Membership.has_ability?(member, :view_role, struct)
    end

    test "revokes ability from inherited member from id on struct" do
      struct = insert(:role)
      member = insert(:member)
      ability = insert(:ability, identifier: "view_role")

      Member.grant(member, ability, struct)
      member = Repo.get(Member, member.id) |> Repo.preload([:entities])

      assert 1 == length(member.entities)
      assert Membership.has_ability?(member, :view_role, struct)

      member = Member.revoke(%{member_id: member.id}, ability, struct)
      refute Membership.has_ability?(member, :view_role, struct)
    end
  end

  describe "Membership.Member.grant/3" do
    test "rejects invalid grant" do
      assert_raise ArgumentError, fn ->
        Member.revoke(nil, nil, nil)
      end
    end

    test "grant ability to member on struct" do
      # Can be any struct
      struct = insert(:role)
      member = insert(:member)
      ability = insert(:ability, identifier: "view_role")

      Member.grant(member, ability, struct)
      member = Repo.get(Member, member.id) |> Repo.preload([:entities])

      assert 1 == length(member.entities)
      assert Membership.has_ability?(member, :view_role, struct)
    end

    test "grant ability to inherited member on struct" do
      # Can be any struct
      struct = insert(:role)
      member = insert(:member)
      ability = insert(:ability, identifier: "view_role")

      Member.grant(%{member: member}, ability, struct)
      member = Repo.get(Member, member.id) |> Repo.preload([:entities])

      assert 1 == length(member.entities)
      assert Membership.has_ability?(member, :view_role, struct)
    end

    test "grant ability to inherited member from id on struct" do
      # Can be any struct
      struct = insert(:role)
      member = insert(:member)
      ability = insert(:ability, identifier: "view_role")

      Member.grant(%{member_id: member.id}, ability, struct)
      member = Repo.get(Member, member.id) |> Repo.preload([:entities])

      assert 1 == length(member.entities)
      assert Membership.has_ability?(member, :view_role, struct)
    end

    test "revokes ability to member on struct" do
      # Can be any struct
      struct = insert(:role)
      member = insert(:member)
      ability = insert(:ability, identifier: "view_role")

      Member.grant(member, ability, struct)
      member = Repo.get(Member, member.id) |> Repo.preload([:entities])

      assert 1 == length(member.entities)
      assert Membership.has_ability?(member, :view_role, struct)

      Member.revoke(member, ability, struct)
      member = Repo.get(Member, member.id) |> Repo.preload([:entities])

      assert 0 == length(member.entities)
      refute Membership.has_ability?(member, :view_role, struct)
    end

    test "revokes no ability to member on struct" do
      # Can be any struct
      struct = insert(:role)
      member = insert(:member)
      ability = insert(:ability, identifier: "view_role")

      Member.revoke(member, ability, struct)
      member = Repo.get(Member, member.id) |> Repo.preload([:entities])

      assert 0 == length(member.entities)
      refute Membership.has_ability?(member, :view_role, struct)
    end

    test "grants multiple abilities to member on struct" do
      # Can be any struct
      struct = insert(:role)
      member = insert(:member)
      ability = insert(:ability, identifier: "view_role")
      ability_delete = insert(:ability, identifier: "delete_role")

      member = Member.grant(member, ability, struct)
      member = Member.grant(member, ability_delete, struct)
      member = Repo.get(Member, member.id) |> Repo.preload([:entities])

      assert 1 == length(member.entities)
      assert Membership.has_ability?(member, :view_role, struct)
      assert Membership.has_ability?(member, :delete_role, struct)
    end

    test "revokes multiple abilities to member on struct" do
      # Can be any struct
      struct = insert(:role)
      member = insert(:member)
      ability = insert(:ability, identifier: "view_role")
      ability_delete = insert(:ability, identifier: "delete_role")

      member = Member.grant(member, ability, struct)
      member = Member.grant(member, ability_delete, struct)
      member = Repo.get(Member, member.id) |> Repo.preload([:entities])

      assert 1 == length(member.entities)
      assert Membership.has_ability?(member, :view_role, struct)
      assert Membership.has_ability?(member, :delete_role, struct)

      Member.revoke(member, ability_delete, struct)
      refute Membership.has_ability?(member, :delete_role, struct)
      assert Membership.has_ability?(member, :view_role, struct)
    end
  end
end
