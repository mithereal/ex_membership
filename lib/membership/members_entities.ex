defmodule Membership.MembersEntities do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset
  alias __MODULE__

  schema "membership_members_entities" do
    belongs_to(:member, Membership.Member)
    field(:assoc_id, :integer)
    field(:assoc_type, :string)
    field(:plans, {:array, :string}, default: [])

    timestamps()
  end

  def changeset(%MembersEntities{} = struct, params \\ %{}) do
    struct
    |> cast(params, [:member_id, :assoc_type, :assoc_id, :plans])
    |> validate_required([:member_id, :assoc_type, :assoc_id, :plans])
  end

  def create(
        %Membership.Member{id: id},
        %{__struct__: entity_name, id: entity_id},
        plans \\ []
      ) do
    changeset(%MembersEntities{
      member_id: id,
      assoc_type: entity_name |> normalize_struct_name,
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
