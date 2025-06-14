defmodule Membership.Plan do
  @moduledoc """
  Plan is main representation of a single plan
  """
  use Membership.Schema
  import Ecto.Query

  alias Membership.Feature
  alias Membership.Plan
  alias Membership.Plan.Server
  alias Membership.PlanFeatures

  @config Membership.Config.new()

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

  def changeset(%Plan{} = struct, params) do
    struct
    |> cast(params, @params)
    |> cast_assoc(:features, required: false)
    |> validate_required(@required_fields)
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

  def create(identifier, name, features \\ []) do
    changeset =
      changeset(%Plan{}, %{
        identifier: identifier,
        name: name
      })

    plan = @config |> Repo.insert_or_update(changeset)

    Enum.map(features, fn f ->
      Feature.create(f.identifier, f.name)
      |> Plan.grant(plan)
    end)
  end

  def create(plan = %Plan{}) do
    create(plan.identifier, plan.name, plan.features)
  end

  def table, do: :membership_plans

  @doc """
  Grant given grant type to a feature.

  ## Examples

  Function accepts either `Membership.Plan` or `Membership.Feature` grants.
  Function is merging existing grants with the new ones, so calling grant with same
  grants will not duplicate entries in table.

  To grant particular feature to a given plan

      iex> Membership.Plan.grant(%Membership.Feature{id: 1}, %Membership.Plan{id: 1})

  To grant particular feature to a given plan

      iex> Membership.Plan.grant(%Membership.Plan{id: 1}, %Membership.Feature{id: 1})

  """

  @spec grant(Plan.t(), Plan.t() | Feature.t()) :: Member.t()
  def grant(%Plan{id: id} = _plan, %Feature{id: feature_id} = _feature) do
    # Preload Plan features
    plan = @config |> Repo.get!(Plan, id)
    feature = @config |> Repo.get!(Feature, feature_id)

    revoke(feature, plan)

    @config |> Repo.insert(%PlanFeatures{plan_id: plan.id, feature_id: feature.id})

    Server.reload()
  end

  def grant(%{plan: %Plan{id: _pid} = plan}, %Feature{id: _id} = feature) do
    grant(plan, feature)
  end

  def grant(%{plan_id: id}, %Feature{id: _id} = feature) do
    @config
    |> Repo.get!(Plan, id)
    |> grant(feature)
  end

  def grant(%Feature{id: feature_id} = _feature, %Plan{id: id} = _plan) do
    plan = @config |> Repo.get!(Plan, id)
    feature = @config |> Repo.get!(Feature, feature_id)

    revoke(feature, plan)

    @config
    |> Repo.insert(%PlanFeatures{plan_id: plan.id, feature_id: feature.id})

    Server.reload()
  end

  def grant(%{feature: feature}, %Plan{id: _id} = plan) do
    grant(plan, feature)
  end

  def grant(%{feature_id: id}, %Plan{id: _id} = plan) do
    grant(plan, %Feature{id: id})
  end

  def grant(_, _), do: raise(ArgumentError, message: "Bad arguments for giving grant")

  def grant(_, _, _), do: raise(ArgumentError, message: "Bad arguments for giving grant")

  @doc """
  Revoke given grant type from a member.

  ## Examples

  Function accepts either `Membership.Plan` or `Membership.Feature` grants.
  Function is directly opposite of `Membership.Member.grant/2`

  To revoke particular feature from a given plan

      iex> Membership.Plan.revoke(%Membership.Feature{id: 1}, %Membership.Plan{id: 1})

  To revoke particular plan from a given feature

      iex> Membership.Plan.revoke(%Membership.Plan{id: 1}, %Membership.Feature{id: 1})

  """
  @spec revoke(Plan.t(), Plan.t() | Feature.t()) :: Member.t()
  def revoke(%Plan{id: id} = _, %Feature{id: _id} = feature) do
    query =
      from(pa in PlanFeatures)
      |> where([pr], pr.plan_id == ^id and pr.feature_id == ^feature.id)

    @config |> Repo.delete_all(query)
  end

  def revoke(%{plan: %Plan{id: _pid} = plan}, %Feature{id: _id} = feature) do
    revoke(plan, feature)
  end

  def revoke(%{feature_id: id}, %Feature{id: _id} = feature) do
    revoke(%Plan{id: id}, feature)
  end

  def revoke(%Feature{id: id} = _, %Plan{id: _id} = plan) do
    query =
      from(pa in PlanFeatures)
      |> where([pr], pr.feature_id == ^id and pr.plan_id == ^plan.id)

    @config |> Repo.delete_all(query)
  end

  def revoke(
        %{feature: %Feature{id: _pid} = feature},
        %Plan{id: _id} = plan
      ) do
    revoke(plan, feature)
  end

  def revoke(%{feature_id: id}, %Plan{id: _id} = plan) do
    revoke(%Feature{id: id}, plan)
  end

  def revoke(_, _), do: raise(ArgumentError, message: "Bad arguments for revoking grant")

  def revoke(_, _, _), do: raise(ArgumentError, message: "Bad arguments for revoking grant")

  def load_plan_feature(plan, %{
        __struct__: _feature_name,
        id: feature_id,
        identifier: _identifier
      }) do
    query =
      FeaturePlans
      |> where(
        [e],
        e.plan_id == ^plan.id and e.feature_id == ^feature_id
      )

    @config |> Repo.one(query)
  end

  def all() do
    @config
    |> Repo.all(Membership.Plan)
    |> Repo.preload(:features)
    |> Enum.map(fn x ->
      features = Enum.map(x.features, fn f -> f.identifier end)
      {x.identifier, features}
    end)
  end

  def all(config) do
    config
    |> Repo.all(Membership.Plan)
    |> Repo.preload(:features)
    |> Enum.map(fn x ->
      features = Enum.map(x.features, fn f -> f.identifier end)
      {x.identifier, features}
    end)
  end
end
