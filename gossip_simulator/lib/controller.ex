defmodule GossipSimulator.Controller do
    def startNodes(numNodes, topology, algorithm) do
        pidList = []
        case algorithm do
            "gossip" ->
                pidList = Enum.map(1..numNodes, fn x -> elem(GossipSimulator.GPNode.start_link(x), 1) end)
                start_pid = get_start_node(pidList)
                gossip_trigger(start_pid, pidList)
            "push-sum" ->
                pidList = Enum.map(1..numNodes, fn x -> elem(GossipSimulator.PSNode.start_link(x), 1) end)
                start_pid = get_start_node(pidList)
                ps_trigger(start_pid, pidList)
        end
        
        IO.puts Kernel.inspect(pidList)
        stay()
    end
    
    # This is only for test, without toplogy nodel
    defp gossip_trigger(start_pid, pidList) do
        {pid1, pidList} = List.pop_at(pidList, 0)
        {pid2, pidList}  = List.pop_at(pidList, 0)
        {pid3, pidList}  = List.pop_at(pidList, 0)
        GossipSimulator.GPNode.set_neighbor(pid1, [pid2, pid3])
        GossipSimulator.GPNode.set_neighbor(pid2, [pid1, pid3])
        GossipSimulator.GPNode.set_neighbor(pid3, [pid1, pid2])
        GossipSimulator.GPNode.send_msg(start_pid, "aaa")
    end

    # This is only for test, without toplogy nodel
    defp ps_trigger(start_pid, pidList) do
        {pid1, pidList} = List.pop_at(pidList, 0)
        {pid2, pidList}  = List.pop_at(pidList, 0)
        {pid3, pidList}  = List.pop_at(pidList, 0)
        GossipSimulator.GPNode.set_neighbor(pid1, [pid2, pid3])
        GossipSimulator.GPNode.set_neighbor(pid2, [pid1, pid3])
        GossipSimulator.GPNode.set_neighbor(pid3, [pid1, pid2])
        GossipSimulator.PSNode.send_msg(start_pid)
    end

    defp get_start_node(pidList) do
        random_number = :rand.uniform(length(pidList))
        start_pid = Enum.at(pidList, random_number-1)
    end

    def stay() do
        :timer.sleep(100)
        stay()
    end
end