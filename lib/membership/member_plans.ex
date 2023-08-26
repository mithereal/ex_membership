defmodule Membership.MemberPlans do
  @moduledoc """
  MemberPlans is the association linking the member to the plan you can also set specific features for the membership
  """

  use Membership.Schema
  import Ecto.Changeset

  schema "membership_member_plans" do
    belongs_to(:member, Membership.Member)
    belongs_to(:plan, Membership.Plan)
  end

  def changeset(%Membership.MemberPlans{} = struct, params \\ %{}) do
    struct
    |> cast(params, [:member_id, :plan_id])
    |> validate_required([:member_id, :plan_id])
  end

  def create(
        %Membership.Member{id: id},
        %{__struct__: _plan_name, id: plan_id},
        _features \\ []
      ) do
    changeset(%Membership.MemberPlans{
      member_id: id,
      plan_id: plan_id
    })
    |> Membership.Repo.insert!()
  end
end
