defmodule Consumer.Debezium do
  @behaviour :brod_group_subscriber_v2

  alias Bolt.Sips

  require Logger
  require Record

  Record.defrecord(
    :kafka_message_set,
    Record.extract(:kafka_message_set, from_lib: "brod/include/brod.hrl")
  )

  Record.defrecord(
    :kafka_message,
    Record.extract(:kafka_message, from_lib: "kafka_protocol/include/kpro_public.hrl")
  )

  def child_spec(config) do
    %{
      id: __MODULE__,
      start: {:brod, :start_link_group_subscriber_v2, [Map.put(config, :cb_module, __MODULE__)]}
    }
  end


  @impl true
  def init(_arg, _arg2) do
    {:ok, []}
  end

  @impl true
  def handle_message(message_set, state) do
    messages = kafka_message_set(message_set, :messages)

    Enum.each(messages, fn message ->
      %{"id" => id} = kafka_message(message, :key) |> Jason.decode!() |> Map.get("payload")

      %{"after" => attrs, "before" => _before, "source" => %{"snapshot" => snapshot, "table" => table}} =
        kafka_message(message, :value) |> Jason.decode!() |> Map.get("payload")

      Logger.debug("Id: " <> inspect(id))
      Logger.debug("Attrs: " <> inspect(attrs))
      Logger.debug("Table: #{table}")
      Logger.debug("Snapshot: #{snapshot}")

      create_entity(table, attrs)
    end)

    {:ok, :commit, state}
  end

  defp create_entity("users", attrs) do
    query = """
      MERGE (u:User {id: {id}})
      ON MATCH
        SET
          u.name = {name},
          u.nickname = {nickname}
    """
    Sips.query!(Sips.conn(), query, attrs)
  end

  defp create_entity("following_relationships", attrs) do
    query = """
      MATCH (follower:User {id: {follower_id}})
      MATCH (following:User {id: {following_id}})
      MERGE (follower)-[rel:FOLLOWS]->(following)
    """
    case Sips.query!(Sips.conn(), query, attrs) do
      %Sips.Response{stats: %{"relationships-created" => _}} ->
        :ok

      _ ->
        Logger.warn("Couldn't create relation")
        %Bolt.Sips.Response{} = Sips.query!(Sips.conn(), """
          CREATE (follower:User {id: {follower_id}})-[rel:FOLLOWS]->(following:User {id: {following_id}})
        """, attrs)
    end
  end
end
