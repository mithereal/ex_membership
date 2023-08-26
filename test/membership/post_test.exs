defmodule PostTest do
  use Membership

  def delete(member) do
    load_and_authorize_member(member)

    permissions do
      has_plan(:admin)
    end

    as_authorized do
      {:ok, "Authorized"}
    end
  end

  def update(member) do
    load_and_authorize_member(member)

    membership_permissions do
      has_feature(:update_post)
    end

    as_authorized do
      {:ok, "Authorized"}
    end
  end

  def entity_update(member) do
    load_and_authorize_member(member)

    membership_permissions do
      has_feature(:delete_member, member)
    end

    as_authorized do
      {:ok, "Authorized"}
    end
  end

  def no_macro(member) do
    load_and_authorize_member(member)

    membership_permissions do
      has_feature(:update_post)
    end

    case is_authorized?() do
      :ok -> {:ok, "Authorized"}
      _ -> raise ArgumentError, message: "Not authorized"
    end
  end

  def no_permissions(member) do
    load_and_authorize_member(member)

    permissions do
    end

    case is_authorized?() do
      :ok -> {:ok, "Authorized"}
      _ -> raise ArgumentError, message: "Not authorized"
    end
  end

  def calculated(member, email_confirmed) do
    load_and_authorize_member(member)

    permissions do
      calculated(fn _member ->
        email_confirmed
      end)
    end

    case is_authorized?() do
      :ok -> {:ok, "Authorized"}
      _ -> raise ArgumentError, message: "Not authorized"
    end
  end

  def calculated_macro(member) do
    load_and_authorize_member(member)

    permissions do
      calculated(:confirmed_email)
    end

    case is_authorized?() do
      :ok -> {:ok, "Authorized"}
      _ -> raise ArgumentError, message: "Not authorized"
    end
  end

  def confirmed_email(_member) do
    false
  end
end

