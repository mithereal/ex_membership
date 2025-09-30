defmodule Membership.MemberPlanAdmin do
  @behaviour Kaffy.ResourceAdmin
  @repo Membership.Repo.repo()

  import Ecto.Query
  alias Membership.Member
  alias Membership.Plan
  alias Membership.MemberPlans

  def plural_name(_) do
    "Member Plans"
  end

  # Show all entries
  def index(conn) do
    MemberPlans.index(conn)
  end

  # Create a new changeset
  def build(_conn), do: %MemberPlans{}

  # Get an entry using simulated composite key
  def get(%{"member_id" => member_id, "plan_id" => plan_id}) do
    @repo.get_by!(MemberPlans, member_id: member_id, plan_id: plan_id)
  end

  # Parse Kaffy's string ID like "123:456"
  def get(id) when is_binary(id) do
    [member_id_str, plan_id_str] = String.split(id, ":")

    # Convert IDs to integers (or UUIDs if you're using UUIDs)
    {member_id, _} = Integer.parse(member_id_str)
    {plan_id, _} = Integer.parse(plan_id_str)

    get(%{"member_id" => member_id, "plan_id" => plan_id})
  end

  # Create a record
  def create(attrs) do
    %MemberPlans{}
    |> MemberPlans.changeset(attrs)
    |> @repo.insert()
  end

  # Update a record
  def update(member_plan, attrs) do
    member_plan
    |> MemberPlans.changeset(attrs)
    |> @repo.update()
  end

  # Delete a record
  def delete(member_plan) do
    @repo.delete(member_plan)
  end

  # Define how the form looks
  def changeset(schema, params) do
    MemberPlans.changeset(schema, params)
  end

  def form_fields(_conn) do
    [
      member_id: %{type: :select, choices: member_choices()},
      plan_id: %{type: :select, choices: plan_choices()}
    ]
  end

  defp member_choices do
    @repo.all(Member)
    |> Enum.map(&{&1.identifier, &1.id})
  end

  defp plan_choices do
    @repo.all(Plan)
    |> Enum.map(&{&1.name, &1.id})
  end

  # Simulate ordering
  @impl true
  def ordering(_schema) do
    [asc: :member_id]
  end

  # Kaffy uses `to_string/1` to render row IDs in URLs
  # So we override this to use our composite key
  defimpl String.Chars, for: Membership.MemberPlans do
    def to_string(struct) do
      "#{struct.member_id}:#{struct.plan_id}"
    end
  end
end
