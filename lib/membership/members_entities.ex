defmodule Membership.MemberPlans do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset
  alias __MODULE__

  schema "membership_member_plans" do
    belongs_to(:member, Membership.Member)
    field(:assoc_id, :integer)
    field(:plans, {:array, :string}, default: [])

    timestamps()
  end

  def changeset(%Membership.MemberPlans{} = struct, params \\ %{}) do
    struct
    |> cast(params, [:member_id, :assoc_id, :plans])
    |> validate_required([:member_id, :assoc_id, :plans])
  end

  def create(
        %Membership.Member{id: id},
        %{__struct__: entity_name, id: entity_id},
        plans \\ []
      ) do
    changeset(%Membership.MemberPlans{
      member_id: id,
      assoc_id: entity_id,
      plans: plans
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
