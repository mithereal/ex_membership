defmodule Membership.Factory do
  use ExMachina.Ecto, repo: Membership.Repo
  alias Membership.Member
  alias Membership.Feature
  alias Membership.Plan
  alias Membership.Role

  def member_factory do
    %Member{
      id: id_sequence()
    }
  end

  def plan_factory do
    plan = Faker.Color.En.name()

    %Plan{
      id: id_sequence(),
      identifier: sequence(:plan, [plan]),
      name: sequence(:plan_name, &"Generated plan-#{&1}")
    }
  end

  def role_factory do
    plan = Faker.Color.En.name()

    %Role{
      id: id_sequence(),
      identifier: sequence(:plan, [plan]),
      name: sequence(:plan_name, &"Generated role-#{&1}")
    }
  end

  def feature_factory do
    feature = Faker.Company.bullshit_suffix()

    %Feature{
      id: id_sequence(),
      identifier: sequence(:feature, [feature]),
      name: sequence(:feature_name, &"Generated feature-#{&1}")
    }
  end

  def id_sequence() do
    case Membership.Config.key_type() do
      :binary_id -> Ecto.UUID.generate()
      :uuid -> Ecto.UUID.generate()
      _ -> sequence(:id, &"#{&1}")
    end
  end
end
