defmodule Membership.Factory do
  use ExMachina.Ecto, repo: Membership.Repo
  alias Membership.Member
  alias Membership.Feature
  alias Membership.Plan

  def member_factory do
    %Member{}
  end

  def plan_factory do
    %Plan{
      identifier: sequence(:plan, ["Free", "Bronze", "Silver", "Gold"])
    }
  end

  def feature_factory do
    %Feature{
      identifier: sequence(:feature, ["feature_id"]),
      name: sequence(:feature_name, &"Generated feature-#{&1}")
    }
  end
end
