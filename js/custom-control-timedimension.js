/* custom timedimension control */

L.Control.TimeDimensionCustom = L.Control.TimeDimension.include({
  /* override getDisplayDateFormat to only output UTC year and onth */
  _getDisplayDateFormat: function(date) {
    var month_names = [
      "Jan", "Feb", "Mar", "Apr", "May", "Jun",
      "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
    return (
      month_names[date.getUTCMonth()] + ' ' +
      date.getUTCFullYear().toString());
  },

  /* overriding update basically only so i can update my story bit bar with
     animations */
  _update: function() {
    if (!this._timeDimension) {
      return;
    }
    if (this._timeDimension.getCurrentTimeIndex() >= 0) {
      var date = new Date(this._timeDimension.getCurrentTime());
      if (this._displayDate) {
        L.DomUtil.removeClass(this._displayDate, 'loading');
        this._displayDate.innerHTML = this._getDisplayDateFormat(date);
        // also (sneakily) update my story element!
        document.getElementById('story-bitbar-td').innerHTML =
          this._getDisplayDateFormat(date);
      }
      if (this._sliderTime && !this._slidingTimeSlider) {
        this._sliderTime.setValue(this._timeDimension.getCurrentTimeIndex());
      }
    } else {
      if (this._displayDate) {
        this._displayDate.innerHTML = this._getDisplayNoTimeError();
      }
    }
  },

  /* override for fluid slider width */
  _createSliderTime: function(className, container) {
    var sliderContainer,
        sliderbar,
        max,
        knob, limits;
    sliderContainer = L.DomUtil.create('div', className, container);
    /*L.DomEvent
        .addListener(sliderContainer, 'click', L.DomEvent.stopPropagation)
        .addListener(sliderContainer, 'click', L.DomEvent.preventDefault);*/

    sliderbar = L.DomUtil.create('div', 'slider', sliderContainer);
    max = this._timeDimension.getAvailableTimes().length - 1;

    if (this.options.limitSliders) {
        limits = this._limitKnobs = this._createLimitKnobs(sliderbar);
    }
    knob = new L.UI.Knob(sliderbar, {
        className: 'knob main',
        rangeMin: 0,
        rangeMax: max
    });
    knob.on('dragend', function(e) {
        var value = e.target.getValue();
        this._sliderTimeValueChanged(value);
        this._slidingTimeSlider = false;
    }, this);
    knob.on('drag', function(e) {
        this._slidingTimeSlider = true;
        var time = this._timeDimension.getAvailableTimes()[e.target.getValue()];
        if (time) {
            var date = new Date(time);
            if (this._displayDate) {
              this._displayDate.innerHTML = this._getDisplayDateFormat(date);
            }
            if (this.options.timeSliderDragUpdate){
                this._sliderTimeValueChanged(e.target.getValue());
            }
        }
    }, this);

    knob.on('predrag', function() {
        var minPosition, maxPosition;
        if (limits) {
            //limits the position between lower and upper knobs
            minPosition = limits[0].getPosition();
            maxPosition = limits[1].getPosition();
            if (this._newPos.x < minPosition) {
                this._newPos.x = minPosition;
            }
            if (this._newPos.x > maxPosition) {
                this._newPos.x = maxPosition;
            }
        }
    }, knob);
    L.DomEvent.on(sliderbar, 'click', function(e) {
        if (L.DomUtil.hasClass(e.target, 'knob')) {
            return; //prevent value changes on drag release
        }
        var first = (e.touches && e.touches.length === 1 ? e.touches[0] : e),
            x = L.DomEvent.getMousePosition(first, sliderbar).x;
        if (limits) { // limits exits
            if (limits[0].getPosition() <= x && x <= limits[1].getPosition()) {
                knob.setPosition(x);
                this._sliderTimeValueChanged(knob.getValue());
            }
        } else {
            knob.setPosition(x);
            this._sliderTimeValueChanged(knob.getValue());
        }

    }, this);

    /* my addition: on map resize, recalculate slider and knob. can assue a map
       b/c this fn gets called by onAdd */
    L.DomEvent.on(this._map, 'resize', function() {
      // css is enough for the _main_ sliderbar; just need to handle the knob
      console.log('Knob value: ' + knob.getValue());
      console.log('Knob position: ' + knob.getPosition());
      console.log('Knob min: ' + knob.getMinValue());
      console.log('Knob max: ' + knob.getMaxValue());
      console.log('sliderContainer...');
      console.log(L.DomUtil.getStyle(sliderContainer, 'width'));
      // knob.setPosition(knob.getPosition());

      // okay, need to use a fixed width in css to ake this work. start w/ 100px
      // var kno
      var knob_value = knob.getValue();
      sliderbar.style.width = L.DomUtil.getStyle(sliderContainer, 'width');
      knob.setValue(knob_value);
      
      
    }, this);
    knob.setPosition(0);
    
    return knob;
  },

  addTo: function() {
    //To be notified AFTER the component was added to the DOM
    L.Control.prototype.addTo.apply(this, arguments);

    // get a handle to the slider container via the entire control's container
    var sliderContainer;
    for (i = 0; i < this._container.children.length; i++) {
      console.log(this._container.children[i].classList);
      if (this._container.children[i].classList.contains('timecontrol-slider'))
        sliderContainer = this._container.children[i];
    }
    // get the knob's current value, then update the sliderbar, then the knob
    var knob_value = this._sliderTime.getValue();
    sliderContainer.firstChild.style.width =
      L.DomUtil.getStyle(sliderContainer, 'width');
    this._sliderTime.setValue(knob_value);

    this._onPlayerStateChange();
    this._onTimeLimitsChanged();
    this._update();
    return this;
  }
});

L.Map.addInitHook(function() {
  if (this.options.timeDimensionControl) {
    this.timeDimensionControl = new L.Control.TimeDimensionCustom(this.options.timeDimensionControlOptions || {});
    // this.addControl(this.timeDimensionControl);
  }
});
