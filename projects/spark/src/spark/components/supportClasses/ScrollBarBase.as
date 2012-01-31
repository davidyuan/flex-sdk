////////////////////////////////////////////////////////////////////////////////
//
//  ADOBE SYSTEMS INCORPORATED
//  Copyright 2008 Adobe Systems Incorporated
//  All Rights Reserved.
//
//  NOTICE: Adobe permits you to use, modify, and distribute this file
//  in accordance with the terms of the license agreement accompanying it.
//
////////////////////////////////////////////////////////////////////////////////

package spark.components.supportClasses
{

import flash.events.Event;
import flash.events.MouseEvent;
import flash.events.TimerEvent;
import flash.geom.Point;
import flash.utils.Timer;

import mx.events.FlexEvent;
import mx.events.PropertyChangeEvent;
import mx.events.ResizeEvent;
import mx.events.SandboxMouseEvent;

import spark.components.Button;
import spark.core.IViewport;
import spark.effects.SimpleMotionPath;
import spark.effects.animation.Animation;
import spark.effects.easing.IEaser;
import spark.effects.easing.Linear;
import spark.effects.easing.Sine;

/**
 *  @copy spark.components.supportClasses.GroupBase#symbolColor
 *  
 *  @langversion 3.0
 *  @playerversion Flash 10
 *  @playerversion AIR 1.5
 *  @productversion Flex 4
 */ 
[Style(name="symbolColor", type="uint", format="Color", inherit="yes", theme="spark")]

/**
 *  Number of milliseconds after the first page event
 *  until subsequent page events occur.
 * 
 *  @default 500
 *  
 *  @langversion 3.0
 *  @playerversion Flash 10
 *  @playerversion AIR 1.5
 *  @productversion Flex 4
 */
[Style(name="repeatDelay", type="Number", format="Time", inherit="no")]

/**
 *  Number of milliseconds between page events
 *  if the user presses and holds the mouse on the track.
 *  
 *  @default 35
 *  
 *  @langversion 3.0
 *  @playerversion Flash 10
 *  @playerversion AIR 1.5
 *  @productversion Flex 4
 */
[Style(name="repeatInterval", type="Number", format="Time", inherit="no")]

/**
 *  The ScrollBar class helps to position
 *  the portion of data that is displayed when there is too much data
 *  to fit in a display area. 
 *  The ScrollBar class displays a pair of scrollbars and a viewport. 
 *  A viewport is a UIComponent that implements IViewport, such as Group.
 *  
 *  <p>This control extends the TrackBase class and
 *  is the base class for the HScrollBar and VScrollBar
 *  controls.</p> 
 * 
 *  <p>A scroll bar consists of a track, a variable-size scroll thumb, and 
 *  two optional arrow buttons. The ScrollBar class uses four parameters 
 *  to calculate its display state:</p>
 *
 *  <ul>
 *    <li><code>minimum</code>: Minimum range value.</li>
 *    <li><code>maximum</code>:Maximum range value.</li>
 *    <li><code>value</code>: Current position, which must be within the
 *    minimum and maximum range values.</li>
 *    <li>Viewport size: Represents the number of items
 *    in the range that you can display at one time. The
 *    number of items must be less than or equal to the 
 *    range, where the range is the set of values between
 *    the minimum range value and the maximum range value.</li>
 *  </ul>
 *
 *  @see spark.core.IViewport
 *  @see spark.skins.default.ScrollerSkin
 *  @see spark.skins.default.ScrollBarDownButtonSkin
 *  @see spark.skins.default.ScrollBarLeftButtonSkin
 *  @see spark.skins.default.ScrollBarRightButtonSkin
 *  @see spark.skins.default.ScrollBarUpButtonSkin
 *  
 *  @langversion 3.0
 *  @playerversion Flash 10
 *  @playerversion AIR 1.5
 *  @productversion Flex 4
 */
public class ScrollBar extends TrackBase
{
    include "../../core/Version.as";

    //--------------------------------------------------------------------------
    //
    //  Class constants
    //
    //--------------------------------------------------------------------------

    //--------------------------------------------------------------------------
    //
    //  Constructor
    //
    //--------------------------------------------------------------------------

    /**
     *  Constructor. 
     *  
     *  @langversion 3.0
     *  @playerversion Flash 10
     *  @playerversion AIR 1.5
     *  @productversion Flex 4
     */
    public function ScrollBar():void
    {
        super();
    }

    //--------------------------------------------------------------------------
    //
    // Skins
    //
    //--------------------------------------------------------------------------

    [SkinPart(required="false")]
    
    /**
     *  An optional skin part that defines a button 
     *  that, when pressed, steps the scrollbar up. 
     *  This is equivalent to a decreasing step to the <code>value</code> property.
     *  
     *  @langversion 3.0
     *  @playerversion Flash 10
     *  @playerversion AIR 1.5
     *  @productversion Flex 4
     */
    public var decrementButton:Button;
    
    [SkinPart(required="false")]
    
    /**
     *  An optional skin part that defines a button 
     *  that, when pressed, steps the scrollbar down.
     *  This is equivalent
     *  to an increasing step to the <code>value</code> property.
     *  
     *  @langversion 3.0
     *  @playerversion Flash 10
     *  @playerversion AIR 1.5
     *  @productversion Flex 4
     */
    public var incrementButton:Button;
    
    //--------------------------------------------------------------------------
    //
    //  Variables
    //
    //--------------------------------------------------------------------------

    /**
     * @private
     * this one animator is used by both paging and stepping animations. It
     * is responsible for running the repeated operation (animating from the beginning
     * of the repeat to whenever it ends or the user stops the repeating action).
     */
    private var _animator:Animation = null;
    private function get animator():Animation
    {
        if (_animator)
            return _animator;
        _animator = new Animation();
        var animTarget:AnimationTarget = new AnimationTarget(animationUpdateHandler);
        animTarget.endFunction = animationEndHandler;
        _animator.animationTarget = animTarget;
        return _animator;
    }

    /**
     * @private
     * These variables track whether we are currently involved in a stepping
     * animation, and which direction we are stepping
     */
    private var steppingDown:Boolean;
    private var steppingUp:Boolean;

    /**
     * @private
     * This variable tracks whether we are currently running an animation to
     * do a single page() operation. This is used to end that operation properly
     * if another operation interrupts it.
     */ 
    private var animatingSinglePage:Boolean;
    
    
    private static var easyInLinearEaser:IEaser = new Linear(.1);
    private static var deceleratingSineEaser:IEaser = new Sine(0);
    
    // TODO: transient?    
    // Direction indicator for current track-scrolling operations
    private var trackScrollDown:Boolean;
    
    // Timer used for repeated scrolling when mouse is held down on track
    private var trackScrollTimer:Timer;
    
    // TODO: transient?    
    // Cache current position on track for scrolling operations
    private var trackPosition:Point = new Point();
    
    // TODO: transient?    
    // Flag to indicate whether track-scrolling is in process
    private var trackScrolling:Boolean = false;
    
    //--------------------------------------------------------------------------
    //
    //  Overridden properties: Range
    //
    //--------------------------------------------------------------------------
    
    /**
     *  @inheritDoc
     *  
     *  @langversion 3.0
     *  @playerversion Flash 10
     *  @playerversion AIR 1.5
     *  @productversion Flex 4
     */
     override public function set valueInterval(value:Number):void
    {
        super.valueInterval = value;
        
        // setting valueInterval may change the pageSize
        pageSizeChanged = true;
    }

    //--------------------------------------------------------------------------
    //
    // Properties
    //
    //--------------------------------------------------------------------------
    
    //---------------------------------
    // smoothScrolling
    //--------------------------------- 
    /**
     * This property determines the default value <code>smoothScrolling</code>
     * for all ScrollBars.
     * 
     * @default true
     * @langversion 3.0
     * @playerversion Flash 10
     * @playerversion AIR 1.5
     * @productversion Flex 4
     * @see #smoothScrolling
     */
    public static var smoothScrollingDefault:Boolean = true;
    
    //---------------------------------
    // smoothScrolling
    //--------------------------------- 
    
    /**
     * @private
     * Backing storage for the smoothScrolling property
     */
    private var _smoothScrolling:Boolean = smoothScrollingDefault;
    
    /**
     * This property determines whether the scrollbar will animate
     * smoothly when paging and stepping. When false, page and step
     * operations will jump directly to the paged/stepped locations. 
     * When true, the scrollbar, and any content it is scrolling, will
     * animate to that location.
     *
     * @default true
     *
     * @langversion 3.0
     * @playerversion Flash 10
     * @playerversion AIR 1.5
     * @productversion Flex 4      
     */
    public function get smoothScrolling():Boolean
    {
        return _smoothScrolling;
    }
    
    public function set smoothScrolling(value:Boolean):void
    {
        _smoothScrolling = value;
    }
    
    //---------------------------------
    // fixedThumbSize
    //--------------------------------- 
    
    private var _fixedThumbSize:Boolean = false;
    
    /**
     *  If true, the thumb's size along the scrollbar's axis will be
     *  its preferred size.
     *    
     *  @default false
     *  @see #calculateThumbSize
     * 
     *  @langversion 3.0
     *  @playerversion Flash 10
     *  @playerversion AIR 1.5
     *  @productversion Flex 4
     */
    public function get fixedThumbSize():Boolean
    {
        return _fixedThumbSize;
    }
    
    /**
     *  @private
     */
    public function set fixedThumbSize(value:Boolean):void
    {
        if (value == _fixedThumbSize)
            return;
            
        _fixedThumbSize = value;
        invalidateSize();
        invalidateDisplayList();
    }

    //---------------------------------
    // pageSize
    //--------------------------------- 

    private var _pageSize:Number = 20;

    private var pageSizeChanged:Boolean = false;

    /**
     *  The change in the value of the <code>value</code> property 
     *  when you call the <code>page()</code> method.
     *
     *  @default 20
     *  
     *  @langversion 3.0
     *  @playerversion Flash 10
     *  @playerversion AIR 1.5
     *  @productversion Flex 4
     */
    public function get pageSize():Number
    {
        return _pageSize;
    }

    /**
     *  @private
     */
    public function set pageSize(value:Number):void
    {
        if (value == _pageSize)
            return;
            
        _pageSize = value;
        pageSizeChanged = true;
        
        invalidateProperties();
        invalidateDisplayList();
    }
    
    //----------------------------------
    //  viewport
    //----------------------------------    

    private var _viewport:IViewport;
    
    /**
     *  The viewport controlled by this scrollbar.
     * 
     *  If a viewport is specified, then changes to its actual size, content 
     *  size, and scroll position cause the corresponding ScrollBar methods to
     *  run:
     *  <ul>
     *  <li><code>viewportResizeHandler()</code></li>
     *  <li><code>contentWidthChangeHandler()</code></li>
     *  <li><code>contentHeightChangeHandler()</code></li>
     *  <li><code>viewportVerticalScrollPositionChangeHandler()</code></li>
     *  <li><code>viewportHorizontalScrollPositionChangeHandler()</code></li>
     *  </ul>
     * 
     *  <p>The VScrollBar and HScrollBar classes override these methods to 
     *  keep their <code>pageSize</code>, <code>maximum</code>, and <code>value</code> properties in sync with the
     *  viewport.   Similarly, they override their <code>page()</code> and <code>step()</code> methods to
     *  use the viewport's <code>scrollPositionDelta</code> methods to compute page and
     *  and step offsets.</p>
     *    
     *  @default null
     *  @see spark.components.VScrollBar
     *  @see spark.components.HScrollBar
     *
     *  
     *  @langversion 3.0
     *  @playerversion Flash 10
     *  @playerversion AIR 1.5
     *  @productversion Flex 4
     */
    public function get viewport():IViewport
    {
        return _viewport;
    }
    
    /**
     *  @private
     */
    public function set viewport(value:IViewport):void
    {
        if (value == _viewport)
            return;
            
        if (_viewport)  // old _viewport
        {
            _viewport.removeEventListener(PropertyChangeEvent.PROPERTY_CHANGE, viewport_propertyChangeHandler);
            _viewport.removeEventListener(ResizeEvent.RESIZE, viewportResizeHandler);
            _viewport.clipAndEnableScrolling = false;
        }

        _viewport = value;

        if (_viewport)  // new _viewport
        {
            _viewport.addEventListener(PropertyChangeEvent.PROPERTY_CHANGE, viewport_propertyChangeHandler);
            _viewport.addEventListener(ResizeEvent.RESIZE, viewportResizeHandler);
            _viewport.clipAndEnableScrolling = true;
        }
    }
    
    //--------------------------------------------------------------------------
    //
    // Methods
    //
    //--------------------------------------------------------------------------

    /**
     *  @private
     */
    private function startAnimation(duration:Number, valueTo:Number, 
        easer:IEaser, startDelay:Number = 0):void
    {
        animator.stop();
        animator.duration = duration;
        animator.easer = easer;
        animator.motionPaths = [new SimpleMotionPath("value", value, valueTo)];
        animator.startDelay = startDelay;
        animator.play();
    }
    
    /**
     *  @private
     */
    override protected function commitProperties():void
    {
        super.commitProperties();
        
        if (pageSizeChanged)
        {
            if (valueInterval != 0)
                _pageSize = nearestValidInterval(_pageSize, valueInterval);
            
            pageSizeChanged = false;
        }
    }
    
    /**
     *  @private
     */    
    override protected function partAdded(partName:String, instance:Object):void
    {
        super.partAdded(partName, instance);
        
        if (instance == decrementButton)
        {
            decrementButton.addEventListener(FlexEvent.BUTTON_DOWN,
                                             button_buttonDownHandler);
            decrementButton.addEventListener(MouseEvent.ROLL_OVER,
                                             button_rollOverHandler);
            decrementButton.addEventListener(MouseEvent.ROLL_OUT,
                                             button_rollOutHandler);
            decrementButton.autoRepeat = true;
        }
        else if (instance == incrementButton)
        {
            incrementButton.addEventListener(FlexEvent.BUTTON_DOWN,
                                             button_buttonDownHandler);
            incrementButton.addEventListener(MouseEvent.ROLL_OVER,
                                             button_rollOverHandler);
            incrementButton.addEventListener(MouseEvent.ROLL_OUT,
                                             button_rollOutHandler);
            incrementButton.autoRepeat = true;
        }
        else if (instance == track)
        {
            track.addEventListener(MouseEvent.ROLL_OVER,
                                   track_rollOverHandler);
            track.addEventListener(MouseEvent.ROLL_OUT,
                                   track_rollOutHandler);
        }
    }

    /**
     *  @private
     */    
    override protected function partRemoved(partName:String, instance:Object):void
    {
        super.partRemoved(partName, instance);
        
        if (instance == decrementButton)
        {
            decrementButton.removeEventListener(FlexEvent.BUTTON_DOWN,
                                                button_buttonDownHandler);
            decrementButton.removeEventListener(MouseEvent.ROLL_OVER,
                                                button_rollOverHandler);
            decrementButton.removeEventListener(MouseEvent.ROLL_OUT,
                                                button_rollOutHandler);
        }
        else if (instance == incrementButton)
        {
            incrementButton.removeEventListener(FlexEvent.BUTTON_DOWN,
                                                button_buttonDownHandler);
            incrementButton.removeEventListener(MouseEvent.ROLL_OVER,
                                                button_rollOverHandler);
            incrementButton.removeEventListener(MouseEvent.ROLL_OUT,
                                                button_rollOutHandler);
        }
        else if (instance == track)
        {
            track.removeEventListener(MouseEvent.ROLL_OVER,
                                      track_rollOverHandler);
            track.removeEventListener(MouseEvent.ROLL_OUT, 
                                      track_rollOutHandler);
        }
    }

    /**
     *  Adds or subtracts <code>pageSize</code> from <code>value</code>.
     *  For an addition, the new <code>value</code> is the closest multiple of <code>pageSize</code> 
     *  that is larger than the current <code>value</code>.
     *  For a subtraction, the new <code>value</code> 
     *  is the closest multiple of <code>pageSize</code> that is 
     *  smaller than the current value. 
     *  The minimum value of <code>value</code> is <code>pageSize</code>. 
     *
     *  @param increase Whether the paging action adds (<code>true</code>)or
     *  decreases (<code>false</code>) <code>value</code>. 
     *  
     *  @langversion 3.0
     *  @playerversion Flash 10
     *  @playerversion AIR 1.5
     *  @productversion Flex 4
     */
    public function page(increase:Boolean = true):void
    {
        var val:Number;
        if (increase)
            val = Math.min(value + pageSize, maximum);
        else
            val = Math.max(value - pageSize, minimum);
        if (smoothScrolling) {
            startAnimation(getStyle("repeatInterval"), val, Linear.getInstance());            
            animatingSinglePage = true;
        }
        else
        {
            setValue(val);
            dispatchEvent(new Event("change"));
        }
    }

    /**
     *  Calculates the size for the thumb from the current range, pageSize, and
     *  trackSize settings.
     * 
     *  If fixedThumbSize is true, then subclasses should return a value based
     *  on the thumb's preferred size instead.
     * 
     *  @see #fixedThumbSize
     *  
     *  @langversion 3.0
     *  @playerversion Flash 10
     *  @playerversion AIR 1.5
     *  @productversion Flex 4
     */
    override protected function calculateThumbSize():Number
    {
        var range:Number = maximum - minimum;
        
        // Thumb takes up entire track.
        if (range == 0)
            return trackSize;
        
        return Math.min((pageSize / (range + pageSize) ) * trackSize, trackSize);
    }

    //--------------------------------------------------------------------------
    // 
    // Event Handlers
    //
    //--------------------------------------------------------------------------

    //---------------------------------
    // Viewport property changes
    //---------------------------------
     
    private function viewport_propertyChangeHandler(event:PropertyChangeEvent):void
    {
        switch(event.property) 
        {
            case "contentWidth": 
                viewportContentWidthChangeHandler(event);
                break;
                
            case "contentHeight": 
                viewportContentHeightChangeHandler(event);
                break;
                
            case "horizontalScrollPosition":
                viewportHorizontalScrollPositionChangeHandler(event);
                break;

            case "verticalScrollPosition":
                viewportVerticalScrollPositionChangeHandler(event);
                break;
        }
    }
    
    
   /**
    *  Called when the viewport's width or height value changes. Does nothing by default.
    *  
    *  @langversion 3.0
    *  @playerversion Flash 10
    *  @playerversion AIR 1.5
    *  @productversion Flex 4
    */
    protected function viewportResizeHandler(event:ResizeEvent):void
    {
    }
    
   /**
    *  Called when the viewport's <code>contentWidth</code> value changes. Does nothing by default.
    *  
    *  @langversion 3.0
    *  @playerversion Flash 10
    *  @playerversion AIR 1.5
    *  @productversion Flex 4
    */
    protected function viewportContentWidthChangeHandler(event:PropertyChangeEvent):void
    {
    }
    
    /**
     *  Called when the viewport's <code>contentHeight</code> value changes. Does nothing by default.
     *  
     *  @langversion 3.0
     *  @playerversion Flash 10
     *  @playerversion AIR 1.5
     *  @productversion Flex 4
     */
    protected function viewportContentHeightChangeHandler(event:PropertyChangeEvent):void
    {
    }
    
    /**
     *  Called when the viewport's <code>horizontalScrollPosition</code> value changes. Does nothing by default.
     *  
     *  @langversion 3.0
     *  @playerversion Flash 10
     *  @playerversion AIR 1.5
     *  @productversion Flex 4
     */
    protected function viewportHorizontalScrollPositionChangeHandler(event:PropertyChangeEvent):void
    {
    }  
    
    /**
     *  Called when the viewport's <code>verticalScrollPosition</code> value changes. Does nothing by default. 
     *  
     *  @langversion 3.0
     *  @playerversion Flash 10
     *  @playerversion AIR 1.5
     *  @productversion Flex 4
     */
    protected function viewportVerticalScrollPositionChangeHandler(event:PropertyChangeEvent):void
    {
    }   
    
    //---------------------------------
    // Mouse up/down handlers
    //---------------------------------
     
    /**
     *  Handles a click on the increment or decrement button of the scroll bar. 
     *  This should cause a stepping operation, which is repeated if held down.
     *  The delay before repetition begins and the delay between repeated events
     *  are determined by the <code>repeatDelay</code> and 
     *  <code>repeatInterval</code> styles of the underlying Button objects.
     * 
     *  @see spark.components.Button
     *
     *  @langversion 3.0
     *  @playerversion Flash 10
     *  @playerversion AIR 1.5
     *  @productversion Flex 4  
     */
    protected function button_buttonDownHandler(event:Event):void
    {
        // Noop if we're currently running a stepping animation. We get
        // called repeatedly here due to the button's autoRepeat
        if (!steppingDown && !steppingUp)
        {
            var increment:Boolean = (event.target == incrementButton);
            var oldValue:Number = value;
            
            // TODO (chaase): first step is non-animated, just to simplify the delayed
            // start of the animated stepping. Seems okay, but worth thinking
            // about whether we should animate the first step too
            step(increment);
            
            if (value != oldValue)
            {
                positionThumb(valueToPosition(value));
                dispatchEvent(new Event("change"));
            }

            if (smoothScrolling)
            {
                systemManager.getSandboxRoot().addEventListener(MouseEvent.MOUSE_UP, 
                    button_buttonUpHandler, true /*useCapture*/);
                systemManager.getSandboxRoot().addEventListener(
                    SandboxMouseEvent.MOUSE_UP_SOMEWHERE, button_buttonUpHandler);
                // TODO (chaase): what's a reasonable stepSize? Can't use viewport's because
                // it can vary widely depending on what items are in the view. Can't use
                // default stepSize because it can be quite small if not changed by
                // the scroller. 1/10th of pageSize seems reasonable, but will result
                // in a different total duration with animated vs. non-animated stepping
                animateStepping(increment ? maximum : minimum, pageSize/10);
            }
            return;
        }
    }
    
    /**
     *  Handles releasing the increment or decrement button of the scrollbar. 
     *  This ends the stepping operation started by the original buttonDown
     *  event on the button.
     *
     *  @see spark.components.Button
     *
     *  @langversion 3.0
     *  @playerversion Flash 10
     *  @playerversion AIR 1.5
     *  @productversion Flex 4  
     
     */
    protected function button_buttonUpHandler(event:Event):void
    {
        if (steppingDown || steppingUp)
        {
            if (animator.isPlaying)
            {
                animationEndHandler(animator);
            }
            else
            {
                // probably shouldn't get here, but just in case
                steppingUp = steppingDown = false;
            }
            // stop even if !isPlaying - it might just be startDelayed
            animator.stop();
            
            systemManager.getSandboxRoot().removeEventListener(MouseEvent.MOUSE_UP, 
                button_buttonUpHandler, true /*useCapture*/);
            systemManager.getSandboxRoot().removeEventListener(
                SandboxMouseEvent.MOUSE_UP_SOMEWHERE, button_buttonUpHandler);
        }
    }
    
    //---------------------------------
    // Track dragging handlers
    //---------------------------------
    
    /**
     *  @private
     *  Handle mouse-down events for the scroll track. In our handler,
     *  we figure out where the event occurred on the track and begin
     *  paging the scroll position toward that location. We start a 
     *  timer to handle repeating events if the user keeps the button
     *  pressed on the track.
     */
    override protected function track_mouseDownHandler(event:MouseEvent):void
    {
        // TODO (chaase): We might want a different event mechanism eventually
        // which would push this enabled check into the child/skin components
        if (!enabled)
            return;

        // Make sure we finish any running page animation before starting
        // a new one. end() will set value to the desired paged-to value for 
        // that running animation
        if (animatingSinglePage)
            animator.end();
        
        var pt:Point = new Point(event.stageX, event.stageY);
        // Cache original event location for use on later repeating events
        trackPosition = track.globalToLocal(pt);
        var newScrollPosition:Number = pointToPosition(trackPosition.x, trackPosition.y);
        var newScrollValue:Number = positionToValue(newScrollPosition);
        
        trackScrollDown = (newScrollValue > value);
        
        var oldValue:Number = value;
        
        if (event.shiftKey)
        {
            // shift-click positions jumps to the clicked location instead
            // of incrementally paging
            var slideDuration:Number = getStyle("slideDuration");
            // Adjust the position - we want the clicked position to be at the
            // half-way point of the thumb when it's done moving
            newScrollPosition -= thumbSize/2;
            newScrollValue = positionToValue(newScrollPosition);
            var adjustedValue:Number = nearestValidValue(newScrollValue, valueInterval);
            if (smoothScrolling && 
                slideDuration != 0 && 
                (maximum - minimum) != 0)
            {
                // Animate the shift-click operation
                startAnimation(slideDuration * 
                    (Math.abs(value - newScrollValue) / (maximum - minimum)),
                    adjustedValue, deceleratingSineEaser);
            }
            else
            {
                setValue(adjustedValue);
                dispatchEvent(new Event("change"));
            }
            return;
        }
        
        page(trackScrollDown);
        
        trackScrolling = true;

        // Add event handlers for drag and up events
        addSystemHandlers(MouseEvent.MOUSE_MOVE, track_mouseMoveHandler, 
            stage_track_mouseMoveHandler);
        systemManager.addEventListener(
            MouseEvent.MOUSE_UP, track_mouseLeaveHandler, true);
        systemManager.stage.addEventListener(Event.MOUSE_LEAVE, 
                            track_mouseLeaveHandler);

        // TODO (chaase): consider using the repeat behavior of Button
        // to handle track-down repetition, instead of doing it with a
        // custom Timer. As long as we can distinguish the first
        // down event from subsequent ones, we may be able to just let
        // Button do most of this work.
        // Start a timer to handle repeating events if the user
        // continues to hold the mouse button down
        if (!trackScrollTimer)
        {
            trackScrollTimer = new Timer(getStyle("repeatDelay"), 1);
            trackScrollTimer.addEventListener(TimerEvent.TIMER, 
                                              trackScrollTimerHandler);
        } 
        else
        {
            // Note that this behavior, resetting the initial delay, differs 
            // from Flex3 but is more consistent with general application
            // scrollbar behavior
            trackScrollTimer.delay = getStyle("repeatDelay");
            trackScrollTimer.repeatCount = 1;
        }
        trackScrollTimer.start();
    }

    /**
     * Animates the operation to move to <code>newValue</code>.
     * The <code>pageSize</code> parameter is used to compute the amount 
     * of time taken to get to that value, so that the time taken to animate
     * a paging operation is roughly the same as the non-animated version; 
     * both operations should end up at the same place at about the same time.
     *
     * @param newValue The final value being paged to.
     * @param pageSize The amount of horizontal or vertical movement requested.
     * This value is used to compute, with the <code>repeatInterval</code> style,
     * the total time taken to move to the new value. <code>pageSize</code>
     * is usually set dynamically by the containing Scroller to the value required
     * to view content at a logical content boundary.
     *  
     *  @langversion 3.0
     *  @playerversion Flash 10
     *  @playerversion AIR 1.5
     *  @productversion Flex 4
     */
    protected function animatePaging(newValue:Number, pageSize:Number):void
    {
        animatingSinglePage = false;
        if (trackScrollDown)
            newValue = newValue - pageSize;
        // TODO (chaase): hard-coding easing behavior, how to style it?
        startAnimation(
            getStyle("repeatInterval") * (Math.abs(newValue - value) / pageSize),
            nearestValidValue(newValue, pageSize), Linear.getInstance());
    }

    /**
     * Animates the operation to step to <code>newValue</code>.
     * The <code>stepSize</code> parameter is used to compute the amount 
     * of time taken to get to that value, so that the time taken to animate
     * a stepping operation is roughly the same as the non-animated version; 
     * both operations should end up at the same place at about the same time.
     *
     * @param newValue The final value being stepped to.
     * @param stepSize The amount of stepping requested.
     * This value is used to compute, with the <code>repeatInterval</code> style,
     * the total time taken to step to the new value. <code>stepSize</code>
     * is usually set dynamically by the containing Scroller to the value required
     * to view content at a logical content boundary.
     *  
     *  @langversion 3.0
     *  @playerversion Flash 10
     *  @playerversion AIR 1.5
     *  @productversion Flex 4
     */
    
    protected function animateStepping(newValue:Number, stepSize:Number):void
    {
        steppingDown = (newValue > value);
        steppingUp = !steppingDown;
        // TODO (chaase): we're using ScrollBar's repeatInterval for animated
        // stepping, but Button's repeatInterval for non-animated stepping
        // TODO (chaase): think about the total duration for the animation. This
        // calculation
        // TODO (chaase): hard-coding easing behavior, how to style it?
        startAnimation(
            getStyle("repeatInterval") * (Math.abs(newValue - value) / stepSize),
            newValue, easyInLinearEaser, getStyle("repeatDelay"));
    }

    /**
     * @private
     * Handles events from the Animation that runs the page, step,
     * and shift-click smooth-scrolling operations.
     * Just call setValue() with the current animated value.
     */
    private function animationUpdateHandler(animation:Animation):void
    {
        setValue(animation.currentValue["value"]);
    }
    
    /**
     * @private
     * Handles end event from the Animation that runs the page, step,
     * and shift-click animations.
     * We dispatch the "change" event at this time, after the animation
     * is done.
     */
    private function animationEndHandler(animation:Animation):void
    {
        if (trackScrolling)
            trackScrolling = false;

        if (steppingDown || steppingUp)
        {
            // If we're animating stepping, end on a final real step call in the
            // appropriate direction, ensuring that we stop on a content 
            // item boundary 
            step(steppingDown);
            steppingUp = steppingDown = false;
            animator.startDelay = 0;
        }
        animatingSinglePage = false;
        dispatchEvent(new Event("change"));
    }
    
    /**
     *  @private
     *  This gets called at certain intervals to repeat the scroll 
     *  event when the user is still holding the mouse button 
     *  down on the track.
     */
    private function trackScrollTimerHandler(event:Event):void
    {
        // Only repeat the scrolling if the current scroll position
        // (represented by fraction) is not past the current
        // mouse position on the track 
        var newScrollPosition:Number = pointToPosition(
            trackPosition.x, trackPosition.y);
        var newScrollValue:Number = positionToValue(newScrollPosition);
                
        if (trackScrollDown)
        {
            var range:Number = maximum - minimum;
            if (range == 0)
                return;
            
            if ((value + pageSize) > newScrollValue)
                return;
        }
        else if (newScrollValue > value)
        {
            return;
        }

        if (smoothScrolling)
        {
            // This gets called after an initial repeateDelay on a paging
            // operation, but after that we're just running the animation. This
            // function is only called repeatedly in the non-smoothScrolling case.
            animatePaging(newScrollValue, pageSize);
            return;
        }

        var oldValue:Number = value;
        
        page(trackScrollDown);
        
        if (value != oldValue)
        {
            positionThumb(valueToPosition(value));
            dispatchEvent(new Event("change"));
        }

        if (trackScrollTimer && trackScrollTimer.repeatCount == 1)
        {
            // If this was the first time repeating, set the Timer to
            // repeat indefinitely with an appropriate interval delay
            trackScrollTimer.delay = getStyle("repeatInterval");
            trackScrollTimer.repeatCount = 0;
        }
    }

    /**
     *  @private
     *  Handle mouse-move events for track scrolling anywhere on the stage
     */
    private function stage_track_mouseMoveHandler(event:MouseEvent):void
    {
        if (event.target != stage)
            return;

        track_mouseMoveHandler(event);
    }

    /**
     *  @private
     *  Record a new trackPosition, which is the location of the
     *  mouse on the track, relative to the stage. This is used 
     *  in the ongoing Timer events for track scrolling.  Note
     *  that the timer will be stopped when the mouse is not over
     *  the track, so although we are setting new trackPosition
     *  values, we are not actually stepping the scroll if the mouse
     *  is outside of the track area.
     */
    private function track_mouseMoveHandler(event:MouseEvent):void
    {
        if (trackScrolling)
        {
            var pt:Point = new Point(event.stageX, event.stageY);
            // Cache original event location for use on later repeating events
            trackPosition = track.globalToLocal(pt);
        }
    }

    /**
     *  @private
     *  Stop scrolling the track if the mouse leaves the stage
     *  area. Remove the listeners and stop the Timer.
     */
    private function track_mouseLeaveHandler(event:Event):void
    {
        trackScrolling = false;
        removeSystemHandlers(MouseEvent.MOUSE_MOVE, track_mouseMoveHandler,
                stage_track_mouseMoveHandler);
        systemManager.removeEventListener(MouseEvent.MOUSE_UP,
                track_mouseLeaveHandler, true);
        systemManager.stage.removeEventListener(Event.MOUSE_LEAVE, 
                            track_mouseLeaveHandler);

        if (trackScrollTimer)
            trackScrollTimer.reset();
            
        if (smoothScrolling && !animatingSinglePage)
        {
            if (animator.isPlaying)
            {
                animationEndHandler(animator);
            }
            // Stop it regardless, in case the animation is startDelayed and
            // thus not 'playing', but still active
            animator.stop();
        }
    }

    /**
     *  @private
     *  If we are still in the middle of track-scrolling, restart the
     *  timer when the mouse re-enters the track area.
     */
    private function track_rollOverHandler(event:MouseEvent):void
    {
        if (trackScrolling && trackScrollTimer)
            trackScrollTimer.start();
    }
    
    /**
     *  @private
     *  Stop the track-scrolling repeat events if the mouse leaves
     *  the track area.
     */
    private function track_rollOutHandler(event:MouseEvent):void
    {
        if (trackScrolling && trackScrollTimer)
            trackScrollTimer.stop();
    }
    
    /**
     *  @private
     *  Resume the increment/decrement animation if the mouse enters the
     *  button area
     */
    private function button_rollOverHandler(event:MouseEvent):void
    {
        if (steppingUp || steppingDown)
            animator.resume();
    }
    
    /**
     *  @private
     *  Pause the increment/decrement animation if the mouse leaves the
     *  button area
     */
    private function button_rollOutHandler(event:MouseEvent):void
    {
        if (steppingUp || steppingDown)
            animator.pause();
    }
}

}