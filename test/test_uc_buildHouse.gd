extends GutTest

var player
var property

func before_each():
	player = Player.new()

	player.state.balance = 5000

	property = PropertyCell.new()

	property.property_owner = player

	property.data = PropertyData.new()
	property.data.build_cost = 100
	
func test_build_first_house():
	var success = property.build_house()

	assert_true(success)
	assert_eq(property.house_count, 1)
	assert_false(property.has_hotel)
	
	
func test_build_four_houses():
	for i in range(4):
		property.build_house()

	assert_eq(property.house_count, 4)
	assert_false(property.has_hotel)
func test_upgrade_to_hotel():
	for i in range(4):
		property.build_house()

	property.build_house()

	assert_eq(property.house_count, 0)
	assert_true(property.has_hotel)
	
func test_cannot_build_after_hotel():
	property.has_hotel = true

	var result = property.build_house()

	assert_false(result)
