defmodule Membership.Repo.Migrations.CreateMembersTable do
  use Ecto.Migration


  def change do
    key_type = Membership.Config.key_type(:migration)

    create table(:membership_members, primary_key: false) do
      add(:id, key_type, primary_key: true)
      add(:identifier, :string)
      add(:name, :string, size: 255)

      timestamps()
    end
  end
end
