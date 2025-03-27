defmodule Membership.Repo.Migrations.SetupTables do
  use Ecto.Migration

  def change do
    key_type =
      case Application.get_env(:ex_membership, :primary_key_type) do
        nil -> :serial
        _ -> :uuid
      end

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
      add(:member_id, references(:membership_members, type: key_type))
      add(:plan_id, references(:membership_plans, type: key_type))
    end

    create table(:membership_member_features, primary_key: false) do
      add(:member_id, references(:membership_members, type: key_type))
      add(:feature_id, references(:membership_features, type: key_type))
      add(:permission, :string)
    end

    create table(:membership_plan_features, primary_key: false) do
      add(:plan_id, references(:membership_plans, type: key_type))
      add(:feature_id, references(:membership_features, type: key_type))
    end

    create table(:membership_roles, primary_key: false) do
      add(:id, key_type, primary_key: {:id, key_type, autogenerate: true})
      add(:identifier, :string)
      add(:name, :string, size: 255)
    end

    create(unique_index(:membership_roles, [:identifier]))

    create table(:membership_member_roles, primary_key: false) do
      add(:member_id, references(:membership_members, type: key_type))
      add(:role_id, references(:membership_roles, type: key_type))
    end

    create table(:membership_role_features, primary_key: false) do
      add(:role_id, references(:membership_roles, type: key_type))
      add(:feature_id, references(:membership_features, type: key_type))
    end
  end
end
