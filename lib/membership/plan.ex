defmodule Membership.Plan do
  @moduledoc """
  Plan is main representation of a single plan
  """
  use Membership.Schema
  import Ecto.Changeset

  alias Membership.Plan

  @typedoc "A plan struct"
  @type t :: %Plan{}

  schema "membership_plans" do
    field(:identifier, :string)
    field(:name, :string)

    many_to_many(:features, Membership.Feature,
      join_through: Membership.PlanFeatures,
      on_replace: :delete
    )
  end

  def changeset(%Plan{} = struct, params \\ %{}) do
    struct
    |> cast(params, [:identifier, :name])
    |> validate_required([:identifier, :name])
    |> unique_constraint(:identifier, message: "Plan already exists")
  end

  def build(identifier, name, features \\ []) do
    changeset(%Plan{}, %{
      identifier: identifier,
      name: name,
      features: features
    })
  end

  def table, do: :membership_plans
end
