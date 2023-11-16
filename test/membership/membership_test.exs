defmodule Membership.MembershipTest do
  use Membership.EctoCase

  setup do
    :ok
  end

  describe "Membership.create_membership" do
    test "loads macros" do
      functions = Post.__info__(:functions)

      assert functions[:load_and_authorize_member] == 1
    end
  end

  describe "Membership.base tests" do
    test "rejects no role" do
      member = insert(:member)

      assert {:error, "Member is not granted to perform this action"} ==
               Post.delete_post(1, member.id)
    end
  end

  #
  test "rejects invalid role" do
    insert(:feature)
    member = insert(:member, identifier: "test")
    insert(:plan, identifier: "gold")

    assert {:error, "Member is not granted to perform this action"} ==
             Post.delete_post(1, member.id)
  end

  test "allows plan" do
    feature = insert(:feature, identifier: "delete_posts")

    member =
      insert(:member)

    plan = insert(:plan, identifier: "gold")

    Membership.Feature.grant(feature, plan)
    member = Membership.Member.grant(member, plan)

    assert {:ok, "Post 1 was Deleted"} == Post.delete_post(1, member.id)
  end

  test "rejects no features" do
    member = insert(:member)

    assert {:error, "Member is not granted to perform this action"} == Post.update(1, member.id)
  end

  test "rejects invalid features" do
    member = insert(:member)
    feature = insert(:feature, identifier: "view_post")

    member = Membership.Member.grant(member, feature, "required")

    assert {:error, "Member is not granted to perform this action"} == Post.update(1, member.id)
  end

  test "allows feature" do
    member = insert(:member)
    feature = insert(:feature, identifier: "update_post")

    Membership.Member.grant(member, feature, "required")

    assert {:ok, "Post was Updated"} == Post.update(1, member.id)
  end

  test "rejects inherited ability from role" do
    member = insert(:member)
    role = insert(:role, identifier: "admin", name: "Administator")
    feature = insert(:feature, identifier: "view_post")

    Membership.Feature.grant(feature, role)
    member = Membership.Member.grant(member, feature, "deny")

    assert {:error, "Member is not granted to perform this action"} == Post.update(1, member.id)
  end

  test "allows inherited ability from role" do
    member = insert(:member)
    role = insert(:role, identifier: "admin", name: "Administator")
    feature = insert(:feature, identifier: "update_post")

    Membership.Feature.grant(feature, role)
    member = Membership.Member.grant(member, role)

    assert {:ok, "Post was Updated"} == Post.update(1, member.id)
  end

  test "allows inherited ability from multiple roles" do
    member = insert(:member)
    plan = insert(:plan, identifier: "admin", name: "Administator")
    plan_1 = insert(:plan, identifier: "editor", name: "Administator")
    feature = insert(:feature, identifier: "delete_post")
    feature_update = insert(:feature, identifier: "update_post")

    _role = Membership.Feature.grant(plan, feature)
    _role_editor = Membership.Feature.grant(plan_1, feature_update)
    member = Membership.Member.grant(member, plan)
    member = Membership.Member.grant(member, plan_1)

    assert {:ok, "Post was Updated"} == Post.update(1, member.id)
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

    member = Membership.Member.grant(member, feature, "required")

    assert {:ok, "Authorized"} == Post.no_macro(member)
  end

  test "allows ability without any required permissions" do
    member = insert(:member)
    feature = insert(:feature, identifier: "update_post")

    member = Membership.Member.grant(member, feature, "required")

    assert {:ok, "Authorized"} == Post.no_permissions(member)
  end

  describe "Membership.authorize!/1" do
    test "it evaluates empty conditions as true" do
      assert :ok == Membership.authorize!([])
    end
  end

  describe "Membership.calculated/1" do
    test "grants calculated permissions" do
      member = insert(:member)
      assert {:ok, "Authorized"} == Post.calculated_function(member, true)
    end

    #    test "rejects calculated permissions" do
    #      member = insert(:member)
    #      Membership.unload_member!(member)
    #
    #      assert_raise ArgumentError, fn ->
    #        reply = Post.calculated_function(member, false)
    #        IO.inspect(reply)
    #      end
    #    end

    test "rejects macro calculated permissions" do
      member = insert(:member)
      assert {:ok, "Authorized"} == Post.calculated_function(member, true)
    end
  end

  describe "Membership.has_feature?/2" do
    test "grants feature passed as an argument" do
      member = insert(:member)
      feature = insert(:feature, identifier: "update_post")

      member = Membership.Member.grant(member, feature, "required")

      assert Membership.has_feature?(member, "update_post")

      refute Membership.has_feature?(member, "delete_post")
    end
  end

  describe "Membership.has_role?/2" do
    test "grants role passed as an argument" do
      member = insert(:member)
      role = insert(:role, identifier: "admin", name: "Administrator")

      member = Membership.Member.grant(member, role)

      assert Membership.has_role?(member, "admin")

      refute Membership.has_role?(member, "editor")
    end
  end

  describe "Membership.perform_authorization!/3" do
    test "performs authorization" do
      member = insert(:member)
      feature = insert(:feature, identifier: "delete_posts", name: "delete_posts")

      member = Membership.Member.grant(member, feature, "required")
      member = Post.load_and_authorize_member(member)

      assert Post.perform_authorization!(member, "delete_posts")
      assert Membership.perform_authorization!(member, [])
    end
  end
end
