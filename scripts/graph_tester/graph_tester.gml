/// @description Complete unit test suite for Graph library
/// @function TestRunner()

function TestRunner() constructor
{
	test_count = 0;
	passed_count = 0;
	failed_count = 0;
	failed_tests = [];
	
	static Assert = function(condition, test_name)
	{
		test_count++;
		if (condition)
		{
			passed_count++;
			show_debug_message("✓ PASS: " + test_name);
		}
		else
		{
			failed_count++;
			array_push(failed_tests, test_name);
			show_debug_message("✗ FAIL: " + test_name);
		}
	}
	
	static AssertEquals = function(expected, actual, test_name)
	{
		Assert(expected == actual, test_name + " (Expected: " + string(expected) + ", Got: " + string(actual) + ")");
	}
	
	static AssertArrayEquals = function(expected, actual, test_name)
	{
		var equals = is_array(expected) && is_array(actual) && array_length(expected) == array_length(actual);
		if (equals)
		{
			for (var i = 0; i < array_length(expected); i++)
			{
				if (expected[i] != actual[i])
				{
					equals = false;
					break;
				}
			}
		}
		Assert(equals, test_name);
	}
	
	static PrintSummary = function()
	{
		show_debug_message("\n========================================");
		show_debug_message("TEST SUMMARY");
		show_debug_message("========================================");
		show_debug_message("Total tests: " + string(test_count));
		show_debug_message("Passed: " + string(passed_count));
		show_debug_message("Failed: " + string(failed_count));
		show_debug_message("Success rate: " + string((passed_count / test_count) * 100) + "%");
		
		if (failed_count > 0)
		{
			show_debug_message("\nFailed tests:");
			for (var i = 0; i < array_length(failed_tests); i++)
				show_debug_message("  - " + failed_tests[i]);
		}
		show_debug_message("========================================\n");
	}
}

/// @description Test graph construction
function TestGraphConstruction(runner)
{
	show_debug_message("\n=== Testing Graph Construction ===");
	
	// Test 1: Empty undirected graph
	var g1 = new Graph(GraphFlags.GRAPH_NONE);
	runner.AssertEquals(0, g1.GetNodeCount(), "Empty undirected graph - node count");
	runner.AssertEquals(0, g1.GetEdgeCount(), "Empty undirected graph - edge count");
	runner.Assert(!g1.IsDirected(), "Empty graph is undirected");
	runner.Assert(!g1.IsWeighted(), "Empty graph is unweighted");
	
	// Test 2: Directed graph
	var g2 = new Graph(GraphFlags.GRAPH_DIRECTED);
	runner.Assert(g2.IsDirected(), "Directed graph flag");
	
	// Test 3: Weighted graph
	var g3 = new Graph(GraphFlags.GRAPH_WEIGHTED);
	runner.Assert(g3.IsWeighted(), "Weighted graph flag");
	
	// Test 4: Graph with self-loops
	var g4 = new Graph(GraphFlags.GRAPH_ALLOW_SELF_LOOP);
	g4.AddEdge("A", "A");
	runner.Assert(g4.HasEdge("A", "A"), "Self-loop allowed");
	
	// Test 5: Graph without self-loops
	var g5 = new Graph(GraphFlags.GRAPH_NONE);
	g5.AddEdge("A", "A");
	runner.Assert(!g5.HasEdge("A", "A"), "Self-loop not allowed");
	
	// Test 6: Immutable graph
	var g6 = new Graph(GraphFlags.GRAPH_IMMUTABLE);
	runner.Assert(g6.IsImmutable(), "Immutable graph flag");
	g6.AddNode("A");
	runner.AssertEquals(0, g6.GetNodeCount(), "Immutable graph rejects modifications");
	
	// Test 7: Construction with builder (edges array)
	var g7 = new Graph(GraphFlags.GRAPH_NONE, [
		new Edge("A", "B"),
		new Edge("B", "C"),
		new Edge("C", "D")
	]);
	runner.AssertEquals(4, g7.GetNodeCount(), "Builder with edges - node count");
	runner.AssertEquals(3, g7.GetEdgeCount(), "Builder with edges - edge count");
	
	// Test 8: Construction with builder (struct)
	var g8 = new Graph(GraphFlags.GRAPH_NONE, {
		nodes: ["A", "B", "C"],
		edges: [new Edge("A", "B")]
	});
	runner.AssertEquals(3, g8.GetNodeCount(), "Builder with struct - node count");
	runner.AssertEquals(1, g8.GetEdgeCount(), "Builder with struct - edge count");
	
	// Test 9: Combined flags
	var g9 = new Graph(GraphFlags.GRAPH_DIRECTED | GraphFlags.GRAPH_WEIGHTED);
	runner.Assert(g9.IsDirected() && g9.IsWeighted(), "Combined flags");
}

/// @description Test adding nodes
function TestAddNodes(runner)
{
	show_debug_message("\n=== Testing Add Nodes ===");
	
	var g = new Graph(GraphFlags.GRAPH_NONE);
	
	// Test 1: Add single node
	g.AddNode("A");
	runner.AssertEquals(1, g.GetNodeCount(), "Add single node");
	runner.Assert(g.HasNode("A"), "Node exists");
	
	// Test 2: Add multiple nodes (varargs)
	g.Clear();
	g.AddNodes("A", "B", "C", "D");
	runner.AssertEquals(4, g.GetNodeCount(), "Add multiple nodes (varargs)");
	
	// Test 3: Add multiple nodes (array)
	g.Clear();
	g.AddNodes(["_x", "_y", "Z"]);
	runner.AssertEquals(3, g.GetNodeCount(), "Add multiple nodes (array)");
	
	// Test 4: Add duplicate node
	g.Clear();
	g.AddNode("A");
	g.AddNode("A");
	runner.AssertEquals(1, g.GetNodeCount(), "Duplicate node not added");
	
	// Test 5: Add nodes with different types
	g.Clear();
	g.AddNode("String");
	g.AddNode(123);
	g.AddNode(456.78);
	runner.AssertEquals(3, g.GetNodeCount(), "Nodes with different types");
}

/// @description Test adding edges
function TestAddEdges(runner)
{
	show_debug_message("\n=== Testing Add Edges ===");
	
	// Test 1: Simple edge in undirected graph
	var g1 = new Graph(GraphFlags.GRAPH_NONE);
	g1.AddEdge("A", "B");
	runner.AssertEquals(2, g1.GetNodeCount(), "Edge creates nodes");
	runner.AssertEquals(1, g1.GetEdgeCount(), "Single edge count");
	runner.Assert(g1.HasEdge("A", "B"), "Edge A->B exists");
	runner.Assert(g1.HasEdge("B", "A"), "Edge B->A exists (undirected)");
	
	// Test 2: Edge in directed graph
	var g2 = new Graph(GraphFlags.GRAPH_DIRECTED);
	g2.AddEdge("A", "B");
	runner.Assert(g2.HasEdge("A", "B"), "Directed edge A->B exists");
	runner.Assert(!g2.HasEdge("B", "A"), "Directed edge B->A doesn't exist");
	
	// Test 3: Weighted edge
	var g3 = new Graph(GraphFlags.GRAPH_WEIGHTED);
	g3.AddEdge("A", "B", 5.5);
	runner.AssertEquals(5.5, g3.GetWeight("A", "B"), "Weighted edge");
	
	// Test 4: Unweighted edge (default weight)
	var g4 = new Graph(GraphFlags.GRAPH_NONE);
	g4.AddEdge("A", "B");
	runner.AssertEquals(1, g4.GetWeight("A", "B"), "Default weight");
	
	// Test 5: Add multiple edges (varargs)
	var g5 = new Graph(GraphFlags.GRAPH_NONE);
	g5.AddEdges(new Edge("A", "B"), new Edge("B", "C"), new Edge("C", "D"));
	runner.AssertEquals(3, g5.GetEdgeCount(), "Multiple edges (varargs)");
	
	// Test 6: Add multiple edges (array)
	var g6 = new Graph(GraphFlags.GRAPH_NONE);
	g6.AddEdges([new Edge("A", "B"), new Edge("B", "C")]);
	runner.AssertEquals(2, g6.GetEdgeCount(), "Multiple edges (array)");
	
	// Test 7: Edge with array
	var g7 = new Graph(GraphFlags.GRAPH_NONE);
	g7.AddEdge(["_x", "_y", 10]);
	runner.Assert(g7.HasEdge("_x", "_y"), "Edge from array");
	
	// Test 8: Edge with struct
	var g8 = new Graph(GraphFlags.GRAPH_WEIGHTED);
	g8.AddEdge({from: "M", to: "N", weight: 7});
	runner.AssertEquals(7, g8.GetWeight("M", "N"), "Edge from struct");
	
	// Test 9: Duplicate edge
	var g9 = new Graph(GraphFlags.GRAPH_NONE);
	g9.AddEdge("A", "B");
	g9.AddEdge("A", "B");
	runner.AssertEquals(1, g9.GetEdgeCount(), "Duplicate edge not added");
}

