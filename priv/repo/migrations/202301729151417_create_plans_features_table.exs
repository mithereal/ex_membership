defmodule Membership.Repo.Migrations.CreatePlanFeaturesTable do
  use Ecto.Migration

  def change do
    create table(:membership_plan_features) do
      add(:plan_id, references(Membership.Plan.table()))
      add(:assoc_id, :integer)
    end
  end
end
