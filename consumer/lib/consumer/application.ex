defmodule Consumer.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Bolt.Sips, Application.get_env(:bolt_sips, Bolt)},
      {Consumer.Debezium, Application.get_env(:consumer, Consumer.Debezium)}
    ]

    opts = [strategy: :one_for_one, name: Consumer.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