/// @description Test removal operations
function TestRemoval(runner)
{
	show_debug_message("\n=== Testing Removal ===");
	
	// Test 1: Remove single node
	var g1 = new Graph(GraphFlags.GRAPH_NONE);
	g1.AddNodes("A", "B", "C");
	g1.AddEdge("A", "B");
	g1.RemoveNode("B");
	runner.AssertEquals(2, g1.GetNodeCount(), "Node removed");
	runner.Assert(!g1.HasNode("B"), "Node doesn't exist");
	runner.Assert(!g1.HasEdge("A", "B"), "Edge removed with node");
	
	// Test 2: Remove multiple nodes (array)
	var g2 = new Graph(GraphFlags.GRAPH_NONE);
	g2.AddNodes("A", "B", "C", "D", "E");
	g2.RemoveNodes(["B", "D"]);
	runner.AssertEquals(3, g2.GetNodeCount(), "Multiple nodes removed (array)");
	
	// Test 3: Remove multiple nodes (varargs)
	var g3 = new Graph(GraphFlags.GRAPH_NONE);
	g3.AddNodes("A", "B", "C", "D");
	g3.RemoveNodes("A", "C");
	runner.AssertEquals(2, g3.GetNodeCount(), "Multiple nodes removed (varargs)");
	
	// Test 4: Remove single edge
	var g4 = new Graph(GraphFlags.GRAPH_NONE);
	g4.AddEdge("A", "B");
	g4.AddEdge("B", "C");
	g4.RemoveEdge("A", "B");
	runner.AssertEquals(1, g4.GetEdgeCount(), "Edge removed");
	runner.Assert(!g4.HasEdge("A", "B"), "Edge doesn't exist");
	
	// Test 5: Remove edge in directed graph
	var g5 = new Graph(GraphFlags.GRAPH_DIRECTED);
	g5.AddEdge("A", "B");
	g5.RemoveEdge("A", "B");
	runner.Assert(!g5.HasEdge("A", "B"), "Directed edge removed");
	runner.AssertEquals(0, g5.GetEdgeCount(), "Edge count after removal");
	
	// Test 6: Remove multiple edges
	var g6 = new Graph(GraphFlags.GRAPH_NONE);
	g6.AddEdges([new Edge("A", "B"), new Edge("B", "C"), new Edge("C", "D")]);
	g6.RemoveEdges([new Edge("A", "B"), new Edge("C", "D")]);
	runner.AssertEquals(1, g6.GetEdgeCount(), "Multiple edges removed");

}

/// @description Test getter functions
function TestGetters(runner)
{
	show_debug_message("\n=== Testing Getters ===");
	
	var g = new Graph(GraphFlags.GRAPH_WEIGHTED);
	g.AddEdge("A", "B", 5);
	g.AddEdge("B", "C", 3);
	g.AddEdge("A", "C", 7);
	
	// Test 1: GetNodes
	var nodes = g.GetNodes();
	runner.AssertEquals(3, array_length(nodes), "GetNodes count");
	
	// Test 2: GetEdges
	var edges = g.GetEdges();
	runner.AssertEquals(3, array_length(edges), "GetEdges count");
	
	// Test 3: GetNeighbors
	var neighbors = g.GetNeighbors("A");
	runner.AssertEquals(2, array_length(neighbors), "GetNeighbors count");
	
	// Test 4: GetNeighbors for non-existent node
	var no_neighbors = g.GetNeighbors("Z");
	runner.AssertEquals(0, array_length(no_neighbors), "GetNeighbors for non-existent node");
	
	// Test 5: GetEdge
	var edge = g.GetEdge("A", "B");
	runner.Assert(edge != undefined, "GetEdge returns edge");
	runner.AssertEquals(5, edge.weight, "Edge weight");
	
	// Test 6: GetWeight
	runner.AssertEquals(3, g.GetWeight("B", "C"), "GetWeight");
	
	// Test 7: SetWeight
	g.SetWeight("A", "B", 10);
	runner.AssertEquals(10, g.GetWeight("A", "B"), "SetWeight");
	
	// Test 8: GetNeighborsCount
	runner.AssertEquals(2, g.GetNeighborsCount("A"), "GetNeighborsCount");
}

/// @description Test degree calculations
function TestDegrees(runner)
{
	show_debug_message("\n=== Testing Degrees ===");
	
	// Test 1: Degrees in undirected graph
	var g1 = new Graph(GraphFlags.GRAPH_NONE);
	g1.AddEdge("A", "B");
	g1.AddEdge("A", "C");
	g1.AddEdge("A", "D");
	runner.AssertEquals(3, g1.GetDegree("A"), "Undirected degree");
	runner.AssertEquals(3, g1.GetOutDegree("A"), "Undirected out-degree");
	runner.AssertEquals(3, g1.GetInDegree("A"), "Undirected in-degree");
	
	// Test 2: Degrees in directed graph
	var g2 = new Graph(GraphFlags.GRAPH_DIRECTED);
	g2.AddEdge("A", "B");
	g2.AddEdge("A", "C");
	g2.AddEdge("D", "A");
	runner.AssertEquals(2, g2.GetOutDegree("A"), "Directed out-degree");
	runner.AssertEquals(1, g2.GetInDegree("A"), "Directed in-degree");
	runner.AssertEquals(3, g2.GetDegree("A"), "Directed total degree");
	
	// Test 3: Degree of isolated node
	var g3 = new Graph(GraphFlags.GRAPH_NONE);
	g3.AddNode("Isolated");
	runner.AssertEquals(0, g3.GetDegree("Isolated"), "Isolated node degree");
	
	// Test 4: Degree of non-existent node
	var g4 = new Graph(GraphFlags.GRAPH_NONE);
	runner.AssertEquals(0, g4.GetDegree("NonExistent"), "Non-existent node degree");
}

/// @description Test BFS algorithm
function TestBFS(runner)
{
	show_debug_message("\n=== Testing BFS ===");
	
	var g = new Graph(GraphFlags.GRAPH_NONE);
	g.AddEdge("A", "B");
	g.AddEdge("A", "C");
	g.AddEdge("B", "D");
	g.AddEdge("C", "E");
	
	// Test 1: Basic BFS
	var result = g.BFS("A");
	runner.AssertEquals(5, array_length(result.visited), "BFS visits all nodes");
	runner.Assert(result.visited[0] == "A", "BFS starts at source");
	
	// Test 2: BFS with target
	var result2 = g.BFS("A", "D");
	runner.Assert(result2.visited[array_length(result2.visited) - 1] == "D", "BFS stops at target");
	
	// Test 3: BFS on non-existent node
	var result3 = g.BFS("Z");
	runner.Assert(result3 == undefined, "BFS on non-existent node");
	
	// Test 4: HasPath
	runner.Assert(g.HasPath("A", "E"), "Path exists");
	runner.Assert(!g.HasPath("A", "Z"), "Path doesn't exist");
	
	// Test 5: GetPath
	var path = g.GetPath("A", "D");
	runner.Assert(is_array(path), "GetPath returns array");
	runner.Assert(path[0] == "A" && path[array_length(path) - 1] == "D", "Path from A to D");
}

