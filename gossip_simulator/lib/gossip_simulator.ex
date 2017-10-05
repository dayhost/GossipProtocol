defmodule GossipSimulator do
  def main(args) do
    GossipSimulator.Controller.startNodes(3, "test", "gossip")
    # GossipSimulator.Controller.startNodes(3, "test", "push-sum")
  end
end
