class SceneBoxViewController < UIViewController

  attr_writer :delegate

  LITTLE_GAP = 10
  BIG_GAP = 40
  WIDTH = 768

  def loadView
    # Do not call super.
    self.view = UIView.alloc.initWithFrame([[0, 0], [WIDTH, WIDTH]])
    view.backgroundColor =  Constants::LIGHT_BLUE_GRAY
    setup_button(:back, [LITTLE_GAP, LITTLE_GAP])
    @collection_view = UICollectionView.alloc.initWithFrame([[@current_xpos, 0], [WIDTH - @current_xpos, WIDTH]], collectionViewLayout: UICollectionViewFlowLayout.alloc.init)
    @collection_view.backgroundColor =  Constants::LIGHT_BLUE_GRAY
    @collection_view.registerClass(ToyButton, forCellWithReuseIdentifier: SCENEBUTTON)
    @collection_view.registerClass(DeleteToyButton, forCellWithReuseIdentifier: DELETESCENEBUTTON)
    @collection_view.dataSource = self
    @collection_view.delegate = self
    view.addSubview(@collection_view)
    #setup delete button

    @delete_mode = false
    @del_button = UIButton.buttonWithType(UIButtonTypeCustom)
    @del_button.setImage(UIImage.imageNamed(:trash), forState: UIControlStateNormal)
    @del_button.sizeToFit
    @del_button.frame = [ [LITTLE_GAP, LITTLE_GAP+BIG_GAP*2], @del_button.frame.size]
    @del_button.addTarget(self, action: :delete, forControlEvents: UIControlEventTouchUpInside)
    view.addSubview(@del_button)
  end

  def setup_button(image_name, position)
    button = UIButton.buttonWithType(UIButtonTypeCustom)
    button.setImage(UIImage.imageNamed(image_name), forState: UIControlStateNormal)
    button.sizeToFit
    button.frame = [position, button.frame.size]
    button.addTarget(self, action: image_name, forControlEvents: UIControlEventTouchUpInside)
    view.addSubview(button)
    frame = button.frame
    @current_xpos = @left_margin = frame.origin.x + frame.size.width + BIG_GAP
    @right_margin = WIDTH - LITTLE_GAP
    @next_ypos = @current_ypos = LITTLE_GAP
  end

  # We need this to gain access to the toys.
  def state=(state)
    @state = state
    @delegate.save_scene
  end

  def viewDidAppear(animated)
    #add gesture recognizer to close window on tap outside
    @recognizer = UITapGestureRecognizer.alloc.initWithTarget(self, action: 'handleTapOutside:')
    @recognizer.cancelsTouchesInView = false
    @recognizer.numberOfTapsRequired = 1
    view.window.addGestureRecognizer(@recognizer)
  end

  # Back to the previous screen.
  def back
    self.view.window.removeGestureRecognizer(@recognizer)
    @delegate.close_toybox
  end


  #activate delete mode
  def delete
    if @delete_mode
      @delete_mode = false
      #set image
      @del_button.setImage(UIImage.imageNamed(:trash), forState: UIControlStateNormal)
    else
      @delete_mode = true
      #set image
      @del_button.setImage(UIImage.imageNamed(:done), forState: UIControlStateNormal)
    end
    #update cells
    @collection_view.reloadData()

  end

  def delete_scene(sender)
    index_path = @collection_view.indexPathForCell(sender.superview);
    @state.scenes.delete_at(index_path.row)
    @collection_view.deleteItemsAtIndexPaths([index_path])
    @collection_view.reloadData()
    @state.save
  end

  # The methods to implement the UICollectionViewDataSource protocol.

  SCENEBUTTON = "ToyButton"
  DELETESCENEBUTTON = "DeleteToyButton"

  def collectionView(cv, numberOfItemsInSection: section)
    @state.scenes.length
  end

  def collectionView(cv, cellForItemAtIndexPath: index_path)
    item = index_path.row # ignore section as only one
    if @delete_mode
      scene_button = cv.dequeueReusableCellWithReuseIdentifier(DELETESCENEBUTTON, forIndexPath: index_path)
      scene_button.layer.removeAllAnimations
      animateToyButton(scene_button,0,false)
      scene_button.del_toy_button.addTarget(self, action: 'delete_scene:', forControlEvents: UIControlEventTouchUpInside)
    else
      scene_button = cv.dequeueReusableCellWithReuseIdentifier(SCENEBUTTON, forIndexPath: index_path)
    end
    # make sure scene image is up to date
    @state.scenes[item].update_image
    scene_button.toy = @state.scenes[item]
    scene_button

  end

  def animateToyButton(button,rotation,decreasing)

    timeStamp = Time.now.usec/50000.0
    rotation = Math.cos(timeStamp)/50.0

    UIView.animateWithDuration(0.00001,
                               delay: 0,
                               options: UIViewAnimationOptionAllowUserInteraction,
                               animations: lambda {
                                 button.transform = CGAffineTransformMakeRotation(rotation)
                               },
                               completion:lambda {|finished|
                                 animateToyButton(button,rotation,decreasing)
                               }
    )
  end

  # And the methods for the UICollectionViewDelegateFlowLayout protocol.
  # Without this the size of the cells are the default.
  def collectionView(cv, layout: layout, sizeForItemAtIndexPath: index_path)
    item = index_path.row
    @state.scenes[item].image.size
  end

  def collectionView(cv, layout: layout, insetForSectionAtIndex: section)
    UIEdgeInsetsMake(5, 5, 5, 5)
  end

  # And the methods for the UICollectionViewDelegate protocol.
  def collectionView(cv, didSelectItemAtIndexPath: index_path)
    item = index_path.row
    if not @delete_mode
      self.view.window.removeGestureRecognizer(@recognizer)
      @delegate.drop_scene(item)
    end
  end

  def handleTapOutside(sender)
    # if (sender.state == UIGestureRecognizerStateEnded)
    #   location = sender.locationInView(nil) #Passing nil gives us coordinates in the window
    #   #Then we convert the tap's location into the local view's coordinate system, and test to see if it's in or outside. If outside, dismiss the view.
    #   if (!self.view.pointInside(self.view.convertPoint(location, fromView:self.view.window), withEvent:nil))
    #     # Remove the recognizer first so it's view.window is valid.
    #     self.view.window.removeGestureRecognizer(sender)
    #     self.dismissModalViewControllerAnimated(true)
    #   end
    # end
  end
end