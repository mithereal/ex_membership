defmodule Membership.PlanFeatures do
  @moduledoc false

  use Membership.Schema
  import Ecto.Changeset
  alias __MODULE__
  alias Membership.Feature
  alias Membership.Plan

  schema "membership_plan_features" do
    belongs_to(:feature, Feature)
    belongs_to(:plan, Plan)
  end

  def changeset(%PlanFeatures{} = struct, params \\ %{}) do
    struct
    |> cast(params, [:feature, :plan])
    |> validate_required([:feature, :plan])
  end

  def create(
        %Membership.PlanFeatures{id: id},
        %{__struct__: _plan_name, id: assoc_id},
        features \\ []
      ) do
    changeset(%PlanFeatures{
      feature_id: id,
      plan_id: assoc_id
    })
    |> Membership.Repo.insert!()
  end
end
