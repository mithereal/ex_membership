defmodule Membership.RoleFeatureAdmin do
  @behaviour Kaffy.ResourceAdmin

  alias Membership.Repo
  alias Membership.{RoleFeatures, Role, Feature}
  import Ecto.Query

  # Show all entries
  def index(_conn) do
    Repo.all(RoleFeatures)
  end

  # Create a new changeset
  def build(_conn), do: %RoleFeatures{}

  # Get an entry using simulated composite key
  def get(%{"role_id" => role_id, "feature_id" => feature_id}) do
    Repo.get_by!(RoleFeatures, role_id: role_id, feature_id: feature_id)
  end

  # Parse Kaffy's string ID like "123:456"
  def get(id) when is_binary(id) do
    [role_id_str, feature_id_str] = String.split(id, ":")

    # Convert IDs to integers (or UUIDs if you're using UUIDs)
    {role_id, _} = Integer.parse(role_id_str)
    {feature_id, _} = Integer.parse(feature_id_str)

    get(%{"role_id" => role_id, "feature_id" => feature_id})
  end

  # Create a record
  def create(attrs) do
    %RoleFeatures{}
    |> RoleFeatures.changeset(attrs)
    |> Repo.insert()
  end

  # Update a record
  def update(role_feature, attrs) do
    role_feature
    |> RoleFeatures.changeset(attrs)
    |> Repo.update()
  end

  # Delete a record
  def delete(role_feature) do
    Repo.delete(role_feature)
  end

  # Define how the form looks
  def changeset(schema, params) do
    RoleFeatures.changeset(schema, params)
  end

  def form_fields(_conn) do
    [
      role_id: %{type: :select, choices: role_choices()},
      feature_id: %{type: :select, choices: feature_choices()}
    ]
  end

  defp role_choices do
    Repo.all(Role)
    |> Enum.map(&{&1.identifier, &1.id})
  end

  defp feature_choices do
    Repo.all(Feature)
    |> Enum.map(&{&1.name, &1.id})
  end

  # Simulate ordering
  @impl true
  def ordering(_schema) do
    [asc: :role_id]
  end

  # Kaffy uses `to_string/1` to render row IDs in URLs
  # So we override this to use our composite key
  defimpl String.Chars, for: Roleship.RoleFeatures do
    def to_string(struct) do
      "#{struct.role_id}:#{struct.feature_id}"
    end
  end
end
