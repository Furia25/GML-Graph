<p align="center">
    <img alt="GML-Graph-icon" src="https://github.com/user-attachments/assets/bb995962-9021-4df3-a1bf-e457bb640033" width="25%"/>
</p>

# Graph Library for GameMaker
A comprehensive graph data structure implementation for the latest versions of GameMaker Studio 2. This project aims to provide the most complete set of graph theory features and algorithms possible, while serving as a practical exploration of graph theory concepts.

## Features
This library offers a wide range of graph operations including:
- Multiple graph types (directed, weighted, immutable)
- Classic graph algorithms (BFS, DFS, Dijkstra, pathfinding)
- Cycle detection and topological sorting
- Graph manipulation and analysis tools
- Export capabilities (DOT format, adjacency matrix)

The goal is to continuously expand functionality to cover as much of graph theory as practical for game development.

## Installation
Download the latest `.yymps` package from the [Releases](../../releases) page and import it into your GameMaker project.

## Quick Start

### Basic Example
```gml
// Create an undirected, unweighted graph
var graph = new Graph(GraphFlags.GRAPH_NONE);

// Add some nodes and edges
graph.AddEdge("A", "B");
graph.AddEdge("B", "C");
graph.AddEdge("C", "D");

// Find a path
var path = graph.GetPath("A", "D");
show_debug_message(path); // ["A", "B", "C", "D"]
```

### Using Graph Flags
Flags control the behavior and properties of your graph:

```gml
// Directed graph (edges have direction: A → B is different from B → A)
var directed = new Graph(GraphFlags.GRAPH_DIRECTED);
directed.AddEdge("A", "B");  // Only A → B exists, not B → A

// Weighted graph (edges have numeric weights)
var weighted = new Graph(GraphFlags.GRAPH_WEIGHTED);
weighted.AddEdge("A", "B", 5);   // Edge with weight 5
weighted.AddEdge("B", "C", 10);  // Edge with weight 10

// Combine flags with bitwise OR
var complex = new Graph(GraphFlags.GRAPH_DIRECTED | GraphFlags.GRAPH_WEIGHTED);
complex.AddEdge("Start", "End", 3.5);

// Allow self-loops (node connecting to itself)
var loops = new Graph(GraphFlags.GRAPH_ALLOW_SELF_LOOP);
loops.AddEdge("A", "A");  // Valid!

// Immutable graph (read-only after creation)
var readonly = new Graph(GraphFlags.GRAPH_IMMUTABLE, {
    edges: [["A", "B"], ["B", "C"]]
});
// readonly.AddEdge(...) would be ignored
```

The library supports method chaining for clean, readable code:
```gml
var graph = new Graph(GraphFlags.GRAPH_NONE)
    .AddEdge("A", "B")
    .AddEdge("B", "C")
    .AddEdge("C", "A");
```

## Documentation
I would love to create comprehensive documentation for this library, but unfortunately I don't have the time to do so at the moment. The code is well-commented with JSDoc annotations, which should help you understand how to use each method.

**Any help with documentation would be greatly appreciated!** If you'd like to contribute examples, tutorials, or reference documentation, please feel free to submit a pull request.

## Contributing
All contributions are welcome! Whether it's:
- Bug fixes and optimizations
- New graph algorithms or features
- Documentation and examples
- Performance improvements
- Code reviews and suggestions
- An entire refactor of the codebase

Feel free to open issues or submit pull requests. Your help in making this library better is greatly appreciated!

## Performance
While this library strives for efficiency, it will never be perfect. Any contributions, optimizations, or suggestions to improve performance are greatly appreciated!

## License
[MIT License](LICENSE) - Free to use in commercial and non-commercial projects.
