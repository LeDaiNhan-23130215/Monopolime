extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var handler := EventHandler.new()
	var failures := []

	if handler.chance_cards.size() != 40:
		failures.append("Chance deck should define 40 cards, got " + str(handler.chance_cards.size()))
	if handler.community_cards.size() != 40:
		failures.append("Community deck should define 40 cards, got " + str(handler.community_cards.size()))

	var counts: Dictionary = handler.get_deck_counts()
	if int(counts.get("chance", -1)) != 40:
		failures.append("Chance draw pile should start with 40 cards")
	if int(counts.get("community", -1)) != 40:
		failures.append("Community draw pile should start with 40 cards")

	var chance_card := handler._draw_chance()
	var community_card := handler._draw_community()
	counts = handler.get_deck_counts()
	if int(counts.get("chance", -1)) != 39:
		failures.append("Chance draw pile should have 39 cards after one draw")
	if int(counts.get("community", -1)) != 39:
		failures.append("Community draw pile should have 39 cards after one draw")

	for card in [chance_card, community_card]:
		for key in ["title", "text", "action", "icon"]:
			if not card.has(key) or str(card[key]).strip_edges() == "":
				failures.append("Drawn card is missing " + key + ": " + str(card))

	if failures.is_empty():
		print("Event deck check passed.")
		handler.free()
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		handler.free()
		quit(1)
