extends GutTest

var asset_manager
var player
var property

func before_each():
	asset_manager = AssetManager.new()

	player = Player.new()

	property = PropertyCell.new()

	property.data = PropertyData.new()
	property.data.buy_price = 200

	property.property_owner = player
	player.add_property(property)

func test_mortgage_property():
	var result = asset_manager.mortgage_property(
		player,
		property
	)

	assert_true(result)
	assert_true(property.is_mortgaged)

func test_redeem_property():
	property.is_mortgaged = true

	player.balance = 1000

	var result = asset_manager.redeem_property(
		player,
		property
	)

	assert_true(result)
	assert_false(property.is_mortgaged)
