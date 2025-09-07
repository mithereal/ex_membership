defmodule Membership.Repo.Migrations.CreateRolesTable do
  use Ecto.Migration

  def change do
    key_type = Membership.key_type(:migration)

    create table(:membership_roles, primary_key: false) do
      add(:id, key_type, primary_key: {:id, key_type, autogenerate: true})
      add(:identifier, :string)
      add(:name, :string, size: 255)
    end

    create(unique_index(:membership_roles, [:identifier]))
  end
end
