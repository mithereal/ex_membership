# 🛡 Membership 🛡 

[![Coverage Status](https://img.shields.io/coveralls/github/mithereal/ex_membership.svg?style=flat-square)](https://coveralls.io/github/mithereal/ex_membership)
[![Build Status](https://img.shields.io/travis/mithereal/ex_membership.svg?style=flat-square)](https://travis-ci.org/mithereal/ex_membership)
[![Version](https://img.shields.io/hexpm/v/ex_membership.svg?style=flat-square)](https://hex.pm/packages/ex_membership)

Membership is toolkit for granular feature management for members. It allows you to define granular features such as:
this is basically terminator but with methods and dsl for membership plans and features
also we can now coexist with terminator and have our own custom dsl/ets etc.
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

    as_member do
      has_plan(:admin) # or
      has_plan(:editor) # or
      has_feature(:delete_posts) # or
      has_feature(:delete, post) # Entity related features
      calculated_member(fn member ->
        member.email_confirmed?
      end)
    end

    as_member do
      Sample.Repo.get(Sample.Post, id) |> Sample.repo.delete()
    end

    # Notice that you can use both macros or functions

    case member_authorized? do
      :ok -> Sample.Repo.get(Sample.Post, id) |> Sample.repo.delete()
      {:error, message} -> "Raise error"
      _ -> "Raise error"
    end
  end

```

## Features

- [x] `Member` -> `[Feature]` permission schema
- [x] `Plan` -> `[Feature]` permission schema
- [x] `Member` -> `[Plan]` -> `[Feature]` permission schema
- [x] `Member` -> `Object` -> `[Feature]` permission schema
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


    as_member do
      has_plan(:admin) # or
      has_plan(:editor) # or
      has_feature(:delete_posts) # or
    end

    member_authorized do
      Sample.Repo.get(Sample.Post, id) |> Sample.repo.delete()
    end

    # Notice that you can use both macros or functions

    case member_authorized? do
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

    as_member do
      calculated_member(fn member -> do
        member.email_confirmed?
      end)
    end
  end
end
```

We can also use DSL form of `calculated_member` keyword

```elixir
defmodule Sample.Post do
  def create() do
    user = Sample.Repo.get(Sample.User, 1)
    load_and_authorize_member(user)

    as_member do
      calculated_member(:confirmed_email)
    end
  end

  def confirmed_email(member) do
    member.email_confirmed?
  end
end
```

### Composing calculations

When we need to member calculation based on external data we can invoke bindings to `calculated_member/2`

```elixir
defmodule Sample.Post do
  def create() do
    user = Sample.Repo.get(Sample.User, 1)
    post = %Post{owner_id: 1}
    load_and_authorize_member(user)

    as_member do
      calculated_member(:confirmed_email)
      calculated_member(:is_owner, [post])
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

To perform exclusive features such as `when User is owner of post AND is in editor plan` we can do so as in following example

```elixir
defmodule Sample.Post do
  def create() do
    user = Sample.Repo.get(Sample.User, 1)
    post = %Post{owner_id: 1}
    load_and_authorize_member(user)

    as_member do
      has_plan(:editor)
    end

    member_authorized do
      case is_owner(member, post) do
        :ok -> ...
        {:error, message} -> ...
      end
    end
  end

  def is_owner(member, post) do
    load_and_authorize_member(member)

    as_member do
      calculated_member(fn p, [post] ->
        p.id == post.owner_id
      end)
    end

    member_authorized?
  end
end
```

We can simplify example in this case by excluding DSL for permissions

```elixir
defmodule Sample.Post do
  def create() do
    user = Sample.Repo.get(Sample.User, 1)
    post = %Post{owner_id: 1}

    # We can also use has_feature?/2
    if has_plan?(user, :admin) and is_owner(user, post) do
      ...
    end
  end

  def is_owner(member, post) do
    member.id == post.owner_id
  end
end
```

### Member related features

Membership allows you to grant features on any particular struct. Struct needs to have signature of `%{__struct__: entity_name, id: entity_id}` to infer correct relations. Lets assume that we want to grant `:delete` feature on particular `Post` for our member:

```elixir
iex> {:ok, member} = %Membership.Member{} |> Membership.Repo.insert()
iex> post = %Post{id: 1}
iex> feature = %Feature{identifier: "delete"}
iex> Membership.Member.grant(member, :delete, post)
iex> Membership.has_feature?(member, :delete, post)
true
```

```elixir
defmodule Sample.Post do
  def delete() do
    user = Sample.Repo.get(Sample.User, 1)
    post = %Post{id: 1}
    load_and_authorize_member(user)

    as_member do
      has_feature(:delete, post)
    end

    member_authorized do
      :ok
    end
  end
end
```

### Granting features

Let's assume we want to create new `Plan` - _gold_ which is able to delete accounts inside our system. We want to have special `Member` who is given this _plan_ but also he is able to have `Feature` for banning users.

1. Create member

```elixir
iex> {:ok, member} = %Membership.Member{} |> Membership.Repo.insert()
```

2. Create some features

```elixir
iex> {:ok, feature_delete} = Membership.Feature.build("delete_accounts", "Delete accounts of users") |> Membership.Repo.insert()
iex> {:ok, feature_ban} = Membership.Feature.build("ban_accounts", "Ban users") |> Membership.Repo.insert()
```

3. Create plan

```elixir
iex> {:ok, plan} = Membership.Plan.build("gold", [], "Gold Package") |> Membership.Repo.insert()
```

4. Grant features to a plan

```elixir
iex> Membership.Plan.grant(plan, feature_delete)
```

5. Grant plan to a member

```elixir
iex> Membership.Member.grant(member, plan)
```

6. Grant features to a member

```elixir
iex> Membership.Member.grant(member, feature_ban)
```

```elixir
iex> member |> Membership.Repo.preload([:plans, :features])
%Membership.Member{
  features: [
    %Membership.Feature{
      identifier: "ban_accounts"
    }
  ]
  plans: [
    %Membership.Plan{
      identifier: "gold"
      features: ["delete_accounts"]
    }
  ]
}
```

### Revoking features

Same as we can grant any features to models we can also revoke them.

```elixir
iex> Membership.Member.revoke(member, plan)
iex> member |> Membership.Repo.preload([:plans, :features])
%Membership.Member{
  features: [
    %Membership.Feature{
      identifier: "ban_accounts"
    }
  ]
  plans: []
}
iex> Membership.Member.revoke(member, feature_ban)
iex> member |> Membership.Repo.preload([:plans, :features])
%Membership.Member{
  features: []
  plans: []
}
```

## License

[MIT © Jason Clark](mailto:mithereal@gmail.com)
