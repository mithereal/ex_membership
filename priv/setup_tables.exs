defmodule Membership.Repo.Migrations.SetupTables do
  use Ecto.Migration

  alias Membership.Config

  def change do
    key_type = Config.key_type(:migration)

    create table(:membership_plans, primary_key: false) do
      add(:id, key_type, primary_key: {:id, key_type, autogenerate: true})
      add(:identifier, :string)
      add(:name, :string, size: 255)
    end

    create(unique_index(:membership_plans, [:identifier]))

    create table(:membership_features, primary_key: false) do
      add(:id, key_type, primary_key: {:id, key_type, autogenerate: true})
      add(:identifier, :string)
      add(:name, :string, size: 255)
    end

    create(unique_index(:membership_features, [:identifier]))

    create table(:membership_members, primary_key: false) do
      add(:id, key_type, primary_key: {:id, key_type, autogenerate: true})
      add(:identifier, :string)
      add(:features, {:array, :string}, default: [])

      timestamps()
    end

    create table(:membership_member_plans, primary_key: false) do
      add(:member_id, references(Membership.Member.table(), type: key_type))
      add(:plan_id, references(Membership.Plan.table(), type: key_type))
    end

    create table(:membership_member_features, primary_key: false) do
      add(:member_id, references(Membership.Member.table(), type: key_type))
      add(:feature_id, references(Membership.Feature.table(), type: key_type))
      add(:permission, :string)
    end

    create table(:membership_plan_features, primary_key: false) do
      add(:plan_id, references(Membership.Plan.table(), type: key_type))
      add(:feature_id, references(Membership.Feature.table(), type: key_type))
    end

    create table(:membership_roles, primary_key: false) do
      add(:id, key_type, primary_key: {:id, key_type, autogenerate: true})
      add(:identifier, :string)
      add(:name, :string, size: 255)
    end

    create(unique_index(:membership_roles, [:identifier]))

    create table(:membership_member_roles, primary_key: false) do
      add(:member_id, references(Membership.Member.table(), type: key_type))
      add(:role_id, references(Membership.Role.table(), type: key_type))
    end

    create table(:membership_role_features, primary_key: false) do
      add(:role_id, references(Membership.Role.table(), type: key_type))
      add(:feature_id, references(Membership.Feature.table(), type: key_type))
    end
  end
end
