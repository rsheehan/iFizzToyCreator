# Holds the information on the scene.
# This includes toys, edges and backgrounds (eventually)

# TODO: separate the edge and background stuff into BackgroundTemplate
class SceneTemplate

  attr_reader :toys, :edges, :actions

  def initialize(toys, edges, actions, identifier)
    @identifier = identifier
    @toys = toys    # each of type ToyInScene
    @edges = edges  # each of type ToyPart - either Circle or Points
    @actions = actions   # each a Hash
    puts "SceneTemplate actions"
    p actions
    # possibly create an image of the scene for the scene box view
  end

  # Turns the SceneTemplate into json compatible data.
  def to_json_compatible
    json_scene = {}
    json_scene[:id] = @identifier
    # the toys are represented by their identifiers
    json_toys = []
    @toys.each do |toy|
      json_toys << toy.to_json_compatible
    end
    json_scene[:toys] = json_toys
    json_edges = []
    @edges.each do |edge_part|
      json_edges << edge_part.to_json_compatible
    end
    json_scene[:edges] = json_edges
    json_scene
  end

end