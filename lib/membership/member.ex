defmodule Post do
  defstruct name: "john"
end

defmodule Membership.Member do
  @moduledoc """
  Member is a main actor for determining features
  """
  use Membership.Schema
  import Ecto.Changeset
  import Ecto.Query

  alias Membership.Plan
  alias Membership.Feature
  alias Membership.MemberPlans
  alias Membership.MemberFeatures

  alias Membership.Repo

  alias Membership.Member

  @typedoc "A member struct"
  @type t :: %Member{}

  schema "membership_members" do
    field(:features, {:array, :string}, default: [])

    many_to_many(:plans, Membership.Plan,
      join_through: Membership.PlanFeatures,
      on_replace: :delete
    )

    many_to_many(:extra_features, Membership.Feature,
      join_through: Membership.MemberFeatures,
      on_replace: :delete
    )

    timestamps()
  end

  def changeset(%Member{} = struct, params \\ %{}) do
    struct
    |> cast(params, [])
    |> cast_assoc(:plans, required: false)
    |> cast_assoc(:extra_features, required: false)
  end

  @doc """
  Grant given grant type to a member.

  ## Examples

  Function accepts either `Membership.Feature` or `Membership.Plan` grants.
  Function is merging existing grants with the new ones, so calling grant with same
  grants will not duplicate entries in table.

  To grant particular feature to a given member

      iex> Membership.Member.grant(%Membership.Member{id: 1}, %Membership.Feature{id: 1})

  To grant particular plan to a given member

      iex> Membership.Member.grant(%Membership.Member{id: 1}, %Membership.Plan{id: 1})

  """

  @spec grant(Member.t(), Feature.t() | Plan.t()) :: Member.t()
  def grant(%Member{id: id} = _member, %Plan{id: _id} = plan) do
    # Preload member plans
    member = Member |> Repo.get!(id) |> Repo.preload([:plans])

    plans = merge_uniq_grants(member.plans ++ [plan])

    changeset =
      changeset(member)
      |> put_assoc(:plans, plans)

    changeset |> Repo.update!()
  end

  def grant(%{member: %Member{id: _pid} = member}, %Plan{id: _id} = plan) do
    grant(member, plan)
  end

  def grant(%{member_id: id}, %Plan{id: _id} = plan) do
    member = Member |> Repo.get!(id)
    grant(member, plan)
  end

  def grant(%Member{id: id} = _member, %Feature{id: _id} = feature) do
    member = Member |> Repo.get!(id)
    features = Enum.uniq(member.features ++ [feature.identifier])

    changeset =
      changeset(member)
      |> put_change(:features, features)

    changeset |> Repo.update!()
  end

  def grant(%{member: %Member{id: id}}, %Feature{id: _id} = feature) do
    member = Member |> Repo.get!(id)
    grant(member, feature)
  end

  def grant(%{member_id: id}, %Feature{id: _id} = feature) do
    member = Member |> Repo.get!(id)
    grant(member, feature)
  end

  def grant(_, _), do: raise(ArgumentError, message: "Bad arguments for giving grant")

  def grant(
        %Member{id: _pid} = member,
        %Feature{id: _aid} = feature,
        %Feature{id: _aid} = extra_feature
      ) do
    features = load_member_features(member, feature)

    case features do
      nil ->
        features = Enum.uniq(member.features ++ [feature])

        MemberFeatures.create(member, extra_feature.identifier)

        MemberFeatures.changeset(feature)
        |> put_change(:features, features)
        |> Repo.update!()

      feature ->
        MemberFeatures.create(member, extra_feature.identifier)
        feature
    end

    member
  end

  def grant(
        %Member{id: _pid} = member,
        %Feature{id: _aid} = feature,
        %Plan{id: _aid} = plan
      ) do
    features = load_member_features(member, feature)

    case features do
      nil ->
        features = Enum.uniq(member.features ++ [feature])

        MemberFeatures.changeset(feature)
        |> put_change(:features, features)
        |> Repo.update!()

        Plan.create(member, plan)

      feature ->
        Plan.create(member, plan)
        feature
    end

    member
  end

  def grant(
        %{member_id: id},
        %Feature{id: _id} = feature,
        %{__struct__: _feature_name, id: _feature_id} = feature
      ) do
    grant(%Member{id: id}, feature, feature)
  end

  def grant(
        %{member: %Member{id: _pid} = member},
        %Feature{id: _id} = feature,
        %{__struct__: _feature_name, id: _feature_id} = feature
      ) do
    grant(member, feature, feature)
  end

  def grant(_, _, _), do: raise(ArgumentError, message: "Bad arguments for giving grant")

  @doc """
  Revoke given grant type from a member.

  ## Examples

  Function accepts either `Membership.Feature` or `Membership.Plan` grants.
  Function is directly opposite of `Membership.Member.grant/2`

  To revoke particular feature from a given member

      iex> Membership.Member.revoke(%Membership.Member{id: 1}, %Membership.Feature{id: 1})

  To revoke particular plan from a given member

      iex> Membership.Member.revoke(%Membership.Member{id: 1}, %Membership.Plan{id: 1})

  """
  @spec revoke(Member.t(), Feature.t() | Plan.t()) :: Member.t()
  def revoke(%Member{id: id} = _member, %Plan{id: _id} = plan) do
    from(pa in MemberPlans)
    |> where([pr], pr.member_id == ^id and pr.plan_id == ^plan.id)
    |> Repo.delete_all()
  end

  def revoke(%{member: %Member{id: _pid} = member}, %Plan{id: _id} = plan) do
    revoke(member, plan)
  end

  def revoke(%{member_id: id}, %Plan{id: _id} = plan) do
    revoke(%Member{id: id}, plan)
  end

  def revoke(%Member{id: id} = _member, %Feature{id: _id} = feature) do
    member = Member |> Repo.get!(id)

    features =
      Enum.filter(member.features, fn grant ->
        grant != feature.identifier
      end)

    changeset =
      changeset(member)
      |> put_change(:features, features)

    changeset |> Repo.update!()
  end

  def revoke(
        %{member: %Member{id: _pid} = member},
        %Feature{id: _id} = feature
      ) do
    revoke(member, feature)
  end

  def revoke(%{member_id: id}, %Feature{id: _id} = feature) do
    revoke(%Member{id: id}, feature)
  end

  def revoke(_, _), do: raise(ArgumentError, message: "Bad arguments for revoking grant")

  def revoke(
        %Member{id: _pid} = member,
        %Feature{id: _id} = feature,
        %{__struct__: _feature_name, id: _feature_id} = feature
      ) do
    feature_features = load_member_features(member, feature)

    case feature_features do
      nil ->
        member

      feature ->
        features =
          Enum.filter(feature.features, fn grant ->
            grant != feature.identifier
          end)

        if length(features) == 0 do
          feature |> Repo.delete!()
        else
          MemberFeatures.changeset(feature)
          |> put_change(:features, features)
          |> Repo.update!()
        end

        member
    end
  end

  def revoke(
        %{member_id: id},
        %Feature{id: _id} = feature,
        %{__struct__: _feature_name, id: _feature_id} = feature
      ) do
    revoke(%Member{id: id}, feature, feature)
  end

  def revoke(
        %{member: %Member{id: _pid} = member},
        %Feature{id: _id} = feature,
        %{__struct__: _feature_name, id: _feature_id} = feature
      ) do
    revoke(member, feature, feature)
  end

  def revoke(_, _, _), do: raise(ArgumentError, message: "Bad arguments for revoking grant")

  def load_member_features(member, %{
        __struct__: _feature_name,
        id: feature_id,
        identifier: _identifier
      }) do
    MemberFeatures
    |> where(
      [e],
      e.member_id == ^member.id and e.feature_id == ^feature_id
    )
    |> Repo.one()
  end

  def table, do: :membership_members

  defp merge_uniq_grants(grants) do
    Enum.uniq_by(grants, fn grant ->
      grant.identifier
    end)
  end

  def normalize_struct_name(name) do
    name
    |> Atom.to_string()
    |> String.replace(".", "_")
    |> String.downcase()
  end
end
