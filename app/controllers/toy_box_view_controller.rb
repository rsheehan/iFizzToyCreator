class ToyBoxViewController < UIViewController

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
    @collection_view.registerClass(ToyButton, forCellWithReuseIdentifier: TOYBUTTON)
    @collection_view.registerClass(DeleteToyButton, forCellWithReuseIdentifier: DELETETOYBUTTON)
    @collection_view.registerClass(CopyToyButton, forCellWithReuseIdentifier: COPYTOYBUTTON)

    @collection_view.dataSource = self
    @collection_view.delegate = self
    view.addSubview(@collection_view)
    #setup delete button

    @copy_mode = false
    @copy_button = UIButton.buttonWithType(UIButtonTypeCustom)
    @copy_button.setImage(UIImage.imageNamed(:copy), forState: UIControlStateNormal)
    @copy_button.sizeToFit
    @copy_button.frame = [ [LITTLE_GAP, LITTLE_GAP+BIG_GAP*2], @copy_button.frame.size]
    @copy_button.addTarget(self, action: :copy, forControlEvents: UIControlEventTouchUpInside)
    view.addSubview(@copy_button)

    @delete_mode = false
    @del_button = UIButton.buttonWithType(UIButtonTypeCustom)
    @del_button.setImage(UIImage.imageNamed(:trash), forState: UIControlStateNormal)
    @del_button.sizeToFit
    @del_button.frame = [ [LITTLE_GAP, LITTLE_GAP+BIG_GAP*4], @del_button.frame.size]
    @del_button.addTarget(self, action: :delete, forControlEvents: UIControlEventTouchUpInside)
    view.addSubview(@del_button)

  end

  def setup_button(image_name, position)
    #p 'setup button'
    button = UIButton.buttonWithType(UIButtonTypeCustom)
    button.setImage(UIImage.imageNamed(image_name), forState: UIControlStateNormal)
    #button.setTitle(image_name)
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
    @state.toys.each do |toy|
      if toy.identifier == Constants::SCENE_TOY_IDENTIFIER
        sceneToy = toy.clone
        @state.toys.delete(toy)
        @state.toys << sceneToy
        break
      end
    end
  end

  def viewDidAppear(animated)
    #add gesture recognizer to close window on tap outside
    @recognizer = UITapGestureRecognizer.alloc.initWithTarget(self, action: 'handleTapOutside:')
    @recognizer.cancelsTouchesInView = false
    @recognizer.numberOfTapsRequired = 1
    view.window.addGestureRecognizer(@recognizer)
  end

  # Back to the ToyCreator to make a new one.
  def back
    self.view.window.removeGestureRecognizer(@recognizer)
    @delegate.close_toybox
  end

  #activate delete mode
  def delete
    #p "delete toy button pressed"
    if @delete_mode
      @delete_mode = false
      #set image
      @del_button.setImage(UIImage.imageNamed(:trash), forState: UIControlStateNormal)
    else
      @delete_mode = true
      #set image
      @del_button.setImage(UIImage.imageNamed(:done), forState: UIControlStateNormal)

      @copy_mode = false
      #set image
      @copy_button.setImage(UIImage.imageNamed(:copy), forState: UIControlStateNormal)
    end

    #update cells
    @collection_view.reloadData()

  end

  #activate copy mode
  def copy
    p "copy toy button pressed"

    if @copy_mode
      @copy_mode = false
      #set image
      @copy_button.setImage(UIImage.imageNamed(:copy), forState: UIControlStateNormal)
    else
      @copy_mode = true
      #set image
      @copy_button.setImage(UIImage.imageNamed(:done), forState: UIControlStateNormal)

      @delete_mode = false
      #set image
      @del_button.setImage(UIImage.imageNamed(:trash), forState: UIControlStateNormal)
    end

    #update cells
    @collection_view.reloadData()

  end

  def delete_toy(sender)
    p "delete toy process"
    index_path = @collection_view.indexPathForCell(sender.superview);
    @state.toys.delete_at(index_path.row)
    @collection_view.deleteItemsAtIndexPaths([index_path])
  end

  def copy_toy(sender)
    p "copy toy process"
    index_path = @collection_view.indexPathForCell(sender.superview);
    toy = @state.toys[index_path.row]
    p "toy = #{toy}"

    toyCopied = ToyTemplate.new(toy.parts, (rand(2**60).to_s))
    @state.toys.insert(index_path.row, toyCopied)

    @collection_view.reloadData()

    #@state.toys.delete_at(index_path.row)
    #@collection_view.deleteItemsAtIndexPaths([index_path])
  end

  # The methods to implement the UICollectionViewDataSource protocol.

  TOYBUTTON = "ToyButton"
  DELETETOYBUTTON = "DeleteToyButton"
  COPYTOYBUTTON = "CopyToyButton"

  def collectionView(cv, numberOfItemsInSection: section)
    @state.toys.length
  end

  def collectionView(cv, cellForItemAtIndexPath: index_path)
    item = index_path.row # ignore section as only one
    if @delete_mode or @copy_mode
      # toy_button is UICollecctionViewCell

      if @delete_mode
        toy_button = cv.dequeueReusableCellWithReuseIdentifier(DELETETOYBUTTON, forIndexPath: index_path)
        toy_button.layer.removeAllAnimations
        animateToyButton(toy_button,0,false)
        toy_button.del_toy_button.addTarget(self, action: 'delete_toy:', forControlEvents: UIControlEventTouchUpInside)
      elsif @copy_mode
        toy_button = cv.dequeueReusableCellWithReuseIdentifier(COPYTOYBUTTON, forIndexPath: index_path)
        toy_button.layer.removeAllAnimations
        animateToyButton(toy_button,0,false)
        toy_button.copy_toy_button.addTarget(self, action: 'copy_toy:', forControlEvents: UIControlEventTouchUpInside)
      end
    else
      # toy_button is UICollecctionViewCell
      toy_button = cv.dequeueReusableCellWithReuseIdentifier(TOYBUTTON, forIndexPath: index_path)
    end

    # add some border to the toys
    #toy_button.layer.borderWidth = 3.0
    #toy_button.layer.borderColor = UIColor.blackColor.CGColor
    #toy_button.backgroundColor = UIColor.whiteColor
    @state.toys[item].update_image
    toy_button.toy = @state.toys[item]
    toy_button.accessibilityLabel = item.to_s

    if @state.toys[item].identifier == Constants::SCENE_TOY_IDENTIFIER
    #if item == @state.toys.size - 1
      toy_button.hidden = true
    else
      toy_button.hidden = false
    end

    toy_button

  end

  def animateToyButton(button,rotation,decreasing)
    timeStamp = Time.now.usec/50000.0
    rotation = Math.cos(timeStamp)/50.0

    UIView.animateWithDuration(0.00001,
                               delay: 0.05,
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
    @state.toys[item].image.size
  end

  def collectionView(cv, layout: layout, insetForSectionAtIndex: section)
    UIEdgeInsetsMake(5, 5, 5, 5)
  end

  # And the methods for the UICollectionViewDelegate protocol.
  def collectionView(cv, didSelectItemAtIndexPath: index_path)
    item = index_path.row
    if not @delete_mode
      self.view.window.removeGestureRecognizer(@recognizer)
      @delegate.drop_toy(item)
    end
  end

  # handleTapOutside
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