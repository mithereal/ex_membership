defmodule Membership.Member do
  @moduledoc """
  Member is a main actor for determining features
  """
  use Membership.Schema

  @primary_key {:id, Membership.Config.key_type(), autogenerate: true}
  @foreign_key_type Membership.Config.key_type()

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

  @default_alphabet Enum.concat([?0..?9, ?A..?Z, ?a..?z])
  @default_membership_identifier_size 8

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
    |> cast(params, [:identifier, :features])
    |> generate_identifier()
    |> cast_assoc(:plans, required: false)
    |> cast_assoc(:roles, required: false)
    |> cast_assoc(:extra_features, required: false)
  end

  def generate_identifier(changeset) do
    size = Membership.Config.get(:membership_identifier_size, @default_membership_identifier_size)
    alphabet = Membership.Config.get(:membership_identifier_alphabet, @default_alphabet)
    changeset |> put_change(:identifier, Nanoid.generate(size, alphabet))
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
  def grant(%Member{id: id} = _member, %Plan{id: plan_id} = _plan) do
    repo = Membership.Repo.repo()
    member = Member |> repo.get!(id)
    plan = Plan |> repo.get!(plan_id)

    revoke(member, plan)

    %MemberPlans{member_id: member.id, plan_id: plan.id}
    |> repo.insert()

    sync_features(member)
  end

  def grant(%{member: %Member{id: _pid} = member}, %Plan{id: _id} = plan) do
    grant(member, plan)
  end

  def grant(%{member_id: id}, %Plan{id: _id} = plan) do
    %Member{id: id}
    |> grant(plan)
  end

  def grant(%Member{id: id} = _member, %Role{id: role_id} = _role) do
    repo = Membership.Repo.repo()
    member = Member |> repo.get!(id)
    role = Role |> repo.get!(role_id)

    revoke(member, role)

    %MemberRoles{member_id: member.id, role_id: role.id}
    |> repo.insert()

    sync_features(member)
  end

  def grant(%{member: %Member{id: _pid} = member}, %Role{id: _id} = role) do
    grant(member, role)
  end

  def grant(%{member_id: id}, %Role{id: _id} = role) do
    %Member{id: id}
    |> grant(role)
  end

  def grant(_, _), do: raise(ArgumentError, message: "Bad arguments for giving grant")

  def grant(%Member{id: id} = _member, %Feature{id: feature_id} = _feature, permission) do
    repo = Membership.Repo.repo()
    member = Member |> repo.get!(id)
    feature = Feature |> repo.get(feature_id)

    %MemberFeatures{member_id: member.id, feature_id: feature.id, permission: permission}
    |> repo.insert()

    sync_features(member)
  end

  def grant(%{member: member}, %Feature{id: _id} = feature, permission) do
    member
    |> grant(feature, permission)
  end

  def grant(%{member_id: id}, %Feature{id: _id} = feature, permission) do
    %Member{id: id}
    |> grant(feature, permission)
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
    repo = Membership.Repo.repo()

    from(pa in MemberPlans)
    |> where([pr], pr.member_id == ^id and pr.plan_id == ^plan.id)
    |> repo.delete_all()
  end

  def revoke(%{member: %Member{id: _pid} = member}, %Plan{id: _id} = plan) do
    revoke(member, plan)
  end

  def revoke(%{member_id: id}, %Plan{id: _id} = plan) do
    revoke(%Member{id: id}, plan)
  end

  def revoke(%Member{id: id} = _member, %Role{id: _id} = role) do
    repo = Membership.Repo.repo()

    from(pa in MemberRoles)
    |> where([pr], pr.member_id == ^id and pr.role_id == ^role.id)
    |> repo.delete_all()
  end

  def revoke(%{member: %Member{id: _pid} = member}, %Role{id: _id} = role) do
    revoke(member, role)
  end

  def revoke(%{member_id: id}, %Role{id: _id} = role) do
    revoke(%Member{id: id}, role)
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
    repo = Membership.Repo.repo()
    member = Member |> repo.get!(id)

    features =
      Enum.filter(member.features, fn grant ->
        grant != feature.identifier
      end)

    changeset(member)
    |> put_change(:features, features)
    |> repo.update!()
  end

  def revoke(_, _), do: raise(ArgumentError, message: "Bad arguments for revoking grant")

  def revoke(_, _, _), do: raise(ArgumentError, message: "Bad arguments for revoking grant")

  def load_member_feature(member, %{
        __struct__: _feature_name,
        id: feature_id,
        identifier: _identifier
      }) do
    repo = Membership.Repo.repo()

    MemberFeatures
    |> where(
      [e],
      e.member_id == ^member.id and e.feature_id == ^feature_id
    )
    |> repo.one()
  end

  def load_member_plan(member, %{
        __struct__: _plan_name,
        id: plan_id,
        identifier: _identifier
      }) do
    repo = Membership.Repo.repo()

    MemberPlans
    |> where(
      [e],
      e.member_id == ^member.id and e.plan_id == ^plan_id
    )
    |> repo.one()
  end

  def load_member_role(member, %{
        __struct__: _role_name,
        id: role_id,
        identifier: _identifier
      }) do
    repo = Membership.Repo.repo()

    MemberRoles
    |> where(
      [e],
      e.member_id == ^member.id and e.role_id == ^role_id
    )
    |> repo.one()
  end

  @doc """
  Sync features column with the member features and member plans pivot tables.
  we do this for caching reasons, ie holding the plan[feature] and extra feature identifiers summed
  into a list and stored in features column of the member, we  query this to see if member has
  ex feature vs repo lookup by plan and checking if plan has said feature
  """
  @spec sync_features(Member.t()) :: Member.t()
  def sync_features(%Member{id: id} = _member) do
    repo = Membership.Repo.repo()

    member =
      Member
      |> repo.get!(id)
      |> repo.preload(plans: :features)
      |> repo.preload(roles: :features)
      |> repo.preload(:extra_features)

    plan_features =
      Enum.map(member.plans, fn x ->
        x.features
        |> Enum.map(fn f ->
          f.identifier
        end)
      end)
      |> List.flatten()

    extra_features =
      Enum.map(member.extra_features, fn x ->
        x.identifier
      end)

    role_features =
      Enum.map(member.roles, fn x ->
        x.features
        |> Enum.map(fn f ->
          f.identifier
        end)
      end)

    feature_removals = fetch_removed_features(member.id)

    features =
      List.flatten(
        Enum.uniq(member.features ++ plan_features ++ role_features ++ extra_features) --
          feature_removals
      )

    changeset(member)
    |> put_change(:features, features)
    |> repo.update!()
  end

  def build(name) do
    changeset(%Member{}, %{
      name: name
    })
    |> Ecto.Changeset.apply_changes()
  end

  def create(name) do
    repo = Membership.Repo.repo()

    changeset(%Member{}, %{
      name: name
    })
    |> repo.insert_or_update()
  end

  def table, do: :membership_members

  def fetch_removed_features(id) do
    repo = Membership.Repo.repo()

    repo.all(
      from(mf in MemberFeatures,
        join: f in Feature,
        on: mf.feature_id == f.id,
        where: mf.member_id == ^id and mf.permission != "required",
        select: f.identifier
      )
    )
  end
end
