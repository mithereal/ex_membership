defmodule Membership.MemberPlans do
  @moduledoc """
  MemberPlans is the association linking the member to the plan you can also set specific features for the membership
  """

  use Membership.Schema, type: :binary_fk

  @config Membership.Config.new()

  alias Membership.Member
  alias Membership.Plan
  alias Membership.MemberPlans

  schema "membership_member_plans" do
    belongs_to(:member, Member)
    belongs_to(:plan, Plan)
  end

  def changeset(%MemberPlans{} = struct, params \\ %{}) do
    struct
    |> cast(params, [:member_id, :plan_id])
    |> validate_required([:member_id, :plan_id])
  end

  def create(
        %Member{id: id},
        %{__struct__: _plan_name, id: plan_id},
        _features \\ []
      ) do
    changeset =
      changeset(%MemberPlans{
        member_id: id,
        plan_id: plan_id
      })

    @config |> Repo.insert!(changeset)
  end
end
