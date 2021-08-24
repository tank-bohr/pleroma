defmodule Pleroma.LoadTesting.Users do
  @moduledoc """
  Module for generating users with friends.
  """
  import Ecto.Query

  alias Pleroma.Repo
  alias Pleroma.User
  alias Pleroma.User.Query

  @defaults [
    users: 200,
    friends: 100
  ]

  @max_concurrency 5

  @spec generate(keyword()) :: User.t()
  def generate(opts \\ []) do
    opts = Keyword.merge(@defaults, opts)

    generate_users(opts[:users])
    make_friends(opts[:friends])
  end

  def generate_users(max) do
    IO.puts("Starting generating #{max} users...")

    {time, users} =
      :timer.tc(fn ->
        Task.async_stream(
          1..max,
          &generate_user(&1),
          max_concurrency: @max_concurrency,
          timeout: :timer.minutes(5)
        )
        |> Enum.to_list()
      end)

    IO.puts("Generating users took #{time} millis.\n")
    users
  end

  defp generate_user(i) do
    %User{
      name: "Test テスト User #{i}",
      email: "user.#{i}.@example.com",
      nickname: "nick-#{i}",
      password_hash: "$pbkdf2-sha512$160000$/p/nc2IgpHAe9jX/J0W4xQ$.j35tmUYFLOJbTmUaU2gMoSE1UX9coj.wpNTD9I4JHpUHfl5tAqJectI4COIA1gNA80BqXClCl8nHIZ.WMN9Ig",
      bio: "Tester Number #{i}",
      local: true
    }
    |> user_urls()
    |> Repo.insert!()
  end

  defp user_urls(%{local: true} = user) do
    urls = %{
      ap_id: User.ap_id(user),
      follower_address: User.ap_followers(user),
      following_address: User.ap_following(user)
    }

    Map.merge(user, urls)
  end

  def make_friends(count) do
    query = from(u in User, where: u.local == true, order_by: fragment("RANDOM()"), limit: ^count)

    query
    |> Repo.all()
    |> Enum.each(fn user -> make_friends(user, count) end)
  end

  def make_friends(main_user, max) when is_integer(max) do
    IO.puts("Starting making friends for #{max} users...")

    {time, _} =
      :timer.tc(fn ->
        number_of_users =
          (max / 2)
          |> Kernel.trunc()

        main_user
        |> get_users(%{limit: number_of_users, local: :local})
        |> run_stream(main_user)
      end)

    IO.puts("Making friends took #{time} millis.\n")
  end

  def make_friends(%User{} = main_user, %User{} = user) do
    {:ok, _, _} = User.follow(main_user, user)
  end

  @spec get_users(User.t(), keyword()) :: [User.t()]
  def get_users(user, opts) do
    criteria = %{limit: opts[:limit]}

    criteria =
      if opts[:local] do
        Map.put(criteria, opts[:local], true)
      else
        criteria
      end

    criteria =
      if opts[:friends?] do
        Map.put(criteria, :friends, user)
      else
        criteria
      end

    query =
      criteria
      |> Query.build()
      |> random_without_user(user)

    query =
      if opts[:friends?] == false do
        friends_ids =
          %{friends: user}
          |> Query.build()
          |> Repo.all()
          |> Enum.map(& &1.id)

        from(u in query, where: u.id not in ^friends_ids)
      else
        query
      end

    Repo.all(query)
  end

  defp random_without_user(query, user) do
    from(u in query,
      where: u.id != ^user.id,
      order_by: fragment("RANDOM()")
    )
  end

  defp run_stream(users, main_user) do
    Task.async_stream(users, &make_friends(main_user, &1),
      max_concurrency: @max_concurrency,
      timeout: :timer.minutes(5)
    )
    |> Stream.run()
  end

  @spec prepare_users(User.t(), keyword()) :: map()
  def prepare_users(user, opts) do
    friends_limit = opts[:friends_used]
    non_friends_limit = opts[:non_friends_used]

    %{
      user: user,
      friends_local: fetch_users(user, friends_limit, :local, true),
      friends_remote: fetch_users(user, friends_limit, :external, true),
      non_friends_local: fetch_users(user, non_friends_limit, :local, false),
      non_friends_remote: fetch_users(user, non_friends_limit, :external, false)
    }
  end

  defp fetch_users(user, limit, local, friends?) do
    user
    |> get_users(limit: limit, local: local, friends?: friends?)
    |> Enum.shuffle()
  end
end

Pleroma.LoadTesting.Users.generate()