/// @description Test Dijkstra algorithm
function TestDijkstra(runner)
{
	show_debug_message("\n=== Testing Dijkstra ===");
	
	var g = new Graph(GraphFlags.GRAPH_WEIGHTED | GraphFlags.GRAPH_DIRECTED);
	g.AddEdge("A", "B", 4);
	g.AddEdge("A", "C", 2);
	g.AddEdge("B", "D", 3);
	g.AddEdge("C", "B", 1);
	g.AddEdge("C", "D", 5);
	
	// Test 1: Basic Dijkstra
	var result = g.Dijkstra("A", "D");
	runner.Assert(result != undefined, "Dijkstra returns result");
	runner.AssertEquals(6, result.distances[$ "D"], "Shortest distance A to D");
	
	// Test 2: GetShortestPath
	var path = g.GetShortestPath("A", "D");
	runner.Assert(is_array(path), "Shortest path is array");
	runner.Assert(path[0] == "A", "Path starts at source");
	runner.Assert(path[array_length(path) - 1] == "D", "Path ends at target");
	
	// Test 3: GetShortestDistance
	var dist = g.GetShortestDistance("A", "D");
	runner.AssertEquals(6, dist, "Shortest distance");
	
	// Test 4: Dijkstra with negative weights
	var g2 = new Graph(GraphFlags.GRAPH_WEIGHTED | GraphFlags.GRAPH_DIRECTED);
	g2.AddEdge("A", "B", -5);
	var result2 = g2.Dijkstra("A");
	runner.Assert(result2 == undefined, "Dijkstra rejects negative weights");
}

/// @description Test connected components
function TestComponents(runner)
{
	show_debug_message("\n=== Testing Components ===");
	
	// Test 1: Connected graph
	var g1 = new Graph(GraphFlags.GRAPH_NONE);
	g1.AddEdge("A", "B");
	g1.AddEdge("B", "C");
	g1.AddEdge("C", "D");
	runner.Assert(g1.IsConnected(), "Connected graph");
	runner.AssertEquals(1, g1.GetComponentsCount(), "One component");
	
	// Test 2: Disconnected graph
	var g2 = new Graph(GraphFlags.GRAPH_NONE);
	g2.AddEdge("A", "B");
	g2.AddEdge("C", "D");
	g2.AddEdge("E", "F");
	runner.Assert(!g2.IsConnected(), "Disconnected graph");
	runner.AssertEquals(3, g2.GetComponentsCount(), "Three components");
	
	// Test 3: GetComponents
	var components = g2.GetComponents();
	runner.AssertEquals(3, array_length(components), "GetComponents returns all components");
}

/// @description Test copy and clone operations
function TestCopyClone(runner)
{
	show_debug_message("\n=== Testing Copy & Clone ===");
	
	var g1 = new Graph(GraphFlags.GRAPH_WEIGHTED);
	g1.AddEdge("A", "B", 5);
	g1.AddEdge("B", "C", 3);
	
	// Test 1: Clone
	var g2 = g1.Clone();
	runner.AssertEquals(g1.GetNodeCount(), g2.GetNodeCount(), "Clone has same nodes");
	runner.AssertEquals(g1.GetEdgeCount(), g2.GetEdgeCount(), "Clone has same edges");
	runner.AssertEquals(g1.GetWeight("A", "B"), g2.GetWeight("A", "B"), "Clone has same weights");
	
	// Test 2: Clone modification doesn't affect original
	g2.AddEdge("C", "D");
	runner.Assert(g1.GetEdgeCount() != g2.GetEdgeCount(), "Clone is independent");
	
	// Test 3: Clone with unfreeze
	var g3 = new Graph(GraphFlags.GRAPH_IMMUTABLE);
	g3 = new Graph(GraphFlags.GRAPH_NONE, [new Edge("_x", "_y")]).Freeze();
	var g4 = g3.Clone(true);
	runner.Assert(!g4.IsImmutable(), "Clone unfrozen");
	
	// Test 4: Copy
	var g5 = new Graph(GraphFlags.GRAPH_NONE);
	g5.Copy(g1);
	runner.AssertEquals(g1.GetNodeCount(), g5.GetNodeCount(), "Copy has same nodes");
}

/// @description Test immutability features
function TestImmutability(runner)
{
	show_debug_message("\n=== Testing Immutability ===");
	
	var g = new Graph(GraphFlags.GRAPH_IMMUTABLE);
	
	// Test 1: Cannot add nodes
	g.AddNode("A");
	runner.AssertEquals(0, g.GetNodeCount(), "Cannot add nodes to immutable graph");
	
	// Test 2: Cannot add edges
	g.AddEdge("A", "B");
	runner.AssertEquals(0, g.GetEdgeCount(), "Cannot add edges to immutable graph");
	
	// Test 3: Cannot remove from frozen graph
	var g2 = new Graph(GraphFlags.GRAPH_NONE, [new Edge("A", "B")]);
	g2.Freeze();
	g2.RemoveNode("A");
	runner.AssertEquals(2, g2.GetNodeCount(), "Cannot remove from frozen graph");
	
	// Test 4: Cannot clear frozen graph
	g2.Clear();
	runner.Assert(g2.GetNodeCount() > 0, "Cannot clear frozen graph");
}

/// @description Test path finding
function TestPaths(runner)
{
	show_debug_message("\n=== Testing Paths ===");
	
	// Test 1: Shortest unweighted path
	var g1 = new Graph(GraphFlags.GRAPH_NONE);
	g1.AddEdge("A", "B");
	g1.AddEdge("B", "C");
	g1.AddEdge("A", "C"); // Direct path is shorter
	var path = g1.GetShortestPath("A", "C");
	runner.AssertEquals(2, array_length(path), "Shortest unweighted path length");
	
	// Test 2: Shortest unweighted distance
	var dist = g1.GetShortestDistance("A", "C");
	runner.AssertEquals(1, dist, "Shortest unweighted distance");
	
	// Test 3: No path exists
	var g2 = new Graph(GraphFlags.GRAPH_NONE);
	g2.AddNode("A");
	g2.AddNode("B");
	var path2 = g2.GetShortestPath("A", "B");
	runner.Assert(path2 == undefined, "No path exists");
	var dist2 = g2.GetShortestDistance("A", "B");
	runner.AssertEquals(-1, dist2, "No path distance is -1");
}

/// @description Run all unit tests
function RunAllTests()
{
	var runner = new TestRunner();
	
	show_debug_message("\n########################################");
	show_debug_message("# GRAPH LIBRARY - COMPLETE UNIT TESTS #");
	show_debug_message("########################################");
	
	TestGraphConstruction(runner);
	TestAddNodes(runner);
	TestAddEdges(runner);
	TestRemoval(runner);
	TestGetters(runner);
	TestDegrees(runner);
	TestBFS(runner);
	TestDijkstra(runner);
	TestComponents(runner);
	TestCopyClone(runner);
	TestImmutability(runner);
	TestPaths(runner);
	
	runner.PrintSummary();
	
	return runner;
}

/// @description Benchmark timer utility
function BenchmarkTimer() constructor
{
    start_time = 0;
    end_time = 0;
    
    static Start = function()
    {
        start_time = get_timer();
    }
    
    static Stop = function()
    {
        end_time = get_timer();
        return GetElapsed();
    }
    
    static GetElapsed = function()
    {
        return (end_time - start_time) / 1000; // Convert to milliseconds
    }
}

/// @description Benchmark result container
function BenchmarkResult(name, time_ms, operations) constructor
{
    self.name = name;
    self.time_ms = time_ms;
    self.operations = operations;
    self.ops_per_sec = (operations / time_ms) * 1000;
    self.avg_time_per_op = time_ms / operations;
}

