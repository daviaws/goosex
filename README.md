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
3. dynamically distribute just one Player process per node ✅
3.1. libcluster: using gossip (it accepts k8s as protocol also) for cluster healing/formation ✅
3.2. stablish dynamic players across cluster ✅
3.3. NodeListener: to handle joins and downs of nodes ✅
3.4. adequate supervision tree: respawn died and unconnected quorum nodes on netsplit ✅
4. http route for querying Player type 

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

# Running clustered (libcluster)

```ex
# shell 1
PORT=4000 iex --sname a -S mix phx.server

# shell 2
PORT=4001 iex --sname b -S mix phx.server

# shell 3
PORT=4002 iex --sname c -S mix phx.server

# shell 4
PORT=4003 iex --sname d -S mix phx.server
iex(c@davi-dragon)1> Node.list
[:"d@davi-dragon", :"a@davi-dragon", :"b@davi-dragon"]
iex(c@davi-dragon)2> Xoose.start_distributed
:ok
```

In case of node down / netsplit it will be automatic quorum resolution after 1 second of the first node down.

The game only will end if there is no suficient quorum then it will need a manual `Xoose.start_distributed`.

Else: the game can resume itself with elastic scaling.

**Tip: for simulating a netsplit out of quorum:**
1. I used terminator terminal
2. then I opened 4 tab (ctrl + shift + e & ctrl + shift + o)
3. I followed the 4 nodes spawn
4. now you can test node connection and disconnection logs
5. you can check the game does not start until `Xoose.start_distributed`
6. you can then close any 3 nodes before 1 second and check :out_of_quorum restart
7. any other scenary when there are sufficient quorum the game keeps going