defmodule Membership.MembershipTest do
  use Membership.EctoCase

  setup do
    Membership.load_membership_plans()
    :ok
  end

  describe "Membership.create_membership" do
    test "loads macros" do
      functions = Post.__info__(:functions)

      assert functions[:load_and_authorize_member] == 1
    end

    test "rejects no role" do
      member = insert(:member)

      assert {:error, "Member is not granted to perform this action"} == Post.delete(member)
    end

    test "rejects invalid role" do
      member = insert(:member)
      plan = insert(:plan, identifier: "gold")

      Membership.Member.grant(member, plan)

      assert {:error, "Member is not granted to perform this action"} == Post.delete(member)
    end

    test "allows plan" do
      member = insert(:member)
      plan = insert(:plan, identifier: "admin")

      member = Membership.Member.grant(member, plan)
      assert {:ok, "Authorized"} == Post.delete(member)
    end

    test "rejects no features" do
      member = insert(:member)

      assert {:error, "Member is not granted to perform this action"} == Post.update(member)
    end

    test "rejects invalid features" do
      member = insert(:member)
      feature = insert(:feature, identifier: "view_post")

      member = Membership.Member.grant(member, feature)

      assert {:error, "Member is not granted to perform this action"} == Post.update(member)
    end

    test "allows feature" do
      member = insert(:member)
      feature = insert(:feature, identifier: "update_post")

      member = Membership.Member.grant(member, feature)

      assert {:ok, "Authorized"} == Post.update(member)
    end

    test "allows ability on struct" do
      member = insert(:member)
      feature = insert(:feature, identifier: "delete_member")

      member = Membership.Member.grant(member, feature, member)

      assert {:ok, "Authorized"} == Post.entity_update(member)
    end

    test "rejects ability on struct" do
      member = insert(:member)
      ability = insert(:feature, identifier: "update_post")

      member = Membership.Member.grant(member, feature, member)

      assert {:error, "Member is not granted to perform this action"} ==
               Post.entity_update(member)
    end

    test "rejects inherited ability from role" do
      member = insert(:member)
      plan = insert(:plan, identifier: "admin", name: "Administator")
      ability = insert(:ability, identifier: "view_post")

      feature = Membership.Feature.grant(plan, ability)
      member = Membership.Member.grant(member, feature)

      assert {:error, "Member is not granted to perform this action"} == Post.update(member)
    end

    test "allows inherited ability from role" do
      member = insert(:member)
      plan = insert(:plan, identifier: "admin", name: "Administator")
      feature = insert(:feature, identifier: "update_post")

      role = Membership.Role.grant(plan, feature)
      member = Membership.Member.grant(member, role)

      assert {:ok, "Authorized"} == Post.update(member)
    end

    test "allows inherited ability from multiple roles" do
      member = insert(:member)
      plan = insert(:plan, identifier: "admin", name: "Administator")
      plan_1 = insert(:plan, identifier: "editor", name: "Administator")
      feature = insert(:feature, identifier: "delete_post")
      feature_update = insert(:feature, identifier: "update_post")

      role = Membership.Role.grant(plan, feature)
      role_editor = Membership.Role.grant(plan_1, feature_update)
      member = Membership.Member.grant(member, plan)
      member = Membership.Member.grant(member, plan_1)

      assert {:ok, "Authorized"} == Post.update(member)
    end

    test "rejects ability without macro block" do
      member = insert(:member)

      assert_raise ArgumentError, fn ->
        Post.no_macro(member)
      end
    end

    test "allows ability without macro block" do
      member = insert(:member)
      feature = insert(:feature, identifier: "update_post")

      member = Membership.Member.grant(member, feature)

      assert {:ok, "Authorized"} == Post.no_macro(member)
    end

    test "allows ability without any required permissions" do
      member = insert(:member)
      feature = insert(:feature, identifier: "update_post")

      member = Membership.Member.grant(member, feature)

      assert {:ok, "Authorized"} == Post.no_permissions(member)
    end
  end

  describe "Membership.authorize!/1" do
    test "it evaluates empty conditions as true" do
      assert :ok == Membership.authorize!([])
    end
  end

  describe "Membership.load_and_store_member/1" do
    test "allows ability to not preloaded member from database" do
      member = insert(:member)
      feature = insert(:feature, identifier: "update_post")

      not_loaded_member = %{member_id: member.id}
      Membership.Member.grant(member, feature)

      assert {:ok, "Authorized"} == Post.update(not_loaded_member)
    end
  end

  describe "Membership.store_member/1" do
    test "allows ability to member loaded on different struct" do
      member = insert(:member)
      feature = insert(:feature, identifier: "update_post")

      member = Membership.Member.grant(member, feature)
      user = %{member: member}

      assert {:ok, "Authorized"} == Post.update(user)
    end
  end

  describe "Membership.calculated/1" do
    test "grants calculated permissions" do
      member = insert(:member)
      assert {:ok, "Authorized"} == Post.calculated(member, true)
    end

    test "rejects calculated permissions" do
      member = insert(:member)

      assert_raise ArgumentError, fn ->
        Post.calculated(member, false)
      end
    end

    test "rejects macro calculated permissions" do
      member = insert(:member)
      assert {:ok, "Authorized"} == Post.calculated(member, true)
    end
  end

  describe "Membership.has_feature?/2" do
    test "grants feature passed as an argument" do
      member = insert(:member)
      feature = insert(:feature, identifier: "update_post")

      member = Membership.Member.grant(member, feature)

      assert Membership.has_feature?(member, :update_post)

      refute Membership.has_feature?(member, :delete_post)
    end
  end

  describe "Membership.has_plan?/2" do
    test "grants role passed as an argument" do
      member = insert(:member)
      plan = insert(:plan, identifier: "admin", name: "Administrator")

      member = Membership.Member.grant(member, plan)

      assert Membership.has_plan?(member, :admin)

      refute Membership.has_plan?(member, :editor)
    end
  end

  describe "Membership.perform_authorization!/3" do
    test "performs authorization" do
      member = insert(:member)
      plan = insert(:plan, identifier: "admin", name: "Administrator")

      member = Membership.Member.grant(member, plan)

      assert Membership.perform_authorization!(member)
      assert Membership.perform_authorization!(member, [])
      assert Membership.perform_authorization!(member, [], [])
    end
  end
end
