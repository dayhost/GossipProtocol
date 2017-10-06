defmodule GossipSimulator do
  def main(args) do
    # GossipSimulator.Controller.startNodes(300, "full", "gossip")
    GossipSimulator.Controller.startNodes(3, "line", "push-sum")
  end
end
