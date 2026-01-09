/// @description Enhanced complete unit test suite for Graph library
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
	
	static AssertArrayContains = function(arr, value, test_name)
	{
		var contains = false;
		for (var i = 0; i < array_length(arr); i++)
		{
			if (arr[i] == value)
			{
				contains = true;
				break;
			}
		}
		Assert(contains, test_name);
	}
	
	/// @description Assert graph internal consistency
	static AssertGraphConsistency = function(g, test_name)
	{
		var nodes = g.GetNodes();
		var edges = g.GetEdges();

		// Node count consistency
		AssertEquals(
			array_length(nodes),
			g.GetNodeCount(),
			test_name + " - node count consistency"
		);

		// Edge count consistency
		AssertEquals(
			array_length(edges),
			g.GetEdgeCount(),
			test_name + " - edge count consistency"
		);

		// Undirected symmetry
		if (!g.IsDirected())
		{
			for (var i = 0; i < array_length(edges); i++)
			{
				var e = edges[i];
				Assert(
					g.HasEdge(e.to, e.from),
					test_name + " - undirected symmetry (" + string(e.from) + "," + string(e.to) + ")"
				);
			}
		}
		
		// All edges reference existing nodes
		for (var i = 0; i < array_length(edges); i++)
		{
			var e = edges[i];
			Assert(g.HasNode(e.from), test_name + " - edge from node exists");
			Assert(g.HasNode(e.to), test_name + " - edge to node exists");
		}
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

/// @description Test empty graphs and extreme minimal cases
function TestEmptyAndMinimalGraphs(runner)
{
	show_debug_message("\n=== Testing Empty & Minimal Graphs ===");

	// Empty undirected graph
	var g1 = new Graph(GraphFlags.GRAPH_NONE);
	runner.AssertEquals(0, g1.GetNodeCount(), "Empty graph node count");
	runner.AssertEquals(0, g1.GetEdgeCount(), "Empty graph edge count");
	runner.Assert(g1.GetNodes() != undefined, "Empty graph GetNodes valid");
	runner.Assert(!g1.IsConnected(), "Empty graph not connected");
	runner.AssertEquals(0, g1.GetComponentsCount(), "Empty graph has 0 components");
	runner.Assert(!g1.HasNode("X"), "Empty graph has no nodes");
	runner.Assert(!g1.HasEdge("X", "Y"), "Empty graph has no edges");

	// Empty directed graph
	var g2 = new Graph(GraphFlags.GRAPH_DIRECTED);
	runner.AssertEquals(0, g2.GetNodeCount(), "Empty directed graph");
	runner.Assert(g2.IsDirected(), "Empty directed graph flag");

	// Single node
	var g3 = new Graph(GraphFlags.GRAPH_NONE);
	g3.AddNode("A");
	runner.AssertEquals(1, g3.GetNodeCount(), "Single node graph");
	runner.AssertEquals(0, g3.GetEdgeCount(), "Single node no edges");
	runner.Assert(g3.IsConnected(), "Single node graph is connected");
	runner.AssertEquals(1, g3.GetComponentsCount(), "Single node is one component");
	runner.AssertEquals(0, g3.GetDegree("A"), "Single node has degree 0");
	
	// Single node BFS
	var bfs = g3.BFS("A");
	runner.AssertArrayEquals(["A"], bfs.path, "BFS on single node");
	
	// Single self-loop
	var g4 = new Graph(GraphFlags.GRAPH_ALLOW_SELF_LOOP);
	g4.AddEdge("A", "A");
	runner.AssertEquals(1, g4.GetNodeCount(), "Self-loop creates one node");
	runner.AssertEquals(1, g4.GetEdgeCount(), "Self-loop is one edge");
	runner.Assert(g4.HasEdge("A", "A"), "Self-loop exists");
	
	// Two isolated nodes
	var g5 = new Graph(GraphFlags.GRAPH_NONE);
	g5.AddNodes("A", "B");
	runner.Assert(!g5.IsConnected(), "Two isolated nodes not connected");
	runner.AssertEquals(2, g5.GetComponentsCount(), "Two isolated nodes = 2 components");
	runner.Assert(!g5.HasPath("A", "B"), "No path between isolated nodes");

	runner.AssertGraphConsistency(g1, "Empty graph");
	runner.AssertGraphConsistency(g3, "Single node graph");
	runner.AssertGraphConsistency(g4, "Self-loop graph");
	runner.AssertGraphConsistency(g5, "Isolated nodes graph");
}

/// @description Test DFS traversal functionality
function TestDFS(runner)
{
	show_debug_message("\n=== Testing DFS Traversal ===");
	
	// Basic DFS on simple path graph
	var g1 = new Graph(GraphFlags.GRAPH_NONE);
	g1.AddEdges(["A", "B"], ["B", "C"], ["C", "D"]);
	var dfs1 = g1.DFS("A");
	runner.AssertArrayEquals(["A", "B", "C", "D"], dfs1.path, "DFS simple path");
	runner.Assert(dfs1.visited[$ "D"], "DFS marks all nodes visited");
	runner.AssertEquals("C", dfs1.previous[$ "D"], "DFS tracks previous correctly");
	
	// DFS with target
	var dfs2 = g1.DFS("A", "C");
	runner.Assert(array_length(dfs2.path) <= 4, "DFS stops at target");
	runner.AssertEquals("C", array_last(dfs2.path), "DFS target is last element");
	
	// DFS on branching graph
	var g2 = new Graph(GraphFlags.GRAPH_NONE);
	g2.AddEdges(["A", "B"], ["A", "C"], ["B", "D"], ["C", "E"]);
	var dfs3 = g2.DFS("A");
	runner.AssertEquals(5, array_length(dfs3.path), "DFS visits all nodes in tree");
	runner.AssertEquals("A", dfs3.path[0], "DFS starts at source");
	
	// DFS visit order should be depth-first (visit one branch fully before backtracking)
	runner.Assert(dfs3.visited[$ "B"], "DFS visits all reachable nodes");
	runner.Assert(dfs3.visited[$ "D"], "DFS visits deep nodes");
	
	// DFS on directed graph
	var g3 = new Graph(GraphFlags.GRAPH_DIRECTED);
	g3.AddEdges(["A", "B"], ["B", "C"], ["A", "D"]);
	var dfs4 = g3.DFS("A");
	runner.AssertEquals(4, array_length(dfs4.path), "DFS on directed graph");
	runner.Assert(!g3.HasPath("C", "A"), "Directed graph no reverse path");
	
	// DFS with callback
	var callback_state = {count: 0};
	var callback = method(callback_state, function(node, prev) {
		self.count++;
	});
	g1.DFS("A", undefined, callback);
	runner.AssertEquals(4, callback_state.count, "DFS callback called for each node");
	
	// DFS on disconnected graph
	var g4 = new Graph(GraphFlags.GRAPH_NONE);
	g4.AddEdges(["A", "B"], ["C", "D"]);
	var dfs5 = g4.DFS("A");
	runner.AssertEquals(2, array_length(dfs5.path), "DFS only visits connected component");
	runner.Assert(!dfs5.visited[$ "C"], "DFS doesn't visit disconnected nodes");
	
	// DFS on graph with cycle (undirected)
	var g5 = new Graph(GraphFlags.GRAPH_NONE);
	g5.AddEdges(["A", "B"], ["B", "C"], ["C", "A"]);
	var dfs6 = g5.DFS("A");
	runner.AssertEquals(3, array_length(dfs6.path), "DFS visits all nodes in cycle");
	runner.Assert(dfs6.visited[$ "A"] && dfs6.visited[$ "B"] && dfs6.visited[$ "C"], "DFS marks cycle nodes visited");
	
	// DFS on single node
	var g6 = new Graph(GraphFlags.GRAPH_NONE);
	g6.AddNode("A");
	var dfs7 = g6.DFS("A");
	runner.AssertArrayEquals(["A"], dfs7.path, "DFS on single node");
	
	// DFS with self-loop
	var g7 = new Graph(GraphFlags.GRAPH_ALLOW_SELF_LOOP);
	g7.AddEdges(["A", "A"], ["A", "B"]);
	var dfs8 = g7.DFS("A");
	runner.AssertEquals(2, array_length(dfs8.path), "DFS handles self-loop");
	
	runner.AssertGraphConsistency(g1, "DFS graph 1");
	runner.AssertGraphConsistency(g2, "DFS graph 2");
	runner.AssertGraphConsistency(g3, "DFS graph 3");
}

/// @description Test cycle detection on undirected graphs
function TestCycleDetectionUndirected(runner)
{
	show_debug_message("\n=== Testing Cycle Detection (Undirected) ===");
	
	// Acyclic path
	var g1 = new Graph(GraphFlags.GRAPH_NONE);
	g1.AddEdges(["A", "B"], ["B", "C"], ["C", "D"]);
	runner.Assert(!g1.HasCycle(), "Simple path has no cycle");
	runner.Assert(g1.IsAcyclic(), "Simple path is acyclic");
	runner.Assert(!g1.IsCyclic(), "Simple path not cyclic");
	runner.AssertEquals(undefined, g1.GetCycle(), "No cycle returns undefined");
	
	// Simple triangle cycle
	var g2 = new Graph(GraphFlags.GRAPH_NONE);
	g2.AddEdges(["A", "B"], ["B", "C"], ["C", "A"]);
	runner.Assert(g2.HasCycle(), "Triangle has cycle");
	runner.Assert(g2.IsCyclic(), "Triangle is cyclic");
	runner.Assert(!g2.IsAcyclic(), "Triangle not acyclic");
	var cycle2 = g2.GetCycle();
	runner.Assert(is_array(cycle2), "GetCycle returns array for cycle");
	runner.Assert(array_length(cycle2) >= 3, "Triangle cycle has at least 3 nodes");
	runner.AssertEquals(cycle2[0], array_last(cycle2), "Cycle starts and ends at same node");
	
	// Square cycle
	var g3 = new Graph(GraphFlags.GRAPH_NONE);
	g3.AddEdges(["A", "B"], ["B", "C"], ["C", "D"], ["D", "A"]);
	runner.Assert(g3.HasCycle(), "Square has cycle");
	var cycle3 = g3.GetCycle();
	runner.Assert(array_length(cycle3) >= 4, "Square cycle has at least 4 nodes");
	
	// Tree structure (no cycles)
	var g4 = new Graph(GraphFlags.GRAPH_NONE);
	g4.AddEdges(["A", "B"], ["A", "C"], ["B", "D"], ["B", "E"], ["C", "F"]);
	runner.Assert(!g4.HasCycle(), "Tree has no cycle");
	runner.Assert(g4.IsAcyclic(), "Tree is acyclic");
	runner.AssertEquals(undefined, g4.GetCycle(), "Tree returns no cycle");
	
	// Graph with cycle and extra branches
	var g5 = new Graph(GraphFlags.GRAPH_NONE);
	g5.AddEdges(["A", "B"], ["B", "C"], ["C", "A"], ["A", "D"], ["D", "E"]);
	runner.Assert(g5.HasCycle(), "Complex graph detects cycle");
	var cycle5 = g5.GetCycle();
	runner.Assert(is_array(cycle5), "Complex graph returns cycle");
	
	// Multiple disjoint cycles
	var g6 = new Graph(GraphFlags.GRAPH_NONE);
	g6.AddEdges(["A", "B"], ["B", "C"], ["C", "A"], ["D", "E"], ["E", "F"], ["F", "D"]);
	runner.Assert(g6.HasCycle(), "Multiple cycles detected");
	
	// Self-loop is a cycle
	var g7 = new Graph(GraphFlags.GRAPH_ALLOW_SELF_LOOP);
	g7.AddEdge("A", "A");
	runner.Assert(g7.HasCycle(), "Self-loop is a cycle");
	var cycle7 = g7.GetCycle();
	runner.Assert(is_array(cycle7), "Self-loop returns cycle");
	
	// Empty graph has no cycle
	var g8 = new Graph(GraphFlags.GRAPH_NONE);
	runner.Assert(!g8.HasCycle(), "Empty graph has no cycle");
	
	// Single node has no cycle
	var g9 = new Graph(GraphFlags.GRAPH_NONE);
	g9.AddNode("A");
	runner.Assert(!g9.HasCycle(), "Single node has no cycle");
	
	runner.AssertGraphConsistency(g1, "Acyclic path");
	runner.AssertGraphConsistency(g2, "Triangle cycle");
	runner.AssertGraphConsistency(g4, "Tree structure");
}

/// @description Test cycle detection on directed graphs
function TestCycleDetectionDirected(runner)
{
	show_debug_message("\n=== Testing Cycle Detection (Directed) ===");
	
	// Simple directed acyclic path
	var g1 = new Graph(GraphFlags.GRAPH_DIRECTED);
	g1.AddEdges(["A", "B"], ["B", "C"], ["C", "D"]);
	runner.Assert(!g1.HasCycle(), "Directed path has no cycle");
	runner.Assert(g1.IsAcyclic(), "Directed path is acyclic");
	runner.Assert(g1.IsDAG(), "Directed acyclic path is DAG");
	
	// Simple directed cycle
	var g2 = new Graph(GraphFlags.GRAPH_DIRECTED);
	g2.AddEdges(["A", "B"], ["B", "C"], ["C", "A"]);
	runner.Assert(g2.HasCycle(), "Directed triangle has cycle");
	runner.Assert(!g2.IsDAG(), "Directed cycle is not DAG");
	var cycle2 = g2.GetCycle();
	runner.Assert(is_array(cycle2), "Directed cycle returns array");
	runner.AssertEquals(cycle2[0], array_last(cycle2), "Directed cycle closes");
	
	// Directed graph with back edge
	var g3 = new Graph(GraphFlags.GRAPH_DIRECTED);
	g3.AddEdges(["A", "B"], ["B", "C"], ["C", "D"], ["D", "B"]);
	runner.Assert(g3.HasCycle(), "Back edge creates cycle");
	var cycle3 = g3.GetCycle();
	runner.Assert(array_length(cycle3) >= 3, "Back edge cycle valid length");
	
	// DAG (topologically ordered)
	var g4 = new Graph(GraphFlags.GRAPH_DIRECTED);
	g4.AddEdges(["A", "B"], ["A", "C"], ["B", "D"], ["C", "D"]);
	runner.Assert(!g4.HasCycle(), "DAG has no cycle");
	runner.Assert(g4.IsDAG(), "Proper DAG detected");
	runner.AssertEquals(undefined, g4.GetCycle(), "DAG returns no cycle");
	
	// Directed self-loop
	var g5 = new Graph(GraphFlags.GRAPH_DIRECTED | GraphFlags.GRAPH_ALLOW_SELF_LOOP);
	g5.AddEdge("A", "A");
	runner.Assert(g5.HasCycle(), "Directed self-loop is cycle");
	runner.Assert(!g5.IsDAG(), "Self-loop not a DAG");
	
	// Complex DAG (diamond structure)
	var g6 = new Graph(GraphFlags.GRAPH_DIRECTED);
	g6.AddEdges(["A", "B"], ["A", "C"], ["B", "D"], ["C", "D"], ["D", "E"]);
	runner.Assert(!g6.HasCycle(), "Diamond DAG has no cycle");
	runner.Assert(g6.IsDAG(), "Diamond structure is DAG");
	
	// Directed cycle with tail
	var g7 = new Graph(GraphFlags.GRAPH_DIRECTED);
	g7.AddEdges(["A", "B"], ["B", "C"], ["C", "B"], ["A", "D"]);
	runner.Assert(g7.HasCycle(), "Cycle with tail detected");
	
	// Multiple components, one with cycle
	var g8 = new Graph(GraphFlags.GRAPH_DIRECTED);
	g8.AddEdges(["A", "B"], ["B", "C"], ["D", "E"], ["E", "F"], ["F", "D"]);
	runner.Assert(g8.HasCycle(), "Cycle in one component detected");
	
	// Undirected would have cycle, directed does not
	var g9 = new Graph(GraphFlags.GRAPH_DIRECTED);
	g9.AddEdges(["A", "B"], ["B", "C"]);
	runner.Assert(!g9.HasCycle(), "Directed path no cycle");
	var g9_undirected = new Graph(GraphFlags.GRAPH_NONE);
	g9_undirected.AddEdges(["A", "B"], ["B", "C"], ["C", "A"]);
	runner.Assert(g9_undirected.HasCycle(), "Same edges undirected has cycle");
	
	// Large DAG
	var g10 = new Graph(GraphFlags.GRAPH_DIRECTED);
	for (var i = 0; i < 10; i++) {
		for (var j = i + 1; j < 10; j++) {
			g10.AddEdge(string(i), string(j));
		}
	}
	runner.Assert(!g10.HasCycle(), "Large complete DAG has no cycle");
	runner.Assert(g10.IsDAG(), "Large graph is DAG");
	
	runner.AssertGraphConsistency(g1, "Directed acyclic path");
	runner.AssertGraphConsistency(g2, "Directed cycle");
	runner.AssertGraphConsistency(g4, "DAG");
}

/// @description Test edge cases and error handling
function TestDFSAndCycleEdgeCases(runner)
{
	show_debug_message("\n=== Testing DFS & Cycle Edge Cases ===");
	
	// DFS on non-existent node
	var g1 = new Graph(GraphFlags.GRAPH_NONE);
	g1.AddNode("A");
	var error_caught = false;
	try {
		g1.DFS("Z");
	} catch (e) {
		error_caught = true;
	}
	runner.Assert(error_caught, "DFS throws error on non-existent source");
	
	// DFS with non-existent target
	error_caught = false;
	try {
		g1.DFS("A", "Z");
	} catch (e) {
		error_caught = true;
	}
	runner.Assert(error_caught, "DFS throws error on non-existent target");
	
	// HasCycle on empty graph
	var g2 = new Graph(GraphFlags.GRAPH_NONE);
	runner.Assert(!g2.HasCycle(), "Empty graph has no cycle");
	
	// GetCycle called multiple times
	var g3 = new Graph(GraphFlags.GRAPH_NONE);
	g3.AddEdges(["A", "B"], ["B", "C"], ["C", "A"]);
	var cycle1 = g3.GetCycle();
	var cycle2 = g3.GetCycle();
	runner.Assert(is_array(cycle1) && is_array(cycle2), "GetCycle consistent");
	
	// IsDAG on undirected graph
	var g4 = new Graph(GraphFlags.GRAPH_NONE);
	g4.AddEdges(["A", "B"], ["B", "C"]);
	runner.Assert(!g4.IsDAG(), "Undirected graph is not DAG");
	
	// Very long cycle
	var g5 = new Graph(GraphFlags.GRAPH_DIRECTED);
	for (var i = 0; i < 100; i++) {
		g5.AddEdge(string(i), string((i + 1) mod 100));
	}
	runner.Assert(g5.HasCycle(), "Long cycle detected");
	var cycle5 = g5.GetCycle();
	runner.Assert(array_length(cycle5) >= 10, "Long cycle returns valid length");
	
	// Cycle detection after modifications
	var g6 = new Graph(GraphFlags.GRAPH_NONE);
	g6.AddEdges(["A", "B"], ["B", "C"]);
	runner.Assert(!g6.HasCycle(), "Initially no cycle");
	g6.AddEdge("C", "A");
	runner.Assert(g6.HasCycle(), "Cycle after adding edge");
	g6.RemoveEdge("C", "A");
	runner.Assert(!g6.HasCycle(), "No cycle after removing edge");
	
	runner.AssertGraphConsistency(g3, "Cycle graph");
	runner.AssertGraphConsistency(g6, "Modified graph");
}

/// @description Test graph construction with builder patterns (IMPROVED)
function TestGraphConstruction(runner)
{
	show_debug_message("\n=== Testing Graph Construction ===");
	
	// Test all flag combinations
	var flags_tests = [
		[GraphFlags.GRAPH_NONE, false, false, false, false, "NONE"],
		[GraphFlags.GRAPH_DIRECTED, true, false, false, false, "DIRECTED"],
		[GraphFlags.GRAPH_WEIGHTED, false, true, false, false, "WEIGHTED"],
		[GraphFlags.GRAPH_ALLOW_SELF_LOOP, false, false, true, false, "SELF_LOOP"],
		[GraphFlags.GRAPH_DIRECTED | GraphFlags.GRAPH_WEIGHTED, true, true, false, false, "DIR+WEIGHT"],
		[GraphFlags.GRAPH_DIRECTED | GraphFlags.GRAPH_ALLOW_SELF_LOOP, true, false, true, false, "DIR+SELF"],
		[GraphFlags.GRAPH_WEIGHTED | GraphFlags.GRAPH_ALLOW_SELF_LOOP, false, true, true, false, "WEIGHT+SELF"],
		[GraphFlags.GRAPH_DIRECTED | GraphFlags.GRAPH_WEIGHTED | GraphFlags.GRAPH_ALLOW_SELF_LOOP, true, true, true, false, "ALL_FLAGS"]
	];
	
	for (var i = 0; i < array_length(flags_tests); i++)
	{
		var test = flags_tests[i];
		var g = new Graph(test[0]);
		runner.AssertEquals(test[1], g.IsDirected(), "Flag " + test[5] + " - directed");
		runner.AssertEquals(test[2], g.IsWeighted(), "Flag " + test[5] + " - weighted");
		runner.AssertEquals(test[4], g.IsImmutable(), "Flag " + test[5] + " - immutable");
	}
	
	// Self-loop behavior
	var g_loop = new Graph(GraphFlags.GRAPH_ALLOW_SELF_LOOP);
	g_loop.AddEdge("A", "A");
	runner.Assert(g_loop.HasEdge("A", "A"), "Self-loop allowed with flag");
	
	var g_no_loop = new Graph(GraphFlags.GRAPH_NONE);
	var error_caught = false;
	try {g_no_loop.AddEdge("A", "A");} catch (_) {error_caught = true;};
	runner.Assert(error_caught, "Self-loop throws error without flag");
	runner.Assert(!g_no_loop.HasEdge("A", "A"), "Self-loop rejected without flag");
	
	// CORRECTION: Immutable flag during construction
	var g_imm = new Graph(GraphFlags.GRAPH_IMMUTABLE, [new Edge("X", "Y")]);
	runner.AssertEquals(2, g_imm.GetNodeCount(), "Immutable allows builder during construction");
	runner.Assert(g_imm.IsImmutable(), "Graph is immutable after construction");
	g_imm.AddNode("Z");
	runner.AssertEquals(2, g_imm.GetNodeCount(), "Immutable rejects post-construction modifications");
	
	// Builder with edges array
	var g_builder1 = new Graph(GraphFlags.GRAPH_NONE, [
		new Edge("A", "B"),
		new Edge("B", "C"),
		new Edge("C", "D")
	]);
	runner.AssertEquals(4, g_builder1.GetNodeCount(), "Builder edges - node count");
	runner.AssertEquals(3, g_builder1.GetEdgeCount(), "Builder edges - edge count");
	runner.Assert(g_builder1.HasEdge("A", "B"), "Builder edges - edge exists");
	
	// Builder with struct
	var g_builder2 = new Graph(GraphFlags.GRAPH_NONE, {
		nodes: ["A", "B", "C"],
		edges: [new Edge("A", "B")]
	});
	runner.AssertEquals(3, g_builder2.GetNodeCount(), "Builder struct - node count");
	runner.AssertEquals(1, g_builder2.GetEdgeCount(), "Builder struct - edge count");
	
	// Builder with graph copy
	var g_source = new Graph(GraphFlags.GRAPH_NONE);
	g_source.AddEdge("X", "Y");
	g_source.AddEdge("Y", "Z");
	var g_builder3 = new Graph(GraphFlags.GRAPH_NONE, g_source);
	runner.AssertEquals(3, g_builder3.GetNodeCount(), "Builder with graph copy - nodes");
	runner.AssertEquals(2, g_builder3.GetEdgeCount(), "Builder with graph copy - edges");
	
	// Builder with mixed array (nodes and edges)
	var g_builder4 = new Graph(GraphFlags.GRAPH_NONE, [
		"A", "B", // standalone nodes
		new Edge("C", "D"),
		["E", "F"], // edge as array
		{from: "G", to: "H"} // edge as struct
	]);
	runner.AssertEquals(8, g_builder4.GetNodeCount(), "Builder mixed array - nodes");
	runner.AssertEquals(3, g_builder4.GetEdgeCount(), "Builder mixed array - edges");
}

/// @description Test node operations exhaustively
function TestNodeOperations(runner)
{
	show_debug_message("\n=== Testing Node Operations ===");
	
	var g = new Graph(GraphFlags.GRAPH_NONE);
	
	// Add single node
	g.AddNode("A");
	runner.AssertEquals(1, g.GetNodeCount(), "Add single node");
	runner.Assert(g.HasNode("A"), "Node exists");
	
	// Add duplicate node
	g.AddNode("A");
	runner.AssertEquals(1, g.GetNodeCount(), "Duplicate node rejected");
	
	// Add multiple nodes (varargs)
	g.AddNodes("B", "C", "D");
	runner.AssertEquals(4, g.GetNodeCount(), "Add multiple nodes varargs");
	
	// Add multiple nodes (array)
	g.AddNodes(["E", "F"]);
	runner.AssertEquals(6, g.GetNodeCount(), "Add multiple nodes array");
	
	// Add nodes with different types
	g.AddNode(123);
	g.AddNode(456.78);
	g.AddNode("String");
	runner.AssertEquals(9, g.GetNodeCount(), "Mixed type nodes");
	runner.Assert(g.HasNode(123), "Integer node exists");
	runner.Assert(g.HasNode(456.78), "Real node exists");
	
	// Remove single node
	g.RemoveNode("A");
	runner.AssertEquals(8, g.GetNodeCount(), "Remove single node");
	runner.Assert(!g.HasNode("A"), "Removed node doesn't exist");
	
	// Remove multiple nodes (varargs)
	g.RemoveNodes("B", "C");
	runner.AssertEquals(6, g.GetNodeCount(), "Remove multiple nodes varargs");
	
	// Remove multiple nodes (array)
	g.RemoveNodes(["D", "E"]);
	runner.AssertEquals(4, g.GetNodeCount(), "Remove multiple nodes array");
	
	// Remove non-existent node (should not crash)
	g.RemoveNode("NonExistent");
	runner.AssertEquals(4, g.GetNodeCount(), "Remove non-existent node");
	
	// GetNodes returns all nodes
	var nodes = g.GetNodes();
	runner.AssertEquals(4, array_length(nodes), "GetNodes returns all");
	
	// Clear all nodes
	g.Clear();
	runner.AssertEquals(0, g.GetNodeCount(), "Clear all nodes");
	runner.AssertEquals(0, g.GetEdgeCount(), "Clear removes edges too");
	
	runner.AssertGraphConsistency(g, "Node operations");
}

/// @description Test edge operations exhaustively
function TestEdgeOperations(runner)
{
	show_debug_message("\n=== Testing Edge Operations ===");
	
	// Simple undirected edge
	var g1 = new Graph(GraphFlags.GRAPH_NONE);
	g1.AddEdge("A", "B");
	runner.Assert(g1.HasEdge("A", "B"), "Undirected edge A->B");
	runner.Assert(g1.HasEdge("B", "A"), "Undirected edge B->A");
	runner.AssertEquals(1, g1.GetEdgeCount(), "Undirected edge count");
	runner.AssertEquals(2, g1.GetNodeCount(), "Edge creates nodes");
	
	// Directed edge
	var g2 = new Graph(GraphFlags.GRAPH_DIRECTED);
	g2.AddEdge("A", "B");
	runner.Assert(g2.HasEdge("A", "B"), "Directed edge A->B exists");
	runner.Assert(!g2.HasEdge("B", "A"), "Directed edge B->A doesn't exist");
	runner.AssertEquals(1, g2.GetEdgeCount(), "Directed edge count");
	
	// Weighted edges
	var g3 = new Graph(GraphFlags.GRAPH_WEIGHTED);
	g3.AddEdge("A", "B", 5.5);
	g3.AddEdge("B", "C", 10);
	g3.AddEdge("C", "D", -3);
	runner.AssertEquals(5.5, g3.GetWeight("A", "B"), "Positive weight");
	runner.AssertEquals(10, g3.GetWeight("B", "C"), "Integer weight");
	runner.AssertEquals(-3, g3.GetWeight("C", "D"), "Negative weight");
	
	// Default weight
	var g4 = new Graph(GraphFlags.GRAPH_NONE);
	g4.AddEdge("A", "B");
	runner.AssertEquals(1, g4.GetWeight("A", "B"), "Default weight is 1");
	
	// Multiple edges (varargs)
	var g5 = new Graph(GraphFlags.GRAPH_NONE);
	g5.AddEdges(new Edge("A", "B"), new Edge("B", "C"), new Edge("C", "D"));
	runner.AssertEquals(3, g5.GetEdgeCount(), "Multiple edges varargs");
	
	// Multiple edges (array)
	var g6 = new Graph(GraphFlags.GRAPH_NONE);
	g6.AddEdges([new Edge("A", "B"), new Edge("B", "C")]);
	runner.AssertEquals(2, g6.GetEdgeCount(), "Multiple edges array");
	
	// Edge from array notation
	var g7 = new Graph(GraphFlags.GRAPH_WEIGHTED);
	g7.AddEdge(["X", "Y", 15]);
	runner.Assert(g7.HasEdge("X", "Y"), "Edge from array");
	runner.AssertEquals(15, g7.GetWeight("X", "Y"), "Weight from array");
	
	// Edge from struct
	var g8 = new Graph(GraphFlags.GRAPH_WEIGHTED);
	g8.AddEdge({from: "M", to: "N", weight: 7});
	runner.Assert(g8.HasEdge("M", "N"), "Edge from struct");
	runner.AssertEquals(7, g8.GetWeight("M", "N"), "Weight from struct");
	
	// Duplicate edge
	var g9 = new Graph(GraphFlags.GRAPH_NONE);
	g9.AddEdge("A", "B");
	g9.AddEdge("A", "B");
	runner.AssertEquals(1, g9.GetEdgeCount(), "Duplicate edge rejected");
	
	// GetEdges returns all edges
	var g10 = new Graph(GraphFlags.GRAPH_NONE);
	g10.AddEdge("A", "B");
	g10.AddEdge("B", "C");
	var edges = g10.GetEdges();
	runner.AssertEquals(2, array_length(edges), "GetEdges count");
	
	// GetEdge retrieves specific edge
	var edge = g10.GetEdge("A", "B");
	runner.Assert(edge != undefined, "GetEdge returns edge");
	runner.AssertEquals("A", edge.from, "Edge from correct");
	runner.AssertEquals("B", edge.to, "Edge to correct");
	
	// GetEdge on non-existent edge
	try {no_edge = g10.GetEdge("X", "Y")} catch (_) {no_edge = undefined};
	runner.Assert(no_edge == undefined, "GetEdge returns undefined for non-existent");
	
	// SetWeight modifies weight
	var g11 = new Graph(GraphFlags.GRAPH_WEIGHTED);
	g11.AddEdge("A", "B", 5);
	g11.SetWeight("A", "B", 20);
	runner.AssertEquals(20, g11.GetWeight("A", "B"), "SetWeight modifies weight");
	
	// SetWeight on undirected graph affects both directions
	runner.AssertEquals(20, g11.GetWeight("B", "A"), "SetWeight undirected symmetry");
	
	runner.AssertGraphConsistency(g1, "Undirected edges");
	runner.AssertGraphConsistency(g2, "Directed edges");
	runner.AssertGraphConsistency(g3, "Weighted edges");
}

/// @description Test edge removal with proper cache invalidation (IMPROVED)
function TestEdgeRemoval(runner)
{
	show_debug_message("\n=== Testing Edge Removal ===");
	
	// Remove edge in undirected graph
	var g1 = new Graph(GraphFlags.GRAPH_NONE);
	g1.AddEdge("A", "B");
	g1.AddEdge("B", "C");
	
	// Verify cache before removal
	var edges_before = g1.GetEdges();
	runner.AssertEquals(2, array_length(edges_before), "Edges before removal");
	
	g1.RemoveEdge("A", "B");
	runner.Assert(!g1.HasEdge("A", "B"), "Undirected edge removed A->B");
	runner.Assert(!g1.HasEdge("B", "A"), "Undirected edge removed B->A");
	runner.AssertEquals(1, g1.GetEdgeCount(), "Edge count after removal");
	
	// Verify cache invalidation
	var edges_after = g1.GetEdges();
	runner.AssertEquals(1, array_length(edges_after), "GetEdges reflects removal");
	
	// Remove edge using different notations
	var g2 = new Graph(GraphFlags.GRAPH_NONE);
	g2.AddEdge("A", "B");
	g2.AddEdge("C", "D");
	g2.AddEdge("E", "F");
	
	g2.RemoveEdge(new Edge("A", "B")); // struct notation
	runner.Assert(!g2.HasEdge("A", "B"), "Remove with struct");
	
	g2.RemoveEdge(["C", "D"]); // array notation
	runner.Assert(!g2.HasEdge("C", "D"), "Remove with array");
	
	runner.AssertEquals(1, g2.GetEdgeCount(), "Count after varied removals");
	
	// Remove multiple edges at once
	var g3 = new Graph(GraphFlags.GRAPH_NONE);
	g3.AddEdges([new Edge("A", "B"), new Edge("B", "C"), new Edge("C", "D")]);
	g3.RemoveEdges([new Edge("A", "B"), new Edge("C", "D")]);
	runner.AssertEquals(1, g3.GetEdgeCount(), "RemoveEdges batch");
	
	// Structure dirty flag after removal
	var g4 = new Graph(GraphFlags.GRAPH_NONE);
	g4.AddEdge("A", "B");
	g4.AddEdge("B", "C");
	var comps_before = g4.GetComponentsCount();
	g4.RemoveEdge("A", "B");
	var comps_after = g4.GetComponentsCount();
	runner.Assert(comps_before != comps_after || comps_after == 2, "Component cache invalidated after edge removal");
}

// @description Test node removal with structure dirty flag (IMPROVED)
function TestNodeRemovalWithEdges(runner)
{
	show_debug_message("\n=== Testing Node Removal With Edges ===");
	
	// Remove node with edges in undirected graph
	var g1 = new Graph(GraphFlags.GRAPH_NONE);
	g1.AddEdge("A", "B");
	g1.AddEdge("A", "C");
	g1.AddEdge("B", "C");
	
	var neighbors_before = g1.GetNeighbors("B");
	runner.AssertEquals(2, array_length(neighbors_before), "B has 2 neighbors before removal");
	
	g1.RemoveNode("A");
	runner.AssertEquals(2, g1.GetNodeCount(), "Node removed");
	runner.AssertEquals(1, g1.GetEdgeCount(), "Node's edges removed");
	runner.Assert(g1.HasEdge("B", "C"), "Unrelated edge remains");
	
	// Verify neighbor lists updated
	var neighbors_after = g1.GetNeighbors("B");
	runner.AssertEquals(1, array_length(neighbors_after), "B now has 1 neighbor");
	
	// Remove node from directed graph - removes incoming AND outgoing
	var g2 = new Graph(GraphFlags.GRAPH_DIRECTED);
	g2.AddEdge("A", "B");
	g2.AddEdge("C", "A");
	g2.AddEdge("B", "C");
	g2.AddEdge("A", "D");
	
	runner.AssertEquals(4, g2.GetEdgeCount(), "4 edges before removal");
	g2.RemoveNode("A");
	runner.AssertEquals(3, g2.GetNodeCount(), "Node removed from directed");
	runner.AssertEquals(1, g2.GetEdgeCount(), "All edges to/from A removed");
	runner.Assert(g2.HasEdge("B", "C"), "Unrelated edge remains");
	runner.Assert(!g2.HasEdge("A", "B"), "Outgoing edge removed");
	runner.Assert(!g2.HasEdge("C", "A"), "Incoming edge removed");
	
	// Component recalculation after node removal
	var g3 = new Graph(GraphFlags.GRAPH_NONE);
	g3.AddEdge("A", "B");
	g3.AddEdge("B", "C");
	runner.AssertEquals(1, g3.GetComponentsCount(), "Connected before removal");
	g3.RemoveNode("B"); // Bridge node
	runner.AssertEquals(2, g3.GetComponentsCount(), "Disconnected after bridge removal");
}

/// @description Test degree calculations
function TestDegrees(runner)
{
	show_debug_message("\n=== Testing Degrees ===");
	
	// Undirected graph degrees
	var g1 = new Graph(GraphFlags.GRAPH_NONE);
	g1.AddEdge("A", "B");
	g1.AddEdge("A", "C");
	g1.AddEdge("A", "D");
	runner.AssertEquals(3, g1.GetDegree("A"), "Undirected degree");
	runner.AssertEquals(3, g1.GetOutDegree("A"), "Undirected out-degree equals degree");
	runner.AssertEquals(3, g1.GetInDegree("A"), "Undirected in-degree equals degree");
	runner.AssertEquals(1, g1.GetDegree("B"), "Undirected degree of neighbor");
	
	// Directed graph degrees
	var g2 = new Graph(GraphFlags.GRAPH_DIRECTED);
	g2.AddEdge("A", "B");
	g2.AddEdge("A", "C");
	g2.AddEdge("D", "A");
	g2.AddEdge("E", "A");
	runner.AssertEquals(2, g2.GetOutDegree("A"), "Directed out-degree");
	runner.AssertEquals(2, g2.GetInDegree("A"), "Directed in-degree");
	runner.AssertEquals(4, g2.GetDegree("A"), "Directed total degree");
	runner.AssertEquals(1, g2.GetInDegree("B"), "Leaf node in-degree");
	runner.AssertEquals(1, g2.GetOutDegree("D"), "Source node out-degree");
	
	// Isolated node degree
	var g3 = new Graph(GraphFlags.GRAPH_NONE);
	g3.AddNode("Isolated");
	runner.AssertEquals(0, g3.GetDegree("Isolated"), "Isolated node degree");

	// GetNeighborsCount
	runner.AssertEquals(3, g1.GetNeighborsCount("A"), "GetNeighborsCount undirected");
	runner.AssertEquals(2, g2.GetNeighborsCount("A"), "GetNeighborsCount directed out");
	
	// Self-loop degree
	var g5 = new Graph(GraphFlags.GRAPH_ALLOW_SELF_LOOP | GraphFlags.GRAPH_DIRECTED);
	g5.AddEdge("A", "A");
	g5.AddEdge("A", "B");
	runner.AssertEquals(2, g5.GetOutDegree("A"), "Self-loop out-degree");
	runner.AssertEquals(1, g5.GetInDegree("A"), "Self-loop in-degree");
}

/// @description Test neighbor operations
function TestNeighbors(runner)
{
	show_debug_message("\n=== Testing Neighbors ===");
	
	var g = new Graph(GraphFlags.GRAPH_NONE);
	g.AddEdge("A", "B");
	g.AddEdge("A", "C");
	g.AddEdge("A", "D");
	g.AddEdge("B", "C");
	
	// GetNeighbors
	var neighbors_a = g.GetNeighbors("A");
	runner.AssertEquals(3, array_length(neighbors_a), "GetNeighbors count");
	runner.AssertArrayContains(neighbors_a, "B", "Neighbor B exists");
	runner.AssertArrayContains(neighbors_a, "C", "Neighbor C exists");
	runner.AssertArrayContains(neighbors_a, "D", "Neighbor D exists");
	
	// GetNeighbors for node with one neighbor
	var neighbors_d = g.GetNeighbors("D");
	runner.AssertEquals(1, array_length(neighbors_d), "Single neighbor");
	runner.AssertArrayContains(neighbors_d, "A", "Correct neighbor");
	
	// GetNeighbors for isolated node
	g.AddNode("Isolated");
	var neighbors_iso = g.GetNeighbors("Isolated");
	runner.AssertEquals(0, array_length(neighbors_iso), "Isolated node has no neighbors");
	
	// GetNeighbors for non-existent node
	var _test = false;
	try {g.GetNeighbors("NonExistent");} catch (_) {_test = true};
	runner.AssertEquals(_test, true, "Non-existent node neighbors (Should throw)");
	
	// Directed graph neighbors (outgoing only)
	var g2 = new Graph(GraphFlags.GRAPH_DIRECTED);
	g2.AddEdge("A", "B");
	g2.AddEdge("C", "A");
	var neighbors_dir = g2.GetNeighbors("A");
	runner.AssertEquals(1, array_length(neighbors_dir), "Directed neighbors (out only)");
	runner.AssertArrayContains(neighbors_dir, "B", "Outgoing neighbor exists");
}

/// @description Test BFS algorithm thoroughly
function TestBFS(runner)
{
	show_debug_message("\n=== Testing BFS ===");
	
	var g = new Graph(GraphFlags.GRAPH_NONE);
	g.AddEdge("A", "B");
	g.AddEdge("A", "C");
	g.AddEdge("B", "D");
	g.AddEdge("C", "E");
	g.AddEdge("D", "F");
	
	// Basic BFS from root
	var result1 = g.BFS("A");
	runner.AssertEquals(6, array_length(result1.path), "BFS visits all reachable");
	runner.AssertEquals("A", result1.path[0], "BFS starts at source");
	
	// BFS with target
	var result2 = g.BFS("A", "F");
	runner.Assert(result2.path[array_length(result2.path) - 1] == "F", "BFS stops at target");
	runner.Assert(array_length(result2.path) <= 6, "BFS with target visits fewer nodes");

	// BFS on disconnected graph
	var g2 = new Graph(GraphFlags.GRAPH_NONE);
	g2.AddEdge("A", "B");
	g2.AddEdge("C", "D");
	var result5 = g2.BFS("A");
	runner.AssertEquals(2, array_length(result5.path), "BFS on disconnected visits component only");
	
	// BFS on single node
	var g3 = new Graph(GraphFlags.GRAPH_NONE);
	g3.AddNode("A");
	var result6 = g3.BFS("A");
	runner.AssertEquals(1, array_length(result6.path), "BFS on single node");
	
	// BFS on directed graph
	var g4 = new Graph(GraphFlags.GRAPH_DIRECTED);
	g4.AddEdge("A", "B");
	g4.AddEdge("B", "C");
	g4.AddEdge("C", "A");
	var result7 = g4.BFS("A");
	runner.AssertEquals(3, array_length(result7.path), "BFS on directed cycle");
	
	// BFS level order (breadth-first property)
	var g5 = new Graph(GraphFlags.GRAPH_NONE);
	g5.AddEdge("A", "B");
	g5.AddEdge("A", "C");
	g5.AddEdge("B", "D");
	g5.AddEdge("C", "E");
	var result8 = g5.BFS("A");
	// Level 0: A, Level 1: B,C, Level 2: D,E
	runner.AssertEquals("A", result8.path[0], "BFS level 0");
	runner.Assert(result8.path[1] == "B" || result8.path[1] == "C", "BFS level 1");
	runner.Assert(result8.path[2] == "B" || result8.path[2] == "C", "BFS level 1");
}

/// @description Test path finding
function TestPaths(runner)
{
	show_debug_message("\n=== Testing Path Finding ===");
	
	var g = new Graph(GraphFlags.GRAPH_NONE);
	g.AddEdge("A", "B");
	g.AddEdge("B", "C");
	g.AddEdge("C", "D");
	g.AddEdge("A", "D"); // Shorter path
	
	// HasPath - connected nodes
	runner.Assert(g.HasPath("A", "D"), "Path exists A to D");
	runner.Assert(g.HasPath("B", "D"), "Path exists B to D");
	runner.Assert(g.HasPath("A", "C"), "Path exists A to C");
	
	// HasPath - same node
	runner.Assert(g.HasPath("A", "A"), "Path exists to self");
	
	// HasPath - disconnected graph
	var g2 = new Graph(GraphFlags.GRAPH_NONE);
	g2.AddEdge("A", "B");
	g2.AddEdge("C", "D");
	runner.Assert(!g2.HasPath("A", "C"), "No path between components");
	
	// GetPath - simple path
	var path1 = g.GetPath("A", "C");
	runner.Assert(is_array(path1), "GetPath returns array");
	runner.AssertEquals("A", path1[0], "Path starts at source");
	runner.AssertEquals("C", path1[array_length(path1) - 1], "Path ends at target");
	
	// GetPath - shortest unweighted path
	var path2 = g.GetPath("A", "D");
	runner.AssertEquals(2, array_length(path2), "Shortest path length");
	runner.AssertArrayEquals(["A", "D"], path2, "Direct path chosen");
	
	// GetPath - no path exists
	var path3 = g2.GetPath("A", "C");
	runner.Assert(path3 == undefined, "GetPath returns undefined when no path");

	// GetPath - same node
	var path4 = g.GetPath("A", "A");
	runner.AssertEquals(1, array_length(path4), "Path to self");
	runner.AssertArrayEquals(["A"], path4, "Path to self is just node");
	
	// GetPath - directed graph
	var g3 = new Graph(GraphFlags.GRAPH_DIRECTED);
	g3.AddEdge("A", "B");
	g3.AddEdge("B", "C");
	var path5 = g3.GetPath("A", "C");
	runner.AssertArrayEquals(["A", "B", "C"], path5, "Directed path");
	var path6 = g3.GetPath("C", "A");
	runner.Assert(path6 == undefined, "No reverse path in directed graph");
}

/// @description Test shortest distance
function TestShortestDistance(runner)
{
	show_debug_message("\n=== Testing Shortest Distance ===");
	
	// Unweighted graph
	var g1 = new Graph(GraphFlags.GRAPH_NONE);
	g1.AddEdge("A", "B");
	g1.AddEdge("B", "C");
	g1.AddEdge("B", "E");
	g1.AddEdge("A", "C"); // Direct edge
	
	runner.AssertEquals(1, g1.GetShortestDistance("A", "C"), "Shortest unweighted distance");
	runner.AssertEquals(2, g1.GetShortestDistance("A", "E"), "Longer path distance");
	runner.AssertEquals(0, g1.GetShortestDistance("A", "A"), "Distance to self is 0");
	
	// No path
	var g2 = new Graph(GraphFlags.GRAPH_NONE);
	g2.AddNode("A");
	g2.AddNode("B");
	runner.AssertEquals(infinity, g2.GetShortestDistance("A", "B"), "No path returns inf");
	
	// Weighted graph (uses Dijkstra)
	var g3 = new Graph(GraphFlags.GRAPH_WEIGHTED);
	g3.AddEdge("A", "B", 10);
	g3.AddEdge("A", "C", 3);
	g3.AddEdge("C", "B", 2);
	
	runner.AssertEquals(5, g3.GetShortestDistance("A", "B"), "Weighted shortest distance");
	
}

/// @description Test Dijkstra with edge cases (IMPROVED)
function TestDijkstra(runner)
{
	show_debug_message("\n=== Testing Dijkstra ===");
	
	var g = new Graph(GraphFlags.GRAPH_WEIGHTED | GraphFlags.GRAPH_DIRECTED);
	g.AddEdge("A", "B", 4);
	g.AddEdge("A", "C", 2);
	g.AddEdge("B", "D", 3);
	g.AddEdge("C", "B", 1);
	g.AddEdge("C", "D", 5);
	g.AddEdge("D", "E", 2);
	
	// Basic Dijkstra
	var result1 = g.Dijkstra("A");
	runner.Assert(result1 != undefined, "Dijkstra returns result");
	runner.AssertEquals(0, result1.distances[$ "A"], "Distance to self is 0");
	runner.AssertEquals(3, result1.distances[$ "B"], "Shortest distance A to B");
	runner.AssertEquals(6, result1.distances[$ "D"], "Shortest distance A to D");
	runner.AssertEquals(8, result1.distances[$ "E"], "Shortest distance A to E");
	
	// Dijkstra with target
	var result2 = g.Dijkstra("A", "D");
	runner.AssertEquals(6, result2.distances[$ "D"], "Dijkstra with target");
	
	// GetShortestPath using Dijkstra
	var path1 = g.GetShortestPath("A", "D");
	runner.AssertArrayEquals(["A", "C", "B", "D"], path1, "Optimal weighted path");
	
	// Verify path actually has correct total weight
	var path_weight = 0;
	for (var i = 0; i < array_length(path1) - 1; i++)
		path_weight += g.GetWeight(path1[i], path1[i + 1]);
	runner.AssertEquals(6, path_weight, "Path weight matches distance");

	// Dijkstra with negative weights (should throw)
	var g2 = new Graph(GraphFlags.GRAPH_WEIGHTED | GraphFlags.GRAPH_DIRECTED);
	g2.AddEdge("A", "B", -5);
	var result4 = false;
	try {g2.Dijkstra("A");} catch(_) {result4 = true;};
	runner.Assert(result4, "Dijkstra throws on negative weights");
	
	// Dijkstra on unreachable node
	var g3 = new Graph(GraphFlags.GRAPH_WEIGHTED);
	g3.AddEdge("A", "B", 5);
	g3.AddNode("C");
	var result5 = g3.Dijkstra("A");
	runner.Assert(result5.distances[$ "C"] == undefined, "Unreachable node not in distances");
	
	// Zero-weight edges
	var g4 = new Graph(GraphFlags.GRAPH_WEIGHTED);
	g4.AddEdge("A", "B", 0);
	g4.AddEdge("B", "C", 5);
	var result6 = g4.Dijkstra("A");
	runner.AssertEquals(0, result6.distances[$ "B"], "Zero-weight edge");
	runner.AssertEquals(5, result6.distances[$ "C"], "Path through zero-weight");
}

/// @description Test connected components with directed graphs (CORRECTED)
function TestComponents(runner)
{
	show_debug_message("\n=== Testing Connected Components ===");
	
	// Note: GetComponents uses BFS which treats directed graphs as undirected
	// for connectivity (weak connectivity)
	
	// Fully connected undirected
	var g1 = new Graph(GraphFlags.GRAPH_NONE);
	g1.AddEdge("A", "B");
	g1.AddEdge("B", "C");
	g1.AddEdge("C", "D");
	runner.Assert(g1.IsConnected(), "Fully connected graph");
	runner.AssertEquals(1, g1.GetComponentsCount(), "One component");
	
	// Disconnected graph - 3 components
	var g2 = new Graph(GraphFlags.GRAPH_NONE);
	g2.AddEdge("A", "B");
	g2.AddEdge("C", "D");
	g2.AddEdge("E", "F");
	runner.Assert(!g2.IsConnected(), "Disconnected graph");
	runner.AssertEquals(3, g2.GetComponentsCount(), "Three components");
	
	// Directed graph - WEAK connectivity (undirected interpretation)
	var g3 = new Graph(GraphFlags.GRAPH_DIRECTED);
	g3.AddEdge("A", "B");
	g3.AddEdge("B", "C");
	runner.Assert(g3.IsConnected(), "Directed graph weakly connected");
	
	// Directed disconnected
	var g4 = new Graph(GraphFlags.GRAPH_DIRECTED);
	g4.AddEdge("A", "B");
	g4.AddEdge("C", "D");
	runner.Assert(!g4.IsConnected(), "Directed disconnected");
	runner.AssertEquals(2, g4.GetComponentsCount(), "Two weak components");

	// Component cache invalidation
	var g5 = new Graph(GraphFlags.GRAPH_NONE);
	g5.AddEdge("A", "B");
	g5.AddNode("C");
	runner.AssertEquals(2, g5.GetComponentsCount(), "2 components initially");
	g5.AddEdge("B", "C"); // Connect them
	runner.AssertEquals(1, g5.GetComponentsCount(), "1 component after connection");
}

/// @description Test copy and clone operations
function TestCopyClone(runner)
{
	show_debug_message("\n=== Testing Copy & Clone ===");
	
	var g1 = new Graph(GraphFlags.GRAPH_WEIGHTED | GraphFlags.GRAPH_DIRECTED);
	g1.AddEdge("A", "B", 5);
	g1.AddEdge("B", "C", 3);
	g1.AddEdge("C", "D", 7);
	
	// Clone basic
	var g2 = g1.Clone();
	runner.AssertEquals(g1.GetNodeCount(), g2.GetNodeCount(), "Clone same nodes");
	runner.AssertEquals(g1.GetEdgeCount(), g2.GetEdgeCount(), "Clone same edges");
	runner.AssertEquals(g1.GetWeight("A", "B"), g2.GetWeight("A", "B"), "Clone same weights");
	runner.AssertEquals(g1.IsDirected(), g2.IsDirected(), "Clone same flags - directed");
	runner.AssertEquals(g1.IsWeighted(), g2.IsWeighted(), "Clone same flags - weighted");
	
	// Clone is independent
	g2.AddEdge("D", "E");
	runner.Assert(g1.GetEdgeCount() != g2.GetEdgeCount(), "Clone is independent");
	runner.Assert(!g1.HasNode("E"), "Original unchanged");
	
	// Clone preserves structure
	g2.RemoveEdge("A", "B");
	runner.Assert(g1.HasEdge("A", "B"), "Original structure intact");
	
	// Clone with unfreeze
	var g3 = new Graph(GraphFlags.GRAPH_NONE, [new Edge("X", "Y")]);
	g3.Freeze();
	runner.Assert(g3.IsImmutable(), "Graph frozen");
	var g4 = g3.Clone(true);
	runner.Assert(!g4.IsImmutable(), "Clone unfrozen");
	g4.AddEdge("Y", "Z");
	runner.AssertEquals(2, g4.GetEdgeCount(), "Unfrozen clone modifiable");
	
	// Clone without unfreeze
	var g5 = g3.Clone(false);
	runner.Assert(g5.IsImmutable(), "Clone remains frozen");
	
	// Copy into existing graph
	var g6 = new Graph(GraphFlags.GRAPH_NONE);
	g6.AddEdge("M", "N");
	g6.Copy(g1);
	runner.AssertEquals(g1.GetNodeCount(), g6.GetNodeCount(), "Copy replaces content");
	runner.Assert(g6.HasEdge("A", "B"), "Copy has source edges");
	runner.Assert(!g6.HasEdge("M", "N"), "Copy clears old content");
	
	// Copy preserves weights
	runner.AssertEquals(5, g6.GetWeight("A", "B"), "Copy preserves weights");
	
	// Copy empty graph
	var g7 = new Graph(GraphFlags.GRAPH_NONE);
	var g8 = new Graph(GraphFlags.GRAPH_NONE);
	g8.AddEdge("A", "B");
	g8.Copy(g7);
	runner.AssertEquals(0, g8.GetNodeCount(), "Copy empty clears");
}

/// @description Test immutability and freeze
function TestImmutability(runner)
{
	show_debug_message("\n=== Testing Immutability ===");
	
	// Immutable from construction
	var g1 = new Graph(GraphFlags.GRAPH_IMMUTABLE);
	runner.Assert(g1.IsImmutable(), "Immutable flag set");
	
	g1.AddNode("A");
	runner.AssertEquals(0, g1.GetNodeCount(), "Cannot add nodes");
	
	g1.AddEdge("A", "B");
	runner.AssertEquals(0, g1.GetEdgeCount(), "Cannot add edges");
	
	// Freeze mutable graph
	var g2 = new Graph(GraphFlags.GRAPH_NONE);
	g2.AddEdge("A", "B");
	g2.AddEdge("B", "C");
	runner.Assert(!g2.IsImmutable(), "Initially mutable");
	
	g2.Freeze();
	runner.Assert(g2.IsImmutable(), "Frozen graph immutable");
	
	g2.AddEdge("C", "D");
	runner.AssertEquals(2, g2.GetEdgeCount(), "Cannot add after freeze");
	
	g2.RemoveNode("A");
	runner.AssertEquals(3, g2.GetNodeCount(), "Cannot remove after freeze");
	
	g2.RemoveEdge("A", "B");
	runner.AssertEquals(2, g2.GetEdgeCount(), "Cannot remove edges after freeze");
	
	g2.Clear();
	runner.Assert(g2.GetNodeCount() > 0, "Cannot clear after freeze");
	
	// SetWeight on frozen
	var g3 = new Graph(GraphFlags.GRAPH_WEIGHTED, [new Edge("A", "B", 5)]);
	g3.Freeze();
	g3.SetWeight("A", "B", 10);
	runner.AssertEquals(5, g3.GetWeight("A", "B"), "Cannot modify weight after freeze");
	
	// Freeze preserves read operations
	runner.Assert(g2.HasNode("A"), "Can read nodes after freeze");
	runner.Assert(g2.HasEdge("A", "B"), "Can read edges after freeze");
	var nodes = g2.GetNodes();
	runner.AssertEquals(3, array_length(nodes), "Can get nodes after freeze");
}

/// @description Test graph clear operation
function TestClear(runner)
{
	show_debug_message("\n=== Testing Clear ===");
	
	var g = new Graph(GraphFlags.GRAPH_NONE);
	g.AddEdge("A", "B");
	g.AddEdge("B", "C");
	g.AddEdge("C", "D");
	
	runner.AssertEquals(4, g.GetNodeCount(), "Graph has nodes before clear");
	runner.AssertEquals(3, g.GetEdgeCount(), "Graph has edges before clear");
	
	g.Clear();
	
	runner.AssertEquals(0, g.GetNodeCount(), "Clear removes all nodes");
	runner.AssertEquals(0, g.GetEdgeCount(), "Clear removes all edges");
	runner.Assert(!g.HasNode("A"), "No nodes after clear");
	runner.Assert(!g.HasEdge("A", "B"), "No edges after clear");
	
	// Can add after clear
	g.AddEdge("X", "Y");
	runner.AssertEquals(2, g.GetNodeCount(), "Can add after clear");
	
	// Clear empty graph
	var g2 = new Graph(GraphFlags.GRAPH_NONE);
	g2.Clear();
	runner.AssertEquals(0, g2.GetNodeCount(), "Clear empty graph");
}

/// @description Test complex graph structures
function TestComplexStructures(runner)
{
	show_debug_message("\n=== Testing Complex Structures ===");
	
	// Complete graph K5
	var g1 = new Graph(GraphFlags.GRAPH_NONE);
	var nodes = ["A", "B", "C", "D", "E"];
	for (var i = 0; i < array_length(nodes); i++)
	{
		for (var j = i + 1; j < array_length(nodes); j++)
		{
			g1.AddEdge(nodes[i], nodes[j]);
		}
	}
	runner.AssertEquals(5, g1.GetNodeCount(), "K5 node count");
	runner.AssertEquals(10, g1.GetEdgeCount(), "K5 edge count");
	runner.Assert(g1.IsConnected(), "K5 is connected");
	runner.AssertEquals(4, g1.GetDegree("A"), "K5 vertex degree");

	// Cycle graph
	var g2 = new Graph(GraphFlags.GRAPH_NONE);
	g2.AddEdge("A", "B");
	g2.AddEdge("B", "C");
	g2.AddEdge("C", "D");
	g2.AddEdge("D", "A");
	runner.Assert(g2.IsConnected(), "Cycle is connected");
	runner.AssertEquals(2, g2.GetDegree("A"), "Cycle vertex degree");
	
	// Binary tree
	var g3 = new Graph(GraphFlags.GRAPH_DIRECTED);
	g3.AddEdge("A", "B");
	g3.AddEdge("A", "C");
	g3.AddEdge("B", "D");
	g3.AddEdge("B", "E");
	g3.AddEdge("C", "F");
	g3.AddEdge("C", "G");
	runner.AssertEquals(7, g3.GetNodeCount(), "Binary tree nodes");
	runner.AssertEquals(2, g3.GetOutDegree("A"), "Root out-degree");
	runner.AssertEquals(0, g3.GetOutDegree("D"), "Leaf out-degree");
	
	// Star graph
	var g4 = new Graph(GraphFlags.GRAPH_NONE);
	g4.AddEdge("Center", "A");
	g4.AddEdge("Center", "B");
	g4.AddEdge("Center", "C");
	g4.AddEdge("Center", "D");
	runner.AssertEquals(4, g4.GetDegree("Center"), "Star center degree");
	runner.AssertEquals(1, g4.GetDegree("A"), "Star leaf degree");
	
	// Bipartite graph
	var g5 = new Graph(GraphFlags.GRAPH_NONE);
	g5.AddEdge("A1", "B1");
	g5.AddEdge("A1", "B2");
	g5.AddEdge("A2", "B1");
	g5.AddEdge("A2", "B2");
	runner.AssertEquals(4, g5.GetNodeCount(), "Bipartite nodes");
	runner.Assert(g5.IsConnected(), "Bipartite connected");
	
	runner.AssertGraphConsistency(g1, "Complete graph");
	runner.AssertGraphConsistency(g2, "Cycle graph");
	runner.AssertGraphConsistency(g3, "Binary tree");
	runner.AssertGraphConsistency(g4, "Star graph");
	runner.AssertGraphConsistency(g5, "Bipartite graph");
}

/// @description Test edge cases and boundary conditions
function TestEdgeCases(runner)
{
	show_debug_message("\n=== Testing Edge Cases ===");
	
	// Very large node values
	var g1 = new Graph(GraphFlags.GRAPH_NONE);
	g1.AddNode(999999);
	g1.AddNode(-999999);
	runner.Assert(g1.HasNode(999999), "Large positive number node");
	runner.Assert(g1.HasNode(-999999), "Large negative number node");

	// Special characters in node names
	var g3 = new Graph(GraphFlags.GRAPH_NONE);
	g3.AddNode("node with spaces");
	g3.AddNode("node_with_underscore");
	g3.AddNode("node-with-dash");
	runner.Assert(g3.HasNode("node with spaces"), "Node with spaces");
	runner.Assert(g3.HasNode("node_with_underscore"), "Node with underscore");
	
	// Very high weight
	var g4 = new Graph(GraphFlags.GRAPH_WEIGHTED);
	g4.AddEdge("A", "B", 999999.99);
	runner.AssertEquals(999999.99, g4.GetWeight("A", "B"), "Very high weight");
	
	// Zero weight
	var g5 = new Graph(GraphFlags.GRAPH_WEIGHTED);
	g5.AddEdge("A", "B", 0);
	runner.AssertEquals(0, g5.GetWeight("A", "B"), "Zero weight");
	
	// Fractional weight
	var g6 = new Graph(GraphFlags.GRAPH_WEIGHTED);
	g6.AddEdge("A", "B", 0.001);
	runner.AssertEquals(0.001, g6.GetWeight("A", "B"), "Fractional weight");
	
	// Same node name as number and string
	var g7 = new Graph(GraphFlags.GRAPH_NONE);
	g7.AddNode(123);
	g7.AddNode("123");
	runner.AssertEquals(1, g7.GetNodeCount(), "Number and string treated the same");
	
	// Multiple self-loops (if allowed)
	var g8 = new Graph(GraphFlags.GRAPH_ALLOW_SELF_LOOP);
	g8.AddEdge("A", "A");
	g8.AddEdge("A", "A");
	runner.AssertEquals(1, g8.GetEdgeCount(), "Duplicate self-loop rejected");
	
	// Operations on completely empty structures
	var g9 = new Graph(GraphFlags.GRAPH_NONE);
	runner.AssertEquals(0, array_length(g9.GetNodes()), "GetNodes on empty");
	runner.AssertEquals(0, array_length(g9.GetEdges()), "GetEdges on empty");
}

/// @description Test mixed type nodes
function TestMixedTypes(runner)
{
	show_debug_message("\n=== Testing Mixed Type Nodes ===");
	
	var g = new Graph(GraphFlags.GRAPH_NONE);
	
	// Add different types
	g.AddNode("String");
	g.AddNode(42);
	g.AddNode(3.14);
	g.AddNode(true);
	g.AddNode(false);
	
	runner.AssertEquals(5, g.GetNodeCount(), "Mixed types count");
	runner.Assert(g.HasNode("String"), "String node");
	runner.Assert(g.HasNode(42), "Integer node");
	runner.Assert(g.HasNode(3.14), "Real node");
	runner.Assert(g.HasNode(true), "Boolean true node");
	runner.Assert(g.HasNode(false), "Boolean false node");
	
	// Edges between different types
	g.AddEdge("String", 42);
	g.AddEdge(42, 3.14);
	g.AddEdge(3.14, true);
	
	runner.Assert(g.HasEdge("String", 42), "Edge between string and int");
	runner.Assert(g.HasEdge(42, 3.14), "Edge between int and real");
	runner.Assert(g.HasEdge(3.14, true), "Edge between real and bool");
	
	// Path between different types
	runner.Assert(g.HasPath("String", true), "Path through mixed types");
	
	runner.AssertGraphConsistency(g, "Mixed types graph");
}

/// @description Test cache management (NEW)
function TestCacheManagement(runner)
{
	show_debug_message("\n=== Testing Cache Management ===");
	
	var g = new Graph(GraphFlags.GRAPH_NONE);
	
	// Node cache
	g.AddNode("A");
	var nodes1 = g.GetNodes();
	var nodes2 = g.GetNodes();
	runner.Assert(nodes1 != nodes2, "Node cache does not returns same reference");
	
	g.AddNode("B");
	var nodes3 = g.GetNodes();
	runner.Assert(nodes1 != nodes3, "Node cache invalidated on add");
	runner.AssertEquals(2, array_length(nodes3), "New cache has updated count");
	
	// Edge cache
	g.AddEdge("A", "B");
	var edges1 = g.GetEdges();
	var edges2 = g.GetEdges();
	runner.Assert(edges1 != edges2, "Edge cache does not returns same reference");
	
	g.AddEdge("B", "C");
	var edges3 = g.GetEdges();
	runner.Assert(edges1 != edges3, "Edge cache invalidated on add");
	
	g.RemoveEdge("A", "B");
	var edges4 = g.GetEdges();
	runner.Assert(edges3 != edges4, "Edge cache invalidated on remove");
	
	// Component cache
	var comps1 = g.GetComponents();
	var comps2 = g.GetComponents();
	runner.Assert(comps1 == comps2, "Component cache returns same reference");
	
	g.AddNode("D");
	var comps3 = g.GetComponents();
	runner.Assert(comps1 != comps3, "Component cache invalidated by structure change");
}

/// @description CORRECTED: Test edge count in undirected graphs
function TestEdgeCountUndirected(runner)
{
	show_debug_message("\n=== Testing Edge Count (Undirected) ===");
	
	var g = new Graph(GraphFlags.GRAPH_NONE);
	
	// In undirected graphs, edge count should reflect unique edges
	g.AddEdge("A", "B");
	runner.AssertEquals(1, g.GetEdgeCount(), "One undirected edge");
	
	// GetEdges should return only one edge object for A-B
	var edges = g.GetEdges();
	runner.AssertEquals(1, array_length(edges), "GetEdges returns 1 for undirected A-B");
	
	// But both directions exist
	runner.Assert(g.HasEdge("A", "B"), "A->B exists");
	runner.Assert(g.HasEdge("B", "A"), "B->A exists");
	
	// Adding multiple edges
	g.AddEdge("B", "C");
	g.AddEdge("C", "D");
	runner.AssertEquals(3, g.GetEdgeCount(), "Three undirected edges");
	runner.AssertEquals(3, array_length(g.GetEdges()), "GetEdges returns 3");
}


/// @description Test weight operations (NEW)
function TestWeightOperations(runner)
{
	show_debug_message("\n=== Testing Weight Operations ===");
	
	// SetWeight on weighted graph
	var g1 = new Graph(GraphFlags.GRAPH_WEIGHTED);
	g1.AddEdge("A", "B", 5);
	runner.AssertEquals(5, g1.GetWeight("A", "B"), "Initial weight");
	g1.SetWeight("A", "B", 10);
	runner.AssertEquals(10, g1.GetWeight("A", "B"), "Weight updated");
	
	// SetWeight maintains undirected symmetry
	runner.AssertEquals(10, g1.GetWeight("B", "A"), "Undirected weight symmetry after update");
	
	// SetWeight on directed graph
	var g2 = new Graph(GraphFlags.GRAPH_WEIGHTED | GraphFlags.GRAPH_DIRECTED);
	g2.AddEdge("A", "B", 5);
	g2.AddEdge("B", "A", 3);
	g2.SetWeight("A", "B", 10);
	runner.AssertEquals(10, g2.GetWeight("A", "B"), "Directed weight A->B updated");
	runner.AssertEquals(3, g2.GetWeight("B", "A"), "Directed weight B->A unchanged");
	
	// SetWeight error on non-weighted graph
	var g3 = new Graph(GraphFlags.GRAPH_NONE);
	g3.AddEdge("A", "B");
	var error_caught = false;
	try {g3.SetWeight("A", "B", 5);} catch (_) {error_caught = true;};
	runner.Assert(error_caught, "SetWeight throws on non-weighted graph");
	
	// SetWeight returns self for chaining
	var g4 = new Graph(GraphFlags.GRAPH_WEIGHTED);
	g4.AddEdge("A", "B", 1).SetWeight("A", "B", 5).AddEdge("B", "C", 3);
	runner.AssertEquals(5, g4.GetWeight("A", "B"), "SetWeight chainable");
	runner.AssertEquals(2, g4.GetEdgeCount(), "Chaining works");
	
	// GetWeight on non-existent edge
	error_caught = false;
	try {g1.GetWeight("X", "Y");} catch (_) {error_caught = true;};
	runner.Assert(error_caught, "GetWeight throws on non-existent edge");
}


#region Tests Unitaires Manquants

/// @description Test GetTopologicalSort sur DAG
function TestTopologicalSort(runner)
{
	show_debug_message("\n=== Testing Topological Sort ===");
	
	// Simple DAG
	var g1 = new Graph(GraphFlags.GRAPH_DIRECTED);
	g1.AddEdges(["A", "B"], ["A", "C"], ["B", "D"], ["C", "D"]);
	var topo1 = g1.GetTopologicalSort();
	runner.Assert(is_array(topo1), "Topological sort returns array");
	runner.AssertEquals(4, array_length(topo1), "All nodes in topological sort");
	runner.AssertEquals("A", topo1[0], "Root node first in topo sort");
	runner.AssertEquals("D", topo1[3], "Sink node last in topo sort");
	
	// Verify topological ordering
	var pos = {};
	for (var i = 0; i < array_length(topo1); i++)
		pos[$ topo1[i]] = i;
	runner.Assert(pos[$ "A"] < pos[$ "B"], "A before B in topo order");
	runner.Assert(pos[$ "A"] < pos[$ "C"], "A before C in topo order");
	runner.Assert(pos[$ "B"] < pos[$ "D"], "B before D in topo order");
	runner.Assert(pos[$ "C"] < pos[$ "D"], "C before D in topo order");
	
	// DAG with multiple valid orderings
	var g2 = new Graph(GraphFlags.GRAPH_DIRECTED);
	g2.AddEdges(["1", "2"], ["1", "3"], ["2", "4"], ["3", "4"]);
	var topo2 = g2.GetTopologicalSort();
	runner.AssertEquals(4, array_length(topo2), "Topo sort on diamond DAG");
	
	// Graph with cycle returns undefined
	var g3 = new Graph(GraphFlags.GRAPH_DIRECTED);
	g3.AddEdges(["A", "B"], ["B", "C"], ["C", "A"]);
	var topo3 = g3.GetTopologicalSort();
	runner.AssertEquals(undefined, topo3, "Cyclic graph returns undefined");
	
	// Undirected graph throws error
	var g4 = new Graph(GraphFlags.GRAPH_NONE);
	g4.AddEdge("A", "B");
	var error_caught = false;
	try { g4.GetTopologicalSort(); } catch (_) { error_caught = true; }
	runner.Assert(error_caught, "Undirected graph throws on topo sort");
	
	// Empty graph
	var g5 = new Graph(GraphFlags.GRAPH_DIRECTED);
	var topo5 = g5.GetTopologicalSort();
	runner.AssertArrayEquals([], topo5, "Empty graph topo sort");
	
	// Single node
	var g6 = new Graph(GraphFlags.GRAPH_DIRECTED);
	g6.AddNode("X");
	var topo6 = g6.GetTopologicalSort();
	runner.AssertArrayEquals(["X"], topo6, "Single node topo sort");
	
	// Complex DAG (provided example)
	var g8 = new Graph(GraphFlags.GRAPH_DIRECTED);
	g8.AddEdges([5, 11], [7, 11], [7, 8], [3, 8], [3, 10], [11, 2], [11, 9], [11, 10], [8, 9]);
	var topo8 = g8.GetTopologicalSort();
	runner.Assert(is_array(topo8), "Complex DAG has topo sort");
	runner.AssertEquals(7, array_length(topo8), "Complex DAG all nodes");
	
	runner.AssertGraphConsistency(g1, "Topo sort graph 1");
	runner.AssertGraphConsistency(g8, "Complex DAG");
}

/// @description Test IsTree functionality
function TestIsTree(runner)
{
	show_debug_message("\n=== Testing IsTree ===");
	
	// Undirected tree
	var g1 = new Graph(GraphFlags.GRAPH_NONE);
	g1.AddEdges(["A", "B"], ["A", "C"], ["B", "D"], ["B", "E"]);
	runner.Assert(g1.IsTree(), "Undirected tree detected");
	
	// Undirected graph with cycle is not tree
	var g2 = new Graph(GraphFlags.GRAPH_NONE);
	g2.AddEdges(["A", "B"], ["B", "C"], ["C", "A"]);
	runner.Assert(!g2.IsTree(), "Cycle prevents tree");
	
	// Disconnected graph is not tree
	var g3 = new Graph(GraphFlags.GRAPH_NONE);
	g3.AddEdges(["A", "B"], ["C", "D"]);
	runner.Assert(!g3.IsTree(), "Disconnected graph not tree");
	
	// Directed tree (DAG)
	var g4 = new Graph(GraphFlags.GRAPH_DIRECTED);
	g4.AddEdges(["A", "B"], ["A", "C"], ["B", "D"]);
	runner.Assert(g4.IsTree(), "Directed tree (DAG)");
	
	// Directed with cycle not tree
	var g5 = new Graph(GraphFlags.GRAPH_DIRECTED);
	g5.AddEdges(["A", "B"], ["B", "C"], ["C", "A"]);
	runner.Assert(!g5.IsTree(), "Directed cycle not tree");
	
	// Empty graph not tree
	var g6 = new Graph(GraphFlags.GRAPH_NONE);
	runner.Assert(!g6.IsTree(), "Empty graph not tree");
	
	// Single node is tree
	var g7 = new Graph(GraphFlags.GRAPH_NONE);
	g7.AddNode("A");
	runner.Assert(g7.IsTree(), "Single node is tree");
}

/// @description Test IsComplete functionality
function TestIsComplete(runner)
{
	show_debug_message("\n=== Testing IsComplete ===");
	
	// Complete undirected graph K3
	var g1 = new Graph(GraphFlags.GRAPH_NONE);
	g1.AddEdges(["A", "B"], ["B", "C"], ["C", "A"]);
	runner.Assert(g1.IsComplete(), "K3 is complete");
	
	// Complete undirected graph K4
	var g2 = new Graph(GraphFlags.GRAPH_NONE);
	g2.AddEdges(["A", "B"], ["A", "C"], ["A", "D"], ["B", "C"], ["B", "D"], ["C", "D"]);
	runner.Assert(g2.IsComplete(), "K4 is complete");
	
	// Incomplete graph
	var g3 = new Graph(GraphFlags.GRAPH_NONE);
	g3.AddEdges(["A", "B"], ["B", "C"]);
	runner.Assert(!g3.IsComplete(), "Missing edge not complete");
	
	// Empty graph
	var g4 = new Graph(GraphFlags.GRAPH_NONE);
	runner.Assert(!g4.IsComplete(), "Empty graph not complete");
	
	// Single node with self-loop
	var g5 = new Graph(GraphFlags.GRAPH_ALLOW_SELF_LOOP);
	g5.AddEdge("A", "A");
	runner.Assert(g5.IsComplete(), "Single node with self-loop complete");
	
	// Directed complete graph
	var g6 = new Graph(GraphFlags.GRAPH_DIRECTED);
	g6.AddEdges(["A", "B"], ["B", "A"], ["A", "C"], ["C", "A"], ["B", "C"], ["C", "B"]);
	runner.Assert(g6.IsComplete(), "Directed complete graph");
}

/// @description Test GetDensity functionality
function TestGetDensity(runner)
{
	show_debug_message("\n=== Testing GetDensity ===");
	
	// Complete graph has density 1
	var g1 = new Graph(GraphFlags.GRAPH_NONE);
	g1.AddEdges(["A", "B"], ["B", "C"], ["C", "A"]);
	runner.AssertEquals(1, g1.GetDensity(), "Complete K3 density = 1");
	
	// Empty graph
	var g2 = new Graph(GraphFlags.GRAPH_NONE);
	runner.AssertEquals(0, g2.GetDensity(), "Empty graph density = 0");
	
	// Single node
	var g3 = new Graph(GraphFlags.GRAPH_NONE);
	g3.AddNode("A");
	runner.AssertEquals(0, g3.GetDensity(), "Single node density = 0");
	
	// Sparse graph
	var g4 = new Graph(GraphFlags.GRAPH_NONE);
	g4.AddEdges(["A", "B"], ["B", "C"], ["C", "D"], ["D", "E"]);
	var density4 = g4.GetDensity();
	runner.Assert(density4 > 0 && density4 < 1, "Sparse graph 0 < density < 1");
	
	// Directed graph density
	var g5 = new Graph(GraphFlags.GRAPH_DIRECTED);
	g5.AddEdges(["A", "B"], ["B", "C"]);
	var density5 = g5.GetDensity();
	runner.Assert(density5 > 0 && density5 < 1, "Directed graph density");
}

/// @description Test GetReversed functionality
function TestGetReversed(runner)
{
	show_debug_message("\n=== Testing GetReversed ===");
	
	// Simple directed graph
	var g1 = new Graph(GraphFlags.GRAPH_DIRECTED);
	g1.AddEdges(["A", "B"], ["B", "C"], ["C", "D"]);
	var g1_rev = g1.GetReversed();
	runner.Assert(g1_rev.HasEdge("B", "A"), "Reversed edge B->A");
	runner.Assert(g1_rev.HasEdge("C", "B"), "Reversed edge C->B");
	runner.Assert(g1_rev.HasEdge("D", "C"), "Reversed edge D->C");
	runner.Assert(!g1_rev.HasEdge("A", "B"), "Original edge removed");
	
	// Original unchanged
	runner.Assert(g1.HasEdge("A", "B"), "Original graph unchanged");
	
	// Weighted directed graph
	var g2 = new Graph(GraphFlags.GRAPH_DIRECTED | GraphFlags.GRAPH_WEIGHTED);
	g2.AddEdge("X", "Y", 5);
	var g2_rev = g2.GetReversed();
	runner.AssertEquals(5, g2_rev.GetWeight("Y", "X"), "Reversed weight preserved");
	
	// Immutable reversed graph
	var g3 = new Graph(GraphFlags.GRAPH_DIRECTED, [new Edge("A", "B")]);
	g3.Freeze();
	var g3_rev = g3.GetReversed();
	runner.Assert(g3_rev.IsImmutable(), "Reversed graph is immutable");
	
	// Undirected throws error
	var g4 = new Graph(GraphFlags.GRAPH_NONE);
	g4.AddEdge("A", "B");
	var error_caught = false;
	try { g4.GetReversed(); } catch (_) { error_caught = true; }
	runner.Assert(error_caught, "Undirected graph throws on reverse");
	
	runner.AssertGraphConsistency(g1_rev, "Reversed graph");
	runner.AssertGraphConsistency(g2_rev, "Reversed weighted graph");
}

/// @description Test Reverse (in-place) functionality
function TestReverse(runner)
{
	show_debug_message("\n=== Testing Reverse (in-place) ===");
	
	// Simple directed graph
	var g1 = new Graph(GraphFlags.GRAPH_DIRECTED);
	g1.AddEdges(["A", "B"], ["B", "C"]);
	g1.Reverse();
	runner.Assert(g1.HasEdge("B", "A"), "In-place reversed B->A");
	runner.Assert(g1.HasEdge("C", "B"), "In-place reversed C->B");
	runner.Assert(!g1.HasEdge("A", "B"), "Original edges removed");
	
	// Immutable graph unchanged
	var g2 = new Graph(GraphFlags.GRAPH_DIRECTED, [new Edge("X", "Y")]);
	g2.Freeze();
	g2.Reverse();
	runner.Assert(g2.HasEdge("X", "Y"), "Immutable unchanged by Reverse");
	
	// Undirected throws
	var g3 = new Graph(GraphFlags.GRAPH_NONE);
	g3.AddEdge("A", "B");
	var error_caught = false;
	try { g3.Reverse(); } catch (_) { error_caught = true; }
	runner.Assert(error_caught, "Undirected Reverse throws");
	
	runner.AssertGraphConsistency(g1, "In-place reversed graph");
}

/// @description Test GetRandomNode and GetRandomEdge
function TestRandomGetters(runner)
{
	show_debug_message("\n=== Testing Random Getters ===");
	
	var g = new Graph(GraphFlags.GRAPH_NONE);
	g.AddEdges(["A", "B"], ["B", "C"], ["C", "D"]);
	
	// GetRandomNode
	var random_node = g.GetRandomNode();
	runner.Assert(g.HasNode(random_node), "GetRandomNode returns valid node");
	
	// GetRandomEdge
	var random_edge = g.GetRandomEdge();
	runner.Assert(is_struct(random_edge), "GetRandomEdge returns struct");
	runner.Assert(g.HasEdge(random_edge.from, random_edge.to), "GetRandomEdge returns valid edge");
	
	// Multiple calls should work
	for (var i = 0; i < 10; i++)
	{
		var node = g.GetRandomNode();
		runner.Assert(g.HasNode(node), "Random node valid iteration " + string(i));
	}
}

/// @description Test GetDebugID
function TestGetDebugID(runner)
{
	show_debug_message("\n=== Testing GetDebugID ===");
	
	var g1 = new Graph(GraphFlags.GRAPH_NONE);
	var g2 = new Graph(GraphFlags.GRAPH_NONE);
	
	var id1 = g1.GetDebugID();
	var id2 = g2.GetDebugID();

	runner.Assert(is_numeric(id1), "Debug ID is numeric");
	runner.Assert(id1 != id2, "Different graphs have different IDs");
	
	// Clone has different ID
	var g3 = g1.Clone();
	var id3 = g3.GetDebugID();
	runner.Assert(id1 != id3, "Clone has different debug ID");
}

/// @description Test ToDOT export
function TestToDOT(runner)
{
	show_debug_message("\n=== Testing ToDOT Export ===");
	
	// Undirected graph
	var g1 = new Graph(GraphFlags.GRAPH_NONE);
	g1.AddEdges(["A", "B"], ["B", "C"]);
	var dot1 = g1.ToDOT();
	runner.Assert(string_pos("graph", dot1) > 0, "Undirected uses 'graph'");
	runner.Assert(string_pos("--", dot1) > 0, "Undirected uses '--'");
	runner.Assert(string_pos("A -- B", dot1) > 0, "Contains edge A--B");
	
	// Directed graph
	var g2 = new Graph(GraphFlags.GRAPH_DIRECTED);
	g2.AddEdges(["X", "Y"], ["Y", "Z"]);
	var dot2 = g2.ToDOT();
	runner.Assert(string_pos("digraph", dot2) > 0, "Directed uses 'digraph'");
	runner.Assert(string_pos("->", dot2) > 0, "Directed uses '->'");
	runner.Assert(string_pos("X -> Y", dot2) > 0, "Contains edge X->Y");
	
	// Weighted graph
	var g3 = new Graph(GraphFlags.GRAPH_WEIGHTED);
	g3.AddEdge("M", "N", 5.5);
	var dot3 = g3.ToDOT();
	runner.Assert(string_pos("weight=5.5", dot3) > 0, "Contains weight attribute");
	
	// Isolated node
	var g4 = new Graph(GraphFlags.GRAPH_NONE);
	g4.AddNode("Isolated");
	g4.AddEdge("A", "B");
	var dot4 = g4.ToDOT();
	runner.Assert(string_pos("Isolated", dot4) > 0, "Contains isolated node");
	
	// Custom name
	var dot5 = g1.ToDOT("MyGraph");
	runner.Assert(string_pos("MyGraph", dot5) > 0, "Custom graph name");
}

/// @description Test ToAdjacencyMatrix export
function TestToAdjacencyMatrix(runner)
{
	show_debug_message("\n=== Testing ToAdjacencyMatrix ===");
	
	// Simple undirected graph
	var g1 = new Graph(GraphFlags.GRAPH_NONE);
	g1.AddEdges(["0", "1"], ["1", "2"]);
	var matrix1 = g1.ToAdjacencyMatrix();
	runner.Assert(is_array(matrix1), "Returns array");
	runner.AssertEquals(3, array_length(matrix1), "Matrix size matches node count");
	runner.Assert(matrix1[0][1] == true, "Edge 0-1 in matrix");
	runner.Assert(matrix1[1][0] == true, "Undirected symmetry");
	runner.Assert(matrix1[0][2] == false, "No edge 0-2");
	
	// Directed graph
	var g2 = new Graph(GraphFlags.GRAPH_DIRECTED);
	g2.AddEdges(["A", "B"], ["B", "C"]);
	var matrix2 = g2.ToAdjacencyMatrix();
	runner.Assert(is_array(matrix2), "Directed matrix is array");
	runner.AssertEquals(3, array_length(matrix2), "Directed matrix size");
	
	// Empty graph
	var g3 = new Graph(GraphFlags.GRAPH_NONE);
	var matrix3 = g3.ToAdjacencyMatrix();
	runner.AssertEquals(0, array_length(matrix3), "Empty graph empty matrix");
}

/// @description Test IsSelfLoopable
function TestIsSelfLoopable(runner)
{
	show_debug_message("\n=== Testing IsSelfLoopable ===");
	
	var g1 = new Graph(GraphFlags.GRAPH_ALLOW_SELF_LOOP);
	runner.Assert(g1.IsSelfLoopable(), "Self-loop flag detected");
	
	var g2 = new Graph(GraphFlags.GRAPH_NONE);
	runner.Assert(!g2.IsSelfLoopable(), "No self-loop flag");
	
	var g3 = new Graph(GraphFlags.GRAPH_DIRECTED | GraphFlags.GRAPH_ALLOW_SELF_LOOP);
	runner.Assert(g3.IsSelfLoopable(), "Self-loop with other flags");
}

/// @description Run all unit tests
function RunAllTests()
{
	var runner = new TestRunner();
	
	show_debug_message("\n########################################");
	show_debug_message("# GRAPH LIBRARY - ENHANCED UNIT TESTS #");
	show_debug_message("########################################");
	
	TestEmptyAndMinimalGraphs(runner);
	TestGraphConstruction(runner);
	TestNodeOperations(runner);
	TestEdgeOperations(runner);
	TestEdgeRemoval(runner);
	TestNodeRemovalWithEdges(runner);
	TestCopyClone(runner);
	TestDegrees(runner);
	TestNeighbors(runner);
	TestBFS(runner);
	TestPaths(runner);
	TestShortestDistance(runner);
	TestDijkstra(runner);
	TestComponents(runner);
	TestImmutability(runner);
	TestClear(runner);
	TestComplexStructures(runner);
	TestEdgeCases(runner);
	TestMixedTypes(runner);
	TestDFS(runner);
	TestCycleDetectionUndirected(runner);
	TestCycleDetectionDirected(runner);
	TestDFSAndCycleEdgeCases(runner);
	TestWeightOperations(runner);
	TestCacheManagement(runner);
	TestEdgeCountUndirected(runner);
	TestIsSelfLoopable(runner);
	TestToAdjacencyMatrix(runner);
	TestToDOT(runner);
	TestGetDebugID(runner);
	TestRandomGetters(runner);
	TestReverse(runner);
	TestGetReversed(runner);
	TestGetDensity(runner);
	TestIsComplete(runner);
	TestIsTree(runner)
	TestTopologicalSort(runner)
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
    
    var node_count = 50000;
    var edge_count = 100000;
    
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
    
    var node_count = 10000;
    
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

/// @description Benchmark DFS traversal on linear path
function BenchmarkDFSLinearPath(runner, node_count, iterations)
{
	// Build linear path graph
	var g = new Graph(GraphFlags.GRAPH_NONE);
	for (var i = 0; i < node_count - 1; i++)
		g.AddEdge(string(i), string(i + 1));
	
	var timer = new BenchmarkTimer();
	timer.Start();
	
	for (var i = 0; i < iterations; i++)
	{
		var result = g.DFS("0");
	}
	
	var elapsed = timer.Stop();
	runner.AddResult($"DFS Linear Path ({node_count} nodes)", elapsed, iterations);
}

/// @description Benchmark DFS traversal on tree structure
function BenchmarkDFSTree(runner, depth, branching_factor, iterations)
{
	// Build balanced tree
	var g = new Graph(GraphFlags.GRAPH_NONE);
	var node_id = 0;
	var queue = ["0"];
	var current_depth = 0;
	
	while (array_length(queue) > 0 && current_depth < depth)
	{
		var next_queue = [];
		for (var i = 0; i < array_length(queue); i++)
		{
			var parent = queue[i];
			for (var j = 0; j < branching_factor; j++)
			{
				node_id++;
				var child = string(node_id);
				g.AddEdge(parent, child);
				array_push(next_queue, child);
			}
		}
		queue = next_queue;
		current_depth++;
	}
	
	var timer = new BenchmarkTimer();
	timer.Start();
	
	for (var i = 0; i < iterations; i++)
	{
		var result = g.DFS("0");
	}
	
	var elapsed = timer.Stop();
	runner.AddResult($"DFS Tree (depth={depth}, branch={branching_factor})", elapsed, iterations);
}

/// @description Benchmark DFS with early termination (target found)
function BenchmarkDFSWithTarget(runner, node_count, target_position, iterations)
{
	// Build linear path
	var g = new Graph(GraphFlags.GRAPH_NONE);
	for (var i = 0; i < node_count - 1; i++)
		g.AddEdge(string(i), string(i + 1));
	
	var target = string(target_position);
	
	var timer = new BenchmarkTimer();
	timer.Start();
	
	for (var i = 0; i < iterations; i++)
	{
		var result = g.DFS("0", target);
	}
	
	var elapsed = timer.Stop();
	runner.AddResult($"DFS Early Stop (target at {target_position}/{node_count})", elapsed, iterations);
}

/// @description Benchmark DFS on dense graph
function BenchmarkDFSDenseGraph(runner, node_count, iterations)
{
	// Build complete graph (all nodes connected)
	var g = new Graph(GraphFlags.GRAPH_NONE);
	for (var i = 0; i < node_count; i++)
	{
		for (var j = i + 1; j < node_count; j++)
		{
			g.AddEdge(string(i), string(j));
		}
	}
	
	var timer = new BenchmarkTimer();
	timer.Start();
	
	for (var i = 0; i < iterations; i++)
	{
		var result = g.DFS("0");
	}
	
	var elapsed = timer.Stop();
	runner.AddResult($"DFS Dense Graph ({node_count} nodes, complete)", elapsed, iterations);
}

/// @description Benchmark DFS on directed vs undirected graph
function BenchmarkDFSDirectedVsUndirected(runner, node_count, iterations)
{
	// Build directed path
	var g_dir = new Graph(GraphFlags.GRAPH_DIRECTED);
	for (var i = 0; i < node_count - 1; i++)
		g_dir.AddEdge(string(i), string(i + 1));
	
	// Build undirected path
	var g_undir = new Graph(GraphFlags.GRAPH_NONE);
	for (var i = 0; i < node_count - 1; i++)
		g_undir.AddEdge(string(i), string(i + 1));
	
	// Benchmark directed
	var timer = new BenchmarkTimer();
	timer.Start();
	for (var i = 0; i < iterations; i++)
		g_dir.DFS("0");
	var elapsed_dir = timer.Stop();
	runner.AddResult($"DFS Directed ({node_count} nodes)", elapsed_dir, iterations);
	
	// Benchmark undirected
	timer.Start();
	for (var i = 0; i < iterations; i++)
		g_undir.DFS("0");
	var elapsed_undir = timer.Stop();
	runner.AddResult($"DFS Undirected ({node_count} nodes)", elapsed_undir, iterations);
}

/// @description Benchmark HasCycle on acyclic graphs
function BenchmarkHasCycleAcyclic(runner, node_count, iterations)
{
	// Build tree (guaranteed acyclic)
	var g = new Graph(GraphFlags.GRAPH_NONE);
	for (var i = 1; i < node_count; i++)
		g.AddEdge(string(floor(i / 2)), string(i));
	
	var timer = new BenchmarkTimer();
	timer.Start();
	
	for (var i = 0; i < iterations; i++)
	{
		var has_cycle = g.HasCycle();
	}
	
	var elapsed = timer.Stop();
	runner.AddResult($"HasCycle Acyclic Tree ({node_count} nodes)", elapsed, iterations);
}

/// @description Benchmark HasCycle on cyclic graphs
function BenchmarkHasCycleCyclic(runner, node_count, iterations)
{
	// Build graph with early cycle
	var g = new Graph(GraphFlags.GRAPH_NONE);
	g.AddEdges(["0", "1"], ["1", "2"], ["2", "0"]); // Early cycle
	for (var i = 3; i < node_count; i++)
		g.AddEdge(string(i - 1), string(i));
	
	var timer = new BenchmarkTimer();
	timer.Start();
	
	for (var i = 0; i < iterations; i++)
	{
		var has_cycle = g.HasCycle();
	}
	
	var elapsed = timer.Stop();
	runner.AddResult($"HasCycle Early Cycle ({node_count} nodes)", elapsed, iterations);
}

/// @description Benchmark HasCycle with late cycle
function BenchmarkHasCycleLateCycle(runner, node_count, iterations)
{
	// Build graph with cycle at the end
	var g = new Graph(GraphFlags.GRAPH_NONE);
	for (var i = 0; i < node_count - 3; i++)
		g.AddEdge(string(i), string(i + 1));
	// Add cycle at end
	var last = string(node_count - 3);
	g.AddEdges([last, string(node_count - 2)], [string(node_count - 2), string(node_count - 1)], [string(node_count - 1), last]);
	
	var timer = new BenchmarkTimer();
	timer.Start();
	
	for (var i = 0; i < iterations; i++)
	{
		var has_cycle = g.HasCycle();
	}
	
	var elapsed = timer.Stop();
	runner.AddResult($"HasCycle Late Cycle ({node_count} nodes)", elapsed, iterations);
}

/// @description Benchmark GetCycle on graphs with cycles
function BenchmarkGetCycle(runner, cycle_size, iterations)
{
	// Build simple cycle
	var g = new Graph(GraphFlags.GRAPH_NONE);
	for (var i = 0; i < cycle_size - 1; i++)
		g.AddEdge(string(i), string(i + 1));
	g.AddEdge(string(cycle_size - 1), "0"); // Close the cycle
	
	var timer = new BenchmarkTimer();
	timer.Start();
	
	for (var i = 0; i < iterations; i++)
	{
		var cycle = g.GetCycle();
	}
	
	var elapsed = timer.Stop();
	runner.AddResult($"GetCycle ({cycle_size}-node cycle)", elapsed, iterations);
}

/// @description Benchmark IsDAG on directed acyclic graphs
function BenchmarkIsDAG(runner, node_count, iterations)
{
	// Build DAG (topologically ordered)
	var g = new Graph(GraphFlags.GRAPH_DIRECTED);
	for (var i = 0; i < node_count; i++)
	{
		for (var j = i + 1; j < min(i + 5, node_count); j++)
		{
			g.AddEdge(string(i), string(j));
		}
	}
	
	var timer = new BenchmarkTimer();
	timer.Start();
	
	for (var i = 0; i < iterations; i++)
	{
		var is_dag = g.IsDAG();
	}
	
	var elapsed = timer.Stop();
	runner.AddResult($"IsDAG True ({node_count} nodes)", elapsed, iterations);
}

/// @description Benchmark IsDAG on graphs with cycles
function BenchmarkIsDAGWithCycle(runner, node_count, iterations)
{
	// Build directed graph with cycle
	var g = new Graph(GraphFlags.GRAPH_DIRECTED);
	g.AddEdges(["0", "1"], ["1", "2"], ["2", "0"]); // Cycle
	for (var i = 3; i < node_count; i++)
		g.AddEdge(string(i - 1), string(i));
	
	var timer = new BenchmarkTimer();
	timer.Start();
	
	for (var i = 0; i < iterations; i++)
	{
		var is_dag = g.IsDAG();
	}
	
	var elapsed = timer.Stop();
	runner.AddResult($"IsDAG False ({node_count} nodes)", elapsed, iterations);
}

/// @description Benchmark cycle detection on directed vs undirected graphs
function BenchmarkCycleDirectedVsUndirected(runner, node_count, iterations)
{
	// Directed cyclic graph
	var g_dir = new Graph(GraphFlags.GRAPH_DIRECTED);
	for (var i = 0; i < node_count - 1; i++)
		g_dir.AddEdge(string(i), string(i + 1));
	g_dir.AddEdge(string(node_count - 1), "0");
	
	// Undirected cyclic graph
	var g_undir = new Graph(GraphFlags.GRAPH_NONE);
	for (var i = 0; i < node_count - 1; i++)
		g_undir.AddEdge(string(i), string(i + 1));
	g_undir.AddEdge(string(node_count - 1), "0");
	
	// Benchmark directed
	var timer = new BenchmarkTimer();
	timer.Start();
	for (var i = 0; i < iterations; i++)
		g_dir.HasCycle();
	var elapsed_dir = timer.Stop();
	runner.AddResult($"HasCycle Directed Cycle ({node_count} nodes)", elapsed_dir, iterations);
	
	// Benchmark undirected
	timer.Start();
	for (var i = 0; i < iterations; i++)
		g_undir.HasCycle();
	var elapsed_undir = timer.Stop();
	runner.AddResult($"HasCycle Undirected Cycle ({node_count} nodes)", elapsed_undir, iterations);
}

/// @description Benchmark DFS with callback overhead
function BenchmarkDFSCallback(runner, node_count, iterations)
{
	// Build linear path
	var g = new Graph(GraphFlags.GRAPH_NONE);
	for (var i = 0; i < node_count - 1; i++)
		g.AddEdge(string(i), string(i + 1));
	
	var callback_state = {dummy: 0};
	var callback = method(callback_state, function(node, prev) {
		self.dummy = node;
	});
	
	// Benchmark without callback
	var timer = new BenchmarkTimer();
	timer.Start();
	for (var i = 0; i < iterations; i++)
		g.DFS("0");
	var elapsed_no_cb = timer.Stop();
	runner.AddResult($"DFS No Callback ({node_count} nodes)", elapsed_no_cb, iterations);
	
	// Benchmark with callback
	timer.Start();
	for (var i = 0; i < iterations; i++)
		g.DFS("0", undefined, callback);
	var elapsed_with_cb = timer.Stop();
	runner.AddResult($"DFS With Callback ({node_count} nodes)", elapsed_with_cb, iterations);
}

/// @description Benchmark cycle detection on sparse vs dense graphs
function BenchmarkCycleSparseVsDense(runner, node_count, iterations)
{
	// Sparse graph (tree + one edge for cycle)
	var g_sparse = new Graph(GraphFlags.GRAPH_NONE);
	for (var i = 1; i < node_count; i++)
		g_sparse.AddEdge(string(floor(i / 2)), string(i));
	g_sparse.AddEdge("0", string(node_count - 1)); // Add cycle
	
	// Dense graph (many edges)
	var g_dense = new Graph(GraphFlags.GRAPH_NONE);
	for (var i = 0; i < node_count; i++)
	{
		for (var j = i + 1; j < min(i + 10, node_count); j++)
		{
			g_dense.AddEdge(string(i), string(j));
		}
	}
	
	// Benchmark sparse
	var timer = new BenchmarkTimer();
	timer.Start();
	for (var i = 0; i < iterations; i++)
		g_sparse.HasCycle();
	var elapsed_sparse = timer.Stop();
	runner.AddResult($"HasCycle Sparse ({node_count} nodes)", elapsed_sparse, iterations);
	
	// Benchmark dense
	timer.Start();
	for (var i = 0; i < iterations; i++)
		g_dense.HasCycle();
	var elapsed_dense = timer.Stop();
	runner.AddResult($"HasCycle Dense ({node_count} nodes)", elapsed_dense, iterations);
}

/// @description Run all DFS benchmarks
function BenchmarkDFS(runner)
{
	show_debug_message("\n=== DFS TRAVERSAL BENCHMARKS ===");
	
	BenchmarkDFSLinearPath(runner, 100, 1000);
	BenchmarkDFSLinearPath(runner, 500, 200);
	BenchmarkDFSLinearPath(runner, 1000, 100);
	
	BenchmarkDFSTree(runner, 5, 3, 500);  // 3^5 = 243 nodes
	BenchmarkDFSTree(runner, 7, 2, 200);  // 2^7 = 127 nodes
	
	BenchmarkDFSWithTarget(runner, 1000, 100, 500);
	BenchmarkDFSWithTarget(runner, 1000, 900, 500);
	
	BenchmarkDFSDenseGraph(runner, 50, 100);
	BenchmarkDFSDenseGraph(runner, 100, 20);
	
	BenchmarkDFSDirectedVsUndirected(runner, 500, 200);
	
	BenchmarkDFSCallback(runner, 500, 200);
}

/// @description Run all cycle detection benchmarks
function BenchmarkCycleDetection(runner)
{
	show_debug_message("\n=== CYCLE DETECTION BENCHMARKS ===");
	
	BenchmarkHasCycleAcyclic(runner, 100, 500);
	BenchmarkHasCycleAcyclic(runner, 500, 100);
	BenchmarkHasCycleAcyclic(runner, 1000, 50);
	
	BenchmarkHasCycleCyclic(runner, 100, 500);
	BenchmarkHasCycleCyclic(runner, 500, 100);
	
	BenchmarkHasCycleLateCycle(runner, 100, 500);
	BenchmarkHasCycleLateCycle(runner, 500, 100);
	
	BenchmarkGetCycle(runner, 10, 1000);
	BenchmarkGetCycle(runner, 50, 500);
	BenchmarkGetCycle(runner, 100, 200);
	
	BenchmarkCycleDirectedVsUndirected(runner, 100, 500);
	BenchmarkCycleDirectedVsUndirected(runner, 500, 100);
	
	BenchmarkCycleSparseVsDense(runner, 100, 200);
}

/// @description Run all DAG benchmarks
function BenchmarkDAG(runner)
{
	show_debug_message("\n=== DAG BENCHMARKS ===");
	
	BenchmarkIsDAG(runner, 100, 500);
	BenchmarkIsDAG(runner, 500, 100);
	BenchmarkIsDAG(runner, 1000, 50);
	
	BenchmarkIsDAGWithCycle(runner, 100, 500);
	BenchmarkIsDAGWithCycle(runner, 500, 100);
}

/// @description IMPROVED: Realistic graph patterns
function BenchmarkRealisticPatterns(runner)
{
	show_debug_message("\n=== REALISTIC GRAPH PATTERNS ===");
	
	// Social network pattern (scale-free / power law)
	var timer1 = new BenchmarkTimer();
	timer1.Start();
	var g_social = new Graph(GraphFlags.GRAPH_NONE);
	// Hub nodes with many connections
	for (var hub = 0; hub < 5; hub++)
	{
		for (var i = 0; i < 50; i++)
		{
			g_social.AddEdge(hub, 100 + hub * 50 + i);
		}
	}
	// Regular nodes with few connections
	for (var i = 0; i < 200; i++)
	{
		var connections = irandom_range(1, 3);
		for (var j = 0; j < connections; j++)
		{
			var target = irandom(399);
			if (target != i)
				g_social.AddEdge(i, target);
		}
	}
	var time1 = timer1.Stop();
	runner.AddResult("Build Social Network Pattern (power law)", time1, 1);
	
	// BFS from hub
	var timer2 = new BenchmarkTimer();
	timer2.Start();
	g_social.BFS(0);
	var time2 = timer2.Stop();
	runner.AddResult("BFS from Hub Node", time2, 1);
	
	// Road network pattern (sparse, planar)
	var timer3 = new BenchmarkTimer();
	timer3.Start();
	var g_road = new Graph(GraphFlags.GRAPH_WEIGHTED);
	var grid_size = 30;
	for (var _y = 0; _y < grid_size; _y++)
	{
		for (var _x = 0; _x < grid_size; _x++)
		{
			var node = _y * grid_size + _x;
			if (_x < grid_size - 1)
				g_road.AddEdge(node, node + 1, random_range(1, 10));
			if (_y < grid_size - 1)
				g_road.AddEdge(node, node + grid_size, random_range(1, 10));
		}
	}
	var time3 = timer3.Stop();
	runner.AddResult("Build Road Network Pattern (grid)", time3, 1);
	
	// Dijkstra on road network
	var timer4 = new BenchmarkTimer();
	timer4.Start();
	g_road.Dijkstra(0, grid_size * grid_size - 1);
	var time4 = timer4.Stop();
	runner.AddResult("Dijkstra on Road Network (corner to corner)", time4, 1);
}

#endregion

/// @description Benchmark GetTopologicalSort
function BenchmarkTopologicalSort(runner, node_count, iterations)
{
	// Build DAG with layered structure
	var g = new Graph(GraphFlags.GRAPH_DIRECTED);
	var layers = 5;
	var nodes_per_layer = ceil(node_count / layers);
	
	for (var _layer = 0; _layer < layers - 1; _layer++)
	{
		for (var i = 0; i < nodes_per_layer; i++)
		{
			var from = _layer * nodes_per_layer + i;
			for (var j = 0; j < nodes_per_layer; j++)
			{
				var to = (_layer + 1) * nodes_per_layer + j;
				if (random(1) > 0.5) // 50% connectivity
					g.AddEdge(string(from), string(to));
			}
		}
	}
	
	var timer = new BenchmarkTimer();
	timer.Start();
	
	for (var i = 0; i < iterations; i++)
	{
		var topo = g.GetTopologicalSort();
	}
	
	var elapsed = timer.Stop();
	runner.AddResult($"GetTopologicalSort ({node_count} nodes, {iterations} iterations)", elapsed, iterations);
}

/// @description Benchmark GetReversed
function BenchmarkGetReversed(runner, edge_count, iterations)
{
	var g = new Graph(GraphFlags.GRAPH_DIRECTED);
	for (var i = 0; i < edge_count; i++)
		g.AddEdge(string(i), string(i + 1));
	
	var timer = new BenchmarkTimer();
	timer.Start();
	
	for (var i = 0; i < iterations; i++)
	{
		var reversed = g.GetReversed();
	}
	
	var elapsed = timer.Stop();
	runner.AddResult($"GetReversed ({edge_count} edges, {iterations} iterations)", elapsed, iterations);
}

/// @description Benchmark Reverse in-place
function BenchmarkReverse(runner, edge_count, iterations)
{
	var timer = new BenchmarkTimer();
	timer.Start();
	
	for (var i = 0; i < iterations; i++)
	{
		var g = new Graph(GraphFlags.GRAPH_DIRECTED);
		for (var j = 0; j < edge_count; j++)
			g.AddEdge(string(j), string(j + 1));
		g.Reverse();
	}
	
	var elapsed = timer.Stop();
	runner.AddResult($"Reverse in-place ({edge_count} edges, {iterations} iterations)", elapsed, iterations);
}

/// @description Benchmark ToDOT export
function BenchmarkToDOT(runner, edge_count, iterations)
{
	var g = new Graph(GraphFlags.GRAPH_WEIGHTED);
	for (var i = 0; i < edge_count; i++)
		g.AddEdge(string(i), string(i + 1), random_range(1, 10));
	
	var timer = new BenchmarkTimer();
	timer.Start();
	
	for (var i = 0; i < iterations; i++)
	{
		var dot = g.ToDOT();
	}
	
	var elapsed = timer.Stop();
	runner.AddResult($"ToDOT Export ({edge_count} edges, {iterations} iterations)", elapsed, iterations);
}

/// @description Benchmark ToAdjacencyMatrix
function BenchmarkToAdjacencyMatrix(runner, node_count, iterations)
{
	var g = new Graph(GraphFlags.GRAPH_NONE);
	for (var i = 0; i < node_count - 1; i++)
		g.AddEdge(string(i), string(i + 1));
	
	var timer = new BenchmarkTimer();
	timer.Start();
	
	for (var i = 0; i < iterations; i++)
	{
		var matrix = g.ToAdjacencyMatrix();
	}
	
	var elapsed = timer.Stop();
	runner.AddResult($"ToAdjacencyMatrix ({node_count} nodes, {iterations} iterations)", elapsed, iterations);
}

/// @description Benchmark GetDensity
function BenchmarkGetDensity(runner, node_count, iterations)
{
	var g = new Graph(GraphFlags.GRAPH_NONE);
	for (var i = 0; i < node_count; i++)
	{
		for (var j = i + 1; j < node_count; j++)
		{
			if (random(1) > 0.7)
				g.AddEdge(string(i), string(j));
		}
	}
	
	var timer = new BenchmarkTimer();
	timer.Start();
	
	for (var i = 0; i < iterations; i++)
	{
		var density = g.GetDensity();
	}
	
	var elapsed = timer.Stop();
	runner.AddResult($"GetDensity ({node_count} nodes, {iterations} iterations)", elapsed, iterations);
}

/// @description Benchmark IsTree
function BenchmarkIsTree(runner, node_count, iterations)
{
	// Build tree structure
	var g = new Graph(GraphFlags.GRAPH_NONE);
	for (var i = 1; i < node_count; i++)
		g.AddEdge(string(floor(i / 2)), string(i));
	
	var timer = new BenchmarkTimer();
	timer.Start();
	
	for (var i = 0; i < iterations; i++)
	{
		var is_tree = g.IsTree();
	}
	
	var elapsed = timer.Stop();
	runner.AddResult($"IsTree ({node_count} nodes, {iterations} iterations)", elapsed, iterations);
}

/// @description Benchmark IsComplete
function BenchmarkIsComplete(runner, node_count, iterations)
{
	// Build complete graph
	var g = new Graph(GraphFlags.GRAPH_NONE);
	for (var i = 0; i < node_count; i++)
	{
		for (var j = i + 1; j < node_count; j++)
		{
			g.AddEdge(string(i), string(j));
		}
	}
	
	var timer = new BenchmarkTimer();
	timer.Start();
	
	for (var i = 0; i < iterations; i++)
	{
		var is_complete = g.IsComplete();
	}
	
	var elapsed = timer.Stop();
	runner.AddResult($"IsComplete ({node_count} nodes, {iterations} iterations)", elapsed, iterations);
}

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

	show_debug_message("\n=== Random shit ===");
	BenchmarkTopologicalSort(runner, 100, 100);
	BenchmarkTopologicalSort(runner, 500, 20);
	BenchmarkTopologicalSort(runner, 2500, 1);
	
	BenchmarkGetReversed(runner, 100, 500);
	BenchmarkGetReversed(runner, 500, 100);
	BenchmarkGetReversed(runner, 1000, 50);
	
	BenchmarkReverse(runner, 100, 200);
	BenchmarkReverse(runner, 500, 50);
	
	BenchmarkToDOT(runner, 50, 500);
	BenchmarkToDOT(runner, 100, 200);
	BenchmarkToDOT(runner, 500, 50);
	
	BenchmarkToAdjacencyMatrix(runner, 50, 200);
	BenchmarkToAdjacencyMatrix(runner, 100, 50);
	BenchmarkToAdjacencyMatrix(runner, 200, 20);
	
	BenchmarkGetDensity(runner, 50, 1000);
	BenchmarkGetDensity(runner, 100, 500);
	BenchmarkGetDensity(runner, 200, 100);
	
	BenchmarkIsTree(runner, 100, 500);
	BenchmarkIsTree(runner, 500, 100);
	BenchmarkIsTree(runner, 1000, 50);
	
	BenchmarkIsComplete(runner, 20, 1000);
	BenchmarkIsComplete(runner, 50, 200);
	BenchmarkIsComplete(runner, 100, 50);
	
	BenchmarkDFS(runner);
	BenchmarkCycleDetection(runner);
	BenchmarkDAG(runner);
	BenchmarkRealisticPatterns(runner);
	
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

var _test = new Graph(GraphFlags.GRAPH_DIRECTED);
_test.AddEdges([5, 11], [7, 11], [7, 8], [3, 8], [3, 10], [11, 2], [11, 9], [11, 10], [8, 9]);
show_debug_message(_test.ToDOT());
show_debug_message(_test.GetTopologicalSort());