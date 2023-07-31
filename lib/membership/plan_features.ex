defmodule Membership.PlanFeatures do
  @moduledoc false

  use Membership.Schema
  import Ecto.Changeset
  alias __MODULE__

  schema "membership_plan_features" do
    belongs_to(:feature, Membership.PlanFeatures)
    field(:assoc_id, :integer)
    field(:plan_name, :string)

    timestamps()
  end

  def changeset(%PlanFeatures{} = struct, params \\ %{}) do
    struct
    |> cast(params, [:feature_id, :assoc_id, :plan_name])
    |> validate_required([:feature_id, :assoc_id, :plan_name])
  end

  def create(
        %Membership.PlanFeatures{id: id},
        %{__struct__: plan_name, id: assoc_id},
        features \\ []
      ) do
    changeset(%PlanFeatures{
      feature_id: id,
      assoc_id: assoc_id,
      plan_name: plan_name |> normalize_struct_name
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
