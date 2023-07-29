defmodule Membership.Factory do
  use ExMachina.Ecto, repo: Membership.Repo
  alias Membership.Member
  alias Membership.Ability
  alias Membership.Role

  def member_factory do
    %Member{}
  end

  def ability_factory do
    %Ability{
      identifier: sequence(:role, ["view_post", "delete_post", "create_post"])
    }
  end

  def role_factory do
    %Role{
      identifier: sequence(:role, ["admin", "editor", "user"]),
      name: sequence(:role_name, &"Generated role-#{&1}")
    }
  end
end