/// @description Benchmark runner with comprehensive metrics
function BenchmarkRunner() constructor
{
    results = [];
    
    static AddResult = function(name, time_ms, operations)
    {
        var _result = new BenchmarkResult(name, time_ms, operations);
        array_push(results, _result);
        
        show_debug_message($"✓ {name}:");
        show_debug_message($"  Total: {time_ms}ms | Per Op: {_result.avg_time_per_op}ms | Throughput: {_result.ops_per_sec} ops/sec");
        
        return _result;
    }
    
    static PrintSummary = function()
    {
        show_debug_message("\n" + string_repeat("=", 80));
        show_debug_message("BENCHMARK SUMMARY");
        show_debug_message(string_repeat("=", 80));
        show_debug_message($"Total benchmarks: {array_length(results)}");
        show_debug_message(string_repeat("-", 80));
        
        var total_time = 0;
        for (var i = 0; i < array_length(results); i++)
        {
            var r = results[i];
            total_time += r.time_ms;
            show_debug_message($"[{i + 1}] {r.name}");
            show_debug_message($"    Time: {r.time_ms}ms | Ops: {r.operations} | Throughput: {r.ops_per_sec} ops/sec");
        }
        
        show_debug_message(string_repeat("-", 80));
        show_debug_message($"Total execution time: {total_time}ms");
        show_debug_message(string_repeat("=", 80) + "\n");
    }
    
    static GetFastestResult = function()
    {
        if (array_length(results) == 0) return undefined;
        
        var _fastest = results[0];
        for (var i = 1; i < array_length(results); i++)
        {
            if (results[i].time_ms < _fastest.time_ms)
                _fastest = results[i];
        }
        return _fastest;
    }
    
    static GetSlowestResult = function()
    {
        if (array_length(results) == 0) return undefined;
        
        var _slowest = results[0];
        for (var i = 1; i < array_length(results); i++)
        {
            if (results[i].time_ms > _slowest.time_ms)
                _slowest = results[i];
        }
        return _slowest;
    }
}

#region Construction Benchmarks

/// @description Benchmark empty graph construction
function BenchmarkEmptyConstruction(runner, iterations)
{
    var timer = new BenchmarkTimer();
    timer.Start();
    
    for (var i = 0; i < iterations; i++)
    {
        var g = new Graph(GraphFlags.GRAPH_NONE);
    }
    
    var elapsed = timer.Stop();
    runner.AddResult("Empty Graph Construction", elapsed, iterations);
}

/// @description Benchmark directed graph construction
function BenchmarkDirectedConstruction(runner, iterations)
{
    var timer = new BenchmarkTimer();
    timer.Start();
    
    for (var i = 0; i < iterations; i++)
    {
        var g = new Graph(GraphFlags.GRAPH_DIRECTED);
    }
    
    var elapsed = timer.Stop();
    runner.AddResult("Directed Graph Construction", elapsed, iterations);
}

/// @description Benchmark weighted graph construction
function BenchmarkWeightedConstruction(runner, iterations)
{
    var timer = new BenchmarkTimer();
    timer.Start();
    
    for (var i = 0; i < iterations; i++)
    {
        var g = new Graph(GraphFlags.GRAPH_WEIGHTED);
    }
    
    var elapsed = timer.Stop();
    runner.AddResult("Weighted Graph Construction", elapsed, iterations);
}

/// @description Benchmark graph construction with edges
function BenchmarkConstructionWithEdges(runner, edge_count, iterations)
{
    // Prepare edges array
    var edges = [];
    for (var i = 0; i < edge_count; i++)
        array_push(edges, new Edge(i, i + 1));
    
    var timer = new BenchmarkTimer();
    timer.Start();
    
    for (var i = 0; i < iterations; i++)
    {
        var g = new Graph(GraphFlags.GRAPH_NONE, edges);
    }
    
    var elapsed = timer.Stop();
    runner.AddResult($"Graph Construction with {edge_count} Edges", elapsed, iterations);
}

/// @description Benchmark graph construction with struct builder
function BenchmarkConstructionWithStruct(runner, node_count, iterations)
{
    // Prepare nodes array
    var nodes = [];
    for (var i = 0; i < node_count; i++)
        array_push(nodes, i);
    
    var timer = new BenchmarkTimer();
    timer.Start();
    
    for (var i = 0; i < iterations; i++)
    {
        var g = new Graph(GraphFlags.GRAPH_NONE, {nodes: nodes, edges: []});
    }
    
    var elapsed = timer.Stop();
    runner.AddResult($"Graph Construction with Struct ({node_count} nodes)", elapsed, iterations);
}

/// @description Run all construction benchmarks
function BenchmarkConstruction(runner)
{
    show_debug_message("\n=== CONSTRUCTION BENCHMARKS ===");
    
    BenchmarkEmptyConstruction(runner, 10000);
    BenchmarkDirectedConstruction(runner, 10000);
    BenchmarkWeightedConstruction(runner, 10000);
    BenchmarkConstructionWithEdges(runner, 100, 1000);
    BenchmarkConstructionWithEdges(runner, 500, 200);
    BenchmarkConstructionWithStruct(runner, 100, 1000);
    BenchmarkConstructionWithStruct(runner, 500, 200);
}

#endregion

#region Node Operations Benchmarks

/// @description Benchmark individual node addition
function BenchmarkAddNodesIndividual(runner, node_count)
{
    var timer = new BenchmarkTimer();
    timer.Start();
    
    var g = new Graph(GraphFlags.GRAPH_NONE);
    for (var i = 0; i < node_count; i++)
    {
        g.AddNode("Node_" + string(i));
    }
    
    var elapsed = timer.Stop();
    runner.AddResult($"Add {node_count} Nodes (Individual)", elapsed, node_count);
}

/// @description Benchmark batch node addition with array
function BenchmarkAddNodesBatch(runner, node_count)
{
    // Prepare nodes array
    var nodes = [];
    for (var i = 0; i < node_count; i++)
        array_push(nodes, "Node_" + string(i));
    
    var timer = new BenchmarkTimer();
    timer.Start();
    
    var g = new Graph(GraphFlags.GRAPH_NONE);
    g.AddNodes(nodes);
    
    var elapsed = timer.Stop();
    runner.AddResult($"Add {node_count} Nodes (Batch Array)", elapsed, node_count);
}

/// @description Benchmark node existence check
function BenchmarkHasNode(runner, node_count, check_count)
{
    // Setup graph with nodes
    var g = new Graph(GraphFlags.GRAPH_NONE);
    for (var i = 0; i < node_count; i++)
        g.AddNode(i);
    
    var timer = new BenchmarkTimer();
    timer.Start();
    
    for (var i = 0; i < check_count; i++)
    {
        g.HasNode(irandom(node_count - 1));
    }
    
    var elapsed = timer.Stop();
    runner.AddResult($"HasNode Check ({node_count} nodes, {check_count} checks)", elapsed, check_count);
}

/// @description Benchmark node removal
function BenchmarkRemoveNodes(runner, node_count, remove_count)
{
    // Setup graph
    var g = new Graph(GraphFlags.GRAPH_NONE);
    for (var i = 0; i < node_count; i++)
        g.AddNode(i);
    
    var timer = new BenchmarkTimer();
    timer.Start();
    
    for (var i = 0; i < remove_count; i++)
    {
        g.RemoveNode(i);
    }
    
    var elapsed = timer.Stop();
    runner.AddResult($"Remove {remove_count} Nodes (from {node_count})", elapsed, remove_count);
}

/// @description Benchmark GetNodes operation
function BenchmarkGetNodes(runner, node_count, iterations)
{
    // Setup graph
    var g = new Graph(GraphFlags.GRAPH_NONE);
    for (var i = 0; i < node_count; i++)
        g.AddNode(i);
    
    var timer = new BenchmarkTimer();
    timer.Start();
    
    for (var i = 0; i < iterations; i++)
    {
        var nodes = g.GetNodes();
    }
    
    var elapsed = timer.Stop();
    runner.AddResult($"GetNodes ({node_count} nodes, {iterations} calls)", elapsed, iterations);
}

/// @description Run all node operation benchmarks
function BenchmarkNodeOperations(runner)
{
    show_debug_message("\n=== NODE OPERATIONS BENCHMARKS ===");
    
    BenchmarkAddNodesIndividual(runner, 100);
    BenchmarkAddNodesIndividual(runner, 500);
    BenchmarkAddNodesIndividual(runner, 1000);
    BenchmarkAddNodesBatch(runner, 100);
    BenchmarkAddNodesBatch(runner, 500);
    BenchmarkAddNodesBatch(runner, 1000);
    BenchmarkHasNode(runner, 1000, 10000);
    BenchmarkRemoveNodes(runner, 1000, 500);
    BenchmarkGetNodes(runner, 100, 1000);
    BenchmarkGetNodes(runner, 1000, 100);
}

#endregion

#region Edge Operations Benchmarks

