defmodule Membership.Plan do
  @moduledoc """
  Plan is main representation of a single plan
  """
  use Membership.Schema

  alias Membership.Feature
  alias Membership.Plan
  alias Membership.PlanFeatures

  @typedoc "A plan struct"
  @type t :: %Plan{}

  @params ~w(identifier name)a
  @required_fields ~w(identifier name)a

  schema "membership_plans" do
    field(:identifier, :string)
    field(:name, :string)

    many_to_many(:features, Feature,
      join_through: PlanFeatures,
      on_replace: :delete
    )
  end

  def changeset(%Plan{} = struct, params = %Plan{}) do
    params = %{id: params.id, identifier: params.identifier, name: params.name}
    changeset(struct, params)
  end

  def changeset(%Plan{} = struct, params \\ %{}) do
    struct
    |> cast(params, [:identifier, :name])
    |> cast_assoc(:features, required: false)
    |> validate_required([:identifier, :name])
    |> unique_constraint(:identifier, message: "Plan already exists")
  end

  def build(identifier, name, features \\ []) do
    changeset(%Plan{}, %{
      identifier: identifier,
      name: name,
      features: features
    })
    |> Ecto.Changeset.apply_changes()
  end

  def table, do: :membership_plans

  def create(identifier, name, features \\ []) do
    features =
      Enum.map(features, fn f ->
        Feature.create(f.identifier, f.name)
      end)

    changeset(%Plan{}, %{
      identifier: identifier,
      name: name,
      features: features
    })
    |> Repo.insert_or_update()
  end

  def create(plan = %Plan{}) do
    create(plan.identifier, plan.name, plan.features)
  end
end
