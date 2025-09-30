defmodule Membership.PlanFeatures do
  @moduledoc false

  use Membership.Schema, type: :binary_fk

  alias Membership.Feature
  alias Membership.Plan
  alias Membership.PlanFeatures

  schema "membership_plan_features" do
    # Virtual ID field (for Kaffy)
    field(:id, :string, virtual: true)

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

  def table, do: :membership_plan_features

  def index(_conn) do
    Repo.all(PlanFeatures)
    |> Enum.map(&with_virtual_id/1)
  end

  def get(%{"plan_id" => plan_id, "feature_id" => feature_id}) do
    Repo.get_by!(PlanFeatures, plan_id: plan_id, feature_id: feature_id)
    |> with_virtual_id()
  end

  def get(id) when is_binary(id) do
    case String.split(id, ":") do
      [plan_id_str, feature_id_str] ->
        get(%{"plan_id" => plan_id_str, "feature_id" => feature_id_str})

      _ ->
        raise "Invalid ID format. Expected 'plan_id:feature_id'"
    end
  end

  defp with_virtual_id(struct) do
    %{struct | id: "#{struct.plan_id}:#{struct.feature_id}"}
  end
end
