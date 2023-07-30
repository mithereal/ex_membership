defmodule Membership.MemberPlans do
  @moduledoc """
  MemberPlans is the association linking the member to the plan you can also set specific features for the membership
  """

  use Ecto.Schema
  import Ecto.Changeset
  alias __MODULE__

  schema "membership_member_plans" do
    belongs_to(:member, Membership.Member)
    field(:assoc_id, :integer)
    field(:plan_name, :string)
    field(:features, {:array, :string}, default: [])

    timestamps()
  end

  def changeset(%Membership.MemberPlans{} = struct, params \\ %{}) do
    struct
    |> cast(params, [:member_id, :assoc_id, :features, :plan_name])
    |> validate_required([:member_id, :assoc_id, :features, :plan_name])
  end

  def create(
        %Membership.Member{id: id},
        %{__struct__: plan_name, id: assoc_id},
        features \\ []
      ) do
    changeset(%Membership.MemberPlans{
      member_id: id,
      plan_id: assoc_id,
      plan_name: plan_name |> normalize_struct_name,
      features: features
    })
    |> Membership.Repo.insert!()
  end

  def normalize_struct_name(name) do
    name
    |> Atom.to_string()
    |> String.replace(".", "_")
    |> String.downcase()
  end
end
