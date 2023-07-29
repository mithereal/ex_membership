defmodule Membership.Plan do
  @moduledoc """
  Plan is main representation of a single plan
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias __MODULE__

  @typedoc "A plan struct"
  @type t :: %Plan{}

  schema "membership_plans" do
    field(:identifier, :string)
    field(:name, :string)

    timestamps()
  end

  def changeset(%Plan{} = struct, params \\ %{}) do
    struct
    |> cast(params, [:identifier, :name])
    |> validate_required([:identifier, :name])
    |> unique_constraint(:identifier, message: "Plan already exists")
  end

  def build(identifier, name) do
    changeset(%Plan{}, %{
      identifier: identifier,
      name: name
    })
  end
end
