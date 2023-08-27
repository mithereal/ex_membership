defmodule Membership.Repo.Migrations.CreatePlanFeaturesTable do
  use Ecto.Migration

  def change do
    key_type = Membership.Config.key_type(:migration)

    create table(:membership_plan_features, primary_key: false) do
      add(:id, key_type, primary_key: true)

      add(:plan_id, references(Membership.Plan.table(), type: key_type))
      add(:feature_id, references(Membership.Feature.table(), type: key_type))
    end
  end
end
