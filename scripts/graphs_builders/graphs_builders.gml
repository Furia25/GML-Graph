
/// @description GraphRandom
/// @param {real} flags Graph flags
/// @param {real} nodes_count Number of nodes
/// @param {real} p Probability of edge creation (0-1)
/// @param {real} min_weight Minimum edge weight (optional, default 1)
/// @param {real} max_weight Maximum edge weight (optional, default 10)
function GraphRandom(flags, nodes_count, p, min_weight = 1, max_weight = 10)
{
	var _graph = new Graph(flags);
	var _probability = clamp(p, 0, 1);
	for (var i = 0; i < nodes_count; i++)
		_graph.AddNode(i);
	for (var i = 0; i < nodes_count; i++)
	{
		for (var j = 0; j < nodes_count; j++)
		{
			if (i == j && !(flags & GraphFlags.GRAPH_ALLOW_SELF_LOOP))
				continue ;
			if (random(1) < _probability)
				_graph.AddEdge(i, j, _graph.IsWeighted() ? random_range(min_weight, max_weight) : 1);
		}
	}
	return (_graph);
}

function GraphCycle(flags, nodes_count, min_weight = 1, max_weight = 10)
{
	var _graph = new Graph(flags);
	for (var i = 0; i < nodes_count; i++)
	{
		var _next = (i + 1) % nodes_count;
		_graph.AddEdge(i, _next, _graph.IsWeighted() ? random_range(min_weight, max_weight) : 1);
	}
	return (_graph);
}

function GraphPath(flags, nodes_count, min_weight = 1, max_weight = 10)
{
	var _graph = new Graph(flags);
	for (var i = 0; i < nodes_count; i++)
		_graph.AddEdge(i, i + 1, _graph.IsWeighted() ? random_range(min_weight, max_weight) : 1);
	return (_graph);
}

function GraphGrid(flags, rows, cols, diag = false, min_weight = 1, max_weight = 10)
{
	var _graph = new Graph(flags);
	for (var _y = 0; _y < rows; _y++)
	{
		for (var _x = 0; _x < cols; _x++)
		{
			var _node = $"{_x}:{_y}";
			var _left = _x == 0;
			var _right = _y == cols - 1;
			var _top = _y == 0;
			var _bot = _x == rows - 1;
			var _weight = _graph.IsWeighted() ? random_range(min_weight, max_weight) : 1;
			_graph.AddNodes(_node);
			if (!_top)
				_graph.AddEdge(_node, $"{_x }:{_y - 1}", _weight);
			if (!_bot)
				_graph.AddEdge(_node, $"{_x}:{_y + 1}", _weight);
			if (!_left)
				_graph.AddEdge(_node, $"{_x - 1}:{_y}", _weight);
			if (!_right)
				_graph.AddEdge(_node, $"{_x + 1}:{_y}", _weight);
			if (diag && !_top && !_left)
				_graph.AddEdge(_node, $"{_x - 1}:{_y - 1}", _weight);
			if (diag && !_bot && !_right)
				_graph.AddEdge(_node, $"{_x + 1}:{_y + 1}", _weight);
		}
	}
}
