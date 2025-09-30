defmodule Membership.PlanFeatureAdmin do
  @behaviour Kaffy.ResourceAdmin
  @repo Membership.Repo.repo()

  alias Membership.{PlanFeatures, Plan, Feature}
  import Ecto.Query

  def plural_name(_) do
    "Plan Features"
  end

  # Show all entries
  def index(conn) do
    PlanFeatures.index(conn)
  end

  # Create a new changeset
  def build(_conn), do: %PlanFeatures{}

  # Get an entry using simulated composite key
  def get(%{"plan_id" => plan_id, "feature_id" => feature_id}) do
    @repo.get_by!(PlanFeatures, plan_id: plan_id, feature_id: feature_id)
  end

  # Parse Kaffy's string ID like "123:456"
  def get(id) when is_binary(id) do
    [plan_id_str, feature_id_str] = String.split(id, ":")

    # Convert IDs to integers (or UUIDs if you're using UUIDs)
    {plan_id, _} = Integer.parse(plan_id_str)
    {feature_id, _} = Integer.parse(feature_id_str)

    get(%{"plan_id" => plan_id, "feature_id" => feature_id})
  end

  # Create a record
  def create(attrs) do
    %PlanFeatures{}
    |> PlanFeatures.changeset(attrs)
    |> @repo.insert()
  end

  # Update a record
  def update(plan_feature, attrs) do
    plan_feature
    |> PlanFeatures.changeset(attrs)
    |> @repo.update()
  end

  # Delete a record
  def delete(plan_feature) do
    @repo.delete(plan_feature)
  end

  # Define how the form looks
  def changeset(schema, params) do
    PlanFeatures.changeset(schema, params)
  end

  def form_fields(_conn) do
    [
      plan_id: %{type: :select, choices: plan_choices()},
      feature_id: %{type: :select, choices: feature_choices()}
    ]
  end

  defp plan_choices do
    @repo.all(Plan)
    |> Enum.map(&{&1.identifier, &1.id})
  end

  defp feature_choices do
    @repo.all(Feature)
    |> Enum.map(&{&1.name, &1.id})
  end

  # Simulate ordering
  @impl true
  def ordering(_schema) do
    [asc: :plan_id]
  end

  # Kaffy uses `to_string/1` to render row IDs in URLs
  # So we override this to use our composite key
  defimpl String.Chars, for: Planship.PlanFeatures do
    def to_string(struct) do
      "#{struct.plan_id}:#{struct.feature_id}"
    end
  end
end
