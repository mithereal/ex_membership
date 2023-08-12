defmodule Membership.Schema do
  @moduledoc false
  defmacro __using__(_options) do
    type = Membership.Config.key_type()

    case type do
      :binary_id ->
        quote do
          use Ecto.Schema
          @primary_key {:id, :binary_id, autogenerate: true}
          @foreign_key_type :binary_id
          alias __MODULE__
        end

      _ ->
        quote do
          use Ecto.Schema
          alias __MODULE__
        end
    end
  end
end
