defmodule GossipSimulator.Controller do
    def startNodes(numNodes, topology, algorithm) do
        # pidList = []
        case algorithm do
            "gossip" ->
                pidList = Enum.map(1..numNodes, fn x -> elem(GossipSimulator.GPNode.start_link(x), 1) end)
                start_pid = get_start_node(pidList)
                IO.puts "Build topology."
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
                # IO.puts "#{inspect neighbors_map}"
                # :timer.sleep(1000000)
                start_timer = System.system_time(:millisecond)
                IO.puts "Start protocol."
                IO.puts "=============Start time: #{inspect start_timer} millisecond."
                keys = Map.keys(neighbors_map)
                gossip_set_neighbors(neighbors_map, keys)
                gossip_trigger(start_pid)
                # monitor_nodes = Task.async(fn pidList -> monitor_nodes(pidList) end)
                end_timer = monitor_nodes(pidList)
                IO.puts "=============End time: #{inspect end_timer} millisecond."
                duration = (end_timer - start_timer)
                IO.puts "Running time: #{inspect duration}."
            "push-sum" ->
                pidList = Enum.map(1..numNodes, fn x -> elem(GossipSimulator.PSNode.start_link(x), 1) end)
                start_pid = get_start_node(pidList)
                IO.puts "Build topology."
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
                start_timer = System.system_time(:millisecond)
                IO.puts "Start protocol."
                IO.puts "=============Start time: #{inspect start_timer} millisecond."
                keys = Map.keys(neighbors_map)
                ps_set_neighbors(neighbors_map, keys)
                ps_trigger(start_pid)
                # monitor_nodes = Task.async(fn pidList -> monitor_nodes(pidList) end)
                end_timer = monitor_nodes(pidList)
                IO.puts "=============End time: #{inspect end_timer} millisecond."
                duration = (end_timer - start_timer)
                IO.puts "Running time: #{inspect duration} millisecond."               
        end
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
        Enum.at(pidList, random_number-1)
    end

    # def stay() do
    #     :timer.sleep(100)
    #     stay()
    # end

    defp monitor_nodes(pid_list) do
        # If ture keep loop, otherwise
        if check_alive(pid_list) do
            # IO.puts "Some pids live."
            monitor_nodes(pid_list)     
        else
            # IO.puts "All pids die."
            System.system_time(:millisecond)
        end
    end

    defp check_alive(pid_list) do
        # Return false means all pid is dead. Otherwise return ture
        Enum.reduce(pid_list, false, fn(x, acc) -> Process.alive?(x) || acc end)
    end
end