defmodule Membership.Repo.Migrations.CreateAbilitiesTable do
  use Ecto.Migration

  def change do
    create table(:membership_plans) do
      add(:identifier, :string)
      add(:name, :string, size: 255)

      timestamps()
    end

    create(unique_index(:membership_plans, [:identifier]))
  end
end
