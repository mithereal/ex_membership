defmodule Membership.Repo.Migrations.CreateMembersTable do
  use Ecto.Migration

  def change do
    key_type = Membership.key_type(:migration)

    create table(:membership_members, primary_key: false) do
      add(:id, key_type, primary_key: {:id, key_type, autogenerate: true})
      add(:identifier, :string)
      add(:features, {:array, :string}, default: [])

      timestamps()
    end
  end
end