/// @description Benchmark adding undirected edges
function BenchmarkAddEdgesUndirected(runner, edge_count)
{
    var timer = new BenchmarkTimer();
    timer.Start();
    
    var g = new Graph(GraphFlags.GRAPH_NONE);
    for (var i = 0; i < edge_count; i++)
    {
        g.AddEdge(i, i + 1);
    }
    
    var elapsed = timer.Stop();
    runner.AddResult($"Add {edge_count} Undirected Edges", elapsed, edge_count);
}

/// @description Benchmark adding directed edges
function BenchmarkAddEdgesDirected(runner, edge_count)
{
    var timer = new BenchmarkTimer();
    timer.Start();
    
    var g = new Graph(GraphFlags.GRAPH_DIRECTED);
    for (var i = 0; i < edge_count; i++)
    {
        g.AddEdge(i, i + 1);
    }
    
    var elapsed = timer.Stop();
    runner.AddResult($"Add {edge_count} Directed Edges", elapsed, edge_count);
}

/// @description Benchmark adding weighted edges
function BenchmarkAddEdgesWeighted(runner, edge_count)
{
    var timer = new BenchmarkTimer();
    timer.Start();
    
    var g = new Graph(GraphFlags.GRAPH_WEIGHTED);
    for (var i = 0; i < edge_count; i++)
    {
        g.AddEdge(i, i + 1, random(100));
    }
    
    var elapsed = timer.Stop();
    runner.AddResult($"Add {edge_count} Weighted Edges", elapsed, edge_count);
}

/// @description Benchmark batch edge addition
function BenchmarkAddEdgesBatch(runner, edge_count)
{
    // Prepare edges array
    var edges = [];
    for (var i = 0; i < edge_count; i++)
        array_push(edges, new Edge(i, i + 1));
    
    var timer = new BenchmarkTimer();
    timer.Start();
    
    var g = new Graph(GraphFlags.GRAPH_NONE);
    g.AddEdges(edges);
    
    var elapsed = timer.Stop();
    runner.AddResult($"Add {edge_count} Edges (Batch)", elapsed, edge_count);
}

/// @description Benchmark edge existence check
function BenchmarkHasEdge(runner, edge_count, check_count)
{
    // Setup graph with edges
    var g = new Graph(GraphFlags.GRAPH_NONE);
    for (var i = 0; i < edge_count; i++)
        g.AddEdge(i, i + 1);
    
    var timer = new BenchmarkTimer();
    timer.Start();
    
    for (var i = 0; i < check_count; i++)
    {
        var n = irandom(edge_count - 1);
        g.HasEdge(n, n + 1);
    }
    
    var elapsed = timer.Stop();
    runner.AddResult($"HasEdge Check ({edge_count} edges, {check_count} checks)", elapsed, check_count);
}

/// @description Benchmark GetEdges operation
function BenchmarkGetEdges(runner, edge_count, iterations)
{
    // Setup graph
    var g = new Graph(GraphFlags.GRAPH_NONE);
    for (var i = 0; i < edge_count; i++)
        g.AddEdge(i, i + 1);
    
    var timer = new BenchmarkTimer();
    timer.Start();
    
    for (var i = 0; i < iterations; i++)
    {
        var edges = g.GetEdges();
    }
    
    var elapsed = timer.Stop();
    runner.AddResult($"GetEdges ({edge_count} edges, {iterations} calls)", elapsed, iterations);
}

/// @description Benchmark edge removal
function BenchmarkRemoveEdges(runner, edge_count, remove_count)
{
    // Setup graph
    var g = new Graph(GraphFlags.GRAPH_NONE);
    for (var i = 0; i < edge_count; i++)
        g.AddEdge(i, i + 1);
    
    var timer = new BenchmarkTimer();
    timer.Start();
    
    for (var i = 0; i < remove_count; i++)
    {
        g.RemoveEdge(i, i + 1);
    }
    
    var elapsed = timer.Stop();
    runner.AddResult($"Remove {remove_count} Edges (from {edge_count})", elapsed, remove_count);
}

/// @description Benchmark GetNeighbors operation
function BenchmarkGetNeighbors(runner, neighbor_count, iterations)
{
    // Create star graph (one node connected to many)
    var g = new Graph(GraphFlags.GRAPH_NONE);
    for (var i = 1; i <= neighbor_count; i++)
    {
        g.AddEdge(0, i);
    }
    
    var timer = new BenchmarkTimer();
    timer.Start();
    
    for (var i = 0; i < iterations; i++)
    {
        var neighbors = g.GetNeighbors(0);
    }
    
    var elapsed = timer.Stop();
    runner.AddResult($"GetNeighbors ({neighbor_count} neighbors, {iterations} calls)", elapsed, iterations);
}

/// @description Run all edge operation benchmarks
function BenchmarkEdgeOperations(runner)
{
    show_debug_message("\n=== EDGE OPERATIONS BENCHMARKS ===");
    
    BenchmarkAddEdgesUndirected(runner, 100);
    BenchmarkAddEdgesUndirected(runner, 500);
    BenchmarkAddEdgesUndirected(runner, 1000);
    BenchmarkAddEdgesDirected(runner, 100);
    BenchmarkAddEdgesDirected(runner, 1000);
    BenchmarkAddEdgesWeighted(runner, 100);
    BenchmarkAddEdgesWeighted(runner, 1000);
    BenchmarkAddEdgesBatch(runner, 1000);
    BenchmarkHasEdge(runner, 1000, 10000);
    BenchmarkGetEdges(runner, 100, 1000);
    BenchmarkGetEdges(runner, 1000, 100);
    BenchmarkRemoveEdges(runner, 1000, 500);
    BenchmarkGetNeighbors(runner, 100, 1000);
    BenchmarkGetNeighbors(runner, 1000, 100);
}

#endregion

#region Degree Calculation Benchmarks

/// @description Benchmark degree calculation in undirected graph
function BenchmarkDegreeUndirected(runner, edge_count, iterations)
{
    // Create star graph
    var g = new Graph(GraphFlags.GRAPH_NONE);
    for (var i = 1; i <= edge_count; i++)
        g.AddEdge(0, i);
    
    var timer = new BenchmarkTimer();
    timer.Start();
    
    for (var i = 0; i < iterations; i++)
    {
        var degree = g.GetDegree(0);
    }
    
    var elapsed = timer.Stop();
    runner.AddResult($"GetDegree Undirected ({edge_count} edges, {iterations} calls)", elapsed, iterations);
}

/// @description Benchmark out-degree calculation in directed graph
function BenchmarkOutDegreeDirected(runner, edge_count, iterations)
{
    // Create directed star graph
    var g = new Graph(GraphFlags.GRAPH_DIRECTED);
    for (var i = 1; i <= edge_count; i++)
        g.AddEdge(0, i);
    
    var timer = new BenchmarkTimer();
    timer.Start();
    
    for (var i = 0; i < iterations; i++)
    {
        var degree = g.GetOutDegree(0);
    }
    
    var elapsed = timer.Stop();
    runner.AddResult($"GetOutDegree Directed ({edge_count} edges, {iterations} calls)", elapsed, iterations);
}

/// @description Benchmark in-degree calculation in directed graph
function BenchmarkInDegreeDirected(runner, edge_count, iterations)
{
    // Create directed star graph (reversed)
    var g = new Graph(GraphFlags.GRAPH_DIRECTED);
    for (var i = 1; i <= edge_count; i++)
        g.AddEdge(i, 0);
    
    var timer = new BenchmarkTimer();
    timer.Start();
    
    for (var i = 0; i < iterations; i++)
    {
        var degree = g.GetInDegree(0);
    }
    
    var elapsed = timer.Stop();
    runner.AddResult($"GetInDegree Directed ({edge_count} edges, {iterations} calls)", elapsed, iterations);
}

/// @description Run all degree calculation benchmarks
function BenchmarkDegreeCalculations(runner)
{
    show_debug_message("\n=== DEGREE CALCULATION BENCHMARKS ===");
    
    BenchmarkDegreeUndirected(runner, 10, 10000);
    BenchmarkDegreeUndirected(runner, 100, 1000);
    BenchmarkDegreeUndirected(runner, 500, 500);
    BenchmarkOutDegreeDirected(runner, 100, 1000);
    BenchmarkOutDegreeDirected(runner, 500, 500);
    BenchmarkInDegreeDirected(runner, 100, 1000);
    BenchmarkInDegreeDirected(runner, 500, 500);
}

