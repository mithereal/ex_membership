defmodule Membership.PlanFeatures do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset
  alias __MODULE__

  schema "membership_plan_features" do
    belongs_to(:feature, Membership.PlanFeatures)
    field(:plan_id, :integer)
    field(:plan_name, :string)

    timestamps()
  end

  def changeset(%PlanFeatures{} = struct, params \\ %{}) do
    struct
    |> cast(params, [:feature_id, :plan_id, :plan_name])
    |> validate_required([:feature_id, :plan_id, :plan_name])
  end

  def create(
        %Membership.PlanFeatures{id: id},
        %{__struct__: plan_name, id: plan_id},
        features \\ []
      ) do
    changeset(%PlanFeatures{
      feature_id: id,
      plan_id: plan_id,
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
