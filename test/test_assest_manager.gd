extends GutTest

func test_buy_property_deducts_money():
	var player = Player.new()
	player.balance = 1500

	var property = PropertyCell.new()

	var data = PropertyData.new()
	data.cell_name = "Green 7"
	data.buy_price = 300

	property.data = data

	var am = AssetManager.new()

	var result = am.transfer_property(player, property, 300)

	assert_true(result)
	assert_eq(player.balance, 1200)
	assert_eq(property.property_owner, player)

	property.queue_free()
	am.queue_free()
	
func test_transfer_property_fails_when_no_data():
	var player = Player.new()
	player.balance = 1500

	var property = PropertyCell.new()

	var am = AssetManager.new()

	var result = am.transfer_property(player, property, 300)

	assert_false(result)
	assert_eq(player.balance, 1500)
	assert_null(property.property_owner)

	property.queue_free()
	am.queue_free()
	
func test_transfer_property_fails_when_player_has_no_money():
	var player = Player.new()
	player.balance = 100

	var property = PropertyCell.new()

	var data = PropertyData.new()
	data.cell_name = "Green 7"
	data.buy_price = 300

	property.data = data

	var am = AssetManager.new()

	var result = am.transfer_property(player, property, 300)

	assert_false(result)
	assert_eq(player.balance, 100)
	assert_null(property.property_owner)

	property.queue_free()
	am.queue_free()
