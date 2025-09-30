defmodule Membership.MemberFeatureAdmin do
  @behaviour Kaffy.ResourceAdmin
  @repo Membership.Repo.repo()

  alias Membership.Member
  alias Membership.Feature
  alias Membership.MemberFeatures

  import Ecto.Query

  def plural_name(_) do
    "Member Features"
  end

  # Show all entries
  def index(conn) do
    MemberFeatures.index(conn)
  end

  # Create a new changeset
  def build(_conn), do: %MemberFeatures{}

  # Get an entry using simulated composite key
  def get(%{"member_id" => member_id, "feature_id" => feature_id}) do
    @repo.get_by!(MemberFeatures, member_id: member_id, feature_id: feature_id)
  end

  # Parse Kaffy's string ID like "123:456"
  def get(id) when is_binary(id) do
    [member_id_str, feature_id_str] = String.split(id, ":")

    # Convert IDs to integers (or UUIDs if you're using UUIDs)
    {member_id, _} = Integer.parse(member_id_str)
    {feature_id, _} = Integer.parse(feature_id_str)

    get(%{"member_id" => member_id, "feature_id" => feature_id})
  end

  # Create a record
  def create(attrs) do
    %MemberFeatures{}
    |> MemberFeatures.changeset(attrs)
    |> @repo.insert()
  end

  # Update a record
  def update(member_feature, attrs) do
    member_feature
    |> MemberFeatures.changeset(attrs)
    |> @repo.update()
  end

  # Delete a record
  def delete(member_feature) do
    @repo.delete(member_feature)
  end

  # Define how the form looks
  def changeset(schema, params) do
    MemberFeatures.changeset(schema, params)
  end

  def form_fields(_conn) do
    [
      member_id: %{type: :select, choices: member_choices()},
      feature_id: %{type: :select, choices: feature_choices()}
    ]
  end

  defp member_choices do
    @repo.all(Member)
    |> Enum.map(&{&1.identifier, &1.id})
  end

  defp feature_choices do
    @repo.all(Feature)
    |> Enum.map(&{&1.name, &1.id})
  end

  # Simulate ordering
  @impl true
  def ordering(_schema) do
    [asc: :member_id]
  end

  # Kaffy uses `to_string/1` to render row IDs in URLs
  # So we override this to use our composite key
  defimpl String.Chars, for: Membership.MemberFeatures do
    def to_string(struct) do
      "#{struct.member_id}:#{struct.feature_id}"
    end
  end
end
