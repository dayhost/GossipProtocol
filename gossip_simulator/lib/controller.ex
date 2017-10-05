defmodule GossipSimulator.Controller do
    def createTopology(nums) do
        pidList = []
        {:ok, pid} = GossipSimulator.GPNode.start_link()
        IO.puts "start server 1"
        pidList = List.insert_at(pidList, -1, pid)
        {:ok, pid} = GossipSimulator.GPNode.start_link()
        IO.puts "start server 2"
        pidList = List.insert_at(pidList, -1, pid)
        IO.puts Kernel.inspect(pidList)
        trigger(pidList)
    end

    def trigger(pidList) do
        {pid1, pidList} = List.pop_at(pidList, 0)
        {pid2, pidList}  = List.pop_at(pidList, 0)
        GossipSimulator.GPNode.set_neighbor(pid1, pid1, [pid2])
        GossipSimulator.GPNode.set_neighbor(pid2, pid2, [pid1])
        GossipSimulator.GPNode.send_msg(pid1, "aaa")
        stay()
    end

    def stay() do
        :timer.sleep(100)
        stay()
    end
end