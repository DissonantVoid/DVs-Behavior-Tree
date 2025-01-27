class_name UTTestBase
extends Node

## Base class for all test scripts

# NOTE: there is no auto_free() that automatically removes node after test ends
#    dev is responsible for explicitly instancing and freeing nodes

signal error(message : String)

# NOTE: before_all and before_each cannot use await to ensure that each test
#       starts right after _ready
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
		error.emit("{0} and {1} are not equal".format([a, b]))

func assert_fail(message : String = "It. Just. Failed!"):
	error.emit(message)
