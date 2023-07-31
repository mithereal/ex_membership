defmodule Membership.MemberFeatures do
  @moduledoc """
  MemberFeatures is the association linking the member to the feature you can also set specific features for the membership
  """

  use Ecto.Schema
  import Ecto.Changeset
  alias __MODULE__

  schema "membership_member_features" do
    belongs_to(:member, Membership.Member)
    field(:assoc_id, :integer)
    field(:features, {:array, :string}, default: [])

    timestamps()
  end

  def changeset(%Membership.MemberFeatures{} = struct, params \\ %{}) do
    struct
    |> cast(params, [:member_id, :assoc_id, :features])
    |> validate_required([:member_id, :assoc_id, :features])
  end

  def create(
        %Membership.Member{id: id},
        %{__struct__: _feature_name, id: assoc_id},
        features \\ []
      ) do
    changeset(%Membership.MemberFeatures{
      member_id: id,
      assoc_id: assoc_id,
      features: features
    })
    |> Membership.Repo.insert!()
  end
end
