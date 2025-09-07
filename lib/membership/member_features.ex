defmodule Membership.MemberFeatures do
  @moduledoc """
  MemberFeatures is the association linking the member to the feature you can also set specific features for the membership
  """

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
    repo = Membership.Repo.repo()

    changeset(%MemberFeatures{
      member_id: id,
      feature_id: feature_id,
      permission: permission
    })
    |> repo.insert!()
  end

  def table, do: :membership_member_features
end
