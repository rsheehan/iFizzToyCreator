class CollectionViewPopoverViewController < UIViewController

    attr_writer :delegate, :selected, :scene_creator_view_controller
    attr_accessor :mode
    LITTLE_GAP = 10
    BIG_GAP = 40
    WIDTH = 350
    MAX_HEIGHT = 500

    ACTIONS = [:touch, :timer, :collision, :shake, :score_reaches, :when_created, :loud_noise, :toy_touch]
    EFFECTS = [:apply_force, :explosion, :apply_torque, :create_new_toy, :delete_effect, :score_adder, :play_sound, :text_bubble, :scene_shift]
    TOYBUTTON = "ToyButton"

    def loadView
      # Do not call super.
      self.view = UIView.alloc.initWithFrame([[0, 0], [WIDTH, MAX_HEIGHT]])
      view.backgroundColor =  UIColor.colorWithRed(0.9, green: 0.9, blue: 0.95, alpha: 1.0)

      #default mode value
      if @mode.nil?
        @mode = :actions
      end

      #back button
      @back_button = UIButton.buttonWithType(UIButtonTypeCustom)
      @back_button.setImage(UIImage.imageNamed(:back_arrow), forState: UIControlStateNormal)
      @back_button.frame = [[5, 5], [30,30]]
      @back_button.addTarget(self, action: 'back:', forControlEvents: UIControlEventTouchUpInside)
      view.addSubview(@back_button)

      @margin = @back_button.frame.size.width

      #title
      @title = UILabel.alloc.initWithFrame([[@margin+5,5],[WIDTH-@margin-5,30]])
      if @title_text
        @title.setText(@title_text)
      else
        @title.setText(Language::CHOOSE_TRIGGER)
      end
      @title.setBackgroundColor(UIColor.colorWithRed(0.9, green: 0.9, blue: 0.95, alpha: 1.0))
      @title.setFont(UIFont.boldSystemFontOfSize(18))
      view.addSubview(@title)

      #title separator
      separator = CALayer.layer
      separator.frame = CGRectMake(5, 35.0, WIDTH, 1.0)
      separator.backgroundColor = UIColor.colorWithWhite(0.8, alpha:1.0).CGColor
      self.view.layer.addSublayer(separator)

      @col_view = UICollectionView.alloc.initWithFrame([[0, 40], [WIDTH, WIDTH]], collectionViewLayout: UICollectionViewFlowLayout.alloc.init)
      @col_view.backgroundColor =  UIColor.colorWithRed(0.9, green: 0.9, blue: 0.95, alpha: 1.0)
      @col_view.registerClass(ImageCell, forCellWithReuseIdentifier: "ImgCell")
      @col_view.registerClass(ToyButton, forCellWithReuseIdentifier: TOYBUTTON)
      @col_view.dataSource = self
      @col_view.delegate = self
      view.addSubview(@col_view)

      self.preferredContentSize = [WIDTH, [@col_view.frame.origin.y+@col_view.frame.size.height+5, MAX_HEIGHT].min ]

    end

    def setTitle(text)
      @title_text = text
      if @title
        @title.setText(text)
      end
    end

    # We need this to gain access to the toys.
    def state=(state)
      @state = state
    end

    # Back to the Select toy screen.
    def back(sender)
      if @state
        @state.save
      end
      @delegate.action_flow_back
    end

    # The methods to implement the UICollectionViewDataSource protocol.
    def collectionView(cv, numberOfItemsInSection: section)
      case @mode
        when :effects
          return EFFECTS.size
        when :toys
          @state.toys.length
        else
          return ACTIONS.size
      end
    end

    # Setting up individual buttons in the view
    def collectionView(cv, cellForItemAtIndexPath: index_path)
      item = index_path.row # ignore section as only one

      case @mode
        when :effects
          cell = cv.dequeueReusableCellWithReuseIdentifier("ImgCell", forIndexPath: index_path)
          cell.image = UIImage.imageNamed(EFFECTS[item])
          cell.text = name_for_label(EFFECTS[item])
        when :toys
          cell = cv.dequeueReusableCellWithReuseIdentifier("ImgCell", forIndexPath: index_path)
          @state.toys[item].update_image
          cell.image = @state.toys[item].image
        else
          cell = cv.dequeueReusableCellWithReuseIdentifier("ImgCell", forIndexPath: index_path)
          cell.image = UIImage.imageNamed(ACTIONS[item])
          cell.text = name_for_label(ACTIONS[item])
      end

      cell
    end

    # And the methods for the UICollectionViewDelegateFlowLayout protocol.
    # Without this the size of the cells are the default.
    def collectionView(cv, layout: layout, sizeForItemAtIndexPath: index_path)
      item = index_path.row
      case @mode
        when :effects
          img_size = UIImage.imageNamed(EFFECTS[item]).size
          CGSizeMake(img_size.width,img_size.height+10)
        when :toys
          CGSizeMake(75,75)
        else
          img_size = UIImage.imageNamed(ACTIONS[item]).size
          CGSizeMake(img_size.width,img_size.height+10)
      end
    end

    def collectionView(cv, layout: layout, insetForSectionAtIndex: section)
      UIEdgeInsetsMake(5, 5, 5, 5)
    end

    # And the methods for the UICollectionViewDelegate protocol.
    def collectionView(cv, didSelectItemAtIndexPath: index_path)
      item = index_path.row
      case @mode
        when :effects
          @delegate.makeEffect(EFFECTS[item])
        when :toys
          @delegate.chose_toy(item)
        else
          @delegate.makeTrigger(ACTIONS[item])
      end
    end

    def name_for_label(name)
      case name
        when :touch
          Language::TOUCH
        when :collision
          Language::COLLISION
        when :timer
          Language::REPEAT
        when :hold
          Language::HOLD
        when :shake
          Language::SHAKE
        when :when_created
          Language::WHEN_CREATED
        when :loud_noise
          Language::LOUD_NOISE
        when :toy_touch
          Language::TOY_TOUCH
        when :score_reaches
          Language::SCORE_REACHES
        when :apply_force
          Language::FORCE
        when :apply_torque
          Language::ROTATION
        when :explosion
          Language::EXPLOSION
        when :create_new_toy
          Language::CREATE_NEW_TOY
        when :delete_effect
          Language::DELETE
        when :score_adder
          Language::SCORE_ADDER
        when :play_sound
          Language::PLAY_SOUND
        when :text_bubble
          Language::TEXT_BUBBLE
        when :scene_shift
          Language::SCENE_SHIFT
      end
    end

end