#endregion

#region BFS Algorithm Benchmarks

/// @description Benchmark BFS on linear graph
function BenchmarkBFSLinear(runner, node_count)
{
    // Create linear graph (chain)
    var g = new Graph(GraphFlags.GRAPH_NONE);
    for (var i = 0; i < node_count - 1; i++)
        g.AddEdge(i, i + 1);
    
    var timer = new BenchmarkTimer();
    timer.Start();
    
    var result = g.BFS(0);
    
    var elapsed = timer.Stop();
    runner.AddResult($"BFS on Linear Graph ({node_count} nodes)", elapsed, 1);
}

/// @description Benchmark BFS on complete graph
function BenchmarkBFSComplete(runner, node_count)
{
    // Create complete graph (all connected)
    var g = new Graph(GraphFlags.GRAPH_NONE);
    for (var i = 0; i < node_count; i++)
    {
        for (var j = i + 1; j < node_count; j++)
        {
            g.AddEdge(i, j);
        }
    }
    
    var timer = new BenchmarkTimer();
    timer.Start();
    
    var result = g.BFS(0);
    
    var elapsed = timer.Stop();
    runner.AddResult($"BFS on Complete Graph ({node_count} nodes)", elapsed, 1);
}

/// @description Benchmark BFS with early termination
function BenchmarkBFSWithTarget(runner, node_count)
{
    // Create linear graph
    var g = new Graph(GraphFlags.GRAPH_NONE);
    for (var i = 0; i < node_count - 1; i++)
        g.AddEdge(i, i + 1);
    
    var timer = new BenchmarkTimer();
    timer.Start();
    
    var result = g.BFS(0, node_count / 2); // Stop halfway
    
    var elapsed = timer.Stop();
    runner.AddResult($"BFS with Target (Linear, {node_count} nodes)", elapsed, 1);
}

/// @description Benchmark HasPath operation
function BenchmarkHasPath(runner, node_count, iterations)
{
    // Create linear graph
    var g = new Graph(GraphFlags.GRAPH_NONE);
    for (var i = 0; i < node_count - 1; i++)
        g.AddEdge(i, i + 1);
    
    var timer = new BenchmarkTimer();
    timer.Start();
    
    for (var i = 0; i < iterations; i++)
    {
        var has_path = g.HasPath(0, node_count - 1);
    }
    
    var elapsed = timer.Stop();
    runner.AddResult($"HasPath ({node_count} nodes, {iterations} calls)", elapsed, iterations);
}

/// @description Benchmark GetPath operation
function BenchmarkGetPath(runner, node_count, iterations)
{
    // Create linear graph
    var g = new Graph(GraphFlags.GRAPH_NONE);
    for (var i = 0; i < node_count - 1; i++)
        g.AddEdge(i, i + 1);
    
    var timer = new BenchmarkTimer();
    timer.Start();
    
    for (var i = 0; i < iterations; i++)
    {
        var path = g.GetPath(0, node_count - 1);
    }
    
    var elapsed = timer.Stop();
    runner.AddResult($"GetPath ({node_count} nodes, {iterations} calls)", elapsed, iterations);
}

/// @description Run all BFS benchmarks
function BenchmarkBFS(runner)
{
    show_debug_message("\n=== BFS ALGORITHM BENCHMARKS ===");
    
    BenchmarkBFSLinear(runner, 100);
    BenchmarkBFSLinear(runner, 500);
    BenchmarkBFSLinear(runner, 1000);
    BenchmarkBFSComplete(runner, 50);
    BenchmarkBFSComplete(runner, 100);
    BenchmarkBFSWithTarget(runner, 1000);
    BenchmarkHasPath(runner, 100, 100);
    BenchmarkHasPath(runner, 500, 20);
    BenchmarkGetPath(runner, 100, 100);
    BenchmarkGetPath(runner, 500, 20);
}

#endregion

#region Dijkstra Algorithm Benchmarks

/// @description Benchmark Dijkstra on linear weighted graph
function BenchmarkDijkstraLinear(runner, node_count)
{
    // Create weighted linear graph
    var g = new Graph(GraphFlags.GRAPH_WEIGHTED | GraphFlags.GRAPH_DIRECTED);
    for (var i = 0; i < node_count - 1; i++)
        g.AddEdge(i, i + 1, random_range(1, 10));
    
    var timer = new BenchmarkTimer();
    timer.Start();
    
    var result = g.Dijkstra(0, node_count - 1);
    
    var elapsed = timer.Stop();
    runner.AddResult($"Dijkstra on Linear Graph ({node_count} nodes)", elapsed, 1);
}

/// @description Benchmark Dijkstra on dense graph
function BenchmarkDijkstraDense(runner, node_count)
{
    // Create dense weighted graph
    var g = new Graph(GraphFlags.GRAPH_WEIGHTED | GraphFlags.GRAPH_DIRECTED);
    for (var i = 0; i < node_count; i++)
    {
        for (var j = 0; j < node_count; j++)
        {
            if (i != j && random(1) > 0.5) // 50% edge probability
                g.AddEdge(i, j, random_range(1, 10));
        }
    }
    
    var timer = new BenchmarkTimer();
    timer.Start();
    
    var result = g.Dijkstra(0);
    
    var elapsed = timer.Stop();
    runner.AddResult($"Dijkstra on Dense Graph ({node_count} nodes)", elapsed, 1);
}

/// @description Benchmark GetShortestPath
function BenchmarkGetShortestPath(runner, node_count, iterations)
{
    // Create weighted linear graph
    var g = new Graph(GraphFlags.GRAPH_WEIGHTED | GraphFlags.GRAPH_DIRECTED);
    for (var i = 0; i < node_count - 1; i++)
        g.AddEdge(i, i + 1, random_range(1, 10));
    
    var timer = new BenchmarkTimer();
    timer.Start();
    
    for (var i = 0; i < iterations; i++)
    {
        var path = g.GetShortestPath(0, node_count - 1);
    }
    
    var elapsed = timer.Stop();
    runner.AddResult($"GetShortestPath ({node_count} nodes, {iterations} calls)", elapsed, iterations);
}

/// @description Benchmark GetShortestDistance
function BenchmarkGetShortestDistance(runner, node_count, iterations)
{
    // Create weighted linear graph
    var g = new Graph(GraphFlags.GRAPH_WEIGHTED | GraphFlags.GRAPH_DIRECTED);
    for (var i = 0; i < node_count - 1; i++)
        g.AddEdge(i, i + 1, random_range(1, 10));
    
    var timer = new BenchmarkTimer();
    timer.Start();
    
    for (var i = 0; i < iterations; i++)
    {
        var dist = g.GetShortestDistance(0, node_count - 1);
    }
    
    var elapsed = timer.Stop();
    runner.AddResult($"GetShortestDistance ({node_count} nodes, {iterations} calls)", elapsed, iterations);
}

/// @description Run all Dijkstra benchmarks
function BenchmarkDijkstra(runner)
{
    show_debug_message("\n=== DIJKSTRA ALGORITHM BENCHMARKS ===");
    
    BenchmarkDijkstraLinear(runner, 100);
    BenchmarkDijkstraLinear(runner, 500);
    BenchmarkDijkstraLinear(runner, 1000);
    BenchmarkDijkstraDense(runner, 50);
    BenchmarkDijkstraDense(runner, 100);
    BenchmarkGetShortestPath(runner, 100, 100);
    BenchmarkGetShortestPath(runner, 500, 20);
    BenchmarkGetShortestDistance(runner, 100, 100);
    BenchmarkGetShortestDistance(runner, 500, 20);
}

#endregion

#region Connected Components Benchmarks

/// @description Benchmark IsConnected on connected graph
function BenchmarkIsConnectedTrue(runner, node_count)
{
    // Create connected graph (linear)
    var g = new Graph(GraphFlags.GRAPH_NONE);
    for (var i = 0; i < node_count - 1; i++)
        g.AddEdge(i, i + 1);
    
    var timer = new BenchmarkTimer();
    timer.Start();
    
    var connected = g.IsConnected();
    
    var elapsed = timer.Stop();
    runner.AddResult($"IsConnected on Connected Graph ({node_count} nodes)", elapsed, 1);
}

