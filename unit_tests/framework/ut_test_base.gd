class_name UTTestBase
extends Node

## Base class for all test scripts

# NOTE: there is no auto_free() that automatically removes node after test ends
#    dev is responsible for explicitly instancing and freeing nodes

signal error(message : String)

func before_all():
	return

func after_all():
	return

func before_each():
	return

func after_each():
	return

func assert_equal(a, b):
	if a != b:
		error.emit("# and # are not equal".format([a, b], "#"))
