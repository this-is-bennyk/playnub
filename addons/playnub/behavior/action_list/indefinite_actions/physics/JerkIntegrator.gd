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

class_name JerkIntegrator
extends IndefiniteAction

## Derives positional and rotational motion controlled by jerk for [RigidBodyActor]s.
## 
## [b][u]CAUTION[/u]: This class's implementation is not finished yet.[/b][br][br]
## Jerk is the key to good game UX when it comes to physics motion. It is the second
## derivative of position and the first derivative of acceleration. As such, it smoothes
## acceleration out in much the same way as acceleration does to velocity. It can be
## the differentiator between good- and great-feeling motion. Therefore, the [JerkIntegrator]
## provides a general-purpose solution to applying jerk to 2D and 3D rigid bodies inheriting
## from the [RigidBodyActor], along with additional variables for controlling the resulting motion.
## 
## @experimental

var _counteract_collisions := false

func indefinite_update() -> void:
	var rigidbody := target as RigidBodyActor
	
	var state2D: PhysicsDirectBodyState2D = null
	var state3D: PhysicsDirectBodyState3D = null
	
	if rigidbody.base is RigidBody2D:
		state2D = rigidbody.get_state_2D()
	else:
		state3D = rigidbody.get_state_3D()
	
	var contact_count := state2D.get_contact_count() if state2D else state3D.get_contact_count()
	
	if _counteract_collisions:
		var contact_idx := 0
		
		while contact_idx < contact_count:
			if state2D:
				var impulse := state2D.get_contact_impulse(contact_idx)
				var inv_impulse := -impulse
				state2D.apply_central_impulse(inv_impulse * 2.0)
			else:
				var impulse := state3D.get_contact_impulse(contact_idx)
				var inv_impulse := -impulse
				state3D.apply_central_impulse(inv_impulse * 2.0)
			
			contact_idx += 1
	
	#_calculate_jerks()
	#_apply_forces(state.step, state)
	#_damp_velocities(state)
