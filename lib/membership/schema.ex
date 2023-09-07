defmodule Membership.Schema do
  @moduledoc false
  defmacro __using__(options) do
    type =
      case Enum.member?(options, :type) do
        false -> Membership.Config.key_type()
        true -> options[:type]
      end

    case type do
      :binary_id ->
        quote do
          use Ecto.Schema
          @primary_key {:id, :binary_id, autogenerate: true}
          @foreign_key_type :binary_id

          import Ecto.Changeset

          alias Membership.Repo
        end

      :binary_fk ->
        quote do
          use Ecto.Schema
          @primary_key false
          @foreign_key_type :binary_id

          import Ecto.Changeset

          alias Membership.Repo
        end

      _ ->
        quote do
          use Ecto.Schema
          @primary_key {:id, :id, autogenerate: true}

          import Ecto.Changeset

          alias Membership.Repo
        end
    end
  end
end
