extends Resource
class_name PlayerState

var position: int = 0
var balance: int = 1500
var in_jail: bool = false
var bankrupt: bool = false
var special_cards: int = 0

func update_position(new_position: int):
	position = new_position

func add_balance(amount: int):
	balance += amount

func deduct_balance(amount: int):
	balance -= amount
	

func set_in_jail(flag: bool):
	in_jail = flag

func set_bankrupt(flag: bool):
	bankrupt = flag
