defmodule GossipSimulator.Controller do
    def startNodes(numNodes, topology, algorithm) do
        pidList = []
        case algorithm do
            "gossip" ->
                pidList = Enum.map(1..numNodes, fn x -> elem(GossipSimulator.GPNode.start_link(x), 1) end)
                start_pid = get_start_node(pidList)
                neighbors_map =
                    case topology do
                        "2D"->
                            GossipSimulator.Topology.get_topology_2d(pidList)
                        "line"->
                            GossipSimulator.Topology.get_topology_line(pidList)
                        "full"->
                            GossipSimulator.Topology.get_topology_all(pidList)
                        "imp2D"->
                            GossipSimulator.Topology.get_topology_inp_2d(pidList)
                    end
                keys = Map.keys(neighbors_map)
                gossip_set_neighbors(neighbors_map, keys)
                gossip_trigger(start_pid)
            "push-sum" ->
                pidList = Enum.map(1..numNodes, fn x -> elem(GossipSimulator.PSNode.start_link(x), 1) end)
                start_pid = get_start_node(pidList)
                neighbors_map =
                case topology do
                    "2D"->
                        GossipSimulator.Topology.get_topology_2d(pidList)
                    "line"->
                        GossipSimulator.Topology.get_topology_line(pidList)
                    "full"->
                        GossipSimulator.Topology.get_topology_all(pidList)
                    "imp2D"->
                        GossipSimulator.Topology.get_topology_inp_2d(pidList)
                end
                keys = Map.keys(neighbors_map)
                ps_set_neighbors(neighbors_map, keys)
                ps_trigger(start_pid)
        end
        
        IO.puts Kernel.inspect(pidList)
        stay()
    end

    defp gossip_set_neighbors(neighbors_map, keys) do
        case neighbors_map==%{} do
            true->
                "finish"
            false->
                {key, keys} = List.pop_at(keys, 0)
                {neighbor, neighbors_map} = Map.pop(neighbors_map, key)
                GossipSimulator.GPNode.set_neighbor(key, neighbor)
                gossip_set_neighbors(neighbors_map, keys)
        end
    end

    defp ps_set_neighbors(neighbors_map, keys) do
        case neighbors_map==%{} do
            true->
                "finish"
            false->
                {key, keys} = List.pop_at(keys, 0)
                {neighbor, neighbors_map} = Map.pop(neighbors_map, key)
                GossipSimulator.PSNode.set_neighbor(key, neighbor)
                gossip_set_neighbors(neighbors_map, keys)
        end
    end

    # This is only for test, without toplogy nodel
    defp gossip_trigger(start_pid) do
        GossipSimulator.GPNode.send_msg(start_pid, "msg")
    end

    # This is only for test, without toplogy nodel
    defp ps_trigger(start_pid) do
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