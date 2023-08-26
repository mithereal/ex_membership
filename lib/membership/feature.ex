defmodule Membership.Feature do
  @moduledoc """
  Feature is main representation of a single feature flag assigned to a plan
  """
  use Membership.Schema
  import Ecto.Changeset

  alias Membership.Feature

  @typedoc "A Feature struct"
  @type t :: %Feature{}

  schema "membership_features" do
    field(:identifier, :string)
    field(:name, :string)
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

  def table, do: :membership_features

  @doc """
  Grant given grant type to a member.

  ## Examples

  Function accepts either `Membership.Feature` or `Membership.Plan` grants.
  Function is merging existing grants with the new ones, so calling grant with same
  grants will not duplicate entries in table.

  To grant particular feature to a given member

      iex> Membership.Member.grant(%Membership.Member{id: 1}, %Membership.Feature{id: 1})

  To grant particular feature to a given plan

      iex> Membership.Feature.grant(%Membership.Feature{id: 1}, %Membership.Plan{id: 1})

  """

  @spec grant(Feature.t(), Feature.t() | Plan.t()) :: Member.t()
  def grant(%Feature{id: id} = _member, %Plan{id: _id} = plan) do
    # Preload Feature plans
    member = Feature |> Repo.get!(id) |> Repo.preload([:plans])

    plans = merge_uniq_grants(member.plans ++ [plan])

    changeset =
      changeset(member)
      |> put_assoc(:plans, plans)

    changeset |> Repo.update!()
  end

  def grant(%{feature: %Feature{id: _pid} = feature}, %Plan{id: _id} = plan) do
    grant(feature, plan)
  end

  def grant(%{feature_id: id}, %Plan{id: _id} = plan) do
    feature = Feature |> Repo.get!(id)
    grant(feature, plan)
  end

  #### todo
  def grant(%Plan{id: id} = _member, %Feature{id: _id} = feature) do
    plan = Plan |> Repo.get!(id)
    features = Enum.uniq(plan.features ++ [feature.identifier])

    changeset =
      Plan.changeset(plan)
      |> put_change(:features, features)

    changeset |> Repo.update!()
  end

  def grant(%{plan: %Plan{id: id}}, %Feature{id: _id} = feature) do
    plan = Plan |> Repo.get!(id)
    grant(plan, feature)
  end

  def grant(%{plan_id: id}, %Feature{id: _id} = feature) do
    plan = Member |> Repo.get!(id)
    grant(plan, feature)
  end

  def grant(_, _), do: raise(ArgumentError, message: "Bad arguments for giving grant")

  def grant(
        %Plan{id: _pid} = plan,
        %Feature{id: _aid} = feature,
        %{__struct__: _feature_name, id: _feature_id} = feature
      ) do
    features = load_plan_features(plan, feature)

    case features do
      nil ->
        PlanFeatures.create(plan, feature, [feature.identifier])

      feature ->
        features = Enum.uniq(feature.features ++ [feature.identifier])

        PlanFeatures.changeset(feature)
        |> put_change(:features, features)
        |> Repo.update!()
    end

    plan
  end

  def grant(
        %{plan_id: id},
        %Feature{id: _id} = feature,
        %{__struct__: _feature_name, id: _feature_id} = feature
      ) do
    grant(%Plan{id: id}, feature, feature)
  end

  def grant(
        %{member: %Plan{id: _pid} = plan},
        %Feature{id: _id} = feature,
        %{__struct__: _feature_name, id: _feature_id} = feature
      ) do
    grant(plan, feature, feature)
  end

  def grant(_, _, _), do: raise(ArgumentError, message: "Bad arguments for giving grant")

  @doc """
  Revoke given grant type from a member.

  ## Examples

  Function accepts either `Membership.Feature` or `Membership.Plan` grants.
  Function is directly opposite of `Membership.Member.grant/2`

  To revoke particular feature from a given plan

      iex> Membership.Feature.revoke(%Membership.Plan{id: 1}, %Membership.Feature{id: 1})

  To revoke particular plan from a given feature

      iex> Membership.Feature.revoke(%Membership.Feature{id: 1}, %Membership.Plan{id: 1})

  """
  @spec revoke(Plan.t(), Feature.t() | Plan.t()) :: Member.t()
  def revoke(%Plan{id: id} = _, %Plan{id: _id} = plan) do
    from(pa in PlanFeatures)
    |> where([pr], pr.feature_id == ^id and pr.plan_id == ^plan.id)
    |> Repo.delete_all()
  end

  def revoke(%{feature: %Feature{id: _pid} = feature}, %Plan{id: _id} = plan) do
    revoke(feature, plan)
  end

  def revoke(%{feature_id: id}, %Plan{id: _id} = plan) do
    revoke(%Feature{id: id}, plan)
  end

  def revoke(%Plan{id: id} = _member, %Feature{id: _id} = feature) do
    plan = Plan |> Repo.get!(id)

    features =
      Enum.filter(plan.features, fn grant ->
        grant != feature.identifier
      end)

    changeset =
      changeset(member)
      |> put_change(:features, features)

    changeset |> Repo.update!()
  end

  def revoke(
        %{plan: %Plan{id: _pid} = plan},
        %Feature{id: _id} = feature
      ) do
    revoke(plan, feature)
  end

  def revoke(%{plan_id: id}, %Feature{id: _id} = feature) do
    revoke(%Plan{id: id}, feature)
  end

  def revoke(_, _), do: raise(ArgumentError, message: "Bad arguments for revoking grant")

  def revoke(
        %Plan{id: _pid} = plan,
        %Feature{id: _id} = feature,
        %{__struct__: _feature_name, id: _feature_id} = feature
      ) do
    feature_features = load_plan_features(plan, feature)

    case feature_features do
      nil ->
        plan

      feature ->
        features =
          Enum.filter(feature.features, fn grant ->
            grant != feature.identifier
          end)

        if length(features) == 0 do
          feature |> Repo.delete!()
        else
          PlanFeatures.changeset(feature)
          |> put_change(:features, features)
          |> Repo.update!()
        end

        plan
    end
  end

  def revoke(
        %{plan_id: id},
        %Feature{id: _id} = plan,
        %{__struct__: _feature_name, id: _feature_id} = feature
      ) do
    revoke(%Plan{id: id}, feature, feature)
  end

  def revoke(
        %{plan: %Plan{id: _pid} = plan},
        %Feature{id: _id} = feature,
        %{__struct__: _feature_name, id: _feature_id} = feature
      ) do
    revoke(plan, feature, feature)
  end

  def revoke(_, _, _), do: raise(ArgumentError, message: "Bad arguments for revoking grant")

  def load_plan_features(plan, %{
        __struct__: _feature_name,
        id: feature_id,
        identifier: identifier
      }) do
    PlanFeatures
    |> where(
      [e],
      e.plan_id == ^plan.id and e.feature_id == ^feature_id
    )
    |> Repo.one()
  end
end