/// @description Benchmark IsConnected on disconnected graph
function BenchmarkIsConnectedFalse(runner, component_count, nodes_per_component)
{
    // Create disconnected graph with multiple components
    var g = new Graph(GraphFlags.GRAPH_NONE);
    for (var c = 0; c < component_count; c++)
    {
        var offset = c * nodes_per_component;
        for (var i = 0; i < nodes_per_component - 1; i++)
            g.AddEdge(offset + i, offset + i + 1);
    }
    
    var timer = new BenchmarkTimer();
    timer.Start();
    
    var connected = g.IsConnected();
    
    var elapsed = timer.Stop();
    var total_nodes = component_count * nodes_per_component;
    runner.AddResult($"IsConnected on Disconnected Graph ({total_nodes} nodes, {component_count} components)", elapsed, 1);
}

/// @description Benchmark GetComponents operation
function BenchmarkGetComponents(runner, component_count, nodes_per_component)
{
    // Create graph with multiple components
    var g = new Graph(GraphFlags.GRAPH_NONE);
    for (var c = 0; c < component_count; c++)
    {
        var offset = c * nodes_per_component;
        for (var i = 0; i < nodes_per_component - 1; i++)
            g.AddEdge(offset + i, offset + i + 1);
    }
    
    var timer = new BenchmarkTimer();
    timer.Start();
    
    var components = g.GetComponents();
    
    var elapsed = timer.Stop();
    var total_nodes = component_count * nodes_per_component;
    runner.AddResult($"GetComponents ({total_nodes} nodes, {component_count} components)", elapsed, 1);
}

/// @description Benchmark GetComponentsCount operation
function BenchmarkGetComponentsCount(runner, component_count, nodes_per_component)
{
    // Create graph with multiple components
    var g = new Graph(GraphFlags.GRAPH_NONE);
    for (var c = 0; c < component_count; c++)
    {
        var offset = c * nodes_per_component;
        for (var i = 0; i < nodes_per_component - 1; i++)
            g.AddEdge(offset + i, offset + i + 1);
    }
    
    var timer = new BenchmarkTimer();
    timer.Start();
    
    var count = g.GetComponentsCount();
    
    var elapsed = timer.Stop();
    var total_nodes = component_count * nodes_per_component;
    runner.AddResult($"GetComponentsCount ({total_nodes} nodes, {component_count} components)", elapsed, 1);
}

/// @description Run all connected components benchmarks
function BenchmarkComponents(runner)
{
    show_debug_message("\n=== CONNECTED COMPONENTS BENCHMARKS ===");
    
    BenchmarkIsConnectedTrue(runner, 100);
    BenchmarkIsConnectedTrue(runner, 500);
    BenchmarkIsConnectedTrue(runner, 1000);
    BenchmarkIsConnectedFalse(runner, 5, 20);
    BenchmarkIsConnectedFalse(runner, 10, 50);
    BenchmarkGetComponents(runner, 5, 20);
    BenchmarkGetComponents(runner, 10, 50);
    BenchmarkGetComponentsCount(runner, 10, 50);
}

#endregion

#region Copy and Clone Benchmarks

/// @description Benchmark Clone operation
function BenchmarkClone(runner, node_count, edge_count)
{
    // Create source graph
    var g = new Graph(GraphFlags.GRAPH_WEIGHTED);
    for (var i = 0; i < edge_count; i++)
        g.AddEdge(i % node_count, (i + 1) % node_count, random_range(1, 10));
    
    var timer = new BenchmarkTimer();
    timer.Start();
    
    var g_clone = g.Clone();
    
    var elapsed = timer.Stop();
    runner.AddResult($"Clone Graph ({node_count} nodes, {edge_count} edges)", elapsed, 1);
}

/// @description Benchmark Clone with unfreeze
function BenchmarkCloneUnfreeze(runner, node_count, edge_count)
{
    // Create and freeze source graph
    var g = new Graph(GraphFlags.GRAPH_NONE);
    for (var i = 0; i < edge_count; i++)
        g.AddEdge(i % node_count, (i + 1) % node_count);
    g.Freeze();
    
    var timer = new BenchmarkTimer();
    timer.Start();
    
    var g_clone = g.Clone(true);
    
    var elapsed = timer.Stop();
    runner.AddResult($"Clone Frozen Graph with Unfreeze ({node_count} nodes, {edge_count} edges)", elapsed, 1);
}

/// @description Benchmark Copy operation
function BenchmarkCopy(runner, node_count, edge_count)
{
    // Create source graph
    var g_source = new Graph(GraphFlags.GRAPH_WEIGHTED);
    for (var i = 0; i < edge_count; i++)
        g_source.AddEdge(i % node_count, (i + 1) % node_count, random_range(1, 10));
    
    var g_target = new Graph(GraphFlags.GRAPH_NONE);
    
    var timer = new BenchmarkTimer();
    timer.Start();
    
    g_target.Copy(g_source);
    
    var elapsed = timer.Stop();
    runner.AddResult($"Copy Graph ({node_count} nodes, {edge_count} edges)", elapsed, 1);
}

/// @description Run all copy/clone benchmarks
function BenchmarkCopyClone(runner)
{
    show_debug_message("\n=== COPY & CLONE BENCHMARKS ===");
    
    BenchmarkClone(runner, 50, 100);
    BenchmarkClone(runner, 100, 500);
    BenchmarkClone(runner, 500, 1000);
    BenchmarkCloneUnfreeze(runner, 100, 500);
    BenchmarkCopy(runner, 100, 500);
}

#endregion

#region Graph Type Benchmarks

/// @description Benchmark operations on different graph types
function BenchmarkGraphTypes(runner)
{
    show_debug_message("\n=== GRAPH TYPE COMPARISON BENCHMARKS ===");
    
    var edge_count = 1000;
    
    // Undirected graph
    var timer1 = new BenchmarkTimer();
    timer1.Start();
    var g_undirected = new Graph(GraphFlags.GRAPH_NONE);
    for (var i = 0; i < edge_count; i++)
        g_undirected.AddEdge(i, i + 1);
    var elapsed1 = timer1.Stop();
    runner.AddResult($"Build Undirected Graph ({edge_count} edges)", elapsed1, edge_count);
    
    // Directed graph
    var timer2 = new BenchmarkTimer();
    timer2.Start();
    var g_directed = new Graph(GraphFlags.GRAPH_DIRECTED);
    for (var i = 0; i < edge_count; i++)
        g_directed.AddEdge(i, i + 1);
    var elapsed2 = timer2.Stop();
    runner.AddResult($"Build Directed Graph ({edge_count} edges)", elapsed2, edge_count);
    
    // Weighted graph
    var timer3 = new BenchmarkTimer();
    timer3.Start();
    var g_weighted = new Graph(GraphFlags.GRAPH_WEIGHTED);
    for (var i = 0; i < edge_count; i++)
        g_weighted.AddEdge(i, i + 1, random_range(1, 10));
    var elapsed3 = timer3.Stop();
    runner.AddResult($"Build Weighted Graph ({edge_count} edges)", elapsed3, edge_count);
    
    // Combined flags
    var timer4 = new BenchmarkTimer();
    timer4.Start();
    var g_combined = new Graph(GraphFlags.GRAPH_DIRECTED | GraphFlags.GRAPH_WEIGHTED);
    for (var i = 0; i < edge_count; i++)
        g_combined.AddEdge(i, i + 1, random_range(1, 10));
    var elapsed4 = timer4.Stop();
    runner.AddResult($"Build Directed+Weighted Graph ({edge_count} edges)", elapsed4, edge_count);
}

#endregion

#region Complex Graph Benchmarks

/// @description Benchmark on complete graph (all nodes connected)
function BenchmarkCompleteGraph(runner, node_count)
{
    var timer = new BenchmarkTimer();
    timer.Start();
    
    var g = new Graph(GraphFlags.GRAPH_NONE);
    for (var i = 0; i < node_count; i++)
    {
        for (var j = i + 1; j < node_count; j++)
        {
            g.AddEdge(i, j);
        }
    }
    
    var elapsed = timer.Stop();
    var edge_count = (node_count * (node_count - 1)) / 2;
    runner.AddResult($"Build Complete Graph ({node_count} nodes, {edge_count} edges)", elapsed, edge_count);
}

