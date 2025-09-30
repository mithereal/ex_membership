defmodule Membership.RoleAdmin do
  @moduledoc """
  Configuration for roles in Kaffy admin.
  """

  import Phoenix.Component

  alias Membership.Role

  def create_changeset(schema, attrs) do
    Role.changeset(schema, attrs)
  end

  def update_changeset(schema, attrs) do
    Role.changeset(schema, attrs)
  end

  def index(_) do
    [
      name: %{
        name: "roles"
      }
    ]
  end

  def form_fields(_) do
    [
      name: nil
    ]
  end

  def insert(conn, _changeset) do
    name = conn.params["role"]["name"]

    Role.create(name, name)
  end

  def delete(conn, _changeset) do
    with %{params: %{"ids" => id}} <- conn,
         {:ok, data} <- Role.get(id),
         :ok <- Membership.delete_role(data) do
      {:ok, data}
    else
      error ->
        {:error, error}
    end
  end
end
