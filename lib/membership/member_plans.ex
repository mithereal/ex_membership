defmodule Membership.MemberPlans do
  @moduledoc """
  MemberPlans is the association linking the member to the plan you can also set specific features for the membership
  """

  use Membership.Schema, type: :binary_fk

  alias Membership.Member
  alias Membership.Plan
  alias Membership.MemberPlans

  schema "membership_member_plans" do
    # Virtual ID field (for Kaffy)
    field(:id, :string, virtual: true)

    belongs_to(:member, Member)
    belongs_to(:plan, Plan)
  end

  def changeset(%MemberPlans{} = struct, params \\ %{}) do
    struct
    |> cast(params, [:member_id, :plan_id])
    |> validate_required([:member_id, :plan_id])
  end

  def create(
        %Member{id: id},
        %{__struct__: _plan_name, id: plan_id},
        _features \\ []
      ) do
    repo = Membership.Repo.repo()

    changeset(%MemberPlans{
      member_id: id,
      plan_id: plan_id
    })
    |> repo.insert!()
  end

  def table, do: :membership_member_plans

  def index(_conn) do
    repo = Membership.Repo.repo()

    repo.all(MemberPlans)
    |> Enum.map(&with_virtual_id/1)
  end

  def get(%{"member_id" => member_id, "plan_id" => plan_id}) do
    repo = Membership.Repo.repo()

    repo.get_by!(MemberPlans, member_id: member_id, plan_id: plan_id)
    |> with_virtual_id()
  end

  def get(id) when is_binary(id) do
    case String.split(id, ":") do
      [member_id_str, plan_id_str] ->
        get(%{"member_id" => member_id_str, "plan_id" => plan_id_str})

      _ ->
        raise "Invalid ID format. Expected 'member_id:plan_id'"
    end
  end

  defp with_virtual_id(struct) do
    %{struct | id: "#{struct.member_id}:#{struct.plan_id}"}
  end
end
