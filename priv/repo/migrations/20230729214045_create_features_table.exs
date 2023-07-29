defmodule Membership.Repo.Migrations.CreateFeaturesTable do
  use Ecto.Migration

  def change do
    create table(:membership_features) do
      add(:identifier, :string)
      add(:name, :string, size: 255)

      timestamps()
    end

    create(unique_index(:membership_features, [:identifier]))
  end
end
