defmodule Membership.MemberAdmin do
  @moduledoc """
  Configuration for members in Kaffy admin.
  """

  import Phoenix.Component

  alias Membership.Member

  def create_changeset(schema, attrs) do
    Member.changeset(schema, attrs)
  end

  def update_changeset(schema, attrs) do
    Member.changeset(schema, attrs)
  end

  def index(_) do
    [
      user: %{
        name: "Member"
      }
    ]
  end

  def form_fields(_) do
    [
      user: nil
    ]
  end

  def insert(conn, changeset) do
    user = conn.params["member"]["user"]

    {status, data} = Framework.Accounts.get_user_by_email(user)

    case status do
      :ok ->
        {_, membership} = Member.create(data)

        Ecto.Changeset.change(data, member_id: membership.id)
        |> Framework.Repo.update()

      # |> Framework.Accounts.User.update_user()

      _ ->
        Ecto.Changeset.add_error(changeset, :member, "Email Not found")
    end
  end

  def delete(conn, _changeset) do
    with %{params: %{"ids" => id}} <- conn,
         {:ok, data} <- Member.get(id),
         :ok <- Membership.delete_member(data) do
      {:ok, data}
    else
      error ->
        {:error, error}
    end
  end
end
