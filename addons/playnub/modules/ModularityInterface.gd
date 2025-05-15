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

class_name ModularityInterface
extends Node

## Interface for certain necessary properties of the [Module] node.
##
## This class is meant to be abstract. [b]Do not instantiate.[/b]

## What a unique module does when replacing another / others of the same type.
enum UniquenessMode
{
	## Only replaces the reference. Does not affect the other module(s).
	  REPLACE_ONLY
	## Deletes the other module(s) from memory, then replaces it / them.
	, DELETE_AND_REPLACE
	## Stashes the other module(s) in the parent module, then replaces it / them.
	## (Not functional yet.)
	## @experimental: To be implemented when stashing or disabling (whichever is used) is introduced.
	, STASH_AND_REPLACE
}

## Virtual function that determines if the module should enforce uniqueness
## programmatically as opposed to using the designer variable [member uniqueness_enabled].
## Override this function to enable it by copy and pasting this snippet:
## [codeblock]
## func is_strongly_unique(super_level: int) -> bool:
##     if super_level == 0:
##         return true
##     return super(super_level - 1)
## [/codeblock]
## [b]HACK[/b]: This is make sure that we can properly allow
## [member Module.uniqueness_enabled] to work with only the most derived class.
func is_strongly_unique(super_level: int) -> bool:
	return false

## Returns how existing modules of the same type should be replaced, if there are any,
## assuming [method has_strong_uniqueness] returns [code]true[/code].
## Override this function to enable it by copy and pasting this snippet:
## [codeblock]
## func get_strong_uniqueness_mode(super_level: int) -> UniquenessMode:
##     if super_level == 0:
##         return UniquenessMode.REPLACE_ONLY # Replace this with whichever mode you choose.
##     return super(super_level - 1)
## [/codeblock]
## [b]HACK[/b]: This is make sure that we can properly allow
## [member Module.uniqueness_enabled] to work with only the most derived class.
func get_strong_uniqueness_mode(super_level: int) -> UniquenessMode:
	return UniquenessMode.REPLACE_ONLY
