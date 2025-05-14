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

@icon("uid://csqaeo0wvqsgd")
class_name BoxFiller
extends Resource

## Interface for initializing [Box]es in the editor.
## 
## This class provides an extension interface for the [Box] class, since it is
## difficult to accommodate for all kinds of data to initialize in the editor.
## Inherit from this class to create designer-controlled values for [Resource]s
## that use [Box]es.

## The data to set in the [Box].
var data = null
## The key to part of the [member data].
var key = null

func _init() -> void:
	setup()

## The function to inherit from to initialize [member data] and [member key].
## Expose customer parameters with exported variables, then assign them to
## [member data] and [member key] as you see fit. See [method Box.rewrite]
## for more information on how to set up those two member variables.
func setup() -> void:
	assert(false, "Abstract function!")
