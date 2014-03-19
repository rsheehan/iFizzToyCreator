# The view for the play stuff.
# Includes the PlayScene

# CURRENTLY NOT USED
# using a straight SKView instead
class PlayView < SKView

  def initWithFrame(frame)
    super
    self.showsDrawCount = true
    self.showsNodeCount = true
    self.showsFPS = true
    self
  end

end