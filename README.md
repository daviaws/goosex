# xoose

It's a goose goose duck implementation in Elixir.
It covers basic concepts about clustering and elastic scaling.

# Business Logic

● Design a system that will select a single node as a “Goose” within a cluster of nodes. Every other node should be considered a “Duck”.
○ If the Goose dies, another Duck should become the new Goose.
○ If a dead Goose rejoins, it should become a Duck (assuming there is
already another Goose)
○ There can be only one Goose, even if some working nodes are
unreachable (network partition)

■ Each node should run an http server with an endpoint allowing us to check if that
node is a Duck or a Goose.

Ideally
● Your design should accommodate a dynamic and changing number of nodes
(elastic scale).
● There should be a way to make your design highly available

More on expectations around network partition:
● In the case of a network partition, there should not be 2 geese.
● For example, if your cluster size has grown to 5, and 1 of the nodes is lost due to network partition, it is expected that the goose will be on the side of the 4 nodes.
● Reason being the 4 node side is the only part that can reach a quorum on who
should be the goose in a cluster size of 5, where a minimum of 3 nodes need to
agree to reach consensus.

# Roadmap

1. start project basics (phx.new) ✅
2. basic business logic (local game) ✅
3. dynamically distribute just one Player process per node
4. http route for querying Player type
5. handling quorum netsplit

# Before Start

.tool-version relies on [asdf](https://asdf-vm.com/guide/getting-started.html) to manage elixir versioning

we started this project with phx.new defaults
```sh
mix phx.new xoose
```

# Phoenix Server

To start your Phoenix server:

  * Run `mix setup` to install and setup dependencies
  * Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

# Trying a local goose goose duck game

Run the server as `iex -S mix phx.server`

Then you can run a default of 5 players: `Xoose.start_local()`

Or you can run a custom number of players: `Xoose.start_local(10)`
