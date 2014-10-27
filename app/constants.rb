class Constants

  # Defined constants throughout the application
  DEBUG = false
  # View constants
  module Front
    Left = 0
    Up = 1
    Right = 2
    Bottom = 3
  end
  GOLD = UIColor.colorWithRed(0xd8/255.0, green: 0xd8/255.0, blue: 0, alpha: 1.0)
  LIGHT_GRAY = UIColor.colorWithRed(0.95, green: 0.95, blue: 0.95, alpha: 1.0)
  GRAY = UIColor.colorWithRed(0.8, green: 0.8, blue: 0.85, alpha: 1.0)
  LIGHT_BLUE_GRAY = UIColor.colorWithRed(0.9, green: 0.9, blue: 0.95, alpha: 1.0)
  BUTTON_TINT_COLOR = UIColor.redColor
  MESSAGE_COLOURS = ['black', 'white', 'red', 'green', 'blue', 'cyan', 'yellow', 'orange', 'purple', 'brown']
  BACKGROUND_COLOUR_LIST = [
          UIColor.colorWithRed(153/255.0, green: 153/255.0, blue: 255/255.0, alpha: 1.0),
          UIColor.colorWithRed(255/255.0, green: 153/255.0, blue: 153/255.0, alpha: 1.0),
          UIColor.colorWithRed(255/255.0, green: 204/255.0, blue: 153/255.0, alpha: 1.0),
          UIColor.colorWithRed(255/255.0, green: 255/255.0, blue: 153/255.0, alpha: 1.0),
          UIColor.colorWithRed(153/255.0, green: 255/255.0, blue: 153/255.0, alpha: 1.0),       
          UIColor.colorWithRed(204/255.0, green: 153/255.0, blue: 255/255.0, alpha: 1.0),
          UIColor.colorWithRed(224/255.0, green: 224/255.0, blue: 224/255.0, alpha: 1.0)
      ]  
  
  ICON_LABEL_FONT_SIZE = 12
  INSTRUCTION_LABEL_FONT_SIZE = 15
  GENERAL_BUTTON_FONT_SIZE = 19

  paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, true)
  BUNDLE_ROOT = paths.objectAtIndex(0) # Get the docs directory
  DOCUMENT_PATH = paths.objectAtIndex(0) # Get the docs directory
  

  # Sound constants
  SOUND_NAMES = []
  
  dirContents = NSFileManager.defaultManager.directoryContentsAtPath(NSBundle.mainBundle.bundlePath)
  dirContents.each do |fileName|
    if fileName.hasSuffix(".wav") || fileName.hasSuffix(".mp3")
      SOUND_NAMES << fileName
    end
  end

  MAX_CONVEX_HULL_POINTS = 12
  DEFAULT_GRAVITY_X = 0
  DEFAULT_GRAVITY_Y = -4

  # when using touch to draw scene and toys
  MAGNITUDE_DISTANCE_BETWEEN_POINTS = 3.0
  MAX_CONTROLLED_POINTS_FOR_A_CURVE = 25
  SMALL_BSPLINE_STEPS = 5.0

  SMALLER_SIZED_SAVED_SCENE = 0.35
  SMALL_GAP = 7       #pixels to display borders on scene
  SMALL_MARGIN = 10   #pixels

  # transition effects between scenes
  TRANSITION_EFFECT = SKTransition.revealWithDirection( SKTransitionDirectionLeft,  duration: 1.5 ) # for how many seconds 

  GENERAL_TOY_FORCE = 100000
  RANDOM_HASH_KEY = 99999
  MOVE_TOWARDS_AND_AWAY_SPEED = 500 #pixels per second
  TIME_AFTER_EXPLOSION = 1.0 # seconds
  TIME_FOR_MESSAGE_TO_SEND = 3.0

  IFIZZ_INTRODUCTION_TEXT =""

end