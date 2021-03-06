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
    "ic-renderer-grid",
    function(Y) {
        var _percent_to_unit_map = {
            "100": "1",
            "75":  "3-4",
            "66":  "2-3",
            "50":  "1-2",
            "33":  "1-3",
            "25":  "1-4"
        };

        var _plugin_name_map = {
            ignorable: Y.IC.Plugin.Ignorable
        };

        var Clazz = Y.namespace("IC").RendererGrid = Y.Base.create(
            "ic_renderer_grid",
            Y.IC.RendererBase,
            [ Y.WidgetParent ],
            {
                BOUNDING_TEMPLATE: '<div class="yui3-g"></div>',
                CONTENT_TEMPLATE:  null,

                _unit_config: null,

                initializer: function (config) {
                    Y.log(Clazz.NAME + "::initializer");
                    //Y.log(Clazz.NAME + "::initializer: " + Y.dump(config));

                    this._unit_config = config.units;

                    this.set("width", this.get("advisory_width"));
                    this.set("height", this.get("advisory_height"));
                },

                destructor: function () {
                    Y.log(Clazz.NAME + "::destructor");

                    this._unit_config = null;
                },

                renderUI: function () {
                    Y.log(Clazz.NAME + "::renderUI");
                    Clazz.superclass.renderUI.apply(this, arguments);

                    Y.each(
                        this._unit_config,
                        function (row, i, a) {
                            Y.log(Clazz.NAME + "::renderUI - adding row: " + i);

                            // each row is a unit itself
                            var row_unit_node = Y.Node.create('<div class="yui3-u-1"></div>');

                            if (Y.Lang.isValue(row.add_class)) {
                                Y.log(Clazz.NAME + "::renderUI - row " + i + " adds class '" + row.add_class + "'");
                                row_unit_node.addClass(row.add_class);
                            }

                            if (Y.Lang.isValue(row.plugins)) {
                                Y.each(
                                    row.plugins,
                                    function (plugin_item, ii, ia) {
                                        Y.log(Clazz.NAME + "::renderUI - row " + i + " plugging " + plugin_item);
                                        var plugin = _plugin_name_map[plugin_item];
                                        row_unit_node.plug(plugin);
                                   }
                                );
                            }

                            if (Y.Lang.isValue(row.content)) {
                                Y.log(Clazz.NAME + "::renderUI - adding row " + i + " - basic content: " + row.content);
                                if (Y.Lang.isString(row.content)) {
                                    row_unit_node.setContent(row.content);
                                }
                                else {
                                    row.content.render = row_unit_node;

                                    Y.IC.Renderer.buildContent(row.content);
                                }
                            }
                            else {
                                var columns;
                                if (Y.Lang.isValue(row.columns)) {
                                    columns = row.columns;
                                }
                                else if (Y.Lang.isArray(row)) {
                                    columns = row;
                                }
                                else {
                                    // TODO: throw an exception
                                }

                                // row with a grid inside of it to create the columns
                                var row_grid_node = Y.Node.create('<div class="yui3-g"></div>');
                                row_unit_node.append(row_grid_node);

                                Y.log(Clazz.NAME + "::renderUI - row " + i + " has " + columns.length + " column(s)");
                                Y.each(
                                    columns,
                                    function (col, ii, ia) {
                                        //Y.log(Clazz.NAME + "::renderUI - row " + i + ", col " + ii + ": " + Y.dump(col));
                                        var unit_class = "yui3-u-";
                                        if (Y.Lang.isValue(col.percent)) {
                                            unit_class += _percent_to_unit_map[col.percent];
                                        }
                                        else {
                                            unit_class += "1";
                                        }

                                        var unit_node = Y.Node.create('<div class="' + unit_class + '"></div>');

                                        if (Y.Lang.isValue(col.add_class)) {
                                            unit_node.addClass(col.add_class);
                                        }

                                        if (Y.Lang.isString(col.content)) {
                                            unit_node.setContent(col.content);
                                        }
                                        else {
                                            col.content.render = unit_node;

                                            Y.IC.Renderer.buildContent( col.content );
                                        }

                                        this.append(unit_node);
                                    },
                                    row_grid_node
                                );
                            }

                            this.append(row_unit_node);
                        },
                        this.get("contentBox")
                    );
                }
            },
            {
                ATTRS: {}
            }
        );

        Y.IC.Renderer.registerConstructor("Grid", Clazz.prototype.constructor);
    },
    "@VERSION@",
    {
        requires: [
            "ic-renderer-grid-css",
            "ic-renderer-base",
            "ic-plugin-ignorable"
        ]
    }
);
