.. SPDX-License-Identifier: LGPL-2.1-or-later

================================
MediaServer2 D-Bus specification
================================

This is the D-Bus interface that can be used by applications that want to have
out-of-process media streams exported to other apps.

********************
Theory of operations
********************

Each provider application needs to maintain a hierarchy of media in which each object
in the hierarchy is either an item or a container. An item is a playable leaf object
and a container is a collection of other containers and/or items. For example, if a
provider exposes media in a particular directory on some filesystem, each directory
will be exposed as a container and each media file will be exposed as an item.

***********
Entry point
***********

The service name on the *SESSION* bus should be:

``org.gnome.UPnP.MediaServer2.ApplicationName``, for example ``org.gnome.UPnP.MediaServer2.PulseAudio``.

Rygel shold look for all services on the bus starting with ``org.gnome.UPnP.MediaServer2.``,
both active ant activatable. It should then do its calls on an entry point object on the
service with the path of ``/org/gnome/UPnP/MediaServer2/ApplicationName``,
for example ``/org/gnome/UPnP/MediaServer2/PulseAudio``.

The two ApplicationName suffixes on the service name and the path should be identical.

**********
Interfaces
**********

The objects that are implemented by services of this type can have the following interfaces:

.. code::

    org.gnome.UPnP.MediaObject2
    org.gnome.UPnP.MediaContainer2
    org.gnome.UPnP.MediaItem2

MediaContainer is for directories that are expoised (in UPnP terms: "containers"). MediaItem is
for streams/files that are exposed (in UPnP terms "items").

MediaItem as well as MediaContainer objects need to implement MediaObject.

The entry point object needs to implement the MediaContainer interface (and hence MediaObject).


org.gnome.UPnP.MediaContainer2
==============================

Methods
-------

org.gnome.UPnP.MediaContainer2.ListChildren (u Offset, u Max, as Filter) -> (aa{sv} Children)
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

ListChildren will get you a list of property name and value dictionaries, one for each object listed.

``Offset`` is the zero-based index of the first item in the search result that the caller is
interested in and ``Max`` is the maximum number of objectes to return out of the search result
(0 for no limit). Together these two properties define a window or slice in the result the caller is
interested in, to allow for incremental browsing.

``Filter`` is an array of property names that the caller is interested in. To fetch all available
properties in the result, clients must pass an array with the single element ``"*"``.

For the properties, refer to :ref:TBD.

org.gnome.UPnP.MediaContainer2.ListChildrenEx (u Offset, u Max, as Filter, s SortBy) -> (aa{sv} Children)
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

ListChildrenEx will get you a list of property name and value dictionaries for all media objects directly
under this container.

``Offset`` is the zero-based index of the first item in the search result that the caller is
interested in and ``Max`` is the maximum number of objectes to return out of the search result
(0 for no limit). Together these two properties define a window or slice in the result the caller is
interested in, to allow for incremental browsing.

``Filter`` is an array of property names that the caller is interested in. To fetch all available
properties in the result, clients must pass an array with the single element ``"*"``.

``SortBy`` is the name of a property that shall be used to use as a sort key for the returned list.

.. note::

    This function is currently not used by Rygel.

For the properties, refer to :ref:TBD.

org.gnome.UPnP.MediaContainer2.ListContainers (u Offset, u Max, as Filter) -> (aa{sv} Children)
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

ListConainers will get you a list of property name and value dictionaries, for all containers under
this container.

``Offset`` is the zero-based index of the first item in the search result that the caller is
interested in and ``Max`` is the maximum number of objectes to return out of the search result
(0 for no limit). Together these two properties define a window or slice in the result the caller is
interested in, to allow for incremental browsing.

``Filter`` is an array of property names that the caller is interested in. To fetch all available
properties in the result, clients must pass an array with the single element ``"*"``.

For the properties, refer to :ref:TBD.

org.gnome.UPnP.MediaContainer2.ListContainersEx (u Offset, u Max, as Filter, s SortBy) -> (aa{sv} Children)
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

ListConainersEx will get you a list of property name and value dictionaries, for all containers under
this container.

``Offset`` is the zero-based index of the first item in the search result that the caller is
interested in and ``Max`` is the maximum number of objectes to return out of the search result
(0 for no limit). Together these two properties define a window or slice in the result the caller is
interested in, to allow for incremental browsing.

``Filter`` is an array of property names that the caller is interested in. To fetch all available
properties in the result, clients must pass an array with the single element ``"*"``.

``SortBy`` is the name of a property that shall be used to use as a sort key for the returned list.
It needs to be prefixed with "+" to denote ascending order and "-" for descending order.

.. note::

    This function is currently not used by Rygel.

For the properties, refer to :ref:TBD.

org.gnome.UPnP.MediaContainer2.ListItems (u Offset, u Max, as Filter) -> (aa{sv} Children)
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

ListItems will get you a list of property name and value dictionaries, for all items under
this container.

``Offset`` is the zero-based index of the first item in the search result that the caller is
interested in and ``Max`` is the maximum number of objectes to return out of the search result
(0 for no limit). Together these two properties define a window or slice in the result the caller is
interested in, to allow for incremental browsing.

``Filter`` is an array of property names that the caller is interested in. To fetch all available
properties in the result, clients must pass an array with the single element ``"*"``.

For the properties, refer to :ref:TBD.

org.gnome.UPnP.MediaContainer2.ListItemsEx (u Offset, u Max, as Filter, s SortBy) -> (aa{sv} Children)
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

ListItems will get you a list of property name and value dictionaries, for all items under this
container.

