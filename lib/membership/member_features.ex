defmodule Membership.MemberFeatures do
  @moduledoc false

  use Membership.Schema, type: :binary_fk

  alias Membership.Member
  alias Membership.Feature
  alias Membership.MemberFeatures

  schema "membership_member_features" do
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
    changeset(%MemberFeatures{
      member_id: id,
      feature_id: feature_id,
      permission: permission
    })
    |> Repo.insert!()
  end

  def table, do: :membership_features
end
