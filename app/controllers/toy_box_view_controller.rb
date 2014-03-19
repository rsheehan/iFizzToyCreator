class ToyBoxViewController < UIViewController

  attr_writer :delegate

  LITTLE_GAP = 10
  BIG_GAP = 40
  WIDTH = 768

  def loadView
    # Do not call super.
    self.view = UIView.alloc.initWithFrame([[0, 0], [WIDTH, WIDTH]])
    view.backgroundColor =  UIColor.colorWithRed(0.9, green: 0.9, blue: 0.95, alpha: 1.0)
    setup_button(:new, [LITTLE_GAP, LITTLE_GAP])
    collection_view = UICollectionView.alloc.initWithFrame([[@current_xpos, 0], [WIDTH - @current_xpos, WIDTH]], collectionViewLayout: UICollectionViewFlowLayout.alloc.init)
    collection_view.backgroundColor =  UIColor.colorWithRed(0.9, green: 0.9, blue: 0.95, alpha: 1.0)
    collection_view.registerClass(ToyButton, forCellWithReuseIdentifier: TOYBUTTON)
    collection_view.dataSource = self
    collection_view.delegate = self
    view.addSubview(collection_view)
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
  end

  #def process_row_of_buttons(row_of_buttons)
  #  row_of_buttons.each do |row_button|
  #    size = row_button.frame.size
  #    x = row_button.frame.origin.x
  #    y = (row_button.frame.origin.y + @next_ypos - BIG_GAP)/2 - size.height/2
  #    row_button.frame = [[x, y], size]
  #    row_button.addTarget(@delegate, action: 'drop_toy:', forControlEvents: UIControlEventTouchUpInside)
  #    view.addSubview(row_button)
  #  end
  #end

  # Back to the ToyCreator to make a new one.
  def new
    @delegate.close_toybox
  end

  ## Jump from here to the SceneCreator.
  #def scene
  #
  #end

  # The methods to implement the UICollectionViewDataSource protocol.

  TOYBUTTON = "ToyButton"

  def collectionView(cv, numberOfItemsInSection: section)
    @state.toys.length
  end

  def collectionView(cv, cellForItemAtIndexPath: index_path)
    item = index_path.row # ignore section as only one
    toy_button = cv.dequeueReusableCellWithReuseIdentifier(TOYBUTTON, forIndexPath: index_path)
    toy_button.toy = @state.toys[item]
    toy_button
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
    @delegate.drop_toy(item)
  end

end