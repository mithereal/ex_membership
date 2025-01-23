defmodule Membership.Config do
  @doc """
  Return value by key from config.exs file.
  """

  def get(name, default \\ nil) do
    Application.get_env(:ex_membership, name, default)
  end

  def key_type() do
    case Application.get_env(:ex_membership, :primary_key_type) do
      nil -> :integer
      _ -> :binary_id
    end
  end

  def key_type(:migration) do
    case Application.get_env(:ex_membership, :primary_key_type) do
      nil -> :serial
      _ -> :uuid
    end
  end
end
