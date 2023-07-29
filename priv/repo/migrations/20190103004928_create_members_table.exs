defmodule Membership.Repo.Migrations.CreateMembersTable do
  use Ecto.Migration

  def change do
    create table(:membership_members) do
      add(:plans, {:array, :string}, default: [])

      timestamps()
    end
  end
end
