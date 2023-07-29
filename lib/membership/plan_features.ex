defmodule Membership.PlanFeatures do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset
  alias __MODULE__

  schema "membership_plan_features" do
    belongs_to(:feature, Membership.Feature)
    field(:assoc_id, :integer)
    field(:features, {:array, :string}, default: [])

    timestamps()
  end

  def changeset(%PlanFeatures{} = struct, params \\ %{}) do
    struct
    |> cast(params, [:member_id, :assoc_id, :features])
    |> validate_required([:member_id, :assoc_id, :features])
  end

  def create(
        %Membership.PlanFeatures{id: id},
        %{__struct__: entity_name, id: entity_id},
        features \\ []
      ) do
    changeset(%PlanFeatures{
      member_id: id,
      assoc_id: entity_id,
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
