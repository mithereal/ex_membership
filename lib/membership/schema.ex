defmodule Membership.Schema do
  @moduledoc false
  defmacro __using__(options) do
    type = options[:type] || Membership.Config.key_type()

    case type do
      :binary_id ->
        quote do
          use Ecto.Schema
          @primary_key {:id, :binary_id, autogenerate: true}
          @foreign_key_type :binary_id

          import Ecto.Changeset

          alias Membership.Repo
        end

      :uuid ->
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
