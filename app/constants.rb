class Constants

  # Defined constants throughout the application
  
  GOLD = UIColor.colorWithRed(0xd8/255.0, green: 0xd8/255.0, blue: 0, alpha: 1)
  module Front
    Left = 0
    Up = 1
    Right = 2
    Bottom = 3
  end
  SOUND_NAMES = ['marble_drop.wav', 'here_we_go.wav', 'explosion_single_large.mp3']
  DEBUG = false

  # used for convex hull
  MAX_CONVEX_HULL_POINTS = 12

  DEFAULT_GRAVITY_X = 0
  DEFAULT_GRAVITY_Y = -4

  # when using touch to draw scene and toys
  MAGNITUDE_DISTANCE_BETWEEN_POINTS = 7.0
  MAX_CONTROLLED_POINTS_FOR_A_CURVE = 20
  SMALL_BSPLINE_STEPS = 5.0

  # used when
  SMALLER_SIZED_SAVED_SCENE = 0.35
  SMALL_GAP = 2

  # transition effects between scenes
  TRANSITION_EFFECT = SKTransition.revealWithDirection( SKTransitionDirectionLeft,  duration: 1 ) # for how many seconds

end