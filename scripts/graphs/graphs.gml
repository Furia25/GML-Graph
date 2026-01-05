
enum GraphFlags
{
	GRAPH_NONE					= 0,
	GRAPH_DIRECTED				= 1 << 0,
	GRAPH_WEIGHTED				= 1 << 1,
	GRAPH_ALLOW_SELF_LOOP		= 1 << 2,
	GRAPH_IMMUTABLE				= 1 << 3,
	GRAPH_ALL					= GraphFlags.GRAPH_DIRECTED | GraphFlags.GRAPH_WEIGHTED | GraphFlags.GRAPH_ALLOW_SELF_LOOP | GraphFlags.GRAPH_IMMUTABLE
};

/// @description Creates a new edge structure connecting two nodes
/// @param {Any} from The source node
/// @param {Any} to The target node
/// @param {Real} weight The edge weight (default: 1)
/// @return {Struct.Edge}
function Edge(from, to, weight = 1) constructor
{
	self.from = from;
	self.to = to;
	self.weight = weight;
}

/// @description Creates a new graph data structure with specified configuration
/// @param {Real} flags Bitwise flags from GraphFlags enum to configure the graph
/// @param {Any} [builder] Optional builder with multiple initialization options. See documentation for all possibilities
/// @param {Any...} args Optional arguments for builder in case its callable
/// @return {Struct.Graph}
function Graph(flags, builder = undefined) constructor
{
	static __graph_count = 0;

	self.__graph_id = __graph_count;
	self.__flags = flags
	self.__flags &= ~GraphFlags.GRAPH_IMMUTABLE;

	self.__graph = {};

	self.__edge_count = 0;
	self.__node_count = 0;

	self.__edge_cache = undefined;
	self.__edge_dirty = true;

	self.__structure_dirty = true;
	self.__components_cache = undefined;

	if (builder != undefined)
	{
		var _args = [];
		for (var i = 2; i < argument_count; i++)
			array_push(_args, argument[i]);
		self.__build__(builder, _args);
	}
		
	self.__flags = flags;
	if (self.IsImmutable())
		self.Freeze();

	#region Algorithm

	/// @description Performs breadth-first search traversal from source node
	/// @param {Any} source The starting node for traversal
	/// @param {Any} [target] Optional target node to stop at when found
	/// @param {Function} [callback] Optional callback function(current_node, previous_node) called for each visited node
	/// @return {Struct} Returns {visited: array of nodes in visit order, previous: struct mapping nodes to their predecessors}
	static BFS = function(source, target = undefined, callback = undefined)
	{
		if (!self.HasNode(source))
			self.__throw__($"Node {source} does not exist");
		if (target != undefined && !self.HasNode(target))
			self.__throw__($"Node {target} does not exist");
		var _result = [];
		var _queue = ds_queue_create();
		var _previous = {};
		var _visited = {};

		_visited[$ source] = true;
		ds_queue_enqueue(_queue, source);

		while (!ds_queue_empty(_queue))
		{
			var _current = ds_queue_dequeue(_queue);
			array_push(_result, _current);
			if (callback != undefined)
				callback(_current, _previous[$ _current]);
			if (_current == target)
				break ;
			var _neighbors = self.GetNeighbors(_current);
			for (var i = 0; i < array_length(_neighbors); i++)
			{
				var _neighbor = _neighbors[i];
				if (_visited[$ _neighbor])
					continue ;
				_visited[$ _neighbor] = true;
				_previous[$ _neighbor] = _current;
				ds_queue_enqueue(_queue, _neighbor);
			}
		}
		ds_queue_destroy(_queue);
		return ({path: _result, visited: _visited, previous: _previous});
	}

	/// @description Performs depth-first search traversal from source node
	/// @param {Any} source The starting node for traversal
	/// @param {Any} [target] Optional target node to stop at when found
	/// @param {Function} [callback] Optional callback function(current_node, previous_node) called for each visited node
	/// @return {Struct} Returns {visited: array of nodes in visit order, previous: struct mapping nodes to their predecessors}
	static DFS = function(source, target = undefined, callback = undefined)
	{
		if (!self.HasNode(source))
			self.__throw__($"Node {source} does not exist");
		if (target != undefined && !self.HasNode(target))
			self.__throw__($"Node {target} does not exist");
		var _result = [];
		var _stack = [];
		var _visited = {};
		var _previous = {};

		array_push(_stack, source);
		while (array_length(_stack) > 0)
		{
			var _current = array_pop(_stack);
			if (_visited[$ _current])
				continue ;
			_visited[$ _current] = true;
			array_push(_result, _current);
			if (callback != undefined)
				callback(_current, _previous[$ _current]);
			if (_current == target)
				break ;
			var _neighbors = self.GetNeighbors(_current);
			for (var i = array_length(_neighbors) - 1; i >= 0; i--)
			{
				var _neighbor = _neighbors[i];
				if (_visited[$ _neighbor])
					continue ;
				array_push(_stack, _neighbor);
				_previous[$ _neighbor] = _current;
			}
		}
		return ({path: _result, visited: _visited, previous: _previous});
	}

	static __DFSGetCycleUndirected = function(source, _visited = undefined, _previous = undefined)
	{
		_visited ??= {};
		_previous ??= {};
		var _stack = [];
		array_push(_stack, source);

		while (array_length(_stack) > 0)
		{
			var _current = array_pop(_stack);
			if (_visited[$ _current])
				continue ;

			_visited[$ _current] = true;
			var _parent = _previous[$ _current];
			var _neighbors = self.GetNeighbors(_current);
			for (var i = array_length(_neighbors) - 1; i >= 0; i--)
			{
				var _neighbor = _neighbors[i];
				if (!_visited[$ _neighbor])
				{
					
					_previous[$ _neighbor] = _current;
					array_push(_stack, _neighbor);
				}
				else if (_neighbor != _parent)
				{
					var _cycle = [_neighbor];
					var _cur = _current;
					while (_cur != _neighbor && _cur != undefined)
					{
						array_push(_cycle, _cur);
						_cur = _previous[$ _cur];
					}
					array_push(_cycle, _neighbor);
					return (_cycle);
				}
			}
		}
		return (undefined);
	}

	static __DFSGetCycleDirected = function(source, _state = undefined, _previous = undefined)
	{
		_state ??= {};
		_previous ??= {};
		var _stack = [];

		array_push(_stack, source);
		_state[$ source] = __GraphColor.GRAY;
		while (array_length(_stack) > 0)
		{
			var _current = array_last(_stack);
			var _neighbors = self.GetNeighbors(_current);
			var _all_processed = true;

			for (var i = array_length(_neighbors) - 1; i >= 0; i--)
			{
				var _neighbor = _neighbors[i];
				if (!variable_struct_exists(_state, _neighbor)) // __GraphColor.WHITE
				{
					_state[$ _neighbor] = __GraphColor.GRAY;
					_previous[$ _neighbor] = _current;
					array_push(_stack, _neighbor);
					_all_processed = false;
					break ;
				}
				else if (_state[$ _neighbor] == __GraphColor.GRAY)
				{
					var _cycle = [_neighbor];
					var _cur = _current;
					while (_cur != _neighbor && _cur != undefined)
					{
						array_push(_cycle, _cur);
						_cur = _previous[$ _cur];
					}
					array_push(_cycle, _neighbor);
					return (_cycle);
				}
			}
			if (_all_processed)
			{
				_state[$ _current] = __GraphColor.BLACK;
				array_pop(_stack);
			}
		}
		return (undefined);
	}

	/// @description Finds shortest paths from source to all reachable nodes using Dijkstra's algorithm
	/// @param {Any} source The starting node
	/// @param {Any} [target] Optional target node to stop at when found
	/// @return {Struct} Returns {distances: struct mapping nodes to shortest distances, previous: struct mapping nodes to predecessors}
	static Dijkstra = function(source, target = undefined)
	{
		if (!self.HasNode(source))
			self.__throw__($"Node {source} does not exist");
		if (target != undefined && !self.HasNode(target))
			self.__throw__($"Node {target} does not exist");
		var _prev = {};
		var _distances = {};
		var _visited = {};
		var _queue = ds_priority_create();

		_distances[$ source] = 0;
		ds_priority_add(_queue, source, 0);

		while (!ds_priority_empty(_queue))
		{
			var _u = ds_priority_delete_min(_queue);
			if (_visited[$ _u])
				continue ;
			_visited[$ _u] = true;

			if (_u == target)
				break ;

			var _neighbors = self.GetNeighbors(_u);
			for (var i = 0; i < array_length(_neighbors); i++)
			{
				var _v = _neighbors[i];
				if (_visited[$ _v])
					continue ;
				var _weight = self.__graph[$ _u][$ _v];
				if (_weight < 0)
				{
					ds_priority_destroy(_queue);
					self.__throw__("Graph contain negative weights, dijkstra failed.");
				}
				var _alt = _distances[$ _u] + _weight;
				if (_distances[$ _v] == undefined || _alt < _distances[$ _v])
				{
					_distances[$ _v] = _alt;
					_prev[$ _v] = _u;
					ds_priority_add(_queue, _v, _alt);
				}
			}
		}
		ds_priority_destroy(_queue);
		return ({distances: _distances, previous: _prev, visited: _visited});
	}

	#endregion

	#region Checks

	/// @description Checks if the graph is directed
	/// @return {Bool} Returns true if graph is directed, false otherwise
	static IsDirected = function()
	{
		gml_pragma("forceinline");
		return (self.__flags & GraphFlags.GRAPH_DIRECTED) != 0;
	}

	/// @description Checks if the graph is immutable (read-only)
	/// @return {Bool} Returns true if graph is immutable, false otherwise
	static IsImmutable = function()
	{
		gml_pragma("forceinline");
		return (self.__flags & GraphFlags.GRAPH_IMMUTABLE) != 0;
	}

	/// @description Checks if the graph supports weighted edges
	/// @return {Bool} Returns true if graph is weighted, false otherwise
	static IsWeighted = function()
	{
		gml_pragma("forceinline");
		return (self.__flags & GraphFlags.GRAPH_WEIGHTED) != 0;
	}

	static IsSelfLoopable = function()
	{
		gml_pragma("forceinline");
		return (self.__flags & GraphFlags.GRAPH_ALLOW_SELF_LOOP) != 0;
	}

	/// @description Checks if a node exists in the graph
	/// @param {Any} node The node to check
	/// @return {Bool} Returns true if node exists, false otherwise
	static HasNode = function(node)
	{
		gml_pragma("forceinline");
		return (self.__graph[$ node] != undefined);
	}

	/// @description Checks if an edge exists between two nodes
	/// @param {Any} from The source node
	/// @param {Any} to The target node
	/// @return {Bool} Returns true if edge exists, false otherwise
	static HasEdge = function(from, to)
	{
		gml_pragma("forceinline");
		return (self.__graph[$ from] != undefined && (self.__graph[$ from][$ to] != undefined));
	}

	/// @description Checks if a path exists between two nodes
	/// @param {Any} from The source node
	/// @param {Any} to The target node
	/// @return {Bool} Returns true if a path exists, false otherwise
	static HasPath = function(from, to)
	{
		gml_pragma("forceinline");
		return (__isBFSPathValid(self.BFS(from, to), from, to));
	}

	/// @description Checks if the graph is fully connected (single component)
	/// @return {Bool} Returns true if graph has exactly one connected component
	static IsConnected = function()
	{
		gml_pragma("forceinline");
		return (self.GetComponentsCount() == 1);
	}

	static HasCycle = function()
	{
		gml_pragma("forceinline");
		return (self.GetCycle() != undefined);
	}

	static IsCyclic = function()
	{
		gml_pragma("forceinline");
		return (self.HasCycle());
	}

	static IsAcyclic = function()
	{
		gml_pragma("forceinline");
		return (!self.HasCycle());
	}

	static IsDAG = function()
	{
		gml_pragma("forceinline");
		return (self.IsDirected() && self.IsAcyclic());
	}

	static IsTree = function()
	{
		gml_pragma("forceinline");
		return (self.IsDirected() ? self.IsDAG() : self.IsConnected() && self.IsAcyclic());
	}

	static IsComplete = function()
	{
		gml_pragma("forceinline");
		var n = self.GetNodeCount();
		if (n == 0)
			return (false);
		return (self.GetEdgeCount() == n * (self.__flags & GraphFlags.GRAPH_ALLOW_SELF_LOOP ? n : n - 1) * 0.5);
	}

	#endregion

	#region Getters / Setters

	/// @description Retrieves the edge structure between two nodes
	/// @param {Any} from The source node
	/// @param {Any} to The target node
	/// @return {Struct.Edge} Returns the Edge struct
	static GetEdge = function(from, to)
	{
		gml_pragma("forceinline")
		if (!self.HasEdge(from, to))
			self.__throw__($"Edge {from} -> {to} does not exist");
		return (new Edge(from, to, self.__graph[$ from][$ to]));
	}

	/// @description Gets the weight of an edge between two nodes
	/// @param {Any} from The source node
	/// @param {Any} to The target node
	/// @return {Real} Returns the edge weight
	static GetWeight = function(from, to)
	{
		gml_pragma("forceinline");
		if (!self.HasEdge(from, to))
			self.__throw__($"Edge {from} -> {to} does not exist");
		return (self.__graph[$ from][$ to]);
	}

	/// @description Sets the weight of an existing edge (weighted graphs only)
	/// @param {Any} from The source node
	/// @param {Any} to The target node
	/// @param {Real} weight The new weight value
	/// @return {Struct.self} Returns self for method chaining
	static SetWeight = function (from, to, weight)
	{
		if (self.IsImmutable())
			return (self);
		if (!self.IsWeighted())
			self.__throw__("Cannot set weight on non-weighted graph.");
		if (!self.HasEdge(from, to))
			self.__throw__($"Edge {from} -> {to} does not exist");
		self.__graph[$ from][$ to] = weight;
		if (!self.IsDirected())
			self.__graph[$ to][$ from] = weight;
		self.__edge_dirty = true;
		return (self);
	}

	/// @description Gets an array of all nodes in the graph
	/// @return {Array<String>} Returns array of node identifiers
	static GetNodes = function()
	{
		gml_pragma("forceinline");
		return (variable_struct_get_names(self.__graph));
	}

	/// @description Gets all neighbors (adjacent nodes) of a given node
	/// @param {Any} node The node to get neighbors for
	/// @return {Array<String>} Returns array of neighboring node identifiers
	static GetNeighbors = function(node)
	{
		gml_pragma("forceinline");
		if (!self.HasNode(node))
			self.__throw__($"Node {node} does not exist");
		return (variable_struct_get_names(self.__graph[$ node]));
	}

	/// @description Gets an array of all edges in the graph
	/// @return {Array<Struct.Edge>} Returns array of Edge structs
	static GetEdges = function()
	{
		if (!self.__edge_dirty)
			return (variable_clone(self.__edge_cache));
		self.__edge_cache = [];
		var _nodes = self.GetNodes();
		for (var i = 0; i < array_length(_nodes); i++)
		{
			var _from = _nodes[i];
			var _neighbors = variable_struct_get_names(self.__graph[$ _from]);
			for (var j = 0; j < array_length(_neighbors); j++)
			{
				var _to = _neighbors[j];
				if (!self.IsDirected() && _from > _to)
					continue ;
				array_push(self.__edge_cache, new Edge(_from, _to, self.__graph[$ _from][$ _to]));
			}
		}
		self.__edge_dirty = false;
		return (variable_clone(self.__edge_cache));
	}

	/// @description Gets the total number of nodes in the graph
	/// @return {Real} Returns node count
	static GetNodeCount = function()
	{
		gml_pragma("forceinline");
		return (self.__node_count);
	}

	/// @description Gets the total number of edges in the graph
	/// @return {Real} Returns edge count
	static GetEdgeCount = function()
	{
		gml_pragma("forceinline");
		return (self.__edge_count);
	}

	/// @description Gets the number of neighbors for a given node
	/// @param {Any} node The node to count neighbors for
	/// @return {Real} Returns neighbor count
	static GetNeighborsCount = function(node)
	{
		gml_pragma("forceinline");
		return (array_length(self.GetNeighbors(node)));
	}

	/// @description Gets the out-degree (number of outgoing edges) of a node
	/// @param {Any} node The node to check
	/// @return {Real} Returns out-degree
	static GetOutDegree = function(node)
	{
		if (!self.HasNode(node))
			self.__throw__($"Node {node} does not exist");
		return (self.GetNeighborsCount(node));
	}

	/// @description Gets the in-degree (number of incoming edges) of a node
	/// @param {Any} node The node to check
	/// @return {Real} Returns in-degree
	static GetInDegree = function(node)
	{
		if (!self.HasNode(node))
			self.__throw__($"Node {node} does not exist");
	
		if (!self.IsDirected())
			return (self.GetOutDegree(node));
	
		var _count = 0;
		var _nodes = self.GetNodes();
		for (var i = 0; i < array_length(_nodes); i++)
		{
			if (self.HasEdge(_nodes[i], node))
				_count++;
		}
		return (_count);
	}

	/// @description Gets the total degree of a node 
	/// (in-degree + out-degree for directed, neighbor count for undirected)
	/// @param {Any} node The node to check
	/// @return {Real} Returns total degree
	static GetDegree = function(node)
	{
		if (!self.HasNode(node))
			self.__throw__($"Node {node} does not exist");
		if (!self.IsDirected())
			return (self.GetNeighborsCount(node));
		else
			return (self.GetInDegree(node) + self.GetOutDegree(node));
	}

	/// @description Finds any path between two nodes using BFS
	/// @param {Any} source The starting node
	/// @param {Any} target The destination node
	/// @return {Array<String>|Undefined} Returns array of nodes forming the path, or undefined if no path exists
	static GetPath = function(source, target)
	{
		if (!self.HasNode(source) || !self.HasNode(target))
			self.__throw__($"Invalid nodes for path {source} to {target}")
		var _bfs_result = self.BFS(source, target);
		if (!__isBFSPathValid(_bfs_result, source, target))
			return (undefined);
		return (__reconstructPath(_bfs_result.previous, source, target))
	}

	/// @description Gets all connected components in the graph
	/// @return {Array<Array<String>>} Returns array of components, each component is an array of node identifiers
	static GetComponents = function()
	{
		if (!self.__structure_dirty)
			return (self.__components_cache);
		self.__components_cache = [];
		var _visited_nodes = {};
		var _nodes = self.GetNodes();
		for (var i = 0; i < array_length(_nodes); i++)
		{
			var _node = _nodes[i];
			if (_visited_nodes[$ _node] != undefined)
				continue ;
			var _bfs_result = self.BFS(_node);
			for (var j = 0; j < array_length(_bfs_result.path); j++)
				_visited_nodes[$ _bfs_result.path[j]] = true;
			array_push(self.__components_cache, _bfs_result.path);
		}
		self.__structure_dirty = false;
		return (self.__components_cache);
	}

	/// @description Gets the number of connected components in the graph
	/// @return {Real} Returns component count
	static GetComponentsCount = function()
	{
		gml_pragma("forceinline");
		return (array_length(self.GetComponents()));
	}

	/// @description Finds the shortest path between two nodes
	/// @param {Any} source The starting node
	/// @param {Any} target The destination node
	/// @return {Array<String>|Undefined} Returns array of nodes forming shortest path, or undefined if no path exists
	static GetShortestPath = function(source, target)
	{
		gml_pragma("forceinline");
		return (self.GetShortestPathData(source, target).path);
	}

	/// @description Gets the shortest distance between two nodes
	/// @param {Any} source The starting node
	/// @param {Any} target The destination node
	/// @return {Real} Returns shortest distance, or infinity if no path exists
	static GetShortestDistance = function(source, target)
	{
		gml_pragma("forceinline");
		return (self.GetShortestPathData(source, target).distance);
	}

	/// @param {Any} source The starting node
	/// @param {Any} target The destination node
	/// @return {Struct} Returns {path: array of nodes or undefined, distance: real or infinity}
	static GetShortestPathData = function(source, target)
	{
		gml_pragma("forceinline");
		return (self.IsWeighted() ?
			self.GetShortestPathDataWeighted(source, target) :
			self.GetShortestPathDataUnweighted(source, target))
	}

	/// @description Gets shortest path data for weighted graphs using Dijkstra's algorithm
	/// @param {Any} source The starting node
	/// @param {Any} target The destination node
	/// @return {Struct} Returns {path: array of nodes or undefined, distance: real or infinity}
	static GetShortestPathDataWeighted = function(source, target)
	{
		if (!self.HasNode(source) || !self.HasNode(target))
			self.__throw__($"Invalid nodes for path {source} to {target}")
		var _result = self.Dijkstra(source, target);
		if (!_result)
			return ({path: undefined, distance: infinity});
		return ({path: __reconstructPath(_result.previous, source, target),
			distance: _result.distances[$ target] ?? infinity});
	}

	/// @description Gets shortest path data for unweighted graphs using BFS
	/// @param {Any} source The starting node
	/// @param {Any} target The destination node
	/// @return {Struct} Returns {path: array of nodes or undefined, distance: real or infinity}
	static GetShortestPathDataUnweighted = function(source, target)
	{
		if (!self.HasNode(source) || !self.HasNode(target))
			self.__throw__($"Invalid nodes for path {source} to {target}")
		var _result = self.BFS(source, target);
		if (!_result)
			return ({path: undefined, distance: infinity});
		var _path = __reconstructPath(_result.previous, source, target);
		return ({path: _path, distance: is_array(_path) ? array_length(_path) - 1 : infinity});
	}

	/// @description Calculates the density of the graph (ratio of actual edges to possible edges)
	/// @return {Real} Returns density value between 0 and 1, or 0 for graphs with 0 or 1 nodes
	static GetDensity = function()
	{
		gml_pragma("forceinline")
		var _n = self.GetNodeCount();
		if (_n <= 1)
			return (0);

		var _divisor = (self.__flags & GraphFlags.GRAPH_ALLOW_SELF_LOOP) ? _n : _n - 1;
		return (self.GetEdgeCount() / (_n * _divisor / (self.IsDirected() ? 1 : 2)));
	}

	static GetCycle = function()
	{
		gml_pragma("forceinline");
		var _state = {};
		var _previous = {};
		var _nodes = self.GetNodes();
		var _search = self.IsDirected() ? self.__DFSGetCycleDirected : self.__DFSGetCycleUndirected;
		for (var i = 0; i < array_length(_nodes); i++)
		{
			var _node = _nodes[i];
			if (!variable_struct_exists(_state, _node))
			{
				var _result = _search(_node, _state, _previous);
				if (_result != undefined)
					return (_result);
			}
		}
		return (undefined);
	}

	static GetRandomNode = function()
	{
		gml_pragma("forceinline");
		return (self.GetNodes()[irandom(self.GetNodeCount())]);
	}

	static GetRandomEdge = function()
	{
		gml_pragma("forceinline");
		return (self.GetEdges()[irandom(self.GetEdgeCount())]);
	}

	static GetDebugID = function()
	{
		gml_pragma("forceinline");
		return (self.__graph_id);
	}

	static GetReversed = function()
	{
		gml_pragma("forceinline");
		if (!self.IsDirected())
			self.__throw__("Can't reverse an undirected graph");
		var _reversed = self.Clone(true).Reverse();
		if (self.IsImmutable())
			_reversed.Freeze();
		return (_reversed);
	}

	#endregion

	#region Export / Import

	static ToDOT = function(name = "G")
	{
		var _buffer = buffer_create(2048, buffer_grow, 1);
		var _directed = self.IsDirected();
		var _weighted = self.IsWeighted();
		var _operator = _directed ? "->" : "--";
		buffer_write(_buffer, buffer_text, $"{_directed ? "digraph" : "graph"} {name} \{\n");
		var _nodes = self.GetNodes();
		for (var i = 0; i < array_length(_nodes); i++)
		{
			var _node = _nodes[i];
			if (self.GetNeighborsCount(_node) == 0)
				buffer_write(_buffer, buffer_text, $"	{_node};\n");
		}
		var _edges = self.GetEdges();
		for (var i = 0; i < array_length(_edges); i++)
		{
			var _edge = _edges[i];
			buffer_write(_buffer, buffer_text, $"	{_edge.from} {_operator} {_edge.to}");
			if (_weighted)
				buffer_write(_buffer, buffer_text, $" [weight={_edge.weight}]");
			buffer_write(_buffer, buffer_text, ";\n");
		}
		buffer_write(_buffer, buffer_text, $"}\n");
		buffer_seek(_buffer, buffer_seek_start, 0);
		var _result = buffer_read(_buffer, buffer_string);
		buffer_delete(_buffer);
		return (_result);
	}

	static ToAdjacencyMatrix = function()
	{
		var _nodes = self.GetNodes();
		array_sort(_nodes, true);
		var _array_y = array_create(self.__node_count);
		for (var _y = 0; _y < self.__node_count; _y++)
		{
			var _array_x = array_create(self.__node_count);
			for (var _x = 0; _x < self.__node_count; _x++)
				_array_x[_x] = self.HasEdge(_x, _y);
			_array_y[_y] = _array_x;
		}
		return (_array_y);
	}

	#endregion

	#region Graph Manipulation

	static Reverse = function()
	{
		if (self.IsImmutable())
			return (self);
		if (!self.IsDirected())
			self.__throw__("Can't reverse an undirected graph");
		var _edges = self.GetEdges();
		self.Clear();
		for (var i = 0; i < array_length(_edges); i++)
		{
			var _edge = _edges[i];
			self.AddEdge(_edge.to, _edge.from, _edge.weight);
		}
		self.__edge_dirty = true;
	    self.__structure_dirty = true;
		return (self);
	}

	/// @description Removes all nodes and edges from the graph (ignored if immutable)
	/// @return {Struct.self} Returns self for method chaining
	static Clear = function()
	{
		if (!self.IsImmutable())
		{
			self.__graph = {};
			self.__edge_count = 0;
			self.__node_count = 0;
			self.__edge_dirty = true;
			self.__structure_dirty = true;
			self.__edge_cache = undefined;
		}
		return (self);
	}

	/// @description Copies all data from another graph into this graph
	/// @param {Struct.self} graph The source graph to copy from
	/// @param {Bool} unfreeze Whether to remove immutable flag after copying
	/// @return {Struct.self} Returns self for method chaining
	static Copy = function(graph, unfreeze = true)
	{
		if (self.IsImmutable())
			return (self);
		if (!is_struct(graph) || !is_instanceof(graph, Graph)) 
			self.__throw__("Graph copy failed, not a graph.");
		var _keys = struct_get_names(graph);
		for (var j = 0; j < array_length(_keys); j++)
		{
			var _k = _keys[j];
			var _value = graph[$ _k];
			
			if (is_struct(_value))
				self[$ _k] = variable_clone(_value);
			else
				self[$ _k] = _value;
		}
		if (unfreeze)
			self.__flags &= ~GraphFlags.GRAPH_IMMUTABLE;
		self.__edge_dirty = true;
		self.__graph_id = Graph.__graph_count++;

		return (self);
	}

	/// @description Creates a deep copy of this graph
	/// @param {Bool} unfreeze Whether to remove immutable flag from the clone
	/// @return {Struct.self} Returns new Graph instance with same structure
	static Clone = function(unfreeze = true)
	{
		var _flags = self.__flags;
		if (unfreeze)
			_flags &= ~GraphFlags.GRAPH_IMMUTABLE;
		var _result = new Graph(_flags);
		var _nodes = self.GetNodes();
		for (var i = 0; i < array_length(_nodes); i++)
		{
			var _from = _nodes[i];
			var _neighbors = self.GetNeighbors(_from);
			for (var j = 0; j < array_length(_neighbors); j++)
			{
				var _to = _neighbors[j];
				if (!self.IsDirected() && _from > _to)
					continue ;
				_result.AddEdge(_from, _to, self.__graph[$ _from][$ _to]);
			}
		}
		return (_result);
	}

	/// @description Makes the graph immutable (read-only), preventing all modifications
	/// @return {Struct.self} Returns self for method chaining
	static Freeze = function()
	{
		gml_pragma("forceinline");
		/*Immutable Graph could be more optimized in the future*/
		self.__flags |= GraphFlags.GRAPH_IMMUTABLE;
		return (self);
	}

	/// @description Removes a node and all its connected edges from the graph
	/// @param {Any} node The node to remove
	/// @return {Struct.self} Returns self for method chaining
	static RemoveNode = function(node)
	{
		if (self.IsImmutable() || !self.HasNode(node))
			return (self);

		var _neighbors = variable_struct_get_names(self.__graph[$ node]);
		var _out_count = array_length(_neighbors);
		if (self.IsDirected())
		{
			var _all_nodes = variable_struct_get_names(self.__graph);
			for (var i = 0; i < array_length(_all_nodes); i++)
			{
				var _from = _all_nodes[i];
				if (_from == node || self.__graph[$ _from][$ node] == undefined)
					continue ;
				variable_struct_remove(self.__graph[$ _from], node);
				self.__edge_count--;
			}
		}
		else
		{
			for (var i = 0; i < _out_count; i++)
				variable_struct_remove(self.__graph[$ _neighbors[i]], node);
		}
		self.__edge_count -= _out_count;
		variable_struct_remove(self.__graph, node);
		self.__node_count--;
		self.__structure_dirty = true;
		self.__edge_dirty = true;
		return (self);
	}

	/// @description Removes multiple nodes from the graph
	/// @param {Array<String>|String...} nodes Array of nodes to remove, or multiple node arguments
	/// @return {Struct.self} Returns self for method chaining
	static RemoveNodes = function(nodes)
	{
		if (self.IsImmutable() || argument_count == 0)
			return (self);
		if (argument_count == 1 && is_array(argument[0]))
		{
			var _array = argument[0];
			for (var i = 0; i < array_length(_array); i++)
				self.RemoveNode(_array[i]);
			return (self);
		}
		for (var i = 0; i < argument_count; i++)
			self.RemoveNode(argument[i]);
		return (self);
	}

	/// @description Removes an edge from the graph. Accepts edge as two arguments, Edge struct, or [from, to] array
	/// @param {Struct.Edge} edge An Edge definition, by array, by struct, or by 2 reals.
	/// @return {Struct.self} Returns self for method chaining
	static RemoveEdge = function()
	{
		gml_pragma("forceinline")
		if (argument_count > 1)
			self.RemoveEdgeArg(argument[0], argument[1]);
		else if (is_struct(argument[0]))
			self.RemoveEdgeStruct(argument[0]);
		else if (is_array(argument[0]))
			self.RemoveEdgeArray(argument[0]);
		return (self);
	}

	/// @description Internal function to remove edge without validation
	/// @param {Any} from Source node
	/// @param {Any} to Target node
	/// @ignore
	static __RemoveEdgeUnsafe = function(from, to)
	{
		gml_pragma("forceinline")
		variable_struct_remove(self.__graph[$ from], to);
		if (!self.IsDirected())
			variable_struct_remove(self.__graph[$ to], from);
		self.__edge_count--;
		self.__edge_dirty = true;
		self.__structure_dirty = true;
	}

	/// @description (Not Recommended) Removes an edge specified by from and to arguments
	/// @param {Any} from Source node
	/// @param {Any} to Target node
	/// @return {Struct.self} Returns self for method chaining
	static RemoveEdgeArg = function(from, to)
	{
		gml_pragma("forceinline")
		if (self.IsImmutable() || !self.HasEdge(from, to))
			return (self);
		self.__RemoveEdgeUnsafe(from, to)
		return (self);
	}

	/// @description (Not Recommended) Removes an edge specified by an Edge struct
	/// @param {Struct.Edge} edge_struct The edge structure with from and to fields
	/// @return {Struct.self} Returns self for method chaining
	static RemoveEdgeStruct = function(_struct)
	{
		gml_pragma("forceinline");
		self.RemoveEdgeArg(_struct.from, _struct.to);
		return (self);
	}

	/// @description (Not Recommended) Removes an edge specified by a [from, to] array
	/// @param {Array<Any>} edge_array Array with [from, to] elements
	/// @return {Struct.self} Returns self for method chaining
	static RemoveEdgeArray = function(_array)
	{
		gml_pragma("forceinline");
		self.RemoveEdgeArg(_array[0], _array[1]);
		return (self);
	}

	/// @description Removes multiple edges from the graph
	/// @param {Struct.Edge...} edges Muliple edges definition, by array, by struct, or by 2 reals.
	/// @return {Struct.self} Returns self for method chaining
	static RemoveEdges = function(edges)
	{
		if (self.IsImmutable() || argument_count == 0)
			return (self);
		if (argument_count == 1 && is_array(argument[0]))
		{
			var _array = argument[0];
			for (var i = 0; i < array_length(_array); i++)
				self.RemoveEdge(_array[i])
			return (self);
		}
		for (var i = 0; i < argument_count; i++)
			self.RemoveEdge(argument[i]);
		return (self);
	}

	/// @description Adds a node to the graph if it doesn't already exist
	/// @param {Any} node The node identifier to add
	/// @return {Struct.self} Returns self for method chaining
	static AddNode = function(node)
	{
		gml_pragma("forceinline");
		if (self.IsImmutable())
			return (self);
		if (node != undefined && !self.__graph[$ node])
		{
			self.__graph[$ node] = {};
			self.__node_count++;
			self.__structure_dirty = true;
		}
		return (self);
	}

	/// @description Adds multiple nodes to the graph
	/// @param {Array<Any>|Any} nodes Array of nodes to add, or multiple node arguments
	/// @return {Struct.self} Returns self for method chaining
	static AddNodes = function()
	{
		if (self.IsImmutable() || argument_count == 0)
			return (self);
		if (argument_count == 1 && is_array(argument[0]))
		{
			var _array = argument[0];
			for (var i = 0; i < array_length(_array); i++)
				self.AddNode(_array[i]);
			return (self);
		}
		for (var i = 0; i < argument_count; i++)
			self.AddNode(argument[i]);
		return (self);
	}

	/// @description Adds an edge to the graph. Accepts edge as two/three arguments, Edge struct, or array
	/// @param {Struct.Edge} edge An Edge definition, by array, by struct, or by 2 reals.
	/// @return {Struct.self} Returns self for method chaining
	static AddEdge = function()
	{
		gml_pragma("forceinline")
		if (argument_count > 1)
			self.AddEdgeArg(argument[0], argument[1], argument_count == 3 ? argument[2] : 1);
		else if (is_struct(argument[0]))
			self.AddEdgeStruct(argument[0]);
		else if (is_array(argument[0]))
			self.AddEdgeArray(argument[0]);
		return (self);
	}

	/// @description (Not Recommended) Adds an edge specified by from and to arguments
	/// @param {Any} from Source node
	/// @param {Any} to Target node
	/// @param {Real} weight Edge weight (weighted graphs only) (default: 1)
	/// @return {Struct.self} Returns self for method chaining
	static AddEdgeArg = function(from, to, weight = 1)
	{
		if (self.IsImmutable() || from == undefined || to == undefined || self.HasEdge(from, to))
			return (self);
		if (from == to && !(self.__flags & GraphFlags.GRAPH_ALLOW_SELF_LOOP))
			self.__throw__("Self referencing edge unallowed by flags");
		if (!self.IsWeighted() && weight != 1)
			self.__throw__("Cannot set weight on unweighted graph");

		self.AddNode(from);
		self.__graph[$ from][$ to] = weight;

		self.AddNode(to);
		if (!self.IsDirected())
			self.__graph[$ to][$ from] = weight;

		self.__edge_count++;
		self.__edge_dirty = true;
		self.__structure_dirty = true;
		return (self);
	}

	/// @description (Not Recommended) Adds an edge specified by a [from, to] or [from, to, weight] array
	/// @param {Array<Any>} edge_array Array with [from, to] or [from, to, weight] elements
	/// @return {Struct.self} Returns self for method chaining
	static AddEdgeArray = function(_array)
	{
		gml_pragma("forceinline");
		self.AddEdgeArg(_array[0], _array[1], array_length(_array) == 3 ? _array[2] : 1);
		return (self);
	}

	/// @description (Not Recommended) Adds an edge specified by an Edge struct or struct with from/to/weight fields
	/// @param {Struct.Edge} edge_struct The edge structure with from, to, and optional weight fields
	/// @return {Struct.self} Returns self for method chaining
	static AddEdgeStruct = function(_struct)
	{
		gml_pragma("forceinline");
		self.AddEdgeArg(_struct[$ "from"], _struct[$ "to"], _struct[$ "weight"] ?? 1);
		return (self)
	}

	/// @description Adds multiple edges to the graph
	/// @param {Struct.Edge...} edges Muliple edges definition, by array, by struct, or by 2 reals.
	/// @return {Struct.self} Returns self for method chaining
	static AddEdges = function(edges)
	{
		if (self.IsImmutable() || argument_count == 0)
			return (self);
		if (argument_count == 1 && is_array(argument[0]))
		{
			var _array = argument[0];
			for (var i = 0; i < array_length(_array); i++)
				self.AddEdge(_array[i]);
			return (self);
		}
		for (var i = 0; i < argument_count; i++)
			self.AddEdge(argument[i]);
		return (self);
	}

	#endregion

	/// @description Internal function to build graph from various input formats
	/// @param {Any} builder Graph, struct with nodes/edges, array, or single node
	/// @param {Array<Any>} args Arguments for builder if its callable
	/// @ignore
	static __build__ = function(builder, args)
	{
		if (is_callable(builder))
			builder(self, args);
		if (is_struct(builder))
		{
			if (builder[$ "nodes"] != undefined)
				self.AddNodes(builder.nodes);
			if (builder[$ "edges"] != undefined)
				self.AddEdges(builder.edges);
			if (is_instanceof(builder, Graph))
				self.Copy(builder, true);
		}
		else if (is_array(builder))
		{
			for (var i = 0; i < array_length(builder); i++)
			{
				var item = builder[i];
				if (is_struct(item))
					self.AddEdgeStruct(item);
				else if (is_array(item))
					self.AddEdgeArray(item);
				else
					self.AddNode(item);
			}
		}
		else
			self.AddNode(builder);
	}

	/// @description Internal function to throw formatted error messages
	/// @param {String} error The error message
	/// @ignore
	static __throw__ = function(error)
	{
		gml_pragma("forceinline");
		/*Didnt used string format because feather gave me strange errors for a reason :c*/
		var _msg = "Error on Graph #" + string(self.__graph_id) + ": " + string(error);
		throw ({message: _msg, longMessage: _msg});
	}
}

/// @description Internal Helper function to validate BFS path result
/// @param {Struct} bfs_result The BFS result structure
/// @param {Any} from Source node
/// @param {Any} to Target node
/// @return {Bool} Returns true if valid path was found
/// @ignore
function __isBFSPathValid(bfs_result, from, to)
{
	gml_pragma("forceinline");
	if (bfs_result == undefined)
		return (false);
	return (array_length(bfs_result.path) > 0 && array_last(bfs_result.path) == to);
}

/// @description Internal Helper function to reconstruct path from BFS/Dijkstra predecessor map
/// @param {Struct} previous Map of nodes to their predecessors
/// @param {Any} source Starting node
/// @param {Any} target Destination node
/// @return {Array<Any>|Undefined} Returns array of nodes forming path, or undefined if no path exists
/// @ignore
function __reconstructPath(previous, source, target)
{
	if (previous[$ target] == undefined && source != target)
		return (undefined);
	var _path = [];
	var _cur = target;
	while (_cur != undefined)
	{
		array_insert(_path, 0, _cur);
		_cur = previous[$ _cur];
	}
	return (_path);
}

enum __GraphColor
{
	WHITE, //unvisited
	GRAY, //in recursion
	BLACK //completly visited
}
