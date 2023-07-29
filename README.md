# 🛡 Membership 🛡 

[![Coverage Status](https://img.shields.io/coveralls/github/mithereal/ex_membership.svg?style=flat-square)](https://coveralls.io/github/mithereal/ex_membership)
[![Build Status](https://img.shields.io/travis/mithereal/ex_membership.svg?style=flat-square)](https://travis-ci.org/mithereal/ex_membership)
[![Version](https://img.shields.io/hexpm/v/ex_membership.svg?style=flat-square)](https://hex.pm/packages/ex_membership)

Membership is toolkit for granular ability management for members. It allows you to define granular abilities such as:
this is basically terminator but with methods and dsl for membership plans
- `Member -> Plan`
- `Member -> [Plan, Plan, ...]`

Here is a small example:

```elixir
defmodule Sample.Post
  use Membership

  def delete_post(id) do
    member = Sample.Repo.get(Membership.Member, 1)
    load_and_authorize_member(member)
    post = %Post{id: 1}

    permissions do
      has_role(:admin) # or
      has_role(:editor) # or
      has_ability(:delete_posts) # or
      has_ability(:delete, post) # Entity related abilities
      calculated(fn member ->
        member.email_confirmed?
      end)
    end

    as_authorized do
      Sample.Repo.get(Sample.Post, id) |> Sample.repo.delete()
    end

    # Notice that you can use both macros or functions

    case is_authorized? do
      :ok -> Sample.Repo.get(Sample.Post, id) |> Sample.repo.delete()
      {:error, message} -> "Raise error"
      _ -> "Raise error"
    end
  end

```

## Features

- [x] `Member` -> `[Ability]` permission schema
- [x] `Role` -> `[Ability]` permission schema
- [x] `Member` -> `[Role]` -> `[Ability]` permission schema
- [x] `Member` -> `Object` -> `[Ability]` permission schema
- [x] Computed permission in runtime
- [x] Easily readable DSL
- [ ] [ueberauth](https://github.com/ueberauth/ueberauth) integration
- [ ] [absinthe](https://github.com/absinthe-graphql/absinthe) middleware
- [ ] Session plug to get current_user

## Installation

```elixir
def deps do
  [
    {:membership, "~> 0.5.2"}
  ]
end
```

```elixir
# In your config/config.exs file
config :membership, Membership.Repo,
  username: "postgres",
  password: "postgres",
  database: "membership_dev",
  hostname: "localhost"
```

```elixir
iex> mix membership.setup
```

### Usage with ecto

Membership is originally designed to be used with Ecto. Usually you will want to have your own table for `Accounts`/`Users` living in your application. To do so you can link member with `belongs_to` association within your schema.

```elixir
# In your migrations add member_id field
defmodule Sample.Migrations.CreateUsersTable do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :username, :string
      add :member_id, references(Membership.Member.table())

      timestamps()
    end

    create unique_index(:users, [:username])
  end
end

```

This will allow you link any internal entity with 1-1 association to members. Please note that you need to create member on each user creation (e.g with `Membership.Member.changeset/2`) and call `put_assoc` inside your changeset

```elixir
# In schema defintion
defmodule Sample.User do
  use Ecto.Schema

  schema "users" do
    field :username, :String

    belongs_to :member, Membership.Member

    timestamps()
  end
end
```

```elixir
# In your model
defmodule Sample.Post
  use Membership

  def delete_post(id) do
    user = Sample.Repo.get(Sample.User, 1)
    load_and_authorize_member(user)
    # Function allows multiple signatues of member it can
    # be either:
    #  * %Membership.Member{}
    #  * %AnyStruct{member: %Membership.Member{}}
    #  * %AnyStruct{member_id: id} (this will perform database preload)


    permissions do
      has_role(:admin) # or
      has_role(:editor) # or
      has_ability(:delete_posts) # or
    end

    as_authorized do
      Sample.Repo.get(Sample.Post, id) |> Sample.repo.delete()
    end

    # Notice that you can use both macros or functions

    case is_authorized? do
      :ok -> Sample.Repo.get(Sample.Post, id) |> Sample.repo.delete()
      {:error, message} -> "Raise error"
      _ -> "Raise error"
    end
  end

```

Membership tries to infer the member, so it is easy to pass any struct (could be for example `User` in your application) which has set up `belongs_to` association for member. If the member was already preloaded from database Membership will take it as loaded member. If you didn't do preload and just loaded `User` -> `Repo.get(User, 1)` Membership will fetch the member on each authorization try.

### Calculated permissions

Often you will come to case when `static` permissions are not enough. For example allow only users who confirmed their email address.

```elixir
defmodule Sample.Post do
  def create() do
    user = Sample.Repo.get(Sample.User, 1)
    load_and_authorize_member(user)

    permissions do
      calculated(fn member -> do
        member.email_confirmed?
      end)
    end
  end
end
```

We can also use DSL form of `calculated` keyword

```elixir
defmodule Sample.Post do
  def create() do
    user = Sample.Repo.get(Sample.User, 1)
    load_and_authorize_member(user)

    permissions do
      calculated(:confirmed_email)
    end
  end

  def confirmed_email(member) do
    member.email_confirmed?
  end
end
```

### Composing calculations

When we need to member calculation based on external data we can invoke bindings to `calculated/2`

```elixir
defmodule Sample.Post do
  def create() do
    user = Sample.Repo.get(Sample.User, 1)
    post = %Post{owner_id: 1}
    load_and_authorize_member(user)

    permissions do
      calculated(:confirmed_email)
      calculated(:is_owner, [post])
    end
  end

  def confirmed_email(member) do
    member.email_confirmed?
  end

  def is_owner(member, [post]) do
    member.id == post.owner_id
  end
end
```

To perform exclusive abilities such as `when User is owner of post AND is in editor role` we can do so as in following example

```elixir
defmodule Sample.Post do
  def create() do
    user = Sample.Repo.get(Sample.User, 1)
    post = %Post{owner_id: 1}
    load_and_authorize_member(user)

    permissions do
      has_role(:editor)
    end

    as_authorized do
      case is_owner(member, post) do
        :ok -> ...
        {:error, message} -> ...
      end
    end
  end

  def is_owner(member, post) do
    load_and_authorize_member(member)

    permissions do
      calculated(fn p, [post] ->
        p.id == post.owner_id
      end)
    end

    is_authorized?
  end
end
```

We can simplify example in this case by excluding DSL for permissions

```elixir
defmodule Sample.Post do
  def create() do
    user = Sample.Repo.get(Sample.User, 1)
    post = %Post{owner_id: 1}

    # We can also use has_ability?/2
    if has_role?(user, :admin) and is_owner(user, post) do
      ...
    end
  end

  def is_owner(member, post) do
    member.id == post.owner_id
  end
end
```

### Entity related abilities

Membership allows you to grant abilities on any particular struct. Struct needs to have signature of `%{__struct__: entity_name, id: entity_id}` to infer correct relations. Lets assume that we want to grant `:delete` ability on particular `Post` for our member:

```elixir
iex> {:ok, member} = %Membership.Member{} |> Membership.Repo.insert()
iex> post = %Post{id: 1}
iex> ability = %Ability{identifier: "delete"}
iex> Membership.Member.grant(member, :delete, post)
iex> Membership.has_ability?(member, :delete, post)
true
```

```elixir
defmodule Sample.Post do
  def delete() do
    user = Sample.Repo.get(Sample.User, 1)
    post = %Post{id: 1}
    load_and_authorize_member(user)

    permissions do
      has_ability(:delete, post)
    end

    as_authorized do
      :ok
    end
  end
end
```

### Granting abilities

Let's assume we want to create new `Role` - _admin_ which is able to delete accounts inside our system. We want to have special `Member` who is given this _role_ but also he is able to have `Ability` for banning users.

1. Create member

```elixir
iex> {:ok, member} = %Membership.Member{} |> Membership.Repo.insert()
```

2. Create some abilities

```elixir
iex> {:ok, ability_delete} = Membership.Ability.build("delete_accounts", "Delete accounts of users") |> Membership.Repo.insert()
iex> {:ok, ability_ban} = Membership.Ability.build("ban_accounts", "Ban users") |> Membership.Repo.insert()
```

3. Create role

```elixir
iex> {:ok, role} = Membership.Role.build("admin", [], "Site administrator") |> Membership.Repo.insert()
```

4. Grant abilities to a role

```elixir
iex> Membership.Role.grant(role, ability_delete)
```

5. Grant role to a member

```elixir
iex> Membership.Member.grant(member, role)
```

6. Grant abilities to a member

```elixir
iex> Membership.Member.grant(member, ability_ban)
```

```elixir
iex> member |> Membership.Repo.preload([:roles, :abilities])
%Membership.Member{
  abilities: [
    %Membership.Ability{
      identifier: "ban_accounts"
    }
  ]
  roles: [
    %Membership.Role{
      identifier: "admin"
      abilities: ["delete_accounts"]
    }
  ]
}
```

### Revoking abilities

Same as we can grant any abilities to models we can also revoke them.

```elixir
iex> Membership.Member.revoke(member, role)
iex> member |> Membership.Repo.preload([:roles, :abilities])
%Membership.Member{
  abilities: [
    %Membership.Ability{
      identifier: "ban_accounts"
    }
  ]
  roles: []
}
iex> Membership.Member.revoke(member, ability_ban)
iex> member |> Membership.Repo.preload([:roles, :abilities])
%Membership.Member{
  abilities: []
  roles: []
}
```

## License

[MIT © Milos Mosovsky](mailto:milos@mosovsky.com)
