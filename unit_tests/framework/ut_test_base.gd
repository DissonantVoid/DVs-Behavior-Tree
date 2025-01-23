class_name UTTestBase
extends Node

## Base class for all test scripts

# NOTE: there is no auto_free() that automatically removes node after test ends
#    dev is responsible for explicitly instancing and freeing nodes

var test_runner : UTTestRunner

func before_all():
	return

func after_all():
	return

func before_each():
	return

func after_each():
	return

func test_assert(statement : bool):
	if statement == false:
		test_runner.eyo_we_got_problems_chief()
