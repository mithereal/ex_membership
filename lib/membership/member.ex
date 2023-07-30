defmodule Post do
  defstruct name: "john"
end

defmodule Membership.Member do
  @moduledoc """
  Member is a main actor for determining abilities
  """
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  alias __MODULE__
  alias Membership.Plan
  alias Membership.Repo
  alias Membership.MemberPlans

  @typedoc "A member struct"
  @type t :: %Member{}

  schema "membership_members" do
    has_many(:plans, MemberPlans)

    timestamps()
  end

  def changeset(%Member{} = struct, params \\ %{}) do
    struct
    |> cast(params, [])
  end

  @doc """
  Grant given grant type to a member.

  ## Examples

  Function accepts either `Membership.Ability` or `Membership.Role` grants.
  Function is merging existing grants with the new ones, so calling grant with same
  grants will not duplicate entries in table.

  To grant particular ability to a given member

      iex> Membership.Member.grant(%Membership.Member{id: 1}, %Membership.Ability{id: 1})

  To grant particular role to a given member

      iex> Membership.Member.grant(%Membership.Member{id: 1}, %Membership.Role{id: 1})

  """

  @spec grant(Member.t(), Ability.t() | Role.t()) :: Member.t()
  def grant(%Member{id: id} = _member, %Role{id: _id} = role) do
    # Preload member roles
    member = Member |> Repo.get!(id) |> Repo.preload([:roles])

    roles = merge_uniq_grants(member.roles ++ [role])

    changeset =
      changeset(member)
      |> put_assoc(:roles, roles)

    changeset |> Repo.update!()
  end

  def grant(%{member: %Member{id: _pid} = member}, %Role{id: _id} = role) do
    grant(member, role)
  end

  def grant(%{member_id: id}, %Role{id: _id} = role) do
    member = Member |> Repo.get!(id)
    grant(member, role)
  end

  def grant(%Member{id: id} = _member, %Ability{id: _id} = ability) do
    member = Member |> Repo.get!(id)
    abilities = Enum.uniq(member.abilities ++ [ability.identifier])

    changeset =
      changeset(member)
      |> put_change(:abilities, abilities)

    changeset |> Repo.update!()
  end

  def grant(%{member: %Member{id: id}}, %Ability{id: _id} = ability) do
    member = Member |> Repo.get!(id)
    grant(member, ability)
  end

  def grant(%{member_id: id}, %Ability{id: _id} = ability) do
    member = Member |> Repo.get!(id)
    grant(member, ability)
  end

  def grant(_, _), do: raise(ArgumentError, message: "Bad arguments for giving grant")

  def grant(
        %Member{id: _pid} = member,
        %Ability{id: _aid} = ability,
        %{__struct__: _entity_name, id: _entity_id} = entity
      ) do
    entity_abilities = load_member_entities(member, entity)

    case entity_abilities do
      nil ->
        MembersEntities.create(member, entity, [ability.identifier])

      entity ->
        abilities = Enum.uniq(entity.abilities ++ [ability.identifier])

        MembersEntities.changeset(entity)
        |> put_change(:abilities, abilities)
        |> Repo.update!()
    end

    member
  end

  def grant(
        %{member_id: id},
        %Ability{id: _id} = ability,
        %{__struct__: _entity_name, id: _entity_id} = entity
      ) do
    grant(%Member{id: id}, ability, entity)
  end

  def grant(
        %{member: %Member{id: _pid} = member},
        %Ability{id: _id} = ability,
        %{__struct__: _entity_name, id: _entity_id} = entity
      ) do
    grant(member, ability, entity)
  end

  def grant(_, _, _), do: raise(ArgumentError, message: "Bad arguments for giving grant")

  @doc """
  Revoke given grant type from a member.

  ## Examples

  Function accepts either `Membership.Ability` or `Membership.Role` grants.
  Function is directly opposite of `Membership.Member.grant/2`

  To revoke particular ability from a given member

      iex> Membership.Member.revoke(%Membership.Member{id: 1}, %Membership.Ability{id: 1})

  To revoke particular role from a given member

      iex> Membership.Member.revoke(%Membership.Member{id: 1}, %Membership.Role{id: 1})

  """
  @spec revoke(Member.t(), Ability.t() | Role.t()) :: Member.t()
  def revoke(%Member{id: id} = _member, %Role{id: _id} = role) do
    from(pa in MembersRoles)
    |> where([pr], pr.member_id == ^id and pr.role_id == ^role.id)
    |> Repo.delete_all()
  end

  def revoke(%{member: %Member{id: _pid} = member}, %Role{id: _id} = role) do
    revoke(member, role)
  end

  def revoke(%{member_id: id}, %Role{id: _id} = role) do
    revoke(%Member{id: id}, role)
  end

  def revoke(%Member{id: id} = _member, %Ability{id: _id} = ability) do
    member = Member |> Repo.get!(id)

    abilities =
      Enum.filter(member.abilities, fn grant ->
        grant != ability.identifier
      end)

    changeset =
      changeset(member)
      |> put_change(:abilities, abilities)

    changeset |> Repo.update!()
  end

  def revoke(
        %{member: %Member{id: _pid} = member},
        %Ability{id: _id} = ability
      ) do
    revoke(member, ability)
  end

  def revoke(%{member_id: id}, %Ability{id: _id} = ability) do
    revoke(%Member{id: id}, ability)
  end

  def revoke(_, _), do: raise(ArgumentError, message: "Bad arguments for revoking grant")

  def revoke(
        %Member{id: _pid} = member,
        %Ability{id: _id} = ability,
        %{__struct__: _entity_name, id: _entity_id} = entity
      ) do
    entity_abilities = load_member_entities(member, entity)

    case entity_abilities do
      nil ->
        member

      entity ->
        abilities =
          Enum.filter(entity.abilities, fn grant ->
            grant != ability.identifier
          end)

        if length(abilities) == 0 do
          entity |> Repo.delete!()
        else
          MembersEntities.changeset(entity)
          |> put_change(:abilities, abilities)
          |> Repo.update!()
        end

        member
    end
  end

  def revoke(
        %{member_id: id},
        %Ability{id: _id} = ability,
        %{__struct__: _entity_name, id: _entity_id} = entity
      ) do
    revoke(%Member{id: id}, ability, entity)
  end

  def revoke(
        %{member: %Member{id: _pid} = member},
        %Ability{id: _id} = ability,
        %{__struct__: _entity_name, id: _entity_id} = entity
      ) do
    revoke(member, ability, entity)
  end

  def revoke(_, _, _), do: raise(ArgumentError, message: "Bad arguments for revoking grant")

  def load_member_entities(member, %{__struct__: entity_name, id: entity_id}) do
    MembersEntities
    |> where(
      [e],
      e.member_id == ^member.id and e.assoc_id == ^entity_id and
        e.assoc_type == ^MembersEntities.normalize_struct_name(entity_name)
    )
    |> Repo.one()
  end

  def table, do: :membership_members

  defp merge_uniq_grants(grants) do
    Enum.uniq_by(grants, fn grant ->
      grant.identifier
    end)
  end
end
