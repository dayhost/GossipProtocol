defmodule GossipSimulator do
  def main(args) do
    GossipSimulator.Controller.createTopology(args)
  end
  def hello do
    :world
  end
end
