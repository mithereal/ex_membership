defmodule Post do
  use Membership, registry: :test

  def no_macro(member, function_name \\ "no_macro") do
    member = load_and_authorize_member(member)

    permissions do
      has_feature("update_post", function_name)
    end

    case authorized?(member, function_name) do
      :ok -> {:ok, "Authorized"}
      _ -> raise ArgumentError, message: "Not authorized"
    end
  end

  def no_permissions(member, function_name \\ "no_permissions") do
    member = load_and_authorize_member(member)

    permissions do
    end

    case authorized?(member, function_name) do
      :ok -> {:ok, "Authorized"}
      _ -> raise ArgumentError, message: "Not authorized"
    end
  end

  def calculated_post(member, email_confirmed) do
    member = load_and_authorize_member(member)

    permissions do
      calculated(
        member,
        fn _member ->
          email_confirmed
        end
      )
    end

    case authorized?(member, "calculated") do
      :ok -> {:ok, "Authorized"}
      _ -> raise ArgumentError, message: "Not authorized"
    end
  end

  def calculated_macro(member, function_name \\ "no_permissions") do
    member = load_and_authorize_member(member)

    permissions do
      calculated(member, :confirmed_email)
    end

    case authorized?(member, function_name) do
      :ok -> {:ok, "Authorized"}
      _ -> raise ArgumentError, message: "Not authorized"
    end
  end

  def confirmed_email(_member) do
    false
  end

  def update(_id \\ 1, member_id \\ nil, function_name \\ "update_post") do
    member = load_and_authorize_member(%{member_id: member_id})

    permissions do
      # or check 1st arg for being an atom vs string
      has_plan("gold", function_name)
      # or
      has_plan("bronze", function_name)
      # or
      has_feature("update_post", function_name)
    end

    case authorized?(member, function_name) do
      :ok -> {:ok, "Post was Updated"}
      {:error, message} -> {:error, message}
      _ -> "Raise error"
    end
  end

  def delete_post(id \\ 1, member_id \\ 1, function_name \\ "delete_post") do
    member =
      load_and_authorize_member(%Membership.Member{id: member_id})

    permissions do
      # or check 1st arg for being an atom vs string
      has_plan("gold", function_name)
      # or
      has_plan("bronze", function_name)
      # or
      has_feature("delete_posts", function_name)

      #      calculated(fn member ->
      #        member.email_confirmed?
      #      end)
    end

    #    as_authorized(function_name) do
    #      :ok
    #    end

    # Notice that you can use both macros or functions

    case authorized?(member, function_name) do
      :ok -> {:ok, "Post #{id} was Deleted"}
      {:error, message} -> {:error, message}
      _ -> "Raise error"
    end
  end
end
