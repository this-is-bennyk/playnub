# MIT License
# 
# Copyright (c) 2025 Ben Kurtin
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

@tool
class_name GenericBoxFiller
extends BoxFiller

## Fills the associated [Box] with a [Variant].

## The data to fill the [Box] with.
@export
var object: Variant

## Optional path to a specific property on the selected [member object].
## Only works if [member object] is of type [Object].
@export
var property_path := &"":
	set(value):
		property_path = value
		emit_changed()

## Editor-only pseudo-console to let the designer know if there's any issues with retrieving
## the object and its specific value.[br]
## [b]NOTE[/b]: This does not verify that the object and/or property will be found or not found
## as expected at runtime, so take this output with a grain of salt and test thoroughly.
@export_custom(PROPERTY_HINT_MULTILINE_TEXT, "", PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_READ_ONLY)
var verification := "":
	get:
		if (not Engine.is_editor_hint()):
			return ""
		
		if object == null:
			return "WARNING: Object is null."
		
		if typeof(object) != TYPE_OBJECT:
			return "Object found with type " + type_string(typeof(object)) + "."
		
		var result := "Object found with type " \
				+ str(object.get_class()) \
				+ str( \
					"" if not object.get_script() else  " (" + \
					( \
						(object.get_script() as Script).resource_path if (object.get_script() as Script).get_global_name().is_empty() else \
						(object.get_script() as Script).get_global_name() \
					) \
					+ ")" \
				) \
				+ "."
		
		if property_path.is_empty():
			return result
		
		var property = object.get_indexed(str(property_path))
		
		if property == null:
			result += "\nWARNING: Property \"" + property_path + "\" returned null."
		else:
			result += "\nProperty \"" + property_path + "\" found with type " \
						+ type_string(typeof(property)) \
						+ str(
							"" if typeof(property) != TYPE_OBJECT else " (" + \
							( \
								(property as Object).get_class() if not (property as Object).get_script() else \
								( \
									((property as Object).get_script() as Script).resource_path if ((property as Object).get_script() as Script).get_global_name().is_empty() else \
									((property as Object).get_script() as Script).get_global_name() \
								) \
							) \
							+ ")"
						) \
						+ " and current value " + var_to_str(property) + "."
		
		return result

func setup() -> void:
	data = object
	key = String(property_path)
