class GameInfo
  attr_accessor :name, :description
  def initialize(name=Constants::GAME_DEFAULT_NAME, description=Constants::GAME_DEFAULT_DESCRIPTION)
    @name = name
    @description = description
  end
  # Turns the BackgroundTemplate into json compatible data.
  def to_json_compatible
    json_game_info = {}
    json_game_info[:name] = @name
    json_game_info[:description] = @description
    json_game_info
  end
end