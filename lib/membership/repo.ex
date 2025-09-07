defmodule Membership.Repo do
  @moduledoc """
  Ecto repository
  """
  defp env(key, default \\ nil) do
    Application.get_env(:ex_membership, key, default)
  end

  def repo() do
    case env(:ecto_repo) do
      nil -> raise "Must define :ecto_repo for Membership to work properly."
      r -> r
    end
  end
end
