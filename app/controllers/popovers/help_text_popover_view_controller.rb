class HelpPopoverViewController < UIViewController

  attr_writer :delegate

  def loadView
    super
    @width = self.view.frame.size.width
    @height = self.view.frame.size.height
    # Do not call super.
    self.view = UIView.alloc.initWithFrame([[0, 0], [@width, @height]])
    view.backgroundColor =  UIColor.blackColor

    #back button
    @back_button = UIButton.buttonWithType(UIButtonTypeCustom)
    @back_button.setImage(UIImage.imageNamed(:back_arrow), forState: UIControlStateNormal)
    @back_button.frame = [[5, 5], [20,20]]

    @margin = @back_button.frame.size.width
    self.preferredContentSize = CGSizeMake(@width,@height)

    local_file = NSURL.fileURLWithPath(File.join(NSBundle.mainBundle.resourcePath, "screenShot.mov"))

    @player = MPMoviePlayerController.alloc.initWithContentURL(local_file)
    @player.view.frame = CGRectMake((@width-800)/2,15,800,600)
    view.addSubview(@player.view)
    @player.play

  end

  def setInstruction(text)
  end

  def getInstruction
  end

  def resizeViews
  end

end