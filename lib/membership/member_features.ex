defmodule Membership.MemberFeatures do
  @moduledoc """
  MemberFeatures is the association linking the member to the feature you can also set specific features for the membership
  """

  use Membership.Schema
  import Ecto.Changeset
  alias __MODULE__

  schema "membership_member_features" do
    belongs_to(:member, Membership.Member)
    belongs_to(:feature, Membership.Feature)
  end

  def changeset(%Membership.MemberFeatures{} = struct, params \\ %{}) do
    struct
    |> cast(params, [:member_id, :feature_id])
    |> validate_required([:member_id, :feature_id])
  end

  def create(
        %Membership.Member{id: id},
        %{__struct__: _feature_name, id: feature_id},
        features \\ []
      ) do
    changeset(%Membership.MemberFeatures{
      member_id: id,
      feature_id: feature_id
    })
    |> Membership.Repo.insert!()
  end
end
