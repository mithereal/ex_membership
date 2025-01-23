defmodule Membership.Repo.Migrations.CreateRoleFeaturesTable do
  use Ecto.Migration

  def change do
    key_type = Membership.key_type(:migration)

    create table(:membership_role_features, primary_key: false) do
      add(:role_id, references(Membership.Role.table(), type: key_type))
      add(:feature_id, references(Membership.Feature.table(), type: key_type))
    end
  end
end
