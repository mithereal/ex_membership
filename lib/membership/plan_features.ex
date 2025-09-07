defmodule Membership.PlanFeatures do
  @moduledoc false

  use Membership.Schema, type: :binary_fk

  alias Membership.Feature
  alias Membership.Plan
  alias Membership.PlanFeatures

  schema "membership_plan_features" do
    belongs_to(:feature, Feature)
    belongs_to(:plan, Plan)
  end

  def changeset(%PlanFeatures{} = struct, params \\ %{}) do
    struct
    |> cast(params, [:feature_id, :plan_id])
    |> validate_required([:feature_id, :plan_id])
  end

  def create(
        %Feature{id: id},
        %{__struct__: _plan_name, id: assoc_id},
        _features \\ []
      ) do
    repo = Membership.Repo.repo()

    changeset(%PlanFeatures{
      feature_id: id,
      plan_id: assoc_id
    })
    |> repo.insert!()
  end
end
