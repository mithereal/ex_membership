defmodule Framework.Membership.MemberPlanAdmin do
  @behaviour Kaffy.ResourceAdmin

  alias Framework.Repo
  alias Membership.{MemberPlans, Member, Plan}
  import Ecto.Query

  # Show all entries
  def index(_conn) do
    Repo.all(MemberPlans)
  end

  # Create a new changeset
  def build(_conn), do: %MemberPlans{}

  # Get an entry using simulated composite key
  def get(%{"member_id" => member_id, "plan_id" => plan_id}) do
    Repo.get_by!(MemberPlans, member_id: member_id, plan_id: plan_id)
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
    |> Repo.insert()
  end

  # Update a record
  def update(member_plan, attrs) do
    member_plan
    |> MemberPlans.changeset(attrs)
    |> Repo.update()
  end

  # Delete a record
  def delete(member_plan) do
    Repo.delete(member_plan)
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
    Repo.all(Member)
    |> Enum.map(&{&1.identifier, &1.id})
  end

  defp plan_choices do
    Repo.all(Plan)
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
