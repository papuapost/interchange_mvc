/*
    Copyright (C) 2008-2010 End Point Corporation, http://www.endpoint.com/

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 2 of the License, or
    (at your option) any later version.
       
    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of 
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program. If not, see: http://www.gnu.org/licenses/ 
*/

YUI.add(
    "ic-manage-window-content-base",
    function (Y) {
        var Clazz = Y.namespace("IC").ManageWindowContentBase = Y.Base.create(
            "ic_manage_window_content_base",
            Y.Widget,
            [ Y.WidgetStdMod ],
            {
                // these are here as stubbed functions to allow for subclassing
                renderUI: function () {},
                bindUI:   function () {},
                syncUI:   function () {},
            },
            {
                ATTRS: {}
            }
        );

        Clazz.getCacheKey = function (config) {
            Y.log(Clazz.NAME + "::getCacheKey");
            //Y.log(Clazz.NAME + "::getCacheKey - config: " + Y.dump(config));

            return "base";
        };
    },
    "@VERSION@",
    {
        requires: [
            //"ic-manage-window-content-base-css",
            "widget",
            "widget-stdmod"
        ]
    }
);
