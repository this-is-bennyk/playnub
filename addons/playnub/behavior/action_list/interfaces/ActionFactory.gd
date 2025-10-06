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

@abstract
class_name ActionFactory
extends Resource

## Interface for creating actions with editor-controlled parameters.
## 
## This resource decouples the actual [Action]s processed by [ActionList]s
## from the data that is used to create them. This allows for hot-reloadable
## game logic that can be shared between objects that use [Action]s, as well
## as for use cases where logic is agnostic of the [Action] created by an
## instance of this resource.

## Returns an action using the data of this resource.[br]
## Derived classes can return more specific actions via GDScript's ability for
## [url=https://en.wikipedia.org/wiki/Covariant_return_type]covariant return types[/url].[br]
## For example:
## [codeblock]
## func create_action() -> Interpolator:
##     # ...
## [/codeblock]
@abstract
func create_action() -> Action
