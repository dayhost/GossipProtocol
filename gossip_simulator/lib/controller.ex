defmodule GossipSimulator.Controller do
    def createTopology(nums) do
        pidList = []
        {:ok, pid} = GossipSimulator.Node.start_link()
        pidList = [pidList | pid]
        {:ok, pid} = GossipSimulator.Node.start_link()
        pidList = [pidList | pid]
    end

    def trigger(pidList) do
        [pid1 | pid2] = pidList
        GossipSimulator.Node.setNeighbor(pid1, [pid2])
        GossipSimulator.Node.setNeighbor(pid2, [pid1])
        GossipSimulator.Node.send(pid1, "aaa")
    end
end