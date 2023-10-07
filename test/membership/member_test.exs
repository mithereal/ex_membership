defmodule Membership.MemberTest do
  use Membership.EctoCase
  alias Membership.Member

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

    test "grant feature to member" do
      member = insert(:member)
      feature = insert(:feature, identifier: "delete_accounts")
      Member.grant(member, feature, "required")

      member = Repo.get(Member, member.id)

      assert 1 == length(member.features)
      assert "delete_accounts" == Enum.at(member.features, 0)
    end

    test "grant feature to inherited member" do
      member = insert(:member)
      feature = insert(:feature, identifier: "delete_accounts")

      Member.grant(%{member: member}, feature, "required")

      member = Repo.get(Member, member.id)

      assert 1 == length(member.features)
      assert "delete_accounts" == Enum.at(member.features, 0)
    end

    test "grant feature to inherited member from id" do
      member = insert(:member)
      feature = insert(:feature, identifier: "delete_accounts")

      Member.grant(%{member_id: member.id}, feature, "required")

      member = Repo.get(Member, member.id)

      assert 1 == length(member.features)
      assert "delete_accounts" == Enum.at(member.features, 0)
    end

    test "grant only unique features to member" do
      member = insert(:member)
      feature = insert(:feature, identifier: "delete_accounts")

      Member.grant(member, feature, "required")
      Member.grant(member, feature, "required")

      member = Repo.get(Member, member.id)

      assert 1 == length(member.features)
      assert "delete_accounts" == Enum.at(member.features, 0)
    end

    test "grant different features to member" do
      member = insert(:member)
      feature_delete = insert(:feature, identifier: "delete_accounts")
      feature_ban = insert(:feature, identifier: "ban_accounts")

      Member.grant(member, feature_delete, "required")
      member = Member.grant(member, feature_ban, "required")

      assert 2 == length(member.features)
      assert [feature_delete.identifier] ++ [feature_ban.identifier] == member.features
    end

    test "grant plan to member" do
      member = insert(:member)
      plan = insert(:plan, identifier: "admin")

      member = Member.grant(member, plan)

      assert 1 == length(member.plans)
      assert plan == Enum.at(member.plans, 0)
    end

    test "grant plan to inherited member" do
      member = insert(:member)
      plan = insert(:plan, identifier: "admin")

      member = Member.grant(%{member: member}, plan)
      plan = Repo.get(Membership.Plan, plan.id) |> Repo.preload(:features)

      assert 1 == length(member.plans)
      assert plan == Enum.at(member.plans, 0)
    end

    test "grant plan to inherited member from id" do
      member = insert(:member)
      plan = insert(:plan, identifier: "admin")

      member = Member.grant(%{member_id: member.id}, plan)

      assert 1 == length(member.plans)
      assert plan == Enum.at(member.plans, 0)
    end

    test "grant only unique plans to member" do
      member = insert(:member)
      plan = insert(:plan, identifier: "admin")

      Member.grant(member, plan)
      member = Member.grant(member, plan)

      assert 1 == length(member.plans)
      assert plan == Enum.at(member.plans, 0)
    end

    test "grant different plans to member" do
      member = insert(:member)
      plan_admin = insert(:plan, identifier: "admin")
      plan_editor = insert(:plan, identifier: "editor")

      Member.grant(member, plan_admin)
      member = Member.grant(member, plan_editor)

      assert 2 == length(member.plans)
      assert [plan_admin] ++ [plan_editor] == member.plans
    end
  end

  describe "Membership.Member.revoke/2" do
    test "rejects invalid grant" do
      assert_raise ArgumentError, fn ->
        Member.revoke(nil, nil)
      end
    end

    test "revokes correct feature from member" do
      member = insert(:member)
      feature = insert(:feature, identifier: "delete_accounts")
      feature_ban = insert(:feature, identifier: "ban_accounts")

      Member.grant(member, feature, "required")
      member = Member.grant(member, feature_ban, "required")

      assert 2 == length(member.features)

      Member.revoke(member, feature)
      member = Repo.get(Member, member.id)
      assert 1 == length(member.features)
      assert "ban_accounts" == Enum.at(member.features, 0)
    end

    test "revokes correct feature from inherited member" do
      member = insert(:member)
      feature = insert(:feature, identifier: "delete_accounts")
      feature_ban = insert(:feature, identifier: "ban_accounts")

      Member.grant(member, feature, "required")
      member = Member.grant(member, feature_ban, "required")

      assert 2 == length(member.features)

      Member.revoke(%{member: member}, feature)
      member = Repo.get(Member, member.id)
      assert 1 == length(member.features)
      assert "ban_accounts" == Enum.at(member.features, 0)
    end

    test "revokes correct feature from inherited member from id" do
      member = insert(:member)
      feature = insert(:feature, identifier: "delete_accounts")
      feature_ban = insert(:feature, identifier: "ban_accounts")

      Member.grant(member, feature, "required")
      member = Member.grant(member, feature_ban, "required")

      assert 2 == length(member.features)

      Member.revoke(%{member_id: member.id}, feature)
      member = Repo.get(Member, member.id)
      assert 1 == length(member.features)
      assert "ban_accounts" == Enum.at(member.features, 0)
    end

    test "revokes correct plan from member" do
      member = insert(:member)
      plan_admin = insert(:plan, identifier: "admin")
      plan_editor = insert(:plan, identifier: "editor")

      Member.grant(member, plan_admin)
      member = Member.grant(member, plan_editor)
      assert 2 == length(member.plans)

      Member.revoke(member, plan_admin)
      member = Repo.get(Member, member.id) |> Repo.preload([:plans])
      assert 1 == length(member.plans)
      assert plan_editor == Enum.at(member.plans, 0)
    end

    test "revokes correct plan from inherited member" do
      member = insert(:member)
      plan_admin = insert(:plan, identifier: "admin")
      plan_editor = insert(:plan, identifier: "editor")

      Member.grant(member, plan_admin)
      Member.grant(member, plan_editor)
      member = Repo.get(Member, member.id) |> Repo.preload([:plans])
      assert 2 == length(member.plans)

      Member.revoke(%{member: member}, plan_admin)
      member = Repo.get(Member, member.id) |> Repo.preload([:plans])
      assert 1 == length(member.plans)
      assert plan_editor == Enum.at(member.plans, 0)
    end

    test "revokes correct plan from inherited member from id" do
      member = insert(:member)
      plan_admin = insert(:plan, identifier: "admin")
      plan_editor = insert(:plan, identifier: "editor")

      Member.grant(member, plan_admin)
      Member.grant(member, plan_editor)
      member = Repo.get(Member, member.id) |> Repo.preload([:plans])
      assert 2 == length(member.plans)

      Member.revoke(%{member_id: member.id}, plan_admin)
      member = Repo.get(Member, member.id) |> Repo.preload([:plans])
      assert 1 == length(member.plans)
      assert plan_editor == Enum.at(member.plans, 0)
    end
  end

  describe "Membership.Member.revoke/3" do
    test "rejects invalid revoke" do
      assert_raise ArgumentError, fn ->
        Member.grant(nil, nil, nil)
      end
    end

    test "revokes feature from member on struct" do
      member = insert(:member)
      feature = insert(:feature, identifier: "view_plan")

      Member.grant(member, feature, "required")
      member = Repo.get(Member, member.id)

      assert 1 == length(member.features)
      assert Membership.has_feature?(member, feature.identifier)

      member = Member.revoke(member, feature)
      refute Membership.has_feature?(member, feature.identifier)
    end
  end

  describe "Membership.Member.grant/3" do
    test "rejects invalid grant" do
      assert_raise ArgumentError, fn ->
        Member.revoke(nil, nil, nil)
      end
    end
  end
end
