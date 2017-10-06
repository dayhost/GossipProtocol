defmodule GossipSimulator do
  def main(args) do
    # GossipSimulator.Controller.startNodes(3, "full", "gossip")
    GossipSimulator.Controller.startNodes(3, "full", "push-sum")
  end
end
