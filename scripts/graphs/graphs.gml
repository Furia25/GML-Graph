
enum GraphFlags
{
	GRAPH_NONE					= 0,
	GRAPH_DIRECTED				= 1 << 0,
	GRAPH_WEIGHTED				= 1 << 1,
	GRAPH_ALLOW_SELF_LOOP		= 1 << 2,
	GRAPH_IMMUTABLE				= 1 << 3,
	GRAPH_ALL					= GraphFlags.GRAPH_DIRECTED | GraphFlags.GRAPH_WEIGHTED | GraphFlags.GRAPH_ALLOW_SELF_LOOP | GraphFlags.GRAPH_IMMUTABLE
};

function Edge(from, to, weight = 1) constructor
{
	self.from = from;
	self.to = to;
	self.weight = weight;
}

function Graph(flags, builder = undefined) constructor
{
	self.__flags = flags
	self.__flags &= ~GraphFlags.GRAPH_IMMUTABLE;

	self.__graph = {};
	self.__in_edges = {};
	self.__edge_count = 0;
	self.__node_count = 0;

	if (builder != undefined)
		self.__build__(builder);
	self.__flags = flags;
	if (self.IsImmutable())
		self.Freeze();

	#region Algorithm

	static BFS = function(source, target = undefined, callback = undefined)
	{
		if (!self.HasNode(source))
			return (undefined);
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
		return ({visited: _result, previous: _previous});
	}

	static Dijkstra = function(source, target = undefined)
	{
		if (!self.HasNode(source) || (target != undefined && !self.HasNode(target)))
			return (undefined);
		var _prev = {};
		var _distances = {};
		var _visited = {};
		var _queue = ds_priority_create();

		_distances[$ source] = 0;
		ds_priority_add(_queue, source, 0);

		while (!ds_priority_empty(_queue))
		{
			var _u = ds_priority_delete_min(_queue);
			if (_visited[$ _u]) continue ;
			_visited[$ _u] = true;

			if (_u == target) break ;

			var _neighbors = self.GetNeighbors(_u);
			for (var i = 0; i < array_length(_neighbors); i++)
			{
				var _v = _neighbors[i];
				if (_visited[$ _v]) continue ;
				var _weight = self.__graph[$ _u][$ _v];
				if (_weight < 0)
				{
					ds_priority_destroy(_queue);
					return (undefined);
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
		return ({distances: _distances, previous: _prev});
	}

	#endregion

	#region Checks

	static IsDirected = function()
	{
		gml_pragma("forceinline");
		return (self.__flags & GraphFlags.GRAPH_DIRECTED) != 0;
	}
	
	static IsImmutable = function()
	{
		gml_pragma("forceinline");
		return (self.__flags & GraphFlags.GRAPH_IMMUTABLE) != 0;
	}

	static IsWeighted = function()
	{
		gml_pragma("forceinline");
		return (self.__flags & GraphFlags.GRAPH_WEIGHTED) != 0;
	}

	static HasNode = function(node)
	{
		gml_pragma("forceinline");
		return (self.__graph[$ node] != undefined);
	}

	static HasEdge = function(from, to)
	{
		gml_pragma("forceinline");
		return (self.__graph[$ from] != undefined && (self.__graph[$ from][$ to] != undefined));
	}

	static HasPath = function(from, to)
	{
		gml_pragma("forceinline");
		return (__isBFSPathValid(self.BFS(from, to), from, to));
	}

	static IsConnected = function()
	{
		gml_pragma("forceinline");
		return (self.GetComponentsCount() == 1);
	}

	#endregion

	#region Getters / Setters

	static GetEdge = function(from, to)
	{
		gml_pragma("forceinline");
		return (self.HasEdge(from, to) ? new Edge(from, to, self.__graph[$ from][$ to]) : undefined);
	}
	
	static GetWeight = function(from, to)
	{
		gml_pragma("forceinline");
		if (!self.HasEdge(from, to))
			throw ("Edge does not exist");
		return (self.__graph[$ from][$ to]);
	}

	static SetWeight = function (from, to, weight)
	{
		if (self.IsImmutable() || !self.IsWeighted() || !self.HasEdge(from, to))
			return (self);
		self.__graph[$ from][$ to] = weight;
		if (!self.IsDirected())
			self.__graph[$ to][$ from] = weight;
		return (self);
	}

	static GetNodes = function()
	{
		gml_pragma("forceinline");
		return (variable_struct_get_names(self.__graph));
	}

	static GetNeighbors = function(node)
	{
		gml_pragma("forceinline");
		return (self.HasNode(node) ? variable_struct_get_names(self.__graph[$ node]) : []);
	}

	static GetEdges = function()
	{
		var _edges = [];
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
				array_push(_edges, new Edge(_from, _to, self.__graph[$ _from][$ _to]));
			}
		}
		return (_edges);
	}

	static GetNodeCount = function()
	{
		gml_pragma("forceinline");
		return (self.__node_count);
	}

	static GetEdgeCount = function()
	{
		gml_pragma("forceinline");
		return (self.__edge_count);
	}

	static GetNeighborsCount = function(node)
	{
		gml_pragma("forceinline");
		return (array_length(self.GetNeighbors(node)));
	}

	static GetOutDegree = function(node)
	{
		if (!self.HasNode(node))
			return (0);
		return (self.GetNeighborsCount(node));
	}

	static GetInDegree = function(node)
	{
		if (!self.HasNode(node))
			return (0);
		var _nodes = self.GetNodes();
		var _count = 0;
		for (var i = 0; i < array_length(_nodes); i++)
		{
			var _from = _nodes[i];
			if (self.HasEdge(_from, node))
				_count += 1;
		}
		return (_count);
	}

	static GetDegree = function(node)
	{
		if (!self.HasNode(node))
			return (0);
		if (!self.IsDirected())
			return (self.GetNeighborsCount(node));
		else
			return (self.GetInDegree(node) + self.GetOutDegree(node));
	}

	static GetPath = function(source, target)
	{
		var _bfs_result = self.BFS(source, target);
		if (!__isBFSPathValid(_bfs_result, source, target))
			return (undefined);
		return (__reconstructPath(_bfs_result.previous, source, target))
	}

	static GetComponents = function()
	{
		var _components = [];
		var _visited_nodes = {};
		var _nodes = self.GetNodes();
		for (var i = 0; i < array_length(_nodes); i++)
		{
			var _node = _nodes[i];
			if (_visited_nodes[$ _node] != undefined)
				continue ;
			var _bfs_result = self.BFS(_node);
			for (var j = 0; j < array_length(_bfs_result.visited); j++)
				_visited_nodes[$ _bfs_result.visited[j]] = true;
			array_push(_components, _bfs_result.visited);
		}
		return (_components);
	}

	static GetComponentsCount = function()
	{
		gml_pragma("forceinline");
		return (array_length(self.GetComponents()));
	}

	static GetShortestPath = function(source, target)
	{
		gml_pragma("forceinline");
		return (self.GetShortestPathData(source, target).path);
	}

	static GetShortestDistance = function(source, target)
	{
		gml_pragma("forceinline");
		return (self.GetShortestPathData(source, target).distance);
	}

	static GetShortestPathData = function(source, target)
	{
		gml_pragma("forceinline");
		return (self.IsWeighted() ?
			self.GetShortestPathDataWeighted(source, target) :
			self.GetShortestPathDataUnweighted(source, target))
	}

	static GetShortestPathDataWeighted = function(source, target)
	{
		gml_pragma("forceinline");
		var _result = self.Dijkstra(source, target);
		if (!_result)
			return ({path: undefined, distance: -1});
		return ({path: __reconstructPath(_result.previous, source, target),
			distance: _result.distances[$ target] ?? -1});
	}

	static GetShortestPathDataUnweighted = function(source, target)
	{
		gml_pragma("forceinline");
		var _result = self.BFS(source, target);
		if (!_result)
			return ({path: undefined, distance: -1});
		var _path = __reconstructPath(_result.previous, source, target);
		return ({path: _path, distance: is_array(_path) ? array_length(_path) - 1 : -1});
	}

	#endregion

	#region Graph Manipulation

	static Clear = function()
	{
		gml_pragma("forceinline");
		if (!self.IsImmutable())
		{
			self.__graph = {};
			self.__edge_count = 0;
			self.__node_count = 0;
		}
		return (self);
	}

	static Copy = function(graph, unfreeze = true)
	{
		if (self.IsImmutable() || !is_struct(graph) || !is_instanceof(graph, Graph)) 
			return (self);
		var _keys = struct_get_names(graph);
		for (var j = 0; j < array_length(_keys); j++)
		{
			var _k = _keys[j];
			self[$ _k] = graph[$ _k];
		}
		if (unfreeze)
			self.__flags &= ~GraphFlags.GRAPH_IMMUTABLE;
		return (self);
	}

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

	static Freeze = function()
	{
		gml_pragma("forceinline");
		/*Immutable Graph could be optimized in the future*/
		self.__flags |= GraphFlags.GRAPH_IMMUTABLE;
		return (self);
	}

	static RemoveNode = function(node)
	{
		if (self.IsImmutable() || !self.HasNode(node))
			return (self);
		var _nodes = self.GetNodes();
		for (var i = 0; i < array_length(_nodes); i++)
		{
			var _other = _nodes[i];
			if (_other == node)
				continue;
			self.RemoveEdgeArg(_other, node);
		}
		if (self.IsDirected())
		{
			var _neighbors = self.GetNeighbors(node);
			for (var i = 0; i < array_length(_neighbors); i++)
				self.RemoveEdgeArg(node, _neighbors[i]);
		}
		variable_struct_remove(self.__graph, node);
		self.__node_count--;
		return (self);
	}

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

	static RemoveEdgeArg = function(from, to)
	{
		if (self.IsImmutable() || !self.HasEdge(from, to))
			return (self);
		if (self.__graph[$ from])
			variable_struct_remove(self.__graph[$ from], to);
		if (!self.IsDirected() && self.__graph[$ to])
			variable_struct_remove(self.__graph[$ to], from)
		self.__edge_count--;
		return (self);
	}

	static RemoveEdgeStruct = function(_struct)
	{
		gml_pragma("forceinline");
		self.RemoveEdgeArg(_struct.from, _struct.to);
		return (self);
	}

	static RemoveEdgeArray = function(_array)
	{
		gml_pragma("forceinline");
		self.RemoveEdgeArg(_array[0], _array[1]);
		return (self);
	}

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

	static AddNode = function(node)
	{
		gml_pragma("forceinline");
		if (self.IsImmutable())
			return (self);
		if (node != undefined && !self.__graph[$ node])
		{
			self.__graph[$ node] = {};
			self.__node_count++;
		}
		return (self);
	}

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

	static AddEdgeArg = function(from, to, weight = 1)
	{
		if (self.IsImmutable() || from == undefined || to == undefined || self.HasEdge(from, to))
			return (self);
		if (from == to && !(self.__flags & GraphFlags.GRAPH_ALLOW_SELF_LOOP))
			return (self);
		if (!self.IsWeighted())
			weight = 1;

		self.AddNode(from);
		self.__graph[$ from][$ to] = weight;

		self.AddNode(to);
		if (!self.IsDirected())
			self.__graph[$ to][$ from] = weight;
		self.__edge_count++;
		return (self);
	}

	static AddEdgeArray = function(_array)
	{
		gml_pragma("forceinline");
		self.AddEdgeArg(_array[0], _array[1], array_length(_array) == 3 ? _array[2] : 1);
		return (self);
	}

	static AddEdgeStruct = function(_struct)
	{
		gml_pragma("forceinline");
		self.AddEdgeArg(_struct[$ "from"], _struct[$ "to"], _struct[$ "weight"] ?? 1);
		return (self)
	}

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

	static __build__ = function(builder)
	{
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
}

function __isBFSPathValid(bfs_result, from, to)
{
	gml_pragma("forceinline");
	if (bfs_result == undefined)
		return (false);
	return (array_length(bfs_result.visited) > 0 && bfs_result.visited[array_length(bfs_result.visited) - 1] == to);
}

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
