defmodule Membership.Repo.Migrations.CreatePlansTable do
  use Ecto.Migration

  def change do
    key_type = Membership.Config.key_type(:migration)

    create table(:membership_plans, primary_key: false) do
      add(:id, key_type, primary_key: true)
      add(:identifier, :string)
      add(:name, :string, size: 255)
      add(:features, {:array, :string}, default: [])
    end

    create(unique_index(:membership_plans, [:identifier]))
  end
end
