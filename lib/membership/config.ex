defmodule Membership.Config do
  @doc """
  Return value by key from config.exs file.
  """

  defstruct get_dynamic_repo: nil,
            prefix: nil,
            log: false,
            name: Membership,
            repo: nil

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

  def new(opts \\ []) do
    repo = Membership.Config.get(:repo)
    struct!(__MODULE__, [repo: repo] ++ opts)
  end
end