``Offset`` is the zero-based index of the first item in the search result that the caller is
interested in and ``Max`` is the maximum number of objectes to return out of the search result
(0 for no limit). Together these two properties define a window or slice in the result the caller is
interested in, to allow for incremental browsing.

``Filter`` is an array of property names that the caller is interested in. To fetch all available
properties in the result, clients must pass an array with the single element ``"*"``.

``SortBy`` is the name of a property that shall be used to use as a sort key for the returned list.
It needs to be prefixed with "+" to denote ascending order and "-" for descending order.

.. note::

    This function is currently not used by Rygel.

For the properties, refer to :ref:TBD.


org.gnome.UPnP.MediaContainer2.SearchObjects (s Query, u Offset, u Max, as Filter) -> (aa{sv} Result)
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

SearchObjects gets you properties of all media objects anywhere under this container that satisfy
the search criteria.

``Query`` is a search criteria string which is described by the following BNF syntax:

.. code:: BNF

    searchCrit   ::= searchExp | asterisk
    searchExp    ::= relExp|
                     searchExp wChar+ logOp wChar+ searchExp|
                     '(' wChar* searchExp wChar* ')'
    logOp        ::= 'and'|'or'
    relExp       ::= property wChar+ binOp wChar+ quotedVal|
                     property wChar+ existsOp wChar+ boolVal
    binOp        ::= relOp|stringOp
    relOp        ::= '='|'!='|'<'|'<='|'>'|'>='
    stringOp     ::= 'contains'|'doesNotContain'|'derivedfrom'
    existsOp     ::= 'exists'
    boolVal      ::= 'true'|'false'
    quotedVal    ::= dQuote escapedQuote dQuote
    wChar        ::= space|hTab|lineFeed|vTab|formFeed|return
    property     ::= (* property name as defined in Section 2.2.20 *)
    escapedQuote ::= (* double-quote escaped string as defined in
                     Section 1.2.2 *)
    hTab         ::= (* UTF-8 code 0x09, horizontal tab character *)
    lineFeed     ::= (* UTF-8 code 0x0A, line feed character *)
    vTab         ::= (* UTF-8 code 0x0B, vertical tab character *)
    formFeed     ::= (* UTF-8 code 0x0C, form feed character *)
    return       ::= (* UTF-8 code 0x0D, carriage return character *)
    space        ::= ' '
                     (* UTF-8 code 0x20, space character *)
    dQuote       ::= '"'
                     (* UTF-8 code 0x22, double quote character *)
    asterisk     ::= '*'
                     (* UTF-8 code 0x2A, asterisk character *)

The operator precedence, highest to lowest, is:

* dQuote
* ()
* binOp, existsOp
* and
* or

The special value asterisk "*" means to return all media objects.

Examples
""""""""
* ``DisplayName contains "Hello"``
* ``Artist = "Michael Jackson" and "Album" = "Thriller"``
* ``Bitrate > 256 and (MIMEType = "audio/mpeg" org MIMEType = "audio/ogg")``


``Offset`` is the zero-based index of the first item in the search result that the caller is
interested in and ``Max`` is the maximum number of objectes to return out of the search result
(0 for no limit). Together these two properties define a window or slice in the result the caller is
interested in, to allow for incremental browsing.

``Filter`` is an array of property names that the caller is interested in. To fetch all available
properties in the result, clients must pass an array with the single element ``"*"``.

org.gnome.UPnP.MediaContainer2.SearchObjectsEx (s Query, u Offset, u Max, as Filter, s SortBy) -> (aa{sv} Result, u TotalMatch)
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

This function is similar to SearchObjectsEx, except for the additional return value ``TotalMatch``
and the additional ``SortBy`` parameter.

``SortBy`` is the name of a property that shall be used to use as a sort key for the returned list.
It needs to be prefixed with "+" to denote ascending order and "-" for descending order.

``TotalMatch`` returns the number of all items that match the ``Query`` parameter, which might differ
from the number of dictionaries in the result array if the application used ``Max`` and ``Offset``
for slicing the result.

.. note::

    This function is currently not used by Rygel.

Properties
----------

+-------------------+-----------+------------+---------------------------------------------+
|     Name          |   Type    |m/o [#f1]_  |              Description                    |
+===================+===========+============+=============================================+
| ChildCount        |     u     | m          | The total number of child media objects.    |
|                   |           |            | An unknown number of children is indicated  |
|                   |           |            | by using UINT_MAX.                          |
+-------------------+-----------+------------+---------------------------------------------+
| Searchable        |     b     | m          | Whether the container suppors the Search(). |
|                   |           |            | method call.                                |
+-------------------+-----------+------------+---------------------------------------------+
| ItemCount         |     u     | o          | Number of child items.                      |
+-------------------+-----------+------------+---------------------------------------------+
| ContainerCount    |     u     | o          | Number of child containers.                 |
+-------------------+-----------+------------+---------------------------------------------+
| Icon              |     o     | o          | Root container only. Object path of a       |
|                   |           |            | MediaContainer2 object matching the         |
|                   |           |            | MediaItem2.Thumbnail property, to be used   |
|                   |           |            | in user interfaces as a device icon.        |
+-------------------+-----------+------------+---------------------------------------------+

Signals
-------

Updated()
^^^^^^^^^

Which shall be triggered when a new child item is created or removed from the container, or one
of the existing child items is modified, or any of the properties of the container itself are
modified. While the signal should be emitted when child containers are created or removed, it
shall not be emitted when child containers are modified: instead the signal should be emitted
on the child in this case.

.. rubric:: Footnotes

.. [#f1] m/o indicates whether the property is optional or mandatory.
