defmodule PostTest do
  use Membership, registry: :test

  def delete(member) do
    {_, member} = load_and_authorize_member(member)

    permissions do
      has_plan(:admin, :delete)
    end

    as_authorized(member, :delete) do
      {:ok, "Authorized"}
    end
  end

  def update(member) do
    {_, member} = load_and_authorize_member(member)

    permissions do
      has_feature(:update_post, :update)
    end

    as_authorized(member, :update) do
      {:ok, "Authorized"}
    end
  end

  def entity_update(member) do
    {_, member} = load_and_authorize_member(member)

    permissions do
      has_feature(:delete_member, :entity_update)
    end

    as_authorized(member, :entity_update) do
      {:ok, "Authorized"}
    end
  end

  def no_macro(member) do
    load_and_authorize_member(member)

    permissions do
      has_feature(:update_post, :no_macro)
    end

    case authorized?() do
      :ok -> {:ok, "Authorized"}
      _ -> raise ArgumentError, message: "Not authorized"
    end
  end

  def no_permissions(member) do
    load_and_authorize_member(member)

    permissions do
    end

    case authorized?() do
      :ok -> {:ok, "Authorized"}
      _ -> raise ArgumentError, message: "Not authorized"
    end
  end

  def is_calculated(member, email_confirmed) do
    {:ok, member} = load_and_authorize_member(member)

    permissions do
      calculated(
        member,
        fn _member ->
          email_confirmed
        end,
        :calculated
      )
    end

    case authorized?() do
      :ok -> {:ok, "Authorized"}
      _ -> raise ArgumentError, message: "Not authorized"
    end
  end

  def calculated_macro(member) do
    {:ok, member} = load_and_authorize_member(member)

    permissions do
      calculated(member, :confirmed_email, :calculated_macro)
    end

    case authorized?() do
      :ok -> {:ok, "Authorized"}
      _ -> raise ArgumentError, message: "Not authorized"
    end
  end

  def confirmed_email(_member) do
    false
  end
end
