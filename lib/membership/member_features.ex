defmodule Membership.MemberFeatures do
  @moduledoc """
  MemberFeatures is the association linking the member to the feature you can also set specific features for the membership
  """

  use Membership.Schema, type: :binary_fk

  alias Membership.Member
  alias Membership.Feature
  alias Membership.MemberFeatures

  schema "membership_member_features" do
    # Virtual ID field (for Kaffy)
    field(:id, :string, virtual: true)

    belongs_to(:member, Member)
    belongs_to(:feature, Feature)
    field(:permission, :string, default: "deny")
  end

  def changeset(%MemberFeatures{} = struct, params \\ %{}) do
    struct
    |> cast(params, [:member_id, :feature_id, :permission])
    |> validate_required([:member_id, :feature_id])
  end

  def create(
        %Member{id: id},
        %{__struct__: _feature_name, id: feature_id},
        permission
      ) do
    repo = Membership.Repo.repo()

    changeset(%MemberFeatures{
      member_id: id,
      feature_id: feature_id,
      permission: permission
    })
    |> repo.insert!()
  end

  def table, do: :membership_member_features

  def index(_conn) do
    Repo.all(MemberFeatures)
    |> Enum.map(&with_virtual_id/1)
  end

  def get(%{"member_id" => member_id, "feature_id" => feature_id}) do
    Repo.get_by!(MemberFeatures, member_id: member_id, feature_id: feature_id)
    |> with_virtual_id()
  end

  def get(id) when is_binary(id) do
    case String.split(id, ":") do
      [member_id_str, feature_id_str] ->
        get(%{"member_id" => member_id_str, "feature_id" => feature_id_str})

      _ ->
        raise "Invalid ID format. Expected 'member_id:feature_id'"
    end
  end

  defp with_virtual_id(struct) do
    %{struct | id: "#{struct.member_id}:#{struct.feature_id}"}
  end
end