/// @description Benchmark on star graph (hub and spokes)
function BenchmarkStarGraph(runner, node_count)
{
    var timer = new BenchmarkTimer();
    timer.Start();
    
    var g = new Graph(GraphFlags.GRAPH_NONE);
    for (var i = 1; i < node_count; i++)
    {
        g.AddEdge(0, i);
    }
    
    var elapsed = timer.Stop();
    runner.AddResult($"Build Star Graph ({node_count} nodes, {node_count - 1} edges)", elapsed, node_count - 1);
}

/// @description Benchmark on grid graph
function BenchmarkGridGraph(runner, width, height)
{
    var timer = new BenchmarkTimer();
    timer.Start();
    
    var g = new Graph(GraphFlags.GRAPH_NONE);
    
    // Horizontal edges
    for (var _y = 0; _y < height; _y++)
    {
        for (var _x = 0; _x < width - 1; _x++)
        {
            var node1 = _y * width + _x;
            var node2 = _y * width + _x + 1;
            g.AddEdge(node1, node2);
        }
    }
    
    // Vertical edges
    for (var _y = 0; _y < height - 1; _y++)
    {
        for (var _x = 0; _x < width; _x++)
        {
            var node1 = _y * width + _x;
            var node2 = (_y + 1) * width + _x;
            g.AddEdge(node1, node2);
        }
    }
    
    var elapsed = timer.Stop();
    var total_nodes = width * height;
    var edge_count = (width - 1) * height + width * (height - 1);
    runner.AddResult($"Build Grid Graph ({width}_x{height} = {total_nodes} nodes, {edge_count} edges)", elapsed, edge_count);
}

/// @description Run complex graph structure benchmarks
function BenchmarkComplexGraphs(runner)
{
    show_debug_message("\n=== COMPLEX GRAPH STRUCTURE BENCHMARKS ===");
    
    BenchmarkCompleteGraph(runner, 50);
    BenchmarkCompleteGraph(runner, 100);
    BenchmarkStarGraph(runner, 100);
    BenchmarkStarGraph(runner, 500);
    BenchmarkStarGraph(runner, 1000);
    BenchmarkGridGraph(runner, 10, 10);
    BenchmarkGridGraph(runner, 20, 20);
    BenchmarkGridGraph(runner, 30, 30);
}

#endregion

#region Memory and Clear Benchmarks

/// @description Benchmark Clear operation
function BenchmarkClear(runner, node_count, edge_count)
{
    // Create graph
    var g = new Graph(GraphFlags.GRAPH_NONE);
    for (var i = 0; i < edge_count; i++)
        g.AddEdge(i % node_count, (i + 1) % node_count);
    
    var timer = new BenchmarkTimer();
    timer.Start();
    
    g.Clear();
    
    var elapsed = timer.Stop();
    runner.AddResult($"Clear Graph ({node_count} nodes, {edge_count} edges)", elapsed, 1);
}

/// @description Benchmark Freeze operation
function BenchmarkFreeze(runner, node_count, edge_count)
{
    // Create graph
    var g = new Graph(GraphFlags.GRAPH_NONE);
    for (var i = 0; i < edge_count; i++)
        g.AddEdge(i % node_count, (i + 1) % node_count);
    
    var timer = new BenchmarkTimer();
    timer.Start();
    
    g.Freeze();
    
    var elapsed = timer.Stop();
    runner.AddResult($"Freeze Graph ({node_count} nodes, {edge_count} edges)", elapsed, 1);
}

/// @description Run memory-related benchmarks
function BenchmarkMemoryOperations(runner)
{
    show_debug_message("\n=== MEMORY & STATE BENCHMARKS ===");
    
    BenchmarkClear(runner, 100, 500);
    BenchmarkClear(runner, 500, 1000);
    BenchmarkFreeze(runner, 100, 500);
    BenchmarkFreeze(runner, 500, 1000);
}

#endregion

#region Stress Test Benchmarks

/// @description Stress test with large graph
function BenchmarkStressTestLarge(runner)
{
    show_debug_message("\n=== STRESS TEST - LARGE GRAPH ===");
    
    var node_count = 5000;
    var edge_count = 10000;
    
    var timer = new BenchmarkTimer();
    timer.Start();
    
    var g = new Graph(GraphFlags.GRAPH_NONE);
    for (var i = 0; i < edge_count; i++)
    {
        var from = irandom(node_count - 1);
        var to = irandom(node_count - 1);
        if (from != to)
            g.AddEdge(from, to);
    }
    
    var elapsed = timer.Stop();
    runner.AddResult($"Stress Test: Build Random Graph ({node_count} nodes, {edge_count} edges)", elapsed, 1);
}

/// @description Stress test BFS on large graph
function BenchmarkStressTestBFS(runner)
{
    show_debug_message("\n=== STRESS TEST - BFS ON LARGE GRAPH ===");
    
    var node_count = 2000;
    
    // Create linear graph for worst-case BFS
    var g = new Graph(GraphFlags.GRAPH_NONE);
    for (var i = 0; i < node_count - 1; i++)
        g.AddEdge(i, i + 1);
    
    var timer = new BenchmarkTimer();
    timer.Start();
    
    var result = g.BFS(0, node_count - 1);
    
    var elapsed = timer.Stop();
    runner.AddResult($"Stress Test: BFS on Linear Graph ({node_count} nodes)", elapsed, 1);
}

/// @description Stress test Dijkstra on large graph
function BenchmarkStressTestDijkstra(runner)
{
    show_debug_message("\n=== STRESS TEST - DIJKSTRA ON LARGE GRAPH ===");
    
    var node_count = 1000;
    
    // Create dense weighted graph
    var g = new Graph(GraphFlags.GRAPH_WEIGHTED | GraphFlags.GRAPH_DIRECTED);
    for (var i = 0; i < node_count; i++)
    {
        for (var j = 0; j < node_count; j++)
        {
            if (i != j && random(1) > 0.7) // 30% edge probability
                g.AddEdge(i, j, random_range(1, 20));
        }
    }
    
    var timer = new BenchmarkTimer();
    timer.Start();
    
    var result = g.Dijkstra(0);
    
    var elapsed = timer.Stop();
    runner.AddResult($"Stress Test: Dijkstra on Dense Graph ({node_count} nodes)", elapsed, 1);
}

#endregion

/// @description Main benchmark runner - executes all benchmarks
function RunAllBenchmarks()
{
    var runner = new BenchmarkRunner();
    
    show_debug_message("\n" + string_repeat("#", 80));
    show_debug_message("# GRAPH LIBRARY - COMPREHENSIVE BENCHMARK SUITE");
    show_debug_message("# " + string_repeat("-", 76));
    show_debug_message("# Testing performance across all graph operations");
    show_debug_message(string_repeat("#", 80));
    
    // Run all benchmark categories
    BenchmarkConstruction(runner);
    BenchmarkNodeOperations(runner);
    BenchmarkEdgeOperations(runner);
    BenchmarkDegreeCalculations(runner);
    BenchmarkBFS(runner);
    BenchmarkDijkstra(runner);
    BenchmarkComponents(runner);
    BenchmarkCopyClone(runner);
    BenchmarkGraphTypes(runner);
    BenchmarkComplexGraphs(runner);
    BenchmarkMemoryOperations(runner);
    BenchmarkStressTestLarge(runner);
    BenchmarkStressTestBFS(runner);
    BenchmarkStressTestDijkstra(runner);
    
    // Print final summary
    runner.PrintSummary();
    
    // Print fastest and slowest operations
    var fastest = runner.GetFastestResult();
    var slowest = runner.GetSlowestResult();
    
    if (fastest != undefined && slowest != undefined)
    {
        show_debug_message("PERFORMANCE HIGHLIGHTS:");
        show_debug_message($"⚡ Fastest: {fastest.name} ({fastest.time_ms}ms)");
        show_debug_message($"🐌 Slowest: {slowest.name} ({slowest.time_ms}ms)");
    }
    
    show_debug_message("\nBenchmark suite completed!");
    
    return runner;
}

RunAllTests();
RunAllBenchmarks();
