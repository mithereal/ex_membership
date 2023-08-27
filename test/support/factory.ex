defmodule Membership.Factory do
  use ExMachina.Ecto, repo: Membership.Repo
  alias Membership.Member
  alias Membership.Feature
  alias Membership.Plan

  def member_factory do
    %Member{}
  end

  def plan_factory do
    plan = Faker.Color.En.name()

    %Plan{
      identifier: sequence(:plan, [plan]),
      name: sequence(:plan_name, &"Generated plan-#{&1}")
    }
  end

  def feature_factory do
    feature = Faker.Company.bullshit_suffix()

    %Feature{
      identifier: sequence(:feature, [feature]),
      name: sequence(:feature_name, &"Generated feature-#{&1}")
    }
  end
end
