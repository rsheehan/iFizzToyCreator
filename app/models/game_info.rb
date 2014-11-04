class GameInfo

  attr_accessor :name, :description

  def initialize(name="Untitled", description="No description yet")
    @name = name
    @description = description
    p "new game = #{name} and description = #{description}"
  end

  # Turns the BackgroundTemplate into json compatible data.
  def to_json_compatible
    json_game_info = {}
    json_game_info[:name] = @name
    json_game_info[:description] = @description

    json_game_info
  end

end