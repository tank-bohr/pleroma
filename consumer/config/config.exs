import Config

config :bolt_sips, Bolt,
  url: "bolt://neo4j:7687",
  pool_size: 10

config :brod,
  clients: [
    kafka_client: [
      endpoints: [kafka: 9092]
    ]
  ]

config :consumer, Consumer.Debezium, %{
    client: :kafka_client,
    group_id: "consumer_group",
    topics: ["dbserver1.public.users", "dbserver1.public.following_relationships"],
    group_config: [
      offset_commit_policy: :commit_to_kafka_v2,
      offset_commit_interval_seconds: 5,
      rejoin_delay_seconds: 2,
      reconnect_cool_down_seconds: 10
    ],
    consumer_config: [begin_offset: :earliest]
  }
