.. SPDX-License-Identifier: LGPL-2.1-or-later

============
Coding Style
============

* 4-spaces (and not tabs) for indentation.
* Each line must be considered 120-columns.
* 1-space between function name and braces (both calls and signature declarations)
* Prefix access to resources in the same object with this:

  .. code-block:: vala

            this.some_member = "value";
            this.some_method_call (a, b, c);

* If function signature/call fits in a single line, do not break it into multiple lines.
* If function signature/call doesn't fit in the same line

  * if the first argument fits on the same line as the previous portion of the call/signature, put it on the first line with following comma rest of them on subsequent lines, one-per-line and aligned with the first argument. Like this:

  .. code-block:: vala

            some_object.some_method_call (a,
                                          b,
                                          c,
                                          d,
                                          e,
                                          f);


  * otherwise, put the opening brace along with the first argument on the second line but indented by 40 columns. The rest of the argument follows the same rule as above. Like this:

  .. code-block:: vala

        public void some_method_with_very_long_name
                                        (int some_argument_with_long_name,
                                         int another_argument);

  * An exception to this rule is made for methods/functions that take variable argument tuples. In that case all the first elements of tuples are indented just the normal way described above but the subsequent elements of each tuple are indented 4-space more. Like this:

  .. code-block:: vala

        this.action.get ("ObjectID",
                             typeof (string),
                             out this.object_id,
                         "Filter",
                             typeof (string),
                             out this.filter,
                         "StartingIndex",
                             typeof (uint),
                             out this.index,
                         "RequestedCount",
                             typeof (uint),
                             out this.requested_count,
                         "SortCriteria",
                             typeof (string),
                             out this.sort_criteria);

* Error declarations go on the same line as the last argument if possible, otherwise put it on the next line either aligned to the last argument if any or indented by 40 spaces if there are no arguments.

  .. code-block:: vala

        public void some_method (int some_variable_with_long_name,
                                 int another_variable) throws Error;
        public void some_method (WithAReallyLongSingleArgument arg)
                                 throws Error;
        public void some_method_with_a_very_long_name_that_throws_error ()
                                        throws Error;

* When you have to break strings on multiple lines, make use of '+' operator (you can use it on strings in Vala). Like this "IF" the string is not to be translated. Translatable strings are allowed to break the 80 character rule.

  .. code-block:: vala

                                some_object.some_method ("A very long string" +
                                                         " that doesn't fit " +
                                                         " in one line.");

* Prefer descriptive names over abbreviations & shortening of names. E.g ``discoverer`` over ``disco``.
* Use ``var`` in variable declarations wherever possible.
* Use ``in`` to check presence of flags instead of bitwise and.
* Blocks inside if/else must always be enclosed by '{}'.

* Empty catch blocks *must* have at least a comment why this is not handled. A debug output of the exception message is preferred.
* The more you provide docs in comments, the better. But at the same time avoid over-documenting. Here is an example of useless
* comment:

  .. code-block:: vala

   // Fetch the document
   fetch_the_document ();

* Each class should go in a separate module (.vala file) & name the modules according to the class in it. E.g Rygel.ContentDirectory class should go under content-directory.vala. (You will find old files still carry the full namespace. New files are allowed to skip the namespace)
* Avoid putting more than 3 ``using`` statements in each module (vala file). If you feel you need to use more, perhaps you should consider refactoring (Move some of the code to a separate class).
* Declare the namespace(s) of the class/errordomain with the class/errordomain itself. Like this:

  .. code-block:: vala

   public class Rygel.Hello {
   ...
   };

* Prefer ``foreach`` over ``for``.
* Add a newline before each return, break, throw, continue etc. if it is not the only statement in that block:

  .. code-block:: vala

    if (condition_applies ()) {
      do_something ();

      return false;
    }

    if (other_condition_applies ()) {
      return true;
    }
