/*

   Licensed to the Apache Software Foundation (ASF) under one or more
   contributor license agreements.  See the NOTICE file distributed with
   this work for additional information regarding copyright ownership.
   The ASF licenses this file to You under the Apache License, Version 2.0
   (the "License"); you may not use this file except in compliance with
   the License.  You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.

 */
package org.apache.flex.forks.batik.dom.svg;

import org.w3c.dom.Element;

/**
 * An interface for DOM nodes that can look up elements with IDs.  This is
 * used to give common interface to {@link org.w3c.dom.Document} and
 * {@link org.apache.flex.forks.batik.dom.xbl.XBLShadowTreeElement} objects.
 *
 * @author <a href="mailto:cam%40mcc%2eid%2eau">Cameron McCormack</a>
 * @version $Id: IdContainer.java 475477 2006-11-15 22:44:28Z cam $
 */
public interface IdContainer {

    /**
     * Returns the element with the given ID that exists in this subtree.
     */
    Element getElementById(String id);
}
