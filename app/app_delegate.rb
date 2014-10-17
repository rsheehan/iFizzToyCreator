class AppDelegate
  def application(application, didFinishLaunchingWithOptions: launchOptions)

    application.applicationSupportsShakeToEdit = true
    application.setStatusBarHidden(true, withAnimation:UIStatusBarAnimationSlide)
    @window = UIWindow.alloc.initWithFrame(UIScreen.mainScreen.bounds)
    @uiMainTab = UITabBarControllerLandscape.alloc.init
    @window.rootViewController = @uiMainTab
    @window.makeKeyAndVisible # do this early otherwise some of the dimensions are wrong

    # Setting of some global properties
    UIButton.appearance.setTintColor(Constants::BUTTON_TINT_COLOR)
    UIButton.appearance.setFont(UIFont.systemFontOfSize(Constants::GENERAL_BUTTON_FONT_SIZE))

    #temporary used

    # temporaryImage = UIImage.imageNamed("bground.jpg")
    # backgroundImageData = UIImageJPEGRepresentation(temporaryImage, 1.0)
    #encodedData = [backgroundImageData].pack("m")

    #string = encodedData.to_s
    
    #data = string.unpack("m")

    # File.open("#{Constants::DOCUMENT_PATH}/temporary.jpg", "w+b") do |f|
    #     f.write(backgroundImageData)
    # end
    
    # p "#{Constants::DOCUMENT_PATH}/temporary.jpg"
    # newImage = UIImage.imageNamed("#{Constants::DOCUMENT_PATH}/temporary.jpg")
    # puts newImage

    # File.open("#{Constants::DOCUMENT_PATH}/temporary.txt", "w+b") do |f|
    #   f.write("awData.to_s")
    # end
   
    true
  end
end

