////////////////////////////////////////////////////////////////////////////////
//
//  Licensed to the Apache Software Foundation (ASF) under one or more
//  contributor license agreements.  See the NOTICE file distributed with
//  this work for additional information regarding copyright ownership.
//  The ASF licenses this file to You under the Apache License, Version 2.0
//  (the "License"); you may not use this file except in compliance with
//  the License.  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//
////////////////////////////////////////////////////////////////////////////////

package spark.utils
{
import mx.core.IFlexDisplayObject;
import mx.core.ILayoutElement;

/**  @private
 * Utility class for MobileGrid
 *  @langversion 3.0
 *  @playerversion AIR 3.8
 *  @productversion Flex 4.11
 */
public class UIComponentUtils
{

    public static function itemToLabel(item:Object, labelField:String, labelFunction:Function, nullLabel:String = '-'):String
    {
        if (labelFunction != null)
        {
            return labelFunction(item);
        }
        else if (item == null)
        {
            return nullLabel;
        }
        else
        {
            return   item[labelField];
        }
    }


    public static function setElementSize(element:Object, width:Number, height:Number):void
    {
        if (element is ILayoutElement)
        {
            ILayoutElement(element).setLayoutBoundsSize(width, height, false);
        }
        else if (element is IFlexDisplayObject)
        {
            IFlexDisplayObject(element).setActualSize(width, height);
        }
        else
        {
            element.width = width;
            element.height = height;
        }
    }

    public static function setElementPosition(element:Object, x:Number, y:Number):void
    {
        if (element is ILayoutElement)
        {
            ILayoutElement(element).setLayoutBoundsPosition(x, y, false);
        }
        else if (element is IFlexDisplayObject)
        {
            IFlexDisplayObject(element).move(x, y);
        }
        else
        {
            element.x = x;
            element.y = y;
        }
    }

    public static function getElementPreferredWidth(element:Object):Number
    {
        var result:Number;

        if (element is ILayoutElement)
        {
            result = ILayoutElement(element).getPreferredBoundsWidth();
        }
        else if (element is IFlexDisplayObject)
        {
            result = IFlexDisplayObject(element).measuredWidth;
        }
        else
        {
            result = element.width;
        }
        return Math.round(result);
    }

    public static function getElementPreferredHeight(element:Object):Number
    {
        var result:Number;

        if (element is ILayoutElement)
        {
            result = ILayoutElement(element).getPreferredBoundsHeight();
        }
        else if (element is IFlexDisplayObject)
        {
            result = IFlexDisplayObject(element).measuredHeight;
        }
        else
        {
            result = element.height;
        }
        return Math.ceil(result);
    }

    public static function offsetForCenter(inLength:Number, outLength:Number):Number
    {
        return ( outLength - inLength) / 2;
    }

    public static function setElementPositionTopRight(component:Object, container:Object, paddingTop:Number = 0, paddingRight:Number = 0):void
    {
        var right:Number = getElementPreferredWidth(container) - getElementPreferredWidth(component) - paddingRight;
        setElementPosition(component, paddingTop, right);
    }

}
}