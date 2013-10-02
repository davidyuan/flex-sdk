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
package spark.components.itemRenderers
{

import mx.core.mx_internal;
import mx.styles.CSSStyleDeclaration;
import mx.styles.IStyleClient;
import mx.styles.StyleManager;

import spark.components.supportClasses.StyleableTextField;
import spark.utils.UIComponentUtils;

use namespace mx_internal;

/** Default lightweight  class for rendering formatted text in MobileGrid cells .
 * <p> You don't have to use this render explicitly as it will be used by default for MobileGrid text cells. </p>
 *
 *  @langversion 3.0
 *  @playerversion AIR 3.8
 *  @productversion Flex 4.11
 *
 *  */
public class MobileGridTextCellRenderer extends StyleableTextField implements IMobileGridTextCellRenderer
{

    private var _labelFunction:Function;
    private var _labelField:String;
    private var _data:Object;

    public function MobileGridTextCellRenderer()
    {
        super();
        editable = false;
        selectable = false;
        multiline = true;
    }

    public function set styleProvider(value:IStyleClient):void
    {
        styleName = value;
        commitStyles();
    }

    public function set textAlign(value:String):void
    {
        setStyle("textAlign", value);
    }

    public function set cssStyleName(pstyleName:String):void
    {
        var css:CSSStyleDeclaration = pstyleName ? StyleManager.getStyleManager(null).getStyleDeclaration("." + pstyleName) : null;
        // must add to container before working on styles
        styleDeclaration = css;     // for direct style
        if (css)
        {
            leftMargin = css.getStyle("paddingLeft");
            rightMargin = css.getStyle("paddingRight");
            //     multiline = css.get
        }
    }

    public function set data(value:Object):void
    {
        _data = value;
        text = UIComponentUtils.itemToLabel(value, _labelField, _labelFunction);
    }

    public function get data():Object
    {
        return _data;
    }

    public function set labelField(value:String):void
    {
        _labelField = value;
    }

    public function set labelFunction(value:Function):void
    {
        _labelFunction = value;
    }

    public function get canSetContentWidth():Boolean
    {
        return true;
    }

    public function get canSetContentHeight():Boolean
    {
        return false;
    }
}
}

