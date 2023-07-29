defmodule Membership.Feature do
  @moduledoc """
  Feature is main representation of a single feature flag assigned to a plan
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias __MODULE__

  @typedoc "A Feature struct"
  @type t :: %Feature{}

  schema "membership_features" do
    field(:identifier, :string)
    field(:name, :string)

    timestamps()
  end

  def changeset(%Feature{} = struct, params \\ %{}) do
    struct
    |> cast(params, [:identifier, :name])
    |> validate_required([:identifier, :name])
    |> unique_constraint(:identifier, message: "Feature already exists")
  end

  def build(identifier, name) do
    changeset(%Feature{}, %{
      identifier: identifier,
      name: name
    })
  end
end
