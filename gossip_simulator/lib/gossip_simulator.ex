defmodule GossipSimulator do
  def main(args) do
    # GossipSimulator.Controller.startNodes(300, "full", "gossip")
    #IO.puts Kernel.inspect(args)
    [node_num, topology, algorithm] = args
    node_num = String.to_integer(node_num)
    GossipSimulator.Controller.startNodes(node_num, topology, algorithm)
    #IO.puts Kernel.inspect(GossipSimulator.Topology.get_topology_line([1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17]))
  end
end
