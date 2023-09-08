defmodule Post do
  defstruct name: "john"
end

defmodule Membership.Member do
  @moduledoc """
  Member is a main actor for determining features
  """
  use Membership.Schema

  import Ecto.Query

  alias Membership.Plan
  alias Membership.Feature
  alias Membership.Role
  alias Membership.MemberPlans
  alias Membership.MemberFeatures
  alias Membership.MemberRoles

  alias Membership.Member

  @typedoc "A member struct"
  @type t :: %Member{}

  schema "membership_members" do
    field(:features, {:array, :string}, default: [])
    field(:identifier, :string, default: nil)

    many_to_many(:plans, Plan,
      join_through: MemberPlans,
      on_replace: :delete
    )

    many_to_many(:extra_features, Feature,
      join_through: MemberFeatures,
      on_replace: :delete
    )

    many_to_many(:roles, Role,
      join_through: MemberRoles,
      on_replace: :delete
    )

    timestamps()
  end

  def changeset(%Member{} = struct, params \\ %{}) do
    struct
    |> cast(params, [])
    |> cast_assoc(:plans, required: false)
    |> cast_assoc(:roles, required: false)
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
    member = Member |> Repo.get!(id) |> Repo.preload(plans: :plan)
    plans = merge_uniq_grants(member.plans ++ [plan])

    changeset(member, %{plans: plans}) |> Repo.update!()
  end

  def grant(%{member: %Member{id: _pid} = member}, %Plan{id: _id} = plan) do
    grant(member, plan)
  end

  def grant(%{member_id: id}, %Plan{id: _id} = plan) do
    member = Member |> Repo.get!(id)
    grant(member, plan)
  end

  def grant(%Member{id: id} = _member, %Feature{id: _id} = feature) do
    member = Member |> Repo.get!(id) |> Repo.preload([:extra_features])
    extra_features = merge_uniq_grants(member.extra_features ++ [feature])

    changeset(member, %{extra_features: extra_features}) |> Repo.update!()
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

  def revoke(
        %{member: %Member{id: _pid} = member},
        %Feature{id: _id} = feature
      ) do
    revoke(member, feature)
  end

  def revoke(%{member_id: id}, %Feature{id: _id} = feature) do
    revoke(%Member{id: id}, feature)
  end

  def revoke(%Member{id: id} = _member, %Feature{id: _id} = feature) do
    member = Member |> Repo.get!(id) |> Repo.preload(:features)

    features =
      Enum.filter(member.features, fn grant ->
        grant != feature.identifier
      end)

    changeset =
      changeset(member)
      |> put_change(:features, features)

    changeset |> Repo.update!()
  end

  def revoke(_, _), do: raise(ArgumentError, message: "Bad arguments for revoking grant")

  def revoke(_, _, _), do: raise(ArgumentError, message: "Bad arguments for revoking grant")

  def load_member_feature(member, %{
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

  def load_member_plan(member, %{
        __struct__: _plan_name,
        id: plan_id,
        identifier: _identifier
      }) do
    MemberPlans
    |> where(
      [e],
      e.member_id == ^member.id and e.plan_id == ^plan_id
    )
    |> Repo.one()
  end

  def load_member_role(member, %{
        __struct__: _role_name,
        id: role_id,
        identifier: _identifier
      }) do
    MemberRoles
    |> where(
      [e],
      e.member_id == ^member.id and e.role_id == ^role_id
    )
    |> Repo.one()
  end

  @doc """
  Sync features column with the member features and member plans pivot tables.
  we do this for caching reasons, ie holding the plan[feature] and extra feature identifiers summed
  into a list and stored in features column of the member, we  query this to see if member has
  ex feature vs repo lookup by plan and checking if plan has said feature
  """
  @spec sync_features(Member.t()) :: Member.t()
  def sync_features(%Member{id: id} = _member) do
    member =
      Member
      |> Repo.get!(id)
      |> Repo.preload(plans: :plan)
      |> Repo.preload(roles: :role)
      |> Repo.preload(extra_features: :feature)

    plan_features =
      Enum.map(member.plans, fn x ->
        x.features
        |> Enum.map(fn f ->
          f.identifier
        end)
      end)

    extra_features =
      Enum.map(member.extra_features, fn x ->
        x.identifier
        |> Enum.map(fn f ->
          f.identifier
        end)
      end)

    role_features =
      Enum.map(member.roles, fn x ->
        x.features
        |> Enum.map(fn f ->
          f.identifier
        end)
      end)

    features =
      Enum.uniq(List.flatten(member.features ++ plan_features ++ role_features ++ extra_features))

    changeset(member, %{features: features}) |> Repo.update!(features)
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
